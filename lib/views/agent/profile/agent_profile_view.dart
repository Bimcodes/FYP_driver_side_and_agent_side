import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../core/constants/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'agent_pin_settings_view.dart';

class AgentProfileView extends ConsumerWidget {
  const AgentProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);
    final user = authState.user;

    final name = user?.name.isNotEmpty == true ? user!.name : 'Agent';
    final initials = name.split(' ').where((e) => e.isNotEmpty).take(2).map((e) => e[0]).join().toUpperCase();
    final subtitle = user?.phone?.isNotEmpty == true
        ? user!.phone!
        : (user?.username?.isNotEmpty == true ? '@${user!.username}' : 'Agent Account');

    return Scaffold(
      backgroundColor: AppColors.agentLightBackground,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            // ── Header ────────────────────────────────────────────────────────
            const Text(
              'Agent Profile',
              style: TextStyle(color: AppColors.agentTextDark, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5),
            ),
            const SizedBox(height: 8),
            const Text(
              'Latest security and account controls',
              style: TextStyle(color: AppColors.agentTextLight, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 32),

            // ── Avatar & Info ─────────────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.agentBlue,
                    child: Text(
                      initials.isEmpty ? 'A' : initials,
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: const TextStyle(color: AppColors.agentTextDark, fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppColors.agentTextLight, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.agentGreenText.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Active profile',
                      style: TextStyle(color: AppColors.agentGreenText, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // ── Security Section ──────────────────────────────────────────────
            const Text(
              'Security',
              style: TextStyle(color: AppColors.agentTextDark, fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              'Protect access to your terminal and transactions.',
              style: TextStyle(color: AppColors.agentTextLight, fontSize: 13),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AgentPinSettingsView()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.agentCardWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.agentBlue.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_outline, color: AppColors.agentBlue, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Transaction PIN', style: TextStyle(color: AppColors.agentTextDark, fontSize: 15, fontWeight: FontWeight.w700)),
                          SizedBox(height: 4),
                          Text(
                            'Set or change your 4-digit PIN to secure cash handling and terminal access.',
                            style: TextStyle(color: AppColors.agentTextLight, fontSize: 12, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.agentBlue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('Required', style: TextStyle(color: AppColors.agentBlue, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── Account Section ───────────────────────────────────────────────
            const Text(
              'Account',
              style: TextStyle(color: AppColors.agentTextDark, fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              'Manage your session and device access.',
              style: TextStyle(color: AppColors.agentTextLight, fontSize: 13),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                ref.read(authViewModelProvider.notifier).signOut();
                context.go(AppRoutes.loginWithEmail); // Per user instruction: log out goes straight to login
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.agentCardWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.agentRedText.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Log Out', style: TextStyle(color: AppColors.agentRedText, fontSize: 15, fontWeight: FontWeight.w700)),
                          SizedBox(height: 4),
                          Text(
                            'End your current session and return to the secure login screen.',
                            style: TextStyle(color: AppColors.agentRedText, fontSize: 12, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.agentRedText.withValues(alpha: 0.5)),
                      ),
                      child: const Icon(Icons.logout, color: AppColors.agentRedText, size: 20),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
