/// Part 1 of the instant-load standard — the [CacheFirstView] widget.
///
/// The UI counterpart to `CacheFirstMixin`. It encodes the instant-load
/// contract so a screen never shows a blocking spinner:
///
///   * On a TRUE first-ever open (no cache has ever existed for this screen)
///     it shows a layout-matched SKELETON — never a centered `CircularProgress`.
///   * On every subsequent open it shows the cached / fresh content INSTANTLY.
///   * skeleton → content and stale → fresh transitions cross-fade via an
///     `AnimatedSwitcher` so the swap is smooth, not a hard cut.
///
/// It is generic over the data type [T] and consumes an [AsyncValue<T>] (the
/// type a Riverpod `FutureProvider` / `StateNotifier<AsyncValue<T>>` exposes),
/// so it drops straight onto existing Riverpod screens.
///
/// ---------------------------------------------------------------------------
/// USAGE EXAMPLE
/// ---------------------------------------------------------------------------
/// ```dart
/// final stepsAsync = ref.watch(stepsProvider);
///
/// CacheFirstView<StepsData>(
///   value: stepsAsync,
///   // True only the very first time this screen is opened on this install.
///   // Persist a bool in SharedPreferences and flip it after the first
///   // successful load (see CacheFirstView.firstEverFlag helper below).
///   isFirstEver: !hasOpenedStepsBefore,
///   traceLabel: 'steps_screen',
///   skeletonBuilder: (context) => const SkeletonList(itemCount: 4),
///   contentBuilder: (context, steps) => StepsBody(steps: steps),
///   errorBuilder: (context, err, st) => RetryTile(onRetry: _reload),
/// );
/// ```
///
/// Why `isFirstEver` instead of just checking `value.isLoading`? Because a
/// returning user ALWAYS has a cached value to show — they should never see a
/// skeleton again. The skeleton is exclusively a cold-install affordance.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../perf/perf_trace.dart';

/// Cross-fade duration for skeleton→content and stale→fresh swaps.
const Duration _kCrossFade = Duration(milliseconds: 260);

/// A cache-first, skeleton-on-first-open content host.
///
/// See the library doc for the rationale. Behaviour matrix:
///
/// | state                         | what renders                       |
/// |-------------------------------|-------------------------------------|
/// | has data (cached OR fresh)    | [contentBuilder]                    |
/// | loading, [isFirstEver] true   | [skeletonBuilder]                   |
/// | loading, [isFirstEver] false  | last data if any, else skeleton     |
/// | error, has previous data      | previous [contentBuilder] (kept)    |
/// | error, no data                | [errorBuilder] (or skeleton)        |
///
/// Never renders a blocking spinner.
class CacheFirstView<T> extends StatefulWidget {
  /// The async state to render. Typically `ref.watch(someProvider)`.
  final AsyncValue<T> value;

  /// True ONLY on a genuine first-ever open of this screen on this install.
  /// When false, a loading state with no data still falls back to the skeleton
  /// (there is genuinely nothing else to show) — but in practice a returning
  /// user's provider is seeded from cache, so this rarely happens.
  final bool isFirstEver;

  /// Builds the layout-matched skeleton. Should mirror [contentBuilder]'s
  /// shape so the cross-fade doesn't reflow.
  final WidgetBuilder skeletonBuilder;

  /// Builds the real content from a resolved value.
  final Widget Function(BuildContext context, T data) contentBuilder;

  /// Builds an error affordance when there is an error AND no data to fall
  /// back to. When null, the skeleton is shown instead (the silent revalidate
  /// will eventually resolve, or a pull-to-refresh will).
  final Widget Function(BuildContext context, Object error, StackTrace? st)?
      errorBuilder;

  /// Label for the `PerfTrace.mark` fired when the first real content paints.
  /// Emits `cachefirstview:<label>:first_content`. Null → no trace.
  final String? traceLabel;

  const CacheFirstView({
    super.key,
    required this.value,
    required this.isFirstEver,
    required this.skeletonBuilder,
    required this.contentBuilder,
    this.errorBuilder,
    this.traceLabel,
  });

  /// Convenience: read whether this screen has ever been opened.
  ///
  /// Stores a bool under `cachefirstview_seen::<screenKey>`. A screen reads
  /// this once in `initState` to compute [isFirstEver], then calls
  /// [markSeen] after its first successful load.
  static Future<bool> hasBeenSeen(String screenKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('cachefirstview_seen::$screenKey') ?? false;
    } catch (_) {
      // On error, assume seen → never trap a user behind a skeleton.
      return true;
    }
  }

  /// Convenience: record that [screenKey] has now been opened, so future
  /// opens compute `isFirstEver == false`. Call after the first content load.
  static Future<void> markSeen(String screenKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('cachefirstview_seen::$screenKey', true);
    } catch (_) {/* best-effort */}
  }

  @override
  State<CacheFirstView<T>> createState() => _CacheFirstViewState<T>();
}

class _CacheFirstViewState<T> extends State<CacheFirstView<T>> {
  /// Last successfully-resolved value — kept so a transient error or a silent
  /// reload never blanks the screen back to a skeleton.
  T? _lastData;

  /// Whether the first-content `PerfTrace.mark` has already fired.
  bool _tracedFirstContent = false;

  @override
  void initState() {
    super.initState();
    _captureData();
  }

  @override
  void didUpdateWidget(covariant CacheFirstView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _captureData();
  }

  /// Latch the most recent non-error data so it survives reload/error states.
  void _captureData() {
    final data = widget.value.valueOrNull;
    if (data != null) {
      _lastData = data;
      if (!_tracedFirstContent && widget.traceLabel != null) {
        _tracedFirstContent = true;
        PerfTrace.mark('cachefirstview:${widget.traceLabel}:first_content');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = _resolveChild(context);
    // Cross-fade every swap: skeleton→content and stale→fresh. The ValueKey
    // ensures AnimatedSwitcher actually animates when the logical state flips.
    return AnimatedSwitcher(
      duration: _kCrossFade,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: KeyedSubtree(key: ValueKey(child.runtimeType), child: child),
    );
  }

  /// Pick what to render per the behaviour matrix in the class doc.
  Widget _resolveChild(BuildContext context) {
    // 1. Fresh / cached data resolved → content. Always preferred.
    final data = widget.value.valueOrNull ?? _lastData;
    if (data != null) {
      return widget.contentBuilder(context, data);
    }

    // 2. Error with no data to fall back to.
    if (widget.value.hasError) {
      final eb = widget.errorBuilder;
      if (eb != null) {
        return eb(context, widget.value.error!, widget.value.stackTrace);
      }
      // No error builder → show the skeleton; the silent revalidate or a
      // pull-to-refresh resolves it. Better than a dead-end error screen.
      return widget.skeletonBuilder(context);
    }

    // 3. Loading with no data. Skeleton on a true first-ever open; also the
    //    skeleton when !isFirstEver but genuinely nothing is cached yet (rare
    //    — cache-first providers seed from disk before first build).
    if (kDebugMode && !widget.isFirstEver) {
      debugPrint(
        '⚠️ [CacheFirstView] "${widget.traceLabel ?? T.toString()}" is '
        'loading with no cached data on a non-first open — the provider may '
        'not be wired cache-first.',
      );
    }
    return widget.skeletonBuilder(context);
  }
}
