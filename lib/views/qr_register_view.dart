import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/app_routes.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/app_logger.dart';

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

      // 4. Route to their dashboard
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

    await showDialog(
      context: context,
      barrierDismissible: false, // Must set password
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Set Your Password', style: TextStyle(color: Colors.white)),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Welcome! Please set a secure password for your account.',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        labelStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) {
                        if (val == null || val.length < 6) {
                          return 'Password must be at least 6 characters.';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                if (isSaving)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  )
                else
                  TextButton(
                    onPressed: () async {
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
                    style: TextButton.styleFrom(foregroundColor: AppColors.agentLight),
                    child: const Text('Save Password'),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Scan Registration QR'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'Ask your Transport Administrator to generate your registration QR code on their dashboard, then scan it below.',
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
