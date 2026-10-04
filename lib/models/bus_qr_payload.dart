// =============================================================================
// FILE: models/bus_qr_payload.dart
// LAYER: Model (Data Layer)
//
// PURPOSE:
//   Represents and parses the structured JSON payload embedded in vehicle QR
//   codes mounted inside campus transit buses.
//
// EXPECTED JSON FORMAT:
//   {
//     "type": "BUS_BOARDING",
//     "vehicle_id": "BUS-001",
//     "route_name": "Campus Main Loop",
//     "bus_vault_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
//     "base_fare": 100
//   }
// =============================================================================

import 'dart:convert';

class BusQrPayload {
  final String type;
  final String vehicleId;
  final String routeName;
  final String busVaultId;
  final int baseFare;

  const BusQrPayload({
    required this.type,
    required this.vehicleId,
    required this.routeName,
    required this.busVaultId,
    required this.baseFare,
  });

  factory BusQrPayload.fromJson(Map<String, dynamic> json) {
    return BusQrPayload(
      type: json['type'] as String? ?? '',
      vehicleId: json['vehicle_id'] as String? ?? '',
      routeName: json['route_name'] as String? ?? 'Campus Transit',
      busVaultId: json['bus_vault_id'] as String? ?? '',
      baseFare: (json['base_fare'] as num?)?.toInt() ?? 100,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'vehicle_id': vehicleId,
        'route_name': routeName,
        'bus_vault_id': busVaultId,
        'base_fare': baseFare,
      };

  /// Safely attempts to parse a raw QR code string.
  ///
  /// Returns `null` if the string is not valid JSON, or if it doesn't match
  /// the expected `BUS_BOARDING` schema.
  static BusQrPayload? tryParse(String raw) {
    try {
      final trimmed = raw.trim();
      if (!trimmed.startsWith('{') || !trimmed.endsWith('}')) {
        return null;
      }
      final decoded = jsonDecode(trimmed);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final payload = BusQrPayload.fromJson(decoded);
      if (payload.type != 'BUS_BOARDING' ||
          payload.vehicleId.isEmpty ||
          payload.busVaultId.isEmpty) {
        return null;
      }
      return payload;
    } catch (_) {
      return null;
    }
  }
}
