/// Change 1 — the Home masthead collapsed its two-line greeting + big Anton
/// date block ("Morning, Casey." / "WEDNESDAY · AUGUST 5") into a single line
/// ("Morning, Casey · Wed, Aug 5"). These tests assert the RENDERED text, not
/// just that `MinimalHeader` builds — a passing "widget exists" test would
/// not have caught the old two-line layout still being there.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/core/providers/user_provider.dart';
import 'package:fitwiz/data/models/user.dart';
import 'package:fitwiz/data/providers/unified_notifications_provider.dart';
import 'package:fitwiz/l10n/generated/app_localizations.dart';
import 'package:fitwiz/screens/home/widgets/minimal_header.dart';

const _weekdaysShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _monthsShort = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Independently computes the short date the header should render, from the
/// SAME wall-clock the widget itself reads. Kept as a plain literal mapping
/// (not `intl`'s `DateFormat`) so the test doesn't depend on `intl` locale
/// initialization having run in the bare test harness.
String _expectedShortDate(DateTime now) =>
    '${_weekdaysShort[now.weekday - 1]}, ${_monthsShort[now.month - 1]} ${now.day}';

String _expectedGreetingWord(DateTime now) {
  final hour = now.hour;
  if (hour < 12) return 'Morning';
  if (hour < 17) return 'Afternoon';
  return 'Evening';
}

Widget _wrap(Widget child, List<Override> overrides) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('MinimalHeader greeting line', () {
    testWidgets(
        'renders the first name and the short date together on one line',
        (tester) async {
      final user = User(id: 'u1', name: 'Casey Jordan');
      await tester.pumpWidget(_wrap(const MinimalHeader(), [
        currentUserProvider.overrideWith((ref) => AsyncValue.data(user)),
        unifiedUnreadCountProvider.overrideWithValue(0),
      ]));
      await tester.pump();

      final now = DateTime.now();
      final expected =
          '${_expectedGreetingWord(now)}, Casey · ${_expectedShortDate(now)}';

      expect(find.text(expected), findsOneWidget);
      // The old two-line layout showed the greeting alone, with a trailing
      // period and no date on the same line — pin that it's gone, not just
      // that some greeting text exists.
      expect(
        find.text('${_expectedGreetingWord(now)}, Casey.'),
        findsNothing,
      );
    });

    testWidgets(
        'degrades to the date alone when the name is unavailable — no "there" placeholder',
        (tester) async {
      final user = User(id: 'u2', name: null);
      await tester.pumpWidget(_wrap(const MinimalHeader(), [
        currentUserProvider.overrideWith((ref) => AsyncValue.data(user)),
        unifiedUnreadCountProvider.overrideWithValue(0),
      ]));
      await tester.pump();

      final expected = _expectedShortDate(DateTime.now());
      expect(find.text(expected), findsOneWidget);
      // Real-name-personalization rule: no placeholder name ever substitutes
      // for a missing real one.
      expect(find.textContaining('there'), findsNothing);
    });
  });
}
