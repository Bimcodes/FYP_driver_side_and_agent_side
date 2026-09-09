import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
      } else {
        context.go(AppRoutes.driverDashboard);
      }
    } else {
      context.go(AppRoutes.roleSelect);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_2,
              size: 80,
              color: AppColors.agentPrimary,
            ),
            SizedBox(height: 24),
            Text(
              'QR Fare Transit',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 32),
            CircularProgressIndicator(
              color: AppColors.agentPrimary,
            ),
          ],
        ),
      ),
    );
  }
}
