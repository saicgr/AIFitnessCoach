import 'package:flutter/material.dart';

/// Global ScaffoldMessenger key registered on MaterialApp so background-job
/// providers can surface toasts that survive screen navigation. Wired in
/// `app.dart` via `MaterialApp.router(scaffoldMessengerKey: ...)`.
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Convenience: show a SnackBar via the root messenger from anywhere.
/// Returns the controller so callers can hide / await dismissal.
ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? rootSnackBar(
  SnackBar snackBar,
) {
  final messenger = rootScaffoldMessengerKey.currentState;
  if (messenger == null) return null;
  // Clear any in-flight snack so back-to-back toasts don't queue invisibly.
  messenger.hideCurrentSnackBar();
  return messenger.showSnackBar(snackBar);
}
