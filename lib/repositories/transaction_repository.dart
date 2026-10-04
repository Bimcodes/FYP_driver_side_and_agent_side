// =============================================================================
// FILE: repositories/transaction_repository.dart
// LAYER: Repository (Data Access Layer)
//
// PURPOSE:
//   Handles all transaction read/write operations AND real-time streaming
//   against the Supabase `transactions` table.
//
// TWO RESPONSIBILITIES:
//   1. WRITE: Insert a new FARE transaction record when Agent transfers tokens.
//   2. READ (Stream): Watch for NEW transaction rows whose receiver_wallet_id
//      matches the Driver's Bus_Vault — this powers the Live Manifest.
//
// WHAT IS A REAL-TIME STREAM? (Supabase Realtime explained)
//   Normally, to get fresh data you must repeatedly call the database
//   (called "polling"). Supabase Realtime is different — it uses a persistent
//   WebSocket connection. Instead of asking "any new rows?", Supabase PUSHES
//   new rows to you the moment they are inserted.
//
//   In code, this looks like a Dart Stream<TransactionModel>:
//   - When the Driver's screen opens, it subscribes to the stream.
//   - Whenever a student pays a fare that credits this driver's Bus_Vault,
//     Supabase instantly pushes that transaction over the WebSocket.
//   - The Driver's ViewModel receives it, triggers the green flash + chime.
//
// SUPABASE REALTIME SETUP REQUIRED:
//   This only works if Realtime is enabled for the `transactions` table.
//   See: Supabase Dashboard → Database → Replication → transactions → ON
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/network/supabase_client.dart';
import '../core/utils/app_logger.dart';
import '../models/transaction_model.dart';

/// Handles transaction creation and real-time boarding event streams.
///
/// [MVVM ROLE]: Repository — Supabase access only. No state, no UI.
class TransactionRepository {
  final SupabaseClient _client;

  const TransactionRepository(this._client);

  Future<String> payFare({
    required String busVaultId,
    required String stopId,
    required int passengers,
    required String pin,
    double? lat,
    double? lng,
  }) async {
    final id = await _client.rpc('pay_fare', params: {
      'p_bus_vault': busVaultId,
      'p_stop_id': stopId,
      'p_passengers': passengers,
      'p_pin': pin,
      'p_lat': lat,
      'p_lng': lng,
    });
    return id as String;
  }

  Future<String> retailTransfer({
    required String studentWalletId,
    required double amount,
    required String pin,
  }) async {
    final id = await _client.rpc('retail_transfer', params: {
      'p_student_wallet': studentWalletId,
      'p_amount': amount,
      'p_pin': pin,
    });
    return id as String;
  }

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Fetches recent transactions where [walletId] was the sender or receiver.
  ///
  /// Used by the Agent History view to show their recent transfers and top-ups.
  /// Ordered by timestamp descending (newest first). Limited to 50 rows.
  Future<List<TransactionModel>> getAgentTransactions(
    String walletId,
  ) async {
    if (walletId.isEmpty) {
      logger.d('[TransactionRepository] getAgentTransactions() — empty walletId, returning []');
      return [];
    }
    logger.d('[TransactionRepository] getAgentTransactions() → walletId: $walletId');
    final data = await _client
        .from('transactions')
        .select()
        .or('sender_wallet_id.eq.$walletId,receiver_wallet_id.eq.$walletId')
        .order('timestamp', ascending: false)
        .limit(50);

    final list = (data as List).map((row) => TransactionModel.fromJson(row)).toList();
    logger.i('[TransactionRepository] ✅ Fetched ${list.length} agent transactions');
    return list;
  }

  /// Fetches recent transactions where [walletId] was the receiver.
  ///
  /// Used by the Driver Ledger view to show all fares collected today.
  Future<List<TransactionModel>> getTransactionsByReceiverWallet(
    String walletId,
  ) async {
    logger.d('[TransactionRepository] getTransactionsByReceiverWallet() → walletId: $walletId');
    final data = await _client
        .from('transactions')
        .select()
        .eq('receiver_wallet_id', walletId)
        .order('timestamp', ascending: false)
        .limit(200);

    final list = (data as List).map((row) => TransactionModel.fromJson(row)).toList();
    logger.i('[TransactionRepository] ✅ Fetched ${list.length} receiver transactions');
    return list;
  }

  /// Fetches all transactions involving [walletId] (either as sender or receiver).
  /// Used by Passenger to view their full ledger of top-ups and fare payments.
  Future<List<TransactionModel>> getStudentTransactions(String walletId) async {
    if (walletId.isEmpty) return [];
    logger.d('[TransactionRepository] getStudentTransactions() → walletId: $walletId');
    final data = await _client
        .from('transactions')
        .select()
        .or('sender_wallet_id.eq.$walletId,receiver_wallet_id.eq.$walletId')
        .order('timestamp', ascending: false)
        .limit(100);

    final list = (data as List).map((row) => TransactionModel.fromJson(row)).toList();
    logger.i('[TransactionRepository] ✅ Fetched ${list.length} student transactions');
    return list;
  }

  // ── Real-Time Stream ──────────────────────────────────────────────────────

  /// Returns a real-time Stream that emits a [TransactionModel] every time
  /// a new transaction crediting [driverWalletId] is inserted into Supabase.
  ///
  /// This is the core of the Driver's Live Manifest feature.
  ///
  /// HOW THE STREAM WORKS:
  ///   1. This method opens a Supabase Realtime channel.
  ///   2. The channel subscribes to INSERT events on `transactions`.
  ///   3. A filter ensures only rows where receiver_wallet_id = driverWalletId
  ///      are forwarded (other drivers' transactions are ignored).
  ///   4. Each incoming payload is parsed into a TransactionModel.
  ///   5. The ViewModel's .listen() callback fires, triggering the green flash.
  ///
  /// The DriverDashboardViewModel calls this once on mount and cancels
  /// the subscription when the driver logs out (in its dispose method).
  Stream<TransactionModel> watchBoardingEvents(String driverWalletId) {
    logger.i('[TransactionRepository] watchBoardingEvents() → opening Realtime stream for driverWalletId: $driverWalletId');
    return _client
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('receiver_wallet_id', driverWalletId)
        .order('timestamp', ascending: false)
        .limit(1)
        .map((rows) {
          if (rows.isEmpty) return null;
          final tx = TransactionModel.fromJson(rows.first);
          logger.i('[TransactionRepository] 📡 Boarding event received — amount: ₦${tx.amount} | id: ${tx.id}');
          return tx;
        })
        .where((tx) => tx != null)
        .cast<TransactionModel>();
  }
}

// ── Riverpod Provider ────────────────────────────────────────────────────────

/// Provides the [TransactionRepository] to Riverpod consumers.
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final client = ref.read(supabaseClientProvider);
  return TransactionRepository(client);
});
