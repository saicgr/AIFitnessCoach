// Regression test for the "Duplicate GlobalKey detected" / "A
// RenderRepaintBoundary was mutated in RenderSliverList.performLayout" crash
// in the customize-rings sheet.
//
// The sheet renders the visible rings in a ReorderableListView keyed by
// `ring_${kind.id}`. If `ringVisibilityProvider` ever emits the same RingKind
// twice (a legacy/corrupt persisted blob repeating an id), two rows share a
// key and Flutter hard-crashes while reparenting the colliding GlobalKey
// mid-layout. `RingVisibilityNotifier` must therefore guarantee a duplicate
// kind can never reach the UI — and should self-heal the corrupt blob on disk.
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitwiz/core/providers/auth_provider.dart';
import 'package:fitwiz/screens/home/widgets/ring_catalog.dart';

/// Pumps microtasks until [test] passes or [tries] is exhausted, so the async
/// `_load()` kicked off in the notifier ctor has time to resolve.
Future<List<RingKind>> _settled(
  ProviderContainer c, {
  required bool Function(List<RingKind>) test,
  int tries = 40,
}) async {
  for (var i = 0; i < tries; i++) {
    final v = c.read(ringVisibilityProvider);
    if (test(v)) return v;
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  return c.read(ringVisibilityProvider);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer makeContainer() {
    final c = ProviderContainer(
      overrides: [
        // Anonymous → notifier uses the `home_ring_order_anon` storage key.
        currentUserIdProvider.overrideWithValue(null),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  group('RingVisibilityNotifier dedup', () {
    test('a persisted order with duplicate ids loads without duplicates',
        () async {
      // hydration + recovery each persisted twice (the crash trigger). The
      // autoenable flag is pre-set so _load never touches healthSyncProvider.
      SharedPreferences.setMockInitialValues({
        'home_ring_order_anon': jsonEncode([
          'train', 'nourish', 'move', 'sleep',
          'hydration', 'hydration', 'recovery', 'recovery',
        ]),
        'home_rings_wearable_autoenable_v1': true,
      });

      final c = makeContainer();
      final state = await _settled(c, test: (v) => v.contains(RingKind.recovery));

      // No duplicates — the invariant the keyed ReorderableListView relies on.
      expect(state.length, state.toSet().length,
          reason: 'visible rings must be unique: $state');
      expect(state.where((k) => k == RingKind.hydration).length, 1);
      expect(state.where((k) => k == RingKind.recovery).length, 1);
      // First-occurrence order is preserved.
      expect(state, [
        RingKind.train,
        RingKind.nourish,
        RingKind.move,
        RingKind.sleep,
        RingKind.hydration,
        RingKind.recovery,
      ]);
    });

    test('the corrupt blob is healed on disk after load', () async {
      SharedPreferences.setMockInitialValues({
        'home_ring_order_anon': jsonEncode([
          'train', 'train', 'nourish', 'move', 'sleep',
        ]),
        'home_rings_wearable_autoenable_v1': true,
      });

      final c = makeContainer();
      await _settled(c, test: (v) => v.length >= 4);
      // Give the self-heal _persist() a beat to flush.
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final prefs = await SharedPreferences.getInstance();
      final healed =
          (jsonDecode(prefs.getString('home_ring_order_anon')!) as List)
              .cast<String>();
      expect(healed, healed.toSet().toList(),
          reason: 'persisted order must be deduped on disk: $healed');
      expect(healed, ['train', 'nourish', 'move', 'sleep']);
    });

    test('setOrder collapses duplicates passed by the reorder callback',
        () async {
      SharedPreferences.setMockInitialValues({
        'home_rings_wearable_autoenable_v1': true,
      });
      final c = makeContainer();
      await _settled(c, test: (v) => v.isNotEmpty);

      final notifier = c.read(ringVisibilityProvider.notifier);
      notifier.setOrder([
        RingKind.move,
        RingKind.move, // duplicate
        RingKind.train,
        RingKind.nourish,
        RingKind.sleep,
      ]);

      final state = c.read(ringVisibilityProvider);
      expect(state.length, state.toSet().length);
      expect(state.where((k) => k == RingKind.move).length, 1);
      // Core rings are all still present.
      expect(
        RingKindX.defaultOrder.every(state.contains),
        isTrue,
        reason: 'core rings must survive setOrder: $state',
      );
    });
  });
}
