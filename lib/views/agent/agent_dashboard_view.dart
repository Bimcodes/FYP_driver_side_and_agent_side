// =============================================================================
// FILE: views/agent/agent_dashboard_view.dart
// LAYER: View (UI Layer)
//
// PURPOSE:
//   The Agent's main home screen — the "Digital Vault".
//   Displays the agent's token balance and recent transactions.
//   Provides navigation to the Transfer and History screens.
//
// MVVM ROLE:
//   View. Reads AgentDashboardState from AgentDashboardViewModel.
//   Contains ZERO business logic.
//
// WHAT THIS VIEW DOES:
//   1. On first build, calls ViewModel.loadDashboard(agent).
//   2. Shows a loading spinner while wallet data loads.
//   3. Once loaded, displays the balance in a large StatCard.
//   4. Shows last 3 transactions as a preview list.
//   5. Provides a "Transfer to Student" button → navigates to RetailTransferView.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../models/transaction_model.dart';
import '../../viewmodels/agent_dashboard_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../shared/primary_button.dart';
import '../shared/stat_card.dart';

/// The Agent's Digital Vault home screen.
///
/// [MVVM ROLE]: Pure View. Reads state, calls actions, renders UI.
class AgentDashboardView extends ConsumerStatefulWidget {
  const AgentDashboardView({super.key});

  @override
  ConsumerState<AgentDashboardView> createState() =>
      _AgentDashboardViewState();
}

class _AgentDashboardViewState extends ConsumerState<AgentDashboardView> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load data once when the view is first shown.
    // We use didChangeDependencies instead of initState because we need
    // access to `ref` which isn't available in initState.
    if (!_initialized) {
      _initialized = true;
      final agent = ref.read(authViewModelProvider).user;
      if (agent != null) {
        // WHY Future.microtask?
        // Riverpod does not allow modifying a provider's state DURING the
        // widget build phase (which includes didChangeDependencies on first mount).
        // Future.microtask() schedules this call to run on the NEXT event loop
        // tick — after the current build pass is complete. This is the standard
        // Riverpod pattern for triggering ViewModel actions from lifecycle methods.
        Future.microtask(() {
          if (mounted) {
            ref
                .read(agentDashboardViewModelProvider.notifier)
                .loadDashboard(agent);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the ViewModel state — rebuilds whenever state changes.
    final dashState = ref.watch(agentDashboardViewModelProvider);
    final authState = ref.watch(authViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.agentDashboardTitle),
        actions: [
          // History button
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Transaction History',
            onPressed: () => context.push(AppRoutes.agentHistory),
          ),
          // Logout button
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: AppStrings.logout,
            onPressed: () {
              ref.read(authViewModelProvider.notifier).signOut();
              context.go(AppRoutes.roleSelect);
            },
          ),
        ],
      ),
      body: dashState.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.agentPrimary),
            )
          : dashState.loadError != null
              ? _ErrorState(error: dashState.loadError!)
              : RefreshIndicator(
                  color: AppColors.agentPrimary,
                  onRefresh: () async {
                    final agent = ref.read(authViewModelProvider).user;
                    if (agent != null) {
                      await ref
                          .read(agentDashboardViewModelProvider.notifier)
                          .loadDashboard(agent);
                    }
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // ── Welcome Header ─────────────────────────────────────
                      Text(
                        'Welcome back,',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        authState.user?.name ?? 'Agent',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Balance Card ───────────────────────────────────────
                      StatCard(
                        label: AppStrings.agentBalanceLabel,
                        value: dashState.wallet != null
                            ? '₦${dashState.wallet!.balance.toStringAsFixed(2)}'
                            : '₦0.00',
                        icon: Icons.account_balance_wallet,
                        accentColor: AppColors.agentPrimary,
                        subtitle: dashState.wallet?.walletType.displayName ?? 'Agent Vault',
                      ),
                      const SizedBox(height: 16),

                      // ── Top Up Button ──────────────────────────────────────
                      OutlinedButton.icon(
                        onPressed: () => context.push(AppRoutes.topupScan),
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Top-Up via Admin QR'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.agentPrimary,
                          side: const BorderSide(color: AppColors.agentPrimary),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Transfer Button ────────────────────────────────────
                      PrimaryButton(
                        label: AppStrings.agentTransferButton,
                        gradient: AppColors.agentGradient,
                        onPressed: () => context.push(AppRoutes.agentTransfer),
                      ),
                      const SizedBox(height: 32),

                      // ── Recent Activity ────────────────────────────────────
                      const Text(
                        'Recent Activity',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (dashState.recentTransactions.isEmpty)
                        const _EmptyTransactions()
                      else
                        ...dashState.recentTransactions
                            .take(5) // Show only the 5 most recent
                            .map((tx) => _TransactionTile(transaction: tx)),
                    ],
                  ),
                ),
    );
  }
}

// ── Private Sub-Widgets ───────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String error;
  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(
        child: Text(
          'No transfers yet. Start by sending tokens to a student.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.agentSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.send, color: AppColors.agentLight, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.displayDescription,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${transaction.timestamp.day}/${transaction.timestamp.month}/${transaction.timestamp.year} · ${transaction.timestamp.hour}:${transaction.timestamp.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '-₦${transaction.amount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
