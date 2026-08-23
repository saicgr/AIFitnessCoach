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
import 'package:fitwiz/data/providers/metric_tile_data_provider.dart'
    show metricScoreSeenInWindowProvider;
import 'package:fitwiz/screens/home/widgets/home/metric_tile_grid.dart'
    show packMetricTileRows;
import 'package:fitwiz/screens/home/widgets/ring_catalog.dart';

/// A container for the capability notifier alone.
///
/// The score-visibility input is supplied rather than computed: reaching for
/// the live one would build the whole score graph, which needs a Supabase
/// session a unit test has no way to give it. Stating it here also makes each
/// test say which account it is describing — one that has never scored.
ProviderContainer _capabilityContainer({bool scoreSeen = false}) =>
    ProviderContainer(overrides: [
      metricScoreSeenInWindowProvider.overrideWithValue(scoreSeen),
    ]);

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
      final c = _capabilityContainer();
      addTearDown(c.dispose);
      final cap = c.read(metricCapabilityProvider);
      expect(cap.resolved, isFalse);
      expect(cap.capable, isEmpty);
    });

    test('a manual add makes a kind capable — the user beats the probe', () async {
      final c = _capabilityContainer();
      addTearDown(c.dispose);
      final notifier = c.read(metricCapabilityProvider.notifier);

      expect(c.read(metricCapabilityProvider).can(RingKind.sleep), isFalse);
      await notifier.markCapable(RingKind.sleep);
      expect(c.read(metricCapabilityProvider).can(RingKind.sleep), isTrue,
          reason: 'the user knows about a source the probe cannot see');
    });

    test('the resolved set survives a restart', () async {
      final c1 = _capabilityContainer();
      await c1.read(metricCapabilityProvider.notifier).markCapable(RingKind.sleep);
      c1.dispose();

      // A fresh container = a fresh launch reading the same prefs.
      final c2 = _capabilityContainer();
      addTearDown(c2.dispose);
      await _settle(() => c2.read(metricCapabilityProvider).can(RingKind.sleep));
      expect(c2.read(metricCapabilityProvider).can(RingKind.sleep), isTrue,
          reason: 'the grid shape must exist BEFORE the first render, not be '
              'rediscovered after it');
    });

    test('capability is never removed once granted', () async {
      final c = _capabilityContainer();
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
    /// The grid's projection, driven through the REAL predicate
    /// ([metricTileMountable]) with its inputs supplied, so the test cannot
    /// drift from production the way the previous hand-rolled copy did.
    ///
    /// [scoreEverScored] defaults to true because most cases here are about
    /// sensors; the score's own gate has its own group below.
    List<HomeMetricTile> mounted({
      required List<HomeMetricTile> arrangement,
      required Set<RingKind> capable,
      bool resolved = true,
      bool scoreEverScored = true,
      bool planHasData = true,
    }) {
      final capability =
          MetricCapability(capable: capable, resolved: resolved);
      return arrangement
          .where((t) => metricTileMountable(
                t.id,
                capability: capability,
                scoreEverScored: scoreEverScored,
                planHasData: planHasData,
              ))
          .toList();
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

    // ── The regression. ──────────────────────────────────────────────────
    //
    // This is the state the screenshot was taken in, and the state no test
    // covered: `probe()` had exactly one call site (onboarding), so every
    // account that finished onboarding before it existed sat at
    // `capable: {}, resolved: false` forever. The grid rendered ONE tile.
    test('a never-probed account still mounts every in-app metric', () {
      final out = mounted(
        arrangement: kDefaultMetricTiles,
        capable: const {}, // the probe never ran for this account
        resolved: false,
        scoreEverScored: true,
      );
      final ids = out.map((t) => t.id).toList();

      expect(ids, contains('hydration'),
          reason: 'water is logged by hand — it never needed a device, so an '
              'empty capability set cannot withhold it');
      expect(ids, contains('weight'));
      expect(ids, isNot(contains('sleep')),
          reason: 'unknown capability is still not a reason to mount a '
              'wearable-only metric');
    });

    test('capability gates devices only, never hand-logged metrics', () {
      for (final id in ['hydration', 'weight', 'protein', 'nourish', 'train']) {
        expect(
          metricTileMountable(id,
              capability: const MetricCapability(),
              scoreEverScored: true,
              planHasData: true),
          isTrue,
          reason: '$id needs no device and must mount regardless of capability',
        );
      }
    });
  });

  group('the first point is a one-way fact', () {
    test('is recorded, and survives a restart', () async {
      // A point lands while the app is open.
      final c1 = _capabilityContainer(scoreSeen: true);
      await _settle(() => c1.read(metricCapabilityProvider).scoreEverScored);
      expect(c1.read(metricCapabilityProvider).scoreEverScored, isTrue);
      c1.dispose();

      // Months later the 90-day history has rolled past it and today is a
      // real 0 — the tile must still be there. Inferring "ever scored" from
      // the retained history alone would silently unmount it.
      final c2 = _capabilityContainer(scoreSeen: false);
      addTearDown(c2.dispose);
      await _settle(() => c2.read(metricCapabilityProvider).scoreEverScored);
      expect(c2.read(metricCapabilityProvider).scoreEverScored, isTrue,
          reason: 'a tile someone has been reading never disappears');
    });

    test('copyWith cannot un-earn it', () {
      const earned = MetricCapability(scoreEverScored: true);
      expect(earned.copyWith(resolved: true).scoreEverScored, isTrue);
      expect(earned.copyWith(scoreEverScored: false).scoreEverScored, isTrue);
    });
  });

  group('the Today Score gate', () {
    test('does not mount for an account that has never scored', () {
      expect(
        metricTileMountable(kTodayScoreTileId,
            capability: const MetricCapability(),
            scoreEverScored: false,
            planHasData: true),
        isFalse,
        reason: 'a 56pt zero above a chart with one point is the "no source '
            'yet" case every other tile is spared',
      );
    });

    test('mounts forever once a point has ever been scored', () {
      // Day 300, 6 AM: today's score is a real 0 and the tile must still be
      // there. Hiding a tile someone reads daily is the data-loss failure.
      expect(
        metricTileMountable(kTodayScoreTileId,
            capability: const MetricCapability(),
            scoreEverScored: true,
            planHasData: true),
        isTrue,
      );
    });
  });

  group('plan-backed tiles', () {
    test('mount only when the field behind them exists', () {
      for (final id in kPlanTileIds) {
        expect(
          metricTileMountable(id,
              capability: const MetricCapability(),
              scoreEverScored: true,
              planHasData: false),
          isFalse,
          reason: '$id must not render "0 to go" for a user who set no target',
        );
        expect(
          metricTileMountable(id,
              capability: const MetricCapability(),
              scoreEverScored: true,
              planHasData: true),
          isTrue,
        );
      }
    });

    test('never depend on Health capability', () {
      // The whole point: these come from onboarding, so a user who skipped
      // Health entirely still gets all of them.
      for (final id in kPlanTileIds) {
        expect(
          metricTileMountable(id,
              capability: const MetricCapability(resolved: true),
              scoreEverScored: false,
              planHasData: true),
          isTrue,
          reason: '$id is plan-sourced; a Health grant is irrelevant to it',
        );
      }
    });
  });

  group('the account-shaped default', () {
    test('a Health-skipped account gets a full grid of plan tiles', () {
      final tiles = defaultMetricTilesFor(
        capabilityResolved: true,
        capable: const {RingKind.hydration, RingKind.weight},
      );
      final ids = tiles.map((t) => t.id).toList();

      // What the founder saw replaced: one tile reading 0.
      expect(ids, contains(kNextSessionTileId));
      expect(ids, contains(kToGoalTileId));
      expect(ids, contains(kThisWeekTileId));
      expect(ids, contains(kDailyFuelTileId));
      // The hand-logged tiles keep their slots — they were never the problem.
      expect(ids, contains('hydration'));
      expect(ids, contains('weight'));
      // And nothing sensor-backed is seeded for a phone with no sources.
      expect(ids, isNot(contains('move')));
      expect(ids, isNot(contains('sleep')));
      expect(ids, isNot(contains('recovery')));
    });

    test('substitutes keep the slot they took — same position, row-packed size',
        () {
      final tiles = defaultMetricTilesFor(
        capabilityResolved: true,
        capable: const {RingKind.hydration, RingKind.weight},
      );
      final ids = tiles.map((t) => t.id).toList();

      // Every substitute lands where the tile it replaced was, in order —
      // the hero's own substitute directly after it, then move's, sleep's,
      // recovery's, then the two hand-logged tiles that needed no
      // substitute.
      expect(
        ids,
        [
          kTodayScoreTileId,
          kNextSessionTileId,
          kToGoalTileId,
          kThisWeekTileId,
          kDailyFuelTileId,
          'hydration',
          'weight',
        ],
      );
      expect(tiles.every((t) => t.page == 1), isTrue,
          reason: 'nothing is ever auto-filled onto page 2');
    });

    test('the default grid is always 3 rows, never 4 — every capability set',
        () {
      // The Today Score's own substitute is a 7th tile added alongside 6
      // defaults, and a capability gap can substitute any of the other 5 —
      // so this must hold regardless of which ids end up in the remaining
      // slots, not just for one hand-picked capability set.
      for (final capable in <Set<RingKind>>[
        const {},
        const {RingKind.hydration, RingKind.weight},
        const {
          RingKind.move,
          RingKind.sleep,
          RingKind.recovery,
          RingKind.hydration,
          RingKind.weight,
        },
        {RingKind.move},
        {RingKind.sleep, RingKind.recovery},
      ]) {
        final tiles = defaultMetricTilesFor(
          capabilityResolved: true,
          capable: capable,
        );
        final rows = packMetricTileRows(tiles);
        expect(rows.length, lessThanOrEqualTo(3),
            reason: 'capable=$capable produced ${rows.length} rows: '
                '${tiles.map((t) => '${t.id}(${t.size.name})').toList()}');
      }
    });

    test('a fully-equipped account keeps every sensor tile it earned', () {
      final tiles = defaultMetricTilesFor(
        capabilityResolved: true,
        capable: const {
          RingKind.move,
          RingKind.sleep,
          RingKind.recovery,
          RingKind.hydration,
          RingKind.weight,
        },
      );
      final ids = tiles.map((t) => t.id).toList();
      for (final t in kDefaultMetricTiles) {
        expect(ids, contains(t.id),
            reason: 'a substitution must never displace a metric that CAN '
                'fill its slot');
      }
    });

    test('the Today Score keeps its slot rather than being substituted', () {
      final tiles = defaultMetricTilesFor(
        capabilityResolved: true,
        capable: const {RingKind.hydration, RingKind.weight},
      );
      expect(tiles.first.id, kTodayScoreTileId,
          reason: 'the score is not unfillable, only zero until the day '
              'starts — it stays in the arrangement so it can come back');
      expect(tiles[1].id, kNextSessionTileId,
          reason: 'and the tile that renders while it is hidden sits in its '
              'place, at its size');
    });

    test('no tile is ever seeded twice', () {
      final tiles = defaultMetricTilesFor(
        capabilityResolved: false,
        capable: const {},
      );
      final ids = tiles.map((t) => t.id).toList();
      expect(ids.toSet().length, ids.length);
    });
  });
}
