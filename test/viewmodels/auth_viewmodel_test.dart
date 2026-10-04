// =============================================================================
// FILE: test/viewmodels/auth_viewmodel_test.dart
// LAYER: Test
//
// PURPOSE:
//   Unit tests for AuthViewModel — specifically the state transitions
//   during sign-in, sign-out, and session restore.
//
// WHAT WE ARE TESTING:
//   1. signIn() sets isLoading = true during the call, then user on success.
//   2. signIn() sets errorMessage when credentials are wrong.
//   3. signOut() resets state to the initial empty AuthState.
//   4. restoreSession() returns the user and updates state if session exists.
//   5. restoreSession() returns null and clears state if no session exists.
//   6. AuthState.copyWith() correctly handles all flag combinations.
//
// STRATEGY — Fake AuthRepository:
//   We create a FakeAuthRepository that we can configure per-test:
//     - shouldSucceed = true  → signIn() returns a real UserModel
//     - shouldSucceed = false → signIn() throws an exception
//   This lets us test the ViewModel in isolation from Supabase.
// =============================================================================

import 'package:driver_agent_fyp/models/user_model.dart';
import 'package:driver_agent_fyp/repositories/auth_repository.dart';
import 'package:driver_agent_fyp/viewmodels/auth_viewmodel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// =============================================================================
// Fake Repository
// =============================================================================

/// A fake AuthRepository for testing.
///
/// Configurable via constructor flags so each test scenario can
/// control what the repository returns without real Supabase calls.
class FakeAuthRepository implements AuthRepository {
  /// When false, signIn() throws an AuthException.
  final bool shouldSignInSucceed;

  /// When null, getCurrentUser() returns null (no active session).
  final UserModel? existingUser;

  FakeAuthRepository({
    this.shouldSignInSucceed = true,
    this.existingUser,
  });

  /// The user that a successful sign-in will return.
  static final _fakeAgent = UserModel(
    id: 'user-agent-test-001',
    role: UserRole.agent,
    name: 'Test Agent',
  );

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    if (!shouldSignInSucceed) {
      throw Exception('Invalid login credentials.');
    }
    return _fakeAgent;
  }

  @override
  Future<void> signOut() async {
    // No-op in tests — just succeeds silently.
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    return existingUser;
  }

  @override
  Future<void> signUpStudent({
    required String email,
    required String password,
    required String firstName,
  }) async {}

  @override
  Future<String> verifyOtp({
    required String email,
    required String otp,
  }) async {
    return 'fake-user-id';
  }

  @override
  Future<UserModel> updateUserProfile({
    required String userId,
    required String firstName,
    String? lastName,
    String? phone,
    String? department,
    String? username,
  }) async {
    return _fakeAgent;
  }

  @override
  Future<UserModel> createStudentProfile({
    required String userId,
    required String firstName,
    String? lastName,
    String? phone,
    String? department,
    String? username,
  }) async {
    return _fakeAgent;
  }

  @override
  Future<void> setTransactionPin(String pin) async {
    // Fake implementation
  }

  @override
  Future<bool> hasTransactionPin() async {
    return true; // Fake implementation
  }
}

// =============================================================================
// Test Helper
// =============================================================================

/// Builds a [ProviderContainer] with the given [FakeAuthRepository] injected.
ProviderContainer _buildContainer(FakeAuthRepository fakeRepo) {
  return ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(fakeRepo),
    ],
  );
}

// =============================================================================
// Tests
// =============================================================================

void main() {
  group('AuthViewModel — signIn()', () {
    test('sets user in state after a successful sign-in', () async {
      final container = _buildContainer(FakeAuthRepository(shouldSignInSucceed: true));
      final vm = container.read(authViewModelProvider.notifier);

      await vm.signIn(email: 'agent@test.com', password: 'password123');

      final state = container.read(authViewModelProvider);
      expect(state.isLoading, isFalse);
      expect(state.user, isNotNull);
      expect(state.user!.name, equals('Test Agent'));
      expect(state.user!.role, equals(UserRole.agent));
      expect(state.errorMessage, isNull);
    });

    test('sets errorMessage in state after a failed sign-in', () async {
      final container = _buildContainer(FakeAuthRepository(shouldSignInSucceed: false));
      final vm = container.read(authViewModelProvider.notifier);

      await vm.signIn(email: 'wrong@test.com', password: 'wrongpassword');

      final state = container.read(authViewModelProvider);
      expect(state.isLoading, isFalse);
      expect(state.user, isNull);
      expect(state.errorMessage, isNotNull);
      expect(state.errorMessage, contains('Invalid login credentials'));
    });

    test('clears any previous error message on a new sign-in attempt', () async {
      // Arrange: put the ViewModel in an error state
      final container = _buildContainer(FakeAuthRepository(shouldSignInSucceed: true));
      container.read(authViewModelProvider.notifier).state =
          const AuthState(errorMessage: 'Old error message');

      // Act: start a new (successful) sign-in
      await container
          .read(authViewModelProvider.notifier)
          .signIn(email: 'agent@test.com', password: 'pass');

      // Assert: old error is gone
      final state = container.read(authViewModelProvider);
      expect(state.errorMessage, isNull);
      expect(state.user, isNotNull);
    });
  });

  group('AuthViewModel — signOut()', () {
    test('resets state to initial after sign-out', () async {
      // Arrange: put the ViewModel in a logged-in state
      final container = _buildContainer(FakeAuthRepository());
      container.read(authViewModelProvider.notifier).state = AuthState(
        user: UserModel(
          id: 'user-001',
          role: UserRole.agent,
          name: 'Active Agent',
        ),
      );

      // Act
      await container.read(authViewModelProvider.notifier).signOut();

      // Assert: state is fully reset
      final state = container.read(authViewModelProvider);
      expect(state.user, isNull);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
    });
  });

  group('AuthViewModel — restoreSession()', () {
    test('restores user from an existing Supabase session', () async {
      final existingUser = UserModel(
        id: 'user-driver-001',
        role: UserRole.driver,
        name: 'Bus Driver Emeka',
      );
      final container = _buildContainer(
        FakeAuthRepository(existingUser: existingUser),
      );

      final result = await container
          .read(authViewModelProvider.notifier)
          .restoreSession();

      expect(result, isNotNull);
      expect(result!.name, equals('Bus Driver Emeka'));
      expect(result.role, equals(UserRole.driver));

      // State should also be updated
      final state = container.read(authViewModelProvider);
      expect(state.user?.id, equals('user-driver-001'));
    });

    test('returns null when no active session exists', () async {
      final container = _buildContainer(
        FakeAuthRepository(existingUser: null), // no active session
      );

      final result = await container
          .read(authViewModelProvider.notifier)
          .restoreSession();

      expect(result, isNull);

      final state = container.read(authViewModelProvider);
      expect(state.user, isNull);
      expect(state.isLoading, isFalse);
    });
  });

  // ── AuthState.copyWith ────────────────────────────────────────────────────

  group('AuthState.copyWith()', () {
    test('clearError = true removes the errorMessage', () {
      const state = AuthState(errorMessage: 'Something went wrong');
      final updated = state.copyWith(clearError: true);
      expect(updated.errorMessage, isNull);
    });

    test('clearUser = true removes the user', () {
      final state = AuthState(
        user: UserModel(id: 'u1', role: UserRole.agent, name: 'John'),
      );
      final updated = state.copyWith(clearUser: true);
      expect(updated.user, isNull);
    });

    test('setting isLoading does not affect other fields', () {
      final state = AuthState(
        user: UserModel(id: 'u1', role: UserRole.agent, name: 'John'),
        errorMessage: 'err',
      );
      final updated = state.copyWith(isLoading: true);
      expect(updated.isLoading, isTrue);
      expect(updated.user, isNotNull); // preserved
      expect(updated.errorMessage, equals('err')); // preserved
    });
  });

  // ── UserRole ──────────────────────────────────────────────────────────────

  group('UserRole', () {
    test('fromString parses all valid role strings', () {
      expect(UserRole.fromString('Admin'), equals(UserRole.admin));
      expect(UserRole.fromString('Agent'), equals(UserRole.agent));
      expect(UserRole.fromString('Driver'), equals(UserRole.driver));
      expect(UserRole.fromString('Student'), equals(UserRole.student));
    });

    test('fromString is case-insensitive', () {
      expect(UserRole.fromString('agent'), equals(UserRole.agent));
      expect(UserRole.fromString('DRIVER'), equals(UserRole.driver));
    });

    test('fromString throws ArgumentError for unknown roles', () {
      expect(
        () => UserRole.fromString('Conductor'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('toDbString produces the correct capitalised string', () {
      expect(UserRole.agent.toDbString(), equals('Agent'));
      expect(UserRole.driver.toDbString(), equals('Driver'));
      expect(UserRole.admin.toDbString(), equals('Admin'));
      expect(UserRole.student.toDbString(), equals('Student'));
    });
  });
}
