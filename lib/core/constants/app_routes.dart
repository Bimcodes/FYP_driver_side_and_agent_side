// =============================================================================
// FILE: core/constants/app_routes.dart
// LAYER: Core / Constants
//
// PURPOSE:
//   Defines all named route strings used by go_router for navigation.
//   Centralising route names here means if a route changes, you only
//   update it in one place — not scattered across every Navigator.push() call.
//
// HOW TO USE:
//   Instead of: context.go('/role-select')
//   Write:       context.go(AppRoutes.roleSelect)
// =============================================================================

/// Contains all named route paths for the application.
///
/// Using constants instead of raw strings prevents typos and makes
/// refactoring routes far safer.
class AppRoutes {
  // Private constructor — this class should never be instantiated.
  // It is purely a namespace for static constants.
  AppRoutes._();

  /// The very first screen. User selects Agent or Driver here.
  static const String roleSelect = '/role-select';

  /// Login screen. Manual login for returning users.
  static const String loginWithEmail = '/login';

  /// Forgot password screen.
  static const String forgotPassword = '/forgot-password';

  /// QR Registration screen. Used by staff to auto-create accounts.
  static const String qrRegister = '/register-qr';

  // ── Authentication & Onboarding ──────────────────────────────────────────
  /// Splash screen that checks for an existing session on launch.
  static const String splash = '/';

  // ── Agent Routes ────────────────────────────────────────────────────────
  /// Agent's main screen showing their Digital Vault balance.
  static const String agentDashboard = '/agent/dashboard';

  /// Agent's Top-Up Scanner for scanning Admin Paystack QR codes.
  static const String topupScan = '/agent/topup-scan';

  /// Agent's transfer screen to send tokens to a student wallet.
  static const String agentTransfer = '/agent/transfer';

  /// Agent's transaction history ledger.
  static const String agentHistory = '/agent/history';

  // ── Driver Routes ────────────────────────────────────────────────────────
  /// Driver's live passenger manifest screen with green-flash boarding events.
  static const String driverDashboard = '/driver/dashboard';

  /// Driver's daily shift ledger showing total fares collected.
  static const String driverLedger = '/driver/ledger';
}
