// One Home, variable length.
//
// The metric grid spent five design rounds trying to make an empty tile look
// acceptable, because three unrelated situations were rendered identically:
// a real zero (0 steps at 6 AM), not-yet-today (watch hasn't synced), and
// no-source-ever (the user owns no watch). Only the third is unfixable by
// copy, and the fix is not to style it — it is to not mount the tile.
//
// These tests pin the rules that make that safe:
//
//   * a phone-native metric (steps) mounts on AUTHORISATION alone, so a
//     zero-history device still shows Steps reading a real 0. A pure
//     sample-count rule would fail it today and mount it tomorrow — the grid
//     growing under the user, which is the thing being prevented.
//   * a wearable-only metric (sleep, readiness) mounts only on EVIDENCE.
//   * the probe only ever ADDS. Google Health silently hid vitals and sleep
//     tiles in May 2026 and users reported it as data loss.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitwiz/data/providers/home_metric_tiles_provider.dart';
import 'package:fitwiz/data/providers/metric_capability_provider.dart';
import 'package:fitwiz/screens/home/widgets/ring_catalog.dart';

/// Pumps microtasks until [test] passes or [tries] is exhausted.
Future<void> _settle(bool Function() test, {int tries = 60}) async {
  for (var i = 0; i < tries; i++) {
    if (test()) return;
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('what a wearable-only metric is', () {
    test('sleep, HRV, readiness and resting HR need a worn device', () {
      for (final k in [
        RingKind.sleep,
        RingKind.hrv,
        RingKind.recovery,
        RingKind.heartRate,
        RingKind.stress,
      ]) {
        expect(metricNeedsWornDevice(k), isTrue, reason: '${k.id}');
      }
    });

    test('steps is PHONE-NATIVE and must not require a worn device', () {
      // The load-bearing case. If `move` were treated as wearable-only, a
      // brand-new phone (and every simulator) would fail the sample probe,
      // Steps would not mount on day one, and it would appear the next day —
      // the grid changing shape under the user.
      expect(metricNeedsWornDevice(RingKind.move), isFalse);
    });

    test('in-app metrics never depend on a device', () {
      for (final k in [RingKind.hydration, RingKind.weight, RingKind.train]) {
        expect(metricNeedsWornDevice(k), isFalse, reason: '${k.id}');
      }
    });
  });

  group('the capability set', () {
    test('starts unresolved, so the grid does not guess', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final cap = c.read(metricCapabilityProvider);
      expect(cap.resolved, isFalse);
      expect(cap.capable, isEmpty);
    });

    test('a manual add makes a kind capable — the user beats the probe', () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final notifier = c.read(metricCapabilityProvider.notifier);

      expect(c.read(metricCapabilityProvider).can(RingKind.sleep), isFalse);
      await notifier.markCapable(RingKind.sleep);
      expect(c.read(metricCapabilityProvider).can(RingKind.sleep), isTrue,
          reason: 'the user knows about a source the probe cannot see');
    });

    test('the resolved set survives a restart', () async {
      final c1 = ProviderContainer();
      await c1.read(metricCapabilityProvider.notifier).markCapable(RingKind.sleep);
      c1.dispose();

      // A fresh container = a fresh launch reading the same prefs.
      final c2 = ProviderContainer();
      addTearDown(c2.dispose);
      await _settle(() => c2.read(metricCapabilityProvider).can(RingKind.sleep));
      expect(c2.read(metricCapabilityProvider).can(RingKind.sleep), isTrue,
          reason: 'the grid shape must exist BEFORE the first render, not be '
              'rediscovered after it');
    });

    test('capability is never removed once granted', () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final notifier = c.read(metricCapabilityProvider.notifier);
      await notifier.markCapable(RingKind.sleep);
      await notifier.markCapable(RingKind.recovery);

      // A later probe that finds nothing (offline, permission hiccup, a watch
      // left uncharged for a month) must not unmount tiles the user reads.
      await notifier.probe(healthAuthorised: false);

      expect(c.read(metricCapabilityProvider).can(RingKind.sleep), isTrue);
      expect(c.read(metricCapabilityProvider).can(RingKind.recovery), isTrue);
    });
  });

  group('which tiles mount', () {
    /// The grid's projection, with the arrangement and capability supplied
    /// directly so the test does not need a Health store.
    List<HomeMetricTile> mounted({
      required List<HomeMetricTile> arrangement,
      required Set<RingKind> capable,
    }) {
      return arrangement.where((t) {
        if (t.id == kTodayScoreTileId) return true;
        final kind = RingKindX.fromId(t.id);
        if (kind == null) return true;
        return capable.contains(kind);
      }).toList();
    }

    test('an iPhone-only user gets no Sleep or Ready tile — not empty ones',
        () {
      final out = mounted(
        arrangement: kDefaultMetricTiles,
        // Authorised, phone-native only: no worn device ever produced a sample.
        capable: {RingKind.move, RingKind.hydration, RingKind.weight},
      );
      final ids = out.map((t) => t.id).toList();

      expect(ids, contains(kTodayScoreTileId));
      expect(ids, contains('move'));
      expect(ids, contains('hydration'));
      expect(ids, contains('weight'));
      expect(ids, isNot(contains('sleep')),
          reason: 'a tile that can never fill must not mount at all — this is '
              'the whole fix');
      expect(ids, isNot(contains('recovery')));
    });

    test('a user who skipped Health keeps the in-app tiles', () {
      final out = mounted(
        arrangement: kDefaultMetricTiles,
        capable: {RingKind.hydration, RingKind.weight},
      );
      final ids = out.map((t) => t.id).toList();
      expect(ids, contains(kTodayScoreTileId),
          reason: 'the score computes from in-app logs; it never needs Health');
      expect(ids, contains('hydration'));
      expect(ids, contains('weight'));
      expect(ids, isNot(contains('move')));
    });

    test('a fully-equipped user gets the whole default set', () {
      final out = mounted(
        arrangement: kDefaultMetricTiles,
        capable: {
          RingKind.move,
          RingKind.sleep,
          RingKind.recovery,
          RingKind.hydration,
          RingKind.weight,
        },
      );
      expect(out.length, kDefaultMetricTiles.length);
    });

    test('the arrangement is filtered, never rewritten', () {
      // The user put Sleep second. They have no watch today, so it does not
      // mount — but buying one must restore it to THEIR slot, which only works
      // if the stored arrangement was left alone.
      const arrangement = kDefaultMetricTiles;
      final withWatch = mounted(
        arrangement: arrangement,
        capable: {
          RingKind.move,
          RingKind.sleep,
          RingKind.recovery,
          RingKind.hydration,
          RingKind.weight,
        },
      );
      expect(
        withWatch.map((t) => t.id).toList(),
        arrangement.map((t) => t.id).toList(),
        reason: 'order preserved exactly — filtering is a read-time projection',
      );
    });
  });
}
