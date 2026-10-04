// =============================================================================
// FILE: viewmodels/bus_selection_viewmodel.dart
// LAYER: ViewModel (Logic Layer)
//
// PURPOSE:
//   Manages state for the Bus Selection screen.
//   Fetches all buses from Supabase and holds the driver's chosen bus
//   for the current shift.
//
// TWO PROVIDERS:
//   1. busSelectionViewModelProvider — AsyncNotifier that loads the bus list
//   2. selectedBusProvider           — StateProvider holding the chosen BusInfo
//                                      (read by DriverDashboardViewModel)
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/app_logger.dart';
import '../repositories/fleet_repository.dart';

export '../repositories/fleet_repository.dart' show BusInfo;

// ── Selected Bus Provider ────────────────────────────────────────────────────

/// Holds the bus the driver has selected for their current shift.
///
/// null = no bus selected yet (driver is on the selection screen).
/// Set by BusSelectionView when the driver taps a bus.
/// Read by DriverDashboardViewModel to know which vault to subscribe to.
final selectedBusProvider = StateProvider<BusInfo?>((ref) => null);

// ── Bus List ViewModel ───────────────────────────────────────────────────────

/// Loads all registered buses for the selection screen.
///
/// [MVVM ROLE]: ViewModel — fetches data, holds loading/error state.
/// No UI, no direct Supabase calls (those are in FleetRepository).
class BusSelectionViewModel extends AsyncNotifier<List<BusInfo>> {
  @override
  Future<List<BusInfo>> build() async {
    return _fetchBuses();
  }

  Future<List<BusInfo>> _fetchBuses() async {
    logger.i('[BusSelectionViewModel] Loading bus list...');
    final repo = ref.read(fleetRepositoryProvider);
    final buses = await repo.getBuses();
    logger.i('[BusSelectionViewModel] ✅ ${buses.length} buses loaded');
    return buses;
  }

  /// Refreshes the bus list (e.g. on pull-to-refresh).
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchBuses);
  }

  /// Called when the driver taps a bus.
  /// Claims the bus in the database, then stores the selection.
  Future<void> selectBus(BusInfo bus) async {
    logger.i('[BusSelectionViewModel] Driver attempting to claim bus: ${bus.id}');
    final repo = ref.read(fleetRepositoryProvider);
    await repo.claimBus(bus.id);
    
    logger.i('[BusSelectionViewModel] Driver successfully claimed bus: ${bus.id} | vault: ${bus.vaultWalletId}');
    ref.read(selectedBusProvider.notifier).state = bus;
  }
}

// ── Riverpod Provider ────────────────────────────────────────────────────────

final busSelectionViewModelProvider =
    AsyncNotifierProvider<BusSelectionViewModel, List<BusInfo>>(
  BusSelectionViewModel.new,
);
