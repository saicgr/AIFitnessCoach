import 'dart:async';

import 'package:flutter/material.dart';

/// Global ScaffoldMessenger key registered on MaterialApp so background-job
/// providers can surface toasts that survive screen navigation. Wired in
/// `app.dart` via `MaterialApp.router(scaffoldMessengerKey: ...)`.
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Slack added to a SnackBar's own duration before the wall-clock backstop
/// fires. Covers the entrance animation plus margin, so the backstop only
/// ever acts when the normal dismissal has genuinely failed.
const Duration kRootSnackBarBackstopMargin = Duration(milliseconds: 1500);

/// Convenience: show a SnackBar via the root messenger from anywhere.
/// Returns the controller so callers can hide / await dismissal.
///
/// A SnackBar's auto-dismiss timer does NOT run on a wall clock — it starts
/// only once the entrance animation completes. So anything that freezes that
/// animation pins the toast on screen indefinitely. The known trigger is
/// `TickerMode`: when a branch of the shell's `IndexedStack` goes offstage its
/// tickers freeze, a toast mid-entrance never finishes entering, and its
/// dismissal timer therefore never starts.
///
/// Because this is the ROOT messenger, such a toast then outlives everything:
/// it sits above the navigator by design, so it survives sub-tab switches and
/// full-screen pushes alike. Observed on device — a "Logged …" confirmation
/// still up **13 minutes** later, on an unrelated screen, covering the very
/// row it was announcing.
///
/// `MainShell` already calls `clearSnackBars()` when the bottom-nav tab
/// changes, but that is one chokepoint of several: it does not fire on a
/// sub-tab switch or a route push, which is exactly how the observed banner
/// survived. The backstop therefore lives here, where all callers pass.
ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? rootSnackBar(
  SnackBar snackBar,
) {
  final messenger = rootScaffoldMessengerKey.currentState;
  if (messenger == null) return null;
  // Clear any in-flight snack so back-to-back toasts don't queue invisibly.
  messenger.hideCurrentSnackBar();
  final controller = messenger.showSnackBar(snackBar);

  // Wall-clock backstop — independent of the entrance animation, so a frozen
  // ticker cannot defeat it.
  var closed = false;
  Timer? backstop;

  // Cancel on normal dismissal rather than letting the timer fire into a
  // closed controller: one dangling timer per toast is untidy in production
  // and trips the "Timer is still pending" assertion in widget tests.
  void onClosed(_) {
    closed = true;
    backstop?.cancel();
    backstop = null;
  }

  controller.closed.then(onClosed).catchError(onClosed);

  backstop = Timer(snackBar.duration + kRootSnackBarBackstopMargin, () {
    backstop = null;
    if (closed) return;
    closed = true;
    // The controller may already be tearing down. Closing a finished
    // controller throws, and this is a background timer with no one to catch.
    try {
      controller.close();
    } catch (_) {
      // Already gone — which is the outcome we wanted anyway.
    }
  });

  return controller;
}
