import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/auth_viewmodel.dart';

class InactivityTimerWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const InactivityTimerWrapper({super.key, required this.child});

  @override
  ConsumerState<InactivityTimerWrapper> createState() => _InactivityTimerWrapperState();
}

class _InactivityTimerWrapperState extends ConsumerState<InactivityTimerWrapper> {
  Timer? _timer;
  final int _timeoutMinutes = 5;

  @override
  void initState() {
    super.initState();
    _resetTimer();
  }

  void _resetTimer([_]) {
    _timer?.cancel();
    
    // Only run the timer if the user is logged in
    final user = ref.read(authViewModelProvider).user;
    if (user != null) {
      _timer = Timer(Duration(minutes: _timeoutMinutes), _handleTimeout);
    }
  }

  void _handleTimeout() {
    final user = ref.read(authViewModelProvider).user;
    if (user != null) {
      ref.read(authViewModelProvider.notifier).signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth changes. If user logs in, we need to start the timer.
    // If they log out, the timer gets cancelled.
    ref.listen(authViewModelProvider, (previous, next) {
      if (next.user != previous?.user) {
        _resetTimer();
      }
    });

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _resetTimer,
      onPointerMove: _resetTimer,
      onPointerUp: _resetTimer,
      child: widget.child,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
