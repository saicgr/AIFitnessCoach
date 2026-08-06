// Card/spacing geometry consistency gate.
//
// Real defect: the Home metrics carousel (`metric_summary_deck.dart`) used
// `borderRadius: 14` / `padding: 13` while the cards directly above and
// below it on the same screen used `16` / `14` — off-by-one, off the app's
// grid, and read as "inconsistent" without being nameable. Nothing caught it
// because nothing compared a card's geometry to the rest of the app's.
//
// This gate statically scans every `.dart` file under `lib/screens/**` and
// `lib/widgets/**` for `BorderRadius.circular(N)` / `Radius.circular(N)`
// (radius) and `EdgeInsets.all(N)` (uniform "card-level" padding), builds a
// histogram per category, derives which values are the app's real
// conventions EMPIRICALLY (not from this file's author's opinion — see
// `card_geometry_scan.dart`'s doc comment for the exact rule and why), and
// flags any non-conventional value that sits suspiciously close (a "near
// miss") to one of those conventions.
//
// Baseline-style, like the other audit gates in this repo (see CLAUDE.md's
// `audit_timezone_usage.py --check` / `audit_supabase_column_drift.py
// --check`): the 317 near-misses already in the tree today are checked into
// `card_geometry_baseline.json` and do NOT fail this test. Only a NEW
// near-miss (one whose file+kind+exact-line isn't in the baseline) fails —
// so this gate stops the bleeding without demanding a same-night full fix of
// pre-existing drift, and the baseline file IS the work list for that
// follow-up cleanup pass.
//
// To accept a fix: re-run `dart run test/ui_gates/card_geometry_scan.dart`
// and copy its stdout over `card_geometry_baseline.json` (this shrinks the
// baseline — the fixed line's key stops appearing). To accept a genuinely
// new, deliberately-distinct value (not a fix, a real new addition): the
// same regeneration step naturally omits it if it either matches an existing
// established value or is far enough from every established value to not be
// a "near miss" in the first place. There is no manual whitelist to edit —
// the file always reflects "what the classifier currently flags", never
// "what someone decided to allow".
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'card_geometry_scan.dart';

/// Loads the checked-in baseline as the set of `GeometryMatch.baselineKey`s
/// it represents.
Set<String> _loadBaselineKeys() {
  final file = File('test/ui_gates/card_geometry_baseline.json');
  final raw = jsonDecode(file.readAsStringSync()) as List<dynamic>;
  return raw
      .map((e) => GeometryMatch.fromJson(e as Map<String, dynamic>))
      .map((m) => m.baselineKey)
      .toSet();
}

String _fmt(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();

/// Renders `value -> count` sorted by count desc, for the failure/report
/// output.
String _histogramReport(Map<double, int> hist, Set<double> established) {
  final entries = hist.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final buf = StringBuffer();
  for (final e in entries) {
    final tag = established.contains(e.key) ? ' [established]' : '';
    buf.writeln('    ${_fmt(e.key).padLeft(6)}  x${e.value}$tag');
  }
  return buf.toString();
}

void main() {
  group('Card geometry consistency gate', () {
    // ── Tolerance-rule sanity checks ──────────────────────────────────
    // These pin the classifier's behavior against the two failure modes the
    // task explicitly calls out, using REAL values from the current
    // histogram (not synthetic ones) so a change to the threshold/tolerance
    // constants that breaks either guarantee is caught here, not discovered
    // later as a false positive/negative in the real gate.
    test('known dominant/deliberately-distinct values are never flagged '
        '(999 pill radius, 4px chip radius, 32/36/40 distinct large radii)',
        () {
      final matches = scanDirs(defaultScanRoots);
      final radiusHist = histogramFor(matches, GeometryKind.radius);
      final established = establishedValues(radiusHist);

      // Sanity: these really are present and either established themselves
      // or far enough from any established anchor — if this ever goes
      // false, the fixture data changed enough that the assertion below is
      // no longer meaningful and needs a look, not a silent skip.
      expect(radiusHist.containsKey(999.0), isTrue,
          reason: 'expected the 999 pill-radius convention to still exist '
              'in lib/ — if this is gone, replace this sanity fixture');

      for (final v in [999.0, 4.0]) {
        expect(isNearMiss(v, established), isFalse,
            reason: '$v is one of the app\'s own established conventions '
                '(count=${radiusHist[v]}) and must never be flagged as a '
                'near-miss of some OTHER value');
      }
      // Distinct large radii that are a full grid-step (>=4px) away from
      // their nearest established neighbor — deliberately different, not
      // drift.
      for (final v in [32.0, 36.0, 40.0]) {
        expect(isNearMiss(v, established), isFalse,
            reason: '$v sits >= kNearMissTolerance from every established '
                'radius value and must be treated as a deliberate distinct '
                'choice, not a near-miss');
      }
    });

    test('a value one grid-step off an established anchor IS flagged '
        '(proves the rule has teeth, not just an allowlist of exclusions)',
        () {
      final matches = scanDirs(defaultScanRoots);
      final radiusHist = histogramFor(matches, GeometryKind.radius);
      final paddingHist = histogramFor(matches, GeometryKind.padding);
      final radiusEstablished = establishedValues(radiusHist);
      final paddingEstablished = establishedValues(paddingHist);
      // 13 is the exact shape of the reported defect (one off a 12/14
      // anchor) and is present today in both categories.
      expect(isNearMiss(13.0, radiusEstablished), isTrue);
      expect(isNearMiss(13.0, paddingEstablished), isTrue);
    });

    // ── The actual gate ────────────────────────────────────────────────
    test(
        'no NEW near-miss card geometry (BorderRadius/EdgeInsets.all) beyond '
        'the checked-in baseline', () {
      final matches = scanDirs(defaultScanRoots);
      expect(matches.length, greaterThan(5000),
          reason: 'Sanity check: found suspiciously few geometry literals '
              '(${matches.length}) — likely a regex or path regression in '
              'this gate itself, not a real drop in lib/.');

      final violations = nearMissViolations(matches);
      final baselineKeys = _loadBaselineKeys();

      final newViolations =
          violations.where((v) => !baselineKeys.contains(v.baselineKey)).toList()
            ..sort((a, b) {
              final byFile = a.file.compareTo(b.file);
              return byFile != 0 ? byFile : a.line.compareTo(b.line);
            });

      // Report the full histogram every run (not just on failure) — this is
      // the drift inventory the task asks for, independent of whether the
      // gate currently passes.
      final radiusHist = histogramFor(matches, GeometryKind.radius);
      final paddingHist = histogramFor(matches, GeometryKind.padding);
      final radiusEstablished = establishedValues(radiusHist);
      final paddingEstablished = establishedValues(paddingHist);
      // ignore: avoid_print
      print('── Card geometry histogram (lib/screens/** + lib/widgets/**) ──\n'
          '  BorderRadius.circular / Radius.circular '
          '(${matches.where((m) => m.kind == GeometryKind.radius).length} '
          'sites, established >= $kEstablishedMinCount uses):\n'
          '${_histogramReport(radiusHist, radiusEstablished)}'
          '  EdgeInsets.all '
          '(${matches.where((m) => m.kind == GeometryKind.padding).length} '
          'sites, established >= $kEstablishedMinCount uses):\n'
          '${_histogramReport(paddingHist, paddingEstablished)}'
          '  total near-miss violations: ${violations.length} '
          '(${baselineKeys.length} baselined, ${newViolations.length} new)');

      expect(
        newViolations,
        isEmpty,
        reason: newViolations.isEmpty
            ? null
            : 'Found ${newViolations.length} NEW card-geometry near-miss(es) '
                'not in the checked-in baseline '
                '(test/ui_gates/card_geometry_baseline.json):\n'
                '${newViolations.map((v) => '  ${v.file}:${v.line}  '
                    '${v.kind.name}=${_fmt(v.value)}  near '
                    '${_fmt(nearestEstablished(v.value, v.kind == GeometryKind.radius ? radiusEstablished : paddingEstablished))}'
                    '  ->  ${v.lineText}').join('\n')}\n'
                'If this is a deliberate new value, re-derive: does it match '
                'an existing established value, or sit >= $kNearMissTolerance '
                'away from every established value? If not, round it to the '
                'nearest established value instead of introducing new drift. '
                'If a cleanup pass fixed pre-existing entries, regenerate the '
                'baseline: `dart run test/ui_gates/card_geometry_scan.dart '
                '> test/ui_gates/card_geometry_baseline.json`.',
      );
    });

    // ── Prove the gate can fail ──────────────────────────────────────────
    test('self-test: the gate DOES fail on a genuinely new near-miss '
        '(scratch fixture, never touches lib/)', () {
      final tempDir = Directory.systemTemp.createTempSync('card_geometry_gate_selftest_');
      addTearDown(() {
        if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      });

      // A synthetic card mirroring the real defect: radius/padding one off
      // the grid. The exact VALUES (13) are real near-misses per the actual
      // repo histogram (see the "one grid-step off" test above); the FILE
      // PATH is synthetic and can never already be in the checked-in
      // baseline, so this is unambiguously a "new" violation regardless of
      // what already exists in lib/.
      final fixture = File('${tempDir.path}/scratch_card.dart');
      fixture.writeAsStringSync('''
class ScratchCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
      ),
    );
  }
}
''');

      // Classify the synthetic matches against the REAL app-wide established
      // sets (read-only scan of lib/ — same as the real gate uses), exactly
      // as the real gate would if this file lived under lib/widgets/.
      final realMatches = scanDirs(defaultScanRoots);
      final radiusEstablished =
          establishedValues(histogramFor(realMatches, GeometryKind.radius));
      final paddingEstablished =
          establishedValues(histogramFor(realMatches, GeometryKind.padding));

      final fixtureMatches = scanDirs([tempDir.path]);
      expect(fixtureMatches.length, 2,
          reason: 'fixture should produce exactly one radius + one padding match');

      final fixtureViolations = fixtureMatches.where((m) {
        final established =
            m.kind == GeometryKind.radius ? radiusEstablished : paddingEstablished;
        return isNearMiss(m.value, established);
      }).toList();

      // This is the assertion that PROVES the gate has teeth: both synthetic
      // sites are classified as violations, and — since the baseline JSON
      // can never contain this temp-dir file path — diffing them against
      // the real baseline would report them as NEW, i.e. the real gate test
      // above would fail loudly if this fixture lived under lib/.
      expect(fixtureViolations.length, 2,
          reason: 'Expected BOTH the radius=13 and padding=13 synthetic '
              'sites to be classified as near-miss violations. If this is '
              '0, the gate would silently accept the exact defect class it '
              'was built to catch — this is a red alert, not a passing '
              'test to relax.');

      final baselineKeys = _loadBaselineKeys();
      for (final v in fixtureViolations) {
        expect(baselineKeys.contains(v.baselineKey), isFalse,
            reason: 'a synthetic temp-dir file path must never collide with '
                'the checked-in baseline');
      }
    });
  });
}
