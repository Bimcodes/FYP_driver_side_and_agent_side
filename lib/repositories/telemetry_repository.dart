// =============================================================================
// FILE: repositories/telemetry_repository.dart
// LAYER: Repository (Data Access Layer)
//
// PURPOSE:
//   Handles inserting GPS coordinates into the Supabase `telemetry` table.
//   This is the simplest repository in the app — it has one job: INSERT.
//
// MVVM ROLE:
//   Repository layer. Called by DriverDashboardViewModel every 5 seconds.
//
// THE GPS BROADCAST LOOP (full picture):
//
//   DriverDashboardViewModel
//       ↓ Timer.periodic(5 seconds)
//       ↓ calls LocationService.getCurrentPosition()
//       ↓ gets LatLng(6.5244, 3.3792)
//       ↓ wraps in TelemetryModel
//       ↓ calls TelemetryRepository.broadcastLocation()
//   TelemetryRepository
//       ↓ INSERT { driver_id, latitude, longitude } into `telemetry`
//   Supabase
//       ↓ stores row, auto-generates id and timestamp
//   Admin Dashboard (Phase 1 — future)
//       ↓ queries latest telemetry per driver_id to render live map markers
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/network/supabase_client.dart';
import '../core/utils/app_logger.dart';
import '../models/telemetry_model.dart';

/// Handles broadcasting GPS coordinates to the Supabase `telemetry` table.
///
/// [MVVM ROLE]: Repository — Supabase INSERT only. No reads, no state, no UI.
class TelemetryRepository {
  final SupabaseClient _client;

  const TelemetryRepository(this._client);

  /// Inserts a new GPS coordinate row into the `telemetry` table.
  ///
  /// Called by the DriverDashboardViewModel every 5 seconds via a Timer.
  ///
  /// Parameters:
  ///   [driverId]   — UUID of the driver broadcasting their location
  ///   [latitude]   — Decimal latitude from the device GPS
  ///   [longitude]  — Decimal longitude from the device GPS
  ///
  /// The database auto-generates `id` (BIGSERIAL) and `timestamp` (DEFAULT now()).
  /// We do not need to pass those in the payload.
  Future<void> broadcastLocation({
    required String driverId,
    required double latitude,
    required double longitude,
  }) async {
    logger.d('[TelemetryRepository] broadcastLocation() → driverId: $driverId | lat: $latitude | lng: $longitude');

    final telemetry = TelemetryModel(
      driverId: driverId,
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
    );

    await _client.from('telemetry').insert(telemetry.toInsertJson());
    logger.d('[TelemetryRepository] ✅ GPS coordinates inserted into telemetry table');
  }

  Future<List<TelemetryModel>> getActiveBuses() async {
    final fifteenMinutesAgo = DateTime.now().subtract(const Duration(minutes: 15)).toIso8601String();
    
    final response = await _client
        .from('telemetry')
        .select()
        .gte('timestamp', fifteenMinutesAgo)
        .order('timestamp', ascending: false);

    return (response as List)
        .map((row) => TelemetryModel.fromJson(row))
        .toList();
  }
}

// ── Riverpod Provider ────────────────────────────────────────────────────────

/// Provides the [TelemetryRepository] to Riverpod consumers.
final telemetryRepositoryProvider = Provider<TelemetryRepository>((ref) {
  final client = ref.read(supabaseClientProvider);
  return TelemetryRepository(client);
});
