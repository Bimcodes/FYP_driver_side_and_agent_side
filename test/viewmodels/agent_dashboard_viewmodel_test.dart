// =============================================================================
// FILE: test/viewmodels/agent_dashboard_viewmodel_test.dart
// LAYER: Test
//
// PURPOSE:
//   Unit tests for AgentDashboardViewModel — specifically the business logic
//   inside transferToStudent(). This is the most critical code in the app:
//   it moves tokens between two wallets and creates an audit record.
//
// WHAT WE ARE TESTING (the business rules):
//   1. Transferring zero or a negative amount is rejected.
//   2. Transferring more than the agent's current balance is rejected.
//   3. A valid transfer:
//        a. Sets isTransferring = true during the call.
//        b. Updates the agent's wallet balance in local state.
//        c. Prepends the new transaction to recentTransactions.
//        d. Sets a transferSuccess message.
//        e. Clears isTransferring when done.
//   4. If the student wallet ID does not exist, the error is surfaced.
//   5. clearTransferFeedback() resets both success and error messages.
//
// WHY FAKE REPOSITORIES (not mocks)?
//   Riverpod injects repositories through Providers. In tests, we override
//   those providers with fake implementations that return controlled data.
//   This means:
//     - No real Supabase calls are made.
//     - Tests run in milliseconds.
//     - We can simulate any scenario (low balance, wallet not found, etc.)
//     - The test is deterministic — it always produces the same result.
//
// HOW RIVERPOD TESTING WORKS:
//   1. Create a ProviderContainer with a list of `overrides`.
//   2. Each override replaces a real provider with a fake.
//   3. The ViewModel is read from the container just like in production.
//   4. Call ViewModel methods and assert on the resulting state.
// =============================================================================

import 'package:driver_agent_fyp/models/transaction_model.dart';
import 'package:driver_agent_fyp/models/wallet_model.dart';
import 'package:driver_agent_fyp/repositories/transaction_repository.dart';
import 'package:driver_agent_fyp/repositories/wallet_repository.dart';
import 'package:driver_agent_fyp/viewmodels/agent_dashboard_viewmodel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// =============================================================================
// Fake Repositories
// =============================================================================

/// A fake WalletRepository that returns controlled data without touching Supabase.
///
/// [FakeWalletRepository] stores its wallet map in memory. Tests can
/// pre-populate it with wallets and then assert on what changed after a call.
class FakeWalletRepository implements WalletRepository {
  /// In-memory wallet store. Map of walletId → WalletModel.
  final Map<String, WalletModel> _wallets;

  FakeWalletRepository(this._wallets);

  @override
  Future<WalletModel> getWalletByOwnerId(String ownerId, {bool createIfMissing = false}) async {
    for (final w in _wallets.values) {
      if (w.ownerId == ownerId) {
        return w;
      }
    }
    if (!createIfMissing) {
      throw Exception('Wallet not found for owner: $ownerId');
    }
    final newWallet = WalletModel(
      id: 'lazy_wallet_$ownerId',
      ownerId: ownerId,
      walletType: WalletType.studentWallet,
      balance: 0.0,
    );
    _wallets[newWallet.id] = newWallet;
    return newWallet;
  }

  @override
  Future<WalletModel?> getWalletById(String walletId) async {
    return _wallets[walletId]; // Returns null if not found
  }

  /// Simulates updateBalance by adjusting the in-memory balance.
  /// Returns the wallet with the new balance (mirrors real Supabase behaviour).
  Future<WalletModel> updateBalance({
    required String walletId,
    required double delta,
  }) async {
    final wallet = _wallets[walletId];
    if (wallet == null) throw Exception('Wallet $walletId not found.');
    final updated = wallet.copyWithBalance(wallet.balance + delta);
    _wallets[walletId] = updated;
    return updated;
  }

  @override
  Stream<WalletModel> watchWallet(String walletId) => const Stream.empty();
}

/// A fake TransactionRepository that records created transactions in memory.
///
/// Tests can inspect [createdTransactions] to verify the right audit record
/// was written after a transfer.
class FakeTransactionRepository implements TransactionRepository {
  final FakeWalletRepository walletRepo;
  final List<TransactionModel> createdTransactions = [];

  FakeTransactionRepository(this.walletRepo);

  @override
  Future<String> payFare({
    required String busVaultId,
    required String stopId,
    required int passengers,
    required String pin,
    double? lat,
    double? lng,
  }) async {
    return 'fake-fare-id';
  }

  @override
  Future<String> retailTransfer({
    required String studentWalletId,
    required double amount,
    required String pin,
  }) async {
    // In a test, we assume the agent vault is the one we want to deduct from
    final agentWallet = walletRepo._wallets.values.firstWhere(
      (w) => w.walletType == WalletType.agentVault,
      orElse: () => throw Exception('Agent vault not found in FakeWalletRepository'),
    );
    
    await walletRepo.updateBalance(walletId: agentWallet.id, delta: -amount);
    await walletRepo.updateBalance(walletId: studentWalletId, delta: amount);

    final tx = TransactionModel(
      id: 'tx-fake-${createdTransactions.length + 1}',
      type: TransactionType.retail,
      senderWalletId: agentWallet.id,
      receiverWalletId: studentWalletId,
      amount: amount,
      status: TransactionStatus.success,
      timestamp: DateTime.now(),
    );
    createdTransactions.add(tx);
    return tx.id;
  }

  @override
  Future<List<TransactionModel>> getStudentTransactions(String walletId) async => [];

  @override
  Future<List<TransactionModel>> getAgentTransactions(String walletId) async => [];

  @override
  Future<List<TransactionModel>> getTransactionsByReceiverWallet(String walletId) async => [];

  @override
  Stream<TransactionModel> watchBoardingEvents(String driverWalletId) => const Stream.empty();
}

// =============================================================================
// Test Helpers
// =============================================================================

/// The agent's wallet UUID used across tests.
const _agentWalletId = 'wallet-agent-001';

/// The student's wallet UUID used across tests.
const _studentWalletId = 'wallet-student-001';

/// The agent's user UUID.
const _agentUserId = 'user-agent-001';

/// Creates a [WalletModel] for the agent with the given [balance].
WalletModel _agentWallet(double balance) => WalletModel(
      id: _agentWalletId,
      ownerId: _agentUserId,
      walletType: WalletType.agentVault,
      balance: balance,
    );

/// Creates a [WalletModel] for the student with the given [balance].
WalletModel _studentWallet(double balance) => WalletModel(
      id: _studentWalletId,
      ownerId: 'user-student-001',
      walletType: WalletType.studentWallet,
      balance: balance,
    );

/// Builds a [ProviderContainer] with fake repositories pre-loaded,
/// and seeds the ViewModel with an initial wallet state.
///
/// [agentBalance] sets how many tokens the agent starts with.
/// [includeStudentWallet] controls whether the student wallet exists.
ProviderContainer _buildContainer({
  required double agentBalance,
  bool includeStudentWallet = true,
}) {
  final wallets = <String, WalletModel>{
    _agentWalletId: _agentWallet(agentBalance),
    if (includeStudentWallet) _studentWalletId: _studentWallet(0),
  };

  final fakeWalletRepo = FakeWalletRepository(wallets);
  final fakeTxRepo = FakeTransactionRepository(fakeWalletRepo);

  final container = ProviderContainer(
    overrides: [
      walletRepositoryProvider.overrideWithValue(fakeWalletRepo),
      transactionRepositoryProvider.overrideWithValue(fakeTxRepo),
    ],
  );

  // Seed the ViewModel with the agent's starting wallet so the balance
  // check inside transferToStudent() has real data to work with.
  container.read(agentDashboardViewModelProvider.notifier).state =
      AgentDashboardState(wallet: _agentWallet(agentBalance));

  return container;
}

// =============================================================================
// Tests
// =============================================================================

void main() {
  group('AgentDashboardViewModel — transferToStudent()', () {
    // ── Happy Path ────────────────────────────────────────────────────────────

    test('a valid transfer deducts from agent balance and sets success message', () async {
      // Arrange: agent starts with ₦500
      final container = _buildContainer(agentBalance: 500);
      final vm = container.read(agentDashboardViewModelProvider.notifier);

      // Act: transfer ₦200 to a student
      await vm.transferToStudent(
        agentWalletId: _agentWalletId,
        studentWalletId: _studentWalletId,
        amount: 200,
        pin: '1234',
      );

      // Assert: state reflects the transfer
      final state = container.read(agentDashboardViewModelProvider);
      expect(state.isTransferring, isFalse);
      expect(state.wallet?.balance, equals(300)); // 500 - 200 = 300
      expect(state.transferSuccess, contains('200.00'));
      expect(state.transferError, isNull);
    });

    test('a valid transfer creates exactly one transaction audit record', () async {
      // Arrange
      final fakeWallets = {
        _agentWalletId: _agentWallet(500),
        _studentWalletId: _studentWallet(0),
      };
      final fakeWalletRepo = FakeWalletRepository(fakeWallets);
      final fakeTxRepo = FakeTransactionRepository(fakeWalletRepo);
      final container = ProviderContainer(overrides: [
        walletRepositoryProvider.overrideWithValue(fakeWalletRepo),
        transactionRepositoryProvider.overrideWithValue(fakeTxRepo),
      ]);
      container.read(agentDashboardViewModelProvider.notifier).state =
          AgentDashboardState(wallet: _agentWallet(500));

      // Act
      await container
          .read(agentDashboardViewModelProvider.notifier)
          .transferToStudent(
            agentWalletId: _agentWalletId,
            studentWalletId: _studentWalletId,
            amount: 150,
            pin: '1234',
          );

      // Assert: one FARE transaction was logged
      expect(fakeTxRepo.createdTransactions.length, equals(1));
      final tx = fakeTxRepo.createdTransactions.first;
      expect(tx.type, equals(TransactionType.retail));
      expect(tx.senderWalletId, equals(_agentWalletId));
      expect(tx.receiverWalletId, equals(_studentWalletId));
      expect(tx.amount, equals(150));
      expect(tx.status, equals(TransactionStatus.success));
    });

    test('a valid transfer prepends the new transaction to recentTransactions', () async {
      // Arrange: agent already has one existing transaction
      final existingTx = TransactionModel(
        id: 'tx-existing',
        type: TransactionType.fare,
        senderWalletId: _agentWalletId,
        receiverWalletId: _studentWalletId,
        amount: 50,
        status: TransactionStatus.success,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      );
      final container = _buildContainer(agentBalance: 500);
      container.read(agentDashboardViewModelProvider.notifier).state =
          AgentDashboardState(
            wallet: _agentWallet(500),
            recentTransactions: [existingTx],
          );

      // Act
      await container
          .read(agentDashboardViewModelProvider.notifier)
          .transferToStudent(
            agentWalletId: _agentWalletId,
            studentWalletId: _studentWalletId,
            amount: 100,
            pin: '1234',
          );

      // Assert: new transaction is FIRST (prepended), old is second
      final state = container.read(agentDashboardViewModelProvider);
      expect(state.recentTransactions.length, equals(2));
      expect(state.recentTransactions.first.amount, equals(100)); // newest first
      expect(state.recentTransactions.last.id, equals('tx-existing'));
    });

    // ── Validation — Zero / Negative Amount ───────────────────────────────────

    test('transferring zero tokens sets a transferError', () async {
      final container = _buildContainer(agentBalance: 500);
      final vm = container.read(agentDashboardViewModelProvider.notifier);

      await vm.transferToStudent(
        agentWalletId: _agentWalletId,
        studentWalletId: _studentWalletId,
        amount: 0,
        pin: '1234',
      );

      final state = container.read(agentDashboardViewModelProvider);
      expect(state.isTransferring, isFalse);
      expect(state.transferError, contains('greater than zero'));
      expect(state.transferSuccess, isNull);
    });

    test('transferring a negative amount sets a transferError', () async {
      final container = _buildContainer(agentBalance: 500);
      final vm = container.read(agentDashboardViewModelProvider.notifier);

      await vm.transferToStudent(
        agentWalletId: _agentWalletId,
        studentWalletId: _studentWalletId,
        amount: -100,
        pin: '1234',
      );

      final state = container.read(agentDashboardViewModelProvider);
      expect(state.transferError, contains('greater than zero'));
    });

    // ── Validation — Insufficient Balance ─────────────────────────────────────

    test('transferring more than balance sets an insufficient funds error', () async {
      // Arrange: agent only has ₦100
      final container = _buildContainer(agentBalance: 100);
      final vm = container.read(agentDashboardViewModelProvider.notifier);

      // Act: try to transfer ₦500
      await vm.transferToStudent(
        agentWalletId: _agentWalletId,
        studentWalletId: _studentWalletId,
        amount: 500,
        pin: '1234',
      );

      final state = container.read(agentDashboardViewModelProvider);
      expect(state.isTransferring, isFalse);
      expect(state.transferError, contains('Insufficient balance'));
      expect(state.transferError, contains('100.00')); // Shows current balance
      expect(state.wallet?.balance, equals(100)); // Balance is unchanged
    });

    test('transferring exactly the full balance succeeds', () async {
      // Boundary test: balance = 100, amount = 100 → should succeed (not fail)
      final container = _buildContainer(agentBalance: 100);

      await container
          .read(agentDashboardViewModelProvider.notifier)
          .transferToStudent(
            agentWalletId: _agentWalletId,
            studentWalletId: _studentWalletId,
            amount: 100,
            pin: '1234',
          );

      final state = container.read(agentDashboardViewModelProvider);
      expect(state.transferError, isNull);
      expect(state.wallet?.balance, equals(0));
    });

    // ── Validation — Student Wallet Not Found ─────────────────────────────────

    test('transferring to a non-existent student wallet sets an error', () async {
      // Arrange: no student wallet in the fake repo
      final container = _buildContainer(
        agentBalance: 500,
        includeStudentWallet: false,
      );

      await container
          .read(agentDashboardViewModelProvider.notifier)
          .transferToStudent(
            agentWalletId: _agentWalletId,
            studentWalletId: 'wallet-does-not-exist',
            amount: 100,
            pin: '1234',
          );

      final state = container.read(agentDashboardViewModelProvider);
      expect(state.transferError, contains('not found'));
      // Balance should be unchanged — the debit was never applied
      expect(state.wallet?.balance, equals(500));
    });

    // ── clearTransferFeedback ─────────────────────────────────────────────────

    test('clearTransferFeedback() removes both success and error messages', () async {
      // Arrange: manually put the ViewModel in a state with a success message
      final container = _buildContainer(agentBalance: 500);
      container.read(agentDashboardViewModelProvider.notifier).state =
          const AgentDashboardState(
            transferSuccess: 'Transfer done!',
            transferError: 'Some old error',
          );

      // Act
      container.read(agentDashboardViewModelProvider.notifier).clearTransferFeedback();

      // Assert
      final state = container.read(agentDashboardViewModelProvider);
      expect(state.transferSuccess, isNull);
      expect(state.transferError, isNull);
    });
  });

  // ── AgentDashboardState.copyWith ─────────────────────────────────────────

  group('AgentDashboardState.copyWith()', () {
    test('clearTransferSuccess flag nullifies the success message', () {
      const state = AgentDashboardState(transferSuccess: 'done!');
      final updated = state.copyWith(clearTransferSuccess: true);
      expect(updated.transferSuccess, isNull);
    });

    test('clearTransferError flag nullifies the error message', () {
      const state = AgentDashboardState(transferError: 'oops');
      final updated = state.copyWith(clearTransferError: true);
      expect(updated.transferError, isNull);
    });

    test('unrelated fields are preserved when only one field changes', () {
      const state = AgentDashboardState(isLoading: true, isTransferring: true);
      final updated = state.copyWith(isLoading: false);
      expect(updated.isLoading, isFalse);
      expect(updated.isTransferring, isTrue); // preserved
    });
  });
}
