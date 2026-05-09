// Widget tests for SnappedEquipmentSection.
//
// We override the StateNotifierProvider with a notifier constructed in
// `autoLoad: false` mode and seed its state via the test-only
// `debugSetState` seam. This avoids hitting the network without resorting
// to mocks for Dio or ApiClient.
//
// Coverage:
//  1. Empty state copy renders when items=[].
//  2. Populated state renders 3 cards with canonical names + badges.
//  3. Tapping a card invokes the caller's onSwapOrAdd with the top match.
//
// Note: tapping triggers `reuseSnap` which still calls the network. For the
// tap-callback test we override `apiClientProvider` so the dio call is
// short-circuited by the autoLoad=false notifier (which doesn't reuse).
// We instead exercise the public callback wiring by stubbing reuseSnap via
// a thin subclass that returns a fixture response.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/screens/workout/widgets/equipment_snap_flow.dart'
    show SnapMode;
import 'package:fitwiz/screens/workout/widgets/snapped_equipment_section.dart';

class _StubNotifier extends SnappedEquipmentNotifier {
  final Map<String, dynamic>? reuseResponse;
  _StubNotifier(super.ref, {this.reuseResponse}) : super(autoLoad: false);

  @override
  Future<Map<String, dynamic>?> reuseSnap({
    required SnappedEquipmentItem item,
    required SnapMode mode,
    String? workoutId,
    String? replacingExerciseId,
  }) async {
    return reuseResponse;
  }
}

SnappedEquipmentItem _fixture(String id, String canonical, {String? lastEx}) {
  return SnappedEquipmentItem(
    id: id,
    s3Key: 'snapped_equipment/u/$id.jpg',
    imageUrl: null,
    canonicalName: canonical,
    confidence: 0.9,
    visionLabel: 'gym_equipment',
    lastExerciseId: lastEx,
    createdVia: 'identify',
    classifiedAt: DateTime.utc(2026, 5, 8),
  );
}

Widget _wrap(Widget child, {required _StubNotifier Function(Ref) build}) {
  return ProviderScope(
    overrides: [
      snappedEquipmentProvider.overrideWith(build),
    ],
    child: MaterialApp(
      home: Scaffold(body: SizedBox(height: 600, child: child)),
    ),
  );
}

void main() {
  testWidgets('empty state shows the no-snaps copy', (tester) async {
    await tester.pumpWidget(_wrap(
      const SnappedEquipmentSection(mode: SnapMode.add),
      build: (ref) => _StubNotifier(ref),
    ));
    await tester.pump();

    expect(find.textContaining('No snapped equipment'), findsOneWidget);
    expect(find.textContaining('camera button'), findsOneWidget);
  });

  testWidgets('populated state renders all three fixtures', (tester) async {
    final items = [
      _fixture('a', 'cable_lat_pulldown', lastEx: 'ex-1'),
      _fixture('b', 'leg_press'),
      _fixture('c', 'rowing_machine', lastEx: 'ex-2'),
    ];

    late _StubNotifier notifier;
    await tester.pumpWidget(_wrap(
      const SnappedEquipmentSection(
          mode: SnapMode.swap, workoutId: 'wo-1'),
      build: (ref) {
        notifier = _StubNotifier(ref);
        return notifier;
      },
    ));
    notifier.debugSetState(SnappedEquipmentState(items: items));
    await tester.pump();

    expect(find.text('Cable lat pulldown'), findsOneWidget);
    expect(find.text('Leg press'), findsOneWidget);
    expect(find.text('Rowing machine'), findsOneWidget);
    expect(find.text('Last used recently'), findsNWidgets(2));
    expect(find.text('Equipment only'), findsOneWidget);
  });

  testWidgets('tapping a card invokes onSwapOrAdd with the top match',
      (tester) async {
    final items = [_fixture('a', 'cable_lat_pulldown')];

    late _StubNotifier notifier;
    Map<String, dynamic>? captured;

    await tester.pumpWidget(_wrap(
      SnappedEquipmentSection(
        mode: SnapMode.swap,
        workoutId: 'wo-1',
        onSwapOrAdd: (m) async {
          captured = m;
          return null;
        },
      ),
      build: (ref) {
        notifier = _StubNotifier(
          ref,
          reuseResponse: {
            'matched': true,
            'matches': [
              {'id': 'ex-99', 'name': 'Cable Lat Pulldown'},
              {'id': 'ex-100', 'name': 'Wide-Grip Lat Pulldown'},
            ],
          },
        );
        return notifier;
      },
    ));
    notifier.debugSetState(SnappedEquipmentState(items: items));
    await tester.pump();

    await tester.tap(find.byType(InkWell).first);
    // Pump for async reuseSnap + onSwapOrAdd.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(captured, isNotNull);
    expect(captured!['id'], 'ex-99');
    expect(captured!['name'], 'Cable Lat Pulldown');
  });
}
