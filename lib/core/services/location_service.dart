// =============================================================================
// FILE: core/services/location_service.dart
// LAYER: Core / Services
//
// PURPOSE:
//   Wraps the `geolocator` plugin into a clean service class.
//   The Driver's ViewModel calls this service — it never calls geolocator
//   directly. This separation means:
//   - If we swap geolocator for another plugin, only this file changes.
//   - We can mock this service in tests to return fake coordinates.
//
// PERMISSIONS FLOW:
//   Android requires the user to grant ACCESS_FINE_LOCATION at runtime.
//   iOS requires NSLocationWhenInUseUsageDescription in Info.plist.
//   This service checks and requests those permissions before locating.
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Represents a latitude/longitude coordinate pair.
///
/// Simple value object — carries GPS data between layers.
class LatLng {
  /// Latitude in decimal degrees (e.g., 6.5244 for Lagos).
  final double latitude;

  /// Longitude in decimal degrees (e.g., 3.3792 for Lagos).
  final double longitude;

  const LatLng({required this.latitude, required this.longitude});

  @override
  String toString() => 'LatLng($latitude, $longitude)';
}

/// Service that wraps the geolocator plugin for GPS coordinate retrieval.
///
/// [MVVM ROLE]: This is a Service — it lives in the Core layer and is
/// used by the ViewModel. It is NOT a Repository (it doesn't touch Supabase)
/// and it is NOT a ViewModel (it holds no app state).
class LocationService {
  /// Checks location permissions and returns the device's current coordinates.
  ///
  /// Returns [null] if the user denies permission or if location services
  /// are disabled on the device.
  ///
  /// The ViewModel calls this in a Timer loop every 5 seconds.
  Future<LatLng?> getCurrentPosition() async {
    // Step 1: Check if location services are enabled in device settings.
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are off in device settings. Cannot proceed.
      return null;
    }

    // Step 2: Check current permission status.
    LocationPermission permission = await Geolocator.checkPermission();

    // Step 3: If permission has never been asked, request it now.
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // User denied the permission request. Cannot proceed.
        return null;
      }
    }

    // Step 4: If permission is permanently denied, we cannot even ask again.
    if (permission == LocationPermission.deniedForever) {
      // The user must manually enable this in device Settings.
      return null;
    }

    // Step 5: Permissions are granted — get the position.
    // LocationAccuracy.high uses GPS hardware for best accuracy.
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    return LatLng(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }
}

// ── Riverpod Provider ────────────────────────────────────────────────────────

/// Provides the [LocationService] to any Riverpod consumer.
///
/// The DriverDashboardViewModel reads this provider to get GPS coordinates.
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});
