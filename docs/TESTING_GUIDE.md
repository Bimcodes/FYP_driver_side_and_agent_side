# Testing Guide — QR Fare Transit App

This document explains the test setup, the strategy used, and how to run and extend the test suite.

---

## Running Tests

```bash
# Run all tests
flutter test

# Run only the ViewModel tests
flutter test test/viewmodels/

# Run a single test file with verbose output
flutter test test/viewmodels/agent_dashboard_viewmodel_test.dart --reporter=expanded

# Static analysis — check for type errors and lints
flutter analyze
```

---

## Test Structure

```
test/
├── widget_test.dart                           # Placeholder (kept for reference)
└── viewmodels/
    ├── agent_dashboard_viewmodel_test.dart    # 11 tests — transfer business logic
    └── auth_viewmodel_test.dart               # 14 tests — auth state transitions
```

**Total: 25 tests, all passing.**

---

## What Is Tested

### `agent_dashboard_viewmodel_test.dart` — 11 Tests

This file tests `AgentDashboardViewModel.transferToStudent()` — the most critical method in the app. It moves tokens between wallets and creates an audit record.

| Test | Scenario |
|---|---|
| Valid transfer deducts balance & sets success | Happy path — normal transfer |
| Valid transfer creates exactly one FARE record | Audit trail is correct |
| New transaction prepended to list (newest first) | UI ordering |
| Zero-amount transfer → error | Edge case |
| Negative-amount transfer → error | Edge case |
| Over-balance transfer → `Insufficient balance` error | Business rule enforcement |
| Exact-balance transfer succeeds | Boundary test — `amount == balance` is allowed |
| Non-existent student wallet → error | Not-found case |
| `clearTransferFeedback()` removes success and error | State cleanup |
| `copyWith(clearTransferSuccess: true)` nullifies success | State flag correctness |
| Unrelated fields preserved on partial `copyWith` | Immutability check |

### `auth_viewmodel_test.dart` — 14 Tests

| Test | Scenario |
|---|---|
| Successful sign-in → `state.user` populated | Happy path |
| Failed sign-in → `state.errorMessage` set | Wrong credentials |
| New sign-in attempt clears old error | Error is transient |
| Sign-out → state fully reset | Logout |
| `restoreSession()` with active session → returns user | Session persist |
| `restoreSession()` with no session → returns null | First launch |
| `copyWith(clearError: true)` → error becomes null | State flag |
| `copyWith(clearUser: true)` → user becomes null | State flag |
| `copyWith(isLoading: true)` preserves other fields | Immutability |
| `UserRole.fromString()` parses all 4 roles | Model parsing |
| `UserRole.fromString()` is case-insensitive | Robustness |
| `UserRole.fromString()` throws for unknown role | Error handling |
| `UserRole.toDbString()` produces correct strings | DB round-trip |

---

## The Testing Strategy — Fake Repositories

Riverpod's dependency injection system is what makes ViewModel testing practical. Instead of hitting a real Supabase database, tests provide **fake repository implementations** that return controlled data from memory.

### Why Fakes Over Mocks

A **fake** is a real implementation of the same interface that works in memory. A **mock** is a generated stub that records calls. Fakes are preferred here because:

- They're readable — you can see exactly what data they return
- They don't require a mocking library
- They can simulate stateful behaviour (e.g., a wallet balance that decreases after a transfer)

### The Pattern

```dart
// 1. Define a fake that implements the real repository interface
class FakeWalletRepository implements WalletRepository {
  final Map<String, WalletModel> _wallets;
  FakeWalletRepository(this._wallets);

  @override
  Future<WalletModel?> getWalletById(String walletId) async {
    return _wallets[walletId]; // Returns null if walletId not in map
  }

  @override
  Future<WalletModel> updateBalance({required String walletId, required double delta}) async {
    final wallet = _wallets[walletId]!;
    final updated = wallet.copyWithBalance(wallet.balance + delta);
    _wallets[walletId] = updated; // Stateful — the balance actually changes
    return updated;
  }
}

// 2. Override the real provider with the fake in a ProviderContainer
final container = ProviderContainer(overrides: [
  walletRepositoryProvider.overrideWithValue(FakeWalletRepository(wallets)),
  transactionRepositoryProvider.overrideWithValue(FakeTransactionRepository()),
]);

// 3. Read the ViewModel — it now uses the fake repos automatically
final vm = container.read(agentDashboardViewModelProvider.notifier);

// 4. Pre-seed the ViewModel state (e.g., give the agent a starting balance)
container.read(agentDashboardViewModelProvider.notifier).state =
    AgentDashboardState(wallet: agentWallet);

// 5. Call the method under test
await vm.transferToStudent(agentWalletId: ..., studentWalletId: ..., amount: 200);

// 6. Assert on the resulting state
final state = container.read(agentDashboardViewModelProvider);
expect(state.wallet?.balance, equals(300)); // 500 - 200 = 300
```

---

## How to Add a New Test

### For a ViewModel test

1. Open the relevant test file in `test/viewmodels/`
2. Add a new `test()` call inside the appropriate `group()`
3. Follow the **Arrange → Act → Assert** structure:

```dart
test('description of what this tests', () async {
  // Arrange: set up the container with fake repos and seed state
  final container = _buildContainer(agentBalance: 500);

  // Act: call the method under test
  await container
      .read(agentDashboardViewModelProvider.notifier)
      .transferToStudent(agentWalletId: ..., studentWalletId: ..., amount: 100);

  // Assert: check the resulting state
  final state = container.read(agentDashboardViewModelProvider);
  expect(state.transferError, isNull);
  expect(state.wallet?.balance, equals(400));
});
```

### For a new ViewModel

1. Create `test/viewmodels/new_feature_viewmodel_test.dart`
2. Implement fake repositories for any repositories the ViewModel uses
3. Write a `_buildContainer()` helper that overrides providers
4. Group tests by method name using `group()`

---

## What Is NOT Tested (and Why)

| Area | Reason |
|---|---|
| Views (UI widgets) | Widget tests require a real Flutter engine and Supabase mocks — high effort, low ROI for an FYP |
| Repositories (database queries) | Requires either a real Supabase instance or complex HTTP mocking — integration testing not in scope |
| GoRouter navigation | The redirect logic is tested indirectly through the auth state machine |
| GPS / camera hardware | Hardware-dependent — mocked at the service level in the ViewModel |

The focus of this test suite is **ViewModel business logic** — the rules that govern token transfers and auth state transitions. These are the highest-value tests because they cover the most critical, mistake-prone code in the app.
