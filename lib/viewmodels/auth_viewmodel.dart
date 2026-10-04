// =============================================================================
// FILE: viewmodels/auth_viewmodel.dart
// LAYER: ViewModel (Logic Layer)
//
// PURPOSE:
//   Manages all state and logic for the authentication flow.
//   This is the intermediary between the Login View and the Auth Repository.
//
// MVVM ROLE:
//   ViewModel. The Login View reads state from here and calls actions here.
//   This class never imports Flutter UI widgets. It only knows about:
//     - AuthRepository (to perform sign-in/out)
//     - UserModel (the resulting data)
//     - Riverpod (to expose state to the View)
//
// WHAT IS Riverpod AsyncNotifier?
//   AsyncNotifier<T> is the ViewModel pattern in Riverpod.
//   - T is the state type — here it's UserModel? (the logged-in user, or null).
//   - `build()` is called once when first watched. It returns the initial state.
//   - `state` is what the View reads. It can be:
//       AsyncData(user)    → user is logged in
//       AsyncLoading()     → login is in progress
//       AsyncError(e, st)  → login failed with an error message
//
//   The View uses a `.when(data:, loading:, error:)` pattern to render
//   different UI based on which of those three states is active.
//
// ADMIN DASHBOARD EQUIVALENT:
//   In the admin dashboard, this is equivalent to the custom hooks like
//   `useAgentViewModel.ts` — they hold state and expose actions to React components.
//   Here, AuthViewModel does the same for Dart Widgets.
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/app_error_handler.dart';
import '../core/utils/app_logger.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

/// State container for the authentication flow.
///
/// Holds the current form field values AND any error messages.
/// This is separate from the user data itself — it tracks what's
/// happening on the login form.
class AuthState {
  /// Whether the sign-in API call is in progress.
  final bool isLoading;

  /// Error message to display to the user. Null if no error.
  final String? errorMessage;

  /// The currently logged-in user. Null if not authenticated.
  final UserModel? user;

  const AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.user,
  });

  /// Returns a copy of this state with specified fields changed.
  /// Used to update state immutably (we never mutate state directly).
  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    UserModel? user,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      user: clearUser ? null : (user ?? this.user),
    );
  }
}

/// ViewModel managing the authentication state and sign-in logic.
///
/// [MVVM ROLE]: ViewModel — coordinates between LoginView and AuthRepository.
///
/// HOW THE VIEW USES THIS:
/// ```dart
/// // In the Login View:
/// final authState = ref.watch(authViewModelProvider);
///
/// // Read loading state:
/// if (authState.isLoading) { ... }
///
/// // Read error message:
/// if (authState.errorMessage != null) { Text(authState.errorMessage!) }
///
/// // Trigger sign-in:
/// ref.read(authViewModelProvider.notifier).signIn(
///   email: emailController.text,
///   password: passwordController.text,
///   expectedRole: selectedRole,
/// );
/// ```
class AuthViewModel extends Notifier<AuthState> {
  /// build() defines the INITIAL STATE when this ViewModel is first created.
  ///
  /// We start with no user (not logged in) and no loading.
  @override
  AuthState build() {
    return const AuthState();
  }

  // ── Actions ────────────────────────────────────────────────────────────────
  // Actions are public methods that Views call when the user interacts with the UI.
  // They update `state` to reflect what's happening.

  /// Attempts to sign in with the provided credentials.
  ///
  /// Updates state through three phases:
  ///   1. isLoading = true  (spinner shows in View)
  ///   2. On success: user is populated, View navigates away
  ///   3. On failure: errorMessage is populated, View shows error text
  ///
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    logger.i('[AuthViewModel] signIn() → email: $email');
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final user = await authRepo.signIn(
        email: email,
        password: password,
      );
      logger.i('[AuthViewModel] ✅ signIn success — user: ${user.name} | role: ${user.role.toDbString()}');
      state = state.copyWith(isLoading: false, user: user);

    } catch (e, st) {
      logger.e('[AuthViewModel] signIn failed', error: e, stackTrace: st);
      final errorMessage = AppErrorHandler.toUserMessage(e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: errorMessage,
        clearUser: true,
      );
    }
  }

  Future<void> setTransactionPin(String pin) async {
    final user = state.user;
    if (user == null) return;

    logger.i('[AuthViewModel] setTransactionPin()');
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.setTransactionPin(pin);
      logger.i('[AuthViewModel] ✅ Transaction PIN updated');
    } catch (e, st) {
      logger.e('[AuthViewModel] Failed to update PIN', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<bool> hasTransactionPin() async {
    try {
      return await ref.read(authRepositoryProvider).hasTransactionPin();
    } catch (e) {
      return false;
    }
  }

  /// Updates the logged-in user's profile details.
  Future<void> updateUserProfile({
    required String firstName,
    String? lastName,
    String? phone,
    String? department,
    String? username,
  }) async {
    final user = state.user;
    if (user == null) return;

    logger.i('[AuthViewModel] updateUserProfile()');
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final updatedUser = await authRepo.updateUserProfile(
        userId: user.id,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        department: department,
        username: username,
      );
      state = state.copyWith(user: updatedUser);
      logger.i('[AuthViewModel] ✅ Profile updated in state');
    } catch (e, st) {
      logger.e('[AuthViewModel] Failed to update profile', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Attempts to restore an existing session from Supabase on app launch.
  /// 
  /// Returns the restored UserModel if successful, or null if no active session exists.
  Future<UserModel?> restoreSession() async {
    logger.i('[AuthViewModel] restoreSession() called');
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final user = await authRepo.getCurrentUser();
      if (user != null) {
        logger.i('[AuthViewModel] ✅ Session restored successfully');
        state = state.copyWith(isLoading: false, user: user);
        return user;
      } else {
        logger.i('[AuthViewModel] No active session found');
        state = state.copyWith(isLoading: false, clearUser: true);
        return null;
      }
    } catch (e) {
      logger.e('[AuthViewModel] Error restoring session', error: e);
      state = state.copyWith(isLoading: false, clearUser: true);
      return null;
    }
  }

  /// Signs out the current user and resets state to initial.
  Future<void> signOut() async {
    logger.i('[AuthViewModel] signOut() called');
    final authRepo = ref.read(authRepositoryProvider);
    await authRepo.signOut();
    logger.i('[AuthViewModel] ✅ State reset — user is now null');
    state = const AuthState();
  }
}

// ── Riverpod Provider ────────────────────────────────────────────────────────

/// Provides the [AuthViewModel] and exposes [AuthState] to the View layer.
///
/// The Login View watches this provider to read loading/error/user state.
final authViewModelProvider = NotifierProvider<AuthViewModel, AuthState>(
  AuthViewModel.new,
);
