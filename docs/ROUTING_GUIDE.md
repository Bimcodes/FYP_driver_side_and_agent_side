# Navigation & Auth Guard Guide — QR Fare Transit App

This document explains the routing system: how screens are navigated, how the auth guard prevents unauthenticated access, and how all of it connects to Riverpod.

---

## Overview

Navigation is handled by **GoRouter** (`go_router: ^14.8.1`). Instead of calling `Navigator.push(MaterialPageRoute(...))`, all navigation is done by:

```dart
context.go(AppRoutes.agentDashboard); // Navigate to a named route
context.pop();                         // Go back
```

The router lives in `lib/core/router/` and is a Riverpod `Provider<GoRouter>` — not a global variable. This is what makes it testable and allows it to react to auth state changes.

---

## Route Definitions

All route path strings are centralised in `lib/core/constants/app_routes.dart`:

```dart
class AppRoutes {
  static const String splash          = '/';
  static const String roleSelect      = '/role-select';
  static const String loginWithEmail  = '/login';
  static const String forgotPassword  = '/forgot-password';
  static const String qrRegister      = '/register-qr';

  // Agent routes — protected
  static const String agentDashboard  = '/agent/dashboard';
  static const String topupScan       = '/agent/topup-scan';
  static const String agentTransfer   = '/agent/transfer';
  static const String agentHistory    = '/agent/history';

  // Driver routes — protected
  static const String driverDashboard = '/driver/dashboard';
  static const String driverLedger    = '/driver/ledger';
}
```

Using constants instead of raw strings prevents typos and means a route rename is one change in one file.

---

## The Auth Guard — Why It Exists

Before Phase 2, the only protection on the dashboard routes was the `SplashView` redirect. A user who constructed a deep link to `/agent/dashboard` could bypass the login screen entirely.

The auth guard fixes this by intercepting **every** navigation attempt — including deep links — and applying access rules before the target screen is ever rendered.

---

## How the Auth Guard Works

Three components work together:

### 1. `RouterNotifier` (`lib/core/router/router_notifier.dart`)

A Riverpod `AutoDisposeAsyncNotifier` that **also** implements Flutter's `Listenable` interface. This dual nature is the key to the system:

- **As a Riverpod notifier:** it can watch `authViewModelProvider` using `ref.listen()`
- **As a `Listenable`:** GoRouter can subscribe to it via `refreshListenable`

```dart
class RouterNotifier extends AutoDisposeAsyncNotifier<void> implements Listenable {

  @override
  Future<void> build() async {
    // Watch auth state. When user logs in or out, notify GoRouter.
    ref.listen<AuthState>(authViewModelProvider, (previous, next) {
      if (previous?.user != next.user || previous?.isLoading != next.isLoading) {
        notifyListeners(); // ← This triggers GoRouter to re-evaluate routes
      }
    });
  }

  // GoRouter's refreshListenable interface
  @override void addListener(VoidCallback listener) => _listeners.add(listener);
  @override void removeListener(VoidCallback listener) => _listeners.remove(listener);
}
```

### 2. `redirect()` — The Guard Rules

`RouterNotifier.redirect()` is called by GoRouter before **every** route transition. It reads the current auth state and applies three rules:

```dart
String? redirect(BuildContext context, GoRouterState routerState) {
  final user = ref.read(authViewModelProvider).user;
  final isLoading = ref.read(authViewModelProvider).isLoading;
  final destination = routerState.matchedLocation;

  // While session restore is still in progress, don't redirect
  if (isLoading) return null;

  final bool goingToProtectedRoute =
      destination.startsWith('/agent') || destination.startsWith('/driver');

  final bool goingToAuthScreen =
      destination == AppRoutes.roleSelect ||
      destination == AppRoutes.loginWithEmail ||
      destination == AppRoutes.forgotPassword ||
      destination == AppRoutes.qrRegister;

  // Rule 1: Not logged in → trying to reach a protected route
  if (user == null && goingToProtectedRoute) return AppRoutes.roleSelect;

  // Rule 2: Already logged in → trying to reach an auth screen
  if (user != null && goingToAuthScreen) {
    return user.role == UserRole.agent
        ? AppRoutes.agentDashboard
        : AppRoutes.driverDashboard;
  }

  // Rule 3: Everything else → allow
  return null;
}
```

**Return values:**
- `null` → allow the navigation to proceed normally
- A route string → redirect to that route instead

### 3. `routerProvider` (`lib/core/router/app_router.dart`)

The GoRouter instance itself is a Riverpod `Provider<GoRouter>`. It reads the `RouterNotifier` and wires everything together:

```dart
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider.notifier);

  return GoRouter(
    initialLocation: AppRoutes.splash,

    // When RouterNotifier calls notifyListeners() (on auth change),
    // GoRouter immediately calls redirect() for the current route.
    refreshListenable: notifier,

    // The guard function — called before every navigation.
    redirect: notifier.redirect,

    routes: [ ... all GoRoute definitions ... ],
  );
});
```

---

## How `QrFareApp` Uses the Router

`QrFareApp` in `main.dart` is a `ConsumerWidget` — it reads the router from Riverpod:

```dart
class QrFareApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'QR Fare Transit',
      theme: AppTheme.dark(),
      routerConfig: router,  // ← GoRouter takes over all navigation
    );
  }
}
```

---

## The Full Event Sequence — Login

Here is what happens step by step when a user taps "Sign In":

```
1. User taps "Sign In" on LoginWithEmailView
   └── View calls: ref.read(authViewModelProvider.notifier).signIn(email, password)

2. AuthViewModel calls AuthRepository.signIn()
   └── Supabase Auth returns a session

3. AuthViewModel updates state:
   state = state.copyWith(user: UserModel(...))

4. Riverpod notifies RouterNotifier (via ref.listen)
   └── Previous state: user = null
   └── Next state: user = UserModel(role: agent)
   └── user changed → RouterNotifier.notifyListeners() fires

5. GoRouter is notified (refreshListenable triggered)
   └── GoRouter calls: routerNotifier.redirect(context, currentRouterState)

6. redirect() runs:
   └── user != null AND destination is an auth screen → Rule 2 applies
   └── Returns: AppRoutes.agentDashboard

7. GoRouter navigates to /agent/dashboard
   └── AgentDashboardView renders
```

---

## The Full Event Sequence — Logout

```
1. User taps "Sign Out"
   └── View calls: ref.read(authViewModelProvider.notifier).signOut()

2. AuthViewModel calls AuthRepository.signOut()
   └── Supabase clears the session token from secure storage

3. AuthViewModel updates state:
   state = state.copyWith(clearUser: true)

4. RouterNotifier detects the change (user changed from UserModel → null)
   └── notifyListeners() fires

5. GoRouter re-evaluates the current route (e.g. /agent/dashboard)
   └── redirect() runs: user == null AND destination is a protected route → Rule 1
   └── Returns: AppRoutes.roleSelect

6. GoRouter navigates to /role-select
   └── The entire Agent dashboard stack is cleared
```

---

## Navigation Rules Summary

| Current path | Auth state | Redirect to |
|---|---|---|
| `/agent/*` or `/driver/*` | Not logged in | `/role-select` |
| `/login`, `/role-select`, `/register-qr`, etc. | Logged in as Agent | `/agent/dashboard` |
| `/login`, `/role-select`, `/register-qr`, etc. | Logged in as Driver | `/driver/dashboard` |
| `/` (splash) | Any | *No redirect — SplashView handles this itself* |
| Any other path | Any | *No redirect — allow through* |

---

## App Startup Navigation

The `SplashView` (`/`) is the initial route for every app launch. Its job is to call `authViewModel.restoreSession()` and then redirect based on the result:

```
App launches → SplashView renders
    │
    ▼
authViewModel.restoreSession() called
    │
    ├── session found → user = UserModel(role: driver)
    │       └── SplashView calls: context.go(AppRoutes.driverDashboard)
    │
    └── no session found → user = null
            └── SplashView calls: context.go(AppRoutes.roleSelect)
```

Note: The GoRouter auth guard also covers this path. Even if `SplashView` somehow navigated to the wrong screen, the guard would catch it on the next evaluation.

---

## Adding New Protected Routes

To add a new screen that requires authentication:

1. Add the route path string to `app_routes.dart`
2. Add a `GoRoute` entry in `app_router.dart`
3. If the route is under `/agent/` or `/driver/`, the auth guard automatically protects it — no extra code needed

```dart
// Step 1 — app_routes.dart
static const String agentNewFeature = '/agent/new-feature';

// Step 2 — app_router.dart (inside the routes list)
GoRoute(
  path: AppRoutes.agentNewFeature,
  builder: (context, state) => const AgentNewFeatureView(),
),

// Step 3 — nothing extra needed. The guard checks startsWith('/agent').
```
