// =============================================================================
// FILE: models/user_model.dart
// LAYER: Model (Data Layer)
//
// PURPOSE:
//   A pure Dart class representing a User in the system.
//   This is the EXACT Flutter equivalent of the TypeScript interface in
//   the admin dashboard: src/models/types.ts → `interface User`
//
// MVVM RULE:
//   This file contains ONLY data. No network calls, no UI, no state.
//   It is a "dumb" data container — a blueprint for what a user looks like.
//
// ADMIN DASHBOARD MAPPING:
//   TypeScript                   →   Dart
//   ─────────────────────────────────────────────────────────────
//   type UserRole = 'Admin' |        enum UserRole { admin, agent,
//     'Agent' | 'Student' |            student, driver }
//     'Driver'
//
//   interface User {             →   class UserModel {
//     id: string;                      final String id;
//     role: UserRole;                  final UserRole role;
//     name: string;                    final String name;
//   }                                }
//
// SUPABASE CONNECTION:
//   When Supabase returns a row from the `users` table, it comes as a
//   Map<String, dynamic> like: { 'id': '...', 'role': 'Agent', 'name': '...' }
//   The fromJson() factory converts that map into a UserModel object.
// =============================================================================

/// Represents the role of a user in the transit system.
///
/// Mirrors the `user_role` enum in the Supabase `users` table
/// and the `UserRole` type in the admin dashboard's types.ts.
enum UserRole {
  /// The administrative user — manages the system from the web dashboard.
  admin,

  /// A Ticket Agent — sells tokens to students from their Digital Vault.
  agent,

  /// A Student — purchases tokens and uses them to pay fares.
  student,

  /// A Transit Driver — operates a vehicle and receives fare payments.
  driver;

  /// Converts a raw string from the database into a [UserRole] enum value.
  ///
  /// Example: UserRole.fromString('Agent') → UserRole.agent
  static UserRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'agent':
        return UserRole.agent;
      case 'student':
        return UserRole.student;
      case 'driver':
        return UserRole.driver;
      default:
        throw ArgumentError('Unknown UserRole: $value');
    }
  }

  /// Converts this enum back to the string the database expects.
  ///
  /// Example: UserRole.agent.toDbString() → 'Agent'
  String toDbString() {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.agent:
        return 'Agent';
      case UserRole.student:
        return 'Student';
      case UserRole.driver:
        return 'Driver';
    }
  }
}

/// Represents a user record from the `users` Supabase table.
///
/// [MVVM ROLE]: This is a Model — a pure data class with no logic.
/// It is used by Repositories (to parse Supabase responses) and
/// by ViewModels (to hold state and make decisions).
///
/// The View never creates or mutates this directly. It reads it through
/// the ViewModel's exposed state.
class UserModel {
  /// The unique identifier of the user (UUID from Supabase).
  final String id;

  /// The role of this user in the transit system.
  final UserRole role;

  /// The display name of the user (e.g., "Campus Gate Agent (John)").
  final String name;

  const UserModel({
    required this.id,
    required this.role,
    required this.name,
  });

  // ── JSON Serialisation ────────────────────────────────────────────────────

  /// Creates a [UserModel] from a Supabase database row.
  ///
  /// Supabase returns database rows as `Map<String, dynamic>`.
  /// This factory parses that map into a typed Dart object.
  ///
  /// Example input:
  /// ```dart
  /// {
  ///   'id': '22222222-2222-2222-2222-222222222222',
  ///   'role': 'Agent',
  ///   'name': 'Campus Gate Agent (John)',
  /// }
  /// ```
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      role: UserRole.fromString(json['role'] as String),
      name: json['name'] as String,
    );
  }

  /// Converts this model back to a Map for inserting/updating in Supabase.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role.toDbString(),
      'name': name,
    };
  }

  @override
  String toString() => 'UserModel(id: $id, role: $role, name: $name)';
}
