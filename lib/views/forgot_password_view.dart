import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/theme/app_colors.dart';
import 'agent/shared/pin_input_widget.dart'; // For OTP input

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  int _step = 0; // 0: Email, 1: OTP, 2: New Password
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  String? _errorMessage;
  String _otpCode = '';
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        _emailController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _step = 1;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpCode.length < 6) { // Assuming 6 digit OTP for Supabase
      setState(() => _errorMessage = 'Please enter a valid 6-digit OTP');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Supabase.instance.client.auth.verifyOTP(
        email: _emailController.text.trim(),
        token: _otpCode,
        type: OtpType.recovery,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _step = 2;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _updatePassword() async {
    if (_passwordController.text.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _passwordController.text),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset successfully! Please log in.')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.authBackground,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: GestureDetector(
          onTap: () => context.pop(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: AppColors.authSurface, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 14),
              ),
              const SizedBox(width: 12),
              const Text('Back to Login', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppColors.error, fontSize: 13),
                  ),
                ),

              if (_step == 0) _buildEmailStep(),
              if (_step == 1) _buildOtpStep(),
              if (_step == 2) _buildNewPasswordStep(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Ticket Agent Forgot Password',
            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, height: 1.2),
          ),
          const SizedBox(height: 12),
          const Text(
            'Enter the email address linked to your ticket agent account and we\'ll send you a secure password reset OTP.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 40),
          const Text('Ticket Agent Email', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'Enter your email address',
              hintStyle: const TextStyle(color: AppColors.textMuted),
              prefixIcon: const Icon(Icons.mail_outline, color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.authSurface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            validator: (val) {
              if (val == null || val.isEmpty) return 'Email is required';
              if (!val.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 12),
          const Text(
            'Check your inbox for the reset OTP and follow the instructions to create a new password.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 60),
          _buildSubmitButton('Send Password Reset OTP', _sendOtp),
          const SizedBox(height: 16),
          const Text(
            'If you don\'t receive the email, check your spam folder or contact support for assistance.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Verify OTP',
          style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Text(
          'Enter the 6-digit code sent to ${_emailController.text.trim()}',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 15, height: 1.5),
        ),
        const SizedBox(height: 48),
        Center(
          child: PinInputWidget(
            length: 6,
            onChanged: (val) => _otpCode = val,
            onCompleted: (val) {
              _otpCode = val;
              _verifyOtp();
            },
          ),
        ),
        const SizedBox(height: 32),
        _buildSubmitButton('Verify', _verifyOtp),
      ],
    );
  }

  Widget _buildNewPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'New Password',
          style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        const Text(
          'Enter your new secure password.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 15, height: 1.5),
        ),
        const SizedBox(height: 40),
        const Text('New Password', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          style: const TextStyle(color: Colors.white),
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            hintText: 'Enter new password',
            hintStyle: const TextStyle(color: AppColors.textMuted),
            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppColors.textMuted),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            filled: true,
            fillColor: AppColors.authSurface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 32),
        _buildSubmitButton('Update Password', _updatePassword),
      ],
    );
  }

  Widget _buildSubmitButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: _isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.authPrimary,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: _isLoading
          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
    );
  }
}
