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
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../models/transaction_model.dart';
import '../../viewmodels/agent_dashboard_viewmodel.dart';

class AgentHistoryView extends ConsumerStatefulWidget {
  const AgentHistoryView({super.key});

  @override
  ConsumerState<AgentHistoryView> createState() => _AgentHistoryViewState();
}

class _AgentHistoryViewState extends ConsumerState<AgentHistoryView> {
  String _selectedFilter = 'All'; // 'All', 'Wholesale Topup', 'Retail Transfer'

  @override
  Widget build(BuildContext context) {
    final dashState = ref.watch(agentDashboardViewModelProvider);
    final allTransactions = dashState.recentTransactions;

    final filteredTransactions = allTransactions.where((tx) {
      if (_selectedFilter == 'All') return true;
      if (_selectedFilter == 'Wholesale Topup') return tx.type == TransactionType.wholesale;
      if (_selectedFilter == 'Retail Transfer') return tx.type == TransactionType.retail;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.agentLightBackground,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0, // We will build a custom header below
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Agent Transaction History',
                    style: TextStyle(color: AppColors.agentTextDark, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Wholesale topups and retail transfers across Treasury and student wallets',
                    style: TextStyle(color: AppColors.agentTextLight, fontSize: 14, height: 1.4),
                  ),
                ],
              ),
            ),

            // ── Filter Chips ──────────────────────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _buildFilterChip('All'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Wholesale Topup'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Retail Transfer'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Transactions List ─────────────────────────────────────────────
            Expanded(
              child: filteredTransactions.isEmpty
                  ? Container(
                      margin: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.agentCardWhite,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: const BoxDecoration(
                              color: Color(0xFFECFDF5), // Light green circle
                              shape: BoxShape.circle,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.agentBlue, width: 2),
                              ),
                              child: const Icon(Icons.close, color: AppColors.agentBlue, size: 20),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text('No transactions yet', style: TextStyle(color: AppColors.agentTextDark, fontSize: 20, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          const Text(
                            'Transfers you make will appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.agentTextLight, fontSize: 15),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      itemCount: filteredTransactions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _HistoryTile(transaction: filteredTransactions[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.agentBlue : AppColors.agentCardWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.agentBlue : const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.agentTextDark,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final TransactionModel transaction;
  const _HistoryTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isInbound = transaction.type == TransactionType.wholesale;
    final isSuccess = transaction.status == TransactionStatus.success;

    final typeLabel = isInbound ? 'Wholesale Topup' : 'Retail Transfer';
    
    // Formatting sender/receiver logic based on transaction type
    final fromText = isInbound ? 'From: Admin (Treasury)' : 'From: My Wallet';
    final toText = isInbound 
        ? 'To: My Wallet' 
        : 'To: STU-${(transaction.receiverWalletId ?? 'XXXX').substring(0, 4).toUpperCase()}';

    final amountColor = isInbound ? AppColors.agentGreenText : AppColors.agentRedText;
    final amountSign = isInbound ? '+' : '-';
    final statusColor = isSuccess ? AppColors.agentGreenText : AppColors.agentRedText;

    final formattedDate = DateFormat('dd MMM yyyy • hh:mm a').format(transaction.timestamp);
    final txnId = 'TXN-${transaction.id.substring(0, 4).toUpperCase()}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.agentCardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side (Details)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  typeLabel,
                  style: const TextStyle(color: AppColors.agentTextDark, fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(fromText, style: const TextStyle(color: AppColors.agentTextLight, fontSize: 13)),
                Text(toText, style: const TextStyle(color: AppColors.agentTextLight, fontSize: 13)),
                const SizedBox(height: 12),
                Text(formattedDate, style: const TextStyle(color: AppColors.agentTextLight, fontSize: 11)),
              ],
            ),
          ),

          // Right side (Amounts and Status)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$amountSign₦${transaction.amount.toStringAsFixed(2)}',
                style: TextStyle(color: amountColor, fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    transaction.status.name.toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(txnId, style: const TextStyle(color: AppColors.agentTextLight, fontSize: 11, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}
