/// Pure scanning/classification core for the navigation-affordance
/// consistency gate (`nav_affordance_gate_test.dart`). Split into its own
/// library (no `flutter_test` dependency — pure `dart:io`/`dart:convert`), the
/// same split `card_geometry_scan.dart` uses, so the exact same logic can be:
///   1. run by the actual gate test (root = real `lib/screens`), and
///   2. run by the "prove it can fail" self-test against a scratch temp
///      directory (see the `group('detector self-test'` block in the gate
///      test), and
///   3. run standalone (`dart run test/ui_gates/nav_affordance_scan.dart`) to
///      regenerate the checked-in baseline after a deliberate cleanup pass —
///      the `--refresh`-equivalent path.
///
/// ── Background ───────────────────────────────────────────────────────────
/// A screenshot audit of 862 images found NO app-wide convention for the
/// full-screen "go back" control: ~35 routes use a circled glass capsule
/// (`GlassBackButton`, `lib/widgets/glass_back_button.dart`), ~36 use a bare
/// system-default `IconButton`/`Icon`. The audit recommends standardising on
/// the circled control. This gate makes that enforceable going forward: it
/// fails when a file under `lib/screens/**` constructs a back-navigation icon
/// (`Icons.arrow_back*` / `Icons.chevron_left*`) SOME OTHER WAY than the
/// canonical widget.
///
/// ── Canonical widget ─────────────────────────────────────────────────────
/// `GlassBackButton` (`lib/widgets/glass_back_button.dart`) — the circled
/// glass capsule — is the one full-screen-route back control. Its sheet-only
/// sibling `SheetBackButton` / `SheetHeader`'s built-in back slot
/// (`lib/widgets/sheet_header.dart`) is the bottom-sheet convention (drag
/// handle + back chip, separate from this gate's scope — see "What this does
/// NOT scan" below). Both widgets build their own icon glyph internally in a
/// file OUTSIDE `lib/screens/**`, so a screen that calls `GlassBackButton(...)`
/// / `SheetBackButton(...)` never re-embeds `Icons.arrow_back`/`chevron_left`
/// text at its call site and is naturally invisible to this scan — no
/// allowlist needed for the common case.
///
/// ── What counts as a violation ───────────────────────────────────────────
/// Any occurrence of `Icons.arrow_back*` / `Icons.chevron_left*` whose
/// nearest enclosing tappable wrapper is a raw `IconButton(...)`
/// (rule `raw-icon-button`) or a bare `Icon(...)` sitting directly inside a
/// `GestureDetector(...)` / `InkWell(...)` (rule `bare-icon-tap`) — i.e. some
/// OTHER way of building a tap-to-go-back control than `GlassBackButton`.
///
/// `Icons.arrow_back*` is treated as an unambiguous "this means go back"
/// signal. `Icons.chevron_left*` is ambiguous — this codebase also uses it
/// for calendar/pager prev-arrows (`_year -= 1`, `onPrev`, month/week
/// navigators) that have nothing to do with screen navigation — so a
/// `chevron_left*` match is only flagged when its wrapper ALSO contains a
/// pop/back signal (`.pop(`, `Navigator.pop`, `context.pop()`, or a callback
/// named `onBack`/`onBackTap`/... ). Either icon family is suppressed when
/// the wrapper carries an explicit pagination signal (`setState`, `_year`,
/// `_month`, `_week`, `prev`, `next`, `page`, `calendar`, `pager`, `carousel`,
/// `slide`, `step` — case-insensitive) — see `_paginationSignalRe`.
///
/// ── Exemptions (why, not just what) ──────────────────────────────────────
/// - **Tab roots** (`kTabRootFiles`): the five bottom-nav destinations
///   (`/home`, `/workouts`, `/coach`, `/nutrition`, `/profile` —
///   `StatefulShellBranch` roots in
///   `lib/navigation/app_router_main_shell_routes.dart`) correctly render
///   with NO back control: there is nowhere to go "back" to from a tab root,
///   Android's system back / the OS gesture already exits/backgrounds the
///   app from there. Exempted at the FILE level — the whole point of a tab
///   root is that it never builds this affordance at all.
/// - **Dialogs**: any icon match whose nearest enclosing `AlertDialog(...)` /
///   `SimpleDialog(...)` / `Dialog(...)` / `CupertinoAlertDialog(...)`
///   contains it is skipped — dialogs correctly dismiss via text buttons
///   (Cancel/OK), not an icon-based back control, and the screenshot audit
///   found dialogs already fully consistent. This is a CONTAINMENT check
///   (any enclosing dialog call, not just the nearest wrapper), so a raw
///   `IconButton(Icons.arrow_back...)` built inside a dialog's `builder:` —
///   even though `IconButton` is textually "closer" to the icon than the
///   dialog constructor — is still correctly exempted.
///
/// ── What this does NOT scan ──────────────────────────────────────────────
/// Bottom sheets (`showModalBottomSheet` builders, `*_sheet.dart` files) are
/// deliberately out of scope for this gate. The screenshot audit found sheets
/// already ~45/60 consistent on drag-handle-only, a DIFFERENT convention
/// (drag handle + optional × close, not a circled back arrow) than
/// full-screen routes — conflating the two would either force sheets to grow
/// a back arrow they shouldn't have, or water down this gate's icon-family
/// logic to accommodate a convention this gate isn't measuring. Sheet
/// consistency is real follow-up work, tracked separately.
library nav_affordance_scan;

import 'dart:convert';
import 'dart:io';

/// The five bottom-nav destination screens (`StatefulShellBranch` roots in
/// `lib/navigation/app_router_main_shell_routes.dart`). A tab root has no
/// "back" to go to — the absence of a back control here is CORRECT, not a
/// deviation, so these files are skipped entirely rather than relying on the
/// per-match heuristics to happen to find nothing.
const Set<String> kTabRootFiles = {
  'lib/screens/home/home_screen.dart', // branch 0: /home
  'lib/screens/workouts/workouts_screen.dart', // branch 1: /workouts
  'lib/screens/chat/coach_tab_screen.dart', // branch 2: /coach
  'lib/screens/nutrition/nutrition_screen.dart', // branch 3: /nutrition
  'lib/screens/profile/profile_screen.dart', // branch 4: /profile ("You")
};

/// Back-navigation icon glyphs. Grouped so `arrow_back*` (unambiguous) and
/// `chevron_left*` (ambiguous — also a pagination glyph in this codebase) get
/// different confidence treatment in [_isViolationWrapper].
final RegExp _backIconRe = RegExp(
  r'Icons\.(arrow_back(?:_ios(?:_new)?)?(?:_rounded)?|chevron_left(?:_rounded)?)\b',
);

bool _isStrongBackIcon(String iconName) => iconName.startsWith('arrow_back');

/// A callback that pops navigation, or is explicitly named for "back".
final RegExp _popSignalRe = RegExp(r'\.pop\(|on\w*[Bb]ack\w*');

/// Calendar/pager/carousel vocabulary — present in this codebase's
/// `chevron_left`-as-"previous" call sites (year/month/week navigators,
/// `PageView` dot indicators). Checked against the wrapper's own source only
/// (a small, local blast radius), so an unrelated word appearing elsewhere in
/// the same file can't suppress a real finding.
final RegExp _paginationSignalRe = RegExp(
  r'\b(prev\w*|next\w*|_?year\w*|_?month\w*|_?week\w*|page\w*|calendar\w*|pager\w*|carousel\w*|slide\w*|step\w*)\b',
  caseSensitive: false,
);

/// Tappable-wrapper keywords this gate can classify. Order doesn't matter —
/// [_findNearestWrapper] picks whichever's balanced range most tightly
/// encloses the match.
const List<String> _wrapperKeywords = [
  'IconButton(',
  'IconButton.filled(',
  'IconButton.filledTonal(',
  'IconButton.outlined(',
  'GestureDetector(',
  'InkWell(',
];

/// Constructors whose contents are exempt outright (containment, not
/// nearest-wrapper — see module doc "Exemptions").
const List<String> _dialogKeywords = [
  'AlertDialog(',
  'SimpleDialog(',
  'CupertinoAlertDialog(',
  // Bare `Dialog(` is deliberately EXCLUDED from this list: `Dialog(` is also
  // a substring of `AlertDialog(`/`SimpleDialog(`/`CupertinoAlertDialog(`
  // (already covered above) and, unlike those three, is not by itself a
  // reliable "this is a modal dialog" signal in this codebase.
];

/// Constructors that already build the canonical circled control — any icon
/// glyph inside one of these (e.g. a caller overriding `GlassBackButton`'s
/// default `icon:` param) is by definition using the canonical widget, not
/// "some other way".
const List<String> _canonicalKeywords = [
  'GlassBackButton(',
  'SheetBackButton(',
];

class NavAffordanceFinding {
  final String file; // repo-relative, posix separators, from the scan root's parent
  final int line; // 1-indexed, first line of the icon match — reporting only
  final String rule; // 'raw-icon-button' | 'bare-icon-tap'
  final String snippet; // normalized wrapper source — the baseline identity

  const NavAffordanceFinding({
    required this.file,
    required this.line,
    required this.rule,
    required this.snippet,
  });

  /// Identity used to diff against the checked-in baseline: file + rule +
  /// the (collapsed, truncated) wrapper source — NOT line number, so an
  /// unrelated edit earlier in the same file never manufactures a phantom
  /// "new" violation. Mirrors `GeometryMatch.baselineKey` in
  /// `card_geometry_scan.dart`.
  String get baselineKey => '$file $rule $snippet';

  Map<String, dynamic> toJson() => {
        'file': file,
        'line': line,
        'rule': rule,
        'snippet': snippet,
      };

  static NavAffordanceFinding fromJson(Map<String, dynamic> j) =>
      NavAffordanceFinding(
        file: j['file'] as String,
        line: (j['line'] as num?)?.toInt() ?? 0,
        rule: j['rule'] as String,
        snippet: j['snippet'] as String,
      );

  @override
  String toString() => '$file:$line  [$rule]  $snippet';
}

({int start, int end})? _balancedRange(String s, int openIdx) {
  var depth = 0;
  for (var i = openIdx; i < s.length; i++) {
    final c = s[i];
    if (c == '(') {
      depth++;
    } else if (c == ')') {
      depth--;
      if (depth == 0) return (start: openIdx, end: i + 1);
    }
  }
  return null; // unbalanced (shouldn't happen in valid Dart) — caller skips
}

/// The char index of the opening `(` for every occurrence of [keyword] (which
/// must itself end in `(`) in [src], in ascending order.
List<int> _openParenIndices(String src, String keyword) {
  final out = <int>[];
  var i = 0;
  while (true) {
    final idx = src.indexOf(keyword, i);
    if (idx == -1) break;
    out.add(idx + keyword.length - 1);
    i = idx + 1;
  }
  return out;
}

String _normalizeSnippet(String block) {
  final collapsed = block.replaceAll(RegExp(r'\s+'), ' ').trim();
  return collapsed.length > 160 ? collapsed.substring(0, 160) : collapsed;
}

/// Matches any `identifier(` shape — used by Rule D to find the nearest
/// enclosing widget/function CALL (any name), not just the known
/// IconButton/GestureDetector/InkWell keywords. See `_isDirectIconParam`.
final RegExp _anyCallRe = RegExp(r'[A-Za-z_][A-Za-z0-9_.]*\s*\(');

/// True when [idx] (the start of an `Icons.xxx` match in [src]) is the value
/// — or a ternary branch of the value — of a named `icon:` argument, e.g.
/// `icon: Icons.arrow_back_rounded` or
/// `icon: cond ? Icons.arrow_back_rounded : Icons.arrow_back_rounded`. Walks
/// backward from [idx] to the start of the enclosing call argument (the
/// nearest un-nested `,` or `(`), tracking paren depth so a nested call
/// inside the SAME argument doesn't fool the boundary search, then checks
/// the argument text against the `icon:` shapes above.
bool _isDirectIconParam(String src, int idx) {
  var depth = 0;
  var i = idx - 1;
  while (i >= 0) {
    final c = src[i];
    if (c == ')') {
      depth++;
    } else if (c == '(') {
      if (depth == 0) break;
      depth--;
    } else if (c == ',' && depth == 0) {
      break;
    }
    i--;
  }
  final argText = src.substring(i + 1, idx);
  return RegExp(r'^\s*icon\s*:\s*$').hasMatch(argText) ||
      RegExp(r'icon\s*:\s*[^,()]*\?[^,()]*:\s*$').hasMatch(argText);
}

/// Scans one file's already-read [src] for violations. [relPath] is what
/// gets stored on each finding (repo-relative, e.g. `lib/screens/...`).
List<NavAffordanceFinding> scanSource(String src, String relPath) {
  final findings = <NavAffordanceFinding>[];

  // Pre-index the exemption-ancestor ranges once per file.
  final dialogRanges = <({int start, int end})>[
    for (final kw in _dialogKeywords)
      for (final open in _openParenIndices(src, kw))
        if (_balancedRange(src, open) != null) _balancedRange(src, open)!,
  ];
  final canonicalRanges = <({int start, int end})>[
    for (final kw in _canonicalKeywords)
      for (final open in _openParenIndices(src, kw))
        if (_balancedRange(src, open) != null) _balancedRange(src, open)!,
  ];
  final wrapperOpens = <String, List<int>>{
    for (final kw in _wrapperKeywords) kw: _openParenIndices(src, kw),
  };

  // Every literal `Icon(...)` call's balanced range — used to distinguish
  // "wrapped in an Icon widget" matches (the common shape: Rules A/B below)
  // from "passed as a bare IconData literal straight to some other widget's
  // `icon:` param" matches (Rule D — see `_isDirectIconParam`). `\bIcon\(`
  // deliberately does NOT match `IconButton(` (no `(` immediately after
  // "Icon" there) or `IconData(`.
  final iconWidgetRanges = <({int start, int end})>[
    for (final open in _openParenIndices(src, 'Icon('))
      if (RegExp(r'\bIcon\($').hasMatch(src.substring(0, open + 1)) &&
          _balancedRange(src, open) != null)
        _balancedRange(src, open)!,
  ];

  // Every `Identifier(` call's open-paren index, for Rule D's "find the
  // nearest enclosing widget constructor" search — deliberately unfiltered
  // (matches every function/constructor call in the file); cheap because
  // Rule D only runs for the rare bare-icon-literal candidates.
  final anyCallOpens = <int>[
    for (final m in _anyCallRe.allMatches(src)) m.end - 1,
  ];

  for (final m in _backIconRe.allMatches(src)) {
    final idx = m.start;
    final iconName = m.group(1)!;

    if (dialogRanges.any((r) => idx >= r.start && idx < r.end)) continue;
    if (canonicalRanges.any((r) => idx >= r.start && idx < r.end)) continue;

    final bareOfIconWidget =
        !iconWidgetRanges.any((r) => idx >= r.start && idx < r.end);

    String? bestKw;
    var bestOpen = -1;
    ({int start, int end})? bestRange;

    if (bareOfIconWidget && _isDirectIconParam(src, idx)) {
      // Rule D: `icon: Icons.arrow_back_rounded` (optionally through a
      // simple ternary) passed straight to a bespoke widget's `icon:`
      // param — e.g. `_TopBarButton(icon: Icons.arrow_back_rounded, ...)`
      // in workout_top_bar_v2.dart. Find the nearest enclosing constructor
      // call of ANY name (not just the IconButton/GestureDetector/InkWell
      // list) — that widget IS the "some other way" back control.
      for (final open in anyCallOpens) {
        if (open >= idx) break;
        if (open <= bestOpen) continue;
        final r = _balancedRange(src, open);
        if (r == null) continue;
        if (idx >= r.start && idx < r.end) {
          bestOpen = open;
          bestRange = r;
        }
      }
      if (bestRange != null) bestKw = 'IconButton('; // buckets with Rule A below
    } else {
      // Rules A/B: nearest enclosing tappable wrapper = the candidate whose
      // balanced range contains idx AND whose open-paren is the largest
      // (i.e. the innermost of the candidates that actually enclose the
      // match).
      for (final kw in _wrapperKeywords) {
        for (final open in wrapperOpens[kw]!) {
          if (open >= idx) break; // opens are ascending; none further can enclose idx
          if (open <= bestOpen) continue; // can't be more inner than what we have
          final r = _balancedRange(src, open);
          if (r == null) continue;
          if (idx >= r.start && idx < r.end) {
            bestOpen = open;
            bestKw = kw;
            bestRange = r;
          }
        }
      }
    }
    if (bestKw == null || bestRange == null) continue; // no classifiable wrapper — skip

    final blockText = src.substring(bestRange.start, bestRange.end);
    if (!_isViolationWrapper(iconName, blockText)) continue;

    final rule = bestKw.startsWith('IconButton') ? 'raw-icon-button' : 'bare-icon-tap';
    final line = '\n'.allMatches(src.substring(0, idx)).length + 1;
    findings.add(NavAffordanceFinding(
      file: relPath,
      line: line,
      rule: rule,
      snippet: _normalizeSnippet(blockText),
    ));
  }

  return findings;
}

bool _isViolationWrapper(String iconName, String wrapperBlock) {
  final pagination = _paginationSignalRe.hasMatch(wrapperBlock);
  if (pagination) return false;
  if (_isStrongBackIcon(iconName)) return true;
  // chevron_left* — ambiguous; only a genuine back/pop signal makes it count.
  return _popSignalRe.hasMatch(wrapperBlock);
}

List<NavAffordanceFinding> scanFile(File f, String relPath) {
  final src = f.readAsStringSync();
  return scanSource(src, relPath);
}

/// Recursively scans every `.dart` file under [root] (default `lib/screens`,
/// run from the `mobile/flutter` package root) except the tab-root files.
List<NavAffordanceFinding> scanNavAffordanceViolations({String root = 'lib/screens'}) {
  final dir = Directory(root);
  if (!dir.existsSync()) return const [];
  final findings = <NavAffordanceFinding>[];
  for (final entity in dir.listSync(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final relPath = entity.path.replaceAll('\\', '/');
    if (kTabRootFiles.contains(relPath)) continue;
    findings.addAll(scanFile(entity, relPath));
  }
  findings.sort((a, b) {
    final c1 = a.file.compareTo(b.file);
    if (c1 != 0) return c1;
    final c2 = a.rule.compareTo(b.rule);
    if (c2 != 0) return c2;
    return a.line.compareTo(b.line);
  });
  return findings;
}

// ─────────────────────────── baseline I/O ───────────────────────────

Map<String, int> _counts(List<NavAffordanceFinding> findings) {
  final c = <String, int>{};
  for (final f in findings) {
    c[f.baselineKey] = (c[f.baselineKey] ?? 0) + 1;
  }
  return c;
}

class BaselineDiff {
  final List<NavAffordanceFinding> newFindings;
  final int grandfathered;
  final int staleBaselineEntries;
  const BaselineDiff({
    required this.newFindings,
    required this.grandfathered,
    required this.staleBaselineEntries,
  });
}

/// Loads `{file, rule, snippet, count}` entries from a baseline JSON file
/// (see `nav_affordance_baseline.json`) into a key -> count map.
Map<String, int> loadBaselineCounts(File baselineFile) {
  final data = jsonDecode(baselineFile.readAsStringSync()) as Map<String, dynamic>;
  final entries = (data['findings'] as List).cast<Map<String, dynamic>>();
  final counts = <String, int>{};
  for (final e in entries) {
    final key = '${e['file']} ${e['rule']} ${e['snippet']}';
    counts[key] = (counts[key] ?? 0) + ((e['count'] as num?)?.toInt() ?? 1);
  }
  return counts;
}

/// Multiset diff, mirroring `audit_timezone_usage.py`'s `--check`: a current
/// finding is grandfathered if the baseline still has an unconsumed count for
/// its key; otherwise it's NEW and fails the gate.
BaselineDiff diffAgainstBaseline(
  List<NavAffordanceFinding> current,
  Map<String, int> baselineCounts,
) {
  final remaining = Map<String, int>.from(baselineCounts);
  final newFindings = <NavAffordanceFinding>[];
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

String encodeBaseline(List<NavAffordanceFinding> findings) {
  final counts = _counts(findings);
  // Rebuild one representative finding per key for its file/rule/snippet.
  final byKey = <String, NavAffordanceFinding>{};
  for (final f in findings) {
    byKey[f.baselineKey] = f;
  }
  final entries = counts.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  final payload = {
    '_comment': 'Grandfathered nav-affordance-gate findings (screens that '
        'build a back-navigation icon some way OTHER than GlassBackButton — '
        'see nav_affordance_scan.dart doc comment). '
        '`nav_affordance_gate_test.dart` fails only on findings NOT listed '
        'here, so the known ~50/50 backlog cannot grow. Keyed by file + rule '
        '+ matched wrapper source (not line numbers — those churn on every '
        'unrelated edit). Regenerate with '
        '`dart run test/ui_gates/nav_affordance_scan.dart > '
        'test/ui_gates/nav_affordance_baseline.json` after intentionally '
        'fixing (or intentionally accepting) findings — never hand-edit to '
        'silence a fresh violation.',
    'total': findings.length,
    'findings': [
      for (final e in entries)
        {
          'file': byKey[e.key]!.file,
          'rule': byKey[e.key]!.rule,
          'snippet': byKey[e.key]!.snippet,
          'count': e.value,
        },
    ],
  };
  return const JsonEncoder.withIndent('  ').convert(payload);
}

/// Standalone entry point: `dart run test/ui_gates/nav_affordance_scan.dart`
/// re-scans the real tree and prints the current violation set as the exact
/// JSON shape `nav_affordance_baseline.json` expects — the `--refresh`
/// path. Pipe it to the baseline file after a deliberate cleanup pass:
///   dart run test/ui_gates/nav_affordance_scan.dart \
///     > test/ui_gates/nav_affordance_baseline.json
void main() {
  final findings = scanNavAffordanceViolations();
  stdout.writeln(encodeBaseline(findings));
  stderr.writeln('${findings.length} nav-affordance violation(s) found across '
      'lib/screens/** (excluding ${kTabRootFiles.length} tab roots).');
}
