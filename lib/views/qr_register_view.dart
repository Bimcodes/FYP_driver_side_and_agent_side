import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/app_routes.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/app_logger.dart';
import '../viewmodels/auth_viewmodel.dart';

class QrRegisterView extends ConsumerStatefulWidget {
  const QrRegisterView({super.key});

  @override
  ConsumerState<QrRegisterView> createState() => _QrRegisterViewState();
}

class _QrRegisterViewState extends ConsumerState<QrRegisterView> {
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
    logger.i('QR Scanned: $rawValue');

    setState(() {
      _isProcessing = true;
    });

    try {
      // Expecting JSON: {"e":"agt-001@qrfare.app","p":"tempPass","r":"Agent","c":"AGT-001"}
      final payload = jsonDecode(rawValue) as Map<String, dynamic>;
      
      final email = payload['e'] as String?;
      final password = payload['p'] as String?;
      final role = payload['r'] as String?;

      if (email == null || password == null || role == null) {
        throw Exception('Invalid QR code format.');
      }

      logger.i('Signing in with embedded credentials for $email...');
      
      // 1. Sign in with the temporary credentials
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Sign in failed.');
      }

      // 2. We are in! Stop scanner.
      _scannerController.stop();

      // Ensure widget is still mounted before showing dialog
      if (!mounted) return;

      // 3. Prompt user to set their own password
      await _showSetPasswordDialog(context);

      // Ensure widget is still mounted before navigation
      if (!mounted) return;

      // 4. Update the AuthViewModel so the router guard knows the user is
      //    now logged in. This triggers GoRouter to re-evaluate the route
      //    and send the user to their correct dashboard automatically.
      await ref.read(authViewModelProvider.notifier).restoreSession();

      // 5. Route to their dashboard
      if (!mounted) return;
      if (role == 'Agent') {
        context.go(AppRoutes.agentDashboard);
      } else if (role == 'Driver') {
        context.go(AppRoutes.driverDashboard);
      } else {
        throw Exception('Unknown role: $role');
      }

    } catch (e) {
      logger.e('QR Registration Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: ${e.toString()}'),
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

  Future<void> _showSetPasswordDialog(BuildContext context) async {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;
    bool obscureText = true;

    await showDialog(
      context: context,
      barrierDismissible: false, // Must set password
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: AppColors.authSurface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.authPrimary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.shield_outlined, color: AppColors.authPrimary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Text('Set Your Password', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Welcome! Please set a secure password for your account.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4),
                      ),
                      const SizedBox(height: 24),
                      const Text('New Password', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: passwordController,
                        obscureText: obscureText,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.authBackground,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2D3748))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2D3748))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.authPrimary)),
                          suffixIcon: GestureDetector(
                            onTap: () => setState(() => obscureText = !obscureText),
                            child: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: AppColors.textSecondary, size: 20),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.length < 6) {
                            return 'Password must be at least 6 characters.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      const Text('Must be at least 6 characters.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 32),
                      
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isSaving ? null : () async {
                            if (!formKey.currentState!.validate()) return;
                            setState(() { isSaving = true; });

                            try {
                              await Supabase.instance.client.auth.updateUser(
                                UserAttributes(password: passwordController.text),
                              );
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            } catch (e) {
                              setState(() { isSaving = false; });
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to update password: $e')),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.authPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: isSaving
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Save Password', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
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
    return Scaffold(
      backgroundColor: AppColors.authBackground,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                // ── Header ────────────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('METRO PASS', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                          SizedBox(height: 4),
                          Text('Terminal Registration', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
                        ],
                      ),
                      // Close button
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: AppColors.authSurface, shape: BoxShape.circle),
                          child: const Icon(Icons.close, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Ask your Transport Administrator to generate your registration QR code on their dashboard, then scan it below.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4),
                  ),
                ),
                const SizedBox(height: 32),

                // ── Camera Viewport ───────────────────────────────────────────────
                Center(
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width - 48,
                        height: 360,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.authPrimary, width: 3),
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            MobileScanner(
                              controller: _scannerController,
                              onDetect: _handleBarcode,
                            ),
                            // Corner markers overlay
                            CustomPaint(
                              painter: _ScannerOverlayPainter(),
                            ),
                            // Dark overlay when processing
                            if (_isProcessing)
                              Container(color: Colors.black.withValues(alpha: 0.7)),
                          ],
                        ),
                      ),
                      
                      // ── SECURE QR ENGINE ACTIVE badge ──
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2430).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.circle, color: AppColors.authPrimary, size: 10),
                            SizedBox(width: 8),
                            Text('SECURE QR ENGINE ACTIVE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),
                
                // ── Footer text & Progress indicator ─────────────────────────────
                const Text(
                  'Validating identity via civic cryptography protocol',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Center(
                  child: SizedBox(
                    width: 120,
                    height: 4,
                    child: LinearProgressIndicator(
                      value: _isProcessing ? null : 0.3,
                      backgroundColor: AppColors.authSurface,
                      color: AppColors.authPrimary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
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

// A simple painter to draw corner brackets for the scanner
class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    const double cornerLength = 40.0;
    const double padding = 32.0;

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
