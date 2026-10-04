// =============================================================================
// FILE: core/router/router_notifier.dart
// LAYER: Core / Router
//
// PURPOSE:
//   Implements the GoRouter auth guard using Riverpod.
//   This class has TWO jobs:
//     1. Acts as a ChangeNotifier so GoRouter knows WHEN to re-evaluate routes.
//     2. Provides the redirect() method that contains the RULES for re-evaluation.
//
// HOW GOROUTER AUTH GUARDS WORK:
//   GoRouter has a `refreshListenable` parameter. When the Listenable it is
//   given calls notifyListeners(), GoRouter immediately re-runs its `redirect`
//   callback for the current route.
//
//   We bridge Riverpod's auth state to GoRouter's Listenable by:
//     a. Watching authViewModelProvider inside build() using ref.listen().
//     b. Calling notifyListeners() every time auth state changes.
//
//   This means: login → auth state changes → GoRouter re-evaluates → dashboard.
//              logout → auth state changes → GoRouter re-evaluates → role select.
//
// WHY AutoDisposeAsyncNotifier?
//   The `ref.listen()` inside `build()` is what creates the bridge.
//   AutoDispose means this notifier is cleaned up when no longer in use (when
//   GoRouter is disposed), preventing memory leaks.
//
// THE REDIRECT RULES:
//   +------------------------------+---------------------+-------------------+
//   | Current path                 | Auth state          | Action            |
//   +------------------------------+---------------------+-------------------+
//   | /agent/* or /driver/*        | user == null        | → /role-select    |
//   | /role-select, /login, etc.   | user != null        | → their dashboard |
//   | anything else                | any                 | allow (null)      |
//   +------------------------------+---------------------+-------------------+
//
// HOW THE VIEW LAYER USES THIS:
//   Views and ViewModels do NOT use this class directly.
//   GoRouter reads it automatically via `refreshListenable` and `redirect`.
//   The only thing Views do is call context.go() — the guard runs invisibly.
// =============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';


import '../../models/user_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../constants/app_routes.dart';

/// A Riverpod notifier that also implements [Listenable] so GoRouter
/// can subscribe to auth state changes.
///
/// [MVVM ROLE]: This is infrastructure — part of the navigation layer.
/// It is neither a ViewModel (no UI state) nor a Repository (no DB access).
class RouterNotifier extends AutoDisposeAsyncNotifier<void> implements Listenable {
  // Internal list of GoRouter's listener callbacks.
  // GoRouter adds/removes its own listener via addListener/removeListener.
  final ObserverList<VoidCallback> _listeners = ObserverList<VoidCallback>();

  /// build() sets up the bridge between Riverpod auth state and GoRouter.
  ///
  /// ref.listen() watches [authViewModelProvider]. Every time [AuthState]
  /// changes (login, logout, session restore), we call notifyListeners()
  /// so GoRouter immediately re-evaluates the current route.
  @override
  Future<void> build() async {
    ref.listen<AuthState>(
      authViewModelProvider,
      (previous, next) {
        // Only notify GoRouter if the user or loading state actually changed.
        // This prevents unnecessary re-evaluation on unrelated state updates.
        if (previous?.user != next.user || previous?.isLoading != next.isLoading) {
          notifyListeners();
        }
      },
    );
  }

  // ── Listenable implementation ─────────────────────────────────────────────
  // These three methods fulfil the [Listenable] contract GoRouter expects.

  @override
  void addListener(VoidCallback listener) => _listeners.add(listener);

  @override
  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  /// Notifies GoRouter that auth state has changed and it should re-run redirect().
  void notifyListeners() {
    // Copy the list before iterating — a listener could remove itself during
    // the loop, which would otherwise cause a concurrent modification error.
    for (final listener in List<VoidCallback>.from(_listeners)) {
      listener();
    }
  }

  // ── Auth Guard — Route Redirect Logic ─────────────────────────────────────

  /// Called by GoRouter BEFORE every route transition.
  ///
  /// Returns:
  ///   - null       → allow the navigation to proceed normally
  ///   - a String   → redirect to that path instead
  ///
  /// [routerState.matchedLocation] is the path the user is trying to navigate to.
  String? redirect(BuildContext context, GoRouterState routerState) {
    final authState = ref.read(authViewModelProvider);
    final user = authState.user;
    final isLoading = authState.isLoading;
    final destination = routerState.matchedLocation;

    // While the session restore is still in progress (e.g., app just launched),
    // do not redirect. The SplashView is shown and it handles the redirect itself
    // once restoreSession() completes.
    if (isLoading) return null;

    // ── Define route categories ──────────────────────────────────────────────

    // Protected routes — require a valid Supabase session.
    final bool isGoingToProtectedRoute = (destination.startsWith('/agent') ||
            destination.startsWith('/driver') ||
            destination.startsWith('/passenger')) &&
        !(destination == AppRoutes.passengerSignup ||
            destination == AppRoutes.passengerOtp ||
            destination == AppRoutes.passengerOnboarding);

    // Auth screens — should not be accessible once logged in.
    final bool isGoingToAuthScreen =
        destination == AppRoutes.roleSelect ||
        destination == AppRoutes.loginWithEmail ||
        destination == AppRoutes.forgotPassword ||
        destination == AppRoutes.qrRegister ||
        destination == AppRoutes.passengerSignup ||
        destination == AppRoutes.passengerOtp ||
        destination == AppRoutes.passengerOnboarding;

    // ── Apply rules ──────────────────────────────────────────────────────────

    // Rule 1: Not logged in + trying to reach a protected route
    //         → send back to login.
    if (user == null && isGoingToProtectedRoute) {
      return AppRoutes.loginWithEmail;
    }

    // Rule 2: Already logged in + trying to reach an auth screen
    //         → send to the correct dashboard for their role.
    if (user != null && isGoingToAuthScreen) {
      if (user.role == UserRole.agent) {
        return AppRoutes.agentDashboard;
      } else if (user.role == UserRole.student) {
        return AppRoutes.passengerDashboard;
      } else {
        return AppRoutes.driverBusSelect;
      }
    }

    // Rule 3: All other navigations — allow through unchanged.
    return null;
  }
}

// ── Riverpod Provider ────────────────────────────────────────────────────────

/// Provides the [RouterNotifier] as an auto-disposing async Riverpod provider.
///
/// The [routerProvider] (in app_router.dart) reads this provider to wire
/// GoRouter's refreshListenable and redirect callback.
final routerNotifierProvider =
    AutoDisposeAsyncNotifierProvider<RouterNotifier, void>(RouterNotifier.new);
