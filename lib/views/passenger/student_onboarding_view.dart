import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/signup_viewmodel.dart';

class StudentOnboardingView extends ConsumerStatefulWidget {
  const StudentOnboardingView({super.key});

  @override
  ConsumerState<StudentOnboardingView> createState() => _StudentOnboardingViewState();
}

class _StudentOnboardingViewState extends ConsumerState<StudentOnboardingView> {
  final _usernameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _departmentController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final success = await ref.read(signupViewModelProvider.notifier).submitOnboarding(
      lastName: _lastNameController.text.trim().isEmpty ? null : _lastNameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      department: _departmentController.text.trim().isEmpty ? null : _departmentController.text.trim(),
      username: _usernameController.text.trim().isEmpty ? null : _usernameController.text.trim(),
    );

    if (success && mounted) {
      await ref.read(authViewModelProvider.notifier).restoreSession();
      if (mounted) {
        context.go(AppRoutes.splash);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signupViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.authBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'STUDENT PROFILE',
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.2),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: _submit,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.authSurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Skip', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Complete your registration to activate automatic campus discounts and secure wallet features.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 32),

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
                const SizedBox(height: 20),
              ],

              // Username
              const Text('Username', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _usernameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'annasmith',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.authSurface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),

              // Last Name
              const Text('Last Name', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _lastNameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Smith',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.authSurface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),

              // Phone Number
              const Text('Phone Number', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: '+234 802 881 9201',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.authSurface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),

              // Department
              const Text('Department', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _departmentController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Computer Science',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.authSurface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.info_outline, color: AppColors.textMuted, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Department information will be verified via student credentials.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),

              // Finish Setup Button
              ElevatedButton(
                onPressed: state.isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.authPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: state.isLoading
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Finish Setup', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
