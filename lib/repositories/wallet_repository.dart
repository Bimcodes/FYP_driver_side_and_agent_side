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
  Future<WalletModel> getWalletByOwnerId(String ownerId, {bool createIfMissing = false}) async {
    logger.d('[WalletRepository] getWalletByOwnerId() → ownerId: $ownerId');
    final data = await _client
        .from('wallets')
        .select()
        .eq('owner_id', ownerId)
        .maybeSingle();

    if (data != null) {
      final wallet = WalletModel.fromJson(data);
      logger.i('[WalletRepository] ✅ Wallet found — id: ${wallet.id} | type: ${wallet.walletType.name} | balance: ₦${wallet.balance}');
      return wallet;
    }

    if (!createIfMissing) {
      logger.e('[WalletRepository] No wallet found for $ownerId.');
      throw Exception('No wallet found for this account. Please contact the administrator.');
    }

    logger.w('[WalletRepository] No wallet found for $ownerId. Attempting to create one...');
    final newWalletData = await _client.from('wallets').insert({
      'owner_id': ownerId,
      'wallet_type': 'Student_Wallet',
      'balance': 0.0,
    }).select().single();
    
    final newWallet = WalletModel.fromJson(newWalletData);
    logger.i('[WalletRepository] ✅ Lazy wallet created — id: ${newWallet.id}');
    return newWallet;
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

  // ── Real-Time Stream ──────────────────────────────────────────────────────

  /// Real-time stream watching a specific wallet's row in Supabase.
  ///
  /// Used by Passenger to receive instantaneous balance updates and trigger
  /// the green flash animation when an Agent transfers tokens.
  Stream<WalletModel> watchWallet(String walletId) {
    logger.i('[WalletRepository] watchWallet() → opening Realtime stream for walletId: $walletId');
    return _client
        .from('wallets')
        .stream(primaryKey: ['id'])
        .eq('id', walletId)
        .map((rows) {
          if (rows.isEmpty) return null;
          final wallet = WalletModel.fromJson(rows.first);
          logger.d('[WalletRepository] 📡 Live wallet update — balance: ₦${wallet.balance}');
          return wallet;
        })
        .where((w) => w != null)
        .cast<WalletModel>();
  }
}

// ── Riverpod Provider ────────────────────────────────────────────────────────

/// Provides the [WalletRepository] to Riverpod consumers.
final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  final client = ref.read(supabaseClientProvider);
  return WalletRepository(client);
});
