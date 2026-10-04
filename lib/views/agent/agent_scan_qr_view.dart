import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/theme/app_colors.dart';
import '../widgets/app_notification.dart';

class AgentScanQrView extends ConsumerStatefulWidget {
  const AgentScanQrView({super.key});

  @override
  ConsumerState<AgentScanQrView> createState() => _AgentScanQrViewState();
}

class _AgentScanQrViewState extends ConsumerState<AgentScanQrView> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue != null) {
      setState(() => _isProcessing = true);
      
      // Stop scanner while processing
      await _scannerController.stop();

      // Show processing state in UI
      // In a real implementation, you'd make an API call here.
      // We will simulate a failure as shown in the mockup.
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        AppNotification.showError(context, 'Scan failed: Invalid Admin QR code');
        
        setState(() => _isProcessing = false);
        // Restart scanner
        await _scannerController.start();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F141E), // Dark theme for scanner
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Scanner Background
            MobileScanner(
              controller: _scannerController,
              onDetect: _onDetect,
            ),
            
            // Overlay with hole (Simulated using containers or just semi-transparent overlay)
            Container(
              color: const Color(0xFF0F141E).withValues(alpha: 0.95),
            ),
            
            // Content
            Column(
              children: [
                const SizedBox(height: 16),
                // Custom App Bar Area
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, color: Colors.white54, size: 16),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Top-Up via Admin QR', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                          Text('Latest Agent requirements', style: TextStyle(color: Colors.white54, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Instructions Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.agentBlue.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.qr_code, color: AppColors.agentBlue, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Ask your Transport Administrator to generate a Top-Up QR',
                              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600, height: 1.3),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Align the Admin QR code inside the camera viewport below.',
                              style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Viewport Frame
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        color: _isProcessing ? AppColors.authSurface : Colors.transparent,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.agentBlue.withValues(alpha: 0.3), width: 2),
                      ),
                      child: _isProcessing 
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              SizedBox(
                                width: 20,
                                height: 2,
                                child: LinearProgressIndicator(color: AppColors.agentBlue, backgroundColor: Colors.transparent),
                              ),
                              SizedBox(height: 24),
                              Text('Processing Admin QR', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              SizedBox(height: 8),
                              Text('Wait for checkout to open', style: TextStyle(color: Colors.white54, fontSize: 13)),
                            ],
                          )
                        : null,
                    ),
                    if (!_isProcessing)
                      Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.agentBlue.withValues(alpha: 0.1), width: 1),
                          borderRadius: BorderRadius.circular(32),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                const Text(
                  'Align the Admin QR code inside the viewport',
                  style: TextStyle(color: Colors.white30, fontSize: 13),
                ),
                
                const Spacer(),
                
                // Bottom Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.flashlight_on_outlined, color: Colors.white54, size: 16),
                          SizedBox(width: 8),
                          Text('Toggle Flash', style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.edit_outlined, color: Colors.white54, size: 16),
                          SizedBox(width: 8),
                          Text('Manual ID', style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
