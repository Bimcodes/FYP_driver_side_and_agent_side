// =============================================================================
// FILE: models/transaction_model.dart
// LAYER: Model (Data Layer)
//
// PURPOSE:
//   Dart equivalent of the `Transaction` interface in the admin dashboard's
//   src/models/types.ts. Represents one row in the Supabase `transactions` table.
//
//   The transactions table is the DOUBLE-ENTRY LEDGER — the financial heart
//   of the system. Every token movement (mint, transfer, fare, burn) is
//   recorded here with a sender and receiver wallet.
//
// TRANSACTION TYPES IN THIS APP:
//   MINT      → Admin creates tokens (Treasury receives, sender is null)
//   WHOLESALE → Admin sends tokens to Agent (Treasury → Agent_Vault)
//   FARE      → Student pays a fare (Student_Wallet → Bus_Vault) ← Agent creates this
//   BURN      → Tokens are destroyed at reconciliation (sender is null)
//
// THE FARE TRANSACTION (what this app creates):
//   When an Agent transfers tokens to a Student, or a Student pays a Driver,
//   a FARE transaction is created:
//     sender_wallet_id   = Agent's wallet (or Student's wallet in QR scenario)
//     receiver_wallet_id = Student's wallet (or Driver's Bus_Vault)
//     type               = 'FARE'
//     amount             = number of tokens transferred
// =============================================================================

/// The type of a transaction in the double-entry ledger.
enum TransactionType {
  /// Admin creates new tokens, deposited into Treasury. No sender wallet.
  mint,

  /// Admin distributes tokens from Treasury to an Agent's Vault.
  wholesale,

  /// Agent distributes tokens to a Student's Wallet (Retail vending).
  retail,

  /// Token payment from Student to a Driver / Bus.
  fare,

  /// Tokens are removed from circulation (e.g., at midnight reconciliation).
  burn;

  /// Parses the database string into a [TransactionType] enum.
  static TransactionType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'MINT':
        return TransactionType.mint;
      case 'WHOLESALE':
        return TransactionType.wholesale;
      case 'RETAIL':
        return TransactionType.retail;
      case 'FARE':
        return TransactionType.fare;
      case 'BURN':
        return TransactionType.burn;
      default:
        throw ArgumentError('Unknown TransactionType: $value');
    }
  }

  /// Returns the uppercase string the database expects.
  String toDbString() => name.toUpperCase();
}

/// The outcome status of a transaction.
enum TransactionStatus {
  /// Transaction has been submitted but not yet confirmed.
  pending,

  /// Transaction completed successfully. Balances have been updated.
  success,

  /// Transaction failed (e.g., insufficient balance). Balances unchanged.
  failed;

  static TransactionStatus fromString(String value) {
    switch (value) {
      case 'PENDING':
        return TransactionStatus.pending;
      case 'SUCCESS':
        return TransactionStatus.success;
      case 'FAILED':
        return TransactionStatus.failed;
      default:
        throw ArgumentError('Unknown TransactionStatus: $value');
    }
  }

  String toDbString() => name.toUpperCase();
}

/// Represents one entry in the `transactions` Supabase table.
///
/// [MVVM ROLE]: Pure Model class. No logic. Only data representation.
///
/// This model is:
///   - Created by [TransactionRepository] from Supabase responses
///   - Held as state in Agent and Driver ViewModels
///   - Displayed in the Agent History view and Driver Ledger view
class TransactionModel {
  /// UUID of this transaction record.
  final String id;

  /// What kind of token movement this represents.
  final TransactionType type;

  /// The wallet tokens were sent FROM. Null for MINT transactions.
  final String? senderWalletId;

  /// The wallet tokens were sent TO. Null for BURN transactions.
  final String? receiverWalletId;

  /// The number of tokens transferred.
  final double amount;

  /// External payment reference (e.g., Paystack reference for WHOLESALE).
  /// Null for FARE transactions initiated by the mobile app.
  final String? reference;

  /// Whether this transaction completed, failed, or is pending.
  final TransactionStatus status;

  /// When this transaction occurred (UTC).
  final DateTime timestamp;

  const TransactionModel({
    required this.id,
    required this.type,
    this.senderWalletId,
    this.receiverWalletId,
    required this.amount,
    this.reference,
    required this.status,
    required this.timestamp,
  });

  // ── JSON Serialisation ────────────────────────────────────────────────────

  /// Parses a Supabase database row into a [TransactionModel].
  ///
  /// Example input from Supabase:
  /// ```dart
  /// {
  ///   'id': 'tx-uuid',
  ///   'type': 'FARE',
  ///   'sender_wallet_id': 'agent-wallet-uuid',
  ///   'receiver_wallet_id': 'driver-wallet-uuid',
  ///   'amount': 100.00,
  ///   'reference': null,
  ///   'status': 'SUCCESS',
  ///   'timestamp': '2026-07-09T10:00:00Z',
  /// }
  /// ```
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      type: TransactionType.fromString(json['type'] as String),
      senderWalletId: json['sender_wallet_id'] as String?,
      receiverWalletId: json['receiver_wallet_id'] as String?,
      amount: (json['amount'] as num).toDouble(),
      reference: json['reference'] as String?,
      status: TransactionStatus.fromString(json['status'] as String),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Converts this model to a Map for inserting into Supabase.
  Map<String, dynamic> toJson() {
    return {
      'type': type.toDbString(),
      'sender_wallet_id': senderWalletId,
      'receiver_wallet_id': receiverWalletId,
      'amount': amount,
      'reference': reference,
      'status': status.toDbString(),
    };
  }

  /// A human-readable description for the transaction list UI.
  String get displayDescription {
    switch (type) {
      case TransactionType.fare:
        return 'Fare Payment';
      case TransactionType.retail:
        return 'Retail Token Vending';
      case TransactionType.wholesale:
        return 'Wholesale Token Purchase';
      case TransactionType.mint:
        return 'Treasury Mint';
      case TransactionType.burn:
        return 'Token Burn';
    }
  }

  @override
  String toString() =>
      'TransactionModel(id: $id, type: $type, amount: $amount, status: $status)';
}
