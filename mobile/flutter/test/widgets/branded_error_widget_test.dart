// Gate: the error boundary must never itself fail.
//
// Two defects, both found tonight and both worse than an ordinary bug because
// this widget IS what users see once something has already gone wrong:
//
//  1. It overflowed its own card by 46px at 1.3x text scale — a fixed Column
//     in a slot whose height it does not control (test/ui_gates/
//     no_overflow_gate_test.dart). It is ErrorWidget.builder, installed
//     globally in main.dart, so this is app-wide.
//  2. It told the user "Go back and reopen it" while rendering ZERO controls.
//     A screenshot audit of 862 screens found it was the only route type in
//     the app with no way out. Users reach it for real — three Sentry issues
//     and the chat-rename crash all land here.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:fitwiz/widgets/branded_error_widget.dart';

FlutterErrorDetails _details() => FlutterErrorDetails(
      exception: Exception('boom'),
      library: 'test',
    );

/// Mounts the boundary in a slot of a given size and text scale, the way a
/// failed screen-level widget actually renders it.
Widget _inSlot({required Size slot, double textScale = 1.0, Widget? home}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: home ??
          Scaffold(
            body: Center(
              child: SizedBox(
                width: slot.width,
                height: slot.height,
                child: BrandedErrorWidget(details: _details()),
              ),
            ),
          ),
    ),
  );
}

void main() {
  group('BrandedErrorWidget — must not overflow its own slot', () {
    // The reported failure was a 170-300px slot at 1.3x. Cover the range and
    // beyond, because the whole point is that it fits at ANY scale.
    for (final slot in const [Size(360, 170), Size(360, 240), Size(320, 300)]) {
      for (final scale in const [1.0, 1.3, 2.0]) {
        testWidgets('slot ${slot.width}x${slot.height} @${scale}x',
            (tester) async {
          await tester.pumpWidget(_inSlot(slot: slot, textScale: scale));
          await tester.pump();
          expect(tester.takeException(), isNull,
              reason: 'the error boundary overflowed at ${scale}x in a '
                  '${slot.width}x${slot.height} slot — it is the LAST thing '
                  'that should break');
        });
      }
    }
  });

  group('BrandedErrorWidget — a way out', () {
    testWidgets('offers a Go back control when the route can pop',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => Scaffold(
                    body: BrandedErrorWidget(details: _details()),
                  ),
                ),
              ),
              child: const Text('go'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(find.text('Go back'), findsOneWidget,
          reason: 'the copy instructs the user to go back — there must be '
              'something to go back with');

      // And it must be a real touch target, not a 70x15pt sliver like the
      // "Talk more" control that silently missed taps elsewhere in this app.
      final size = tester.getSize(find.widgetWithText(TextButton, 'Go back'));
      expect(size.height, greaterThanOrEqualTo(44.0));
      expect(size.width, greaterThanOrEqualTo(44.0));

      await tester.tap(find.text('Go back'));
      await tester.pumpAndSettle();
      expect(find.text('go'), findsOneWidget,
          reason: 'tapping Go back must actually pop the route');
    });

    testWidgets(
        'offers a Go to Home control (not Go back) when there is nothing to pop to',
        (tester) async {
      // Reached via a deep link (no back stack) — the boundary must not
      // strand the user until they relaunch the app.
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: BrandedErrorWidget(details: _details()),
            ),
          ),
          GoRoute(
            path: '/home',
            builder: (context, state) => const Scaffold(body: Text('home')),
          ),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      expect(find.text('Go back'), findsNothing);
      expect(find.text('Go to Home'), findsOneWidget);

      await tester.tap(find.text('Go to Home'));
      await tester.pumpAndSettle();
      expect(find.text('home'), findsOneWidget,
          reason: 'tapping Go to Home must actually navigate there');
    });

    testWidgets('a tiny slot still renders the minimal mark, not a crash',
        (tester) async {
      await tester.pumpWidget(_inSlot(slot: const Size(120, 60)));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });
  });
}
