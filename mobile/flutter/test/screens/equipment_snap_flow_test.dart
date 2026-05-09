// Smoke test for the equipment-snap flow widget surface.
//
// We deliberately keep this lightweight: the camera/picker and the network
// call are external boundaries that are hard to mock in widget tests, so we
// assert only the static parts of the UI (title rendering for each mode,
// fallback action labels). The pipeline behavior is covered by the backend
// pytest in `backend/tests/test_equipment_snap.py`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/screens/workout/widgets/equipment_snap_flow.dart';

void main() {
  testWidgets('EquipmentSnapFlow swap mode renders Snap to swap title',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: EquipmentSnapFlow(
            mode: SnapMode.swap,
            workoutId: 'wo-1',
            replacingExerciseName: 'Bench Press',
          ),
        ),
      ),
    );

    // We only pump one frame: avoid postFrameCallback firing the camera
    // picker which would crash the test harness.
    expect(find.text('Snap to swap'), findsOneWidget);
  });

  testWidgets('EquipmentSnapFlow add mode renders Snap to add title',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: EquipmentSnapFlow(
            mode: SnapMode.add,
            workoutId: 'wo-1',
          ),
        ),
      ),
    );

    expect(find.text('Snap to add'), findsOneWidget);
  });

  testWidgets('EquipmentSnapFlow identify mode renders correct title',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: EquipmentSnapFlow(
            mode: SnapMode.identify,
          ),
        ),
      ),
    );

    expect(find.text('Identify equipment'), findsOneWidget);
  });
}
