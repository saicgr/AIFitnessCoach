import 'package:flutter/material.dart';

/// NavigatorObserver that clears any visible SnackBar whenever the user
/// navigates to a different screen (push, pop, or replace of a non-modal
/// route).
///
/// A SnackBar's ScaffoldMessenger is typically hoisted well above the
/// pushed route that raised it (shared across the whole tab, or the whole
/// app), so popping back to a previous screen or pushing a new one does
/// nothing to it on its own — the toast just keeps running on its own
/// timer, or (per `widgets/main_shell.dart`'s `_onItemTapped` comment) never
/// even starts its timer if the owning branch went offstage mid-animation.
///
/// E2E register: the AI Integrations "Upgrade" toast (and, before it, the
/// Adapt toast and the fasting Recipes toast) followed the user across
/// Settings → Cycle Tracking and the main Settings list — all reached by a
/// plain push/pop within the SAME bottom-nav tab, so `_onItemTapped`'s
/// `clearSnackBars()` (which only fires on a tab switch) never ran. This
/// observer generalizes that already-accepted fix to every full-screen
/// navigation, not just bottom-nav tab switches. Undo-style snackbars are
/// unaffected by design — same reasoning as `_onItemTapped`: the underlying
/// action commits on its own timer, not on the toast's visibility.
///
/// Modal routes (bottom sheets, dialogs, popups) are deliberately excluded —
/// opening a sheet over a toast should not silently kill it, only an actual
/// screen change should.
class SnackBarClearingRouteObserver extends NavigatorObserver {
  bool _isModal(Route<dynamic>? route) {
    if (route == null) return false;
    if (route is PopupRoute) return true;
    if (route is ModalBottomSheetRoute) return true;
    if (route is DialogRoute) return true;
    if (route is RawDialogRoute) return true;
    return false;
  }

  void _clear() {
    final context = navigator?.context;
    if (context == null) return;
    // Defer past the current build/transition frame — clearing mid-push can
    // otherwise race the incoming route's own first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
      }
    });
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // The very first route (app launch) has nothing to clear, and modal
    // routes shouldn't dismiss a toast just for opening on top of it.
    if (previousRoute == null) return;
    if (_isModal(route)) return;
    _clear();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_isModal(route)) return;
    _clear();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (_isModal(newRoute) || _isModal(oldRoute)) return;
    _clear();
  }
}
