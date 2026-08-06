// Regression gate for row 147 (E2E): the composer's mic button is
// push-to-talk (record starts on long-press, stops on release) with no
// affordance saying so — a plain tap (the gesture users try first, and the
// one that occupies this exact slot once text is typed and it becomes the
// send button) was a complete no-op: no recording UI, no tooltip, no hint,
// nothing changed on screen.
//
// This test covers the plain-tap path only — it needs no platform channel
// mocking (permission_handler / record), unlike the long-press → record
// path, which would need those mocked to run headless. The reported defect
// IS the plain-tap no-op, so that's what's asserted here.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/screens/chat/widgets/voice_message_widget.dart';

void main() {
  testWidgets('a plain tap tells the user to press and hold, instead of '
      'silently doing nothing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: VoiceRecorderButton(onRecordingComplete: (_, __) {})),
      ),
    );

    expect(find.byIcon(Icons.mic), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);

    await tester.tap(find.byIcon(Icons.mic));
    await tester.pump(); // SnackBar's entrance animation start
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(SnackBar), findsOneWidget,
        reason: 'A plain tap must say why nothing happened instead of '
            'reading as a dead button.');
    expect(find.textContaining('Press and hold'), findsOneWidget);

    // Still not recording — the tap must not have started anything.
    expect(find.byIcon(Icons.mic), findsOneWidget);
  });

  testWidgets('exposes a tooltip and a semantics label naming the gesture',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: VoiceRecorderButton(onRecordingComplete: (_, __) {})),
      ),
    );

    expect(find.byType(Tooltip), findsOneWidget);
    expect(
      tester.widget<Tooltip>(find.byType(Tooltip)).message,
      contains('Hold'),
    );
    expect(
      find.bySemanticsLabel(RegExp('Press and hold')),
      findsOneWidget,
    );
  });
}
