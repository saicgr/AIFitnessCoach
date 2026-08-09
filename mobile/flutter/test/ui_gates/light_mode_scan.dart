/// Pure scanning/classification core for the hardcoded-dark-colour gate
/// (`light_mode_gate_test.dart`). Split into its own library (no
/// `flutter_test` dependency — pure `dart:io`/`dart:convert`), the same split
/// `nav_affordance_scan.dart` and `card_geometry_scan.dart` use, so the exact
/// same logic can be:
///   1. run by the actual gate test (roots = real `lib/screens` + `lib/widgets`),
///   2. run by the "prove it can fail" self-test against a scratch temp
///      directory (see the `group('detector self-test'` block in the gate test),
///   3. run standalone (`dart run test/ui_gates/light_mode_scan.dart`) to
///      regenerate the checked-in baseline after a cleanup lane lands — the
///      `--refresh`-equivalent path, and
///   4. run as an inventory report
///      (`dart run test/ui_gates/light_mode_scan.dart --report`) — violations
///      grouped by owning directory + worst files, i.e. the fix-lane work list.
///
/// ── Background ───────────────────────────────────────────────────────────
/// Light mode is unreadable on many screens: black cards with near-black text,
/// invisible section labels, dark chips on white. The cause is not a theme
/// bug — it is that `AppColors.*` (`lib/core/constants/app_colors.dart`) is a
/// bag of **dark-theme literals**, and `lib/screens/**` + `lib/widgets/**`
/// reference those literals directly, so those surfaces paint dark colours
/// regardless of the active `Brightness`.
///
/// The theme-aware accessor is `ThemeColors`
/// (`lib/core/theme/theme_colors.dart`):
/// ```dart
/// final tc = ThemeColors.of(context);
/// Container(color: tc.surface, child: Text('hi', style: TextStyle(color: tc.textPrimary)));
/// ```
/// Each `ThemeColors` getter resolves `isDark ? AppColors.X : AppColorsLight.X`,
/// so it is the ONE place a dark literal is allowed to be named.
///
/// ── What counts as a violation ───────────────────────────────────────────
/// A raw `AppColors.<token>` reference in a file under one of [kScanRoots],
/// where `<token>` has a light counterpart — i.e. the dark literal being named
/// has a light-theme equivalent that the code is failing to use. A token with
/// NO light counterpart (`AppColors.surface2`, `AppColors.hairline`,
/// `AppColors.gamGold`, `AppColors.glowCyan`, `AppColors.rarityBronze`, the
/// `quickAction*` family, …) is NOT flagged: there is nothing theme-aware to
/// swap it for, so flagging it would just be noise a lane cannot action.
///
/// ── Deriving the token set (never hardcoded) ─────────────────────────────
/// [deriveTokenSet] reads `app_colors.dart` and `theme_colors.dart` at scan
/// time and computes the in-scope tokens from THOSE FILES, so the gate cannot
/// drift from the palette. A token is in scope when any of:
///
///   (A) **Same-name counterpart** — `AppColorsLight` declares a member of the
///       same name (`elevated`, `surface`, `cardBorder`, `textPrimary`,
///       `textSecondary`, `textMuted`, `success`, `error`, `strength`, …).
///   (B) **Cross-name counterpart declared by `ThemeColors` itself** — the
///       mapping file contains a literal `AppColors.X : AppColorsLight.Y` pair
///       with `X != Y`. This is how `AppColors.pureBlack` gets in scope: its
///       light counterpart is `AppColorsLight.pureWhite`, a fact only
///       `ThemeColors.background` knows.
///   (C) **Black/White naming inversion** — an `AppColors` token whose name
///       ends in `Black` when `AppColorsLight` declares the same name with
///       `Black` → `White` (`nearBlack` ↔ `nearWhite`). Derived from the two
///       classes' own naming convention, not from a hand-written pair list.
///
/// ── Rules (what the fix looks like) ──────────────────────────────────────
/// Each violation is tagged with one of two rules, which is the whole point of
/// the inventory — they need different work:
///
/// - `theme-mapped` — `ThemeColors` already exposes a getter that resolves
///   this exact token, so the fix is mechanical: `AppColors.textMuted` →
///   `ThemeColors.of(context).textMuted`. The getter name is carried on the
///   finding as [LightModeFinding.suggestion]. Getter names are scraped from
///   `theme_colors.dart` (both `=> isDark ? … : …` one-liners and `return
///   isDark ? … : …;` inside a block body), plus its documented
///   colour-name→accent aliases (`Color get orange => accent;` — see that
///   file's "Legacy colour-name aliases" section: those getters are named
///   after a colour but every caller means "the accent").
/// - `no-accessor` — the token HAS a light counterpart in `AppColorsLight` but
///   `ThemeColors` exposes no getter for it (`green`, `orangeLight`,
///   `macroProtein/Carbs/Fat`, `waterBlue*`, `nearBlack`). A lane must either
///   add the getter to `ThemeColors` or make a deliberate design call — it is
///   NOT a blind token swap.
///
/// ── Exemptions (why, not just what) ──────────────────────────────────────
/// - **`lib/core/theme/**` and `lib/core/constants/app_colors.dart`** — the
///   mapping and the palette themselves. `ThemeColors` naming `AppColors.X` is
///   the correct, load-bearing use. Enforced by [_isExemptPath] rather than by
///   relying on the scan roots to happen to exclude it.
/// - **`// accent-allowlist:` lines** — the repo's existing convention for a
///   deliberate semantic colour (error states, brand marks, reward tiers,
///   share-card presets). ~2.9k such lines already exist under the scan roots;
///   this gate honours them rather than inventing a second annotation.
/// - **Line comments** — an `AppColors.foo` mentioned after `//` is prose, not
///   a painted colour. (`://` in a URL is not treated as a comment start.)
/// - **Intentionally-dark-in-both-themes surfaces** (a hero photo scrim, a
///   video overlay, a dark-on-image chip) have no textual signal a static scan
///   can read. They are handled by the same `// accent-allowlist:` comment,
///   with the reason spelled out — that is a deliberate design decision: the
///   annotation forces the author to WRITE DOWN why dark is correct there,
///   instead of a silent second exemption list drifting out of date.
/// - `Colors.transparent` / `Colors.white` / `Colors.black` are outside this
///   gate entirely — it only ever matches the `AppColors.` prefix.
///
/// ── Baseline-style ───────────────────────────────────────────────────────
/// There are thousands of pre-existing violations, so a strict gate would be
/// useless on day one — nobody could land an unrelated change without first
/// converting an unrelated screen. `light_mode_baseline.json` grandfathers the
/// current backlog as a **per-file, per-token multiset** (NOT line numbers —
/// those churn on every unrelated edit, and a 60-violation file would produce
/// 60 phantom "new" findings after inserting one line at the top). The gate
/// fails only when a file's count for a token EXCEEDS its baseline count, i.e.
/// someone added a new raw dark literal. Draining the backlog shrinks counts,
/// which never fails — it just means a baseline refresh is due.
library light_mode_scan;

import 'dart:convert';
import 'dart:io';

/// Directories scanned, relative to the `mobile/flutter` package root. These
/// are the two trees that paint UI; `lib/core`, `lib/providers`, `lib/models`,
/// `lib/shareables` etc. are out of this gate's lane.
const List<String> kScanRoots = ['lib/screens', 'lib/widgets'];

/// The palette (both the dark `AppColors` and the light `AppColorsLight`).
const String kPalettePath = 'lib/core/constants/app_colors.dart';

/// The theme-aware accessor whose getters are the fix.
const String kThemeColorsPath = 'lib/core/theme/theme_colors.dart';

/// Paths that may legitimately name `AppColors.*` — the mapping itself.
bool _isExemptPath(String relPath) =>
    relPath.startsWith('lib/core/theme/') || relPath == kPalettePath;

/// The repo's existing "this colour is deliberate" annotation.
const String kAllowlistMarker = 'accent-allowlist:';

/// A raw palette reference. `\b` before `AppColors` keeps `MyAppColors.` out;
/// the negative lookahead keeps `AppColorsLight.` out (that is already the
/// light literal — a different, much rarer smell, and not this gate's lane).
final RegExp _rawRefRe = RegExp(r'\bAppColors(?!Light)\.([A-Za-z_][A-Za-z0-9_]*)');

/// `static const Color foo = …` / `static const LinearGradient bar = …` /
/// `static final …` member declarations inside a palette class body.
final RegExp _memberRe =
    RegExp(r'static\s+(?:const|final)\s+(?:Color|LinearGradient)\s+([A-Za-z_][A-Za-z0-9_]*)\s*=');

/// A `ThemeColors` ternary that resolves one dark literal to its light
/// counterpart — the authoritative statement that the two are counterparts.
/// Matches both the `=> isDark ? … : …;` one-liner form and the
/// `return isDark ? … : …;` block form.
final RegExp _themeMapRe =
    RegExp(r'AppColors\.([A-Za-z_][A-Za-z0-9_]*)\s*:\s*AppColorsLight\.([A-Za-z_][A-Za-z0-9_]*)');

/// Any getter declaration — used both to attribute a [_themeMapRe] hit to the
/// getter that encloses it (by walking backwards to the nearest `get <name>`)
/// and to build the same-name-getter fallback described in [deriveTokenSetFromSources].
final RegExp _getterRe = RegExp(r'\bget\s+([A-Za-z_][A-Za-z0-9_]*)\b');

/// Extracts the `{ … }` body of `class <name>` from [src] by brace balancing.
String _classBody(String src, String className) {
  final decl = RegExp('class\\s+$className\\b').firstMatch(src);
  if (decl == null) return '';
  final open = src.indexOf('{', decl.end);
  if (open == -1) return '';
  var depth = 0;
  for (var i = open; i < src.length; i++) {
    if (src[i] == '{') depth++;
    if (src[i] == '}') {
      depth--;
      if (depth == 0) return src.substring(open + 1, i);
    }
  }
  return '';
}

Set<String> _members(String classBody) =>
    _memberRe.allMatches(classBody).map((m) => m.group(1)!).toSet();

/// The in-scope token set plus, for each token, the `ThemeColors` getter that
/// replaces it (`null` when there is none → rule `no-accessor`).
class TokenSet {
  /// dark-palette token -> `ThemeColors` getter name, or null if no accessor.
  final Map<String, String?> tokens;

  /// Every member declared by `AppColors` (for the sanity assertions).
  final Set<String> darkMembers;

  /// Every member declared by `AppColorsLight`.
  final Set<String> lightMembers;

  const TokenSet({
    required this.tokens,
    required this.darkMembers,
    required this.lightMembers,
  });

  bool contains(String token) => tokens.containsKey(token);
  String? accessorFor(String token) => tokens[token];

  Set<String> get themeMapped =>
      tokens.entries.where((e) => e.value != null).map((e) => e.key).toSet();
  Set<String> get withoutAccessor =>
      tokens.entries.where((e) => e.value == null).map((e) => e.key).toSet();
}

/// Reads [palettePath] + [themeColorsPath] and derives the in-scope tokens.
/// See the library doc comment, "Deriving the token set", for rules A/B/C.
TokenSet deriveTokenSet({
  String palettePath = kPalettePath,
  String themeColorsPath = kThemeColorsPath,
}) {
  final paletteSrc = File(palettePath).readAsStringSync();
  final themeSrc = File(themeColorsPath).readAsStringSync();
  return deriveTokenSetFromSources(paletteSrc, themeSrc);
}

/// Pure form of [deriveTokenSet] (testable on synthetic sources).
TokenSet deriveTokenSetFromSources(String paletteSrc, String themeSrc) {
  final dark = _members(_classBody(paletteSrc, 'AppColors'));
  final light = _members(_classBody(paletteSrc, 'AppColorsLight'));

  // ── which ThemeColors getter resolves which dark token ──
  // First-wins: `Color get textSecondary => isDark ? AppColors.textSecondary
  // : …` is declared before the legacy alias `Color get cyanDark => isDark ?
  // AppColors.textSecondary : …`, so textSecondary keeps the getter that
  // shares its name rather than being renamed to `cyanDark` by a later line.
  final accessorFor = <String, String>{};
  // Cross-name counterparts asserted by ThemeColors (rule B) —
  // `AppColors.pureBlack : AppColorsLight.pureWhite`.
  final crossCounterpart = <String, String>{};

  for (final m in _themeMapRe.allMatches(themeSrc)) {
    final darkTok = m.group(1)!;
    final lightTok = m.group(2)!;
    if (darkTok != lightTok) crossCounterpart[darkTok] = lightTok;
    // Attribute to the nearest preceding `get <name>`.
    String? getter;
    for (final g in _getterRe.allMatches(themeSrc.substring(0, m.start))) {
      getter = g.group(1);
    }
    if (getter != null) accessorFor.putIfAbsent(darkTok, () => getter!);
  }

  // Same-name-getter fallback: `ThemeColors` declares a getter whose name IS
  // the token. Two shapes rely on this and neither is caught above —
  //   * the documented "legacy colour-name aliases" (`Color get orange =>
  //     accent;`): named after a colour, but every caller means the accent;
  //   * getters that resolve a DIFFERENTLY-named pair (`Color get background
  //     => isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;`), which
  //     is still the right accessor for `AppColors.background`.
  // Only applied when the dark palette actually declares a token of that name,
  // so accent-only getters (`metaPillLeadText`) never invent a token.
  for (final m in _getterRe.allMatches(themeSrc)) {
    final name = m.group(1)!;
    if (dark.contains(name)) accessorFor.putIfAbsent(name, () => name);
  }

  final tokens = <String, String?>{};
  for (final token in dark) {
    final sameName = light.contains(token); // rule A
    final cross = crossCounterpart.containsKey(token); // rule B
    // rule C — Black/White naming inversion (nearBlack ↔ nearWhite).
    final inverted = token.endsWith('Black') &&
        light.contains('${token.substring(0, token.length - 'Black'.length)}White');
    if (!sameName && !cross && !inverted) continue;
    tokens[token] = accessorFor[token];
  }

  return TokenSet(tokens: tokens, darkMembers: dark, lightMembers: light);
}

class LightModeFinding {
  /// Repo-relative, posix separators (`lib/screens/you/...`).
  final String file;

  /// 1-indexed line of the reference — reporting only, NOT part of the
  /// baseline identity (see library doc, "Baseline-style").
  final int line;

  /// The referenced dark-palette token, e.g. `textMuted`.
  final String token;

  /// `theme-mapped` (a `ThemeColors` getter exists → mechanical swap) or
  /// `no-accessor` (light counterpart exists but no getter → needs one).
  final String rule;

  /// The `ThemeColors` getter to use, when the rule is `theme-mapped`.
  final String? suggestion;

  const LightModeFinding({
    required this.file,
    required this.line,
    required this.token,
    required this.rule,
    this.suggestion,
  });

  /// Baseline identity: file + token. Deliberately excludes the line number
  /// (churns on every unrelated edit) and the rule/suggestion (both are
  /// derived from the token, so they would be redundant key material that
  /// invalidates the whole baseline the day a `ThemeColors` getter is added).
  String get baselineKey => '$file $token';

  /// Owning directory for the inventory report — three path segments deep
  /// (`lib/screens/you`, `lib/widgets/glass`), or the file's own directory
  /// when it is shallower.
  String get ownerDir {
    final parts = file.split('/');
    if (parts.length <= 3) return parts.sublist(0, parts.length - 1).join('/');
    return parts.take(3).join('/');
  }

  @override
  String toString() => '$file:$line  AppColors.$token  [$rule]'
      '${suggestion != null ? '  → ThemeColors.of(context).$suggestion' : ''}';
}

/// True when [idx] in [src] sits inside a `//` line comment. `://` (a URL) is
/// not a comment start.
bool _inLineComment(String src, int idx) {
  final lineStart = src.lastIndexOf('\n', idx) + 1;
  final before = src.substring(lineStart, idx);
  for (var i = 0; i + 1 < before.length; i++) {
    if (before[i] == '/' && before[i + 1] == '/') {
      if (i > 0 && before[i - 1] == ':') continue; // `https://…`
      return true;
    }
  }
  return false;
}

/// Scans one file's already-read [src]. [relPath] is stored on each finding.
List<LightModeFinding> scanSource(String src, String relPath, TokenSet tokenSet) {
  if (_isExemptPath(relPath)) return const [];
  final findings = <LightModeFinding>[];

  for (final m in _rawRefRe.allMatches(src)) {
    final token = m.group(1)!;
    if (!tokenSet.contains(token)) continue; // no light counterpart → out of scope
    if (_inLineComment(src, m.start)) continue;

    final lineStart = src.lastIndexOf('\n', m.start) + 1;
    var lineEnd = src.indexOf('\n', m.start);
    if (lineEnd == -1) lineEnd = src.length;
    final lineText = src.substring(lineStart, lineEnd);
    if (lineText.contains(kAllowlistMarker)) continue; // deliberate semantic colour

    final accessor = tokenSet.accessorFor(token);
    findings.add(LightModeFinding(
      file: relPath,
      line: '\n'.allMatches(src.substring(0, m.start)).length + 1,
      token: token,
      rule: accessor != null ? 'theme-mapped' : 'no-accessor',
      suggestion: accessor,
    ));
  }
  return findings;
}

/// Recursively scans every `.dart` file under [roots] (default [kScanRoots],
/// run from the `mobile/flutter` package root).
List<LightModeFinding> scanLightModeViolations({
  List<String> roots = kScanRoots,
  TokenSet? tokenSet,
}) {
  final ts = tokenSet ?? deriveTokenSet();
  final findings = <LightModeFinding>[];
  for (final root in roots) {
    final dir = Directory(root);
    if (!dir.existsSync()) continue;
    for (final entity in dir.listSync(recursive: true, followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final relPath = entity.path.replaceAll('\\', '/');
      findings.addAll(scanSource(entity.readAsStringSync(), relPath, ts));
    }
  }
  findings.sort((a, b) {
    final c1 = a.file.compareTo(b.file);
    if (c1 != 0) return c1;
    return a.line.compareTo(b.line);
  });
  return findings;
}

// ─────────────────────────── baseline I/O ───────────────────────────

Map<String, int> countsOf(List<LightModeFinding> findings) {
  final c = <String, int>{};
  for (final f in findings) {
    c[f.baselineKey] = (c[f.baselineKey] ?? 0) + 1;
  }
  return c;
}

class BaselineDiff {
  final List<LightModeFinding> newFindings;
  final int grandfathered;
  final int staleBaselineEntries;
  const BaselineDiff({
    required this.newFindings,
    required this.grandfathered,
    required this.staleBaselineEntries,
  });
}

/// Loads `{file, token, count}` entries from a baseline JSON file into a
/// key -> count map.
Map<String, int> loadBaselineCounts(File baselineFile) =>
    parseBaselineCounts(baselineFile.readAsStringSync());

Map<String, int> parseBaselineCounts(String json) {
  final data = jsonDecode(json) as Map<String, dynamic>;
  final entries = (data['findings'] as List).cast<Map<String, dynamic>>();
  final counts = <String, int>{};
  for (final e in entries) {
    final key = '${e['file']} ${e['token']}';
    counts[key] = (counts[key] ?? 0) + ((e['count'] as num?)?.toInt() ?? 1);
  }
  return counts;
}

/// Multiset diff, mirroring `nav_affordance_scan.dart` and
/// `audit_timezone_usage.py --check`: a current finding is grandfathered while
/// the baseline still has an unconsumed count for its `file token` key;
/// anything beyond that is NEW and fails the gate.
BaselineDiff diffAgainstBaseline(
  List<LightModeFinding> current,
  Map<String, int> baselineCounts,
) {
  final remaining = Map<String, int>.from(baselineCounts);
  final newFindings = <LightModeFinding>[];
  for (final f in current) {
    final k = f.baselineKey;
    final left = remaining[k] ?? 0;
    if (left > 0) {
      remaining[k] = left - 1;
    } else {
      newFindings.add(f);
    }
  }
  final stale = remaining.values.where((v) => v > 0).fold<int>(0, (a, b) => a + b);
  return BaselineDiff(
    newFindings: newFindings,
    grandfathered: current.length - newFindings.length,
    staleBaselineEntries: stale,
  );
}

String encodeBaseline(List<LightModeFinding> findings) {
  final counts = countsOf(findings);
  final byKey = <String, LightModeFinding>{};
  for (final f in findings) {
    byKey[f.baselineKey] = f;
  }
  final keys = counts.keys.toList()..sort();
  final payload = {
    '_comment': 'Grandfathered hardcoded-dark-colour findings: raw '
        '`AppColors.<token>` references under lib/screens/** + lib/widgets/** '
        'where <token> has a light counterpart in AppColorsLight, so the '
        'surface paints a DARK literal in light mode. See '
        'light_mode_scan.dart doc comment for the derivation rules and '
        'exemptions (lib/core/theme/**, `// accent-allowlist:` lines, tokens '
        'with no light counterpart). `light_mode_gate_test.dart` fails only on '
        'findings NOT covered here, so the backlog cannot grow while the fix '
        'lanes drain it. Keyed by file + token with a count (NOT line numbers '
        '— those churn on every unrelated edit). Regenerate with '
        '`dart run test/ui_gates/light_mode_scan.dart > '
        'test/ui_gates/light_mode_baseline.json` after converting a screen — '
        'never hand-edit to silence a fresh violation.',
    'total': findings.length,
    'byRule': {
      'theme-mapped': findings.where((f) => f.rule == 'theme-mapped').length,
      'no-accessor': findings.where((f) => f.rule == 'no-accessor').length,
    },
    'findings': [
      for (final k in keys)
        {
          'file': byKey[k]!.file,
          'token': byKey[k]!.token,
          'rule': byKey[k]!.rule,
          'count': counts[k],
        },
    ],
  };
  return const JsonEncoder.withIndent('  ').convert(payload);
}

// ─────────────────────────── inventory report ───────────────────────────

/// The fix-lane work list: totals grouped by owning directory, worst files,
/// and per-token totals. Printed by `--report`.
String renderInventory(List<LightModeFinding> findings, TokenSet ts) {
  final b = StringBuffer();
  final byDir = <String, int>{};
  final byFile = <String, int>{};
  final byToken = <String, int>{};
  for (final f in findings) {
    byDir[f.ownerDir] = (byDir[f.ownerDir] ?? 0) + 1;
    byFile[f.file] = (byFile[f.file] ?? 0) + 1;
    byToken[f.token] = (byToken[f.token] ?? 0) + 1;
  }

  b.writeln('TOTAL: ${findings.length} violations across ${byFile.length} files');
  b.writeln('  theme-mapped (mechanical `tc.<getter>` swap): '
      '${findings.where((f) => f.rule == 'theme-mapped').length}');
  b.writeln('  no-accessor  (needs a ThemeColors getter):    '
      '${findings.where((f) => f.rule == 'no-accessor').length}');
  b.writeln('');
  b.writeln('IN-SCOPE TOKENS (${ts.tokens.length}): '
      '${(ts.tokens.keys.toList()..sort()).join(', ')}');
  b.writeln('OUT OF SCOPE (no AppColorsLight counterpart): '
      '${(ts.darkMembers.difference(ts.tokens.keys.toSet()).toList()..sort()).join(', ')}');
  b.writeln('');
  b.writeln('── BY OWNING DIRECTORY ──');
  final dirs = byDir.entries.toList()..sort((a, z) => z.value.compareTo(a.value));
  for (final e in dirs) {
    b.writeln('${e.value.toString().padLeft(6)}  ${e.key}');
  }
  b.writeln('');
  b.writeln('── TOP 20 FILES ──');
  final files = byFile.entries.toList()..sort((a, z) => z.value.compareTo(a.value));
  for (final e in files.take(20)) {
    b.writeln('${e.value.toString().padLeft(6)}  ${e.key}');
  }
  b.writeln('');
  b.writeln('── BY TOKEN ──');
  final toks = byToken.entries.toList()..sort((a, z) => z.value.compareTo(a.value));
  for (final e in toks) {
    final acc = ts.accessorFor(e.key);
    b.writeln('${e.value.toString().padLeft(6)}  AppColors.${e.key.padRight(18)}'
        '${acc != null ? '→ tc.$acc' : '(no ThemeColors getter)'}');
  }
  return b.toString();
}

/// Standalone entry point.
///   dart run test/ui_gates/light_mode_scan.dart            # baseline JSON to stdout
///   dart run test/ui_gates/light_mode_scan.dart --report   # inventory to stdout
void main(List<String> args) {
  final ts = deriveTokenSet();
  final findings = scanLightModeViolations(tokenSet: ts);
  if (args.contains('--report')) {
    stdout.write(renderInventory(findings, ts));
    return;
  }
  stdout.writeln(encodeBaseline(findings));
  stderr.writeln('${findings.length} hardcoded-dark-colour violation(s) across '
      '${kScanRoots.join(' + ')}.');
}
