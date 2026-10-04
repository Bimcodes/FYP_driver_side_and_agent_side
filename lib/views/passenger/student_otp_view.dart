import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../viewmodels/signup_viewmodel.dart';
import '../widgets/app_notification.dart';

class StudentOtpView extends ConsumerStatefulWidget {
  const StudentOtpView({super.key});

  @override
  ConsumerState<StudentOtpView> createState() => _StudentOtpViewState();
}

class _StudentOtpViewState extends ConsumerState<StudentOtpView> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  
  Timer? _resendTimer;
  int _secondsRemaining = 59;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _secondsRemaining = 59);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  Future<void> _verifyOtp() async {
    final otp = _otpCode;
    if (otp.length < 6) {
      AppNotification.showError(context, 'Please enter a valid 6-digit OTP code.');
      return;
    }

    final success = await ref.read(signupViewModelProvider.notifier).verifyOtp(otp);

    if (success && mounted) {
      context.push(AppRoutes.passengerOnboarding);
    }
  }

  void _onDigitChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    if (_otpCode.length == 6) {
      _verifyOtp();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signupViewModelProvider);
    final userEmail = state.email ?? "anna.smith@university.edu";

    return Scaffold(
      backgroundColor: AppColors.authBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),

              // Circular Green Mail Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.authPrimary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mail_outline, color: AppColors.authPrimary, size: 40),
              ),
              const SizedBox(height: 24),

              const Text(
                'VERIFY EMAIL',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1.2),
              ),
              const SizedBox(height: 12),

              const Text(
                'We sent a 6-digit verification code to',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                userEmail,
                style: const TextStyle(color: AppColors.authPrimary, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 36),

              if (state.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Text(state.errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                ),
                const SizedBox(height: 24),
              ],

              const Text(
                'Enter verification code',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),

              // 6 PIN Boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  final isFocused = _focusNodes[index].hasFocus;
                  return SizedBox(
                    width: 48,
                    height: 56,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: AppColors.authSurface,
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isFocused ? AppColors.authPrimary : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.authPrimary, width: 2),
                        ),
                      ),
                      onChanged: (val) => _onDigitChanged(val, index),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 48),

              // Verify Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: state.isLoading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.authPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: state.isLoading
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Verify Email', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),

              // Resend Timer
              GestureDetector(
                onTap: _secondsRemaining == 0 ? _startResendTimer : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Didn't receive the code? ", style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    Text(
                      _secondsRemaining > 0 ? 'Resend Code (${_secondsRemaining}s)' : 'Resend Code',
                      style: TextStyle(
                        color: _secondsRemaining == 0 ? AppColors.authPrimary : AppColors.authPrimary.withValues(alpha: 0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
