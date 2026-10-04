// =============================================================================
// FILE: viewmodels/passenger_dashboard_viewmodel.dart
// LAYER: ViewModel (Logic Layer)
//
// PURPOSE:
//   Manages all state and business logic for the Passenger (Student) workspace:
//     1. Loads Student_Wallet from Supabase.
//     2. Subscribes to real-time WebSocket updates on the student's wallet row.
//     3. Triggers green flash animation when an Agent transfers tokens.
//     4. Manages multi-passenger fare calculation (minimum 100 tokens).
//     5. Executes silent GPS coordinate acquisition and double-entry fare payment.
//
// MVVM ROLE:
//   ViewModel — business logic and state only. No UI, no direct database queries.
// =============================================================================

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/transit_pricing.dart';
import '../core/services/location_service.dart';
import '../core/utils/app_logger.dart';
import '../models/bus_qr_payload.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';
import '../models/wallet_model.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/wallet_repository.dart';

/// UI state for the Passenger workspace.
@immutable
class PassengerDashboardState {
  final bool isLoading;
  final WalletModel? wallet;
  final List<TransactionModel> recentTransactions;
  final String? loadError;

  // ── Top-up Real-Time Notification ──────────────────────────────────────────
  final bool showTopupFlash;
  final double lastReceivedAmount;
  final bool showBoardingApproved;

  // ── Fare & Checkout State ──────────────────────────────────────────────────
  final TransitStop selectedStop;
  final int passengerCount;
  final bool isBoarding;
  final String? boardingError;
  final String? boardingSuccess;

  const PassengerDashboardState({
    this.isLoading = false,
    this.wallet,
    this.recentTransactions = const [],
    this.loadError,
    this.showTopupFlash = false,
    this.lastReceivedAmount = 0.0,
    this.showBoardingApproved = false,
    this.selectedStop = const TransitStop(
      id: 'STOP-GATE',
      name: 'Campus Main Gate',
      fareTokens: 100,
      description: 'Main Entrance & Security Hub',
    ),
    this.passengerCount = 1,
    this.isBoarding = false,
    this.boardingError,
    this.boardingSuccess,
  });

  /// Computed total fare in tokens for current stop & passenger count.
  int get calculatedFare => TransitPricing.calculateTotalFare(
        stop: selectedStop,
        passengerCount: passengerCount,
      );

  PassengerDashboardState copyWith({
    bool? isLoading,
    WalletModel? wallet,
    List<TransactionModel>? recentTransactions,
    String? loadError,
    bool clearLoadError = false,
    bool? showTopupFlash,
    double? lastReceivedAmount,
    bool? showBoardingApproved,
    TransitStop? selectedStop,
    int? passengerCount,
    bool? isBoarding,
    String? boardingError,
    bool clearBoardingError = false,
    String? boardingSuccess,
    bool clearBoardingSuccess = false,
  }) {
    return PassengerDashboardState(
      isLoading: isLoading ?? this.isLoading,
      wallet: wallet ?? this.wallet,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      loadError: clearLoadError ? null : (loadError ?? this.loadError),
      showTopupFlash: showTopupFlash ?? this.showTopupFlash,
      lastReceivedAmount: lastReceivedAmount ?? this.lastReceivedAmount,
      showBoardingApproved: showBoardingApproved ?? this.showBoardingApproved,
      selectedStop: selectedStop ?? this.selectedStop,
      passengerCount: passengerCount ?? this.passengerCount,
      isBoarding: isBoarding ?? this.isBoarding,
      boardingError:
          clearBoardingError ? null : (boardingError ?? this.boardingError),
      boardingSuccess:
          clearBoardingSuccess ? null : (boardingSuccess ?? this.boardingSuccess),
    );
  }
}

/// ViewModel coordinating the Student/Passenger user journey.
class PassengerDashboardViewModel extends Notifier<PassengerDashboardState> {
  StreamSubscription<WalletModel>? _walletSubscription;
  Timer? _flashTimer;
  Timer? _reconnectTimer;
  String? _activeSubscribedWalletId;

  @override
  PassengerDashboardState build() {
    ref.onDispose(() {
      _walletSubscription?.cancel();
      _flashTimer?.cancel();
      _reconnectTimer?.cancel();
    });
    return const PassengerDashboardState();
  }

  // ── Initialisation ─────────────────────────────────────────────────────────

  /// Loads student wallet and recent transaction history.
  Future<void> loadDashboard(UserModel student) async {
    logger.i('[PassengerVM] loadDashboard() → student: ${student.name} (${student.id})');
    state = state.copyWith(isLoading: true, clearLoadError: true);

    try {
      final walletRepo = ref.read(walletRepositoryProvider);
      final txRepo = ref.read(transactionRepositoryProvider);

      final wallet = await walletRepo.getWalletByOwnerId(student.id, createIfMissing: true);
      final history = await txRepo.getStudentTransactions(wallet.id);

      state = state.copyWith(
        isLoading: false,
        wallet: wallet,
        recentTransactions: history,
      );

      // Start listening to real-time wallet balance changes
      _subscribeToWallet(wallet.id);
    } catch (e, st) {
      logger.e('[PassengerVM] loadDashboard failed', error: e, stackTrace: st);
      state = state.copyWith(
        isLoading: false,
        loadError: 'Failed to load transit wallet: ${e.toString()}',
      );
    }
  }

  /// Subscribes to real-time WebSocket events on this student's wallet row.
  void _subscribeToWallet(String walletId) {
    _activeSubscribedWalletId = walletId;
    _walletSubscription?.cancel();
    _reconnectTimer?.cancel();

    final walletRepo = ref.read(walletRepositoryProvider);

    _walletSubscription = walletRepo.watchWallet(walletId).listen(
      (updatedWallet) {
        final currentBalance = state.wallet?.balance ?? 0.0;
        final newBalance = updatedWallet.balance;

        logger.i('[PassengerVM] Realtime wallet update: ₦$currentBalance → ₦$newBalance');

        // Trigger green flash if balance increased (top-up received from Agent)
        if (newBalance > currentBalance && state.wallet != null) {
          final diff = newBalance - currentBalance;
          logger.i('[PassengerVM] 🟢 Token top-up detected! Received: +₦$diff');

          _flashTimer?.cancel();
          state = state.copyWith(
            wallet: updatedWallet,
            showTopupFlash: true,
            lastReceivedAmount: diff,
          );

          _flashTimer = Timer(const Duration(milliseconds: 2500), () {
            state = state.copyWith(showTopupFlash: false);
          });
        } else {
          state = state.copyWith(wallet: updatedWallet);
        }
      },
      onError: (err) {
        logger.w('[PassengerVM] Wallet realtime stream transient error: $err');
        // Schedule auto-reconnect after 5 seconds for transient TLS/socket drops
        _reconnectTimer?.cancel();
        _reconnectTimer = Timer(const Duration(seconds: 5), () {
          if (_activeSubscribedWalletId == walletId) {
            logger.i('[PassengerVM] Auto-reconnecting realtime wallet subscription...');
            _subscribeToWallet(walletId);
          }
        });
      },
    );
  }

  // ── Fare & Stop Configuration ──────────────────────────────────────────────

  /// Updates the passenger's chosen destination stop.
  void setDestination(TransitStop stop) {
    state = state.copyWith(selectedStop: stop);
  }

  /// Increments passenger ticket count.
  void incrementPassengers() {
    if (state.passengerCount < 10) {
      state = state.copyWith(passengerCount: state.passengerCount + 1);
    }
  }

  /// Decrements passenger ticket count (minimum 1).
  void decrementPassengers() {
    if (state.passengerCount > 1) {
      state = state.copyWith(passengerCount: state.passengerCount - 1);
    }
  }

  /// Directly sets the passenger ticket count.
  void setPassengerCount(int count) {
    final valid = count.clamp(1, 10);
    state = state.copyWith(passengerCount: valid);
  }

  /// Clears any pending error or success alerts.
  void clearBoardingAlerts() {
    state = state.copyWith(
      clearBoardingError: true,
      clearBoardingSuccess: true,
    );
  }

  // ── Board Bus Execution ───────────────────────────────────────────────────

  /// Executes double-entry fare payment, silent GPS acquisition, and
  /// transaction logging upon bus QR scan confirmation.
  Future<bool> processBoarding({required BusQrPayload busPayload, required String pin}) async {
    final studentWallet = state.wallet;
    if (studentWallet == null) {
      state = state.copyWith(boardingError: 'Wallet not loaded. Please try again.');
      return false;
    }

    final totalFare = state.calculatedFare.toDouble();
    if (studentWallet.balance < totalFare) {
      state = state.copyWith(
        boardingError:
            'Insufficient balance. Required: ₦${totalFare.toStringAsFixed(0)} tokens, Available: ₦${studentWallet.balance.toStringAsFixed(0)} tokens.',
      );
      return false;
    }

    logger.i(
      '[PassengerVM] processBoarding() → Bus: ${busPayload.vehicleId} | '
      'Stop: ${state.selectedStop.name} | Passengers: ${state.passengerCount} | Fare: ₦$totalFare',
    );

    state = state.copyWith(
      isBoarding: true,
      clearBoardingError: true,
      clearBoardingSuccess: true,
    );

    try {
      final coords = await ref.read(locationServiceProvider).getCurrentPosition();
      final txRepo = ref.read(transactionRepositoryProvider);
      final walletRepo = ref.read(walletRepositoryProvider);

      await txRepo.payFare(
        busVaultId: busPayload.busVaultId,
        stopId: state.selectedStop.id,
        passengers: state.passengerCount,
        pin: pin,
        lat: coords?.latitude,
        lng: coords?.longitude,
      );

      final updatedStudentWallet = await walletRepo.getWalletById(studentWallet.id);
      final history = await txRepo.getStudentTransactions(studentWallet.id);

      logger.i('[PassengerVM] ✅ Boarding approved');

      _flashTimer?.cancel();
      state = state.copyWith(
        isBoarding: false,
        wallet: updatedStudentWallet,
        recentTransactions: history,
        showBoardingApproved: true,
        boardingSuccess:
            'Boarding confirmed for ${state.passengerCount} passenger(s) on ${busPayload.vehicleId}!',
      );

      _flashTimer = Timer(const Duration(seconds: 4), () {
        state = state.copyWith(showBoardingApproved: false);
      });

      return true;
    } catch (e, st) {
      logger.e('[PassengerVM] processBoarding failed', error: e, stackTrace: st);
      // Display the actual error message from Postgres (e.g. 'Incorrect PIN')
      final errorMsg = e.toString().contains('message: "') 
          ? RegExp(r'message: "(.*?)"').firstMatch(e.toString())?.group(1) ?? 'Transaction failed'
          : e.toString();
          
      state = state.copyWith(
        isBoarding: false,
        boardingError: errorMsg.replaceAll('PostgrestException(message: ', '').replaceAll(')', ''),
      );
      return false;
    }
  }
}

// ── Riverpod Provider ────────────────────────────────────────────────────────

/// Provides the [PassengerDashboardViewModel] to the widget tree.
final passengerDashboardViewModelProvider = NotifierProvider<
    PassengerDashboardViewModel, PassengerDashboardState>(
  PassengerDashboardViewModel.new,
);
