// =============================================================================
// FILE: views/shared/stat_card.dart
// LAYER: View (UI Layer)
//
// PURPOSE:
//   A reusable glassmorphic stat card — displays a label, large value,
//   and an icon. Used on both Agent (balance) and Driver (passenger count,
//   tokens collected) dashboards.
// =============================================================================

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// A frosted-glass stat card for displaying a key metric.
///
/// Example usage (Agent balance card):
/// ```dart
/// StatCard(
///   label: 'Your Token Balance',
///   value: '₦50,000',
///   icon: Icons.account_balance_wallet,
///   accentColor: AppColors.agentPrimary,
/// )
/// ```
class StatCard extends StatelessWidget {
  /// Short description above the value (e.g., "Passengers Today").
  final String label;

  /// The main display value (e.g., "₦50,000" or "42").
  final String value;

  /// Icon shown in the top-right corner of the card.
  final IconData icon;

  /// The accent colour for the icon and border glow.
  final Color accentColor;

  /// Optional subtitle below the value.
  final String? subtitle;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: label + icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Main value
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
