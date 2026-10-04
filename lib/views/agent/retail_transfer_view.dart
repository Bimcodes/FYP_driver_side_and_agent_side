// =============================================================================
// FILE: views/agent/retail_transfer_view.dart
// LAYER: View (UI Layer)
//
// PURPOSE:
//   The P2P retail transfer screen where Agents send tokens to students.
//   Input: Student Wallet ID (typed or scanned via QR) + token amount.
//   On submit: calls AgentDashboardViewModel.transferToStudent().
//
// MVVM ROLE:
//   View. Reads state from AgentDashboardViewModel. Calls transfer action.
//   The View does NOT calculate the new balance or touch Supabase.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/constants/app_routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/loading_overlay.dart';
import '../../core/utils/app_bottom_sheets.dart';
import '../../viewmodels/agent_dashboard_viewmodel.dart';
import 'shared/pin_input_widget.dart';
import '../shared/primary_button.dart';

/// The Retail Transfer screen for Agents.
///
/// Allows transferring tokens to a student by:
///   a) Typing the student's Wallet UUID directly.
///   b) Tapping "Scan QR Code" to open the camera scanner.
class RetailTransferView extends ConsumerStatefulWidget {
  const RetailTransferView({super.key});

  @override
  ConsumerState<RetailTransferView> createState() => _RetailTransferViewState();
}

class _RetailTransferViewState extends ConsumerState<RetailTransferView> {
  final _walletIdController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _walletIdController.dispose();
    _amountController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _openScanner() async {
    final scannedId = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (context) => const _QrScannerDialog(),
    );
    if (scannedId != null) {
      setState(() {
        _walletIdController.text = scannedId;
      });
    }
  }

  final _scrollController = ScrollController();

  /// Calls the ViewModel's transfer action.
  Future<void> _onSubmitTransfer() async {
    final walletId = _walletIdController.text.trim();
    final amountText = _amountController.text.trim();

    if (walletId.isEmpty || amountText.isEmpty) return;

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) return;

    final dashState = ref.read(agentDashboardViewModelProvider);
    final agentWalletId = dashState.wallet?.id;
    if (agentWalletId == null) return;
    
    final currentBalance = dashState.wallet?.balance ?? 0;
    if (currentBalance < 100) {
      AppBottomSheets.showInsufficientFunds(
        context,
        onTopUp: () {
          // This should navigate to top-up, but for now we just dismiss
        },
      );
      return;
    }

    // Always require a PIN
    final pin = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter your transaction PIN'),
        content: PinInputWidget(
          onChanged: (_) {},
          onCompleted: (pin) => Navigator.pop(ctx, pin),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ],
      ),
    );
    
    if (pin == null) return; // User cancelled

    if (!mounted) return;
    LoadingOverlay.show(context);

    // Delegate to the ViewModel — await so we know when it's done.
    await ref.read(agentDashboardViewModelProvider.notifier).transferToStudent(
          agentWalletId: agentWalletId,
          studentWalletId: walletId,
          amount: amount,
          pin: pin,
        );

    if (mounted) {
      LoadingOverlay.hide(context);
    }

    // Scroll to top so the agent immediately sees the updated balance card.
    if (mounted) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashState = ref.watch(agentDashboardViewModelProvider);

    // Clear form fields after a successful transfer.
    ref.listen<AgentDashboardState>(agentDashboardViewModelProvider, (_, next) {
      if (next.transferSuccess != null) {
        _walletIdController.clear();
        _amountController.clear();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.agentLightBackground,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Transfer to Student', style: TextStyle(color: AppColors.agentTextDark, fontSize: 20, fontWeight: FontWeight.w800)),
            Text('Manual Wallet ID entry', style: TextStyle(color: AppColors.agentTextLight, fontSize: 13, fontWeight: FontWeight.w400)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFE2E8F0))),
            child: const Icon(Icons.arrow_back_ios_new, size: 14, color: AppColors.agentTextDark),
          ),
          onPressed: () => context.go(AppRoutes.agentDashboard),
        ),
      ),
      body: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Available Balance ──────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppColors.agentGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'AVAILABLE BALANCE',
                              style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text('Wallet ID', style: TextStyle(color: Colors.white, fontSize: 11)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '₦${dashState.wallet?.balance.toStringAsFixed(2) ?? '0.00'}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 32),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Agent wallet balance available for student transfers',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Success / Error Feedback ──────────────────────────────
                  if (dashState.transferSuccess != null) ...[
                    _FeedbackBanner(
                      message: dashState.transferSuccess!,
                      isError: false,
                      onDismiss: () => ref
                          .read(agentDashboardViewModelProvider.notifier)
                          .clearTransferFeedback(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (dashState.transferError != null) ...[
                    _FeedbackBanner(
                      message: dashState.transferError!,
                      isError: true,
                      onDismiss: () => ref
                          .read(agentDashboardViewModelProvider.notifier)
                          .clearTransferFeedback(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Wallet ID Field ────────────────────────────────────────
                  const Text(
                    AppStrings.agentWalletIdLabel,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _walletIdController,
                          style: const TextStyle(
                              color: AppColors.textPrimary, fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: 'Enter wallet UUID or scan QR',
                            prefixIcon: Icon(Icons.credit_card,
                                color: AppColors.textMuted, size: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // QR Scan button
                      GestureDetector(
                        onTap: _openScanner,
                        child: Container(
                          height: 52,
                          width: 52,
                          decoration: BoxDecoration(
                            color: AppColors.agentBlue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.qr_code_scanner,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Amount Field ───────────────────────────────────────────
                  const Text(
                    AppStrings.agentAmountLabel,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'e.g. 100',
                      prefixIcon: Icon(Icons.toll,
                          color: AppColors.textMuted, size: 18),
                      prefixText: '₦ ',
                      prefixStyle: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Submit Button ──────────────────────────────────────────
                  PrimaryButton(
                    label: dashState.isTransferring
                        ? AppStrings.agentTransferring
                        : AppStrings.agentConfirmButton,
                    isLoading: dashState.isTransferring,
                    gradient: AppColors.agentGradient,
                    onPressed: _onSubmitTransfer,
                  ),
                ],
              ),
            ),
    );
  }
}

// ── QR Scanner Dialog ────────────────────────────────────────────────────────

class _QrScannerDialog extends StatefulWidget {
  const _QrScannerDialog();

  @override
  State<_QrScannerDialog> createState() => _QrScannerDialogState();
}

class _QrScannerDialogState extends State<_QrScannerDialog> {
  final MobileScannerController _controller = MobileScannerController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.authSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Scan Student QR', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                      SizedBox(height: 4),
                      Text('Scanning autofills Wallet ID', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              height: 240,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.transparent),
              ),
              clipBehavior: Clip.hardEdge,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MobileScanner(
                    controller: _controller,
                    onDetect: (capture) {
                      final barcode = capture.barcodes.firstOrNull;
                      if (barcode?.rawValue != null) {
                        Navigator.pop(context, barcode!.rawValue);
                      }
                    },
                  ),
                  CustomPaint(
                    painter: _ScannerBracketPainter(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Align QR code within the frame',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerBracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.agentGreenText
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    const double cornerLength = 30.0;
    const double padding = 20.0;

    // Top Left
    canvas.drawPath(
      Path()
        ..moveTo(padding, padding + cornerLength)
        ..lineTo(padding, padding)
        ..lineTo(padding + cornerLength, padding),
      paint,
    );

    // Top Right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - padding - cornerLength, padding)
        ..lineTo(size.width - padding, padding)
        ..lineTo(size.width - padding, padding + cornerLength),
      paint,
    );

    // Bottom Left
    canvas.drawPath(
      Path()
        ..moveTo(padding, size.height - padding - cornerLength)
        ..lineTo(padding, size.height - padding)
        ..lineTo(padding + cornerLength, size.height - padding),
      paint,
    );

    // Bottom Right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - padding - cornerLength, size.height - padding)
        ..lineTo(size.width - padding, size.height - padding)
        ..lineTo(size.width - padding, size.height - padding - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Feedback Banner ───────────────────────────────────────────────────────────

class _FeedbackBanner extends StatelessWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  const _FeedbackBanner({
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.error : AppColors.success;
    final icon = isError ? Icons.error_outline : Icons.check_circle_outline;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontSize: 13),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: Icon(Icons.close, color: color.withValues(alpha: 0.6), size: 16),
          ),
        ],
      ),
    );
  }
}
