# QR Fare Transit — Operations App

A Flutter-based mobile operations application designed for university transit systems, providing tailored workflows for **Agents** and **Drivers**. Built to operate seamlessly with Supabase backend services, the application enables field agents to vend token credits directly to student digital wallets and provides drivers with a real-time boarding manifest, automated visual boarding signals, and background GPS telemetry broadcasting.

---

## Key Features

- **QR Code Staff Onboarding**: Staff accounts are pre-staged via the central administrative web dashboard. Staff scan an onboarding QR code from their mobile device to auto-fill registration parameters and configure their credentials.
- **Agent Digital Vault & Retail Transfers**:
  - Live token balance visualization of the agent's allocated vault.
  - Built-in camera scanner via `mobile_scanner` to capture student wallet QR codes and auto-fill recipient IDs.
  - Client- and server-validated token transfers ensuring sufficient balance and atomic wallet credit/debit.
  - Complete, filterable agent ledger and transaction history.
- **Driver Live Manifest & Boarding Signals**:
  - Real-time WebSocket connection to Supabase listening for student fare payment events.
  - Full-screen green flash boarding animation and passenger count increment upon every verified payment.
  - Haptic feedback vibration (`VIBRATE` permission) on student check-in.
  - Shift summary and daily revenue/fare collection ledger.
- **Automated GPS Telemetry Broadcasting**: Continuous background location tracking utilizing `geolocator`, broadcasting coordinates and transit metadata to the Supabase `telemetry` table every 5 seconds.
- **Role-Based Navigation & Auth Guard**: Deep integration between `GoRouter` and Riverpod (`RouterNotifier`) enforcing strict role isolation. Unauthenticated or unauthorized users are automatically redirected away from `/agent/*` and `/driver/*` route trees.

---

## Architecture Overview

The application follows the **MVVM (Model-View-ViewModel)** architectural pattern, decoupled through **Riverpod** for reactive state management and dependency injection:

```
┌─────────────────────────────────────────────────────────────┐
│                         Views (UI)                          │
│   (ConsumerWidget / ConsumerStatefulWidget via ref.watch)   │
└──────────────────────────────┬──────────────────────────────┘
                               │ Observes state / Dispatches user actions
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                 ViewModels (Riverpod Notifiers)             │
│   (AuthViewModel, AgentDashboardVM, DriverDashboardVM)      │
└──────────────────────────────┬──────────────────────────────┘
                               │ Calls domain actions
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                 Repositories (Data Access)                  │
│  (AuthRepository, WalletRepository, TransactionRepository)  │
└──────────────────────────────┬──────────────────────────────┘
                               │ Reads supabaseClientProvider
                               ▼
┌─────────────────────────────────────────────────────────────┐
│            Supabase Backend (Auth / DB / Realtime)          │
└─────────────────────────────────────────────────────────────┘
```

- **Models (`lib/models/`)**: Immutable data classes with JSON serialization, deserialization, and domain enumerations (`UserRole`, `WalletType`, `TransactionType`, `TransactionStatus`).
- **Repositories (`lib/repositories/`)**: Abstract data access layer encapsulating database queries, authentication methods, and WebSocket channels. Repositories consume `supabaseClientProvider` via dependency injection, allowing straightforward mocking in unit tests.
- **ViewModels (`lib/viewmodels/`)**: Extend Riverpod's `Notifier<T>` to manage UI state, run validations, execute async operations, and handle error boundaries.
- **Views (`lib/views/`)**: Pure presentation layer reacting to state changes and delegating user interactions to ViewModels.
- **Navigation & Auth Guard (`lib/core/router/`)**: `routerProvider` instantiates `GoRouter` using `RouterNotifier` as its `refreshListenable`. `RouterNotifier` observes Riverpod's `authViewModelProvider`, recalculating routing logic on any authentication state change to guard protected paths.

---

## Project Structure

```
lib/
├── main.dart                          # App entry point; QrFareApp is a ConsumerWidget
├── core/
│   ├── constants/
│   │   ├── app_routes.dart            # All GoRouter route path strings
│   │   └── app_strings.dart           # UI copy strings
│   ├── network/
│   │   └── supabase_client.dart       # Supabase init and supabaseClientProvider
│   ├── router/
│   │   ├── app_router.dart            # routerProvider — GoRouter as a Riverpod Provider
│   │   └── router_notifier.dart       # RouterNotifier — auth guard bridge
│   ├── services/
│   │   ├── audio_service.dart         # Boarding chime (placeholder — .mp3 not added yet)
│   │   └── location_service.dart      # Wraps geolocator for GPS coordinates
│   ├── theme/
│   │   ├── app_colors.dart            # Colour palette for Agent and Driver themes
│   │   └── app_theme.dart             # Dark MaterialTheme
│   └── utils/
│       └── app_logger.dart            # logger package wrapper
├── models/
│   ├── user_model.dart                # UserModel + UserRole enum
│   ├── wallet_model.dart              # WalletModel + WalletType enum
│   ├── transaction_model.dart         # TransactionModel + TransactionType/Status enums
│   └── telemetry_model.dart           # TelemetryModel (GPS broadcast rows)
├── repositories/
│   ├── auth_repository.dart           # Supabase Auth: signIn, signOut, getCurrentUser
│   ├── wallet_repository.dart         # wallets table: get by owner/id, updateBalance
│   ├── transaction_repository.dart    # transactions: create, fetch, Realtime stream
│   └── telemetry_repository.dart      # telemetry: broadcastLocation INSERT
├── viewmodels/
│   ├── auth_viewmodel.dart            # AuthViewModel (Notifier<AuthState>)
│   ├── agent_dashboard_viewmodel.dart # AgentDashboardViewModel — transfer logic
│   └── driver_dashboard_viewmodel.dart # DriverDashboardViewModel — GPS + Realtime
└── views/
    ├── splash_view.dart               # Session restore → role-based redirect
    ├── role_selection_view.dart       # Agent / Driver role picker
    ├── login_with_email_view.dart     # Email + password sign-in
    ├── forgot_password_view.dart      # Password reset email
    ├── qr_register_view.dart          # Scan admin QR → auto-register + set password
    ├── shared/                        # Reusable widgets (StatCard, PrimaryButton, etc.)
    ├── agent/
    │   ├── agent_dashboard_view.dart  # Vault balance + recent transactions
    │   ├── retail_transfer_view.dart  # Token transfer form
    │   ├── topup_scanner_view.dart    # QR scanner to auto-fill student wallet ID
    │   └── agent_history_view.dart    # Full transaction history
    └── driver/
        ├── driver_dashboard_view.dart # Live manifest + green flash boarding animation
        └── driver_ledger_view.dart    # Today's fares and shift totals
```

### Test Suite Structure

```
test/
├── widget_test.dart                   # Widget test placeholder
└── viewmodels/
    ├── agent_dashboard_viewmodel_test.dart  # 11 tests — transfer business logic & validations
    └── auth_viewmodel_test.dart             # 14 tests — sign-in, sign-out, session restore
```

---

## Dependencies

The project utilizes the following production and development dependencies:

| Package | Version | Purpose |
| :--- | :--- | :--- |
| [`flutter_riverpod`](https://pub.dev/packages/flutter_riverpod) | `^2.6.1` | Reactive state management, dependency injection, and ViewModel orchestration |
| [`go_router`](https://pub.dev/packages/go_router) | `^14.8.1` | Declarative routing with redirect listeners and role-based route guarding |
| [`supabase_flutter`](https://pub.dev/packages/supabase_flutter) | `^2.9.0` | Client SDK for Supabase Auth, PostgreSQL queries, and Realtime WebSocket subscriptions |
| [`mobile_scanner`](https://pub.dev/packages/mobile_scanner) | `^5.2.3` | Hardware camera QR scanning for student wallets and onboarding invitations |
| [`geolocator`](https://pub.dev/packages/geolocator) | `^13.0.2` | High-accuracy GPS tracking for driver telemetry transmission |
| [`audioplayers`](https://pub.dev/packages/audioplayers) | `^6.4.0` | Boarding chime playback (asset integration pending) |
| [`permission_handler`](https://pub.dev/packages/permission_handler) | `^11.4.0` | Android runtime permission requests for Camera and Fine Location |
| [`uuid`](https://pub.dev/packages/uuid) | `^4.5.1` | RFC 4122 UUID generation for idempotent client transactions |
| [`logger`](https://pub.dev/packages/logger) | `^2.4.0` | Formatted, leveled console logging (`debug`, `info`, `warning`, `error`) |
| [`flutter_lints`](https://pub.dev/packages/flutter_lints) | `^5.0.0` | Official Flutter static analysis rule sets |

---

## Environment & Hardware Permissions

### 1. Supabase Configuration
Project endpoints and public keys are configured in [`lib/core/network/supabase_client.dart`](file:///c:/Users/User/Final%20year%20project/driver_agent_fyp/lib/core/network/supabase_client.dart):

```dart
const String _supabaseUrl = '<YOUR_SUPABASE_PROJECT_URL>';
const String _supabaseAnonKey = '<YOUR_SUPABASE_ANON_KEY>';
```

> **Security Note:** The `anon` key is safe to embed in client-side code as access control is strictly enforced by PostgreSQL Row-Level Security (RLS) policies. **Never** include the Supabase `service_role` key in the mobile application.

### 2. Android Permissions
The following hardware and system permissions are defined in [`android/app/src/main/AndroidManifest.xml`](file:///c:/Users/User/Final%20year%20project/driver_agent_fyp/android/app/src/main/AndroidManifest.xml):

- `android.permission.INTERNET`: HTTP REST and Realtime WebSocket communication with Supabase.
- `android.permission.ACCESS_FINE_LOCATION` & `android.permission.ACCESS_COARSE_LOCATION`: High-accuracy device coordinate acquisition for live vehicle tracking.
- `android.permission.CAMERA`: Hardware camera scanner for parsing onboarding and student wallet QR codes.
- `android.permission.VIBRATE`: Tactile feedback when a student boarding event triggers on the driver manifest.

---

## Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (version `^3.7.2` / Dart `^3.7.2`)
- Android Studio / Android SDK (Platform SDK 34+ recommended)
- Physical Android device or Android Virtual Device (AVD) emulator

### Installation & Execution

1. **Clone and enter the repository:**
   ```bash
   cd driver_agent_fyp
   ```

2. **Install project dependencies:**
   ```bash
   flutter pub get
   ```

3. **Verify static analysis:**
   ```bash
   flutter analyze
   ```

4. **Execute unit tests:**
   ```bash
   flutter test
   ```

5. **Launch the application:**
   ```bash
   flutter run
   ```
