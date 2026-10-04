// =============================================================================
// FILE: viewmodels/driver_dashboard_viewmodel.dart
// LAYER: ViewModel (Logic Layer)
//
// PURPOSE:
//   Manages all state and logic for the Driver's workspace.
//   This is the most complex ViewModel in the app — it coordinates:
//     1. Loading the Driver's Bus_Vault wallet from Supabase.
//     2. Subscribing to a real-time Stream for incoming boarding events.
//     3. Running a background Timer that broadcasts GPS coordinates every 5s.
//     4. Managing the green-flash animation trigger state.
//
// MVVM ROLE:
//   ViewModel — business logic and state only. No UI, no direct DB calls.
//
// THE REAL-TIME BOARDING EVENT FLOW:
//   When a student pays a fare (via QR scan scenario — future phase):
//   1. A FARE transaction is INSERTed into Supabase `transactions` table.
//   2. Supabase Realtime pushes this row to all active WebSocket subscribers.
//   3. This ViewModel's stream listener receives the transaction.
//   4. ViewModel sets isFlashing = true, increments passengerCount.
//   5. DriverDashboardView sees isFlashing = true → shows green overlay.
//   6. ViewModel sets a 1.5-second timer to reset isFlashing = false.
//   7. The green overlay fades out. Screen returns to normal.
//
// THE GPS LOOP:
//   On mount:
//     - Timer.periodic(5 seconds) starts.
//   Every 5 seconds:
//     - LocationService.getCurrentPosition() is called.
//     - If coordinates returned, TelemetryRepository.broadcastLocation() fires.
//   On logout / dispose:
//     - Timer is cancelled. Stream subscription is cancelled.
//     - No memory leaks or background battery drain.
// =============================================================================

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/audio_service.dart';
import '../core/services/location_service.dart';
import '../core/utils/app_logger.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';
import '../models/wallet_model.dart';
import '../repositories/telemetry_repository.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/wallet_repository.dart';
import 'bus_selection_viewmodel.dart';

/// Complete state for the Driver's workspace.
class DriverDashboardState {
  /// True while the initial wallet data is loading.
  final bool isLoading;

  /// The Driver's Bus_Vault wallet.
  final WalletModel? wallet;

  /// Error message if the dashboard fails to load.
  final String? loadError;

  /// Total passengers boarded today (incremented on each boarding event).
  final int passengerCount;

  /// Total tokens collected today (sum of all FARE amounts received).
  final double tokensCollected;

  /// True for 1.5 seconds when a new boarding event arrives.
  /// The View uses this to trigger the green flash animation.
  final bool isFlashing;

  /// True when the GPS timer is active and broadcasting.
  final bool isGpsActive;

  /// All fare transactions received today (for the Ledger view).
  final List<TransactionModel> todaysFares;

  const DriverDashboardState({
    this.isLoading = false,
    this.wallet,
    this.loadError,
    this.passengerCount = 0,
    this.tokensCollected = 0.0,
    this.isFlashing = false,
    this.isGpsActive = false,
    this.todaysFares = const [],
  });

  DriverDashboardState copyWith({
    bool? isLoading,
    WalletModel? wallet,
    String? loadError,
    bool clearLoadError = false,
    int? passengerCount,
    double? tokensCollected,
    bool? isFlashing,
    bool? isGpsActive,
    List<TransactionModel>? todaysFares,
  }) {
    return DriverDashboardState(
      isLoading: isLoading ?? this.isLoading,
      wallet: wallet ?? this.wallet,
      loadError: clearLoadError ? null : (loadError ?? this.loadError),
      passengerCount: passengerCount ?? this.passengerCount,
      tokensCollected: tokensCollected ?? this.tokensCollected,
      isFlashing: isFlashing ?? this.isFlashing,
      isGpsActive: isGpsActive ?? this.isGpsActive,
      todaysFares: todaysFares ?? this.todaysFares,
    );
  }

  /// The expected midnight payout in Naira (1 token = ₦1 equivalent).
  double get expectedPayout => tokensCollected;
}

/// ViewModel for the Driver's Live Manifest and Shift Ledger.
///
/// [MVVM ROLE]: ViewModel — the most active class in the app.
/// It manages both a Timer (GPS loop) and a Stream (boarding events).
///
/// Connected to:
///   - [WalletRepository]: reads driver's Bus_Vault balance
///   - [TransactionRepository]: subscribes to boarding event stream
///   - [TelemetryRepository]: inserts GPS coordinates
///   - [LocationService]: reads device GPS hardware
///   - [AudioService]: plays boarding chime
class DriverDashboardViewModel extends Notifier<DriverDashboardState> {
  /// The Dart periodic timer that fires the GPS broadcast every 5 seconds.
  Timer? _gpsTimer;

  /// The Supabase Realtime stream subscription for boarding events.
  StreamSubscription<TransactionModel>? _boardingSubscription;

  /// A one-shot timer that resets the green flash after 1.5 seconds.
  Timer? _flashResetTimer;

  @override
  DriverDashboardState build() {
    // Register a dispose callback — called when this ViewModel is destroyed.
    // This is critical: without this, the GPS timer and stream subscription
    // would continue running even after the driver logs out.
    ref.onDispose(_cleanup);

    return const DriverDashboardState();
  }

  // ── Initialisation ─────────────────────────────────────────────────────────

  /// The time this driver's shift started (to filter fares to just this session).
  DateTime? _shiftStartTime;

  /// Loads the selected bus vault, starts the GPS timer, and subscribes to boarding events.
  ///
  /// Called by DriverDashboardView when it first mounts.
  /// Takes [driver] from the AuthViewModel's state (the logged-in user).
  Future<void> initializeDashboard(UserModel driver) async {
    logger.i('[DriverViewModel] initializeDashboard() → driver: ${driver.name} (${driver.id})');
    state = state.copyWith(isLoading: true, clearLoadError: true);

    try {
      final selectedBus = ref.read(selectedBusProvider);
      if (selectedBus == null) {
        throw Exception('No bus selected for this shift. Please select a bus first.');
      }

      final walletRepo = ref.read(walletRepositoryProvider);
      final txRepo = ref.read(transactionRepositoryProvider);

      logger.d('[DriverViewModel] Fetching Bus_Vault wallet ${selectedBus.vaultWalletId}...');
      final wallet = await walletRepo.getWalletById(selectedBus.vaultWalletId);
      if (wallet == null) {
        throw Exception('Selected bus has no valid vault wallet.');
      }

      // Record the shift start time if not already set (e.g. from hot reload or navigating away and back)
      _shiftStartTime ??= DateTime.now();

      logger.d('[DriverViewModel] Fetching shift fares for vault: ${wallet.id} since $_shiftStartTime');
      final allRecentFares = await txRepo.getTransactionsByReceiverWallet(wallet.id);
      
      // Option A: Only show passengers that boarded during THIS driver's shift
      final shiftFares = allRecentFares.where((tx) => tx.timestamp.isAfter(_shiftStartTime!)).toList();

      final totalTokens = shiftFares.fold<double>(0.0, (sum, tx) => sum + tx.amount);

      logger.i('[DriverViewModel] ✅ Dashboard initialised — shift fares: ${shiftFares.length} | tokens: ₦$totalTokens');
      state = state.copyWith(
        isLoading: false,
        wallet: wallet,
        todaysFares: shiftFares,
        passengerCount: shiftFares.length,
        tokensCollected: totalTokens,
      );

      logger.d('[DriverViewModel] Starting boarding event stream and GPS loop...');
      _startBoardingStream(wallet.id);
      // We still broadcast the driver's ID for telemetry, not the bus ID.
      _startGpsLoop(driver.id);

    } catch (e, st) {
      logger.e('[DriverViewModel] initializeDashboard failed', error: e, stackTrace: st);
      state = state.copyWith(
        isLoading: false,
        loadError: 'Failed to initialize dashboard: ${e.toString()}',
      );
    }
  }

  // ── Real-Time Boarding Stream ───────────────────────────────────────────────

  /// Subscribes to the Supabase Realtime channel for incoming fare transactions.
  ///
  /// Every time a student pays a fare crediting this driver's Bus_Vault,
  /// Supabase pushes the transaction over WebSocket and [_onBoardingEvent] fires.
  void _startBoardingStream(String driverWalletId) {
    logger.i('[DriverViewModel] _startBoardingStream() → subscribing to wallet: $driverWalletId');
    final txRepo = ref.read(transactionRepositoryProvider);
    _boardingSubscription = txRepo
        .watchBoardingEvents(driverWalletId)
        .listen(_onBoardingEvent);
  }

  /// Called by the stream listener every time a new boarding event arrives.
  ///
  /// This is where the green flash, chime, and counter update happen.
  void _onBoardingEvent(TransactionModel transaction) {
    logger.i('🟢 [DriverViewModel] Boarding event! amount: ₦${transaction.amount} | txId: ${transaction.id}');

    ref.read(audioServiceProvider).playBoardingChime();

    state = state.copyWith(
      isFlashing: true,
      passengerCount: state.passengerCount + 1,
      tokensCollected: state.tokensCollected + transaction.amount,
      todaysFares: [transaction, ...state.todaysFares],
    );

    _flashResetTimer?.cancel();
    _flashResetTimer = Timer(const Duration(milliseconds: 1500), () {
      state = state.copyWith(isFlashing: false);
      logger.d('[DriverViewModel] Flash reset — screen returned to normal');
    });
  }

  // ── GPS Broadcast Loop ──────────────────────────────────────────────────────

  /// Starts a Timer that fires every 5 seconds to broadcast the driver's GPS location.
  ///
  /// Uses Dart's Timer.periodic() — a built-in repeating timer.
  /// The callback runs _broadcastGpsLocation() each time.
  void _startGpsLoop(String driverId) {
    state = state.copyWith(isGpsActive: true);

    _gpsTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _broadcastGpsLocation(driverId),
    );
  }

  /// Gets the current GPS position and inserts it into the `telemetry` table.
  ///
  /// If location is unavailable (permissions denied, GPS off), silently skips.
  Future<void> _broadcastGpsLocation(String driverId) async {
    // WHY try/catch here?
    // The GPS permission is declared in the manifest, but the user may still
    // DENY the runtime permission prompt on first launch. Without this catch,
    // geolocator throws an unhandled exception that crashes the app every 5s.
    // We log the problem and suppress the crash — the GPS indicator in the UI
    // will show inactive, making the issue visible without killing the session.
    try {
      final locationService = ref.read(locationServiceProvider);
      final telemetryRepo = ref.read(telemetryRepositoryProvider);

      final position = await locationService.getCurrentPosition();

      if (position == null) {
        logger.w('[DriverViewModel] GPS unavailable — skipping telemetry broadcast');
        if (state.isGpsActive) state = state.copyWith(isGpsActive: false);
        return;
      }

      logger.d('[DriverViewModel] GPS tick → lat: ${position.latitude.toStringAsFixed(5)} | lng: ${position.longitude.toStringAsFixed(5)}');
      await telemetryRepo.broadcastLocation(
        driverId: driverId,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (!state.isGpsActive) state = state.copyWith(isGpsActive: true);

    } catch (e) {
      // Log the error but DO NOT rethrow — a GPS failure must never crash the app.
      logger.w('[DriverViewModel] GPS broadcast error (non-fatal): $e');
      if (state.isGpsActive) state = state.copyWith(isGpsActive: false);
    }
  }

  // ── Cleanup ────────────────────────────────────────────────────────────────

  /// Cancels all active timers and stream subscriptions.
  ///
  /// Called automatically by Riverpod when this ViewModel is disposed
  /// (e.g., when the driver navigates away or logs out).
  ///
  /// IMPORTANT: Without this, the GPS timer would keep running in the
  /// background indefinitely, draining battery.
  void _cleanup() {
    logger.i('[DriverViewModel] _cleanup() — cancelling GPS timer, stream subscription, and flash timer');
    _gpsTimer?.cancel();
    _boardingSubscription?.cancel();
    _flashResetTimer?.cancel();
    logger.i('[DriverViewModel] ✅ All background tasks stopped');
  }
}

// ── Riverpod Provider ────────────────────────────────────────────────────────

/// Provides the [DriverDashboardViewModel] and [DriverDashboardState] to Views.
final driverDashboardViewModelProvider =
    NotifierProvider<DriverDashboardViewModel, DriverDashboardState>(
  DriverDashboardViewModel.new,
);
