import 'package:flutter/widgets.dart';
import '../core/services/posthog_service.dart';

/// NavigatorObserver that auto-tracks screen views in PostHog
/// whenever GoRouter navigates between routes.
class PosthogRouteObserver extends NavigatorObserver {
  final PosthogService _posthog;

  PosthogRouteObserver(this._posthog);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _trackScreen(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) _trackScreen(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) _trackScreen(previousRoute);
  }

  void _trackScreen(Route<dynamic> route) {
    final name = route.settings.name;
    if (name != null && name.isNotEmpty) {
      _posthog.screen(screenName: name);
    }
  }
}
