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
  static const String roleStudent = 'Student / Passenger';
  static const String roleAgent = 'Ticket Agent';
  static const String roleDriver = 'Transit Driver';
  static const String roleStudentDesc = 'Check balance, receive tokens, board buses, and view transit maps.';
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

  // ── Passenger Screens ────────────────────────────────────────────────────
  static const String passengerDashboardTitle = 'Digital Transit Wallet';
  static const String passengerBalanceLabel = 'Available Token Balance';
  static const String passengerBoardButton = 'Board Bus';
  static const String passengerReceiveButton = 'Receive Tokens';
  static const String passengerMapButton = 'Campus Transit Map';
  static const String passengerHistoryTitle = 'Ride & Top-Up History';
  static const String passengerReceiveModalTitle = 'My Receiving QR Code';
  static const String passengerReceiveModalSubtitle =
      'Present this QR code to an authorized campus Agent to vend tokens directly into your digital wallet.';
  static const String passengerCopyWalletId = 'Copy Wallet ID';
  static const String passengerCopiedMessage = 'Wallet ID copied to clipboard!';
  static const String passengerTopupReceived = 'Tokens Received!';
  static const String passengerScanBusTitle = 'Scan Bus QR Code';
  static const String passengerScanBusHint = 'Align the camera with the vehicle QR code mounted inside the bus';
  static const String checkoutTitle = 'Boarding Checkout';
  static const String checkoutDestinationLabel = 'Destination Stop';
  static const String checkoutPassengersLabel = 'Number of Passengers';
  static const String checkoutTotalFareLabel = 'Total Fare (Tokens)';
  static const String checkoutConfirmWarning =
      'This transaction is final and cannot be reversed. Tokens will be immediately deducted from your wallet.';
  static const String checkoutPayAndBoard = 'Confirm & Pay Fare';
  static const String checkoutInsufficientBalance =
      'Insufficient balance. Please visit an authorized Agent to top up your wallet.';
  static const String checkoutBoardingSuccess = 'Boarding Approved!';

  // ── General ──────────────────────────────────────────────────────────────
  static const String logout = 'Sign Out';
  static const String retry = 'Retry';
  static const String back = 'Back';
  static const String loading = 'Loading...';
  static const String unknownError = 'Something went wrong. Please try again.';
}
