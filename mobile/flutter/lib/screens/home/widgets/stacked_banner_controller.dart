import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Session-scoped state for tracking which banners have been swiped away.
///
/// This is intentionally NOT persisted — banner dismissal within a session
/// is handled here, while cross-session persistence uses the existing
/// SharedPreferences / server-side logic in each banner's own provider.
final stackedBannerControllerProvider =
    StateNotifierProvider<StackedBannerController, Set<String>>((ref) {
  return StackedBannerController();
});

class StackedBannerController extends StateNotifier<Set<String>> {
  StackedBannerController() : super({});

  void dismiss(String bannerId) {
    state = {...state, bannerId};
  }

  bool isDismissed(String bannerId) => state.contains(bannerId);
}
