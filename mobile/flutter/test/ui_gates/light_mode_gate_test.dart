// Hardcoded-dark-colour gate ("light mode gate").
//
// WHY: light mode is unreadable on many screens — black cards with near-black
// text, invisible section labels, dark chips on white (photographed on You,
// Workouts, Coach and Settings). The cause is not a theme bug: `AppColors.*`
// (lib/core/constants/app_colors.dart) is a bag of DARK-THEME LITERALS, and
// lib/screens/** + lib/widgets/** name those literals directly, so those
// surfaces paint dark colours regardless of the active Brightness.
//
// The theme-aware accessor is `ThemeColors` (lib/core/theme/theme_colors.dart):
//   final tc = ThemeColors.of(context);
//   Container(color: tc.surface, child: Text('hi', style: TextStyle(color: tc.textPrimary)))
// Every getter resolves `isDark ? AppColors.X : AppColorsLight.X`, so that file
// is the ONE place a dark literal may be named.
//
// This gate statically scans lib/screens/** + lib/widgets/** for raw
// `AppColors.<token>` references where <token> has a light counterpart in
// `AppColorsLight`. The token set is DERIVED at scan time by reading
// app_colors.dart + theme_colors.dart (never hardcoded here), so the gate
// cannot drift from the palette — add a light counterpart and the matching
// dark token comes into scope automatically. Scan/derivation logic lives in
// `light_mode_scan.dart` (no flutter_test dependency) so it can also run
// standalone; see that file's doc comment for the full rules, the two finding
// classes (`theme-mapped` vs `no-accessor`), and every exemption
// (lib/core/theme/**, `// accent-allowlist:` lines, tokens with no light
// counterpart, `//` comment mentions).
//
// BASELINE-STYLE: there are thousands of pre-existing violations, so a strict
// gate would be useless on day one — nobody could land an unrelated change
// without first converting an unrelated screen. `light_mode_baseline.json`
// grandfathers the current backlog as a per-file, per-token multiset (NOT line
// numbers — those churn on every unrelated edit, and a 112-violation file
// would otherwise report 112 phantom "new" findings after one inserted line).
// This test fails ONLY when a file's count for a token EXCEEDS its baseline,
// i.e. someone added a NEW raw dark literal. Draining the backlog shrinks
// counts, which never fails — it just means a refresh is due:
//   dart run test/ui_gates/light_mode_scan.dart > test/ui_gates/light_mode_baseline.json
// (this repo's Dart tests don't take CLI flags, so that standalone entry point
// IS the refresh command). Never hand-edit the JSON to silence a fresh
// violation. The inventory / fix-lane work list is:
//   dart run test/ui_gates/light_mode_scan.dart --report

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'light_mode_scan.dart';

const _baselinePath = 'test/ui_gates/light_mode_baseline.json';

void main() {
  group('light mode gate — real tree vs. baseline', () {
    test('no NEW hardcoded dark colours beyond the checked-in baseline', () {
      final baselineFile = File(_baselinePath);
      expect(
        baselineFile.existsSync(),
        isTrue,
        reason: 'Missing $_baselinePath. Generate it once with:\n'
            '  dart run test/ui_gates/light_mode_scan.dart > $_baselinePath',
      );

      final current = scanLightModeViolations();
      final diff = diffAgainstBaseline(current, loadBaselineCounts(baselineFile));

      if (diff.newFindings.isNotEmpty) {
        // Cap the printed list so a bulk regression doesn't bury the fix
        // instructions under thousands of lines.
        final shown = diff.newFindings.take(40).map((f) => '  $f').join('\n');
        final more = diff.newFindings.length > 40
            ? '\n  … and ${diff.newFindings.length - 40} more'
            : '';
        fail(
          '${diff.newFindings.length} NEW hardcoded-dark-colour reference(s) — '
          'a file under lib/screens/** or lib/widgets/** names a raw '
          '`AppColors.<token>` whose light counterpart exists in '
          'AppColorsLight, so it paints a DARK colour in light mode:\n'
          '$shown$more\n\n'
          'Fix: `final tc = ThemeColors.of(context);` then use the suggested '
          '`tc.<getter>` (lib/core/theme/theme_colors.dart). If the colour '
          'lives in a `static const` / top-level constant you cannot call '
          '`ThemeColors.of(context)` there — move it into build() or pass a '
          'ThemeColors parameter; dropping `const` from the constructor is '
          'acceptable. Do NOT leave a const that silently stays dark.\n'
          'Check CONTRAST, do not just swap tokens: a black card with an '
          'accent label may need the label rethought, not mapped.\n'
          'If the colour is deliberately dark in BOTH themes (a hero-photo '
          'scrim, a video overlay, a dark-on-image chip) or is a deliberate '
          'semantic colour (error state, brand mark, reward tier), annotate '
          'the line with `// accent-allowlist: <why>` — the reason is '
          'mandatory, that is what keeps the escape hatch honest.\n'
          'If this is a pre-existing finding you are not touching, do not '
          'silence it here — that defeats the gate. If you just converted a '
          'screen, shrink the baseline:\n'
          '  dart run test/ui_gates/light_mode_scan.dart > $_baselinePath\n'
          '\n${diff.grandfathered} pre-existing finding(s) grandfathered.',
        );
      }

      // Informational only — a shrinking baseline (fixes landed) never fails
      // the gate; it just means the refresh command above is due.
      if (diff.staleBaselineEntries > 0) {
        // ignore: avoid_print
        print('light_mode_gate: ${diff.staleBaselineEntries} baseline '
            'violation(s) no longer present — nice, run the refresh command '
            'above to shrink $_baselinePath.');
      } else {
        // ignore: avoid_print
        print('light_mode_gate: clean '
            '(${diff.grandfathered} known violation(s) grandfathered).');
      }
    });

    test('baseline file is valid JSON matching the current scan shape', () {
      final decoded =
          jsonDecode(File(_baselinePath).readAsStringSync()) as Map<String, dynamic>;
      expect(decoded['findings'], isA<List>());
      final findings = (decoded['findings'] as List).cast<Map<String, dynamic>>();
      expect(decoded['total'], findings.fold<int>(0, (a, e) => a + (e['count'] as int)));

      final ts = deriveTokenSet();
      for (final e in findings) {
        expect(e['rule'], anyOf('theme-mapped', 'no-accessor'));
        expect(
          kScanRoots.any((r) => (e['file'] as String).startsWith('$r/')),
          isTrue,
          reason: '${e['file']} is outside the scanned roots $kScanRoots',
        );
        expect(
          ts.contains(e['token'] as String),
          isTrue,
          reason: 'Baseline names AppColors.${e['token']}, which no longer has '
              'a light counterpart — the palette changed under the baseline. '
              'Refresh it.',
        );
      }
    });
  });

  // ─────────────────────── token-derivation checks ───────────────────────
  //
  // The token set is the gate's blast radius, so it gets its own coverage:
  // derived from the REAL palette (so a rename in app_colors.dart trips these
  // rather than silently shrinking the gate) and from synthetic sources (so
  // rules A/B/C are pinned independently of what the palette happens to hold).
  group('token derivation from the real palette', () {
    late TokenSet ts;
    setUpAll(() => ts = deriveTokenSet());

    test('the surface/text/border tokens the audit named are all in scope', () {
      for (final t in [
        'surface', 'elevated', 'background', 'glassSurface', 'cardBorder',
        'textPrimary', 'textSecondary', 'textMuted',
        'accent', 'accentContrast',
        'success', 'warning', 'error', 'info',
        'strength', 'cardio', 'flexibility', 'hiit',
      ]) {
        expect(ts.contains(t), isTrue, reason: 'AppColors.$t should be in scope');
        expect(ts.accessorFor(t), isNotNull,
            reason: 'ThemeColors should expose a getter resolving AppColors.$t');
      }
    });

    test('rule B — pureBlack is in scope via ThemeColors cross-name mapping', () {
      // AppColorsLight has no `pureBlack`; only ThemeColors.background knows
      // its counterpart is AppColorsLight.pureWhite.
      expect(ts.lightMembers.contains('pureBlack'), isFalse);
      expect(ts.contains('pureBlack'), isTrue);
      expect(ts.accessorFor('pureBlack'), 'background');
    });

    test('rule C — nearBlack is in scope via the Black/White naming inversion', () {
      expect(ts.lightMembers.contains('nearWhite'), isTrue);
      expect(ts.contains('nearBlack'), isTrue);
      // No ThemeColors getter exposes nearWhite, so this needs a design call,
      // not a token swap.
      expect(ts.accessorFor('nearBlack'), isNull);
      expect(ts.withoutAccessor, contains('nearBlack'));
    });

    test('tokens with no light counterpart stay OUT of scope', () {
      // Flagging these would be noise a lane cannot action — there is nothing
      // theme-aware to swap them for.
      for (final t in [
        'surface2', 'hairline', 'hairlineStrong', 'gamGold', 'glowCyan',
        'rarityBronze', 'quickActionWater', 'aiAccent', 'rir1', 'yellow',
        'red', 'pink', 'limeGreen', 'onboardingAccent',
      ]) {
        expect(ts.darkMembers, contains(t), reason: 'AppColors.$t vanished — '
            'update this list, the palette changed');
        expect(ts.contains(t), isFalse,
            reason: 'AppColors.$t has no AppColorsLight counterpart and must '
                'not be flagged');
      }
    });

    test('rules A/B/C on synthetic palette + mapping sources', () {
      const palette = '''
class AppColors {
  static const Color surface = Color(0xFF141416);
  static const Color pureBlack = Color(0xFF0A0A0B);
  static const Color nearBlack = Color(0xFF0A0A0A);
  static const Color hairline = Color(0xFF1A1A1A);
  static const Color mint = Color(0xFF00FF00);
}

class AppColorsLight {
  static const Color surface = Color(0xFFF9FAFB);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color nearWhite = Color(0xFFFAFAFA);
  static const Color mint = Color(0xFF00AA00);
}
''';
      const themeColors = '''
class ThemeColors {
  Color get surface => isDark ? AppColors.surface : AppColorsLight.surface;
  Color get background => isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
}
''';
      final t = deriveTokenSetFromSources(palette, themeColors);
      expect(t.accessorFor('surface'), 'surface'); // rule A + getter
      expect(t.accessorFor('pureBlack'), 'background'); // rule B
      expect(t.contains('nearBlack'), isTrue); // rule C
      expect(t.accessorFor('nearBlack'), isNull); // …but no accessor
      expect(t.contains('mint'), isTrue); // rule A
      expect(t.accessorFor('mint'), isNull); // no getter → no-accessor
      expect(t.contains('hairline'), isFalse); // no counterpart at all
    });
  });

  // ─────────────────────── detector unit checks ───────────────────────
  //
  // Regression coverage for the classification RULES themselves (independent
  // of whatever the real tree currently contains), fed through `scanSource` on
  // synthetic source strings.
  group('detector unit checks (scanSource on synthetic fixtures)', () {
    late TokenSet ts;
    setUpAll(() => ts = deriveTokenSet());

    test('flags a raw AppColors.textPrimary in a screen', () {
      const src = '''
Widget build(BuildContext context) {
  return Text('hi', style: TextStyle(color: AppColors.textPrimary));
}
''';
      final f = scanSource(src, 'lib/screens/you/you_screen.dart', ts);
      expect(f, hasLength(1));
      expect(f.single.token, 'textPrimary');
      expect(f.single.rule, 'theme-mapped');
      expect(f.single.suggestion, 'textPrimary');
    });

    test('flags a static const dark literal — the case that cannot take context', () {
      const src = '''
class _Card extends StatelessWidget {
  static const _bg = AppColors.elevated;
}
''';
      final f = scanSource(src, 'lib/widgets/foo_card.dart', ts);
      expect(f, hasLength(1));
      expect(f.single.token, 'elevated');
    });

    test('classifies a light-counterpart token with no ThemeColors getter as no-accessor', () {
      const src = "final c = AppColors.nearBlack;";
      final f = scanSource(src, 'lib/widgets/foo.dart', ts);
      expect(f, hasLength(1));
      expect(f.single.rule, 'no-accessor');
      expect(f.single.suggestion, isNull);
    });

    test('does NOT flag ThemeColors usage — the canonical accessor', () {
      const src = '''
Widget build(BuildContext context) {
  final tc = ThemeColors.of(context);
  return Container(color: tc.surface, child: Text('x', style: TextStyle(color: tc.textPrimary)));
}
''';
      expect(scanSource(src, 'lib/screens/you/you_screen.dart', ts), isEmpty);
    });

    test('does NOT flag a token with no AppColorsLight counterpart', () {
      const src = "final c = AppColors.surface2; final d = AppColors.gamGold;";
      expect(scanSource(src, 'lib/screens/you/you_screen.dart', ts), isEmpty);
    });

    test('does NOT flag a line carrying `// accent-allowlist:`', () {
      const src =
          "final c = AppColors.error; // accent-allowlist: destructive-action "
          "state, red in both themes by design";
      expect(scanSource(src, 'lib/screens/settings/danger_zone.dart', ts), isEmpty);
    });

    test('does NOT flag an intentionally-dark scrim annotated with accent-allowlist', () {
      const src = '''
// A hero photo scrim stays dark in both themes — text sits on the IMAGE.
final scrim = AppColors.pureBlack.withValues(alpha: 0.55); // accent-allowlist: scrim over hero media, dark in both themes
''';
      expect(scanSource(src, 'lib/widgets/hero_header.dart', ts), isEmpty);
    });

    test('does NOT flag a mention inside a `//` comment', () {
      const src = '''
// Historically this used AppColors.textMuted; now theme-aware.
final c = ThemeColors.of(context).textMuted;
''';
      expect(scanSource(src, 'lib/screens/you/you_screen.dart', ts), isEmpty);
    });

    test('does NOT flag AppColorsLight.* (different smell, different lane)', () {
      const src = "final c = AppColorsLight.textPrimary;";
      expect(scanSource(src, 'lib/screens/you/you_screen.dart', ts), isEmpty);
    });

    test('does NOT flag lib/core/theme/** — the mapping itself', () {
      const src =
          "Color get surface => isDark ? AppColors.surface : AppColorsLight.surface;";
      expect(scanSource(src, 'lib/core/theme/theme_colors.dart', ts), isEmpty);
    });

    test('counts every occurrence on a multi-reference line', () {
      const src =
          "final b = BoxDecoration(color: AppColors.elevated, border: Border.all(color: AppColors.cardBorder));";
      final f = scanSource(src, 'lib/widgets/foo.dart', ts);
      expect(f.map((e) => e.token), ['elevated', 'cardBorder']);
    });

    test('ownerDir buckets a finding under its 3-segment owning directory', () {
      const f = LightModeFinding(
        file: 'lib/screens/nutrition/widgets/logged_meals_section.dart',
        line: 1,
        token: 'textMuted',
        rule: 'theme-mapped',
      );
      expect(f.ownerDir, 'lib/screens/nutrition');
      const g = LightModeFinding(
        file: 'lib/widgets/glass_back_button.dart',
        line: 1,
        token: 'textMuted',
        rule: 'theme-mapped',
      );
      expect(g.ownerDir, 'lib/widgets');
    });
  });

  // ─────────────────────── "prove it can fail" self-test ───────────────────
  //
  // End-to-end proof of the ACTUAL gate mechanism (real filesystem scan +
  // baseline diff), not just the unit-level `scanSource` checks above: writes
  // a fabricated screen with a deliberate violation into a throwaway OS temp
  // directory (never touches the real repo tree), runs the real
  // `scanLightModeViolations` against that root, confirms the violation is
  // found and that diffing it against the fixture's own baseline reports it as
  // NEW — i.e. exactly what would fail the main assertion above — then
  // confirms the SAME file converted to ThemeColors is clean, and tears the
  // temp directory down.
  group('detector self-test against a scratch fixture tree', () {
    late Directory tempRoot;
    late String fixtureFile;
    late TokenSet ts;

    setUpAll(() => ts = deriveTokenSet());

    setUp(() {
      tempRoot = Directory.systemTemp.createTempSync('light_mode_gate_selftest_');
      final d = Directory('${tempRoot.path}/lib/screens/fixture')
        ..createSync(recursive: true);
      fixtureFile = '${d.path}/fixture_screen.dart';
    });

    tearDown(() {
      if (tempRoot.existsSync()) tempRoot.deleteSync(recursive: true);
    });

    test('an added raw AppColors reference is caught and reported as NEW', () {
      // Start from a file that already has ONE grandfathered violation, and a
      // baseline that grandfathers exactly that one — the real-world shape.
      File(fixtureFile).writeAsStringSync('''
class FixtureScreen extends StatelessWidget {
  Widget build(BuildContext context) {
    return Container(color: AppColors.elevated);
  }
}
''');
      final before = scanLightModeViolations(
          roots: ['${tempRoot.path}/lib/screens'], tokenSet: ts);
      expect(before, hasLength(1));
      final baseline = countsOf(before);
      expect(diffAgainstBaseline(before, baseline).newFindings, isEmpty,
          reason: 'the grandfathered violation must not fail the gate');

      // Now ADD a violation — the regression this gate exists to stop.
      File(fixtureFile).writeAsStringSync('''
class FixtureScreen extends StatelessWidget {
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.elevated,
      child: Text('hi', style: TextStyle(color: AppColors.textPrimary)),
    );
  }
}
''');
      final after = scanLightModeViolations(
          roots: ['${tempRoot.path}/lib/screens'], tokenSet: ts);
      expect(after, hasLength(2));

      final diff = diffAgainstBaseline(after, baseline);
      expect(diff.newFindings, hasLength(1),
          reason: 'The scanner failed to catch a deliberately-injected raw '
              'AppColors.textPrimary — the gate cannot protect anything if '
              'this fails.');
      expect(diff.newFindings.single.token, 'textPrimary');
      expect(diff.newFindings.single.rule, 'theme-mapped');
      expect(diff.grandfathered, 1);
    });

    test('the SAME fixture converted to ThemeColors is clean', () {
      File(fixtureFile).writeAsStringSync('''
class FixtureScreen extends StatelessWidget {
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Container(
      color: tc.elevated,
      child: Text('hi', style: TextStyle(color: tc.textPrimary)),
    );
  }
}
''');
      final found = scanLightModeViolations(
          roots: ['${tempRoot.path}/lib/screens'], tokenSet: ts);
      expect(found, isEmpty,
          reason: 'ThemeColors is the canonical accessor and must never be '
              'flagged.');
      // …and with an empty baseline it still reports nothing NEW.
      expect(diffAgainstBaseline(found, const {}).newFindings, isEmpty);
    });

    test('removing a violation shows up as a stale baseline entry, not a failure', () {
      File(fixtureFile).writeAsStringSync(
          'final a = AppColors.elevated; final b = AppColors.textMuted;');
      final before = scanLightModeViolations(
          roots: ['${tempRoot.path}/lib/screens'], tokenSet: ts);
      final baseline = countsOf(before);

      File(fixtureFile).writeAsStringSync('final a = AppColors.elevated;');
      final after = scanLightModeViolations(
          roots: ['${tempRoot.path}/lib/screens'], tokenSet: ts);
      final diff = diffAgainstBaseline(after, baseline);
      expect(diff.newFindings, isEmpty);
      expect(diff.staleBaselineEntries, 1);
    });
  });
}
