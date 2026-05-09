/// Widget tests for FatigueAlertModal — Issue 4 fix verification.
///
/// Asserts:
/// - `weight_unit` from response is rendered (no hardcoded "kg").
/// - Suggested weight value renders with the correct unit.
/// - Bodyweight branch (suggested_weight == null) renders rep target card.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/screens/workout/widgets/fatigue_alert_modal.dart';

FatigueAlertData _alert({
  double? suggestedWeight = 37.5,
  String unit = 'lb',
  int? repTarget,
}) {
  return FatigueAlertData.fromJson({
    'fatigue_detected': true,
    'severity': 'high',
    'suggested_weight_reduction': 15,
    'suggested_weight': suggestedWeight,
    'weight_unit': unit,
    'weight_increment': unit == 'lb' ? 5.0 : 2.5,
    'rep_target_reduction': repTarget,
    'reasoning': 'Severe fatigue detected',
    'indicators': const ['rir_deviation'],
    'confidence': 0.9,
  });
}

void main() {
  testWidgets('renders lb unit and value, never "kg"', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FatigueAlertModal(
          alertData: _alert(suggestedWeight: 37.5, unit: 'lb'),
          currentWeight: 45.0,
          exerciseName: 'Bench Press',
          onAcceptSuggestion: () {},
          onContinueAsPlanned: () {},
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('lb'), findsWidgets);
    expect(find.text('kg'), findsNothing);
    expect(find.text('37.5'), findsOneWidget);
    expect(find.text('45.0'), findsOneWidget);
  });

  testWidgets('renders kg unit when user is on metric', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FatigueAlertModal(
          alertData: _alert(suggestedWeight: 17.5, unit: 'kg'),
          currentWeight: 20.0,
          exerciseName: 'Squat',
          onAcceptSuggestion: () {},
          onContinueAsPlanned: () {},
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('kg'), findsWidgets);
    expect(find.text('lb'), findsNothing);
  });

  testWidgets('bodyweight branch shows rep target card, not weight diff', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FatigueAlertModal(
          alertData: _alert(suggestedWeight: null, unit: 'lb', repTarget: 8),
          currentWeight: 0.0,
          exerciseName: 'Pull-up',
          onAcceptSuggestion: () {},
          onContinueAsPlanned: () {},
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('SUGGESTED REP TARGET'), findsOneWidget);
    expect(find.text('8 reps'), findsOneWidget);
    expect(find.text('SUGGESTED ADJUSTMENT'), findsNothing);
  });
}
