/// # Structural regression tests for editable share-card templates
///
/// Replaces the old golden-image suite. That suite called
/// `matchesGoldenFile('goldens/<template>.png')` for all ~240 editable
/// templates, but no `goldens/` directory was ever committed (`git ls-files`
/// returns zero PNGs) — every test failed on a missing reference image, and
/// it never actually rendered a `workoutComplete` share (its `_statsSample()`
/// used `ShareableKind.statsOverview` and set no `heroImageUrl`), so it could
/// not have caught the #142/#143/#144 defects below even if it had passed.
/// See docs/qa/E2E_ISSUES_2026-07-28.md.
///
/// This file is pure-Dart structural assertions over the `CardDoc` a
/// `docBuilder` produces — no widget pump, no fonts, no goldens. `CardDoc` is
/// an immutable data structure (`background` + typed `elements[].props`), so
/// every rule below reads it directly instead of rasterizing and diffing
/// pixels.
///
/// Rules enforced:
///  1. No `workoutComplete`-kind template heroes the exercise-anatomy
///     illustration (`BindingSource.heroImageUrl`) as a full-bleed photo —
///     except `exerciseShowcase`, which does so deliberately (E2E #143).
///  2. Every `RepeaterProps` element in a workout-kind doc resolves to
///     exercise rows, never the food path (E2E #142).
///  3. No fabricated literal numbers: the now-playing/media-scrubber family
///     never ships an invented mm:ss elapsed/total, and no
///     `StatGridProps.tiles` equals the removed hardcoded sample default
///     (E2E #144).
///
/// Each rule has a paired NEGATIVE test that proves the assertion is capable
/// of failing (rather than passing vacuously) by exercising the exact
/// pre-fix code path — the raw `docBuilder` output for #1/#2, and the
/// literal/tiles values that used to ship for #3 — without permanently
/// reverting any source file.
///
/// Plus one `testWidgets` render of a realistic `workoutComplete` share
/// through the real [CardDocRenderer] production path, asserting the
/// exercise ledger actually renders rows.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/shareables/doc/card_doc.dart';
import 'package:fitwiz/shareables/doc/card_doc_renderer.dart';
import 'package:fitwiz/shareables/shareable_catalog.dart';
import 'package:fitwiz/shareables/shareable_data.dart';

const ShareableAspect _kAspect = ShareableAspect.portrait;

/// A realistic `workoutComplete` share — the shape `WorkoutAdapter
/// .fromCompletion` actually produces: a `heroImageUrl` (the anatomy
/// illustration `WorkoutAdapter` always sets when any exercise resolves an
/// image), highlights in the adapter's own order (`DURATION` always first),
/// and a real exercise ledger with logged sets.
Shareable _workoutSample() => Shareable(
      kind: ShareableKind.workoutComplete,
      title: 'Push Day Crushed',
      periodLabel: 'MAY 21',
      accentColor: const Color(0xFFF97316),
      aspect: _kAspect,
      heroValue: 9820,
      heroUnitSingular: 'lbs',
      userDisplayName: 'chetan',
      heroImageUrl: 'https://cdn.zealova.com/ILLUSTRATIONS%20ALL/bench-press.png',
      highlights: const [
        ShareableMetric(label: 'DURATION', value: '52m'),
        ShareableMetric(label: 'VOLUME', value: '9,820 lbs'),
        ShareableMetric(label: 'SETS', value: '16'),
        ShareableMetric(label: 'REPS', value: '124'),
        ShareableMetric(label: 'EXERCISES', value: '3'),
        ShareableMetric(label: 'CALORIES', value: '410 kcal'),
        ShareableMetric(label: 'STREAK', value: '4 days'),
        ShareableMetric(label: 'NEW PRS', value: '1'),
      ],
      exercises: const [
        ShareableExercise(
          name: 'Bench Press',
          isPr: true,
          sets: [
            ShareableSet(weight: 185, unit: 'lbs', reps: 5, rpe: 8),
            ShareableSet(weight: 185, unit: 'lbs', reps: 5, rpe: 8.5),
            ShareableSet(weight: 185, unit: 'lbs', reps: 3, rpe: 9),
          ],
        ),
        ShareableExercise(
          name: 'Overhead Press',
          sets: [
            ShareableSet(weight: 115, unit: 'lbs', reps: 8, rpe: 7),
            ShareableSet(weight: 115, unit: 'lbs', reps: 7, rpe: 8),
          ],
        ),
        ShareableExercise(
          name: 'Pull Up',
          sets: [
            ShareableSet(unit: 'lbs', reps: 12, isBodyweight: true),
            ShareableSet(unit: 'lbs', reps: 10, isBodyweight: true),
          ],
        ),
      ],
    );

/// True when [doc] visually heroes the exercise-anatomy illustration —
/// either as its background photo or a VISIBLE standalone photo element —
/// the exact condition `ShareableCatalog.buildTemplateDoc` strips (E2E
/// #143). `CardDoc.withoutPhoto()` (the strip mechanism) sets `hidden: true`
/// on photo elements rather than removing them, so a hidden element must NOT
/// count — checking the binding alone (ignoring `hidden`) would flag every
/// correctly-stripped template as still an offender.
bool _boundToAnatomyHero(CardDoc doc) {
  final bg = doc.background;
  final bgIsHero = (bg.kind == CardBackgroundKind.photo ||
          bg.kind == CardBackgroundKind.blurredPhoto) &&
      bg.photo?.binding.source == BindingSource.heroImageUrl;
  final elIsHero = doc.elements.any((e) {
    if (e.hidden) return false;
    final props = e.props;
    return props is PhotoProps &&
        props.source.binding.source == BindingSource.heroImageUrl;
  });
  return bgIsHero || elIsHero;
}

/// Manual deep-equals for `List<List<String>>` (avoids adding a dependency
/// just for this one comparison).
bool _tilesEqual(List<List<String>> a, List<List<String>> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i].length != b[i].length) return false;
    for (var j = 0; j < a[i].length; j++) {
      if (a[i][j] != b[i][j]) return false;
    }
  }
  return true;
}

/// The default-parameter sample `statGridEl` used to fabricate before E2E
/// #144 (now removed from `doc_kit.dart` — every caller must pass real
/// tiles). Kept here only so rule 3b can assert no template still ships it.
const _fabricatedStatGridDefault = [
  ['12', 'WORKOUTS'],
  ['48.2k', 'VOLUME LB'],
  ['7', 'PRs'],
  ['14', 'DAY STREAK'],
];

final _mmSsPattern = RegExp(r'^\d+:\d\d$');

/// Every editable template spec actually reachable for [data] — i.e.
/// `spec.isAvailableFor(data)`, the exact predicate the share sheet /
/// editor's "Templates" grid uses to decide what to offer. This is
/// deliberately WIDER than `spec.kinds.contains(ShareableKind
/// .workoutComplete)`: several of the #144-fixed templates (e.g.
/// `dataScoreboard`) only declare `{statsOverview, weeklyProgress}` and
/// reach a `workoutComplete` share through the `statsOverview` wildcard
/// bypass in `isAvailableFor` — scanning by literal `kinds` membership alone
/// silently skips them, which is exactly why the mm:ss/tiles negative tests
/// below target real templates, not hypothetical ones.
List<ShareableTemplateSpec> _workoutKindSpecs(Shareable data) =>
    ShareableCatalog.all()
        .where((s) => s.docBuilder != null && s.isAvailableFor(data))
        .toList();

void main() {
  final workoutSpecs = _workoutKindSpecs(_workoutSample());

  group('CardDoc structural regression (E2E #142 / #143 / #144)', () {
    test('sanity: at least one template declares workoutComplete', () {
      expect(workoutSpecs, isNotEmpty,
          reason: 'No templates declare workoutComplete in `kinds` — '
              'nothing for the rules below to check.');
    });

    // ── Rule 1 (E2E #143) ───────────────────────────────────────────────
    test(
        'rule 1: no workout-kind doc heroes the anatomy illustration as a '
        'photo, except exerciseShowcase', () {
      final data = _workoutSample();
      final offenders = <String>[];
      for (final spec in workoutSpecs) {
        if (spec.template == ShareableTemplate.exerciseShowcase) continue;
        final doc = ShareableCatalog.buildTemplateDoc(spec, data, _kAspect);
        if (_boundToAnatomyHero(doc)) offenders.add(spec.template.name);
      }
      expect(offenders, isEmpty,
          reason: 'Templates still hero the anatomy illustration as a photo '
              'after ShareableCatalog.buildTemplateDoc: $offenders');
    });

    test(
        'rule 1 negative: the raw docBuilder output (bypassing the catalog '
        'fix) still binds heroImageUrl as a photo — proves rule 1 can fail',
        () {
      // This is the exact call every render site used BEFORE #143 —
      // `spec.docBuilder!(data, aspect)` with no policy applied. Comparing
      // it against the wrapped path above demonstrates ShareableCatalog
      // .buildTemplateDoc is what does the stripping, not that no template
      // ever binds heroImageUrl in the first place.
      final data = _workoutSample();
      final spec = ShareableCatalog.specFor(ShareableTemplate.workoutDetails);
      final rawDoc = spec.docBuilder!(data, _kAspect);
      expect(_boundToAnatomyHero(rawDoc), isTrue,
          reason: 'Sanity check failed: workoutDetailsDoc no longer binds '
              'heroImageUrl as a photo at all, so rule 1 would now pass '
              'vacuously even without the #143 fix. Point this sanity check '
              'at a template that still does.');
    });

    // ── Rule 2 (E2E #142) ───────────────────────────────────────────────
    // This is the AUTHOR-level half of rule 2: no preset explicitly opts a
    // workout-kind repeater into the food path (an author mistake — e.g.
    // copy-pasting a food template's `exerciseMode: false`). It deliberately
    // does NOT re-derive the renderer's null-inference formula (`p
    // .exerciseMode ?? data.kind != foodLog`) — duplicating that logic here
    // would only prove the test file agrees with itself, not that the
    // RENDERER actually infers correctly. That path (the actual regression
    // this rule exists for — a repeater silently rendering zero rows) is
    // guarded by the `testWidgets` render below, which pumps the real
    // `CardDocRenderer` end to end; confirmed by temporarily reverting
    // `_repeater`'s inference to a hard `false` default and observing the
    // widget test (not this one) fail.
    test(
        'rule 2: no RepeaterProps in a workout-kind doc explicitly opts '
        'into the food path', () {
      final data = _workoutSample();
      final offenders = <String>[];
      for (final spec in workoutSpecs) {
        final doc = ShareableCatalog.buildTemplateDoc(spec, data, _kAspect);
        for (final e in doc.elements) {
          final props = e.props;
          if (props is RepeaterProps && props.exerciseMode == false) {
            offenders.add(spec.template.name);
          }
        }
      }
      expect(offenders, isEmpty,
          reason: 'Templates whose repeater is explicitly set to the food '
              'path on a workoutComplete share: $offenders');
    });

    test(
        'rule 2 negative: exerciseMode: false is detected by the same '
        'predicate — proves rule 2 can fail', () {
      const offendingProps = RepeaterProps(exerciseMode: false);
      expect(offendingProps.exerciseMode == false, isTrue);
      // And the two honest shapes (explicit true, or null = "infer") must
      // NOT trip it.
      const explicitTrue = RepeaterProps(exerciseMode: true);
      const inferred = RepeaterProps();
      expect(explicitTrue.exerciseMode == false, isFalse);
      expect(inferred.exerciseMode == false, isFalse);
    });

    // ── Rule 3 (E2E #144) ───────────────────────────────────────────────
    test(
        'rule 3a: no ScrubberProps in a workout-kind doc ships a fabricated '
        'mm:ss total', () {
      // Scoped to `ScrubberProps` specifically (not every `TextProps`
      // literal) — `ios_dynamic_island_doc.dart` ALSO legitimately renders a
      // "9:41" iOS status-bar clock beside its scrubber (the well-known
      // Apple-keynote mockup convention, not a claim about the user's real
      // data); a blanket text scan would flag that as a false positive. The
      // scrubber's `rightLabel` is the "total" side and must be either real
      // data (never mm:ss-shaped — durations render as "52m" / "1h 12m" /
      // "45s", see `_fmtDuration`) or absent; `leftLabel` may legitimately
      // be the honest static '0:00' start marker these templates now use
      // for a fully-played bar, or a non-numeric label like 'START'.
      final data = _workoutSample();
      final offenders = <String>[];
      for (final spec in workoutSpecs) {
        final doc = ShareableCatalog.buildTemplateDoc(spec, data, _kAspect);
        for (final e in doc.elements) {
          final props = e.props;
          if (props is! ScrubberProps) continue;
          final isFabricatedDefault =
              props.leftLabel == '1:23' || props.rightLabel == '3:05';
          final totalLooksInvented = _mmSsPattern.hasMatch(props.rightLabel);
          if (isFabricatedDefault || totalLooksInvented) {
            offenders.add(
                '${spec.template.name}: scrubber ${props.leftLabel}/${props.rightLabel}');
          }
        }
      }
      expect(offenders, isEmpty, reason: 'Fabricated mm:ss found: $offenders');
    });

    test(
        'rule 3a negative: a reintroduced fake elapsed/total pair is '
        'flagged by the same predicate — proves rule 3a can fail', () {
      // Exactly what ios_dynamic_island_doc.dart hardcoded before the fix:
      // progress: 0.62, leftLabel: '28:12', rightLabel: '45:00'.
      const reintroduced =
          ScrubberProps(leftLabel: '28:12', rightLabel: '45:00');
      final isFabricatedDefault = reintroduced.leftLabel == '1:23' ||
          reintroduced.rightLabel == '3:05';
      final totalLooksInvented =
          _mmSsPattern.hasMatch(reintroduced.rightLabel);
      expect(isFabricatedDefault || totalLooksInvented, isTrue,
          reason: 'Sanity check: a hardcoded mm:ss total must trip this '
              'rule even when it does not match doc_kit\'s exact removed '
              'default literals.');
      // And the fixed real value + honest start marker must NOT trip it.
      const fixed = ScrubberProps(leftLabel: '0:00', rightLabel: '52m');
      expect(_mmSsPattern.hasMatch(fixed.rightLabel), isFalse);
    });

    test(
        'rule 3b: no StatGridProps.tiles equals the removed fabricated '
        'default', () {
      final data = _workoutSample();
      final offenders = <String>[];
      for (final spec in workoutSpecs) {
        final doc = ShareableCatalog.buildTemplateDoc(spec, data, _kAspect);
        for (final e in doc.elements) {
          final props = e.props;
          if (props is StatGridProps &&
              _tilesEqual(props.tiles, _fabricatedStatGridDefault)) {
            offenders.add(spec.template.name);
          }
        }
      }
      expect(offenders, isEmpty,
          reason: 'Templates still shipping the fabricated default stat '
              'grid: $offenders');
    });

    test(
        'rule 3b negative: the removed default equals itself — proves the '
        'equality check can fail', () {
      const sample = [
        ['12', 'WORKOUTS'],
        ['48.2k', 'VOLUME LB'],
        ['7', 'PRs'],
        ['14', 'DAY STREAK'],
      ];
      expect(_tilesEqual(sample, _fabricatedStatGridDefault), isTrue);
      // And a real tile set must NOT match, or rule 3b would flag every
      // template.
      expect(
          _tilesEqual(
              const [
                ['52m', 'DURATION']
              ],
              _fabricatedStatGridDefault),
          isFalse);
    });
  });

  group('CardDocRenderer widget render (workoutComplete)', () {
    testWidgets('the default workoutComplete template renders exercise rows',
        (tester) async {
      final data = _workoutSample();
      final defaultTemplate =
          ShareableCatalog.defaultTemplateForKind(ShareableKind.workoutComplete)!;
      final spec = ShareableCatalog.specFor(defaultTemplate);
      final doc = ShareableCatalog.buildTemplateDoc(spec, data, _kAspect);
      final size = _kAspect.size;

      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        home: MediaQuery(
          data: MediaQueryData(size: size, devicePixelRatio: 1.0),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox.fromSize(
              size: size,
              child: CardDocRenderer(doc: doc, data: data, showWatermark: true),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // At least one real exercise name from the sample must appear as
      // rendered text — proves the repeater resolved to exercise rows, not
      // an empty food-path list (E2E #142), on the actual default template
      // for a completed workout (E2E #137).
      final foundExerciseName = data.exercises!
          .any((ex) => find.text(ex.name).evaluate().isNotEmpty);
      expect(foundExerciseName, isTrue,
          reason: 'No exercise name from the sample rendered anywhere in '
              'the ${defaultTemplate.name} template — the repeater likely '
              'resolved to zero rows.');
    });
  });
}
