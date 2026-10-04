import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_routes.dart';
import '../core/theme/app_colors.dart';
import '../models/user_model.dart';
import '../viewmodels/auth_viewmodel.dart';

class SplashView extends ConsumerStatefulWidget {
  const SplashView({super.key});

  @override
  ConsumerState<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends ConsumerState<SplashView> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Wait briefly so the splash screen isn't just a flash
    await Future.delayed(const Duration(milliseconds: 1000));
    
    if (!mounted) return;

    final user = await ref.read(authViewModelProvider.notifier).restoreSession();

    if (!mounted) return;

    if (user != null) {
      if (user.role == UserRole.agent) {
        context.go(AppRoutes.agentDashboard);
      } else if (user.role == UserRole.student) {
        context.go(AppRoutes.passengerDashboard);
      } else {
        context.go(AppRoutes.driverDashboard);
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      final hasLoggedIn = prefs.getBool('has_logged_in_before') ?? false;
      if (hasLoggedIn) {
        context.go(AppRoutes.loginWithEmail);
      } else {
        context.go(AppRoutes.roleSelect);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.authBackground,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.authBackground,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.authPrimary.withValues(alpha: 0.1),
                        spreadRadius: 10,
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        color: AppColors.authPrimary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 28),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'METRO PASS',
                  style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.authPrimary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'OPERATIONS',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 40,
            left: 32,
            right: 32,
            child: Column(
              children: [
                const Text(
                  'Initializing Secure Gateway...',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  backgroundColor: AppColors.authSurface,
                  color: AppColors.authPrimary,
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Civic Fintech Protocol v4.8.2',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
