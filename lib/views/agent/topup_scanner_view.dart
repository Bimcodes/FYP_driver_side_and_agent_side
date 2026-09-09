import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_logger.dart';

class TopupScannerView extends StatefulWidget {
  const TopupScannerView({super.key});

  @override
  State<TopupScannerView> createState() => _TopupScannerViewState();
}

class _TopupScannerViewState extends State<TopupScannerView> {
  bool _isProcessing = false;
  final MobileScannerController _scannerController = MobileScannerController();

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final rawValue = barcode.rawValue!;
    
    // Ignore random barcodes that aren't JSON
    if (!rawValue.startsWith('{')) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final payload = jsonDecode(rawValue) as Map<String, dynamic>;
      
      final action = payload['action'] as String?;
      final url = payload['url'] as String?;

      if (action != 'topup' || url == null) {
        throw Exception('Not a valid Top-Up QR code.');
      }

      logger.i('Launching Paystack URL: $url');
      _scannerController.stop();

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Top-up checkout opened! You can return here after paying.'),
              backgroundColor: AppColors.agentPrimary,
            ),
          );
          // Go back to the agent dashboard
          context.pop();
        }
      } else {
        throw Exception('Could not launch payment URL.');
      }
    } catch (e) {
      logger.e('QR Top-Up Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Scan failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      setState(() {
        _isProcessing = false;
      });
      // Small delay before scanner reads again
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Scan Top-Up QR'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'Ask your Transport Administrator to generate a Top-Up QR on their dashboard, then scan it here to pay on your device.',
              style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.agentPrimary, width: 2),
              ),
              clipBehavior: Clip.hardEdge,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MobileScanner(
                    controller: _scannerController,
                    onDetect: _handleBarcode,
                  ),
                  if (_isProcessing)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.agentPrimary,
                        ),
                      ),
                    ),
                  // Crosshair overlay
                  Center(
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white54, width: 2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
