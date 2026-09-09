// =============================================================================
// FILE: views/agent/agent_history_view.dart
// LAYER: View (UI Layer)
//
// PURPOSE:
//   Displays the Agent's full transaction history — all FARE transfers
//   they have made to students. Used as proof of transaction in disputes.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../models/transaction_model.dart';
import '../../viewmodels/agent_dashboard_viewmodel.dart';

/// Full transaction history screen for the Agent.
///
/// [MVVM ROLE]: Pure View. Reads recentTransactions from AgentDashboardViewModel.
class AgentHistoryView extends ConsumerWidget {
  const AgentHistoryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashState = ref.watch(agentDashboardViewModelProvider);
    final transactions = dashState.recentTransactions;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.agentHistoryTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => context.go(AppRoutes.agentDashboard),
        ),
      ),
      body: transactions.isEmpty
          ? const Center(
              child: Text(
                'No transactions yet.\nTransfers you make will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.textMuted, fontSize: 14, height: 1.6),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: transactions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final tx = transactions[index];
                return _HistoryTile(transaction: tx);
              },
            ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final TransactionModel transaction;
  const _HistoryTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.agentSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.send, color: AppColors.agentLight, size: 18),
          ),
          const SizedBox(width: 14),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.displayDescription,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'To: ${transaction.receiverWalletId?.substring(0, 8) ?? 'Unknown'}...',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  '${transaction.timestamp.day}/${transaction.timestamp.month}/${transaction.timestamp.year} · ${transaction.timestamp.hour.toString().padLeft(2, '0')}:${transaction.timestamp.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Amount + Status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '-₦${transaction.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: transaction.status == TransactionStatus.success
                      ? AppColors.success.withValues(alpha: 0.12)
                      : AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  transaction.status.name.toUpperCase(),
                  style: TextStyle(
                    color: transaction.status == TransactionStatus.success
                        ? AppColors.success
                        : AppColors.error,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
