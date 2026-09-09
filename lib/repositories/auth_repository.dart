// =============================================================================
// FILE: repositories/auth_repository.dart
// LAYER: Repository (Data Access Layer)
//
// PURPOSE:
//   Handles all authentication operations using Supabase Auth.
//   This is the ONLY file in the app that calls Supabase's auth API.
//
// MVVM ROLE:
//   Repository layer. Called by AuthViewModel. Never called directly by Views.
//
//   VIEW (login_view.dart)
//     ↓ calls signIn()
//   VIEWMODEL (auth_viewmodel.dart)
//     ↓ calls signIn()
//   REPOSITORY (auth_repository.dart)      ← YOU ARE HERE
//     ↓ calls Supabase.auth.signInWithPassword()
//   SUPABASE AUTH (cloud)
//
// HOW SUPABASE AUTH WORKS:
//   Supabase Auth is essentially a built-in user accounts system.
//   When a user calls signIn(), Supabase:
//   1. Verifies the email + password against its internal auth store.
//   2. Returns a Session object containing a JWT access token.
//   3. Supabase Flutter SDK automatically stores this token — every
//      subsequent database query is automatically authenticated.
//
//   The JWT token is what Supabase uses to identify WHO is making each
//   database query — which is how Row Level Security (RLS) policies work.
//
// ROLE VALIDATION:
//   After login, we query the `users` table to verify that the logged-in
//   user's role matches what they selected on the Role Selection screen.
//   If they selected "Driver" but their DB role is "Agent", they are rejected.
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/network/supabase_client.dart';
import '../core/utils/app_logger.dart';
import '../models/user_model.dart';

/// Handles sign-in, sign-out, and current user queries via Supabase Auth.
///
/// [MVVM ROLE]: Repository — data access only. No state, no UI.
///
/// The AuthViewModel owns an instance of this class (via Riverpod)
/// and calls its methods to perform auth operations.
class AuthRepository {
  /// The Supabase client — injected via constructor for testability.
  final SupabaseClient _client;

  const AuthRepository(this._client);

  // ── Sign In ───────────────────────────────────────────────────────────────

  /// Authenticates a user with email and password.
  ///
  /// Returns the [UserModel] of the authenticated user if the login succeeds.
  ///
  /// Throws an [AuthException] if credentials are wrong.
  ///
  /// How it works step by step:
  ///   1. Calls Supabase Auth to authenticate the credentials.
  ///   2. Extracts the authenticated user's UUID from the session.
  ///   3. Queries the `users` table for that UUID to get the profile.
  ///   4. Validates that profile.role == expectedRole.
  ///   5. Returns the UserModel on success.
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    logger.i('[AuthRepository] signIn() → email: $email');

    // Step 1: Authenticate with Supabase Auth.
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    logger.d('[AuthRepository] Supabase Auth responded — checking session...');

    // Step 2: Extract the authenticated user's UUID.
    final authUser = response.user;
    if (authUser == null) {
      logger.e('[AuthRepository] signIn failed — Supabase returned null user');
      throw Exception('Authentication failed: No user returned.');
    }
    logger.d('[AuthRepository] Auth user UUID: ${authUser.id}');

    // Step 3: Fetch the user's profile from our custom `users` table.
    logger.d('[AuthRepository] Querying users table for id: ${authUser.id}');
    final userData = await _client
        .from('users')
        .select()
        .eq('id', authUser.id)
        .single();

    final userModel = UserModel.fromJson(userData);
    logger.d('[AuthRepository] User profile found — name: ${userModel.name} | role: ${userModel.role.toDbString()}');

    logger.i('[AuthRepository] ✅ Sign-in successful for ${userModel.name} (${userModel.role.toDbString()})');
    return userModel;
  }

  // ── Sign Out ──────────────────────────────────────────────────────────────

  /// Signs the current user out and clears the local session.
  ///
  /// After this call, Supabase no longer has an active session.
  /// The app router redirects back to the Role Selection screen.
  Future<void> signOut() async {
    logger.i('[AuthRepository] signOut() called — clearing Supabase session');
    await _client.auth.signOut();
    logger.i('[AuthRepository] ✅ Session cleared');
  }

  // ── Current Session ───────────────────────────────────────────────────────

  /// Returns the currently authenticated user's profile, or null if not signed in.
  ///
  /// Called at app startup to restore a previous session (if the user
  /// did not sign out before closing the app).
  Future<UserModel?> getCurrentUser() async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) {
      logger.d('[AuthRepository] getCurrentUser() → no active session');
      return null;
    }
    logger.d('[AuthRepository] getCurrentUser() → restoring session for ${authUser.id}');

    try {
      final userData = await _client
          .from('users')
          .select()
          .eq('id', authUser.id)
          .single();
      final user = UserModel.fromJson(userData);
      logger.i('[AuthRepository] ✅ Session restored for ${user.name}');
      return user;
    } catch (e) {
      logger.w('[AuthRepository] getCurrentUser() — users table row missing, treating as unauthenticated');
      return null;
    }
  }
}

// ── Riverpod Provider ────────────────────────────────────────────────────────

/// Provides the [AuthRepository] to Riverpod consumers.
///
/// The AuthViewModel reads this provider to get an AuthRepository instance.
/// The Supabase client is injected from [supabaseClientProvider].
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.read(supabaseClientProvider);
  return AuthRepository(client);
});
