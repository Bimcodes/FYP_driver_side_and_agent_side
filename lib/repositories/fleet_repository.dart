// =============================================================================
// FILE: repositories/fleet_repository.dart
// LAYER: Repository (Data Access Layer)
//
// PURPOSE:
//   Fetches vehicle (bus) data from the Supabase `vehicles` table.
//   Used by the Bus Selection screen so the driver can pick their bus
//   at the start of each shift.
//
// MVVM ROLE:
//   Repository — Supabase access only. No state, no UI.
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/network/supabase_client.dart';
import '../core/utils/app_logger.dart';

/// Lightweight model representing a bus vehicle for selection purposes.
class BusInfo {
  final String id;             // e.g. "BUS-001"
  final String vaultWalletId;  // UUID of the linked Bus_Vault wallet
  final bool isReconciled;

  const BusInfo({
    required this.id,
    required this.vaultWalletId,
    required this.isReconciled,
  });

  factory BusInfo.fromJson(Map<String, dynamic> json) {
    return BusInfo(
      id: json['id'] as String,
      vaultWalletId: json['vault_wallet_id'] as String? ?? '',
      isReconciled: json['is_reconciled'] as bool? ?? false,
    );
  }
}

/// Fetches the list of all registered buses from Supabase.
///
/// [MVVM ROLE]: Repository — no state, no UI.
class FleetRepository {
  final SupabaseClient _client;

  const FleetRepository(this._client);

  /// Returns all buses ordered by their ID ascending.
  ///
  /// Throws if the query fails.
  Future<List<BusInfo>> getBuses() async {
    logger.d('[FleetRepository] getBuses()');
    final data = await _client
        .from('vehicles')
        .select('id, vault_wallet_id, is_reconciled')
        .order('id', ascending: true);

    final buses = (data as List)
        .map((row) => BusInfo.fromJson(row as Map<String, dynamic>))
        .toList();

    logger.i('[FleetRepository] ✅ Fetched ${buses.length} buses');
    return buses;
  }

  Future<void> claimBus(String vehicleId) async {
    logger.d('[FleetRepository] claimBus() -> $vehicleId');
    await _client.rpc('claim_bus', params: {'p_vehicle_id': vehicleId});
  }

  Future<void> releaseBus(String vehicleId) async {
    logger.d('[FleetRepository] releaseBus() -> $vehicleId');
    await _client.rpc('release_bus', params: {'p_vehicle_id': vehicleId});
  }
}

// ── Riverpod Provider ────────────────────────────────────────────────────────

final fleetRepositoryProvider = Provider<FleetRepository>((ref) {
  final client = ref.read(supabaseClientProvider);
  return FleetRepository(client);
});
