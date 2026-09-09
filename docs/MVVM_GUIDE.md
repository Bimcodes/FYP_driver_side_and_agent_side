# MVVM Architecture Guide — QR Fare Transit Operations App

This document explains the MVVM (Model-View-ViewModel) architecture used in this Flutter project, with real examples from every layer including the navigation system added in Phase 2.

---

## Why Architecture Matters

Without a structure, a Flutter app becomes one giant file mixing database calls, business rules, animations, and UI layout together. That file becomes impossible to test, debug, or hand over to another developer.

MVVM solves this by dividing all code into **four layers** with strict rules about what each layer is allowed to do. Breaking these rules is the most common source of bugs in this codebase.

---

## The Four Layers

### Layer 1 — Model (`lib/models/`)

**What it is:** Pure data containers. A Model only holds data and knows how to serialise/deserialise itself from JSON (Supabase database rows).

**Rules:**
- ✅ Define data fields with types
- ✅ Implement `fromJson()` to parse Supabase rows
- ✅ Implement `toJson()` / `toInsertJson()` for writing to Supabase
- ❌ No network calls
- ❌ No Flutter widgets
- ❌ No Riverpod state

**Files in this layer:**

| File | What it models |
|---|---|
| `user_model.dart` | A user row from the `users` table. Contains `UserRole` enum with `fromString()` / `toDbString()` for DB mapping. |
| `wallet_model.dart` | A wallet row from the `wallets` table. Contains `WalletType` enum and `copyWithBalance()` helper. |
| `transaction_model.dart` | A row from the `transactions` table. Contains `TransactionType` and `TransactionStatus` enums. |
| `telemetry_model.dart` | A GPS broadcast row from the `telemetry` table. `toInsertJson()` intentionally omits `id` and `timestamp` since Supabase auto-generates them. |

**Example — the JSON round-trip pattern used in every model:**
```dart
// lib/models/wallet_model.dart

factory WalletModel.fromJson(Map<String, dynamic> json) {
  return WalletModel(
    id: json['id'] as String,
    ownerId: json['owner_id'] as String,       // snake_case from DB → camelCase in Dart
    walletType: WalletType.fromString(json['wallet_type'] as String),
    balance: (json['balance'] as num).toDouble(),
  );
}
```

---

### Layer 2 — Repository (`lib/repositories/`)

**What it is:** The **only** layer that communicates with Supabase. Repositories make queries, get raw JSON back, and convert it into typed Model objects before returning.

**Rules:**
- ✅ Make Supabase queries (`.from().select().eq()...`)
- ✅ Convert raw `Map<String, dynamic>` JSON into Model objects
- ✅ Throw exceptions on database errors (let the ViewModel handle them)
- ❌ No business logic — do not decide whether an operation *should* happen
- ❌ No Flutter widgets
- ❌ No Riverpod state

**Files in this layer:**

| File | Responsibility |
|---|---|
| `auth_repository.dart` | `signIn()`, `signOut()`, `getCurrentUser()` — wraps `supabase.auth.*` |
| `wallet_repository.dart` | `getWalletByOwnerId()`, `getWalletById()`, `updateBalance()` — queries the `wallets` table |
| `transaction_repository.dart` | `createTransaction()`, fetch by sender/receiver, `watchBoardingEvents()` (Realtime stream) |
| `telemetry_repository.dart` | `broadcastLocation()` — single INSERT into the `telemetry` table |

**Each repository is also a Riverpod Provider:**
```dart
// lib/repositories/wallet_repository.dart

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  final client = ref.read(supabaseClientProvider);
  return WalletRepository(client);
});
```

This is what makes repositories injectable and testable — ViewModels get a repository via `ref.read(walletRepositoryProvider)`, and tests override the provider with a fake class.

---

### Layer 3 — ViewModel (`lib/viewmodels/`)

**What it is:** The brain of each feature. ViewModels hold UI state, contain business rules, and coordinate between multiple repositories.

**Implemented using Riverpod's `Notifier<StateClass>` pattern:**
- `state` is the current data snapshot — views watch it and rebuild when it changes
- Methods on the notifier are the "actions" views call when the user taps buttons

**Rules:**
- ✅ Hold state (`isLoading`, `errorMessage`, data lists, etc.)
- ✅ Contain business rules (e.g. "amount must be > 0 and ≤ current balance")
- ✅ Call Repositories to read or write data
- ✅ Update `state` after operations complete
- ❌ No direct Supabase calls — always go through a Repository
- ❌ No Flutter widgets (`Text`, `Container`, etc.)

**Files in this layer:**

| File | What it manages |
|---|---|
| `auth_viewmodel.dart` | `AuthState` — `signIn()`, `signOut()`, `restoreSession()`. The login/logout cycle. |
| `agent_dashboard_viewmodel.dart` | `AgentDashboardState` — wallet balance, transfer form, transaction history, `transferToStudent()` |
| `driver_dashboard_viewmodel.dart` | `DriverDashboardState` — Realtime boarding stream, GPS loop, green flash, shift totals, cleanup |

**The `copyWith` immutability pattern** — state is never mutated directly:
```dart
// Correct: return a new state object
state = state.copyWith(isLoading: false, wallet: updatedWallet);

// Wrong: never do this
state.isLoading = false; // compile error — fields are final
```

---

### Layer 4 — View (`lib/views/`)

**What it is:** Flutter Widgets that render the UI. Views are intentionally "dumb" — they read state and call actions. They contain no logic of their own.

**Rules:**
- ✅ Render UI (Text, Buttons, Cards, Animations)
- ✅ Read state from a ViewModel via `ref.watch()`
- ✅ Call ViewModel actions in event handlers via `ref.read().notifier`
- ❌ No direct Supabase calls
- ❌ No business logic
- ❌ No data processing

**Views are `ConsumerWidget` or `ConsumerStatefulWidget`** — the Riverpod-aware equivalents of `StatelessWidget` and `StatefulWidget`:
```dart
// lib/views/agent/agent_dashboard_view.dart

class AgentDashboardView extends ConsumerStatefulWidget { ... }

class _AgentDashboardViewState extends ConsumerState<AgentDashboardView> {
  @override
  Widget build(BuildContext context) {
    // ref.watch() — subscribes to state. Widget rebuilds on every state change.
    final dashState = ref.watch(agentDashboardViewModelProvider);

    return Text('Balance: ₦${dashState.wallet?.balance ?? 0}');
  }

  void _onTransferPressed() {
    // ref.read() — one-time call. Does not subscribe. Used in callbacks.
    ref.read(agentDashboardViewModelProvider.notifier).transferToStudent(
      agentWalletId: ...,
      studentWalletId: ...,
      amount: ...,
    );
  }
}
```

---

## Layer 5 — Navigation (Phase 2: `lib/core/router/`)

The routing system is a separate cross-cutting concern that lives in `core/`, not in any MVVM layer. It was added in Phase 2 to add a **proper auth guard**.

### The Problem It Solves

Before this was added, the only protection on the dashboard routes was the `SplashView` redirect on app launch. A user who deep-linked directly to `/agent/dashboard` could bypass the login screen entirely.

### How It Works

Two files work together:

**`router_notifier.dart` — The Bridge**

`RouterNotifier` is a Riverpod `AutoDisposeAsyncNotifier` that also implements Flutter's `Listenable` interface. This makes it the bridge between Riverpod (which manages auth state) and GoRouter (which manages navigation).

```dart
// When auth state changes → GoRouter re-evaluates routes
ref.listen<AuthState>(authViewModelProvider, (previous, next) {
  if (previous?.user != next.user) {
    notifyListeners(); // Triggers GoRouter redirect() evaluation
  }
});
```

The `redirect()` method contains the actual rules:
- Unauthenticated user → `/agent/*` or `/driver/*` → redirected to `/role-select`
- Authenticated user → `/login` or `/role-select` → redirected to their dashboard
- All other paths → allowed through

**`app_router.dart` — The Router**

`routerProvider` is a Riverpod `Provider<GoRouter>` — the router is now injectable, not a global variable. `QrFareApp` in `main.dart` reads it via `ref.watch(routerProvider)`.

```dart
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider.notifier);
  return GoRouter(
    refreshListenable: notifier,  // GoRouter subscribes to auth changes
    redirect: notifier.redirect,  // Guard rules run here before each navigation
    routes: [ ... ],
  );
});
```

---

## The Complete Data Flow — One Full Example

Agent transfers tokens to a student wallet:

```
1. USER taps "Confirm Transfer"
   └── RetailTransferView (View)

2. View calls: ref.read(agentDashboardViewModelProvider.notifier)
               .transferToStudent(agentWalletId, studentWalletId, amount)
   └── AgentDashboardViewModel (ViewModel)

3. ViewModel runs business rule: if (amount > currentBalance) throw Exception(...)
   └── Business logic lives here — not in the View

4. ViewModel calls: walletRepo.getWalletById(studentWalletId)
   └── WalletRepository (Repository) → Supabase SELECT

5. ViewModel calls: walletRepo.updateBalance(agentWalletId, -amount)
   └── WalletRepository → Supabase UPDATE (deduct from agent)

6. ViewModel calls: walletRepo.updateBalance(studentWalletId, +amount)
   └── WalletRepository → Supabase UPDATE (credit student)

7. ViewModel calls: txRepo.createTransaction(FARE, agentWalletId, studentWalletId, amount)
   └── TransactionRepository → Supabase INSERT (audit log)

8. ViewModel updates state:
   state = state.copyWith(wallet: updatedWallet, transferSuccess: '₦... transferred!')

9. Riverpod notifies all watchers of the state change

10. RetailTransferView rebuilds and shows the success banner
    └── View (the user sees the result)
```

---

## Riverpod: `watch` vs `read`

This is the most important rule for writing correct Views:

| Situation | Use | Why |
|---|---|---|
| Rendering data in `build()` | `ref.watch()` | Widget rebuilds whenever state changes |
| Calling an action in `onPressed` | `ref.read()` | Just need to call the method once — no subscription needed |
| Reading state inside a callback | `ref.read()` | Callbacks aren't part of the build cycle |

```dart
// CORRECT — in build()
final state = ref.watch(agentDashboardViewModelProvider);

// CORRECT — in a button callback
onPressed: () => ref.read(agentDashboardViewModelProvider.notifier).signOut(),

// WRONG — watch inside a callback causes bugs
onPressed: () => ref.watch(agentDashboardViewModelProvider).user, // DON'T DO THIS
```

---

## Unit Testing — How Fake Repositories Work

The MVVM + Riverpod combination makes ViewModels easy to test without a real Supabase connection. The pattern is:

1. Create a fake class that implements the same repository interface
2. Override the Riverpod provider with the fake in a `ProviderContainer`
3. Call ViewModel methods and assert on the resulting state

```dart
// From test/viewmodels/agent_dashboard_viewmodel_test.dart

class FakeWalletRepository implements WalletRepository {
  final Map<String, WalletModel> _wallets;
  FakeWalletRepository(this._wallets);

  @override
  Future<WalletModel?> getWalletById(String walletId) async {
    return _wallets[walletId]; // Returns null if not in map → tests "not found" case
  }
  // ...
}

final container = ProviderContainer(overrides: [
  walletRepositoryProvider.overrideWithValue(FakeWalletRepository(wallets)),
]);
```

Run all tests: `flutter test`
