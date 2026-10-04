import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../viewmodels/signup_viewmodel.dart';
import '../widgets/app_notification.dart';

class StudentSignupView extends ConsumerStatefulWidget {
  const StudentSignupView({super.key});

  @override
  ConsumerState<StudentSignupView> createState() => _StudentSignupViewState();
}

class _StudentSignupViewState extends ConsumerState<StudentSignupView> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _passwordsMatch =>
      _passwordController.text.isNotEmpty &&
      _passwordController.text.length >= 6 &&
      _passwordController.text == _confirmPasswordController.text;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_passwordController.text != _confirmPasswordController.text) {
      AppNotification.showError(context, 'Passwords do not match');
      return;
    }

    final success = await ref.read(signupViewModelProvider.notifier).signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      firstName: _firstNameController.text.trim(),
    );

    if (success && mounted) {
      context.push(AppRoutes.passengerOtp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signupViewModelProvider);
    final hasError = state.errorMessage != null;

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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Icon
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF0C241E),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_add_outlined, color: AppColors.authPrimary, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'GET STARTED',
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Create your student transit pass',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Top Error Banner (Image 4)
                if (hasError) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF450A0A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEF4444)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Color(0xFFEF4444), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            state.errorMessage!,
                            style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // First Name
                const Text('First Name', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _firstNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Anna',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.authSurface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'First name is required';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Email Address
                const Text('Email Address', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'anna.smith@university.edu',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.authSurface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Email is required';
                    if (!value.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Password
                const Text('Password', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  style: const TextStyle(color: Colors.white),
                  obscureText: _obscurePassword,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textMuted),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    filled: true,
                    fillColor: AppColors.authSurface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    enabledBorder: hasError ? OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEF4444))) : null,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Password is required';
                    if (value.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Confirm Password
                const Text('Confirm Password', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmPasswordController,
                  style: const TextStyle(color: Colors.white),
                  obscureText: _obscureConfirmPassword,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textMuted),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                    filled: true,
                    fillColor: AppColors.authSurface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    enabledBorder: hasError ? OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEF4444))) : null,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please confirm your password';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Validation Status
                if (_passwordsMatch)
                  Row(
                    children: const [
                      Icon(Icons.check, color: AppColors.authPrimary, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Password matches and meets strength criteria.',
                        style: TextStyle(color: AppColors.authPrimary, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),

                // Lower Error Banner (Image 4)
                if (hasError) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8E2428), // Dark red from Image 4
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.info_outline, color: Colors.white, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Registration failed. Please check inputs.',
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                // Submit Button
                ElevatedButton(
                  onPressed: state.isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.authPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: state.isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text('Creating Account... ', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            SizedBox(width: 8),
                            SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                          ],
                        )
                      : const Text(
                          'Create Account',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: 24),

                Center(
                  child: GestureDetector(
                    onTap: () => context.push(AppRoutes.loginWithEmail),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text('Already have an account? ', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        Text('Log In', style: TextStyle(color: AppColors.authPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
