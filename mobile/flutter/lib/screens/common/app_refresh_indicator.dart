import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/api_client.dart';

/// Pull-to-refresh for this app. Use this everywhere instead of Material's
/// [RefreshIndicator].
///
/// ## Why this exists
///
/// `ApiClient.get` coalesces identical in-flight GETs GLOBALLY: while a GET is
/// on the wire, a second identical GET rides it instead of opening a new
/// request. That is right for two widgets asking for one resource in the same
/// frame, and WRONG for a pull-to-refresh — the user's explicit "give me
/// current data" would be answered by a request that was already in flight
/// before they pulled. Pull-to-refresh would spin and hand back the exact
/// payload the user just rejected.
///
/// `ApiClient.beginUserInitiatedRefresh()` is the opt-out (it moves the
/// mutation epoch, so every GET issued from that point opens its own request
/// while GETs issued *within* the refresh still coalesce with each other).
/// Before this widget, that opt-out was called from 2 of the 96 files
/// containing a `RefreshIndicator` — on the other 94 screens, pull-to-refresh
/// could silently not refresh.
///
/// ## Why this is the chokepoint
///
/// `RefreshIndicatorState` reaches `onRefresh` exactly one way: `_show()` calls
/// `widget.onRefresh()`, for both the drag gesture and the programmatic
/// `RefreshIndicatorState.show()`. Wrapping that one callback therefore covers
/// every refresh this widget can start — there is no second entry point to
/// miss, and screens cannot forget to opt out because they no longer make the
/// call themselves.
///
/// Coverage is total rather than best-effort because it is enforced, not
/// assumed: `test/services/api_client_get_coalescing_test.dart` scans `lib/`
/// and fails if a raw `RefreshIndicator(` exists anywhere outside this file.
/// A new screen that reaches for Material's widget breaks the build gate.
///
/// Nothing about painting changes: the epoch bump is a synchronous integer
/// increment before [onRefresh] runs, so cache-first paints and
/// stale-while-revalidate behaviour are untouched — the refresh just cannot be
/// served by a pre-pull request.
///
/// The constructor mirrors [RefreshIndicator]'s default (material) constructor
/// exactly, so migrating a call site is a rename and nothing else.
class AppRefreshIndicator extends ConsumerWidget {
  const AppRefreshIndicator({
    super.key,
    this.displacement = 40.0,
    this.edgeOffset = 0.0,
    required this.onRefresh,
    this.color,
    this.backgroundColor,
    this.notificationPredicate = defaultScrollNotificationPredicate,
    this.semanticsLabel,
    this.semanticsValue,
    this.strokeWidth = RefreshProgressIndicator.defaultStrokeWidth,
    this.triggerMode = RefreshIndicatorTriggerMode.onEdge,
    this.elevation = 2.0,
    required this.child,
  });

  final double displacement;
  final double edgeOffset;
  final RefreshCallback onRefresh;
  final Color? color;
  final Color? backgroundColor;
  final ScrollNotificationPredicate notificationPredicate;
  final String? semanticsLabel;
  final String? semanticsValue;
  final double strokeWidth;
  final RefreshIndicatorTriggerMode triggerMode;
  final double elevation;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The ONE place Material's RefreshIndicator may be constructed.
    return RefreshIndicator(
      displacement: displacement,
      edgeOffset: edgeOffset,
      onRefresh: () {
        // Open the barrier BEFORE the handler's first network call, and
        // synchronously, so no GET issued by the handler can be answered by a
        // request that was already on the wire when the user pulled.
        ref.read(apiClientProvider).beginUserInitiatedRefresh();
        return onRefresh();
      },
      color: color,
      backgroundColor: backgroundColor,
      notificationPredicate: notificationPredicate,
      semanticsLabel: semanticsLabel,
      semanticsValue: semanticsValue,
      strokeWidth: strokeWidth,
      triggerMode: triggerMode,
      elevation: elevation,
      child: child,
    );
  }
}
