// =============================================================================
// FILE: core/theme/app_colors.dart
// LAYER: Core / Theme
//
// PURPOSE:
//   Defines all named colour tokens used throughout the application.
//   Instead of writing Color(0xFF1E293B) in a Widget file, you write
//   AppColors.surface — which is self-documenting and consistent.
//
// DESIGN SYSTEM:
//   - Background: Deep navy-slate (dark mode)
//   - Agent accent: Indigo / violet (matches admin dashboard)
//   - Driver accent: Emerald / cyan (fresh, high-visibility)
//   - Status: Emerald (success), Rose (error), Amber (warning)
// =============================================================================

import 'package:flutter/material.dart';

/// Named colour palette for the QR Fare Transit Operations App.
///
/// All colours are defined here. No raw Color() values should appear
/// anywhere else in the codebase — always import from this file.
class AppColors {
  AppColors._();

  // ── Background Layers ────────────────────────────────────────────────────
  /// The deepest background — used for the Scaffold background.
  static const Color background = Color(0xFF0A0F1E);

  /// Card / panel surface — sits on top of [background].
  static const Color surface = Color(0xFF111827);

  /// Elevated card surface — modals, bottom sheets.
  static const Color surfaceElevated = Color(0xFF1A2235);

  /// Subtle border colour for cards and dividers.
  static const Color border = Color(0xFF1F2D45);

  // ── Text ─────────────────────────────────────────────────────────────────
  /// Primary text — headings and important values.
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// Secondary text — labels and descriptions.
  static const Color textSecondary = Color(0xFF94A3B8);

  /// Muted text — placeholders and subtle hints.
  static const Color textMuted = Color(0xFF475569);

  // ── Agent Accent (Emerald / Green) ────────────────────────────────────────
  /// Primary Agent accent colour (Green). Used for buttons, active states.
  static const Color agentPrimary = Color(0xFF10B981);

  /// Lighter Agent accent. Used for icons and highlights.
  static const Color agentLight = Color(0xFF34D399);

  /// Subtle Agent background tint. Used for card backgrounds.
  static const Color agentSurface = Color(0xFFECFDF5);

  /// Agent gradient: start colour.
  static const Color agentGradientStart = Color(0xFF047857);

  /// Agent gradient: end colour.
  static const Color agentGradientEnd = Color(0xFF10B981);

  // ── Driver Accent (Emerald / Cyan) ────────────────────────────────────────
  /// Primary Driver accent colour. Used for buttons, active states.
  static const Color driverPrimary = Color(0xFF10B981);

  /// Lighter Driver accent. Used for icons and highlights.
  static const Color driverLight = Color(0xFF34D399);

  /// Subtle Driver background tint. Used for card backgrounds.
  static const Color driverSurface = Color(0xFF064E3B);

  /// Driver gradient: start colour.
  static const Color driverGradientStart = Color(0xFF10B981);

  /// Driver gradient: end colour.
  static const Color driverGradientEnd = Color(0xFF0891B2);

  // ── Passenger Accent (Sky / Cyan) ─────────────────────────────────────────
  /// Primary Passenger accent colour. Used for wallet, buttons, highlights.
  static const Color passengerPrimary = Color(0xFF0EA5E9);

  /// Lighter Passenger accent.
  static const Color passengerLight = Color(0xFF38BDF8);

  /// Subtle Passenger background tint.
  static const Color passengerSurface = Color(0xFF082F49);

  /// Passenger gradient: start colour.
  static const Color passengerGradientStart = Color(0xFF0EA5E9);

  /// Passenger gradient: end colour.
  static const Color passengerGradientEnd = Color(0xFF06B6D4);

  // ── Flash Colour (Driver Boarding & Passenger Topup Event) ────────────────
  /// Full-screen flash colour when a passenger boards or tops up.
  /// Deliberately vivid for instant visibility.
  static const Color boardingFlash = Color(0xFF00FF88);

  // ── Status Colours ────────────────────────────────────────────────────────
  /// Success state — transaction confirmed, transfer complete.
  static const Color success = Color(0xFF10B981);

  /// Error state — insufficient balance, auth failure.
  static const Color error = Color(0xFFF43F5E);

  /// Warning state — low balance, GPS inactive.
  static const Color warning = Color(0xFFF59E0B);

  // ── NEW: Auth Redesign Colors (Dark) ──────────────────────────────────────
  static const Color authBackground = Color(0xFF0F141E); // Very dark navy
  static const Color authSurface = Color(0xFF161A25);    // Inputs, cards
  static const Color authPrimary = Color(0xFF18C07A);    // Vibrant green

  // ── NEW: Agent Dashboard Redesign Colors (Light) ──────────────────────────
  static const Color agentLightBackground = Color(0xFFF8FAFC);
  static const Color agentCardWhite = Color(0xFFFFFFFF);
  static const Color agentBlue = Color(0xFF10B981);      // Main green accent
  static const Color agentBlueBorder = Color(0xFFA7F3D0); // Token wallet emerald border
  static const Color agentTextDark = Color(0xFF1E293B);
  static const Color agentTextLight = Color(0xFF64748B);
  static const Color agentGreenArrow = Color(0xFFD1FADF); // Light green bg for arrow
  static const Color agentGreenText = Color(0xFF039855);  // Income text
  static const Color agentRedArrow = Color(0xFFFEE4E2);   // Light red bg for arrow
  static const Color agentRedText = Color(0xFFD92D20);    // Expense text

  // ── Gradient Shorthand ────────────────────────────────────────────────────
  /// Returns the Agent mode linear gradient.
  static const LinearGradient agentGradient = LinearGradient(
    colors: [agentGradientStart, agentGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Returns the Driver mode linear gradient.
  static const LinearGradient driverGradient = LinearGradient(
    colors: [driverGradientStart, driverGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Returns the Passenger mode linear gradient.
  static const LinearGradient passengerGradient = LinearGradient(
    colors: [passengerGradientStart, passengerGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
