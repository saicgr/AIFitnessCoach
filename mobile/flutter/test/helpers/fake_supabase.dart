import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Initialises a signed-out, offline [Supabase] singleton for widget tests.
///
/// Large parts of the app read `Supabase.instance` transitively —
/// `apiClientProvider` calls `ApiClient.startAuthListener()`, several
/// repositories resolve the session for a user id — and in a unit test that
/// trips `'You must initialize the supabase instance before calling
/// Supabase.instance'` on the very first build, before any assertion in the
/// test can run. Screens with a wide provider surface (Settings) cannot
/// realistically stub every one of those providers, so give them the real
/// singleton instead:
///
///  * [EmptyLocalStorage] — never persists or recovers a session, so
///    `currentSession`/`currentUser` are always null: the signed-out state.
///  * `detectSessionInUri: false` — skips the deep-link observer, which needs
///    the `app_links` platform channel.
///  * `autoRefreshToken: false` — no background refresh timer, so
///    `pumpAndSettle()` still settles.
///  * a loopback URL — nothing is ever dialled; any accidental request fails
///    fast against `flutter_test`'s mock HTTP client rather than hitting prod.
///
/// Idempotent: `Supabase.initialize` short-circuits once initialised, so this
/// is safe to call from every `setUpAll`/test in a file.
Future<void> initFakeSupabase() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(<String, Object>{});
  // Without this the Keychain plugin is absent, so `ApiClient`'s resilient
  // wrapper falls back to its 4s `.timeout()` — which leaves a pending Timer
  // at teardown ("A Timer is still pending even after the widget tree was
  // disposed"). An empty mock store resolves every read instantly, which is
  // also the truthful signed-out state.
  FlutterSecureStorage.setMockInitialValues(<String, String>{});
  await Supabase.initialize(
    url: 'http://127.0.0.1:1',
    // Shape-valid anon JWT (header.payload.signature) — never verified,
    // never sent anywhere.
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiJ9.test-anon-key',
    debug: false,
    authOptions: FlutterAuthClientOptions(
      localStorage: EmptyLocalStorage(),
      detectSessionInUri: false,
      autoRefreshToken: false,
    ),
  );
}
