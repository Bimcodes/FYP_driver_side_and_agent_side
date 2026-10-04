import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/loading_overlay.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../widgets/app_notification.dart';
import '../shared/pin_input_widget.dart';

class AgentPinSettingsView extends ConsumerStatefulWidget {
  const AgentPinSettingsView({super.key});

  @override
  ConsumerState<AgentPinSettingsView> createState() => _AgentPinSettingsViewState();
}

class _AgentPinSettingsViewState extends ConsumerState<AgentPinSettingsView> {
  String _currentInput = '';

  Future<void> _savePin(String newPin) async {
    if (newPin.length < 4) {
      AppNotification.showError(context, 'PIN must be 4 digits.');
      return;
    }
    
    LoadingOverlay.show(context);
    try {
      await ref.read(authViewModelProvider.notifier).setTransactionPin(newPin);
      if (mounted) {
        AppNotification.showSuccess(context, 'PIN saved securely.');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppNotification.showError(context, 'Error: $e');
      }
    } finally {
      if (mounted) LoadingOverlay.hide(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.agentLightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFE2E8F0))),
            child: const Icon(Icons.arrow_back_ios_new, size: 14, color: AppColors.agentTextDark),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Transaction PIN', style: TextStyle(color: AppColors.agentTextDark, fontSize: 20, fontWeight: FontWeight.w800)),
            Text('Secure your cash terminal operations', style: TextStyle(color: AppColors.agentTextLight, fontSize: 13, fontWeight: FontWeight.w400)),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Info Box ──────────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F5FF), // Light blue background
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info, color: AppColors.agentBlue, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: const Text(
                        'Your PIN ensures secure cash handling and validates terminal access. Never share it.',
                        style: TextStyle(color: AppColors.agentBlue, fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Create PIN ────────────────────────────────────────────────────
              const Text('Create 4-Digit PIN', style: TextStyle(color: AppColors.agentTextDark, fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              PinInputWidget(
                onChanged: (val) => _currentInput = val,
                onCompleted: (val) {},
              ),
              const SizedBox(height: 24),

              // ── Confirm PIN ───────────────────────────────────────────────────
              const Text('Confirm 4-Digit PIN', style: TextStyle(color: AppColors.agentTextDark, fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              PinInputWidget(
                onChanged: (val) => _currentInput = val,
                onCompleted: (val) {},
              ),
              
              const SizedBox(height: 32),
              
              // ── Save Button ───────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _savePin(_currentInput),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.authPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('Save Secure PIN', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
