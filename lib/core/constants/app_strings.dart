// =============================================================================
// FILE: core/constants/app_strings.dart
// LAYER: Core / Constants
//
// PURPOSE:
//   Centralises all user-facing text strings used in the app.
//   This prevents "magic strings" scattered across Widget files.
//   If the app ever needs translation (i18n), all strings are in one place.
// =============================================================================

/// Holds all user-facing text displayed in the UI.
class AppStrings {
  AppStrings._();

  // ── App ─────────────────────────────────────────────────────────────────
  static const String appName = 'QR Fare Transit';

  // ── Role Selection Screen ────────────────────────────────────────────────
  static const String roleSelectTitle = 'Who are you?';
  static const String roleSelectSubtitle = 'Select your role to continue to your workspace.';
  static const String roleAgent = 'Ticket Agent';
  static const String roleDriver = 'Transit Driver';
  static const String roleAgentDesc = 'Manage your Digital Vault and transfer tokens to students.';
  static const String roleDriverDesc = 'Monitor your live passenger manifest and broadcast your location.';

  // ── Login Screen ─────────────────────────────────────────────────────────
  static const String loginTitle = 'Sign In';
  static const String loginEmailLabel = 'Email Address';
  static const String loginEmailHint = 'your@email.com';
  static const String loginPasswordLabel = 'Password';
  static const String loginPasswordHint = '••••••••';
  static const String loginButton = 'Sign In';
  static const String loginLoading = 'Signing in...';
  static const String loginRoleMismatch =
      'This account is not registered as the selected role. Please go back and choose the correct role.';

  // ── Agent Screens ─────────────────────────────────────────────────────────
  static const String agentDashboardTitle = 'Digital Vault';
  static const String agentBalanceLabel = 'Your Token Balance';
  static const String agentTransferButton = 'Transfer to Student';
  static const String agentHistoryTitle = 'Transaction History';
  static const String agentTransferTitle = 'Retail Transfer';
  static const String agentWalletIdLabel = 'Student Wallet ID';
  static const String agentAmountLabel = 'Token Amount';
  static const String agentScanButton = 'Scan QR Code';
  static const String agentConfirmButton = 'Confirm Transfer';
  static const String agentTransferring = 'Transferring...';
  static const String agentTransferSuccess = 'Transfer completed successfully!';
  static const String agentInsufficientBalance = 'Insufficient balance in your vault.';

  // ── Driver Screens ────────────────────────────────────────────────────────
  static const String driverDashboardTitle = 'Live Manifest';
  static const String driverPassengerCount = 'Passengers Today';
  static const String driverTokensCollected = 'Tokens Collected';
  static const String driverLedgerTitle = 'Shift Ledger';
  static const String driverGpsActive = 'GPS Broadcasting Active';
  static const String driverGpsInactive = 'GPS Inactive';
  static const String driverBoardingSuccess = 'Passenger Boarded!';
  static const String driverExpectedPayout = 'Expected Midnight Payout';

  // ── General ──────────────────────────────────────────────────────────────
  static const String logout = 'Sign Out';
  static const String retry = 'Retry';
  static const String back = 'Back';
  static const String loading = 'Loading...';
  static const String unknownError = 'Something went wrong. Please try again.';
}
