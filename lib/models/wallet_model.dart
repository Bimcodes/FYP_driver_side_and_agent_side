// =============================================================================
// FILE: models/wallet_model.dart
// LAYER: Model (Data Layer)
//
// PURPOSE:
//   Dart equivalent of the `Wallet` interface in the admin dashboard's
//   src/models/types.ts. Represents one row in the Supabase `wallets` table.
//
// ADMIN DASHBOARD MAPPING:
//   TypeScript                          →   Dart
//   ─────────────────────────────────────────────────────────────────────────
//   type WalletType = 'Treasury' |          enum WalletType { treasury,
//     'Agent_Vault' | 'Student_Wallet' |      agentVault, studentWallet,
//     'Bus_Vault'                             busVault }
//
//   interface Wallet {                  →   class WalletModel {
//     id: string;                             final String id;
//     ownerId: string;                        final String ownerId;
//     walletType: WalletType;                 final WalletType walletType;
//     balance: number;                        final double balance;
//   }                                       }
//
// KEY CONCEPT — WALLET TYPES IN THIS APP:
//   The Agent app uses 'Agent_Vault' wallets.
//   The Driver app uses 'Bus_Vault' wallets.
//   The Admin dashboard manages 'Treasury' and all others.
// =============================================================================

/// The type of a wallet in the transit system.
///
/// Mirrors the `wallet_type` enum in the Supabase `wallets` table.
enum WalletType {
  /// The central reserve controlled by the Admin.
  /// All tokens are minted into this wallet first.
  treasury,

  /// An Agent's digital wallet. They purchase tokens wholesale from Treasury.
  agentVault,

  /// A Student's wallet. They receive tokens from Agents and spend them on fares.
  studentWallet,

  /// A Driver's vehicle wallet. Collects fare payments from students.
  busVault;

  /// Converts a raw database string into a [WalletType] enum value.
  static WalletType fromString(String value) {
    switch (value) {
      case 'Treasury':
        return WalletType.treasury;
      case 'Agent_Vault':
        return WalletType.agentVault;
      case 'Student_Wallet':
        return WalletType.studentWallet;
      case 'Bus_Vault':
        return WalletType.busVault;
      default:
        throw ArgumentError('Unknown WalletType: $value');
    }
  }

  /// Converts this enum to the string the database column expects.
  String toDbString() {
    switch (this) {
      case WalletType.treasury:
        return 'Treasury';
      case WalletType.agentVault:
        return 'Agent_Vault';
      case WalletType.studentWallet:
        return 'Student_Wallet';
      case WalletType.busVault:
        return 'Bus_Vault';
    }
  }

  /// A human-readable label for displaying in the UI.
  String get displayName {
    switch (this) {
      case WalletType.treasury:
        return 'Central Treasury';
      case WalletType.agentVault:
        return 'Digital Vault';
      case WalletType.studentWallet:
        return 'Student Wallet';
      case WalletType.busVault:
        return 'Bus Ledger';
    }
  }
}

/// Represents a wallet record from the `wallets` Supabase table.
///
/// [MVVM ROLE]: Pure Model class. Holds data, no logic.
///
/// Every user in the system has at least one Wallet of the appropriate type.
/// The balance is a running total of tokens held.
class WalletModel {
  /// UUID of this wallet record.
  final String id;

  /// UUID of the user who owns this wallet. Foreign key → users.id
  final String ownerId;

  /// The type of this wallet (determines its role in the system).
  final WalletType walletType;

  /// The current token balance. One token = one naira equivalent.
  final double balance;

  const WalletModel({
    required this.id,
    required this.ownerId,
    required this.walletType,
    required this.balance,
  });

  // ── JSON Serialisation ────────────────────────────────────────────────────

  /// Parses a Supabase database row into a [WalletModel].
  ///
  /// Example input from Supabase:
  /// ```dart
  /// {
  ///   'id': 'wallet-uuid',
  ///   'owner_id': 'user-uuid',
  ///   'wallet_type': 'Agent_Vault',
  ///   'balance': 50000.00,
  /// }
  /// ```
  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      walletType: WalletType.fromString(json['wallet_type'] as String),
      // Supabase returns numeric as num — cast to double for Dart safety.
      balance: (json['balance'] as num).toDouble(),
    );
  }

  /// Converts this model to a Map for database writes.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'wallet_type': walletType.toDbString(),
      'balance': balance,
    };
  }

  /// Returns a copy of this model with updated fields.
  WalletModel copyWith({
    String? id,
    String? ownerId,
    WalletType? walletType,
    double? balance,
  }) {
    return WalletModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      walletType: walletType ?? this.walletType,
      balance: balance ?? this.balance,
    );
  }

  /// Returns a copy of this model with an updated balance.
  ///
  /// Used by the ViewModel to compute the new state after a transfer
  /// before writing to the database.
  WalletModel copyWithBalance(double newBalance) {
    return WalletModel(
      id: id,
      ownerId: ownerId,
      walletType: walletType,
      balance: newBalance,
    );
  }

  @override
  String toString() =>
      'WalletModel(id: $id, type: ${walletType.toDbString()}, balance: $balance)';
}
