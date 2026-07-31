import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Wiring gate for E2E register #41.
///
/// `AuthInstallGuard` (lib/core/services/auth_install_guard.dart) shipped
/// correct and fully tested (see auth_install_guard_test.dart) but as DEAD
/// CODE: `grep -rln "AuthInstallGuard" lib/` returned only the file that
/// defines it — zero imports, zero call sites, no `.run()` invocation. A
/// reinstall kept resuming as the previous user, exactly as originally
/// reported, because nothing ever called the fix.
///
/// A source-scan (rather than driving real `main()`, which boots Firebase,
/// Sentry, RevenueCat, etc. — impractical headlessly) is the same pattern
/// already used by test/lint/easy_single_surface_test.dart for "this call
/// site must exist" invariants. It directly reproduces the failure mode: if
/// someone deletes the `AuthInstallGuard.run()` line again, this test fails
/// immediately instead of the bug going unnoticed until the next E2E pass.
void main() {
  test('main() imports AuthInstallGuard and calls run() before runApp(), '
      'after SharedPreferences + Supabase are ready', () {
    final file = File('lib/main.dart');
    expect(file.existsSync(), isTrue, reason: 'main.dart moved?');
    final src = file.readAsStringSync();

    expect(
      src.contains("import 'core/services/auth_install_guard.dart';"),
      isTrue,
      reason: 'main.dart must import AuthInstallGuard',
    );

    final callSite = src.indexOf('AuthInstallGuard.run()');
    expect(
      callSite,
      isNot(-1),
      reason: 'AuthInstallGuard.run() must actually be invoked — a fix '
          'nobody calls is not a fix (this is the entire E2E #41 bug)',
    );

    // Ordering contract (see AuthInstallGuard's own doc comment): must run
    // after SharedPreferences.getInstance() + Supabase.initialize() have
    // completed, and before runApp().
    final sharedPrefsInit = src.indexOf('SharedPreferences.getInstance()');
    final supabaseInit = src.indexOf('Supabase.initialize(');
    // Search from the call site onward — main.dart's own doc comments about
    // the ordering contract mention "runApp()" in prose before the real call,
    // which would otherwise make this indexOf find the WORDS, not the CALL.
    final runAppCall = src.indexOf('runApp(', callSite);

    expect(sharedPrefsInit, isNot(-1));
    expect(supabaseInit, isNot(-1));
    expect(runAppCall, isNot(-1));

    expect(
      callSite > sharedPrefsInit,
      isTrue,
      reason: 'guard must run after SharedPreferences.getInstance() is '
          'reachable, or it cannot see the install marker',
    );
    expect(
      callSite > supabaseInit,
      isTrue,
      reason: 'guard must run after Supabase.initialize() is reachable, or '
          'it cannot see a recovered Supabase session to drop',
    );
    expect(
      callSite < runAppCall,
      isTrue,
      reason: 'guard must complete before runApp(), or AuthNotifier can '
          'read stale credentials before the guard clears them',
    );

    // And it must actually be awaited, not fired-and-forgotten (which would
    // race runApp() despite textually preceding it).
    final lineStart = src.lastIndexOf('\n', callSite);
    final line = src.substring(lineStart, callSite);
    expect(
      line.contains('await'),
      isTrue,
      reason: 'AuthInstallGuard.run() must be awaited — an un-awaited call '
          'races runApp() and reintroduces the same bug non-deterministically',
    );
  });
}
