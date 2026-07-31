// ignore_for_file: avoid_print
//
// Accent-source regression gate (E2E register row 15).
//
// The app accent must come from exactly one place — `accentColorProvider`,
// read via `context.accentColor` / `AccentColorScope.colorOf(context)` /
// `ThemeColors.of(context).accent`. Every widget that instead paints a vivid
// colour of its own is a competing accent source: it is the reason the
// "Quick check-in" sheet rendered cyan inside an otherwise-orange app, Stats /
// You / coach chips owned cyan while fitness chips owned amber, and the
// log-meal action row shipped five different colours in a single row.
//
// This gate is a BASELINE DIFF, in the same shape as
// `backend/scripts/audit_timezone_usage.py`: the ~1,600-site backlog is
// grandfathered, and the gate fails only when a file gains a NEW hardcoded
// accent-family colour. That makes it adoptable today and still blocks the
// regression from growing.
//
// Run:
//   cd mobile/flutter && dart run lib/core/theme/accent_source_gate.dart --check
//   cd mobile/flutter && dart run lib/core/theme/accent_source_gate.dart --list
//   cd mobile/flutter && dart run lib/core/theme/accent_source_gate.dart --refresh-baseline
//
// Suppress an intentional non-accent colour with a trailing comment on the
// line, mirroring the tz gate's `# tz-allowlist:`:
//   color: const Color(0xFFE53935), // accent-allowlist: injury severity scale
//
// What counts as an "accent-family" colour is DERIVED, not enumerated: any
// colour whose HSV saturation and value put it in the vivid brand range. Greys,
// near-blacks, near-whites and washed-out tints are ignored, so semantic
// surfaces (borders, scrims, muted text) never trip the gate.

library;

import 'dart:io';
import 'dart:math' as math;

/// Directories/files that legitimately define or preview raw colours.
const _skipPathFragments = <String>[
  '/lib/l10n/',
  '/lib/core/theme/',
  '/lib/core/constants/app_colors.dart',
];
// NOTE: model/palette files are deliberately NOT skipped. `core/models/
// chat_quick_action.dart` hardcodes 20 different accent-family colours and is
// precisely why the coach quick-action chips render cyan/teal/violet/pink in
// one grid. A palette that is genuinely semantic (macro rings, rarity tiers)
// declares itself with a trailing `// accent-allowlist: <reason>`.

/// Material swatch names that are neutral by construction.
const _neutralMaterialNames = <String>{
  'white',
  'white70',
  'white60',
  'white54',
  'white38',
  'white30',
  'white24',
  'white12',
  'white10',
  'black',
  'black87',
  'black switching',
  'black54',
  'black45',
  'black38',
  'black26',
  'black12',
  'transparent',
  'grey',
  'blueGrey',
  'brown',
};

final _hexLiteral = RegExp(r'Color\(\s*0x([0-9a-fA-F]{8})\s*\)');
// `Color(0x…)` is not the only way to spell a literal colour. Without these two
// the gate has a silent bypass: `Color.fromARGB(255, 249, 115, 22)` is the same
// orange the gate would reject as `Color(0xFFF97316)`. Only fully-literal forms
// are judged — the two computed `Color.fromARGB(...)` call sites in lib/
// (score_colors.dart, card_palette.dart) pass variables, so a static gate
// cannot and must not guess at them.
final _fromArgbLiteral = RegExp(
    r'Color\.fromARGB\(\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})\s*\)');
final _fromRgboLiteral = RegExp(
    r'Color\.fromRGBO\(\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*([0-9.]+)\s*\)');
final _appColorsRef = RegExp(r'\b(AppColors(?:Light)?)\.([A-Za-z_][A-Za-z0-9_]*)');
final _classDecl = RegExp(r'^\s*(?:abstract\s+)?class\s+([A-Za-z_][A-Za-z0-9_]*)');
final _materialRef = RegExp(r'\bColors\.([A-Za-z][A-Za-z0-9]*)');
final _constDecl =
    RegExp(r'static\s+const\s+Color\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*Color\(\s*0x([0-9a-fA-F]{8})\s*\)');

/// True when [argb] sits in the vivid "brand accent" region of HSV space.
///
/// Derived rather than enumerated so a new brand colour is caught without
/// anyone updating a list.
bool isAccentFamily(int argb) {
  final a = (argb >> 24) & 0xFF;
  if (a < 0x40) return false; // near-transparent tints are decoration, not accent
  final r = ((argb >> 16) & 0xFF) / 255.0;
  final g = ((argb >> 8) & 0xFF) / 255.0;
  final b = (argb & 0xFF) / 255.0;
  final maxC = math.max(r, math.max(g, b));
  final minC = math.min(r, math.min(g, b));
  final value = maxC;
  final sat = maxC == 0 ? 0.0 : (maxC - minC) / maxC;
  // Vivid enough to read as "a colour", bright enough to be used as an accent.
  return sat >= 0.35 && value >= 0.45;
}

/// Parses `app_colors.dart` so `AppColors.<name>` can be judged by its value.
///
/// Keyed `"<Class>.<name>"`. `AppColors.cyan` (#06B6D4, vivid) and
/// `AppColorsLight.cyan` (#424242, grey) are DIFFERENT colours — a flat
/// name-keyed map silently lets the second overwrite the first and the gate
/// then misses every dark-theme cyan.
Map<String, int> _loadAppColorConstants(Directory libDir) {
  final file = File('${libDir.path}/core/constants/app_colors.dart');
  if (!file.existsSync()) return const {};
  final out = <String, int>{};
  var currentClass = '';
  for (final line in file.readAsLinesSync()) {
    final cls = _classDecl.firstMatch(line);
    if (cls != null) currentClass = cls.group(1)!;
    final m = _constDecl.firstMatch(line);
    if (m != null) {
      out['$currentClass.${m.group(1)!}'] = int.parse(m.group(2)!, radix: 16);
    }
  }
  return out;
}

class Finding {
  final String path;
  final int line;
  final String token;
  Finding(this.path, this.line, this.token);
  @override
  String toString() => '$path:$line  $token';
}

List<Finding> scan(Directory libDir) {
  final constants = _loadAppColorConstants(libDir);
  final findings = <Finding>[];

  final files = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !_skipPathFragments.any((s) => f.path.contains(s)))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in files) {
    final rel = file.path.split('/mobile/flutter/').last;
    final lines = file.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.contains('accent-allowlist:')) continue;
      final trimmed = line.trimLeft();
      if (trimmed.startsWith('//') || trimmed.startsWith('///')) continue;

      for (final m in _hexLiteral.allMatches(line)) {
        final argb = int.parse(m.group(1)!, radix: 16);
        if (isAccentFamily(argb)) {
          findings.add(Finding(rel, i + 1, 'Color(0x${m.group(1)!.toUpperCase()})'));
        }
      }
      for (final m in _fromArgbLiteral.allMatches(line)) {
        final a = int.parse(m.group(1)!);
        final argb = (a << 24) |
            (int.parse(m.group(2)!) << 16) |
            (int.parse(m.group(3)!) << 8) |
            int.parse(m.group(4)!);
        if (isAccentFamily(argb)) {
          findings.add(Finding(rel, i + 1, 'Color.fromARGB(${m.group(1)},'
              '${m.group(2)},${m.group(3)},${m.group(4)})'));
        }
      }
      for (final m in _fromRgboLiteral.allMatches(line)) {
        final opacity = double.tryParse(m.group(4)!) ?? 1.0;
        final argb = ((opacity.clamp(0.0, 1.0) * 255).round() << 24) |
            (int.parse(m.group(1)!) << 16) |
            (int.parse(m.group(2)!) << 8) |
            int.parse(m.group(3)!);
        if (isAccentFamily(argb)) {
          findings.add(Finding(rel, i + 1, 'Color.fromRGBO(${m.group(1)},'
              '${m.group(2)},${m.group(3)},${m.group(4)})'));
        }
      }
      for (final m in _appColorsRef.allMatches(line)) {
        final ref = '${m.group(1)!}.${m.group(2)!}';
        final argb = constants[ref];
        if (argb != null && isAccentFamily(argb)) {
          findings.add(Finding(rel, i + 1, ref));
        }
      }
      for (final m in _materialRef.allMatches(line)) {
        final name = m.group(1)!;
        if (_neutralMaterialNames.contains(name)) continue;
        findings.add(Finding(rel, i + 1, 'Colors.$name'));
      }
    }
  }
  return findings;
}

Map<String, int> _countByFile(List<Finding> findings) {
  final counts = <String, int>{};
  for (final f in findings) {
    counts[f.path] = (counts[f.path] ?? 0) + 1;
  }
  return counts;
}

/// Baseline is per-file COUNTS (not line numbers) so unrelated edits above an
/// offending line do not churn the file.
Map<String, int> _readBaseline(File f) {
  if (!f.existsSync()) return {};
  final out = <String, int>{};
  for (final line in f.readAsLinesSync()) {
    if (line.trim().isEmpty || line.startsWith('#')) continue;
    final parts = line.split('\t');
    if (parts.length != 2) continue;
    out[parts[0]] = int.parse(parts[1]);
  }
  return out;
}

void _writeBaseline(File f, Map<String, int> counts) {
  final keys = counts.keys.toList()..sort();
  final buf = StringBuffer()
    ..writeln('# Accent-source gate baseline — per-file counts of hardcoded')
    ..writeln('# accent-family colours. Grandfathered backlog; the gate fails')
    ..writeln('# only when a count grows or a new file appears. Regenerate with')
    ..writeln('#   dart run lib/core/theme/accent_source_gate.dart --refresh-baseline')
    ..writeln('# Lower these numbers as screens migrate to context.accentColor.');
  for (final k in keys) {
    buf.writeln('$k\t${counts[k]}');
  }
  f.writeAsStringSync(buf.toString());
}

void main(List<String> args) {
  final scriptDir = File(Platform.script.toFilePath()).parent; // lib/core/theme
  final libDir = scriptDir.parent.parent; // lib
  final baselineFile = File('${scriptDir.path}/accent_source_baseline.tsv');

  final findings = scan(libDir);
  final counts = _countByFile(findings);

  if (args.contains('--refresh-baseline')) {
    _writeBaseline(baselineFile, counts);
    print('✅ baseline refreshed: ${findings.length} findings across '
        '${counts.length} files');
    exit(0);
  }

  if (args.contains('--list')) {
    for (final f in findings) {
      print(f);
    }
    print('— ${findings.length} findings across ${counts.length} files');
    exit(0);
  }

  // A MISSING baseline is a setup error. An EMPTY one is the goal state — the
  // whole backlog has been migrated or allowlisted, so every finding is new by
  // construction. Those two were conflated (`baseline.isEmpty`), which meant
  // the gate started erroring out the moment the sweep actually succeeded.
  // E2E register row 15: the sweep took this from 10,537 findings across 1,212
  // files to 0, and this branch is what it hit on arrival.
  if (!baselineFile.existsSync()) {
    stderr.writeln('❌ no baseline at ${baselineFile.path}. '
        'Run with --refresh-baseline once, and commit it.');
    exit(2);
  }

  final baseline = _readBaseline(baselineFile);

  final regressions = <String>[];
  for (final entry in counts.entries) {
    final was = baseline[entry.key] ?? 0;
    if (entry.value > was) {
      regressions.add('${entry.key}: $was → ${entry.value}');
    }
  }

  if (regressions.isEmpty) {
    final improved = baseline.entries
        .where((e) => (counts[e.key] ?? 0) < e.value)
        .length;
    print('✅ accent-source gate: no new hardcoded accent colours '
        '(${findings.length} grandfathered; $improved file(s) improved)');
    exit(0);
  }

  stderr.writeln('❌ accent-source gate FAILED — new hardcoded accent-family '
      'colours in ${regressions.length} file(s):');
  for (final r in regressions..sort()) {
    stderr.writeln('   $r');
  }
  stderr.writeln('');
  stderr.writeln('Read the accent from the single source instead:');
  stderr.writeln('   final accent = context.accentColor;          '
      '// core/theme/accent_color_provider.dart');
  stderr.writeln('   final accent = ThemeColors.of(context).accent;');
  stderr.writeln('If the colour is genuinely NOT the accent (a severity scale, '
      'a macro ring, a rarity tier), append a trailing');
  stderr.writeln('   // accent-allowlist: <reason>');
  exit(1);
}
