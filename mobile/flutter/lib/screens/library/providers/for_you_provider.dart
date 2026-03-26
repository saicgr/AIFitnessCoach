import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/ai_split_preset.dart';
import '../../../data/models/gym_profile.dart';
import '../../../data/providers/gym_profile_provider.dart';

/// Provides personalized split recommendations scored against the user's gym profile.
///
/// Scoring (max ~95 points):
///   +30: exact days/week match, +15: off by 1
///   +25: environment match (home_gym→Home Warrior, etc.)
///   +10: per matching goal keyword
///   +20: focus area match (lower body→Lower Focused, etc.)
///   +10: difficulty match
final forYouPresetsProvider = Provider<List<AISplitPreset>>((ref) {
  final profile = ref.watch(activeGymProfileProvider);
  if (profile == null) {
    // No profile — return top 4 beginner-friendly defaults
    return aiSplitPresets
        .where((p) => p.difficulty.contains('Beginner') && p.daysPerWeek <= 4)
        .take(4)
        .toList();
  }
  return _scoreAndRank(profile);
});

List<AISplitPreset> _scoreAndRank(GymProfile profile) {
  final userDays = profile.workoutDays?.length ?? 4;
  final env = (profile.workoutEnvironment ?? '').toLowerCase();
  final goals = (profile.goals ?? []).map((g) => g.toLowerCase()).toList();
  final focusAreas = (profile.focusAreas ?? []).map((f) => f.toLowerCase()).toList();
  final split = (profile.trainingSplit ?? '').toLowerCase();

  final scored = <MapEntry<AISplitPreset, int>>[];

  for (final preset in aiSplitPresets) {
    int score = 0;

    // Days match (highest weight)
    if (preset.daysPerWeek == userDays) {
      score += 30;
    } else if ((preset.daysPerWeek - userDays).abs() == 1) {
      score += 15;
    } else if (preset.daysPerWeek == 0) {
      score += 20; // Flexible presets always somewhat relevant
    }

    // Environment match
    if (env.contains('home') && preset.id == 'home_warrior') score += 25;
    if (env.contains('commercial') && preset.category == 'classic') score += 10;
    if (env.contains('outdoor') && preset.id == 'hybrid_athlete') score += 15;

    // Goal matching
    for (final goal in goals) {
      if (goal.contains('strength') && preset.id.contains('strength')) score += 10;
      if (goal.contains('muscle') && preset.hypertrophyScore >= 8.0) score += 10;
      if (goal.contains('weight') && preset.isAIPowered) score += 5;
      if (goal.contains('endurance') && preset.id == 'hybrid_athlete') score += 10;
    }

    // Focus area matching
    if (focusAreas.any((f) => f.contains('lower') || f.contains('leg') || f.contains('glute'))) {
      if (preset.id == 'lower_focused') score += 20;
    }
    if (focusAreas.any((f) => f.contains('upper') || f.contains('chest') || f.contains('back'))) {
      if (preset.id == 'chest_back_focus') score += 20;
    }

    // Difficulty match based on current split complexity
    final isSimpleSplit = split.contains('full_body') || split.isEmpty;
    if (isSimpleSplit && preset.difficulty.contains('Beginner')) score += 10;
    if (!isSimpleSplit && preset.difficulty.contains('Advanced')) score += 10;

    scored.add(MapEntry(preset, score));
  }

  scored.sort((a, b) => b.value.compareTo(a.value));
  return scored.take(4).map((e) => e.key).toList();
}
