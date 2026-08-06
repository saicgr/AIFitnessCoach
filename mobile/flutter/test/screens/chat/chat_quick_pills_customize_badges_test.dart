// Regression gate for row 144 (E2E): "Customize Shortcuts" badged its rows
// 1-5 by their position in the RAW saved order, but the pill strip renders
// `chatVisiblePillsProvider` — which re-sorts the top 5 by time of day
// (`_daypartPreferredOrder`) until the user's first manual reorder. So the
// badges lied: an item shown as "1" in Customize Shortcuts could actually be
// rendering 5th (or not at all) in the real strip.
//
// The fix computes each row's badge from `chatVisiblePillsProvider` itself —
// the exact same provider the strip renders from — instead of the row's
// position in the (still raw-ordered, so dragging is unaffected) reorderable
// list.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitwiz/core/models/chat_quick_action.dart';
import 'package:fitwiz/core/providers/locale_provider.dart' show supportedAppLocales;
import 'package:fitwiz/data/providers/chat_quick_action_provider.dart';
import 'package:fitwiz/l10n/generated/app_localizations.dart';
import 'package:fitwiz/screens/chat/widgets/chat_quick_pills.dart';

void main() {
  setUp(() {
    // `ChatQuickActionOrderNotifier`'s ctor kicks off an async `_load()`
    // against SharedPreferences regardless of the subclass below — give it
    // an empty mock store so it reads null and leaves the fixed `state` this
    // test sets alone (real behaviour: no saved order = no override).
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets(
      'a Customize Shortcuts badge matches the action\'s ACTUAL rank on the '
      'strip, not its row position in the raw saved order', (tester) async {
    // `chatVisiblePillsProvider` re-sorts the top 5 whenever the raw order
    // still equals the shipped default — override it directly so the test
    // doesn't depend on wall-clock daypart logic to force a mismatch.
    // "Check My Form" sits 2nd in the RAW order (position 2) but 4th in
    // what the strip actually renders — exactly the row-144 scenario
    // ("badge 1 renders last").
    final rawOrder = List<String>.from(defaultChatQuickActionOrder);
    final visiblePills = [
      chatQuickActionRegistry['scan_food']!,
      chatQuickActionRegistry['analyze_menu']!,
      chatQuickActionRegistry['quick_workout']!,
      chatQuickActionRegistry['check_form']!,
      chatQuickActionRegistry['nutrition_advice']!,
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatQuickActionOrderProvider.overrideWith(
            (ref) => _FixedOrderNotifier(rawOrder),
          ),
          chatVisiblePillsProvider.overrideWithValue(visiblePills),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark(),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: supportedAppLocales,
          home: Scaffold(
            body: ChatQuickPills(
              onSendPrompt: (_) {},
              onOpenMediaPicker: (_, __) {},
              isLoading: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open the "More" sheet, then its edit mode.
    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    int badgeNumberFor(String label) {
      final row = find.ancestor(
        of: find.text(label),
        matching: find.byType(Container),
      );
      final numberFinder = find.descendant(
        of: row.first,
        matching: find.byType(Text),
      );
      for (final element in numberFinder.evaluate()) {
        final text = (element.widget as Text).data;
        final n = int.tryParse(text ?? '');
        if (n != null) return n;
      }
      throw StateError('No numeric badge found for "$label"');
    }

    // "Check My Form" actually renders 4th on the strip (visiblePills[3]) —
    // the badge must say 4, not its raw-order row position.
    expect(badgeNumberFor('Check My Form'), 4);
    // "Scan Food" actually renders 1st.
    expect(badgeNumberFor('Scan Food'), 1);
  });
}

/// Minimal `ChatQuickActionOrderNotifier` stand-in that skips the real
/// class's async SharedPreferences `_load()` (which would race the assertion
/// below) while keeping the same public shape.
class _FixedOrderNotifier extends ChatQuickActionOrderNotifier {
  _FixedOrderNotifier(List<String> initial) {
    // ignore: invalid_use_of_protected_member
    state = initial;
  }
}
