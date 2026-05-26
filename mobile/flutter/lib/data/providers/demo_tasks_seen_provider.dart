import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks whether the user has reached the pre-signup demo-tasks screen
/// (workout + nutrition app-taste). Used by the router to route brand-new
/// users who skipped the Build-My-Plan funnel (i.e. tapped "Sign In" on the
/// intro screen and signed up with Google/Apple/Email directly) through
/// `/demo-tasks` once before they land on `/personal-info`.
///
/// SharedPreferences key: `demo_tasks_seen`.
class DemoTasksSeenNotifier extends StateNotifier<bool> {
  static const _prefsKey = 'demo_tasks_seen';

  DemoTasksSeenNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_prefsKey) ?? false;
  }

  Future<void> markSeen() async {
    if (state) return;
    state = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
  }
}

final demoTasksSeenProvider =
    StateNotifierProvider<DemoTasksSeenNotifier, bool>((ref) {
  return DemoTasksSeenNotifier();
});
