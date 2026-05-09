import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/screens/chat/widgets/chat_action_confirm_card.dart';
import '../helpers/test_helpers.dart';

/// Smoke tests for the Issue 3 ChatActionConfirmCard.
///
/// We don't exercise the live WorkoutRepository here — the goal is to
/// confirm the card renders, the auto-cancel timer fires after 90 s,
/// and tapping Cancel invokes the onCancelled callback.
///
/// Apply-path tests live in repository-level integration tests because
/// they require provider overrides for ApiClient + WorkoutRepository.
void main() {
  group('ChatActionConfirmCard', () {
    const sampleAction = {
      'action': 'log_set',
      'workout_id': '00000000-0000-0000-0000-000000000001',
      'exercise_id': '00000000-0000-0000-0000-000000000002',
      'set_index': 3,
      'weight': 40.0,
      'weight_unit': 'lb',
      'reps': 8,
      'rir': 2,
      'is_override': false,
    };

    testWidgets('renders summary text + Apply / Cancel buttons',
        (tester) async {
      await tester.pumpWidget(
        createScaffoldedWidget(
          child: const ChatActionConfirmCard(
            actionData: sampleAction,
            summaryText: 'Log set 3: 40 lb × 8 @ RIR 2',
          ),
        ),
      );

      expect(find.text('Log set 3: 40 lb × 8 @ RIR 2'), findsOneWidget);
      expect(find.text('Apply'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('Cancel calls onCancelled and shows Dismissed',
        (tester) async {
      var cancelled = false;
      await tester.pumpWidget(
        createScaffoldedWidget(
          child: ChatActionConfirmCard(
            actionData: Map<String, dynamic>.from(sampleAction),
            summaryText: 'Log set 3',
            onCancelled: () => cancelled = true,
          ),
        ),
      );

      await tester.tap(find.text('Cancel'));
      await tester.pump();

      expect(cancelled, isTrue);
      expect(find.text('Dismissed'), findsOneWidget);
    });

    testWidgets('auto-cancels after 90 seconds', (tester) async {
      var cancelled = false;
      await tester.pumpWidget(
        createScaffoldedWidget(
          child: ChatActionConfirmCard(
            actionData: Map<String, dynamic>.from(sampleAction),
            summaryText: 'Log set 3',
            onCancelled: () => cancelled = true,
          ),
        ),
      );

      // Pump past the 90 s timeout.
      await tester.pump(const Duration(seconds: 91));

      expect(cancelled, isTrue);
      expect(find.text('Dismissed'), findsOneWidget);
    });
  });
}
