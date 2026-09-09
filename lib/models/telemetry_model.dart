// =============================================================================
// FILE: models/telemetry_model.dart
// LAYER: Model (Data Layer)
//
// PURPOSE:
//   Represents one GPS broadcast row in the `telemetry` Supabase table.
//   This table is NEW in Phase 2 — it does not exist in the admin dashboard.
//
// HOW GPS TELEMETRY WORKS:
//   1. Driver logs in and their Live Manifest screen mounts.
//   2. DriverDashboardViewModel starts a Dart Timer that fires every 5 seconds.
//   3. Each tick: LocationService.getCurrentPosition() is called.
//   4. The returned LatLng is wrapped in a TelemetryModel.
//   5. TelemetryRepository.broadcastLocation() inserts it into Supabase.
//   6. The Admin dashboard can then query the latest telemetry per driver
//      to power the live fleet map.
//
// DATABASE SCHEMA (already created in the SQL setup):
//   CREATE TABLE telemetry (
//     id        BIGSERIAL PRIMARY KEY,
//     driver_id UUID REFERENCES users(id),
//     latitude  DOUBLE PRECISION,
//     longitude DOUBLE PRECISION,
//     timestamp TIMESTAMP WITH TIME ZONE DEFAULT now()
//   );
// =============================================================================

/// Represents a single GPS telemetry broadcast from a Driver.
///
/// [MVVM ROLE]: Pure Model class. Only data. No network or UI logic.
///
/// One new row is inserted into the `telemetry` table approximately
/// every 5 seconds for each active Driver.
class TelemetryModel {
  /// Auto-incremented integer ID from Supabase (BIGSERIAL).
  final int? id;

  /// UUID of the driver who broadcast this location. Foreign key → users.id
  final String driverId;

  /// Latitude in decimal degrees.
  final double latitude;

  /// Longitude in decimal degrees.
  final double longitude;

  /// When this coordinate was captured and stored.
  final DateTime timestamp;

  const TelemetryModel({
    this.id,
    required this.driverId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  // ── JSON Serialisation ────────────────────────────────────────────────────

  /// Parses a Supabase database row into a [TelemetryModel].
  factory TelemetryModel.fromJson(Map<String, dynamic> json) {
    return TelemetryModel(
      id: json['id'] as int?,
      driverId: json['driver_id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Converts this model to a Map for INSERTing into Supabase.
  ///
  /// Note: `id` and `timestamp` are intentionally omitted —
  /// Supabase generates them automatically (BIGSERIAL + DEFAULT now()).
  Map<String, dynamic> toInsertJson() {
    return {
      'driver_id': driverId,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  @override
  String toString() =>
      'TelemetryModel(driver: $driverId, lat: $latitude, lng: $longitude, at: $timestamp)';
}
