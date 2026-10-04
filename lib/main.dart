// =============================================================================
// FILE: main.dart
// LAYER: Application Entry Point
//
// PURPOSE:
//   This is where the entire app starts. It has three jobs:
//   1. Initialize Supabase (connect to the cloud database).
//   2. Wrap the app in ProviderScope (enables Riverpod everywhere).
//   3. Wire MaterialApp.router to the routerProvider.
//
// EXECUTION ORDER:
//   1. main() runs.
//   2. WidgetsFlutterBinding.ensureInitialized() prepares Flutter engine.
//   3. initSupabase() connects to the Supabase project.
//   4. runApp() starts the widget tree with ProviderScope at the root.
//
// WHAT CHANGED FROM THE ORIGINAL:
//   Previously, the GoRouter was a top-level global variable defined inline
//   in this file. It has been moved to `core/router/app_router.dart` as a
//   Riverpod Provider so it can access auth state for the route guard.
//
//   QrFareApp is now a ConsumerWidget (was StatelessWidget) so it can
//   read the `routerProvider` from Riverpod.
//
// WHAT IS ProviderScope?
//   ProviderScope is a Riverpod concept. It creates a container that holds
//   all Riverpod provider states. It must wrap the ENTIRE app — placing it
//   at the root ensures every Widget in the tree can access any provider.
//
// WHAT IS GoRouter?
//   GoRouter handles navigation using named routes (like URLs).
//   Instead of Navigator.push(MaterialPageRoute(...)), you call:
//     context.go('/agent/dashboard')
//   All routes are defined in core/router/app_router.dart.
//
// AUTH GUARD:
//   The router now uses RouterNotifier (core/router/router_notifier.dart)
//   as its `refreshListenable`. Whenever auth state changes (login/logout),
//   GoRouter automatically re-evaluates route access and redirects if needed.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/network/supabase_client.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

import 'core/utils/inactivity_timer.dart';

/// Application entry point.
///
/// `async` because we need to await Supabase initialization before the
/// app starts rendering — otherwise the first database call would fail.
Future<void> main() async {
  // Required before any Flutter/plugin API is used in async main().
  WidgetsFlutterBinding.ensureInitialized();

  // Connect to Supabase. This must complete before any repository is used.
  await initSupabase();

  runApp(
    // ProviderScope is the root of the Riverpod dependency injection tree.
    // All Providers defined in the app are accessible under this scope.
    const ProviderScope(child: InactivityTimerWrapper(child: QrFareApp())),
  );
}

// =============================================================================
// Root Application Widget
// =============================================================================

/// The root widget of the QR Fare Transit Operations App.
///
/// This widget:
/// - Applies the dark MaterialTheme via AppTheme.dark()
/// - Reads the GoRouter from [routerProvider] (which includes the auth guard)
/// - Does NOT contain any UI itself — it is purely configuration
///
/// WHY ConsumerWidget (not StatelessWidget)?
///   We need access to `ref` to read `routerProvider` from Riverpod.
///   ConsumerWidget is the standard way to read providers in a widget.
class QrFareApp extends ConsumerWidget {
  const QrFareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read the router from Riverpod. The router is wired to the auth guard
    // via RouterNotifier — see core/router/app_router.dart for details.
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      // App title shown in task switcher / accessibility tools.
      title: 'QR Fare Transit',

      // Debug banner is distracting during development — disable it.
      debugShowCheckedModeBanner: false,

      // Our custom dark theme (defined in core/theme/app_theme.dart).
      theme: AppTheme.dark(),

      // GoRouter configuration — all screens and the auth guard are inside.
      routerConfig: router,
    );
  }
}
