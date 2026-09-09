// =============================================================================
// FILE: core/utils/app_logger.dart
// LAYER: Core Utility
//
// PURPOSE:
//   A single, shared Logger instance for the entire app.
//   Import this file anywhere you need to log something.
//
// HOW TO USE:
//   import '../core/utils/app_logger.dart';
//
//   logger.d('Debug: some detail');   // Blue  — verbose dev info
//   logger.i('Info: action taken');   // Green — normal operations
//   logger.w('Warning: something unexpected but handled');  // Yellow
//   logger.e('Error: something failed', error: e, stackTrace: st);  // Red
//
// LOG LEVELS (when to use each):
//   .d() DEBUG   → Low-level details. Raw data values, function entry/exit.
//                  Example: "Fetching wallet for ownerId: abc-123"
//
//   .i() INFO    → Successful operations. Confirms things worked.
//                  Example: "Wallet loaded: balance=₦50000"
//
//   .w() WARNING → Something unexpected happened but the app recovered.
//                  Example: "No boarding events yet — stream is empty"
//
//   .e() ERROR   → A caught exception. Always pass `error:` and `stackTrace:`
//                  so the full stack trace appears in the terminal.
//                  Example: logger.e('Login failed', error: e, stackTrace: st)
//
// WHY A SINGLETON?
//   If every class created its own Logger(), the terminal would be flooded
//   with repeated headers. One shared instance keeps output clean.
//   All classes use the same `logger` variable from this file.
//
// PRODUCTION NOTE:
//   In release mode, logger automatically suppresses debug/info messages.
//   Only warnings and errors are shown. To disable all logging in release:
//     Logger.level = Level.nothing;
// =============================================================================

import 'package:logger/logger.dart';

/// The global logger instance. Import this file to use it anywhere.
///
/// Usage:
/// ```dart
/// import '../../core/utils/app_logger.dart';
/// logger.i('Dashboard loaded successfully');
/// logger.e('Transfer failed', error: e, stackTrace: st);
/// ```
final logger = Logger(
  // PrettyPrinter adds colour, emoji icons, and proper formatting.
  // This makes logs far easier to read than plain print() statements.
  printer: PrettyPrinter(
    // Number of stack trace lines to show on errors (0 = none, 5 = readable).
    methodCount: 0,
    // Number of stack trace lines to show in ERROR logs.
    errorMethodCount: 8,
    // Maximum line width before wrapping.
    lineLength: 120,
    // Show colours in the terminal (works in VS Code / Android Studio).
    colors: true,
    // Show emoji icons (✅ ⚠️ ❌) next to log level.
    printEmojis: true,
    // Show the timestamp next to each log line.
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
);
