import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../viewmodels/auth_viewmodel.dart';

/// Wraps a view to provide auto-logout functionality after a period of inactivity.
class SessionTimeoutManager extends ConsumerStatefulWidget {
  final Widget child;
  final Duration timeoutDuration;

  const SessionTimeoutManager({
    super.key,
    required this.child,
    this.timeoutDuration = const Duration(minutes: 3),
  });

  @override
  ConsumerState<SessionTimeoutManager> createState() => _SessionTimeoutManagerState();
}

class _SessionTimeoutManagerState extends ConsumerState<SessionTimeoutManager> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer(widget.timeoutDuration, _handleTimeout);
  }

  void _handleUserInteraction([_]) {
    _startTimer();
  }

  void _handleTimeout() {
    if (mounted) {
      // Logout user and navigate to login
      ref.read(authViewModelProvider.notifier).signOut();
      context.go(AppRoutes.loginWithEmail);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session expired due to inactivity. Please log in again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _handleUserInteraction,
      onPointerMove: _handleUserInteraction,
      onPointerUp: _handleUserInteraction,
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}
