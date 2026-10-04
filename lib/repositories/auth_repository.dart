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
        .select('id, name, first_name, last_name, username, phone, department, role')
        .eq('id', authUser.id)
        .single();

    final userModel = UserModel.fromJson(userData);
    logger.d('[AuthRepository] User profile found — name: ${userModel.name} | role: ${userModel.role.toDbString()}');

    logger.i('[AuthRepository] ✅ Sign-in successful for ${userModel.name} (${userModel.role.toDbString()})');
    return userModel;
  }

  // ── Sign Up & OTP (Student) ───────────────────────────────────────────────

  /// Signs up a new student (passenger) using email and password.
  /// 
  /// The [firstName] is stored in `raw_user_meta_data`.
  Future<void> signUpStudent({
    required String email,
    required String password,
    required String firstName,
  }) async {
    logger.i('[AuthRepository] signUpStudent() → email: $email');
    await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'first_name': firstName,
        'role': UserRole.student.toDbString(),
      },
    );
    logger.i('[AuthRepository] ✅ signUpStudent request sent (OTP expected)');
  }

  /// Verifies the OTP sent to the user's email during sign up.
  /// 
  /// Returns the authenticated user's ID upon success.
  Future<String> verifyOtp({
    required String email,
    required String otp,
  }) async {
    logger.i('[AuthRepository] verifyOtp() → email: $email');
    final response = await _client.auth.verifyOTP(
      type: OtpType.signup,
      token: otp,
      email: email,
    );
    
    final authUser = response.user;
    if (authUser == null) {
      throw Exception('OTP Verification failed: No user returned.');
    }
    logger.i('[AuthRepository] ✅ OTP verified for ${authUser.id}');
    return authUser.id;
  }

  /// Updates or inserts the user's profile in the `users` table.
  /// 
  /// Called during the onboarding step or right after OTP verification if no 
  /// database trigger automatically syncs `auth.users` to `public.users`.
  Future<UserModel> createStudentProfile({
    required String userId,
    required String firstName,
    String? lastName,
    String? phone,
    String? department,
    String? username,
  }) async {
    logger.i('[AuthRepository] createStudentProfile() → userId: $userId');
    
    final insertData = {
      'id': userId,
      'role': UserRole.student.toDbString(),
      'name': '$firstName ${lastName ?? ''}'.trim(),
      'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (phone != null) 'phone': phone,
      if (department != null) 'department': department,
      if (username != null) 'username': username,
    };

    final userData = await _client
        .from('users')
        .insert(insertData)
        .select('id, name, first_name, last_name, username, phone, department, role')
        .single();
        
    final userModel = UserModel.fromJson(userData);
    logger.i('[AuthRepository] ✅ Profile created for ${userModel.name}');

    // Create a wallet for the new student
    try {
      await _client.from('wallets').insert({
        'owner_id': userId,
        'wallet_type': 'Student_Wallet',
        'balance': 0.0,
      });
      logger.i('[AuthRepository] ✅ Wallet created for ${userModel.name}');
    } catch (e) {
      logger.w('[AuthRepository] ⚠️ Could not create wallet (might already exist): $e');
    }

    return userModel;
  }

  Future<UserModel> updateUserProfile({
    required String userId,
    required String firstName,
    String? lastName,
    String? phone,
    String? department,
    String? username,
  }) async {
    logger.i('[AuthRepository] updateUserProfile() → userId: $userId');
    
    final updateData = {
      'first_name': firstName,
      'last_name': lastName,
      'username': username,
      'phone': phone,
      'department': department,
      'name': '$firstName ${lastName ?? ''}'.trim(),
    };

    final userData = await _client
        .from('users')
        .update(updateData)
        .eq('id', userId)
        .select('id, name, first_name, last_name, username, phone, department, role')
        .single();
        
    final userModel = UserModel.fromJson(userData);
    logger.i('[AuthRepository] ✅ Profile updated for ${userModel.name}');

    return userModel;
  }

  Future<void> setTransactionPin(String pin) async {
    logger.i('[AuthRepository] setTransactionPin()');
    await _client.rpc('set_transaction_pin', params: {'p_pin': pin});
    logger.i('[AuthRepository] ✅ Transaction PIN updated');
  }

  Future<bool> hasTransactionPin() async {
    return await _client.rpc('has_transaction_pin') as bool;
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
          .select('id, name, first_name, last_name, username, phone, department, role')
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
