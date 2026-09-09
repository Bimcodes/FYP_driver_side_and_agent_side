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

  // ── Agent Accent (Indigo / Violet) ────────────────────────────────────────
  /// Primary Agent accent colour. Used for buttons, active states.
  static const Color agentPrimary = Color(0xFF6366F1);

  /// Lighter Agent accent. Used for icons and highlights.
  static const Color agentLight = Color(0xFF818CF8);

  /// Subtle Agent background tint. Used for card backgrounds.
  static const Color agentSurface = Color(0xFF1E1B4B);

  /// Agent gradient: start colour.
  static const Color agentGradientStart = Color(0xFF6366F1);

  /// Agent gradient: end colour.
  static const Color agentGradientEnd = Color(0xFF7C3AED);

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

  // ── Flash Colour (Driver Boarding Event) ──────────────────────────────────
  /// Full-screen flash colour when a passenger boards.
  /// Deliberately vivid for instant visibility.
  static const Color boardingFlash = Color(0xFF00FF88);

  // ── Status Colours ────────────────────────────────────────────────────────
  /// Success state — transaction confirmed, transfer complete.
  static const Color success = Color(0xFF10B981);

  /// Error state — insufficient balance, auth failure.
  static const Color error = Color(0xFFF43F5E);

  /// Warning state — low balance, GPS inactive.
  static const Color warning = Color(0xFFF59E0B);

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
}
