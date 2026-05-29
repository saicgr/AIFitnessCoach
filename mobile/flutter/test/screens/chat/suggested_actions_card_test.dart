/// Widget tests for SuggestedActionsCard — the AI-coach launcher chips.
///
/// Covers the edge handling that makes the card safe: allowlist filtering of
/// hallucinated/disallowed IDs, the 4-chip cap, result-aware suppression, the
/// form-video bridge gate, the empty -> render-nothing rule, and the prompt
/// fallback. Tap behaviour for launcher chips routes through go_router (needs
/// a full app), so we only exercise the `attach_form_video` tap (a plain
/// callback) here; launch parity is covered by the home-grid path.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/screens/chat/widgets/suggested_actions_card.dart';

Widget _harness(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('SuggestedActionsCard', () {
    testWidgets('renders allowlisted chips and drops disallowed IDs',
        (tester) async {
      await tester.pumpWidget(_harness(const SuggestedActionsCard(
        actionIds: ['scan_menu', 'settings', 'history'],
        prompt: 'Quick ways I can help:',
      )));
      await tester.pump();

      expect(find.text('Scan Menu'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      // 'settings' is NOT in kChatLaunchableActionIds → never rendered.
      expect(find.text('Settings'), findsNothing);
      expect(find.text('Quick ways I can help:'), findsOneWidget);
    });

    testWidgets('caps at 4 chips and dedupes', (tester) async {
      await tester.pumpWidget(_harness(const SuggestedActionsCard(
        actionIds: [
          'scan_menu',
          'scan_menu', // dup
          'photo_food',
          'workout',
          'library',
          'history', // 5th unique → dropped by the cap
        ],
      )));
      await tester.pump();

      expect(find.text('Scan Menu'), findsOneWidget); // deduped
      expect(find.text('Snap Food'), findsOneWidget);
      expect(find.text('Workout'), findsOneWidget);
      expect(find.text('Library'), findsOneWidget);
      expect(find.text('History'), findsNothing); // over the 4-cap
    });

    testWidgets('suppresses excludeIds (dedup vs result card)',
        (tester) async {
      await tester.pumpWidget(_harness(const SuggestedActionsCard(
        actionIds: ['scan_menu', 'workout'],
        excludeIds: {'scan_menu'},
      )));
      await tester.pump();

      expect(find.text('Scan Menu'), findsNothing);
      expect(find.text('Workout'), findsOneWidget);
    });

    testWidgets('hides attach_form_video when no bridge callback',
        (tester) async {
      await tester.pumpWidget(_harness(const SuggestedActionsCard(
        actionIds: ['attach_form_video', 'workout'],
      )));
      await tester.pump();

      expect(find.text('Check my form'), findsNothing);
      expect(find.text('Workout'), findsOneWidget);
    });

    testWidgets('shows attach_form_video and fires the bridge on tap',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(_harness(SuggestedActionsCard(
        actionIds: const ['attach_form_video'],
        onAttachFormVideo: () => tapped = true,
      )));
      await tester.pump();

      expect(find.text('Check my form'), findsOneWidget);
      await tester.tap(find.text('Check my form'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('renders nothing when every ID is filtered out',
        (tester) async {
      await tester.pumpWidget(_harness(const SuggestedActionsCard(
        actionIds: ['settings', 'schedule', 'bogus_id'],
        prompt: 'should not appear',
      )));
      await tester.pump();

      // No prompt line, no chips — collapses to an empty box.
      expect(find.text('should not appear'), findsNothing);
      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('falls back to a variant prompt when none supplied',
        (tester) async {
      await tester.pumpWidget(_harness(const SuggestedActionsCard(
        actionIds: ['scan_menu'],
      )));
      await tester.pump();

      expect(find.text('Scan Menu'), findsOneWidget);
      // Exactly one non-chip lead-in line is present (a pool variant).
      final texts = tester.widgetList<Text>(find.byType(Text)).toList();
      expect(texts.length, greaterThanOrEqualTo(2)); // prompt + chip label
    });
  });
}
