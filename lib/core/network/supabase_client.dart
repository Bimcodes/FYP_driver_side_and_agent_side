// =============================================================================
// FILE: core/network/supabase_client.dart
// LAYER: Core / Network
//
// PURPOSE:
//   This file has two jobs:
//   1. Initialise the Supabase connection once, at app startup.
//   2. Expose the Supabase client as a Riverpod Provider so any Repository
//      can access it via dependency injection (no global singletons).
//
// MVVM CONNECTION:
//   This file lives at the very bottom of the dependency chain:
//     main.dart → calls initSupabase()
//     Repositories → read supabaseClientProvider
//     ViewModels → read repositories via their own providers
//     Views → watch ViewModels
//
// SUPABASE CREDENTIALS:
//   Replace the placeholder strings below with your real values from:
//   Supabase Dashboard → Settings → API
//   - Project URL   → SUPABASE_URL
//   - anon/public   → SUPABASE_ANON_KEY
//
// IMPORTANT — SECURITY:
//   The anon key is safe to include in a mobile app. It is a public key.
//   Supabase uses Row Level Security (RLS) policies to control what
//   authenticated vs. anonymous users can read/write. Never put your
//   service_role key in the app — that bypasses all RLS rules.
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Supabase Credentials ──────────────────────────────────────────────────────
// TODO: Replace these with your real project values from supabase.com
// Navigate to: Your Project → Settings → API → Project URL & API Keys
const String _supabaseUrl = 'https://rkdfcosecgyiqvridwvo.supabase.co';
const String _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJrZGZjb3NlY2d5aXF2cmlkd3ZvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM1OTQ1MjUsImV4cCI6MjA5OTE3MDUyNX0.cwFSzdDsYT9VJTKPa7BGF4Dxfjg6bKgRPCrTU_WaO8Y';

// ── Initialisation ────────────────────────────────────────────────────────────

/// Initialises the Supabase Flutter SDK.
///
/// Must be called once, before [runApp()], in [main()].
/// After this call, [Supabase.instance.client] is available anywhere.
///
/// Example usage in main.dart:
/// ```dart
/// await initSupabase();
/// runApp(const ProviderScope(child: MyApp()));
/// ```
Future<void> initSupabase() async {
  await Supabase.initialize(
    url: _supabaseUrl,
    publishableKey: _supabaseAnonKey,
    // realtimeClientOptions configures the persistent WebSocket connection
    // used by the Driver's Live Manifest to listen for boarding events.
    realtimeClientOptions: const RealtimeClientOptions(
      eventsPerSecond: 10, // Throttle to max 10 events/second
    ),
  );
}

// ── Riverpod Provider ────────────────────────────────────────────────────────

/// Provides the [SupabaseClient] instance to any Riverpod consumer.
///
/// Repositories inject this provider to access the database.
///
/// WHY A PROVIDER INSTEAD OF A GLOBAL?
///   Using a Provider means the client is part of the dependency graph.
///   In tests, you can override this provider with a mock client —
///   testing your Repository logic without a real network connection.
///
/// Example usage in a Repository:
/// ```dart
/// final client = ref.read(supabaseClientProvider);
/// final data = await client.from('wallets').select().eq('owner_id', userId);
/// ```
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  // Supabase.instance.client is the singleton created by initSupabase().
  return Supabase.instance.client;
});
