/// Regression test for Home → GET STARTED CHALLENGE card (E2E row 50, HIGH).
///
/// The completed-challenge trophy advertised a specific reward the account
/// never received: "+290 XP" was the client's hardcoded sum of five local
/// literals (25+50+150+50+15 in `setup_checklist_card.dart`). The XP the
/// account actually held (`xp_transactions`, matching `user_xp.total_xp`)
/// summed to 131 for those same five events — every first-time bonus landed
/// at roughly half its advertised face value, and a THIRD number
/// (`user_first_time_bonuses.xp_awarded`) disagreed with both. None of the
/// three numbers the app/DB could produce matched what was shown.
///
/// There is no reliable way to compute the real per-item awarded amount
/// client-side (the gating logic that produced 131 isn't exposed anywhere
/// the client can read), so per CLAUDE.md's "no fallback/fabricated data —
/// if the truth is unknown, say so" rule, the fix removes the specific
/// figure entirely rather than replacing one wrong constant with another.
/// This test pins that the trophy card never prints a "+<number> XP"
/// pattern — a regression back to a hardcoded total fails it immediately.
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
  id: 'no-xp-fab-user',
  name: 'Tester',
  createdAt: DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
);

List<Override> get _overrides => [
      currentUserProvider.overrideWith((ref) => AsyncValue.data(_user)),
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
    // Same completed-and-inside-window seed as the trophy-dismiss test, so
    // the card renders the one-line trophy (the surface E2E row 50 flagged).
    SharedPreferences.setMockInitialValues({
      'get_started_challenge_done_${_user.id}': true,
      'get_started_challenge_done_at_${_user.id}':
          DateTime.now().toIso8601String(),
    });
  });

  testWidgets(
      'the completed-challenge trophy never prints a fabricated "+N XP" '
      'total', (tester) async {
    await tester.pumpWidget(_wrap(const SetupChecklistCard()));
    await tester.pump();
    await tester.pump();

    expect(find.text('GET STARTED CHALLENGE'), findsOneWidget,
        reason: 'sanity: the trophy card must actually be rendering');

    // The old bug: 'All 5 done · +290 XP' — a number nothing in the account
    // ever matched. Assert the exact fixed copy AND, independently, that no
    // "+<digits> XP" pattern exists anywhere under this card at all (so a
    // future regression that reintroduces a DIFFERENT hardcoded number is
    // caught too, not just this one).
    expect(find.text('All 5 done'), findsOneWidget,
        reason: 'trophy summary must not append a specific XP figure that '
            'nothing in the account\'s real ledger can substantiate');

    final xpAmountPattern = RegExp(r'\+\d+\s*XP');
    final allTextWidgets = tester.widgetList<Text>(find.byType(Text));
    for (final t in allTextWidgets) {
      final str = t.data ?? t.textSpan?.toPlainText() ?? '';
      expect(
        xpAmountPattern.hasMatch(str),
        isFalse,
        reason: 'found a fabricated "+N XP" figure in trophy card text: '
            '"$str" — E2E row 50: no client literal survives contact with '
            'the real xp_transactions ledger',
      );
    }
  });
}
