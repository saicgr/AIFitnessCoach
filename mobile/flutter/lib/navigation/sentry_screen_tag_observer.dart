import 'package:flutter/widgets.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// NavigatorObserver that pins the current route name onto the Sentry scope
/// as `screen` + `route` tags. The default `SentryNavigatorObserver` only
/// emits breadcrumbs and (optionally) starts a transaction; framework
/// asserts like RenderFlex overflow / FractionallySizedBox infinite-width
/// arrive *without* a transaction, so the Sentry issue list can't tell you
/// which screen they fired on. Tags solve that — they're indexed and
/// searchable in the issue list directly.
///
/// Wired into `routerProvider.observers` in `app_router.dart` alongside
/// PostHog + Sentry's own observer.
class SentryScreenTagObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _setScopeForRoute(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) _setScopeForRoute(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) _setScopeForRoute(previousRoute);
  }

  void _setScopeForRoute(Route<dynamic> route) {
    final name = route.settings.name;
    if (name == null || name.isEmpty) return;
    // Fire-and-forget: configureScope is async but we don't need to block
    // navigation on the tag write landing. Worst case: an event fired in
    // the same frame as the push lands tagged with the previous screen,
    // which is still useful triage data.
    // ignore: discarded_futures
    Sentry.configureScope((scope) {
      scope.setTag('screen', name);
      scope.setTag('route', name);
    });
  }
}
