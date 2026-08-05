// Gate: a root SnackBar must leave the screen on a WALL CLOCK, not on its
// entrance animation completing.
//
// Reported from device: the Nutrition "Logged …" confirmation banner never
// dismissed. It was still up 13 minutes after the log, on an unrelated
// screen, covering the very row it was announcing.
//
// Mechanism: a SnackBar's auto-dismiss timer starts when its entrance
// animation COMPLETES. `TickerMode` freezes animations for an offstage branch
// of the shell's IndexedStack, so a toast caught mid-entrance never finishes
// entering and its timer never starts. Because `rootSnackBar` uses the ROOT
// messenger — deliberately, so toasts survive navigation — the stuck toast
// then outlives sub-tab switches and full-screen pushes too.
//
// `MainShell.clearSnackBars()` on bottom-nav change did not save us: it is one
// chokepoint, and neither a sub-tab switch nor a route push goes through it.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/data/providers/root_messenger.dart';

Widget _app({bool tickersEnabled = true}) {
  return MaterialApp(
    scaffoldMessengerKey: rootScaffoldMessengerKey,
    home: TickerMode(
      enabled: tickersEnabled,
      child: const Scaffold(body: SizedBox.expand()),
    ),
  );
}

void main() {
  testWidgets('a normally-animating snackbar still dismisses on its own',
      (tester) async {
    await tester.pumpWidget(_app());
    rootSnackBar(const SnackBar(
      content: Text('Logged Scrambled Eggs'),
      duration: Duration(seconds: 2),
    ));
    await tester.pump();
    expect(find.text('Logged Scrambled Eggs'), findsOneWidget);

    // The entrance animation must finish before the SnackBar's own
    // auto-dismiss timer even starts — that ordering IS the bug's mechanism,
    // so the test has to honour it rather than pump the duration alone.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Logged Scrambled Eggs'), findsNothing,
        reason: 'the ordinary path must still work — the backstop is not '
            'meant to be what dismisses a healthy toast');
  });

  testWidgets('a snackbar whose animation is FROZEN still goes away',
      (tester) async {
    // TickerMode(enabled: false) reproduces an offstage IndexedStack branch:
    // the entrance animation cannot complete, so the SnackBar's own
    // auto-dismiss timer never starts. This is the reported bug.
    await tester.pumpWidget(_app(tickersEnabled: false));
    rootSnackBar(const SnackBar(
      content: Text('Logged Toast'),
      duration: Duration(seconds: 2),
    ));
    await tester.pump();
    expect(find.text('Logged Toast'), findsOneWidget);

    // Well past the snackbar's own duration — with a frozen ticker this is
    // exactly where the old code left it on screen forever.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(kRootSnackBarBackstopMargin);
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Logged Toast'), findsNothing,
        reason: 'a frozen entrance animation must not pin the toast on '
            'screen — this is the 13-minute banner from the device report');
    // Drain any pending timer so the test does not fail on a pending-timer
    // assertion rather than on the behaviour under test.
    await tester.pumpAndSettle();
  });

  testWidgets('the backstop does not double-close an already-closed snackbar',
      (tester) async {
    // The backstop normally fires AFTER the ordinary dismissal has already
    // run. Closing a finished controller throws, so an unguarded backstop
    // would blow up on the happy path rather than on an edge case.
    await tester.pumpWidget(_app());
    rootSnackBar(const SnackBar(
      content: Text('Logged Oats'),
      duration: Duration(milliseconds: 500),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400)); // entrance completes
    await tester.pump(const Duration(milliseconds: 500)); // its own duration
    await tester.pumpAndSettle();
    expect(find.text('Logged Oats'), findsNothing);

    // Now let the backstop's timer fire on the already-closed controller.
    await tester.pump(kRootSnackBarBackstopMargin + const Duration(seconds: 1));
    expect(tester.takeException(), isNull,
        reason: 'the backstop must be safe to fire after normal dismissal');
  });

  testWidgets('an explicitly hidden snackbar does not trip the backstop',
      (tester) async {
    await tester.pumpWidget(_app());
    final c = rootSnackBar(const SnackBar(
      content: Text('Logged Rice'),
      duration: Duration(seconds: 30),
    ));
    await tester.pump();
    c!.close();
    await tester.pumpAndSettle();
    expect(find.text('Logged Rice'), findsNothing);

    await tester.pump(const Duration(seconds: 32));
    expect(tester.takeException(), isNull);
  });
}
