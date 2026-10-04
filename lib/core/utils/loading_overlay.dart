import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class LoadingOverlay {
  /// Shows a modal loading spinner that blocks user interaction.
  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => const PopScope(
        canPop: false, // Prevent back button from dismissing the loading spinner
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.agentPrimary,
          ),
        ),
      ),
    );
  }

  /// Hides the loading spinner.
  static void hide(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}
