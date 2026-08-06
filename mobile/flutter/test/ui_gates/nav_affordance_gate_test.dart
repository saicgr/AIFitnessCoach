// Navigation-affordance consistency gate.
//
// WHY: a screenshot audit of 862 images found NO app-wide convention for the
// full-screen "go back" control — ~35 routes use the circled glass capsule
// (`GlassBackButton`), ~36 use a bare system-default IconButton/Icon. The
// audit recommends standardising on the circled control. This gate makes
// that enforceable going forward by statically scanning `lib/screens/**` for
// any back-navigation icon (`Icons.arrow_back*` / `Icons.chevron_left*`)
// built some OTHER way than `GlassBackButton` — a raw
// `IconButton(icon: Icon(Icons.arrow_back))`, a bare `Icon(Icons.chevron_left)`
// wired to a `GestureDetector`/`InkWell`, or a bespoke button widget handed
// the icon literal directly (`_TopBarButton(icon: Icons.arrow_back_rounded)`).
//
// The scan/classification logic lives in `nav_affordance_scan.dart` (no
// `flutter_test` dependency) so it can also run standalone via
// `dart run test/ui_gates/nav_affordance_scan.dart` to regenerate the
// baseline — see that file's doc comment for the full detection rules,
// exemptions (tab roots, dialogs), and worked false-positive examples
// (calendar/pager prev-next chevrons) this gate deliberately does NOT flag.
//
// BASELINE-STYLE: the app is currently split ~50/50 between the two
// conventions, so a gate that failed on all 36 existing deviants would be
// useless on day one — nobody could land an unrelated change without first
// fixing an unrelated screen. `nav_affordance_baseline.json` grandfathers the
// current backlog (keyed by file + rule + matched wrapper source, NOT line
// number, so it survives unrelated edits); this test fails ONLY on findings
// absent from that baseline, i.e. NEW deviations. To fix a grandfathered
// screen: convert it to `GlassBackButton`, then shrink the baseline with:
//   dart run test/ui_gates/nav_affordance_scan.dart \
//     > test/ui_gates/nav_affordance_baseline.json
// (the `--refresh` path — this repo's Dart tests don't take CLI flags, so the
// standalone `dart run` entry point in nav_affordance_scan.dart IS the
// refresh command). Never hand-edit the JSON to silence a fresh violation.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'nav_affordance_scan.dart';

const _baselinePath = 'test/ui_gates/nav_affordance_baseline.json';

void main() {
  group('nav affordance gate — real tree vs. baseline', () {
    test('no NEW back-affordance deviations beyond the checked-in baseline', () {
      final baselineFile = File(_baselinePath);
      expect(
        baselineFile.existsSync(),
        isTrue,
        reason: 'Missing $_baselinePath. Generate it once with:\n'
            '  dart run test/ui_gates/nav_affordance_scan.dart > $_baselinePath',
      );

      final current = scanNavAffordanceViolations();
      final baselineCounts = loadBaselineCounts(baselineFile);
      final diff = diffAgainstBaseline(current, baselineCounts);

      if (diff.newFindings.isNotEmpty) {
        final lines = diff.newFindings.map((f) => '  $f').join('\n');
        fail(
          '${diff.newFindings.length} NEW nav-affordance deviation(s) — a '
          'screen under lib/screens/** builds a back-navigation icon '
          '(arrow_back*/chevron_left*) some way OTHER than GlassBackButton:\n'
          '$lines\n\n'
          'Fix: replace the raw IconButton/Icon+GestureDetector with '
          '`GlassBackButton(onTap: ...)` (see lib/widgets/glass_back_button.dart).\n'
          'If this finding is a pre-existing screen you are not touching, do '
          'not silence it here — that defeats the gate. If you just fixed a '
          'baseline entry, shrink the baseline:\n'
          '  dart run test/ui_gates/nav_affordance_scan.dart > $_baselinePath\n'
          '\n${diff.grandfathered} pre-existing finding(s) grandfathered.',
        );
      }

      // Informational only — a shrinking baseline (fixes landed) never fails
      // the gate; it just means --refresh is due.
      if (diff.staleBaselineEntries > 0) {
        // ignore: avoid_print
        print('nav_affordance_gate: ${diff.staleBaselineEntries} baseline '
            'entry/entries no longer present in the tree — run the refresh '
            'command above to shrink $_baselinePath.');
      } else {
        // ignore: avoid_print
        print('nav_affordance_gate: clean '
            '(${diff.grandfathered} known finding(s) grandfathered).');
      }
    });

    test('baseline file is valid JSON matching the current scan shape', () {
      final decoded =
          jsonDecode(File(_baselinePath).readAsStringSync()) as Map<String, dynamic>;
      expect(decoded['findings'], isA<List>());
      final findings = (decoded['findings'] as List).cast<Map<String, dynamic>>();
      expect(decoded['total'], findings.fold<int>(0, (a, e) => a + (e['count'] as int)));
      for (final e in findings) {
        expect(e['rule'], anyOf('raw-icon-button', 'bare-icon-tap'));
        expect(e['file'], startsWith('lib/screens/'));
      }
    });

    test('tab-root exemption list still points at real, existing files', () {
      for (final path in kTabRootFiles) {
        expect(
          File(path).existsSync(),
          isTrue,
          reason: '$path no longer exists — the tab-root exemption list in '
              'nav_affordance_scan.dart is stale (screen moved/renamed?).',
        );
      }
      expect(kTabRootFiles, hasLength(5), reason: 'Bottom nav has 5 tabs — '
          'Home · Workout · Coach · Nutrition · You.');
    });
  });

  // ─────────────────────── detector unit checks ───────────────────────
  //
  // Regression coverage for the classification RULES themselves (independent
  // of whatever the real tree currently contains), fed directly through
  // `scanSource` on synthetic source strings. These are what make "prove the
  // gate can fail" durable rather than a one-off manual check.
  group('detector unit checks (scanSource on synthetic fixtures)', () {
    test('flags a raw IconButton(icon: Icon(Icons.arrow_back)) that pops', () {
      const src = '''
class FooScreen extends StatelessWidget {
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }
}
''';
      final findings = scanSource(src, 'lib/screens/foo/foo_screen.dart');
      expect(findings, hasLength(1));
      expect(findings.single.rule, 'raw-icon-button');
    });

    test('flags a bare Icon(Icons.chevron_left) wired to a GestureDetector that pops', () {
      const src = '''
class FooScreen extends StatelessWidget {
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.pop(),
      child: Icon(Icons.chevron_left),
    );
  }
}
''';
      final findings = scanSource(src, 'lib/screens/foo/foo_screen.dart');
      expect(findings, hasLength(1));
      expect(findings.single.rule, 'bare-icon-tap');
    });

    test('flags a bespoke widget handed the icon literal directly (Rule D)', () {
      const src = '''
class FooTopBar extends StatelessWidget {
  Widget build(BuildContext context) {
    return _TopBarButton(
      icon: Icons.arrow_back_rounded,
      onTap: onBack,
    );
  }
}
''';
      final findings = scanSource(src, 'lib/screens/foo/foo_top_bar.dart');
      expect(findings, hasLength(1));
      expect(findings.single.rule, 'raw-icon-button');
    });

    test('does NOT flag GlassBackButton — the canonical widget', () {
      const src = '''
class FooScreen extends StatelessWidget {
  Widget build(BuildContext context) {
    return GlassBackButton(onTap: () => context.pop());
  }
}
''';
      expect(scanSource(src, 'lib/screens/foo/foo_screen.dart'), isEmpty);
    });

    test('does NOT flag a GlassBackButton with a custom overridden icon', () {
      const src = '''
Widget build(BuildContext context) {
  return GlassBackButton(
    icon: Icons.arrow_back_rounded,
    onTap: () => context.pop(),
  );
}
''';
      expect(scanSource(src, 'lib/screens/foo/foo_screen.dart'), isEmpty);
    });

    test('does NOT flag an icon inside an AlertDialog — dialogs use text buttons', () {
      const src = '''
void _confirm(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Row(children: [
        IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(ctx).pop(),
        ),
      ]),
      actions: [TextButton(onPressed: () {}, child: Text('OK'))],
    ),
  );
}
''';
      expect(scanSource(src, 'lib/screens/foo/foo_screen.dart'), isEmpty);
    });

    test('does NOT flag a calendar/pager chevron_left (no pop signal + pagination words)', () {
      const src = '''
Widget _yearRow() {
  return IconButton(
    onPressed: _canPrevYear ? () => setState(() => _year -= 1) : null,
    icon: const Icon(Icons.chevron_left),
  );
}
''';
      expect(scanSource(src, 'lib/screens/foo/foo_calendar.dart'), isEmpty);
    });

    test('does NOT flag chevron_left with no pop/back signal at all (ambiguous, no evidence)', () {
      const src = '''
Widget _row() {
  return GestureDetector(
    onTap: () => _doSomethingUnrelated(),
    child: Icon(Icons.chevron_left),
  );
}
''';
      expect(scanSource(src, 'lib/screens/foo/foo_screen.dart'), isEmpty);
    });

    test('DOES flag chevron_left when it pops and has no pagination words', () {
      const src = '''
Widget _row(BuildContext context) {
  return GestureDetector(
    onTap: () => Navigator.of(context).pop(),
    child: Icon(Icons.chevron_left_rounded),
  );
}
''';
      final findings = scanSource(src, 'lib/screens/foo/foo_screen.dart');
      expect(findings, hasLength(1));
    });
  });

  // ─────────────────────── "prove it can fail" self-test ───────────────────────
  //
  // End-to-end proof of the ACTUAL gate mechanism (real filesystem scan +
  // baseline diff), not just the unit-level `scanSource` checks above: writes
  // a fabricated `lib/screens/...` file with a deliberate violation into a
  // throwaway OS temp directory (never touches the real repo tree), runs
  // `scanNavAffordanceViolations` against that root, confirms the violation
  // is found and that diffing it against an EMPTY baseline reports it as
  // NEW (i.e. this is exactly what would fail `nav_affordance_gate_test`'s
  // main assertion above), then tears the temp directory down.
  group('detector self-test against a scratch fixture tree', () {
    late Directory tempRoot;

    setUp(() {
      tempRoot = Directory.systemTemp.createTempSync('nav_affordance_gate_selftest_');
    });

    tearDown(() {
      if (tempRoot.existsSync()) tempRoot.deleteSync(recursive: true);
    });

    test('a fabricated raw back IconButton IS caught and reported as NEW', () {
      final screensDir = Directory('${tempRoot.path}/lib/screens/fixture');
      screensDir.createSync(recursive: true);
      File('${screensDir.path}/fixture_screen.dart').writeAsStringSync('''
class FixtureScreen extends StatelessWidget {
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}
''');

      final found = scanNavAffordanceViolations(root: '${tempRoot.path}/lib/screens');
      expect(found, hasLength(1),
          reason: 'The scanner failed to catch a deliberately-injected raw '
              'IconButton(icon: Icon(Icons.arrow_back_rounded)) — the gate '
              'cannot protect anything if this fails.');
      expect(found.single.rule, 'raw-icon-button');

      // Diffing against an EMPTY baseline is exactly what
      // nav_affordance_gate_test's main test does against the real
      // baseline — confirm it comes back NEW (i.e. would fail the gate).
      final diff = diffAgainstBaseline(found, const {});
      expect(diff.newFindings, hasLength(1));
    });

    test('the SAME fixture screen swapped to GlassBackButton is clean', () {
      final screensDir = Directory('${tempRoot.path}/lib/screens/fixture');
      screensDir.createSync(recursive: true);
      File('${screensDir.path}/fixture_screen.dart').writeAsStringSync('''
class FixtureScreen extends StatelessWidget {
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 16,
            left: 16,
            child: GlassBackButton(onTap: () => Navigator.of(context).pop()),
          ),
        ],
      ),
    );
  }
}
''');

      final found = scanNavAffordanceViolations(root: '${tempRoot.path}/lib/screens');
      expect(found, isEmpty,
          reason: 'GlassBackButton is the canonical widget and must never '
              'be flagged.');
    });
  });
}
