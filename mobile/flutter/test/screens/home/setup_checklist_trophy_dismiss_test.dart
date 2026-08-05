/// Change 2 — a completed "Get Started Challenge" card no longer has to sit
/// on Home until the 7-day trophy-window auto-expiry; the user can dismiss it
/// immediately with an X, and that dismissal must persist (not just hide for
/// the current widget lifetime). These tests assert the RENDERED trophy text
/// disappears, and that a fresh mount against the SAME SharedPreferences
/// store (simulating a relaunch) never resurrects it.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitwiz/core/providers/user_provider.dart';
import 'package:fitwiz/data/models/user.dart';
import 'package:fitwiz/data/providers/xp_provider.dart';
import 'package:fitwiz/screens/home/widgets/cards/setup_checklist_card.dart';

import 'test_provider_stubs.dart';

final _user = User(
  id: 'trophy-user',
  name: 'Trophy Tester',
  // Outside the 14-day "still offered" window is irrelevant here — the card
  // is already complete, which short-circuits that check.
  createdAt: DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
);

List<Override> get _overrides => [
      currentUserProvider.overrideWith((ref) => AsyncValue.data(_user)),
      // The card also reads `xpProvider` (via `_has()`) during build for its
      // (unused, in the trophy branch) item list — stub it so that never
      // touches a real repository/Dio in the test.
      xpProvider.overrideWith((ref) => StubXPNotifier()),
    ];

Widget _wrap(Widget child) {
  return ProviderScope(
    overrides: _overrides,
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  setUp(() {
    // Pre-seed a completed challenge, done "just now" — well inside the
    // 7-day trophy window, so the card renders the one-line trophy instead
    // of being expired already.
    SharedPreferences.setMockInitialValues({
      'get_started_challenge_done_${_user.id}': true,
      'get_started_challenge_done_at_${_user.id}':
          DateTime.now().toIso8601String(),
    });
  });

  group('SetupChecklistCard — completed trophy dismiss', () {
    testWidgets('completed trophy renders with an X dismiss action',
        (tester) async {
      await tester.pumpWidget(_wrap(const SetupChecklistCard()));
      await tester.pump();
      await tester.pump();

      expect(find.text('GET STARTED CHALLENGE'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets(
        'tapping the X hides the card, and the dismissal survives a fresh mount against the same store',
        (tester) async {
      await tester.pumpWidget(_wrap(const SetupChecklistCard()));
      await tester.pump();
      await tester.pump();
      expect(find.text('GET STARTED CHALLENGE'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump(); // setState hides the card immediately
      await tester.pump(); // let the SharedPreferences write settle
      expect(find.text('GET STARTED CHALLENGE'), findsNothing);

      // Simulate a relaunch: tear the widget down and remount it fresh,
      // against the SAME (now-mutated) SharedPreferences mock store — no
      // re-seeding. If the dismiss only lived in State, this would resurrect
      // the trophy; it must not.
      await tester.pumpWidget(_wrap(const SizedBox.shrink()));
      await tester.pumpWidget(_wrap(const SetupChecklistCard()));
      await tester.pump();
      await tester.pump();

      expect(find.text('GET STARTED CHALLENGE'), findsNothing);
    });
  });
}
