// =============================================================================
// FILE: core/router/app_router.dart
// LAYER: Core / Router
//
// PURPOSE:
//   Declares the GoRouter instance as a Riverpod Provider.
//   This moves the router OUT of main.dart and makes it a proper injectable
//   dependency — the app widget just reads it from the provider.
//
// WHY A PROVIDER AND NOT A GLOBAL VARIABLE?
//   The original router in main.dart was a top-level `final _router = GoRouter(...)`.
//   That works for simple apps, but it cannot:
//     - Access Riverpod providers (like authViewModelProvider)
//     - Be tested in isolation
//     - Be cleaned up automatically
//
//   As a Riverpod provider, the router:
//     - Can read routerNotifierProvider for the auth guard
//     - Is created lazily (only when first used)
//
// HOW GOROUTER + RIVERPOD WORKS TOGETHER:
//   1. GoRouter's `refreshListenable` = the [RouterNotifier] instance.
//   2. RouterNotifier watches authViewModelProvider via ref.listen().
//   3. On auth change → RouterNotifier.notifyListeners() → GoRouter re-evaluates.
//   4. GoRouter calls `redirect` (RouterNotifier.redirect()) → redirect or allow.
//
// HOW QRFAREAPP USES THIS:
//   class QrFareApp extends ConsumerWidget {
//     Widget build(BuildContext context, WidgetRef ref) {
//       final router = ref.watch(routerProvider);   // ← reads this provider
//       return MaterialApp.router(routerConfig: router);
//     }
//   }
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../views/agent/agent_main_view.dart';
import '../../views/agent/agent_history_view.dart';
import '../../views/agent/retail_transfer_view.dart';
import '../../views/agent/topup_scanner_view.dart';
import '../../views/driver/bus_selection_view.dart';
import '../../views/driver/driver_dashboard_view.dart';
import '../../views/driver/driver_ledger_view.dart';
import '../../views/forgot_password_view.dart';
import '../../views/login_with_email_view.dart';
import '../../views/qr_register_view.dart';
import '../../views/role_selection_view.dart';
import '../../views/splash_view.dart';
import '../../views/passenger/student_signup_view.dart';
import '../../views/passenger/student_otp_view.dart';
import '../../views/passenger/student_onboarding_view.dart';
import '../../views/passenger/passenger_main_view.dart';
import '../../views/passenger/passenger_scanner_view.dart';
import '../../views/passenger/passenger_map_view.dart';
import '../../views/passenger/passenger_history_view.dart';
import '../constants/app_routes.dart';
import 'router_notifier.dart';

/// Provides the configured [GoRouter] instance to the entire app.
///
/// This provider wires together:
///   - All named routes (previously defined inline in main.dart)
///   - The auth guard via [RouterNotifier] (refreshListenable + redirect)
///
/// Usage in QrFareApp:
///   ```dart
///   final router = ref.watch(routerProvider);
///   return MaterialApp.router(routerConfig: router);
///   ```
final routerProvider = Provider<GoRouter>((ref) {
  // Get the RouterNotifier instance directly (not its async state value).
  // We need the object itself because:
  //   1. It must be passed to `refreshListenable` (it's a Listenable).
  //   2. Its `redirect` method must be passed to `redirect`.
  final notifier = ref.watch(routerNotifierProvider.notifier);

  return GoRouter(
    // The initial route — shown when the app first opens.
    initialLocation: AppRoutes.splash,

    // refreshListenable: GoRouter subscribes to this Listenable.
    // When RouterNotifier.notifyListeners() fires (on auth state change),
    // GoRouter immediately re-evaluates the `redirect` callback below.
    refreshListenable: notifier,

    // redirect: The auth guard. Called before every route transition.
    // Returning null = allow. Returning a path string = redirect there instead.
    redirect: notifier.redirect,

    routes: [
      // ── Splash ─────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashView(),
      ),

      // ── Role Selection ─────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.roleSelect,
        builder: (context, state) => const RoleSelectionView(),
      ),

      // ── Login & Recovery ───────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.loginWithEmail,
        builder: (context, state) => const LoginWithEmailView(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordView(),
      ),

      // ── QR Registration ────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.qrRegister,
        builder: (context, state) => const QrRegisterView(),
      ),

      // ── Agent Routes ───────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.agentDashboard,
        builder: (context, state) => const AgentMainView(),
      ),
      GoRoute(
        path: AppRoutes.topupScan,
        builder: (context, state) => const TopupScannerView(),
      ),
      GoRoute(
        path: AppRoutes.agentTransfer,
        builder: (context, state) => const RetailTransferView(),
      ),
      GoRoute(
        path: AppRoutes.agentHistory,
        builder: (context, state) => const AgentHistoryView(),
      ),

      // ── Driver Routes ──────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.driverBusSelect,
        builder: (context, state) => const BusSelectionView(),
      ),
      GoRoute(
        path: AppRoutes.driverDashboard,
        builder: (context, state) => const DriverDashboardView(),
      ),
      GoRoute(
        path: AppRoutes.driverLedger,
        builder: (context, state) => const DriverLedgerView(),
      ),

      // ── Passenger (Student) Routes ─────────────────────────────────────────
      GoRoute(
        path: AppRoutes.passengerSignup,
        builder: (context, state) => const StudentSignupView(),
      ),
      GoRoute(
        path: AppRoutes.passengerOtp,
        builder: (context, state) => const StudentOtpView(),
      ),
      GoRoute(
        path: AppRoutes.passengerOnboarding,
        builder: (context, state) => const StudentOnboardingView(),
      ),
      GoRoute(
        path: AppRoutes.passengerDashboard,
        builder: (context, state) => const PassengerMainView(),
      ),
      GoRoute(
        path: AppRoutes.passengerBoard,
        builder: (context, state) => const PassengerScannerView(),
      ),
      GoRoute(
        path: AppRoutes.passengerMap,
        builder: (context, state) => const PassengerMapView(),
      ),
      GoRoute(
        path: AppRoutes.passengerHistory,
        builder: (context, state) => const PassengerHistoryView(),
      ),
    ],

    // ── Error Handler ──────────────────────────────────────────────────────
    // Shown when GoRouter cannot match any declared route (e.g., bad deep link).
    errorBuilder: (context, state) => const _RouteNotFoundView(),
  );
});

// =============================================================================
// Internal Error View
// =============================================================================

/// A minimal 404 screen shown when GoRouter cannot match a route path.
///
/// This is internal to the router — no ViewModel or repository needed.
class _RouteNotFoundView extends StatelessWidget {
  const _RouteNotFoundView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white54, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Page not found',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => GoRouter.of(context).go(AppRoutes.splash),
              child: const Text(
                'Go Home',
                style: TextStyle(color: Colors.blueAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
