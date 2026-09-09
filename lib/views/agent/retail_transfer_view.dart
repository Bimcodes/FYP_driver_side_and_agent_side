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
import '../../viewmodels/agent_dashboard_viewmodel.dart';
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
  bool _showScanner = false;
  MobileScannerController? _scannerController;

  @override
  void dispose() {
    _walletIdController.dispose();
    _amountController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  void _openScanner() {
    _scannerController = MobileScannerController();
    setState(() => _showScanner = true);
  }

  void _closeScanner() {
    _scannerController?.dispose();
    _scannerController = null;
    setState(() => _showScanner = false);
  }

  /// Called when a QR code barcode is detected by the scanner.
  void _onScanDetect(BarcodeCapture capture) {
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue != null) {
      // The QR code should contain the student's wallet UUID.
      _walletIdController.text = barcode!.rawValue!;
      _closeScanner();
    }
  }

  /// Calls the ViewModel's transfer action.
  void _onSubmitTransfer() {
    final walletId = _walletIdController.text.trim();
    final amountText = _amountController.text.trim();

    if (walletId.isEmpty || amountText.isEmpty) return;

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) return;

    final dashState = ref.read(agentDashboardViewModelProvider);
    final agentWalletId = dashState.wallet?.id;
    if (agentWalletId == null) return;

    // Delegate to the ViewModel — the View does not touch Supabase.
    ref.read(agentDashboardViewModelProvider.notifier).transferToStudent(
          agentWalletId: agentWalletId,
          studentWalletId: walletId,
          amount: amount,
        );
  }

  @override
  Widget build(BuildContext context) {
    final dashState = ref.watch(agentDashboardViewModelProvider);

    // Navigate back to dashboard after successful transfer.
    ref.listen<AgentDashboardState>(agentDashboardViewModelProvider,
        (_, next) {
      if (next.transferSuccess != null) {
        // Clear controllers
        _walletIdController.clear();
        _amountController.clear();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.agentTransferTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => context.go(AppRoutes.agentDashboard),
        ),
      ),
      body: _showScanner
          ? _QrScannerOverlay(
              controller: _scannerController!,
              onDetect: _onScanDetect,
              onClose: _closeScanner,
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Available Balance ──────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppColors.agentGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance_wallet,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Available Balance',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              '₦${dashState.wallet?.balance.toStringAsFixed(2) ?? '0.00'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                              ),
                            ),
                          ],
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
                            color: AppColors.agentSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.agentPrimary.withValues(alpha: 0.4)),
                          ),
                          child: const Icon(
                            Icons.qr_code_scanner,
                            color: AppColors.agentLight,
                            size: 22,
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

// ── QR Scanner Overlay ────────────────────────────────────────────────────────

class _QrScannerOverlay extends StatelessWidget {
  final MobileScannerController controller;
  final void Function(BarcodeCapture) onDetect;
  final VoidCallback onClose;

  const _QrScannerOverlay({
    required this.controller,
    required this.onDetect,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MobileScanner(
          controller: controller,
          onDetect: onDetect,
        ),
        // Close button overlay
        Positioned(
          top: 16,
          left: 16,
          child: SafeArea(
            child: GestureDetector(
              onTap: onClose,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ),
        ),
        // Scanning guide overlay
        Center(
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.agentLight, width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: const Text(
            'Align QR code within the frame',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
      ],
    );
  }
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
