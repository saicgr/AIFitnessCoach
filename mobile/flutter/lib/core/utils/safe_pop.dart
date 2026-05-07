import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Safe alternatives to [BuildContext.pop] / [Navigator.pop].
///
/// Why this exists
/// ---------------
/// `context.pop()` and `Navigator.pop` throw a hard "There is nothing to pop"
/// assertion when the navigation stack is empty. Real-world ways the stack
/// ends up empty when a `pop()` is fired:
///
/// 1. The user double-taps a back button → first tap pops, second fires on
///    an empty stack.
/// 2. A coach push notification deep-links straight into a detail screen,
///    making the detail screen the root → user taps "back" → empty stack.
/// 3. Async work resolves AFTER the screen was already popped and tries to
///    pop one more time (e.g. `await save(); if (mounted) context.pop();`
///    when the user manually backed out during the await).
///
/// None of these are bugs the user should see — they are normal navigation
/// races. Throwing an assertion for them turns "user pressed back twice"
/// into a Sentry FATAL. Sentry incident `FITWIZ-FLUTTER-71` was the first
/// one we patched; `FITWIZ-FLUTTER-8D` (2026-05-07) was another from the
/// same class on a different screen.
///
/// We intentionally don't patch every individual `context.pop()` site
/// (953+ across the app) — that's the prompt-stacking anti-pattern. Instead
/// callers can opt into [SafePopExtension.safePop] when the no-op behaviour
/// matters, or rely on the global Sentry filter in `main.dart` that drops
/// the assertion entirely.
extension SafePopExtension on BuildContext {
  /// Pop the route stack only when there is something to pop.
  ///
  /// If the stack is empty, returns `false` and does nothing — the caller
  /// can decide whether to fall through to a `go('/home')` or similar.
  /// Mirrors the shape of `Navigator.maybePop` but uses go_router's
  /// `canPop()` so it stays consistent with our app router.
  bool safePop<T>([T? result]) {
    if (canPop()) {
      pop(result);
      return true;
    }
    return false;
  }

  /// Pop if possible, otherwise navigate to [fallbackLocation] (typically
  /// `/home`). Useful for top-of-flow screens that may be deep-linked into.
  void safePopOrGo(String fallbackLocation, {Object? extra}) {
    if (canPop()) {
      pop();
    } else {
      go(fallbackLocation, extra: extra);
    }
  }
}
