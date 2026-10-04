import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_logger.dart';
import '../../models/bus_qr_payload.dart';
import '../widgets/app_notification.dart';
import 'boarding_checkout_sheet.dart';

class PassengerScannerView extends ConsumerStatefulWidget {
  const PassengerScannerView({super.key});

  @override
  ConsumerState<PassengerScannerView> createState() => _PassengerScannerViewState();
}

class _PassengerScannerViewState extends ConsumerState<PassengerScannerView> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;
  bool _isTorchOn = false;
  String? _scanError;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    final raw = barcode!.rawValue!;
    logger.i('[PassengerScanner] QR scanned: $raw');

    final payload = BusQrPayload.tryParse(raw);
    if (payload == null) {
      setState(() => _scanError = 'Invalid bus QR code...');
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _scanError = null);
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _scanError = null;
    });
    _scannerController.stop();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => BoardingCheckoutSheet(
        busPayload: payload,
        onBoardingComplete: () {
          Navigator.of(modalCtx).pop();
          if (mounted) {
            context.go(AppRoutes.passengerDashboard);
            AppNotification.showSuccess(context, 'Boarding Approved for ${payload.vehicleId}!');
          }
        },
      ),
    ).then((_) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _scannerController.start();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final reticleColor = _scanError != null ? const Color(0xFFEF4444) : AppColors.authPrimary;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Mobile Scanner Camera
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),

          // Reticle Viewport (Image 3 - Red when invalid)
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 280,
                  height: 240,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: reticleColor, width: 3),
                  ),
                ),
                // Horizontal Scanning Line
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 260,
                  height: 2,
                  decoration: BoxDecoration(
                    color: reticleColor,
                    boxShadow: [
                      BoxShadow(
                        color: reticleColor.withValues(alpha: 0.8),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Controls & Overlay
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),
                const Spacer(),

                // Torch Toggle Button below viewport
                GestureDetector(
                  onTap: () async {
                    await _scannerController.toggleTorch();
                    setState(() => _isTorchOn = !_isTorchOn);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F141E).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isTorchOn ? Icons.flashlight_on : Icons.flashlight_on_outlined,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isTorchOn ? 'Torch On' : 'Torch Off',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Error Banner (Image 3)
                if (_scanError != null) ...[
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8E2428), // Dark red from Image 3
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.white, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _scanError!,
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Bottom Hint
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Align the campus bus QR code within the frame to pay your fare.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600, height: 1.4),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
