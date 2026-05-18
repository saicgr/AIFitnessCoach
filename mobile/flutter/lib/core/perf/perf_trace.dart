import 'package:flutter/foundation.dart';

/// Lightweight, dependency-free performance tracer for app-startup and
/// hot-path instrumentation (Phase B of the Home-performance plan).
///
/// Design goals:
///  - **Zero-cost in release.** Every public method short-circuits to a
///    no-op when [kReleaseMode] is true (the printing is guarded by
///    [kDebugMode]). The only release-mode work is a couple of cheap map
///    writes / int increments, which the VM/AOT compiler trims to nothing
///    meaningful. Nothing here ever throws.
///  - **Safe before init.** Callers may invoke any method before
///    [appStart] runs; the start timestamp is lazily initialized on first
///    use so deltas are always well-defined.
///  - **No external deps** beyond `flutter/foundation.dart`.
///
/// Other parts of the app call e.g. `PerfTrace.mark('home_first_content')`;
/// the API surface here must stay exactly as documented so those calls
/// continue to compile.
class PerfTrace {
  PerfTrace._(); // Static-only utility — never instantiated.

  /// Wall-clock time the app (or first trace) started. Lazily set so a
  /// `mark` before `appStart` still produces a sensible delta.
  static DateTime? _start;

  /// Timestamp of the most recent [mark], used to compute inter-mark deltas.
  static DateTime? _lastMark;

  /// Per-name cache hit/miss tallies for [cacheHit] / [cacheMiss].
  static final Map<String, int> _cacheHits = <String, int>{};
  static final Map<String, int> _cacheMisses = <String, int>{};

  /// Records the app-start reference point. Call this once, as early as
  /// possible (e.g. top of `main()`). Idempotent: a second call is ignored
  /// so a stray invocation can't reset the baseline mid-session.
  static void appStart() {
    _start ??= DateTime.now();
  }

  /// Ensures [_start] is populated. Used internally so any method is safe
  /// to call before [appStart].
  static DateTime _ensureStart() {
    return _start ??= DateTime.now();
  }

  /// Records a named milestone. In debug builds, prints the elapsed time
  /// since app start and since the previous mark, e.g.:
  ///   `⏱ [Perf] home_first_content +842ms (Δ+310ms)`
  ///
  /// In release builds this only updates [_lastMark] (cheap) and prints
  /// nothing.
  static void mark(String label) {
    final start = _ensureStart();
    final now = DateTime.now();
    final sinceStart = now.difference(start).inMilliseconds;
    // First mark has no previous mark to diff against — fall back to
    // since-start so the delta is never undefined.
    final prev = _lastMark ?? start;
    final sincePrev = now.difference(prev).inMilliseconds;
    _lastMark = now;
    if (kDebugMode) {
      debugPrint('⏱ [Perf] $label +${sinceStart}ms (Δ+${sincePrev}ms)');
    }
  }

  /// Records a cache hit for [name] and, in debug, prints the running
  /// hit/miss ratio for that name.
  static void cacheHit(String name) {
    _cacheHits[name] = (_cacheHits[name] ?? 0) + 1;
    if (kDebugMode) _printRatio(name);
  }

  /// Records a cache miss for [name] and, in debug, prints the running
  /// hit/miss ratio for that name.
  static void cacheMiss(String name) {
    _cacheMisses[name] = (_cacheMisses[name] ?? 0) + 1;
    if (kDebugMode) _printRatio(name);
  }

  /// Debug-only helper: prints the cumulative hit/miss tally and hit-rate
  /// percentage for [name]. Guarded by callers under [kDebugMode].
  static void _printRatio(String name) {
    final hits = _cacheHits[name] ?? 0;
    final misses = _cacheMisses[name] ?? 0;
    final total = hits + misses;
    // Avoid divide-by-zero — total is always >= 1 here in practice, but
    // stay defensive so this never throws.
    final pct = total == 0 ? 0 : (hits * 100 / total).round();
    debugPrint('⏱ [Perf] cache "$name": $hits hit / $misses miss ($pct%)');
  }
}
