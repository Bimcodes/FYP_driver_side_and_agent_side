// =============================================================================
// FILE: core/theme/app_theme.dart
// LAYER: Core / Theme
//
// PURPOSE:
//   Builds the MaterialTheme object that Flutter uses to style every widget
//   in the app. By defining this here once, every Text, Button, Card, etc.
//   automatically picks up the correct font, colour, and shape.
//
// HOW IT CONNECTS:
//   main.dart passes AppTheme.dark() to MaterialApp's theme parameter.
//   Individual widgets use Theme.of(context) to read values from here.
// =============================================================================

import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Provides the MaterialTheme configuration for the app.
///
/// Call [AppTheme.dark] to get the pre-configured dark ThemeData.
class AppTheme {
  AppTheme._();

  /// The primary dark theme used throughout the app.
  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,

      // ── Colour Scheme ────────────────────────────────────────────────────
      // ColorScheme.fromSeed generates a full M3 colour palette from one seed.
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.agentPrimary,
        brightness: Brightness.dark,
        surface: AppColors.surface,
      ).copyWith(
        // Override specific slots to match our custom palette exactly.
        primary: AppColors.agentPrimary,
        onPrimary: AppColors.textPrimary,
        error: AppColors.error,
      ),

      // ── Scaffold ─────────────────────────────────────────────────────────
      scaffoldBackgroundColor: AppColors.background,

      // ── Typography ───────────────────────────────────────────────────────
      // Using the default M3 typography but overriding colours.
      textTheme: const TextTheme(
        // Large display numbers (e.g., wallet balance)
        displayLarge: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.5,
        ),
        // Section headings
        headlineMedium: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        // Card titles
        titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        // Body text
        bodyLarge: TextStyle(color: AppColors.textSecondary),
        bodyMedium: TextStyle(color: AppColors.textSecondary),
        // Labels and captions
        labelMedium: TextStyle(color: AppColors.textMuted),
      ),

      // ── AppBar ───────────────────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: AppColors.textSecondary),
      ),

      // ── Cards ────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),

      // ── Input Fields ─────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceElevated,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.agentPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // ── Elevated Buttons ──────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.agentPrimary,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Divider ──────────────────────────────────────────────────────────
      dividerColor: AppColors.border,
    );
  }
}
