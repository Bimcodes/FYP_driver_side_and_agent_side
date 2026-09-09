// =============================================================================
// FILE: views/driver/driver_ledger_view.dart
// LAYER: View (UI Layer)
//
// PURPOSE:
//   The Driver's Daily Shift Ledger.
//   Shows total fares collected, passenger count, and expected midnight payout.
//   Provides the driver a transparent record of their earnings for the day.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../models/transaction_model.dart';
import '../../viewmodels/driver_dashboard_viewmodel.dart';
import '../shared/stat_card.dart';

/// The Driver's shift ledger — a transparent view of today's earnings.
///
/// [MVVM ROLE]: Pure View. Reads DriverDashboardState for fare data.
class DriverLedgerView extends ConsumerWidget {
  const DriverLedgerView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashState = ref.watch(driverDashboardViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.driverLedgerTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => context.go(AppRoutes.driverDashboard),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Summary Cards ─────────────────────────────────────────────────
          StatCard(
            label: AppStrings.driverExpectedPayout,
            value: '₦${dashState.expectedPayout.toStringAsFixed(2)}',
            icon: Icons.account_balance,
            accentColor: AppColors.driverPrimary,
            subtitle: 'Estimated midnight fiat transfer • 1 token = ₦1',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Total Passengers',
                  value: '${dashState.passengerCount}',
                  icon: Icons.people_alt_outlined,
                  accentColor: AppColors.driverGradientEnd,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: StatCard(
                  label: 'Tokens Collected',
                  value: dashState.tokensCollected.toStringAsFixed(0),
                  icon: Icons.toll_outlined,
                  accentColor: AppColors.driverPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // ── Payout Info ───────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.driverSurface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.driverPrimary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: const [
                Icon(Icons.info_outline, color: AppColors.driverLight, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your token balance is automatically converted to Naira at midnight '
                    'by the admin reconciliation process. 1 token = ₦1.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── Full Fare List ────────────────────────────────────────────────
          const Text(
            "Today's Fare Transactions",
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),

          if (dashState.todaysFares.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No fares collected yet today.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ),
            )
          else
            ...dashState.todaysFares.map(
              (tx) => _LedgerEntryTile(transaction: tx),
            ),
        ],
      ),
    );
  }
}

class _LedgerEntryTile extends StatelessWidget {
  final TransactionModel transaction;
  const _LedgerEntryTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fare Payment',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${transaction.timestamp.hour.toString().padLeft(2, '0')}:${transaction.timestamp.minute.toString().padLeft(2, '0')}:${transaction.timestamp.second.toString().padLeft(2, '0')} — ${transaction.timestamp.day}/${transaction.timestamp.month}/${transaction.timestamp.year}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+₦${transaction.amount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: AppColors.driverLight,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
