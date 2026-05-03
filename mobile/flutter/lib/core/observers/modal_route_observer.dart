import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/workout_mini_player_provider.dart';

/// NavigatorObserver that tracks whether any modal route (bottom sheet,
/// dialog, popup) is currently on top of the stack and flips the workout
/// mini-player's `suppressedForModal` flag so the pill is hidden under
/// sheets/dialogs.
///
/// The mini-player overlay mounts in `MaterialApp.router.builder` — above
/// the Navigator — so it correctly floats across routes but wrongly floats
/// above modal routes pushed on the Navigator's Overlay. Rather than move
/// the overlay into the Navigator (which would lose cross-route
/// persistence), we hide it while a modal is active.
class WorkoutMiniPlayerRouteObserver extends NavigatorObserver {
  WorkoutMiniPlayerRouteObserver(this._ref);

  final Ref _ref;
  int _activeModalCount = 0;

  bool _isModal(Route<dynamic>? route) {
    if (route is PopupRoute) return true;
    if (route is ModalBottomSheetRoute) return true;
    if (route is DialogRoute) return true;
    if (route is RawDialogRoute) return true;
    return false;
  }

  void _sync() {
    // NavigatorObserver callbacks (didPush/didPop/didRemove/didReplace)
    // fire synchronously during a Navigator update — which itself runs
    // inside the widget build phase. Mutating a Riverpod StateNotifier
    // during build is illegal (StateNotifierListenerError → "Tried to
    // modify a provider while the widget tree was building"). Defer
    // the mutation to a post-frame callback so it lands after the
    // current build completes.
    final shouldSuppress = _activeModalCount > 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final notifier =
            _ref.read(workoutMiniPlayerProvider.notifier);
        notifier.setSuppressedForModal(shouldSuppress);
      } catch (_) {
        // Provider container may have been torn down (sign-out, full
        // reset) between the navigator event and the post-frame tick.
        // Swallow — the next push/pop will re-sync if it still exists.
      }
    });
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_isModal(route)) {
      _activeModalCount++;
      _sync();
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_isModal(route)) {
      _activeModalCount = (_activeModalCount - 1).clamp(0, 1000);
      _sync();
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_isModal(route)) {
      _activeModalCount = (_activeModalCount - 1).clamp(0, 1000);
      _sync();
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final wasModal = _isModal(oldRoute);
    final isModal = _isModal(newRoute);
    if (wasModal && !isModal) {
      _activeModalCount = (_activeModalCount - 1).clamp(0, 1000);
      _sync();
    } else if (!wasModal && isModal) {
      _activeModalCount++;
      _sync();
    }
  }
}
