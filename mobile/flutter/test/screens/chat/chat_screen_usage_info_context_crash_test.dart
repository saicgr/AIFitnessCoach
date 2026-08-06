// Regression gate for the "Usage info" crash: Coach tab -> "..." top-right ->
// "Usage info" replaced the whole screen with the branded error boundary,
// throwing:
//
//   Looking up a deactivated widget's ancestor is unsafe. At this point the
//   state of the widget's element tree is no longer stable. To safely refer
//   to a widget's ancestor in its dispose() method, save a reference to the
//   ancestor by calling dependOnInheritedWidgetOfExactType() in the widget's
//   didChangeDependencies() method.
//
// (That exact framework wording is Flutter's real
// `_debugCheckStateIsActiveForAncestorLookup` assertion text — device logs
// captured it mid-sentence, matching the QA finding's evidence.)
//
// The pre-fix `_showOptionsMenuWithUsageInfo` (chat_screen.dart) closed the
// options sheet and then reopened "Usage info" using `context` from the
// `builder: (context) => GlassSheet(...)` parameter — the SHEET'S OWN
// context, which is only valid while that sheet's route is mounted:
//
//   onTap: () {
//     Navigator.pop(context);        // starts popping the options sheet
//     _showUsageInfoSheet(context);  // reuses the SAME (sheet-owned) context
//   }
//
// `_showUsageInfoSheet` (chat_screen_ext.dart:325-333) immediately calls
// `Theme.of(context)` and `ProviderScope.containerOf(context, listen: false)`
// on that context — both are ancestor lookups, which is exactly what the
// framework refuses once an Element is deactivated. The fix captures the
// Navigator's OWN context (which lives for as long as the screen itself does,
// independent of any sheet pushed on top of it) BEFORE the `builder:` closure
// shadows `context`, and guards reuse with `.mounted`:
//
//   final rootContext = Navigator.of(context).context;   // captured early
//   ...
//   onTap: () {
//     Navigator.pop(context);
//     if (rootContext.mounted) _showUsageInfoSheet(rootContext);
//   }
//
// This mirrors the SAME defensive pattern already used a few hundred lines
// below in the same file, `_minimizeToFloatingChat` (`final rootContext =
// navigator.context; ... if (rootContext.mounted) { ... }`), written for the
// identical class of bug.
//
// This test drives the REAL production `showGlassSheet`/`GlassSheet` widgets
// (`lib/widgets/glass_sheet.dart`) through the exact two-method shape above,
// and proves the property the fix depends on end-to-end: once a pushed
// sheet's route finishes popping, ITS OWN context is no longer safe to use
// for ancestor lookups (`Theme.of`, `ProviderScope.containerOf`) — but the
// Navigator's own context, captured before the sheet ever opened, still is.
// It does not pump the full `ChatScreen` — its `initState` pulls in ~15
// unrelated providers (workouts, hydration, offline coach, router, streaming,
// media) that have no bearing on this defect and would make the test
// slow/flaky without adding coverage of the actual bug.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/core/providers/locale_provider.dart' show supportedAppLocales;
import 'package:fitwiz/l10n/generated/app_localizations.dart';
import 'package:fitwiz/widgets/glass_sheet.dart';

/// Mirrors `_ChatScreenState._showOptionsMenuWithUsageInfo` +
/// `_showUsageInfoSheet`. Opens a GlassSheet with a single "Usage info"
/// ListTile; tapping it pops the sheet and hands its captured contexts out
/// via [onCaptured] so the test can drive the pop-and-reopen sequence
/// explicitly instead of racing real frame timing inside one synchronous
/// `onTap`.
class _OptionsMenuHarness extends StatelessWidget {
  const _OptionsMenuHarness({required this.onCaptured});

  /// Called once, right when the "Usage info" ListTile builds, with
  /// (sheetOwnContext, navigatorRootContext, popTheSheet).
  final void Function(BuildContext sheetContext, BuildContext rootContext,
      VoidCallback popSheet) onCaptured;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (outerContext) => ElevatedButton(
          onPressed: () {
            // Captured BEFORE `builder:` below shadows `context` — exactly
            // where chat_screen.dart's fix captures `rootContext`.
            final rootContext = Navigator.of(outerContext).context;
            showGlassSheet<void>(
              context: outerContext,
              builder: (context) => GlassSheet(
                child: ListTile(
                  title: const Text('Usage info'),
                  onTap: () => onCaptured(
                    context,
                    rootContext,
                    () => Navigator.pop(context),
                  ),
                ),
              ),
            );
          },
          child: const Text('Open options'),
        ),
      ),
    );
  }
}

/// Mirrors `_showUsageInfoSheet` exactly: the two ancestor lookups the real
/// crash asserted on, run against whatever context the caller passes.
void _showUsageInfoSheetHarness(BuildContext context) {
  // ignore: unused_local_variable
  final isDark = Theme.of(context).brightness == Brightness.dark;
  // ignore: unused_local_variable
  final container = ProviderScope.containerOf(context, listen: false);
}

Widget _wrap(Widget child) => ProviderScope(
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
        home: child,
      ),
    );

/// The GlassSheet's `ListTile` paints inside a `DecoratedBox` with a
/// background color, which throws Flutter's benign (pre-existing, unrelated
/// to this defect) "ListTile background color or ink splashes may be
/// invisible" assertion — the same one
/// `test/screens/chat/chat_sessions_rename_crash_test.dart` filters out for
/// the identical reason.
List<Object> _drainIgnoringBenignListTileAssertion(WidgetTester tester) {
  final unexpected = <Object>[];
  Object? leftover;
  while ((leftover = tester.takeException()) != null) {
    if (!leftover.toString().contains('background color or ink splashes')) {
      unexpected.add(leftover!);
    }
  }
  return unexpected;
}

void main() {
  testWidgets(
      'pre-fix pattern: once the options sheet finishes popping, ITS OWN '
      'context throws "deactivated widget" on Theme.of/ProviderScope.'
      'containerOf — the exact crash chat_screen.dart shipped', (tester) async {
    late BuildContext sheetContext;
    late BuildContext rootContext;
    late VoidCallback popSheet;

    await tester.pumpWidget(_wrap(_OptionsMenuHarness(
      onCaptured: (sheet, root, pop) {
        sheetContext = sheet;
        rootContext = root;
        popSheet = pop;
      },
    )));
    await tester.tap(find.text('Open options'));
    await tester.pumpAndSettle();
    expect(find.text('Usage info'), findsOneWidget);

    await tester.tap(find.text('Usage info'));
    await tester.pump();
    _drainIgnoringBenignListTileAssertion(tester);

    // Let the sheet's exit transition run to completion — its route (and the
    // ListTile's own context along with it) is now fully torn down, exactly
    // as it is by the time a real device finishes the pop.
    popSheet();
    await tester.pumpAndSettle();
    _drainIgnoringBenignListTileAssertion(tester);

    expect(sheetContext.mounted, isFalse,
        reason: 'The options sheet\'s own context should be gone once its '
            'route finishes popping — that is the premise of the crash.');
    expect(rootContext.mounted, isTrue,
        reason: 'The Navigator\'s own context must survive the sheet pop — '
            'that is the premise of the fix.');

    // This is the exact call the pre-fix `_showUsageInfoSheet(context)` made
    // — Theme.of/ProviderScope.containerOf on the now-dead sheet context.
    expect(
      () => _showUsageInfoSheetHarness(sheetContext),
      throwsA(predicate((e) => e.toString().contains('deactivated') ||
          e.toString().contains('no longer stable'))),
      reason: 'Reusing the popped sheet\'s own context should reproduce the '
          'shipped "Looking up a deactivated widget\'s ancestor" crash.',
    );
  });

  testWidgets(
      'fix: reopening Usage info on the captured Navigator context (not the '
      'popped sheet\'s own context) never touches a deactivated ancestor',
      (tester) async {
    late BuildContext sheetContext;
    late BuildContext rootContext;
    late VoidCallback popSheet;

    await tester.pumpWidget(_wrap(_OptionsMenuHarness(
      onCaptured: (sheet, root, pop) {
        sheetContext = sheet;
        rootContext = root;
        popSheet = pop;
      },
    )));
    await tester.tap(find.text('Open options'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Usage info'));
    await tester.pump();
    _drainIgnoringBenignListTileAssertion(tester);
    popSheet();
    await tester.pumpAndSettle();
    _drainIgnoringBenignListTileAssertion(tester);

    expect(sheetContext.mounted, isFalse);
    expect(rootContext.mounted, isTrue);

    // This is the exact call chat_screen.dart's fix makes:
    // `if (rootContext.mounted) _showUsageInfoSheet(rootContext);`
    expect(() {
      if (rootContext.mounted) {
        _showUsageInfoSheetHarness(rootContext);
      }
    }, returnsNormally);
    expect(_drainIgnoringBenignListTileAssertion(tester), isEmpty);
  });
}
