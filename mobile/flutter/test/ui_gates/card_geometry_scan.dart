/// Pure scanning/classification core for the card-geometry consistency gate
/// (`card_geometry_gate_test.dart`). Split into its own library (no
/// `flutter_test` dependency — pure `dart:io`/`dart:convert`) so the exact
/// same logic can be:
///   1. run by the actual gate test (`_scanRoots` = real `lib/screens`,
///      `lib/widgets`), and
///   2. run by the "prove it can fail" self-test against a scratch temp
///      directory, and
///   3. run standalone (`dart run test/ui_gates/card_geometry_scan.dart`) to
///      regenerate the checked-in baseline after a deliberate cleanup pass.
///
/// ── What this catches ──────────────────────────────────────────────────
/// `BorderRadius.circular(N)` / `Radius.circular(N)` (radius) and
/// `EdgeInsets.all(N)` (uniform "card-level" padding — see scope note below)
/// anywhere under `lib/screens/**` and `lib/widgets/**`.
///
/// ── Scope note: why only `EdgeInsets.all()` ────────────────────────────
/// `EdgeInsets.symmetric(horizontal: X, vertical: Y)` / `.only(...)` /
/// `.fromLTRB(...)` encode two (or four) independently-tuned axis values —
/// there is no single number to compare against "the card two rows up".
/// `EdgeInsets.all(N)` is the one form that IS a single scalar "this card's
/// padding is N", which is exactly the shape of the reported defect
/// (`padding: 13` vs the neighbors' `padding: 14`). A scan of
/// `EdgeInsets.symmetric(horizontal: X, vertical: X)` (literal equal args)
/// found only 66 sites across the whole tree (vs. 2,331 `.symmetric` calls
/// total) — too small a slice to justify the added complexity of folding it
/// into the "card padding" scale; left as a documented follow-up rather than
/// silently mixed in.
///
/// ── Dominant-value / tolerance rule ─────────────────────────────────────
/// "Established" values are derived from the histogram itself, not assumed:
/// any literal used `kEstablishedMinCount` (50) or more times anywhere in
/// `lib/screens/**` + `lib/widgets/**`. That threshold sits in a real gap in
/// both histograms — every value below it drops to <70% of the next value up
/// (radius: 52 → 33; padding: 50 → 33) — so it is not a number picked to hit
/// a target list, it is the natural elbow.
///
/// A non-established value V is a "near miss" (violation) iff its distance
/// to the NEAREST established value is `> 0` and `<= kNearMissTolerance`
/// (3). Tolerance 3 was chosen because the app's real grid step is 2 (the
/// established set contains ..., 12, 14, 16, 18, 20, ... at that spacing) —
/// so any off-grid value sits at most 1 away from a true grid line, while a
/// genuinely distinct convention deliberately spaced a full grid step (4)
/// away — 24 vs. 28, or the 99/9999 vs. the established 999 pill radius —
/// lands at distance >= 4 and is correctly left alone. Tolerance 3 also
/// clears 26 and 27 (between the established 24 and 28) as ambiguous
/// "sits between two real anchors" drift, worth a human look even though
/// they're not off-by-exactly-one.
library;

import 'dart:convert';
import 'dart:io';

/// Histogram elbow — see doc comment above. Values at or above this many
/// occurrences (summed across BOTH categories are scored separately) are
/// treated as a deliberate app convention, not drift.
const int kEstablishedMinCount = 50;

/// Max distance (in logical pixels) from an established value for a
/// non-established value to be flagged as a near-miss. See doc comment.
const double kNearMissTolerance = 3.0;

/// Values below this are not card geometry — hairlines, badge insets,
/// indicator dots, icon padding. Scoring them as "near-misses" produced 178 of
/// this gate's 317 initial findings and zero actionable ones.
const double kCardGeometryFloor = 8;

enum GeometryKind { radius, padding }

final RegExp radiusPattern = RegExp(
    r'(?:BorderRadius\.circular|Radius\.circular)\(\s*([0-9]+(?:\.[0-9]+)?)\s*\)');
final RegExp paddingAllPattern =
    RegExp(r'EdgeInsets\.all\(\s*([0-9]+(?:\.[0-9]+)?)\s*\)');

class GeometryMatch {
  final GeometryKind kind;
  final String file; // repo-relative, posix separators
  final int line; // 1-indexed
  final double value;
  final String lineText; // trimmed source line the match was found on

  const GeometryMatch({
    required this.kind,
    required this.file,
    required this.line,
    required this.value,
    required this.lineText,
  });

  /// Identity used to diff against the checked-in baseline. File + kind +
  /// exact (trimmed) line text — NOT line number, so an unrelated edit
  /// earlier in the same file (which shifts every line below it) never
  /// manufactures a phantom "new" violation. Only editing/adding/removing a
  /// matching line itself changes this key, which is exactly when the
  /// baseline SHOULD be revisited.
  String get baselineKey => '$file::${kind.name}::$lineText';

  Map<String, dynamic> toJson() => {
        'file': file,
        'kind': kind.name,
        'line': line,
        'value': value,
        'lineText': lineText,
      };

  static GeometryMatch fromJson(Map<String, dynamic> j) => GeometryMatch(
        kind: GeometryKind.values.byName(j['kind'] as String),
        file: j['file'] as String,
        line: j['line'] as int,
        value: (j['value'] as num).toDouble(),
        lineText: j['lineText'] as String,
      );
}

/// Recursively scans every `.dart` file under each of [roots] for
/// [radiusPattern] / [paddingAllPattern] matches, line by line (both
/// patterns are single-line in practice across this codebase — verified via
/// `grep -n 'circular($'` / `'EdgeInsets\.all($'` returning zero hits — so
/// line-based scanning is both simpler and faster than a full-file offset
/// walk, and still gives an exact, reportable line number for free).
List<GeometryMatch> scanDirs(List<String> roots) {
  final matches = <GeometryMatch>[];
  for (final root in roots) {
    final dir = Directory(root);
    if (!dir.existsSync()) continue;
    for (final entry in dir.listSync(recursive: true, followLinks: false)) {
      if (entry is! File || !entry.path.endsWith('.dart')) continue;
      final relPath = entry.path.replaceAll('\\', '/');
      final lines = entry.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        for (final m in radiusPattern.allMatches(line)) {
          matches.add(GeometryMatch(
            kind: GeometryKind.radius,
            file: relPath,
            line: i + 1,
            value: double.parse(m.group(1)!),
            lineText: line.trim(),
          ));
        }
        for (final m in paddingAllPattern.allMatches(line)) {
          matches.add(GeometryMatch(
            kind: GeometryKind.padding,
            file: relPath,
            line: i + 1,
            value: double.parse(m.group(1)!),
            lineText: line.trim(),
          ));
        }
      }
    }
  }
  return matches;
}

/// value -> occurrence count, for one [kind], across [matches].
Map<double, int> histogramFor(List<GeometryMatch> matches, GeometryKind kind) {
  final h = <double, int>{};
  for (final m in matches) {
    if (m.kind != kind) continue;
    h[m.value] = (h[m.value] ?? 0) + 1;
  }
  return h;
}

/// The subset of [histogram]'s keys that count as a deliberate app
/// convention (>= [minCount] occurrences). See module doc comment.
Set<double> establishedValues(Map<double, int> histogram,
    {int minCount = kEstablishedMinCount}) {
  return histogram.entries
      .where((e) => e.value >= minCount)
      .map((e) => e.key)
      .toSet();
}

double _nearestDistance(double value, Set<double> established) {
  double best = double.infinity;
  for (final e in established) {
    final d = (e - value).abs();
    if (d < best) best = d;
  }
  return best;
}

/// The single closest established value to [value] (for reporting "near
/// miss of X"). Only meaningful when [established] is non-empty.
double nearestEstablished(double value, Set<double> established) {
  return established
      .reduce((a, b) => (a - value).abs() <= (b - value).abs() ? a : b);
}

/// True iff [value] is NOT itself established but sits within
/// [tolerance] of the nearest established value (and isn't exactly equal to
/// one, which would mean it IS established already, handled above).
bool isNearMiss(double value, Set<double> established,
    {double tolerance = kNearMissTolerance}) {
  if (established.isEmpty) return false;
  if (established.contains(value)) return false;
  // Below [kCardGeometryFloor] this stops being CARD geometry. Those values are
  // hairlines, badge insets, indicator dots and icon padding — a 3px inset
  // around a 13px glyph is not "a near-miss of 4", it is just a small inset,
  // and nobody can see the difference.
  //
  // This gate's own inventory made the case: of its 317 initial findings, 178
  // were sub-8px micro values (radius=1 x31, radius=7 x33, padding=2 x33,
  // padding=3 x23 ...) and only the 139 at >= 8 were actionable. Reporting the
  // other 178 trains people to ignore the gate, which costs more than the
  // drift it is trying to catch — and it already fired once on a 3px icon
  // inset that had nothing wrong with it.
  if (value < kCardGeometryFloor) return false;
  final d = _nearestDistance(value, established);
  return d > 0 && d <= tolerance;
}

/// Every [GeometryMatch] in [matches] whose value is a near-miss, given the
/// established sets derived from [matches] itself (radius and padding scored
/// independently — the two scales are not comparable to each other).
List<GeometryMatch> nearMissViolations(List<GeometryMatch> matches) {
  final radiusHist = histogramFor(matches, GeometryKind.radius);
  final paddingHist = histogramFor(matches, GeometryKind.padding);
  final radiusEstablished = establishedValues(radiusHist);
  final paddingEstablished = establishedValues(paddingHist);
  return matches.where((m) {
    final established =
        m.kind == GeometryKind.radius ? radiusEstablished : paddingEstablished;
    return isNearMiss(m.value, established);
  }).toList();
}

const List<String> defaultScanRoots = ['lib/screens', 'lib/widgets'];

/// Standalone entry point: `dart run test/ui_gates/card_geometry_scan.dart`
/// re-scans the real tree and prints the current near-miss violation set as
/// JSON — the exact shape `card_geometry_baseline.json` expects. Use after a
/// deliberate cleanup pass to regenerate the baseline (never hand-edit it to
/// silence a fresh violation).
void main() {
  final matches = scanDirs(defaultScanRoots);
  final violations = nearMissViolations(matches)
    ..sort((a, b) {
      final byFile = a.file.compareTo(b.file);
      if (byFile != 0) return byFile;
      return a.line.compareTo(b.line);
    });
  stdout.writeln(
      const JsonEncoder.withIndent('  ').convert(violations.map((v) => v.toJson()).toList()));
  stderr.writeln('${violations.length} near-miss violations across '
      '${matches.length} total geometry literals scanned.');
}
