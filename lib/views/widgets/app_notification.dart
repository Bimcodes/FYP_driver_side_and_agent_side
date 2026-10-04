// =============================================================================
// FILE: views/widgets/app_notification.dart
// LAYER: View / Widgets
//
// PURPOSE:
//   Provides two types of user-facing feedback:
//
//   1. AppNotification.showError(context, message)
//      → A red rounded rectangle that SLIDES UP from the bottom of the screen.
//        The user can dismiss it by tapping or it auto-dismisses after 4 seconds.
//
//   2. AppNotification.showSuccess(context, message)
//      → A green rounded rectangle that DROPS DOWN from the top of the screen.
//        Auto-dismisses after 3 seconds.
//
// DESIGN:
//   - Matches the app's dark theme (AppColors)
//   - Rounded rectangle pill shape
//   - Icon + title + message layout
//   - Smooth slide animations
//
// USAGE:
//   // On error:
//   AppNotification.showError(context, 'Network error — please try again.');
//
//   // On success:
//   AppNotification.showSuccess(context, 'Logged in successfully!');
// =============================================================================

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AppNotification {
  AppNotification._();

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Shows a red error notification that slides up from the bottom.
  ///
  /// Use for failures: auth errors, network issues, validation problems.
  static void showError(
    BuildContext context,
    String message, {
    String title = 'Something went wrong',
    Duration duration = const Duration(seconds: 4),
  }) {
    _showBottomNotification(
      context: context,
      title: title,
      message: message,
      icon: Icons.error_rounded,
      accentColor: AppColors.error,
      backgroundColor: const Color(0xFF1C0A0F),
      duration: duration,
    );
  }

  /// Shows a green success notification that drops in from the top.
  ///
  /// Use for confirmations: login success, payment sent, etc.
  static void showSuccess(
    BuildContext context,
    String message, {
    String title = 'Success',
    Duration duration = const Duration(seconds: 3),
  }) {
    _showTopNotification(
      context: context,
      title: title,
      message: message,
      icon: Icons.check_circle_rounded,
      accentColor: AppColors.success,
      backgroundColor: const Color(0xFF041C12),
      duration: duration,
    );
  }

  /// Shows a warning notification that slides up from the bottom.
  static void showWarning(
    BuildContext context,
    String message, {
    String title = 'Warning',
    Duration duration = const Duration(seconds: 4),
  }) {
    _showBottomNotification(
      context: context,
      title: title,
      message: message,
      icon: Icons.warning_rounded,
      accentColor: AppColors.warning,
      backgroundColor: const Color(0xFF1C1200),
      duration: duration,
    );
  }

  // ── Bottom Sheet Error ─────────────────────────────────────────────────────

  static void _showBottomNotification({
    required BuildContext context,
    required String title,
    required String message,
    required IconData icon,
    required Color accentColor,
    required Color backgroundColor,
    required Duration duration,
  }) {
    // Remove any existing overlay first
    _activeEntry?.remove();
    _activeEntry = null;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _BottomNotificationOverlay(
        title: title,
        message: message,
        icon: icon,
        accentColor: accentColor,
        backgroundColor: backgroundColor,
        duration: duration,
        onDismiss: () {
          entry.remove();
          if (_activeEntry == entry) _activeEntry = null;
        },
      ),
    );

    _activeEntry = entry;
    Overlay.of(context).insert(entry);
  }

  // ── Top Banner Success ─────────────────────────────────────────────────────

  static void _showTopNotification({
    required BuildContext context,
    required String title,
    required String message,
    required IconData icon,
    required Color accentColor,
    required Color backgroundColor,
    required Duration duration,
  }) {
    _activeEntry?.remove();
    _activeEntry = null;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _TopNotificationOverlay(
        title: title,
        message: message,
        icon: icon,
        accentColor: accentColor,
        backgroundColor: backgroundColor,
        duration: duration,
        onDismiss: () {
          entry.remove();
          if (_activeEntry == entry) _activeEntry = null;
        },
      ),
    );

    _activeEntry = entry;
    Overlay.of(context).insert(entry);
  }

  static OverlayEntry? _activeEntry;
}

// =============================================================================
// _BottomNotificationOverlay — slides up from bottom
// =============================================================================

class _BottomNotificationOverlay extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color accentColor;
  final Color backgroundColor;
  final Duration duration;
  final VoidCallback onDismiss;

  const _BottomNotificationOverlay({
    required this.title,
    required this.message,
    required this.icon,
    required this.accentColor,
    required this.backgroundColor,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_BottomNotificationOverlay> createState() =>
      _BottomNotificationOverlayState();
}

class _BottomNotificationOverlayState
    extends State<_BottomNotificationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),   // starts below screen
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();

    // Auto-dismiss after duration
    Future.delayed(widget.duration, _dismiss);
  }

  void _dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom +
        16;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Material(
        type: MaterialType.transparency,
        child: DefaultTextStyle(
          style: const TextStyle(
            fontFamily: 'Roboto',
            decoration: TextDecoration.none,
          ),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: GestureDetector(
                onTap: _dismiss,
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity != null &&
                      details.primaryVelocity! > 100) {
                    _dismiss();
                  }
                },
                child: Container(
                  margin: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: widget.backgroundColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: widget.accentColor.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.accentColor.withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: _NotificationContent(
                    title: widget.title,
                    message: widget.message,
                    icon: widget.icon,
                    accentColor: widget.accentColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// _TopNotificationOverlay — drops in from top
// =============================================================================

class _TopNotificationOverlay extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color accentColor;
  final Color backgroundColor;
  final Duration duration;
  final VoidCallback onDismiss;

  const _TopNotificationOverlay({
    required this.title,
    required this.message,
    required this.icon,
    required this.accentColor,
    required this.backgroundColor,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_TopNotificationOverlay> createState() =>
      _TopNotificationOverlayState();
}

class _TopNotificationOverlayState extends State<_TopNotificationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),  // starts above screen
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();

    Future.delayed(widget.duration, _dismiss);
  }

  void _dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + 12;

    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      child: Material(
        type: MaterialType.transparency,
        child: DefaultTextStyle(
          style: const TextStyle(
            fontFamily: 'Roboto',
            decoration: TextDecoration.none,
          ),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: GestureDetector(
                onTap: _dismiss,
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity != null &&
                      details.primaryVelocity! < -100) {
                    _dismiss();
                  }
                },
                child: Container(
                  margin: EdgeInsets.fromLTRB(16, topPadding, 16, 0),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: widget.backgroundColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: widget.accentColor.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.accentColor.withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _NotificationContent(
                    title: widget.title,
                    message: widget.message,
                    icon: widget.icon,
                    accentColor: widget.accentColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// _NotificationContent — shared layout for both types
// =============================================================================

class _NotificationContent extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color accentColor;

  const _NotificationContent({
    required this.title,
    required this.message,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon circle
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: accentColor, size: 22),
        ),
        const SizedBox(width: 12),

        // Text content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                message,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        // Dismiss hint
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Icon(
            Icons.close_rounded,
            color: AppColors.textMuted,
            size: 16,
          ),
        ),
      ],
    );
  }
}
