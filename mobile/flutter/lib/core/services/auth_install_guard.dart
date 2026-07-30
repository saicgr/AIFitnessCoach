import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// What [AuthInstallGuard.run] decided on this launch. Returned (rather than
/// just logged) so the caller — and a test — can assert the branch taken.
enum AuthInstallGuardOutcome {
  /// The install marker was already present: a normal launch of an app that has
  /// run at least once since it was installed. Nothing was touched.
  subsequentRun,

  /// First launch since (re)install and there was nothing left over to clear.
  /// This is the clean-install case.
  firstRunClean,

  /// First launch since a REINSTALL: credentials from the previous install were
  /// still present and have been cleared, so the app starts signed out.
  firstRunClearedStaleSession,
}

/// Deletes credentials that outlive an app uninstall, so a reinstall really is
/// a clean install.
///
/// ## The bug this exists for (E2E register #41)
///
/// On iOS the **Keychain survives app deletion** — only erasing the device
/// clears it. Everything else the app persists (`NSUserDefaults`, i.e. Flutter's
/// `SharedPreferences`, plus the app container and the Drift database) IS wiped.
/// That asymmetry is what made a "clean install" resume mid-onboarding as the
/// previous user:
///
///  * the Supabase session lives in `SharedPreferences`
///    (`main.dart` configures `SharedPreferencesLocalStorage`) → gone on delete,
///  * but `ApiClient` keeps `auth_token` + `user_id` in `FlutterSecureStorage`
///    (Keychain) → **survives**,
///  * and `AuthRepository.restoreSession()` falls back to exactly that stored
///    token when there is no Supabase session
///    (`if (!await _apiClient.isAuthenticated()) return null;` →
///    `getCurrentUser()` → `GET /users/{user_id}`),
///
/// so the fresh install authenticated as whoever last used the device.
///
/// ## The fix
///
/// Detect first-run-after-install using a marker in `SharedPreferences` — the
/// store that IS cleared by an uninstall — and, when the marker is absent, wipe
/// the Keychain-backed auth credentials before anything reads them.
///
/// ## Ordering contract
///
/// [run] must be awaited in `main()` **after** `SharedPreferences.getInstance()`
/// and `Supabase.initialize()` have completed and **before** `runApp()`, i.e.
/// before `AuthNotifier._init()` can call `restoreSessionWithCache()`. Running
/// it earlier cannot see a recovered Supabase session; running it later races
/// the auth restore it is meant to pre-empt.
///
/// ## Why the marker is written before the wipe
///
/// The wipe is best-effort (a locked/entitlement-broken Keychain can throw). If
/// the marker were written only on success, a device where the delete keeps
/// failing would re-enter this branch on EVERY launch — and by launch two the
/// user may legitimately be signed in, so we would be signing out a real
/// session. Writing the marker first means the guard can only ever fire once
/// per install, which is exactly its contract. The marker write happens before
/// `runApp`, so there is no window in which a real sign-in could be lost.
///
/// ## What is deliberately NOT cleared
///
///  * the Drift database key (`FlutterSecureStorage`, `db_encryption_key`) — the
///    database file itself is deleted with the app container, so a surviving key
///    just re-encrypts the new, empty database. Deleting it is pointless churn.
///  * E2EE key material — the server-side data it decrypts outlives the install,
///    so dropping it would make that data permanently unreadable.
///  * the device id — it is not an identity, and keeping it stable across a
///    reinstall is desirable for install attribution.
///
/// Only the two keys that actually authenticate a request are removed.
class AuthInstallGuard {
  const AuthInstallGuard._();

  /// `SharedPreferences` marker proving the app has launched at least once
  /// since it was installed. Absent ⇒ this is the first run after an install
  /// (fresh or re-install), because an uninstall takes `NSUserDefaults` /
  /// Android `SharedPreferences` with it.
  @visibleForTesting
  static const String installMarkerKey = 'auth.installMarkerV1';

  /// Keychain keys that authenticate an API request. These MUST stay in sync
  /// with `ApiClient._tokenKey` / `ApiClient._userIdKey`.
  @visibleForTesting
  static const List<String> keychainAuthKeys = <String>['auth_token', 'user_id'];

  /// Mirror namespace `_ResilientSecureStorage` writes to when the Keychain is
  /// unavailable (`-34018`) or stalls. Lives in `SharedPreferences`, so it is
  /// already gone after an uninstall — cleared here only so the two stores can
  /// never disagree.
  static const String _sharedPrefsMirrorPrefix = 'secure.';

  /// Same options `ApiClient` constructs its storage with. The delete has to
  /// address the same Keychain/EncryptedSharedPreferences item the write
  /// created, so these cannot drift.
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    // Kept byte-identical to `ApiClient._ResilientSecureStorage`'s options on
    // purpose: the delete has to address the same item the write created, so
    // these two must not drift. (v10 ignores this flag and auto-migrates, so it
    // is inert either way — hence the ignore rather than a divergence.)
    // ignore: deprecated_member_use
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  /// Pure decision, split out so the rule is directly assertable: the guard
  /// fires exactly when the install marker is missing.
  ///
  ///  * fresh install, no token        → marker absent  → fires, clears nothing
  ///  * reinstall, stale Keychain token → marker absent  → fires, clears it
  ///  * every later launch              → marker present → does not fire
  ///  * restore-from-backup (marker and Keychain restored together, same user)
  ///    → marker present → does not fire, session correctly preserved
  @visibleForTesting
  static bool shouldClearStaleCredentials({required bool hasInstallMarker}) =>
      !hasInstallMarker;

  /// Runs the guard. Safe to call more than once (the second call sees the
  /// marker and returns [AuthInstallGuardOutcome.subsequentRun]). Never throws:
  /// a failure here must not be able to block app startup.
  static Future<AuthInstallGuardOutcome> run() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasMarker = prefs.getBool(installMarkerKey) ?? false;
      if (!shouldClearStaleCredentials(hasInstallMarker: hasMarker)) {
        return AuthInstallGuardOutcome.subsequentRun;
      }

      // Marker first — see the "Ordering contract" note above.
      await prefs.setBool(installMarkerKey, true);

      final hadCredentials = await _clearStaleCredentials(prefs);
      if (hadCredentials) {
        debugPrint(
          '🧹 [AuthInstallGuard] First run after reinstall — cleared '
          'Keychain credentials left behind by the previous install',
        );
        return AuthInstallGuardOutcome.firstRunClearedStaleSession;
      }
      debugPrint('✅ [AuthInstallGuard] First run after install — nothing stale');
      return AuthInstallGuardOutcome.firstRunClean;
    } catch (e) {
      // A guard that crashes startup is worse than the bug it prevents.
      debugPrint('⚠️ [AuthInstallGuard] Guard failed, continuing: $e');
      return AuthInstallGuardOutcome.subsequentRun;
    }
  }

  /// Removes every credential that could re-authenticate the previous install.
  /// Returns true if anything was actually found and removed.
  static Future<bool> _clearStaleCredentials(SharedPreferences prefs) async {
    var found = false;

    for (final key in keychainAuthKeys) {
      try {
        if (await _storage.read(key: key) != null) {
          found = true;
          await _storage.delete(key: key);
        }
      } catch (e) {
        debugPrint('⚠️ [AuthInstallGuard] Keychain delete failed for "$key": $e');
      }
      // The SharedPreferences shadow copy the -34018 / stall fallback writes.
      final mirrorKey = '$_sharedPrefsMirrorPrefix$key';
      if (prefs.containsKey(mirrorKey)) {
        found = true;
        await prefs.remove(mirrorKey);
      }
    }

    // Defensive: if a future build ever moves Supabase session persistence off
    // SharedPreferences and onto the Keychain, a recovered session would
    // outlive the uninstall too. Drop it locally (never server-side — the
    // session on other devices is not ours to revoke).
    try {
      if (Supabase.instance.client.auth.currentSession != null) {
        found = true;
        await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
      }
    } catch (e) {
      // Supabase not initialised yet, or already signed out — both benign.
      debugPrint('⚠️ [AuthInstallGuard] Local Supabase sign-out skipped: $e');
    }

    return found;
  }
}
