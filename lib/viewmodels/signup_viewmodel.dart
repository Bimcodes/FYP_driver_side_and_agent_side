import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/app_logger.dart';
import '../repositories/auth_repository.dart';

/// State container for the student sign up flow.
class SignupState {
  final bool isLoading;
  final String? errorMessage;
  
  /// Stored after successful sign up so we know where to send the OTP.
  final String? email;
  
  /// Stored after successful sign up for use in onboarding.
  final String? firstName;
  
  /// Stored after successful OTP verification.
  final String? userId;

  const SignupState({
    this.isLoading = false,
    this.errorMessage,
    this.email,
    this.firstName,
    this.userId,
  });

  SignupState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? email,
    String? firstName,
    String? userId,
    bool clearError = false,
  }) {
    return SignupState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      userId: userId ?? this.userId,
    );
  }
}

/// ViewModel managing the three-step signup process:
/// 1. Create account (sends OTP)
/// 2. Verify OTP
/// 3. Submit Onboarding (inserts into public.users)
class SignupViewModel extends Notifier<SignupState> {
  @override
  SignupState build() => const SignupState();

  Future<bool> signUp({
    required String email,
    required String password,
    required String firstName,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signUpStudent(
        email: email,
        password: password,
        firstName: firstName,
      );
      // Save data for next steps
      state = state.copyWith(isLoading: false, email: email, firstName: firstName);
      return true;
    } catch (e) {
      logger.e('[SignupViewModel] signUp failed', error: e);
      _handleError(e);
      return false;
    }
  }

  Future<bool> verifyOtp(String otp) async {
    if (state.email == null) {
      state = state.copyWith(errorMessage: 'Email not found. Please restart sign up.');
      return false;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final userId = await authRepo.verifyOtp(
        email: state.email!,
        otp: otp,
      );
      state = state.copyWith(isLoading: false, userId: userId);
      return true;
    } catch (e) {
      logger.e('[SignupViewModel] verifyOtp failed', error: e);
      _handleError(e);
      return false;
    }
  }

  Future<bool> submitOnboarding({
    String? lastName,
    String? phone,
    String? department,
    String? username,
  }) async {
    if (state.userId == null || state.firstName == null) {
      state = state.copyWith(errorMessage: 'Session error. Please log in again.');
      return false;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      
      // Update public.users table
      await authRepo.createStudentProfile(
        userId: state.userId!,
        firstName: state.firstName!,
        lastName: lastName,
        phone: phone,
        department: department,
        username: username,
      );
      
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      logger.e('[SignupViewModel] onboarding failed', error: e);
      _handleError(e);
      return false;
    }
  }

  void _handleError(Object e) {
    String errorMessage = e.toString();
    if (errorMessage.startsWith('Exception: ')) {
      errorMessage = errorMessage.replaceFirst('Exception: ', '');
    }
    state = state.copyWith(
      isLoading: false,
      errorMessage: errorMessage,
    );
  }
}

final signupViewModelProvider = NotifierProvider<SignupViewModel, SignupState>(
  SignupViewModel.new,
);
