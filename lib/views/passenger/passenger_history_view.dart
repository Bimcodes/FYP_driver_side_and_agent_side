import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../viewmodels/passenger_dashboard_viewmodel.dart';

class PassengerHistoryView extends ConsumerStatefulWidget {
  const PassengerHistoryView({super.key});

  @override
  ConsumerState<PassengerHistoryView> createState() => _PassengerHistoryViewState();
}

class _PassengerHistoryViewState extends ConsumerState<PassengerHistoryView> {
  int _filterIndex = 0; // 0: All Activity, 1: Bus Rides, 2: Top-Ups

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(passengerDashboardViewModelProvider);
    final walletId = state.wallet?.id;

    final filteredList = state.recentTransactions.where((tx) {
      if (_filterIndex == 1) {
        return tx.senderWalletId == walletId; // Rides (Debits)
      } else if (_filterIndex == 2) {
        return tx.receiverWalletId == walletId; // Top-ups (Credits)
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.agentLightBackground, // Light theme from mockup
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title ─────────────────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                'LEDGER',
                style: TextStyle(color: AppColors.agentTextDark, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1.0),
              ),
            ),

            // ── Filter Chips ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  _buildFilterChip('All Activity', 0),
                  const SizedBox(width: 10),
                  _buildFilterChip('Bus Rides', 1),
                  const SizedBox(width: 10),
                  _buildFilterChip('Top-Ups', 2),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── Transactions / Empty State ─────────────────────────────────────
            Expanded(
              child: filteredList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: const BoxDecoration(
                              color: Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.receipt_long_outlined, color: AppColors.agentTextLight, size: 56),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No transactions found for this filter.',
                            style: TextStyle(color: AppColors.agentTextLight, fontSize: 15, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final tx = filteredList[index];
                        final isDebit = tx.senderWalletId == walletId;

                        final title = isDebit ? 'Route 102 Boarding' : 'Ticket Agent Top-up';
                        final iconData = isDebit ? Icons.directions_bus_outlined : Icons.credit_card_outlined;
                        final iconBg = isDebit ? AppColors.agentRedArrow : AppColors.agentGreenArrow;
                        final iconColor = isDebit ? AppColors.agentRedText : AppColors.agentGreenText;
                        final amountColor = isDebit ? AppColors.agentRedText : AppColors.agentGreenText;
                        final sign = isDebit ? '-' : '+';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.agentCardWhite,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                                child: Icon(iconData, color: iconColor, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(color: AppColors.agentTextDark, fontWeight: FontWeight.w700, fontSize: 15),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${tx.timestamp.day}/${tx.timestamp.month}/${tx.timestamp.year} · ${tx.timestamp.hour.toString().padLeft(2, '0')}:${tx.timestamp.minute.toString().padLeft(2, '0')}',
                                      style: const TextStyle(color: AppColors.agentTextLight, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '$sign₦${tx.amount.toStringAsFixed(0)}',
                                style: TextStyle(color: amountColor, fontWeight: FontWeight.w800, fontSize: 16),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int index) {
    final isSelected = _filterIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _filterIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.authPrimary : AppColors.agentCardWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.authPrimary : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.agentTextLight,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
