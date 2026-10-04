import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../models/transaction_model.dart';
import '../../viewmodels/agent_dashboard_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'agent_main_view.dart';

class AgentDashboardView extends ConsumerStatefulWidget {
  const AgentDashboardView({super.key});

  @override
  ConsumerState<AgentDashboardView> createState() => _AgentDashboardViewState();
}

class _AgentDashboardViewState extends ConsumerState<AgentDashboardView> {
  bool _initialized = false;
  bool _isBalanceVisible = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final agent = ref.read(authViewModelProvider).user;
      if (agent != null) {
        Future.microtask(() {
          if (mounted) {
            ref.read(agentDashboardViewModelProvider.notifier).loadDashboard(agent);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashState = ref.watch(agentDashboardViewModelProvider);
    final authState = ref.watch(authViewModelProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.agentLightBackground,
      body: SafeArea(
        child: dashState.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.agentBlue))
          : dashState.loadError != null
              ? _ErrorState(error: dashState.loadError!)
              : RefreshIndicator(
                  color: AppColors.agentBlue,
                  onRefresh: () async {
                    if (user != null) {
                      await ref.read(agentDashboardViewModelProvider.notifier).loadDashboard(user);
                    }
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // ── Welcome Header with Avatar ─────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Welcome back,',
                                style: TextStyle(color: AppColors.agentTextLight, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                              Text(
                                user?.name ?? 'Agent',
                                style: const TextStyle(color: AppColors.agentTextDark, fontSize: 20, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.agentBlue,
                            child: Text(
                              user?.name.isNotEmpty == true 
                                  ? user!.name.split(' ').map((e) => e[0]).take(2).join().toUpperCase() 
                                  : 'A',
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── Token Wallet Card ──────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.agentCardWhite,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.agentBlueBorder, width: 1.5),
                          boxShadow: [
                            BoxShadow(color: AppColors.agentBlue.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'MY TOKEN WALLET',
                                  style: TextStyle(color: AppColors.agentTextLight, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                                ),
                                GestureDetector(
                                  onTap: () => setState(() => _isBalanceVisible = !_isBalanceVisible),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.agentBlueBorder),
                                    ),
                                    child: Icon(
                                      _isBalanceVisible ? Icons.visibility : Icons.visibility_off,
                                      color: AppColors.agentBlue,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              dashState.wallet != null
                                  ? _isBalanceVisible ? '₦${dashState.wallet!.balance.toStringAsFixed(2)}' : '₦****'
                                  : '₦0.00',
                              style: const TextStyle(color: AppColors.agentTextDark, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Primary balance for student token top-ups and transfers.',
                              style: TextStyle(color: AppColors.agentTextLight, fontSize: 13, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Top Up via Admin QR ────────────────────────────────
                      GestureDetector(
                        onTap: () => context.push(AppRoutes.topupScan),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.agentCardWhite,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: AppColors.agentGreenText.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.qr_code_scanner, color: AppColors.agentGreenText, size: 22),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text('Top-Up via Admin QR', style: TextStyle(color: AppColors.agentTextDark, fontSize: 15, fontWeight: FontWeight.w700)),
                                    SizedBox(height: 2),
                                    Text('Receive funds from an admin QR code.', style: TextStyle(color: AppColors.agentTextLight, fontSize: 12)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: AppColors.agentTextLight, size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Transfer to Student ────────────────────────────────
                      GestureDetector(
                        onTap: () => context.push(AppRoutes.agentTransfer),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.agentBlue,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: AppColors.agentBlue.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 6))],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.arrow_forward, color: Colors.white, size: 22),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Transfer to Student', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 2),
                                    Text('Send tokens to a student account.', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: Colors.white, size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── Recent Activity Header ─────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent Activity',
                            style: TextStyle(color: AppColors.agentTextDark, fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          if (dashState.recentTransactions.isNotEmpty)
                            GestureDetector(
                              onTap: () => ref.read(agentTabIndexProvider.notifier).state = 2, // 2 is Ledger
                              child: const Text('View All', style: TextStyle(color: AppColors.agentBlue, fontSize: 13, fontWeight: FontWeight.w600)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Recent Activity List ───────────────────────────────
                      if (dashState.recentTransactions.isEmpty)
                        const _EmptyTransactions()
                      else
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.agentCardWhite,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
                          ),
                          child: Column(
                            children: dashState.recentTransactions.take(5).toList().asMap().entries.map((entry) {
                              final int idx = entry.key;
                              final tx = entry.value;
                              final isLast = idx == (dashState.recentTransactions.length > 5 ? 4 : dashState.recentTransactions.length - 1);
                              return Column(
                                children: [
                                  _TransactionTile(transaction: tx),
                                  if (!isLast) const Divider(height: 1, color: Color(0xFFE2E8F0), indent: 16, endIndent: 16),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
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
            Text(error, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.agentTextLight)),
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
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      decoration: BoxDecoration(
        color: AppColors.agentCardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9), // Light gray circle
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.folder_outlined, color: AppColors.agentTextLight, size: 28),
            ),
            const SizedBox(height: 16),
            const Text('No transfers yet', style: TextStyle(color: AppColors.agentTextDark, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text(
              'Start by sending tokens to a student.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.agentTextLight, fontSize: 13),
            ),
          ],
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
    // If it's a wholesale transaction (admin -> agent), it's inbound
    final isInbound = transaction.type == TransactionType.wholesale;
    
    final iconBgColor = isInbound ? AppColors.agentGreenArrow : AppColors.agentRedArrow;
    final iconColor = isInbound ? AppColors.agentGreenText : AppColors.agentRedText;
    final iconData = isInbound ? Icons.arrow_downward : Icons.arrow_upward;
    
    final title = isInbound ? 'Admin Top-Up' : 'Student Transfer';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
            child: Transform.rotate(
              angle: isInbound ? 0.785398 : 0.785398, // 45 degrees
              child: Icon(iconData, color: iconColor, size: 18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: AppColors.agentTextDark, fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  '${transaction.timestamp.day.toString().padLeft(2,'0')}/${transaction.timestamp.month.toString().padLeft(2,'0')}/${transaction.timestamp.year} · ${transaction.timestamp.hour.toString().padLeft(2,'0')}:${transaction.timestamp.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: AppColors.agentTextLight, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            isInbound ? '+₦${transaction.amount.toStringAsFixed(2)}' : '-₦${transaction.amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: isInbound ? AppColors.agentGreenText : AppColors.agentRedText,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
