import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_routes.dart';
import '../core/theme/app_colors.dart';

enum AppRoleType { passenger, agent, driver }

/// The initial Welcome / Role Selection screen.
///
/// Allows Passengers, Ticket Agents, and Transit Drivers to select their role,
/// start registration/signup, or log in to an existing account.
class RoleSelectionView extends StatefulWidget {
  const RoleSelectionView({super.key});

  @override
  State<RoleSelectionView> createState() => _RoleSelectionViewState();
}

class _RoleSelectionViewState extends State<RoleSelectionView> {
  AppRoleType _selectedRole = AppRoleType.passenger;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.authBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 36),
              const Text(
                'METRO PASS',
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 1.2),
              ),
              const SizedBox(height: 12),
              const Text(
                'Select Your Role',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose your account type to sign up or sign in to your dashboard.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 28),

              // ── Passenger / Student Card ─────────────────────────────────────
              _buildRoleCard(
                type: AppRoleType.passenger,
                icon: Icons.person_outline,
                title: 'Passenger / Student',
                description: 'Manage digital cards, top up tokens, and pay transit fares.',
                signUpLabel: 'New Student? Sign Up',
                onSignUp: () => context.push(AppRoutes.passengerSignup),
              ),
              const SizedBox(height: 16),

              // ── Ticket Agent Card ───────────────────────────────────────────
              _buildRoleCard(
                type: AppRoleType.agent,
                icon: Icons.shield_outlined,
                title: 'Ticket Agent',
                description: 'Issue tokens, manage terminal vault, and transfer to students.',
                signUpLabel: 'First-time Terminal Register',
                onSignUp: () => context.push(AppRoutes.qrRegister),
              ),
              const SizedBox(height: 16),

              // ── Transit Driver Card ─────────────────────────────────────────
              _buildRoleCard(
                type: AppRoleType.driver,
                icon: Icons.directions_bus_outlined,
                title: 'Transit Driver / Guard',
                description: 'Verify passenger QR passes and validate onboard payments.',
                signUpLabel: 'Driver Registration',
                onSignUp: () => context.push(AppRoutes.qrRegister),
              ),

              const Spacer(),

              // ── Login Button ────────────────────────────────────────────────
              ElevatedButton(
                onPressed: () => context.push(AppRoutes.loginWithEmail),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.authPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _getLoginButtonLabel(),
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Operational systems subject to logging under Law Title 14-C.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _getLoginButtonLabel() {
    switch (_selectedRole) {
      case AppRoleType.passenger:
        return 'Log In as Passenger';
      case AppRoleType.agent:
        return 'Log In as Ticket Agent';
      case AppRoleType.driver:
        return 'Log In as Driver';
    }
  }

  Widget _buildRoleCard({
    required AppRoleType type,
    required IconData icon,
    required String title,
    required String description,
    required String signUpLabel,
    required VoidCallback onSignUp,
  }) {
    final isSelected = _selectedRole == type;

    return GestureDetector(
      onTap: () => setState(() => _selectedRole = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.authBackground : AppColors.authSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.authPrimary : Colors.transparent,
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0C241E) : const Color(0xFF1E2430),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? AppColors.authPrimary : AppColors.textSecondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.authPrimary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('SELECTED', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(height: 16),
              const Divider(color: Color(0xFF1E2430), height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: onSignUp,
                    child: Text(
                      signUpLabel,
                      style: const TextStyle(color: AppColors.authPrimary, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.loginWithEmail),
                    child: Row(
                      children: const [
                        Text('Already registered? ', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        Text('Log in', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
