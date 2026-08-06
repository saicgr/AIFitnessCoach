// Regression test for E2E row 125: the End Fast toast's UNDO action — the
// app's ONLY caller of `undoEndFast` — was both unreadable and untappable for
// the whole life of the toast, because the floating quick-log FAB sat on top
// of it (docs/qa/screenshots/2026-08-05/ui_nutrition_37_logmeal_s.png).
//
// The occlusion is structural, not incidental: main_shell.dart paints the FAB
// as a `Positioned` child added AFTER the tab content in the shell Stack, while
// the SnackBar is shown through the tab's own Scaffold inside that content — so
// the button is ALWAYS above any SnackBar, on every tab that shows it. And
// because QuickLogFabChrome wraps itself in
// `GestureDetector(behavior: HitTestBehavior.opaque)` and Stack hit-tests
// last-child-first, a tap in the overlap opened the quick-log sheet rather than
// firing the toast's action.
//
// The fix is geometric and lives at the two places every SnackBar in the app
// gets its position from:
//   1. `snackBarTheme.insetPadding` (app_theme.dart / theme_provider.dart) was
//      the literal `80`, inside the FAB's [92, 136] band. It now derives from
//      the FAB's own tokens via `kSnackBarBottomInset`.
//   2. main_shell.dart re-applies the RUNTIME bottom safe-area inset on top of
//      it, because Flutter measures a floating SnackBar's insetPadding from the
//      raw screen edge while the FAB is positioned at
//      `paddingOf(context).bottom + kQuickLogFabBottomOffset` — so on a device
//      with a home indicator the button rises and the static value alone would
//      let it land back on the toast. (The first test below pins that Flutter
//      behaviour, so this stops being a claim and starts being a check.)
//
// The tests assert the DEFECT: a real FAB-sized box exactly where
// main_shell.dart positions the button, a real SnackBar with an action under
// the real app theme, and the two rects must not intersect.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/core/constants/app_colors.dart';
import 'package:fitwiz/core/constants/chrome_constants.dart';
import 'package:fitwiz/core/theme/app_theme.dart';
import 'package:fitwiz/core/theme/theme_provider.dart';

const _fabKey = ValueKey('fab-stand-in');

/// The SnackBar's own RenderBox spans down to the bottom of the screen (the
/// inset padding is applied INSIDE it), so measuring `find.byType(SnackBar)`
/// would measure a box the user never sees. The visible toast is its Material.
Finder _toastSurface() => find
    .descendant(of: find.byType(SnackBar), matching: find.byType(Material))
    .first;

/// Mirrors `main_shell.dart` exactly: the shell-level SnackBar inset override
/// wrapped around the tab content, and the FAB at
/// `Positioned(right: 24, bottom: paddingOf(context).bottom +
/// kQuickLogFabBottomOffset)` with a `kQuickLogFabHeight`-tall child.
Future<void> _pumpShellWithToast(
  WidgetTester tester,
  ThemeData theme, {
  required double bottomSafeArea,
  bool applyShellInsetOverride = true,
}) async {
  final messengerKey = GlobalKey<ScaffoldMessengerState>();

  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      scaffoldMessengerKey: messengerKey,
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(390, 844),
          padding: EdgeInsets.only(bottom: bottomSafeArea),
        ),
        child: Stack(
          textDirection: TextDirection.ltr,
          children: [
            Positioned.fill(
              child: Builder(
                builder: (innerContext) {
                  final t = Theme.of(innerContext);
                  final tabContent = const Scaffold(
                    backgroundColor: Colors.black,
                    body: SizedBox.expand(),
                  );
                  if (!applyShellInsetOverride) return tabContent;
                  return Theme(
                    data: t.copyWith(
                      snackBarTheme: t.snackBarTheme.copyWith(
                        insetPadding: EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 8,
                          bottom: MediaQuery.paddingOf(innerContext).bottom +
                              kSnackBarBottomInset,
                        ),
                      ),
                    ),
                    child: tabContent,
                  );
                },
              ),
            ),
            Positioned(
              right: 24,
              bottom: bottomSafeArea + kQuickLogFabBottomOffset,
              child: const SizedBox(
                key: _fabKey,
                height: kQuickLogFabHeight,
                width: 130, // the expanded pill, its widest resting state
              ),
            ),
          ],
        ),
      ),
    ),
  );

  messengerKey.currentState!.showSnackBar(
    SnackBar(
      content: const Text('You fasted for 0h 8m'),
      action: SnackBarAction(label: 'UNDO', onPressed: () {}),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'PREMISE: Flutter measures a floating SnackBar from the raw screen edge, '
    'ignoring the bottom safe-area inset',
    (tester) async {
      // This is why the theme constant alone cannot clear the FAB, and why
      // main_shell.dart re-applies the runtime inset. If a future Flutter
      // starts honouring the inset here, this test fails and the shell
      // override becomes double-padding that should be removed.
      final rects = <double, Rect>{};
      for (final pad in <double>[0, 34]) {
        await _pumpShellWithToast(
          tester,
          AppTheme.buildDarkTheme(AppColors.orange),
          bottomSafeArea: pad,
          applyShellInsetOverride: false,
        );
        rects[pad] = tester.getRect(_toastSurface());
      }
      expect(rects[0]!.bottom, rects[34]!.bottom);
    },
  );

  for (final bottomSafeArea in <double>[0, 34]) {
    testWidgets(
      'a floating SnackBar clears the quick-log FAB '
      '(bottom safe area $bottomSafeArea)',
      (tester) async {
        await _pumpShellWithToast(
          tester,
          AppTheme.buildDarkTheme(AppColors.orange),
          bottomSafeArea: bottomSafeArea,
        );

        expect(find.text('UNDO'), findsOneWidget,
            reason: 'premise: the toast and its action are on screen');

        final toast = tester.getRect(_toastSurface());
        final fab = tester.getRect(find.byKey(_fabKey));

        expect(
          toast.overlaps(fab),
          isFalse,
          reason: 'The quick-log FAB paints above every SnackBar, so any '
              'overlap hides (and steals taps from) the toast action. '
              'toast=$toast fab=$fab',
        );
        expect(
          toast.bottom,
          lessThanOrEqualTo(fab.top),
          reason: 'the toast must sit entirely ABOVE the button, not beside it',
        );
      },
    );
  }

  testWidgets(
    'the UNDO action specifically is clear of the FAB',
    (tester) async {
      await _pumpShellWithToast(
        tester,
        AppTheme.buildDarkTheme(AppColors.orange),
        bottomSafeArea: 34,
      );

      // The reported failure was specifically that UNDO — at the toast's
      // trailing edge — sat under the right-anchored pill.
      final undo = tester.getRect(find.text('UNDO'));
      final fab = tester.getRect(find.byKey(_fabKey));

      expect(undo.overlaps(fab), isFalse, reason: 'undo=$undo fab=$fab');
    },
  );

  testWidgets(
    'light theme uses the same clearance',
    (tester) async {
      await _pumpShellWithToast(
        tester,
        AppThemeLight.buildTheme(AppColors.orange),
        bottomSafeArea: 34,
      );

      final toast = tester.getRect(_toastSurface());
      final fab = tester.getRect(find.byKey(_fabKey));
      expect(toast.overlaps(fab), isFalse, reason: 'toast=$toast fab=$fab');
    },
  );
}
