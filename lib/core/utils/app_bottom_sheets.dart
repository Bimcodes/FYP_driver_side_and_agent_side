import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppBottomSheets {
  /// Shows the Dark Red "Incorrect PIN" error sheet.
  static Future<void> showIncorrectPin(BuildContext context, {required VoidCallback onTryAgain}) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF8E2428), // Dark red from mockup
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle indicator
                Center(
                  child: Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.priority_high, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Incorrect PIN', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('Please verify your credentials and try again.', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onTryAgain();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF8E2428),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('Try Again', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16), // space below button
              ],
            ),
          ),
        );
      },
    );
  }

  /// Shows the Light "Insufficient Funds" bottom sheet.
  static Future<void> showInsufficientFunds(
    BuildContext context, {
    required VoidCallback onTopUp,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle indicator
                Center(
                  child: Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Insufficient Funds', style: TextStyle(color: AppColors.agentTextDark, fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('Your agent wallet balance is too low.', style: TextStyle(color: AppColors.agentTextLight, fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Error message box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2), // Light red background
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFE4E6)),
                  ),
                  child: const Text(
                    'You cannot transfer because your balance is less than 100.',
                    style: TextStyle(color: Color(0xFF881337), fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onTopUp();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.agentBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('Top-Up Wallet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Dismiss', style: TextStyle(color: AppColors.agentTextDark, fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}
