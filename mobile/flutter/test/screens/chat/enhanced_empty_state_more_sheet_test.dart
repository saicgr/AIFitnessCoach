// Regression gate for row 197 (E2E): the "More" sheet ("Try asking Coach
// Mike") stacked two drag-handle grabbers and two close controls in ~35pt of
// vertical space — `_SuggestionsSheet` is a fully self-contained sheet (its
// own DraggableScrollableSheet, blur, border, grabber pill, close button),
// but `_showMoreSuggestions` also wrapped it in `GlassSheet`, which draws its
// OWN `GlassSheetHandle` (a second pill + a second close, in `Icons.close`
// rather than `_SuggestionsSheet`'s own `Icons.close_rounded`). Nothing
// distinguished the two, so the sheet read as drawn twice.
//
// Fix: `_showMoreSuggestions` now passes `_SuggestionsSheet` straight to
// `showGlassSheet` unwrapped — `GlassSheetHandle` (and its whole `GlassSheet`
// chrome) never renders for this sheet.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/core/providers/locale_provider.dart' show supportedAppLocales;
import 'package:fitwiz/data/models/coach_persona.dart';
import 'package:fitwiz/l10n/generated/app_localizations.dart';
import 'package:fitwiz/screens/chat/widgets/enhanced_empty_state.dart';
import 'package:fitwiz/widgets/glass_sheet.dart';

void main() {
  testWidgets('the More sheet shows exactly one grabber and one close control',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
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
          body: EnhancedEmptyState(
            coach: CoachPersona.predefinedCoaches.first,
            onSuggestionTap: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    // The redundant outer GlassSheet (and its GlassSheetHandle grabber+close)
    // must not render at all for this sheet.
    expect(find.byType(GlassSheetHandle), findsNothing,
        reason: '_SuggestionsSheet draws its own chrome; GlassSheet\'s '
            'handle must not ALSO render on top of it.');
    // GlassSheetHandle uses Icons.close (not close_rounded) — its absence
    // confirms the outer wrapper's close control is gone too.
    expect(find.byIcon(Icons.close), findsNothing);

    // _SuggestionsSheet's own close button (Icons.close_rounded) is the only
    // close control left, exactly once.
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
  });
}
