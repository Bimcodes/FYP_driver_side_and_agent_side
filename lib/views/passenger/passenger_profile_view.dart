import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/loading_overlay.dart';
import '../../models/user_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/passenger_dashboard_viewmodel.dart';
import '../agent/profile/agent_pin_settings_view.dart';
import '../widgets/app_notification.dart';

class PassengerProfileView extends ConsumerWidget {
  const PassengerProfileView({super.key});

  void _showEditProfileModal(BuildContext context, WidgetRef ref, UserModel? user) {
    final firstNameController = TextEditingController(text: user?.firstName ?? user?.name.split(' ').first ?? '');
    final lastNameController = TextEditingController(text: user?.lastName ?? (user?.name.contains(' ') == true ? user!.name.split(' ').sublist(1).join(' ') : ''));
    final usernameController = TextEditingController(text: user?.username ?? '');
    final phoneController = TextEditingController(text: user?.phone ?? '');
    final deptController = TextEditingController(text: user?.department ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.agentCardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (modalCtx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Edit Profile',
                  style: TextStyle(color: AppColors.agentTextDark, fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: firstNameController,
                  decoration: InputDecoration(
                    labelText: 'First Name',
                    filled: true,
                    fillColor: AppColors.agentLightBackground,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: lastNameController,
                  decoration: InputDecoration(
                    labelText: 'Last Name',
                    filled: true,
                    fillColor: AppColors.agentLightBackground,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    filled: true,
                    fillColor: AppColors.agentLightBackground,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    filled: true,
                    fillColor: AppColors.agentLightBackground,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: deptController,
                  decoration: InputDecoration(
                    labelText: 'Department',
                    filled: true,
                    fillColor: AppColors.agentLightBackground,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    final fn = firstNameController.text.trim();
                    if (fn.isEmpty) {
                      AppNotification.showError(modalCtx, 'First name is required.');
                      return;
                    }
                    LoadingOverlay.show(modalCtx);
                    try {
                      await ref.read(authViewModelProvider.notifier).updateUserProfile(
                        firstName: fn,
                        lastName: lastNameController.text.trim(),
                        username: usernameController.text.trim(),
                        phone: phoneController.text.trim(),
                        department: deptController.text.trim(),
                      );
                      if (modalCtx.mounted) {
                        LoadingOverlay.hide(modalCtx);
                        Navigator.pop(modalCtx);
                        AppNotification.showSuccess(context, 'Profile updated successfully!');
                      }
                    } catch (e) {
                      if (modalCtx.mounted) {
                        LoadingOverlay.hide(modalCtx);
                        AppNotification.showError(modalCtx, 'Failed to update profile: $e');
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.authPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);
    final user = authState.user;
    final dashState = ref.watch(passengerDashboardViewModelProvider);

    final name = user?.displayName.isNotEmpty == true ? user!.displayName : 'Student';
    final initials = name.split(' ').where((e) => e.isNotEmpty).take(2).map((e) => e[0]).join().toUpperCase();
    final phone = user?.phone?.isNotEmpty == true ? user!.phone! : 'Not provided';
    final department = user?.department?.isNotEmpty == true ? user!.department! : 'Not specified';
    final username = user?.username?.isNotEmpty == true ? '@${user!.username}' : '@student';
    final walletId = dashState.wallet?.id ?? 'Not loaded';
    return Scaffold(
      backgroundColor: AppColors.agentLightBackground, // Consistent light theme
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // ── Title & Edit Action ───────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'PROFILE',
                  style: TextStyle(color: AppColors.agentTextDark, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                ),
                TextButton.icon(
                  onPressed: () => _showEditProfileModal(context, ref, user),
                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.agentGreenText),
                  label: const Text('Edit', style: TextStyle(color: AppColors.agentGreenText, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Student Info Card ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.agentCardWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: AppColors.authPrimary,
                        child: Text(
                          initials.isEmpty ? 'ST' : initials,
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(color: AppColors.agentTextDark, fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(username, style: const TextStyle(color: AppColors.agentGreenText, fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(department, style: const TextStyle(color: AppColors.agentTextLight, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(color: Color(0xFFE2E8F0), height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.phone_outlined, color: AppColors.agentTextLight, size: 18),
                          SizedBox(width: 8),
                          Text('Phone Number', style: TextStyle(color: AppColors.agentTextLight, fontSize: 13)),
                        ],
                      ),
                      Text(phone, style: const TextStyle(color: AppColors.agentTextDark, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Wallet Details Card ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.agentCardWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Student Transit Wallet', style: TextStyle(color: AppColors.agentTextDark, fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Wallet ID', style: TextStyle(color: AppColors.agentTextLight, fontSize: 13)),
                      GestureDetector(
                        onTap: () {
                          if (walletId != 'Not loaded') {
                            Clipboard.setData(ClipboardData(text: walletId));
                            AppNotification.showSuccess(context, 'Wallet ID copied to clipboard!');
                          }
                        },
                        child: Row(
                          children: [
                            Text(
                              walletId.length > 16 ? '...${walletId.substring(walletId.length - 12)}' : walletId,
                              style: const TextStyle(color: AppColors.agentTextDark, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.copy_rounded, color: AppColors.agentGreenText, size: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Current Balance', style: TextStyle(color: AppColors.agentTextLight, fontSize: 13)),
                      Text(
                        '₦${(dashState.wallet?.balance ?? 0.0).toStringAsFixed(0)}',
                        style: const TextStyle(color: AppColors.agentGreenText, fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Security & Account Settings ──────────────────────────────────
            const Text('Security & Options', style: TextStyle(color: AppColors.agentTextDark, fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),

            // Transaction PIN
            FutureBuilder<bool>(
              future: ref.read(authViewModelProvider.notifier).hasTransactionPin(),
              builder: (context, snapshot) {
                final hasPin = snapshot.data ?? false;
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AgentPinSettingsView()),
                    ).then((_) {
                      // Refresh the future builder on return
                      ref.invalidate(authViewModelProvider);
                    });
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
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Color(0xFFECFDF5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.lock_outline, color: AppColors.agentGreenText, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text('Transaction PIN', style: TextStyle(color: AppColors.agentTextDark, fontSize: 14, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: hasPin ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: hasPin ? AppColors.agentGreenText : const Color(0xFFD97706)),
                                    ),
                                    child: Text(
                                      hasPin ? 'SET' : 'NOT SET',
                                      style: TextStyle(
                                        color: hasPin ? AppColors.agentGreenText : const Color(0xFFD97706),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                hasPin ? 'Tap to change your 4-digit PIN' : 'Tap to set up a 4-digit PIN',
                                style: const TextStyle(color: AppColors.agentTextLight, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.agentTextLight, size: 20),
                      ],
                    ),
                  ),
                );
              }
            ),
            const SizedBox(height: 12),

            // Log Out
            GestureDetector(
              onTap: () {
                ref.read(authViewModelProvider.notifier).signOut();
                context.go(AppRoutes.loginWithEmail);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.agentCardWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.agentRedText.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.agentRedArrow,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.logout, color: AppColors.agentRedText, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Log Out', style: TextStyle(color: AppColors.agentRedText, fontSize: 14, fontWeight: FontWeight.bold)),
                          SizedBox(height: 2),
                          Text('Sign out of your student wallet session', style: TextStyle(color: AppColors.agentRedText, fontSize: 12)),
                        ],
                      ),
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
