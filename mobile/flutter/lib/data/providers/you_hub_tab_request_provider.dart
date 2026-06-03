/// You-hub tab-switch request — a nonce-carrying signal so a caller (the
/// home-header avatar, an external deep link) can ask the already-mounted
/// [YouHubScreen] to switch its top-tab even when the *value* of the target
/// index has not changed.
///
/// Why a nonce: the You branch lives in the shell's IndexedStack and is kept
/// alive, so navigating to `/profile?tab=profile` a second time delivers the
/// same `initialTabIndex` and a plain value-equality check (`didUpdateWidget`
/// / `ref.listen` on the bare index) cannot distinguish "new tap" from an
/// incidental rebuild. Bumping [seq] on every request makes each request a
/// distinct, observable event — so tapping the avatar after the user manually
/// swiped to Overview still snaps back to Profile.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// An immutable tab-switch request. [index] is the target top-tab
/// (0 = Overview, 1 = Profile, 2 = Stats & Rewards); [seq] increments on
/// every request so repeats for the same [index] are still observed.
class YouHubTabRequest {
  final int index;
  final int seq;
  const YouHubTabRequest(this.index, this.seq);
}

class YouHubTabRequestNotifier extends StateNotifier<YouHubTabRequest?> {
  YouHubTabRequestNotifier() : super(null);

  /// Request a switch to [index]. Bumps the sequence so the listener fires
  /// even when [index] equals the last requested index.
  void requestTab(int index) {
    final nextSeq = (state?.seq ?? 0) + 1;
    state = YouHubTabRequest(index, nextSeq);
  }
}

/// Null until the first request. [YouHubScreen] seeds its initial tab from
/// this in `initState` and listens for subsequent requests in `build`.
final youHubTabRequestProvider =
    StateNotifierProvider<YouHubTabRequestNotifier, YouHubTabRequest?>(
  (ref) => YouHubTabRequestNotifier(),
);
