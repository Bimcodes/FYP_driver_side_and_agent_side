// =============================================================================
// FILE: views/shared/primary_button.dart
// LAYER: View (UI Layer)
//
// PURPOSE:
//   A reusable button component used throughout the app.
//   Accepts a gradient color, loading state, and callback.
//   Extracted into a shared widget to avoid repeating button styles.
//
// MVVM RULE:
//   Widgets in /shared/ are purely presentational — they receive data
//   via constructor parameters and call callbacks on interaction.
//   They never read from Riverpod providers directly.
// =============================================================================

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// A full-width gradient button with a loading state.
///
/// Used for the main action button on each screen
/// (e.g., "Sign In", "Confirm Transfer", "Scan QR").
class PrimaryButton extends StatelessWidget {
  /// Text displayed on the button.
  final String label;

  /// Called when the button is pressed (null = disabled).
  final VoidCallback? onPressed;

  /// Whether to show a loading spinner instead of the label.
  final bool isLoading;

  /// The gradient to apply to the button background.
  /// Defaults to the Agent indigo gradient.
  final LinearGradient gradient;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.gradient = AppColors.agentGradient,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: (isLoading || onPressed == null)
              ? const LinearGradient(
                  colors: [Color(0xFF374151), Color(0xFF374151)],
                )
              : gradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: (isLoading || onPressed == null)
              ? null
              : [
                  BoxShadow(
                    color: gradient.colors.first.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
        ),
      ),
    );
  }
}
