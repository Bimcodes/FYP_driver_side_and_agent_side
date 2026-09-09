import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_routes.dart';
import '../core/theme/app_colors.dart';

/// The initial Welcome screen.
///
/// Presents paths for first-time registration (Scan QR) and 
/// returning user login (Login with Email).
class RoleSelectionView extends StatelessWidget {
  const RoleSelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Logo / Header ──────────────────────────────────────────────
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.agentPrimary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner, 
                    color: AppColors.agentPrimary, 
                    size: 64,
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // ── Title ──────────────────────────────────────────────────────
              const Text(
                'Welcome to',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'QR Fare Transit',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Access your dashboard to manage transit operations.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 64),

              // ── Scan Button (First Time) ──────────────────────────────────
              ElevatedButton.icon(
                onPressed: () => context.push(AppRoutes.qrRegister),
                icon: const Icon(Icons.qr_code_scanner, size: 24, color: Colors.white),
                label: const Text(
                  'First Time? Scan QR Code',
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.agentPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  elevation: 8,
                  shadowColor: AppColors.agentPrimary.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Manual Login (Returning) ──────────────────────────────────
              OutlinedButton.icon(
                onPressed: () => context.push(AppRoutes.loginWithEmail),
                icon: const Icon(Icons.email_outlined, size: 24, color: AppColors.textPrimary),
                label: const Text(
                  'Already setup? Log in',
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
