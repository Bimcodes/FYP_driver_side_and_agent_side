import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/passenger_dashboard_viewmodel.dart';
import '../widgets/app_notification.dart';

class PassengerDashboardView extends ConsumerStatefulWidget {
  const PassengerDashboardView({super.key});

  @override
  ConsumerState<PassengerDashboardView> createState() => _PassengerDashboardViewState();
}

class _PassengerDashboardViewState extends ConsumerState<PassengerDashboardView> {
  bool _hideBalance = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authViewModelProvider).user;
      if (user != null) {
        ref.read(passengerDashboardViewModelProvider.notifier).loadDashboard(user);
      }
    });
  }

  void _showReceiveQrModal(BuildContext context, String walletId) {
    bool isCopied = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F141E), // Dark theme
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'RECEIVE TRANSIT TOKENS',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Show this QR code to any authorized Ticket Agent at the station kiosk or window.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 28),

                    // High-contrast QR Code
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: QrImageView(
                          data: walletId,
                          version: QrVersions.auto,
                          size: 190.0,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Wallet UUID Copy Box
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: walletId));
                        setState(() => isCopied = true);
                        AppNotification.showSuccess(modalCtx, 'Wallet ID copied to clipboard!');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.authSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFF0C241E),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_circle_outlined, color: AppColors.authPrimary, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                walletId,
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(isCopied ? Icons.check : Icons.copy_rounded, color: isCopied ? AppColors.authPrimary : AppColors.textSecondary, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Action Button
                    ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: walletId));
                        setState(() => isCopied = true);
                        AppNotification.showSuccess(modalCtx, 'Wallet ID copied to clipboard!');
                      },
                      icon: Icon(isCopied ? Icons.check : Icons.copy, color: Colors.white, size: 18),
                      label: Text(
                        isCopied ? 'Wallet ID copied to clipboard!' : 'Copy Wallet ID',
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.authPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(passengerDashboardViewModelProvider);
    final user = ref.watch(authViewModelProvider).user;
    final balance = state.wallet?.balance ?? 0.0;

    final userName = user?.displayName.isNotEmpty == true ? user!.displayName : 'Student';
    final userInitials = userName.split(' ').where((e) => e.isNotEmpty).take(2).map((e) => e[0]).join().toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.agentLightBackground, // Light Theme from Image 5
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.authPrimary,
          onRefresh: () async {
            if (user != null) {
              await ref.read(passengerDashboardViewModelProvider.notifier).loadDashboard(user);
            }
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Top Header ────────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.authPrimary,
                          child: Text(
                            userInitials.isEmpty ? 'ST' : userInitials,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: const TextStyle(color: AppColors.agentTextDark, fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.agentGreenText.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'STUDENT WALLET',
                                style: TextStyle(color: AppColors.agentGreenText, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        ref.read(authViewModelProvider.notifier).signOut();
                        context.go(AppRoutes.loginWithEmail);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.logout_rounded, color: AppColors.agentTextLight, size: 20),
                      ),
                    ),
                  ],
                ),
                // ── Top-Up Flash Notification Banner (Image 5) ───────────────
                if (state.showTopupFlash) ...[
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.authPrimary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.authPrimary.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check, color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Top-Up Received! +₦${state.lastReceivedAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} Tokens',
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Balance Card ──────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppColors.agentGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.authPrimary.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'CURRENT BALANCE',
                            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                          ),
                          IconButton(
                            onPressed: () => setState(() => _hideBalance = !_hideBalance),
                            icon: Icon(
                              _hideBalance ? Icons.visibility_off : Icons.visibility,
                              color: Colors.white70,
                              size: 22,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: _hideBalance ? 'Show balance' : 'Hide balance',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _hideBalance
                            ? '₦••••••'
                            : '₦${balance.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                        style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: -1),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Transit Token Credits',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Primary Button: Board Bus & Pay Fare ──────────────────────
                ElevatedButton.icon(
                  onPressed: () => context.push(AppRoutes.passengerBoard),
                  icon: const Icon(Icons.qr_code_scanner, size: 22, color: Colors.white),
                  label: const Text(
                    'BOARD BUS & PAY FARE',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.authPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Secondary Grid Cards ──────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (state.wallet == null) {
                            AppNotification.showWarning(context, 'Loading wallet credentials...');
                            return;
                          }
                          _showReceiveQrModal(context, state.wallet!.id);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.agentCardWhite,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFECFDF5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.arrow_downward, color: AppColors.agentGreenText, size: 20),
                              ),
                              const SizedBox(height: 14),
                              const Text('Receive Tokens', style: TextStyle(color: AppColors.agentTextDark, fontSize: 15, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              const Text('Top-up from Agent', style: TextStyle(color: AppColors.agentTextLight, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context.push(AppRoutes.passengerMap),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.agentCardWhite,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF1F5F9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.map_outlined, color: AppColors.agentTextDark, size: 20),
                              ),
                              const SizedBox(height: 14),
                              const Text('Transit Map', style: TextStyle(color: AppColors.agentTextDark, fontSize: 15, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              const Text('View campus routes', style: TextStyle(color: AppColors.agentTextLight, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ── Recent Activity Header ────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Recent Activity', style: TextStyle(color: AppColors.agentTextDark, fontSize: 18, fontWeight: FontWeight.w800)),
                    if (state.recentTransactions.isNotEmpty)
                      GestureDetector(
                        onTap: () => context.push(AppRoutes.passengerHistory),
                        child: const Text('View All', style: TextStyle(color: AppColors.agentGreenText, fontSize: 13, fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Recent Activity List ──────────────────────────────────────
                if (state.recentTransactions.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.agentCardWhite,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Center(
                      child: Text('No recent activity.', style: TextStyle(color: AppColors.agentTextLight, fontSize: 14)),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.agentCardWhite,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: state.recentTransactions.take(5).toList().asMap().entries.map((entry) {
                        final idx = entry.key;
                        final tx = entry.value;
                        final isDebit = tx.senderWalletId == state.wallet?.id;
                        final isLast = idx == (state.recentTransactions.length > 5 ? 4 : state.recentTransactions.length - 1);

                        final title = isDebit ? 'Route 102 Boarding' : 'Ticket Agent Top-up';
                        final iconData = isDebit ? Icons.directions_bus_outlined : Icons.credit_card_outlined;
                        final iconBg = isDebit ? AppColors.agentRedArrow : AppColors.agentGreenArrow;
                        final iconColor = isDebit ? AppColors.agentRedText : AppColors.agentGreenText;
                        final amountColor = isDebit ? AppColors.agentRedText : AppColors.agentGreenText;
                        final sign = isDebit ? '-' : '+';

                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
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
                                        Text(title, style: const TextStyle(color: AppColors.agentTextDark, fontWeight: FontWeight.w700, fontSize: 14)),
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
                                    style: TextStyle(color: amountColor, fontWeight: FontWeight.w800, fontSize: 15),
                                  ),
                                ],
                              ),
                            ),
                            if (!isLast) const Divider(height: 1, color: Color(0xFFE2E8F0), indent: 16, endIndent: 16),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                
                // ── Boarding Approved Toast Pill Banner (Mockup) ────────────────
                if (state.showBoardingApproved) ...[
                  const SizedBox(height: 16),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B4F37), // Dark forest green from mockup
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0B4F37).withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.check, color: Colors.white, size: 20),
                        SizedBox(width: 12),
                        Text(
                          'Boarding Approved!',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
