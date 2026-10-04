// =============================================================================
// FILE: viewmodels/agent_dashboard_viewmodel.dart
// LAYER: ViewModel (Logic Layer)
//
// PURPOSE:
//   Manages ALL state and business logic for the Agent's workspace.
//   This covers: the Digital Vault balance, the retail transfer form,
//   and the transaction history list.
//
// MVVM ROLE:
//   ViewModel — coordinates WalletRepository and TransactionRepository.
//   The AgentDashboardView and RetailTransferView read from this class.
//   Neither of those Views ever touches Supabase directly.
//
// THE TRANSFER BUSINESS LOGIC (step by step):
//   When an Agent enters a Student Wallet ID and amount and presses "Transfer":
//   1. ViewModel validates: agent has enough balance.
//   2. ViewModel calls WalletRepository.updateBalance(agentWalletId, -amount)
//      → Supabase: agent wallet balance decreases.
//   3. ViewModel calls WalletRepository.updateBalance(studentWalletId, +amount)
//      → Supabase: student wallet balance increases.
//   4. ViewModel calls TransactionRepository.createTransaction(FARE, ...)
//      → Supabase: a new row is inserted in the `transactions` table as an audit log.
//   5. ViewModel updates its local state to reflect the new balance.
//   6. The View automatically re-renders because it watches this state.
//
// ADMIN DASHBOARD EQUIVALENT:
//   This is exactly what PaystackPaymentService.processPaystackPayment() does
//   in the admin dashboard — debit one wallet, credit another, log the transaction.
//   The Agent ViewModel does the same, but initiated by a mobile user action
//   rather than a Paystack webhook.
// =============================================================================

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/app_logger.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';
import '../models/wallet_model.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/wallet_repository.dart';

/// The complete state snapshot for the Agent Dashboard.
///
/// Riverpod exposes this to all Agent views. When any field changes,
/// every Widget watching this state automatically rebuilds.
class AgentDashboardState {
  /// True while any async operation (load, transfer) is in progress.
  final bool isLoading;

  /// The Agent's Digital Vault wallet. Null while loading.
  final WalletModel? wallet;

  /// Recent outgoing transactions. Used by the History view.
  final List<TransactionModel> recentTransactions;

  /// Error message for the dashboard load. Null if no error.
  final String? loadError;

  // ── Transfer Form State ────────────────────────────────────────────────────
  /// True while a transfer is being processed.
  final bool isTransferring;

  /// Success message to show after a successful transfer.
  final String? transferSuccess;

  /// Error message to show if a transfer fails.
  final String? transferError;

  const AgentDashboardState({
    this.isLoading = false,
    this.wallet,
    this.recentTransactions = const [],
    this.loadError,
    this.isTransferring = false,
    this.transferSuccess,
    this.transferError,
  });

  AgentDashboardState copyWith({
    bool? isLoading,
    WalletModel? wallet,
    List<TransactionModel>? recentTransactions,
    String? loadError,
    bool clearLoadError = false,
    bool? isTransferring,
    String? transferSuccess,
    bool clearTransferSuccess = false,
    String? transferError,
    bool clearTransferError = false,
  }) {
    return AgentDashboardState(
      isLoading: isLoading ?? this.isLoading,
      wallet: wallet ?? this.wallet,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      loadError: clearLoadError ? null : (loadError ?? this.loadError),
      isTransferring: isTransferring ?? this.isTransferring,
      transferSuccess: clearTransferSuccess ? null : (transferSuccess ?? this.transferSuccess),
      transferError: clearTransferError ? null : (transferError ?? this.transferError),
    );
  }
}

/// ViewModel for the Agent's entire workspace.
///
/// [MVVM ROLE]: ViewModel — business logic and state. No UI, no direct DB access.
///
/// Connected to:
///   - [WalletRepository]: reads and updates wallet balances
///   - [TransactionRepository]: logs completed transfers and fetches history
///
/// Used by:
///   - [AgentDashboardView]: reads wallet balance and recent transactions
///   - [RetailTransferView]: calls transferToStudent() action
///   - [AgentHistoryView]: reads recentTransactions list
class AgentDashboardViewModel extends Notifier<AgentDashboardState> {
  @override
  AgentDashboardState build() {
    // The initial state — empty, not loading yet.
    return const AgentDashboardState();
  }

  // ── Initialisation ─────────────────────────────────────────────────────────

  /// Loads the Agent's wallet balance and transaction history from Supabase.
  ///
  /// Called by AgentDashboardView in its initState / first build.
  /// Takes [agent] from the AuthViewModel's state (the logged-in user).
  Future<void> loadDashboard(UserModel agent) async {
    logger.i('[AgentViewModel] loadDashboard() → agent: ${agent.name} (${agent.id})');
    state = state.copyWith(isLoading: true, clearLoadError: true);

    try {
      final walletRepo = ref.read(walletRepositoryProvider);
      final txRepo = ref.read(transactionRepositoryProvider);

      logger.d('[AgentViewModel] Fetching wallet for agent...');
      final wallet = await walletRepo.getWalletByOwnerId(agent.id);

      logger.d('[AgentViewModel] Fetching transaction history for wallet: ${wallet.id}');
      final transactions = await txRepo.getAgentTransactions(wallet.id);

      logger.i('[AgentViewModel] ✅ Dashboard loaded — balance: ₦${wallet.balance} | txCount: ${transactions.length}');
      state = state.copyWith(
        isLoading: false,
        wallet: wallet,
        recentTransactions: transactions,
      );

    } catch (e, st) {
      logger.e('[AgentViewModel] loadDashboard failed', error: e, stackTrace: st);
      state = state.copyWith(
        isLoading: false,
        loadError: 'Failed to load dashboard: ${e.toString()}',
      );
    }
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  /// Transfers tokens from the Agent's vault to a student's wallet.
  ///
  /// This is the core business logic of Agent Mode.
  ///
  /// Step-by-step (mirrors the admin's PaystackPaymentService):
  ///   1. Validate that the amount is positive and the agent has enough balance.
  ///   2. Deduct from Agent's wallet (delta = -amount).
  ///   3. Add to Student's wallet (delta = +amount).
  ///   4. Log the FARE transaction in the `transactions` table.
  ///   5. Update local state to reflect the new balance.
  ///
  /// [studentWalletId]: The UUID of the target student wallet.
  /// [amount]: Number of tokens to transfer (must be > 0).
  Future<bool> transferToStudent({
    required String agentWalletId,
    required String studentWalletId,
    required double amount,
    required String pin,
  }) async {
    logger.i('[AgentViewModel] transferToStudent() → amount: ₦$amount | student: $studentWalletId');
    state = state.copyWith(
      isTransferring: true,
      clearTransferSuccess: true,
      clearTransferError: true,
    );

    try {
      if (amount <= 0) throw Exception('Transfer amount must be greater than zero.');

      final txRepo = ref.read(transactionRepositoryProvider);
      
      await txRepo.retailTransfer(
        studentWalletId: studentWalletId, 
        amount: amount, 
        pin: pin,
      );

      // Fetch the updated agent wallet
      final updatedAgentWallet = await ref.read(walletRepositoryProvider).getWalletById(agentWalletId);
      final txList = await txRepo.getAgentTransactions(agentWalletId);

      logger.i('[AgentViewModel] ✅ Transfer complete — new agent balance: ₦${updatedAgentWallet?.balance}');
      state = state.copyWith(
        isTransferring: false,
        wallet: updatedAgentWallet,
        recentTransactions: txList,
        transferSuccess: '₦${amount.toStringAsFixed(2)} transferred successfully!',
      );
      return true;

    } catch (e, st) {
      logger.e('[AgentViewModel] transferToStudent failed', error: e, stackTrace: st);
      final errorMsg = e.toString().contains('message: "') 
          ? RegExp(r'message: "(.*?)"').firstMatch(e.toString())?.group(1) ?? 'Transaction failed'
          : e.toString();
          
      state = state.copyWith(
        isTransferring: false, 
        transferError: errorMsg.replaceAll('PostgrestException(message: ', '').replaceAll(')', ''),
      );
      return false;
    }
  }

  /// Clears the transfer success/error messages.
  /// Called by the View after displaying the feedback to the user.
  void clearTransferFeedback() {
    state = state.copyWith(
      clearTransferSuccess: true,
      clearTransferError: true,
    );
  }
}

// ── Riverpod Provider ────────────────────────────────────────────────────────

/// Provides the [AgentDashboardViewModel] and [AgentDashboardState] to Views.
final agentDashboardViewModelProvider =
    NotifierProvider<AgentDashboardViewModel, AgentDashboardState>(
  AgentDashboardViewModel.new,
);
