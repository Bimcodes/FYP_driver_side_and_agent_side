// =============================================================================
// FILE: core/utils/app_error_handler.dart
// LAYER: Core / Utils
//
// PURPOSE:
//   Translates raw Supabase exceptions, network errors, and other technical
//   errors into short, friendly messages a regular user can understand.
//
//   Instead of showing:
//     "AuthRetryableFetchException(message: ClientException with SocketException...)"
//   We show:
//     "Network error — please check your connection and try again."
//
// USAGE:
//   final message = AppErrorHandler.toUserMessage(e);
// =============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';

class AppErrorHandler {
  AppErrorHandler._();

  /// Converts any caught exception into a short, readable user-facing message.
  ///
  /// Priority order:
  ///   1. Supabase [AuthException] — specific auth error codes
  ///   2. Network / socket errors  — no connectivity
  ///   3. Generic fallback
  static String toUserMessage(Object error) {
    final raw = error.toString().toLowerCase();

    // ── Supabase AuthException ──────────────────────────────────────────────
    if (error is AuthException) {
      return _mapAuthException(error);
    }

    // ── Network / Socket errors ─────────────────────────────────────────────
    if (_isNetworkError(raw)) {
      return 'Network error — please check your connection and try again.';
    }

    // ── Supabase Retryable Fetch (wraps network errors) ─────────────────────
    if (raw.contains('authretryablefetchexception') ||
        raw.contains('retryable')) {
      return 'Network error — please check your connection and try again.';
    }

    // ── PostgrestException (database errors) ────────────────────────────────
    if (raw.contains('postgrestexception') || raw.contains('pgrst')) {
      return 'Something went wrong on our end. Please try again.';
    }

    // ── Timeout ─────────────────────────────────────────────────────────────
    if (raw.contains('timeout') || raw.contains('timed out')) {
      return 'The request timed out. Please try again.';
    }

    // ── Generic Exception wrapper ────────────────────────────────────────────
    String message = error.toString();
    if (message.startsWith('Exception: ')) {
      message = message.replaceFirst('Exception: ', '');
    }

    // If it's still a very long technical string, use a safe fallback.
    if (message.length > 120 || message.contains(' at ')) {
      return 'An unexpected error occurred. Please try again.';
    }

    return message;
  }

  // ── Private Helpers ────────────────────────────────────────────────────────

  static bool _isNetworkError(String raw) {
    return raw.contains('socketexception') ||
        raw.contains('failed host lookup') ||
        raw.contains('no address associated') ||
        raw.contains('network is unreachable') ||
        raw.contains('connection refused') ||
        raw.contains('connection reset') ||
        raw.contains('clientexception') ||
        raw.contains('errno=7') ||
        raw.contains('no route to host') ||
        raw.contains('handshake error');
  }

  static String _mapAuthException(AuthException e) {
    final msg = e.message.toLowerCase();
    final code = e.code?.toLowerCase() ?? '';

    // Wrong credentials
    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid credentials') ||
        code == 'invalid_credentials') {
      return 'Incorrect email or password. Please try again.';
    }

    // Email not confirmed
    if (msg.contains('email not confirmed') || code == 'email_not_confirmed') {
      return 'Please confirm your email before logging in.';
    }

    // User not found
    if (msg.contains('user not found') || code == 'user_not_found') {
      return 'No account found with that email address.';
    }

    // Too many requests / rate limit
    if (msg.contains('too many requests') ||
        msg.contains('rate limit') ||
        code == 'over_request_rate_limit' ||
        code == 'over_email_send_rate_limit') {
      return 'Too many attempts. Please wait a moment and try again.';
    }

    // Account disabled / banned
    if (msg.contains('user is banned') ||
        msg.contains('not authorized') ||
        code == 'user_banned') {
      return 'Your account has been disabled. Please contact support.';
    }

    // Email already taken
    if (msg.contains('already registered') ||
        msg.contains('email already') ||
        code == 'email_exists') {
      return 'An account with this email already exists.';
    }

    // OTP / Token errors
    if (msg.contains('otp') ||
        (msg.contains('token') && msg.contains('invalid'))) {
      return 'The verification code is invalid or has expired.';
    }

    // Session expired
    if ((msg.contains('session') && msg.contains('expired')) ||
        code == 'session_not_found') {
      return 'Your session has expired. Please log in again.';
    }

    // Network issues wrapping AuthException
    if (_isNetworkError(msg)) {
      return 'Network error — please check your connection and try again.';
    }

    // Fallback — use Supabase's own message
    return e.message.isNotEmpty
        ? e.message
        : 'Authentication failed. Please try again.';
  }
}
