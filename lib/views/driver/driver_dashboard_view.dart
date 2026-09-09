// =============================================================================
// FILE: views/driver/driver_dashboard_view.dart
// LAYER: View (UI Layer)
//
// PURPOSE:
//   The Driver's Live Manifest screen.
//   Core features:
//   1. Displays real-time passenger count and tokens collected.
//   2. Flashes the ENTIRE screen green + plays chime on each boarding event.
//   3. Shows GPS active/inactive indicator.
//   4. Maintains a live list of today's boarding events.
//
// MVVM ROLE:
//   View. Reads DriverDashboardState. Calls initializeDashboard().
//   The green flash, GPS, and stream are ALL managed in the ViewModel.
//   This View only renders what the ViewModel tells it.
//
// THE GREEN FLASH:
//   When state.isFlashing == true, an AnimatedOpacity overlay covers
//   the entire screen with AppColors.boardingFlash (vivid emerald).
//   After 1.5 seconds, the ViewModel sets isFlashing = false and
//   the overlay fades out automatically.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../models/transaction_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/driver_dashboard_viewmodel.dart';
import '../shared/stat_card.dart';

/// The Driver's Live Passenger Manifest screen.
///
/// [MVVM ROLE]: Pure View. All logic is in DriverDashboardViewModel.
class DriverDashboardView extends ConsumerStatefulWidget {
  const DriverDashboardView({super.key});

  @override
  ConsumerState<DriverDashboardView> createState() =>
      _DriverDashboardViewState();
}

class _DriverDashboardViewState extends ConsumerState<DriverDashboardView> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final driver = ref.read(authViewModelProvider).user;
      if (driver != null) {
        // Defer past the build phase — same pattern as AgentDashboardView.
        // See agent_dashboard_view.dart for the full explanation.
        Future.microtask(() {
          if (mounted) {
            ref
                .read(driverDashboardViewModelProvider.notifier)
                .initializeDashboard(driver);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashState = ref.watch(driverDashboardViewModelProvider);
    final authState = ref.watch(authViewModelProvider);

    // Trigger haptic feedback whenever a boarding event fires.
    ref.listen<DriverDashboardState>(driverDashboardViewModelProvider,
        (prev, next) {
      if (next.isFlashing && !(prev?.isFlashing ?? false)) {
        // Vibrate device on boarding — tactile confirmation for the driver.
        HapticFeedback.heavyImpact();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.driverDashboardTitle,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          // Shift Ledger button
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: AppStrings.driverLedgerTitle,
            onPressed: () => context.push(AppRoutes.driverLedger),
          ),
          // Logout
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authViewModelProvider.notifier).signOut();
              context.go(AppRoutes.roleSelect);
            },
          ),
        ],
      ),
      body: dashState.isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(color: AppColors.driverPrimary),
            )
          : dashState.loadError != null
              ? Center(
                  child: Text(
                    dashState.loadError!,
                    style: const TextStyle(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                )
              : Stack(
                  children: [
                    // ── Main Content ──────────────────────────────────────────
                    ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        // Driver name + GPS status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Driver',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  authState.user?.name ?? 'Driver',
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            ),
                            // GPS Status Indicator
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: dashState.isGpsActive
                                    ? AppColors.driverSurface
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: dashState.isGpsActive
                                      ? AppColors.driverPrimary.withValues(alpha: 0.4)
                                      : AppColors.border,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Pulsing dot
                                  if (dashState.isGpsActive)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: AppColors.driverPrimary,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.driverPrimary
                                                .withValues(alpha: 0.5),
                                            blurRadius: 6,
                                          )
                                        ],
                                      ),
                                    )
                                  else
                                    const Icon(Icons.location_off,
                                        size: 10, color: AppColors.textMuted),
                                  const SizedBox(width: 6),
                                  Text(
                                    dashState.isGpsActive
                                        ? AppStrings.driverGpsActive
                                        : AppStrings.driverGpsInactive,
                                    style: TextStyle(
                                      color: dashState.isGpsActive
                                          ? AppColors.driverLight
                                          : AppColors.textMuted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // ── Stat Cards Grid ─────────────────────────────────
                        Row(
                          children: [
                            Expanded(
                              child: StatCard(
                                label: AppStrings.driverPassengerCount,
                                value: '${dashState.passengerCount}',
                                icon: Icons.people_alt_outlined,
                                accentColor: AppColors.driverPrimary,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: StatCard(
                                label: AppStrings.driverTokensCollected,
                                value:
                                    '₦${dashState.tokensCollected.toStringAsFixed(0)}',
                                icon: Icons.toll_outlined,
                                accentColor: AppColors.driverGradientEnd,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // ── Recent Boardings ────────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Recent Boardings',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                letterSpacing: 0.5,
                              ),
                            ),
                            // Live indicator dot
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: AppColors.driverPrimary,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.driverPrimary
                                            .withValues(alpha: 0.5),
                                        blurRadius: 4,
                                      )
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 5),
                                const Text(
                                  'LIVE',
                                  style: TextStyle(
                                    color: AppColors.driverPrimary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (dashState.todaysFares.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Center(
                              child: Text(
                                'Waiting for passengers to board...',
                                style: TextStyle(
                                    color: AppColors.textMuted, fontSize: 13),
                              ),
                            ),
                          )
                        else
                          ...dashState.todaysFares
                              .take(10)
                              .map((tx) => _BoardingEventTile(transaction: tx)),
                      ],
                    ),

                    // ── Green Flash Overlay ─────────────────────────────────────
                    // This AnimatedOpacity widget sits on top of everything.
                    // When isFlashing = true, it becomes visible (opacity 0.6).
                    // When isFlashing = false, it fades to invisible (opacity 0.0).
                    AnimatedOpacity(
                      opacity: dashState.isFlashing ? 0.65 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: dashState.isFlashing
                          ? Container(
                              color: AppColors.boardingFlash,
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      size: 80,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      AppStrings.driverBoardingSuccess,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
    );
  }
}

// ── Boarding Event Tile ───────────────────────────────────────────────────────

class _BoardingEventTile extends StatelessWidget {
  final TransactionModel transaction;
  const _BoardingEventTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.driverPrimary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.driverSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.person_add,
                color: AppColors.driverLight, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Passenger Boarded',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${transaction.timestamp.hour.toString().padLeft(2, '0')}:${transaction.timestamp.minute.toString().padLeft(2, '0')}:${transaction.timestamp.second.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+₦${transaction.amount.toStringAsFixed(0)}',
            style: const TextStyle(
              color: AppColors.driverLight,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
