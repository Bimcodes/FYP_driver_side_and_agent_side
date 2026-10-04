// =============================================================================
// FILE: views/driver/bus_selection_view.dart
// LAYER: View (UI Layer)
//
// PURPOSE:
//   Shown to the driver immediately after login, before the dashboard.
//   The driver selects which bus they are operating for their shift.
//   On selection, the app navigates to the driver dashboard.
//
// MVVM ROLE:
//   Pure View. All logic is in BusSelectionViewModel.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../viewmodels/bus_selection_viewmodel.dart';

/// Bus Selection screen — the driver picks their bus before starting their shift.
///
/// [MVVM ROLE]: Pure View. Reads BusSelectionViewModel state only.
class BusSelectionView extends ConsumerWidget {
  const BusSelectionView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busListState = ref.watch(busSelectionViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.authBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Select Your Bus',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────────
              const SizedBox(height: 8),
              const Text(
                'Which bus are you driving today?',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),

              // ── Bus List ─────────────────────────────────────────────────────
              Expanded(
                child: busListState.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.driverPrimary,
                    ),
                  ),
                  error: (err, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.error, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load buses:\n$err',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: AppColors.error, fontSize: 13),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => ref
                              .read(busSelectionViewModelProvider.notifier)
                              .refresh(),
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.driverPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  data: (buses) {
                    if (buses.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.directions_bus_outlined,
                                color: AppColors.textMuted, size: 56),
                            SizedBox(height: 16),
                            Text(
                              'No buses registered yet.\nContact your administrator.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 14),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      color: AppColors.driverPrimary,
                      onRefresh: () => ref
                          .read(busSelectionViewModelProvider.notifier)
                          .refresh(),
                      child: ListView.separated(
                        itemCount: buses.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final bus = buses[index];
                          return _BusTile(
                            bus: bus,
                            onTap: () => _selectBus(context, ref, bus),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectBus(BuildContext context, WidgetRef ref, BusInfo bus) async {
    if (bus.vaultWalletId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This bus has no linked vault. Please contact your administrator.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      await ref.read(busSelectionViewModelProvider.notifier).selectBus(bus);
      if (context.mounted) {
        context.go(AppRoutes.driverDashboard);
      }
    } catch (e) {
      if (context.mounted) {
        final errorMsg = e.toString().contains('message: "') 
          ? RegExp(r'message: "(.*?)"').firstMatch(e.toString())?.group(1) ?? 'Transaction failed'
          : e.toString();
          
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg.replaceAll('PostgrestException(message: ', '').replaceAll(')', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

// ── Bus Tile ──────────────────────────────────────────────────────────────────

class _BusTile extends StatelessWidget {
  final BusInfo bus;
  final VoidCallback onTap;

  const _BusTile({required this.bus, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.authSurface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.driverPrimary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              // Bus icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.driverSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.directions_bus_rounded,
                  color: AppColors.driverPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Bus ID
              Expanded(
                child: Text(
                  bus.id,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    fontFamily: 'monospace',
                  ),
                ),
              ),

              // Status badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: bus.isReconciled
                      ? const Color(0xFF064E3B).withValues(alpha: 0.4)
                      : AppColors.driverSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: bus.isReconciled
                        ? const Color(0xFF34D399).withValues(alpha: 0.3)
                        : AppColors.driverPrimary.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  bus.isReconciled ? 'Settled' : 'Active',
                  style: TextStyle(
                    color: bus.isReconciled
                        ? const Color(0xFF34D399)
                        : AppColors.driverLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(width: 12),
              const Icon(Icons.chevron_right,
                  color: AppColors.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
