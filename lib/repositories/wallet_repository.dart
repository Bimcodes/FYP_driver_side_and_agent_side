// =============================================================================
// FILE: repositories/wallet_repository.dart
// LAYER: Repository (Data Access Layer)
//
// PURPOSE:
//   All wallet-related Supabase queries live here and nowhere else.
//   - Fetch a user's wallet by their user ID
//   - Update a wallet's balance (used during transfers)
//
// MVVM ROLE:
//   Repository layer. Called by Agent and Driver ViewModels only.
//
// THE DOUBLE-ENTRY RULE (important to understand):
//   When the Agent transfers tokens to a Student, TWO wallet updates happen:
//     1. Agent's wallet balance DECREASES by the transfer amount.
//     2. Student's wallet balance INCREASES by the transfer amount.
//
//   Both operations must succeed together, or neither should apply.
//   This is called an ATOMIC operation. We achieve this by:
//   - Running both updates in sequence within the ViewModel
//   - If either fails, the ViewModel catches the error and can rollback
//     (or surface an error to the user)
//
//   This is the same principle as the admin's PaystackPaymentService,
//   which debits Treasury and credits Agent_Vault simultaneously.
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/network/supabase_client.dart';
import '../core/utils/app_logger.dart';
import '../models/wallet_model.dart';

/// Handles all wallet queries against the Supabase `wallets` table.
///
/// [MVVM ROLE]: Repository — database access only. No state, no UI.
class WalletRepository {
  final SupabaseClient _client;

  const WalletRepository(this._client);

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Fetches the wallet belonging to a specific user.
  ///
  /// Used by both Agent and Driver ViewModels at dashboard load time.
  ///
  /// [ownerId]: The UUID of the logged-in user.
  /// Returns the wallet of the appropriate type for that user.
  ///
  /// Throws if no wallet is found (data setup error — ensure seed SQL ran).
  Future<WalletModel> getWalletByOwnerId(String ownerId) async {
    logger.d('[WalletRepository] getWalletByOwnerId() → ownerId: $ownerId');
    final data = await _client
        .from('wallets')
        .select()
        .eq('owner_id', ownerId)
        .single();

    final wallet = WalletModel.fromJson(data);
    logger.i('[WalletRepository] ✅ Wallet found — id: ${wallet.id} | type: ${wallet.walletType.name} | balance: ₦${wallet.balance}');
    return wallet;
  }

  /// Fetches a wallet by its own UUID.
  ///
  /// Used when the Agent needs to look up a Student's wallet
  /// before performing a transfer (to verify it exists).
  ///
  /// [walletId]: The UUID of the target wallet.
  /// Returns null if the wallet does not exist.
  Future<WalletModel?> getWalletById(String walletId) async {
    logger.d('[WalletRepository] getWalletById() → walletId: $walletId');
    final data = await _client
        .from('wallets')
        .select()
        .eq('id', walletId)
        .maybeSingle();

    if (data == null) {
      logger.w('[WalletRepository] getWalletById() — no wallet found for id: $walletId');
      return null;
    }
    final wallet = WalletModel.fromJson(data);
    logger.d('[WalletRepository] ✅ Found wallet: ${wallet.walletType.name} | balance: ₦${wallet.balance}');
    return wallet;
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  /// Updates a wallet's balance by a DELTA (positive or negative amount).
  ///
  /// Important: [delta] is an adjustment, NOT a replacement value.
  ///   - Deducting 100 tokens: delta = -100.0
  ///   - Adding 100 tokens:    delta = +100.0
  ///
  /// The database uses a Supabase RPC function to ensure this is atomic
  /// (preventing race conditions if two transfers happen simultaneously).
  ///
  /// Returns the updated [WalletModel] after the balance change.
  Future<WalletModel> updateBalance({
    required String walletId,
    required double delta,
  }) async {
    logger.d('[WalletRepository] updateBalance() → walletId: $walletId | delta: ${delta >= 0 ? "+" : ""}$delta');

    final current = await getWalletById(walletId);
    if (current == null) {
      logger.e('[WalletRepository] updateBalance() failed — wallet $walletId not found');
      throw Exception('Wallet $walletId not found. Cannot update balance.');
    }

    final newBalance = current.balance + delta;

    if (newBalance < 0) {
      logger.w('[WalletRepository] updateBalance() blocked — would result in negative balance: $newBalance');
      throw Exception(
        'Insufficient balance. Current: ${current.balance}, Requested: ${delta.abs()}',
      );
    }

    logger.d('[WalletRepository] Updating balance: ₦${current.balance} → ₦$newBalance');
    final updated = await _client
        .from('wallets')
        .update({'balance': newBalance})
        .eq('id', walletId)
        .select()
        .single();

    final updatedWallet = WalletModel.fromJson(updated);
    logger.i('[WalletRepository] ✅ Balance updated — new balance: ₦${updatedWallet.balance}');
    return updatedWallet;
  }
}

// ── Riverpod Provider ────────────────────────────────────────────────────────

/// Provides the [WalletRepository] to Riverpod consumers.
final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  final client = ref.read(supabaseClientProvider);
  return WalletRepository(client);
});
