/// Issue 2: widget tests for EquipmentMatchCard + the "What's this?"
/// chat pill registration.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/core/models/chat_quick_action.dart';
import 'package:fitwiz/core/models/quick_action.dart';
import 'package:fitwiz/screens/chat/widgets/equipment_match_card.dart';

void _wrap(Widget child) {} // helper kept inline below

Widget _harness(Widget child) {
  return MaterialApp(
    theme: ThemeData.light(),
    home: Scaffold(body: child),
  );
}

void main() {
  group('EquipmentMatchCard', () {
    testWidgets('renders canonical name + match rows when matches present',
        (tester) async {
      Map<String, dynamic>? tappedMatch;
      await tester.pumpWidget(_harness(EquipmentMatchCard(
        actionData: const {
          'action': 'open_swap_or_add',
          'canonical_name': 'lat_pulldown',
          'matches': [
            {
              'id': 'ex-1',
              'name': 'Lat Pulldown',
              'image_url': '',
              'primary_muscle': 'lats',
              'badge': 'Recently used',
            },
            {
              'id': 'ex-2',
              'name': 'Wide-Grip Pulldown',
              'image_url': '',
              'primary_muscle': 'lats',
            },
          ],
          'snapped_equipment_id': 'snap-1',
        },
        onMatchTap: (m) => tappedMatch = m,
      )));

      await tester.pump();

      expect(find.text('Lat Pulldown'), findsAtLeastNWidgets(1));
      expect(find.text('Wide-Grip Pulldown'), findsOneWidget);
      expect(find.text('Recently used'), findsOneWidget);
      // Canonical headline humanizes lat_pulldown → Lat Pulldown
      expect(find.text('2 exercises you can do here'), findsOneWidget);

      // Tap the first "Use" button.
      await tester.tap(find.text('Use').first);
      expect(tappedMatch, isNotNull);
      expect(tappedMatch!['id'], 'ex-1');
    });

    testWidgets('empty matches → shows Create custom exercise CTA',
        (tester) async {
      bool createTapped = false;
      await tester.pumpWidget(_harness(EquipmentMatchCard(
        actionData: const {
          'action': 'open_swap_or_add',
          'canonical_name': 'weird_machine',
          'matches': [],
          'unmatched_reason': 'no_canonical',
        },
        onMatchTap: (_) {},
        onCreateCustom: () => createTapped = true,
      )));
      await tester.pump();

      expect(find.text('Create custom exercise'), findsOneWidget);
      expect(find.text('No matching exercises in your library yet'),
          findsOneWidget);
      await tester.tap(find.text('Create custom exercise'));
      expect(createTapped, isTrue);
    });

    testWidgets('not_equipment → no Create custom exercise CTA',
        (tester) async {
      await tester.pumpWidget(_harness(EquipmentMatchCard(
        actionData: const {
          'action': 'open_swap_or_add',
          'matches': [],
          'unmatched_reason': 'not_equipment',
          'vision_label': 'food_plate',
        },
        onMatchTap: (_) {},
        onCreateCustom: () {},
      )));
      await tester.pump();

      expect(find.text('Not gym equipment'), findsOneWidget);
      // Edge case: not_equipment skips the create-custom CTA — telling the
      // user to "add a custom photo of their lunch" would be silly.
      expect(find.text('Create custom exercise'), findsNothing);
    });

    testWidgets('start_workout_with_equipment CTA fires when provided',
        (tester) async {
      bool startTapped = false;
      await tester.pumpWidget(_harness(EquipmentMatchCard(
        actionData: const {
          'action': 'open_swap_or_add',
          'canonical_name': 'lat_pulldown',
          'matches': [
            {
              'id': 'ex-1',
              'name': 'Lat Pulldown',
              'image_url': '',
              'primary_muscle': 'lats',
            },
          ],
        },
        onMatchTap: (_) {},
        onStartWorkoutWithEquipment: () => startTapped = true,
      )));
      await tester.pump();
      expect(find.text('Start a workout with this'), findsOneWidget);
      await tester.tap(find.text('Start a workout with this'));
      expect(startTapped, isTrue);
    });
  });

  group('Issue 2 registry wiring', () {
    test('chatQuickActionRegistry has identify_equipment with intent tag', () {
      final action = chatQuickActionRegistry['identify_equipment'];
      expect(action, isNotNull);
      expect(action!.label, "What's this?");
      expect(action.behavior, ChatActionBehavior.openMediaPicker);
      expect(action.mediaMode, ChatMediaMode.camera);
      // The example prompt must carry the intent marker so the chat
      // pipeline can route the resulting message to identify_equipment.
      expect(
        action.examplePrompt,
        startsWith('[intent:identify_equipment]'),
      );
    });

    test('defaultChatQuickActionOrder includes identify_equipment', () {
      expect(defaultChatQuickActionOrder.contains('identify_equipment'),
          isTrue);
    });

    test('home QuickAction registry has identify_equipment, but NOT in '
        'default 2x5 grid (rule: slot 9 stays scan_menu, slot 10 is More)',
        () {
      final action = quickActionRegistry['identify_equipment'];
      expect(action, isNotNull);
      expect(action!.behavior, QuickActionBehavior.identifyEquipment);
      // Must live in the order list (so it's visible in More sheet) but
      // never inside the first 9 slots (the 2x5 grid except More slot).
      final idx = defaultQuickActionOrder.indexOf('identify_equipment');
      expect(idx, greaterThan(8),
          reason: 'identify_equipment must NOT be in the home 2x5 grid');
    });
  });
}
