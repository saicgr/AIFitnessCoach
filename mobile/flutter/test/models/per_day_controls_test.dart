import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/screens/workout/widgets/per_day_focus_chips.dart';

/// Widget tests for the shared PerDayControls — the per-day focus/duration/
/// intensity/gym component reused by the unified editor AND the per-day sheet.
void main() {
  Widget host({
    String? focus,
    List gymProfiles = const [],
    required ValueChanged<String> onFocusChanged,
    required VoidCallback onAiDecide,
    ValueChanged<String?>? onGymChanged,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: PerDayControls(
            focus: focus,
            durationMin: null,
            intensity: null,
            gymProfileId: null,
            equipmentOverride: null,
            accent: Colors.green,
            textPrimary: Colors.white,
            textMuted: Colors.grey,
            onFocusChanged: onFocusChanged,
            onAiDecide: onAiDecide,
            onDurationChanged: (_) {},
            onIntensityChanged: (_) {},
            onGymChanged: onGymChanged ?? (_) {},
            onEquipmentChanged: (_) {},
            gymProfiles: List.from(gymProfiles),
          ),
        ),
      ),
    );
  }

  testWidgets('renders an explicit "AI decide" chip', (tester) async {
    await tester.pumpWidget(host(
      focus: 'upper_body',
      onFocusChanged: (_) {},
      onAiDecide: () {},
    ));
    expect(find.text('AI decide'), findsOneWidget);
  });

  testWidgets('tapping "AI decide" fires onAiDecide (clears the day)',
      (tester) async {
    var aiDecideTaps = 0;
    await tester.pumpWidget(host(
      focus: 'upper_body',
      onFocusChanged: (_) {},
      onAiDecide: () => aiDecideTaps++,
    ));
    await tester.tap(find.text('AI decide'));
    await tester.pump();
    expect(aiDecideTaps, 1);
  });

  testWidgets('tapping a focus chip fires onFocusChanged with its value',
      (tester) async {
    String? picked;
    final opt = kFocusOptions.first; // first real focus option
    await tester.pumpWidget(host(
      focus: null,
      onFocusChanged: (v) => picked = v,
      onAiDecide: () {},
    ));
    await tester.tap(find.text(opt.label));
    await tester.pump();
    expect(picked, opt.value);
  });

  testWidgets('gym selector is hidden when fewer than 2 gym profiles',
      (tester) async {
    await tester.pumpWidget(host(
      focus: 'full_body',
      gymProfiles: const [], // 0 profiles → no gym selector
      onFocusChanged: (_) {},
      onAiDecide: () {},
    ));
    // "Active gym" label only appears in the gym selector block.
    expect(find.text('Active gym'), findsNothing);
  });
}
