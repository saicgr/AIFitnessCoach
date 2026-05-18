import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The customizable content sections of the unified home screen.
///
/// Order matches the approved v27 layout. The header, notification banners
/// and rating prompt are fixed system chrome and are NOT part of this enum —
/// only the sections a user may legitimately reorder or hide live here.
enum HomeSection {
  quickActions,
  weekStrip,
  workoutCard,
  nutritionCard,
  metricTrio,
  weeklyReport,
  timeline,
  habits,
}

/// The date the user is currently "viewing" on the unified home screen.
///
/// Defaults to today (local midnight). Tapping a day in [HomeWeekStrip]
/// sets this; the workout card reacts in-place instead of navigating away.
/// Always normalized to local midnight by callers.
final selectedHomeDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

extension HomeSectionMeta on HomeSection {
  /// Stable string key used for SharedPreferences persistence. Decoupled
  /// from `name` so a future enum rename can't silently drop a user's saved
  /// layout.
  String get storageKey {
    switch (this) {
      case HomeSection.quickActions:
        return 'quick_actions';
      case HomeSection.weekStrip:
        return 'week_strip';
      case HomeSection.workoutCard:
        return 'workout_card';
      case HomeSection.nutritionCard:
        return 'nutrition_card';
      case HomeSection.metricTrio:
        return 'metric_trio';
      case HomeSection.weeklyReport:
        return 'weekly_report';
      case HomeSection.timeline:
        return 'timeline';
      case HomeSection.habits:
        return 'habits';
    }
  }

  String get label {
    switch (this) {
      case HomeSection.quickActions:
        return 'Quick actions';
      case HomeSection.weekStrip:
        return 'Week strip';
      case HomeSection.workoutCard:
        return "Today's workout";
      case HomeSection.nutritionCard:
        return 'Nutrition';
      case HomeSection.metricTrio:
        return 'Activity & sleep';
      case HomeSection.weeklyReport:
        return 'Weekly report';
      case HomeSection.timeline:
        return "Today's timeline";
      case HomeSection.habits:
        return 'Habits';
    }
  }

  String get description {
    switch (this) {
      case HomeSection.quickActions:
        return 'The six-icon shortcut row';
      case HomeSection.weekStrip:
        return 'Your seven-day workout streak ring';
      case HomeSection.workoutCard:
        return 'Launch card for the day’s session';
      case HomeSection.nutritionCard:
        return 'Calories, macros and water';
      case HomeSection.metricTrio:
        return 'Synced steps, calories & sleep';
      case HomeSection.weeklyReport:
        return 'This week’s progress ring, streak & PRs';
      case HomeSection.timeline:
        return "The day's events on a time-ordered track";
      case HomeSection.habits:
        return 'Your daily habit cards & streaks';
    }
  }

  /// `LineIcon` name representing the section in the editor.
  String get iconName {
    switch (this) {
      case HomeSection.quickActions:
        return 'spark';
      case HomeSection.weekStrip:
        return 'check';
      case HomeSection.workoutCard:
        return 'workout';
      case HomeSection.nutritionCard:
        return 'nutrition';
      case HomeSection.metricTrio:
        return 'activity';
      case HomeSection.weeklyReport:
        return 'flame';
      case HomeSection.timeline:
        return 'check';
      case HomeSection.habits:
        return 'spark';
    }
  }

  static HomeSection? fromStorageKey(String key) {
    for (final s in HomeSection.values) {
      if (s.storageKey == key) return s;
    }
    return null;
  }
}

/// Immutable snapshot of the user's home-section customization.
@immutable
class HomeSectionsState {
  /// Every section, in the user's chosen render order.
  final List<HomeSection> order;

  /// Sections the user has hidden. Still present in [order] so un-hiding
  /// restores them to their previous position.
  final Set<HomeSection> hidden;

  const HomeSectionsState({required this.order, required this.hidden});

  bool isVisible(HomeSection s) => !hidden.contains(s);

  /// The sections to actually render, in order, skipping hidden ones.
  List<HomeSection> get visibleInOrder =>
      order.where((s) => !hidden.contains(s)).toList(growable: false);

  bool get isDefault =>
      hidden.isEmpty && listEquals(order, _defaultOrder);

  HomeSectionsState copyWith({
    List<HomeSection>? order,
    Set<HomeSection>? hidden,
  }) =>
      HomeSectionsState(
        order: order ?? this.order,
        hidden: hidden ?? this.hidden,
      );
}

/// v27 default — every section visible, in the approved order.
const List<HomeSection> _defaultOrder = [
  HomeSection.quickActions,
  HomeSection.weekStrip,
  HomeSection.workoutCard,
  HomeSection.nutritionCard,
  HomeSection.metricTrio,
  HomeSection.weeklyReport,
  HomeSection.timeline,
  HomeSection.habits,
];

const HomeSectionsState _defaultState = HomeSectionsState(
  order: _defaultOrder,
  hidden: <HomeSection>{},
);

const String _kOrderKey = 'home_section_order_v1';
const String _kHiddenKey = 'home_section_hidden_v1';

/// Persists the user's "My Space" home-section layout (order + visibility)
/// to SharedPreferences and exposes it to `home_screen.dart`.
class HomeSectionsNotifier extends StateNotifier<HomeSectionsState> {
  HomeSectionsNotifier() : super(_defaultState) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedOrder = prefs.getStringList(_kOrderKey);
      final savedHidden = prefs.getStringList(_kHiddenKey) ?? const [];

      // Rebuild the order: take saved keys that still map to a real section,
      // then append any section the saved layout didn't know about (e.g. a
      // section added in a newer app version) so nothing silently vanishes.
      final order = <HomeSection>[];
      if (savedOrder != null) {
        for (final key in savedOrder) {
          final s = HomeSectionMeta.fromStorageKey(key);
          if (s != null && !order.contains(s)) order.add(s);
        }
      }
      for (final s in _defaultOrder) {
        if (!order.contains(s)) order.add(s);
      }

      final hidden = <HomeSection>{};
      for (final key in savedHidden) {
        final s = HomeSectionMeta.fromStorageKey(key);
        if (s != null) hidden.add(s);
      }

      if (mounted) {
        state = HomeSectionsState(order: order, hidden: hidden);
      }
    } catch (e) {
      debugPrint('⚠️ [HomeSections] load failed, using default: $e');
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
          _kOrderKey, state.order.map((s) => s.storageKey).toList());
      await prefs.setStringList(
          _kHiddenKey, state.hidden.map((s) => s.storageKey).toList());
    } catch (e) {
      debugPrint('⚠️ [HomeSections] persist failed: $e');
    }
  }

  /// Reorder a section. [oldIndex]/[newIndex] follow `ReorderableListView`
  /// semantics (newIndex is pre-removal).
  void reorder(int oldIndex, int newIndex) {
    final next = List<HomeSection>.from(state.order);
    if (oldIndex < 0 || oldIndex >= next.length) return;
    if (newIndex > oldIndex) newIndex--;
    newIndex = newIndex.clamp(0, next.length - 1);
    final moved = next.removeAt(oldIndex);
    next.insert(newIndex, moved);
    state = state.copyWith(order: next);
    _persist();
  }

  void setVisible(HomeSection section, bool visible) {
    final next = Set<HomeSection>.from(state.hidden);
    if (visible) {
      next.remove(section);
    } else {
      next.add(section);
    }
    state = state.copyWith(hidden: next);
    _persist();
  }

  void toggle(HomeSection section) =>
      setVisible(section, state.hidden.contains(section));

  /// Restore the approved v27 default (all visible, original order).
  void resetToDefault() {
    state = _defaultState;
    _persist();
  }
}

final homeSectionsProvider =
    StateNotifierProvider<HomeSectionsNotifier, HomeSectionsState>(
  (ref) => HomeSectionsNotifier(),
);
