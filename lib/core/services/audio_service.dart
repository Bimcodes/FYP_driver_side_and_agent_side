// =============================================================================
// FILE: core/services/audio_service.dart
// LAYER: Core / Services
//
// PURPOSE:
//   Placeholder service for playing the boarding success chime.
//   Currently does nothing — the audio asset will be added later.
//
//   When the audio file is ready:
//   1. Add the .mp3 file to assets/audio/boarding_success.mp3
//   2. Uncomment the pubspec.yaml asset entry
//   3. Uncomment the audioplayers code below
//
// HOW IT CONNECTS:
//   DriverDashboardViewModel calls audioService.playBoardingChime()
//   every time a new boarding transaction is received from Supabase.
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

// import 'package:audioplayers/audioplayers.dart'; // Uncomment when asset is ready

/// Service that plays audio feedback for the Driver's boarding events.
///
/// [MVVM ROLE]: Core Service — not a repository, not a viewmodel.
/// It is a side-effect executor called by the ViewModel.
class AudioService {
  // final AudioPlayer _player = AudioPlayer(); // Uncomment when asset is ready

  /// Plays the boarding success chime.
  ///
  /// Currently a no-op placeholder. The visual flash effect still works.
  /// Uncomment the audioplayers implementation below when the .mp3 is added.
  Future<void> playBoardingChime() async {
    // TODO: Uncomment when assets/audio/boarding_success.mp3 is added:
    // await _player.play(AssetSource('audio/boarding_success.mp3'));

    // Placeholder: do nothing for now.
    return;
  }

  /// Releases audio player resources.
  ///
  /// Call this when the Driver logs out or the app goes to background.
  Future<void> dispose() async {
    // await _player.dispose(); // Uncomment when asset is ready
  }
}

// ── Riverpod Provider ────────────────────────────────────────────────────────

/// Provides the [AudioService] to Riverpod consumers.
///
/// The DriverDashboardViewModel reads this to trigger chime playback.
final audioServiceProvider = Provider<AudioService>((ref) {
  return AudioService();
});
