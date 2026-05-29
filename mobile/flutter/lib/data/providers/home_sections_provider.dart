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
  coachHero, // NEW (2026-05-22) — Gemini-backed daily insight hero card
  strainCoach, // NEW (2026-05-24, P5 §12) — daily intensity recommendation
  workoutCard,
  nutritionCard,
  metricTrio,
  weeklyReport,
  timeline,
  habits, // Kept in enum so users who customized it still see it; not in default order anymore (moved to Profile)
  todayScore,
  cycle,
  readiness, // NEW — Recovery readiness traffic-light + intensity prescription
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
      case HomeSection.coachHero:
        return 'coach_hero';
      case HomeSection.strainCoach:
        return 'strain_coach';
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
      case HomeSection.todayScore:
        return 'today_score';
      case HomeSection.cycle:
        return 'cycle';
      case HomeSection.readiness:
        return 'readiness';
    }
  }

  String get label {
    switch (this) {
      case HomeSection.quickActions:
        return 'Quick actions';
      case HomeSection.weekStrip:
        return 'Week strip';
      case HomeSection.coachHero:
        return 'Coach insight';
      case HomeSection.strainCoach:
        return 'Strain Coach';
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
      case HomeSection.todayScore:
        return 'Today Score';
      case HomeSection.cycle:
        return 'Cycle';
      case HomeSection.readiness:
        return 'Recovery readiness';
    }
  }

  String get description {
    switch (this) {
      case HomeSection.quickActions:
        return 'The six-icon shortcut row';
      case HomeSection.weekStrip:
        return 'Your seven-day workout streak ring';
      case HomeSection.coachHero:
        return 'A daily nudge from your AI coach';
      case HomeSection.strainCoach:
        return "Today's intensity call: rest / light / moderate / hard";
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
      case HomeSection.todayScore:
        return 'Your Train, Fuel & Move ring for the day';
      case HomeSection.cycle:
        return 'Your cycle phase, day & next-period countdown';
      case HomeSection.readiness:
        return 'Hooper-Index recovery score with intensity prescription';
    }
  }

  /// `LineIcon` name representing the section in the editor.
  String get iconName {
    switch (this) {
      case HomeSection.quickActions:
        return 'spark';
      case HomeSection.weekStrip:
        return 'check';
      case HomeSection.coachHero:
        return 'spark';
      case HomeSection.strainCoach:
        return 'flame';
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
      case HomeSection.todayScore:
        return 'activity';
      case HomeSection.cycle:
        return 'spark';
      case HomeSection.readiness:
        return 'flame';
    }
  }

  /// Core sections can be reordered but never hidden in "My Space" — the
  /// Today Score is the home's anchor and is always present. The Coach Hero
  /// is also core (2026-05-22) since the AI insight is the home's main moat.
  bool get isCore =>
      this == HomeSection.todayScore || this == HomeSection.coachHero;

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

/// v31 default — Direction C feedback: the compact metric deck (todayScore)
/// rises to the very top, directly beneath the notification banners, and the
/// Coach Hero card drops to BELOW it (issue 1). The deck owns the Log / Trends
/// / Start row, so the deck-then-coach order matches the user's mental model:
/// glance at metrics, then read the coach. Timeline is force-rendered last by
/// home_screen (after the contextual card stack) regardless of this order.
/// v30: Quick actions moved below the rings card.
/// v29: Strain Coach card inserted between Coach Hero and Today Score.
/// v28: coach hero hoisted above the score card. Habits row moved off
/// home into Profile.
const List<HomeSection> _defaultOrder = [
  HomeSection.weekStrip,
  // The metric summary deck sits first, right under the banners (issue 1).
  HomeSection.todayScore,
  // Coach Hero now sits BELOW the deck (issue 1).
  HomeSection.coachHero,
  HomeSection.strainCoach,
  HomeSection.quickActions,
  HomeSection.workoutCard,
  HomeSection.nutritionCard,
  // The Cycle card self-hides unless menstrual tracking is enabled, so it is
  // safe to keep in the default order for everyone.
  HomeSection.cycle,
  HomeSection.metricTrio,
  // weeklyReport renders as a two-up "Reports · Recap" row (issue 7).
  HomeSection.weeklyReport,
  HomeSection.timeline,
  // Habits moved to Profile screen — existing users who customized it back
  // in still see it (the enum + extension methods still handle it).
];

const HomeSectionsState _defaultState = HomeSectionsState(
  order: _defaultOrder,
  // Week strip is hidden by default (2026-05-23). The 7-day streak ring is
  // already represented by the Today Score and the date strip on detail
  // screens; surfacing it on home again competed with the score card for
  // attention. Users who want it back can re-enable from My Space.
  hidden: <HomeSection>{HomeSection.weekStrip},
);

// v6 order: metric deck hoisted to top, Coach Hero dropped below it (issue 1).
// v5 order: quick actions moved below the rings card.
// v4 order: Strain Coach inserted between Coach Hero and Today Score (P5).
// v3 order: coach hero inserted above the Today Score; habits moved to Profile.
// v2 hidden: weekStrip hidden by default. Bumping each key forces a one-time
// migration to the new default for existing users.
const String _kOrderKey = 'home_section_order_v6';
const String _kHiddenKey = 'home_section_hidden_v2';

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
      // Distinguish "user has never persisted under this key" (null) from
      // "user explicitly cleared their hides" (empty list). The null case
      // must fall back to `_defaultState.hidden` (e.g. weekStrip hidden by
      // default in v2) instead of starting from an empty set, otherwise
      // bumping the storage-key version effectively un-hides everything.
      final savedHiddenRaw = prefs.getStringList(_kHiddenKey);

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
      // Append any section the saved layout didn't know about, at its
      // intended default position — so a newly-shipped section (e.g. the
      // Today Score) lands where the default wants it, not at the bottom.
      for (var di = 0; di < _defaultOrder.length; di++) {
        final s = _defaultOrder[di];
        if (!order.contains(s)) {
          order.insert(di < order.length ? di : order.length, s);
        }
      }

      final hidden = <HomeSection>{};
      // If the user has never written to the current hidden-key version,
      // seed from the new default; otherwise honor what they persisted.
      if (savedHiddenRaw == null) {
        hidden.addAll(_defaultState.hidden);
      }
      final savedHidden = savedHiddenRaw ?? const <String>[];
      for (final key in savedHidden) {
        final s = HomeSectionMeta.fromStorageKey(key);
        if (s != null) hidden.add(s);
      }
      // A core section must never end up hidden, even from a stale save.
      hidden.removeWhere((s) => s.isCore);

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
    // Core sections can be reordered but never hidden.
    if (!visible && section.isCore) return;
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

  /// Apply a preset layout from the Discover tab. The Today Score (core) is
  /// always kept visible regardless of the preset.
  void applyPreset(HomeSectionPreset preset) {
    final visible = <HomeSection>[...preset.visible];
    if (!visible.contains(HomeSection.todayScore)) {
      visible.insert(0, HomeSection.todayScore);
    }
    final order = <HomeSection>[...visible];
    for (final s in HomeSection.values) {
      if (!order.contains(s)) order.add(s);
    }
    final hidden = <HomeSection>{
      for (final s in HomeSection.values)
        if (!visible.contains(s) && !s.isCore) s,
    };
    state = HomeSectionsState(order: order, hidden: hidden);
    _persist();
  }
}

/// A named preset layout for the "Discover" tab of My Space.
class HomeSectionPreset {
  final String id;
  final String name;
  final String description;

  /// Sections visible in this preset, in render order. The Today Score is
  /// always shown regardless — it is the home's core anchor.
  final List<HomeSection> visible;

  const HomeSectionPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.visible,
  });
}

/// The preset layouts offered in My Space › Discover.
const List<HomeSectionPreset> homeSectionPresets = [
  HomeSectionPreset(
    id: 'balanced',
    name: 'Balanced',
    description: 'Everything on, in the recommended order.',
    visible: _defaultOrder,
  ),
  HomeSectionPreset(
    id: 'essentials',
    name: 'Essentials',
    description: 'Just the score, your workout and nutrition.',
    visible: [
      HomeSection.quickActions,
      HomeSection.todayScore,
      HomeSection.workoutCard,
      HomeSection.nutritionCard,
    ],
  ),
  HomeSectionPreset(
    id: 'training',
    name: 'Training focus',
    description: 'Built around your workouts and weekly progress.',
    visible: [
      HomeSection.quickActions,
      HomeSection.todayScore,
      HomeSection.weekStrip,
      HomeSection.workoutCard,
      HomeSection.weeklyReport,
    ],
  ),
  HomeSectionPreset(
    id: 'nutrition',
    name: 'Nutrition focus',
    description: 'Calories, macros and activity up top.',
    visible: [
      HomeSection.quickActions,
      HomeSection.todayScore,
      HomeSection.nutritionCard,
      HomeSection.metricTrio,
      HomeSection.timeline,
    ],
  ),
  HomeSectionPreset(
    id: 'tracker',
    name: 'Tracker',
    description: 'Every metric — steps, sleep, habits and reports.',
    visible: [
      HomeSection.quickActions,
      HomeSection.todayScore,
      HomeSection.metricTrio,
      HomeSection.weeklyReport,
      HomeSection.weekStrip,
      HomeSection.habits,
    ],
  ),
];

final homeSectionsProvider =
    StateNotifierProvider<HomeSectionsNotifier, HomeSectionsState>(
  (ref) => HomeSectionsNotifier(),
);
