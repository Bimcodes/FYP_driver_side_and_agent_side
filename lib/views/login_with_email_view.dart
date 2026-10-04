import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_routes.dart';
import '../core/theme/app_colors.dart';
import '../models/user_model.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'widgets/app_notification.dart';

class LoginWithEmailView extends ConsumerStatefulWidget {
  const LoginWithEmailView({super.key});

  @override
  ConsumerState<LoginWithEmailView> createState() => _LoginWithEmailViewState();
}

class _LoginWithEmailViewState extends ConsumerState<LoginWithEmailView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Hide keyboard
    FocusScope.of(context).unfocus();

    await ref.read(authViewModelProvider.notifier).signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);

    ref.listen<AuthState>(authViewModelProvider, (prev, next) {
      if (next.user != null && (prev?.user == null)) {
        SharedPreferences.getInstance().then((prefs) {
          prefs.setBool('has_logged_in_before', true);
        });
        
        AppNotification.showSuccess(context, 'Welcome back! You are now logged in.');
        if (next.user!.role == UserRole.agent) {
          context.go(AppRoutes.agentDashboard);
        } else if (next.user!.role == UserRole.student) {
          context.go(AppRoutes.passengerDashboard);
        } else {
          context.go(AppRoutes.driverDashboard);
        }
      }

      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        AppNotification.showError(context, next.errorMessage!);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.authBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
          onPressed: () => context.go(AppRoutes.roleSelect),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                const Text(
                  'METRO PASS',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Account Login',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter your email address and password to sign in to your Metro Pass account.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 40),

                // Email Field
                const Text('Email Address', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'your.email@university.edu',
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
                const SizedBox(height: 24),

                // Password Field & Forgot Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Password', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.forgotPassword),
                      child: const Text('Forgot Password', style: TextStyle(color: AppColors.authPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  style: const TextStyle(color: Colors.white),
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppColors.textMuted),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    filled: true,
                    fillColor: AppColors.authSurface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Password is required';
                    return null;
                  },
                ),
                const SizedBox(height: 48),

                // Login Button
                ElevatedButton(
                  onPressed: authState.isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.authPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: authState.isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Log In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(color: AppColors.authPrimary, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Terminal MT-220 Online & Encrypted',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: TextButton(
                    onPressed: () {
                      context.go(AppRoutes.roleSelect);
                    },
                    child: const Text(
                      'Not you? Switch role',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
