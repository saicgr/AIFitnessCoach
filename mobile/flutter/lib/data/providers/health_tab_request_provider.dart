/// Health-tab sub-navigation request — a nonce-carrying signal so a caller
/// (a `/health?tab=sleep` deep link, a push notification, a home card) can ask
/// the already-mounted `HealthShellScreen` to switch its rail chip even when
/// the *value* of the target index has not changed.
///
/// Why a nonce: the Health branch lives in the shell's `IndexedStack` and is
/// kept alive, so navigating to `/health?tab=sleep` a second time delivers the
/// same `initialTab` and a plain value-equality check (`didUpdateWidget` /
/// `ref.listen` on the bare index) cannot distinguish "new tap" from an
/// incidental rebuild. Bumping [seq] on every request makes each request a
/// distinct, observable event — so a second deep link still snaps the rail
/// back after the user manually moved it.
///
/// Mirrors `you_hub_tab_request_provider.dart`, which solves the identical
/// problem for the You hub's top-tabs.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// An immutable rail-switch request. [index] is the target sub-tab
/// (0 = Overview, 1 = Sleep, 2 = Recovery, 3 = Vitals, 4 = Body); [seq]
/// increments on every request so repeats for the same [index] are still
/// observed.
class HealthTabRequest {
  final int index;
  final int seq;
  const HealthTabRequest(this.index, this.seq);
}

class HealthTabRequestNotifier extends StateNotifier<HealthTabRequest?> {
  HealthTabRequestNotifier() : super(null);

  /// Request a switch to [index]. Bumps the sequence so the listener fires
  /// even when [index] equals the last requested index.
  void requestTab(int index) {
    final nextSeq = (state?.seq ?? 0) + 1;
    state = HealthTabRequest(index, nextSeq);
  }
}

/// Null until the first request. `HealthShellScreen` seeds its initial chip
/// from this in `initState` and listens for subsequent requests in `build`.
final healthTabRequestProvider =
    StateNotifierProvider<HealthTabRequestNotifier, HealthTabRequest?>(
  (ref) => HealthTabRequestNotifier(),
);
