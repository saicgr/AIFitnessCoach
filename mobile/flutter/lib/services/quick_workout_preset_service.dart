import 'package:flutter/foundation.dart';

import '../data/local/database.dart';
import '../data/models/user.dart';
import '../models/equipment_item.dart';
import '../models/quick_workout_preset.dart';

/// Business logic for quick workout presets: AI recommendations, auto-capture, dedup.
class QuickWorkoutPresetService {
  static const _maxPresets = 10;

  /// Load presets. If none exist, generate AI recommendations and save them.
  static Future<List<QuickWorkoutPreset>> loadPresets(
    AppDatabase db,
    String userId,
    User user,
  ) async {
    final rows = await db.quickPresetDao.getPresetsForUser(userId);
    if (rows.isNotEmpty) {
      return rows.map(QuickWorkoutPreset.fromRow).toList();
    }

    // First time: generate AI recommendations from user profile
    final recommendations = generateRecommendations(user);
    for (final preset in recommendations) {
      await db.quickPresetDao.upsertPreset(preset.toCompanion(userId));
    }
    debugPrint('[QuickPresets] Generated ${recommendations.length} AI recommendations');
    return recommendations;
  }

  /// Auto-capture after workout generation. Dedup by config: bump useCount or create new.
  /// Evicts oldest non-favorite, non-AI preset when over max.
  static Future<void> autoCapture(
    AppDatabase db,
    String userId, {
    required int duration,
    String? focus,
    String? difficulty,
    String? goal,
    String? mood,
    bool useSupersets = true,
    List<String> equipment = const ['Bodyweight'],
    List<String> injuries = const [],
    Map<String, EquipmentItem>? equipmentDetails,
  }) async {
    final rows = await db.quickPresetDao.getPresetsForUser(userId);
    final existing = rows.map(QuickWorkoutPreset.fromRow).toList();

    // Build a candidate preset to compare configs
    final candidate = QuickWorkoutPreset.create(
      duration: duration,
      focus: focus,
      difficulty: difficulty,
      goal: goal,
      mood: mood,
      useSupersets: useSupersets,
      equipment: equipment,
      injuries: injuries,
      equipmentDetails: equipmentDetails,
    );

    // Check for config duplicate
    final match = existing.cast<QuickWorkoutPreset?>().firstWhere(
      (p) => p!.matchesConfig(candidate),
      orElse: () => null,
    );

    if (match != null) {
      // Bump use count on existing preset
      await db.quickPresetDao.recordUsage(match.id);
      debugPrint('[QuickPresets] Bumped useCount for existing preset ${match.id}');
      return;
    }

    // Check if we need to evict before adding
    if (existing.length >= _maxPresets) {
      await db.quickPresetDao.evictOldest(userId);
      debugPrint('[QuickPresets] Evicted oldest preset');
    }

    // Save new preset
    await db.quickPresetDao.upsertPreset(candidate.toCompanion(userId));
    debugPrint('[QuickPresets] Captured new preset: ${candidate.label}');
  }

  /// Delete a preset.
  static Future<void> deletePreset(AppDatabase db, String id) {
    return db.quickPresetDao.deletePreset(id);
  }

  /// Toggle favorite on a preset.
  static Future<void> toggleFavorite(AppDatabase db, String id) {
    return db.quickPresetDao.toggleFavorite(id);
  }

  /// Generate 2 AI recommendations from the user's profile (no API calls).
  static List<QuickWorkoutPreset> generateRecommendations(User user) {
    final tier = _equipmentTier(user.equipmentList);
    final duration = _clampDuration(user.workoutDuration);
    final difficulty = _mapFitnessLevel(user.fitnessLevel);
    final injuries = user.injuriesList;

    // Preset 1: primary goal match
    final primaryGoal = _mapPrimaryGoal(user.primaryGoal);
    final preset1 = QuickWorkoutPreset.create(
      duration: duration,
      focus: 'full_body',
      difficulty: difficulty,
      goal: primaryGoal,
      useSupersets: true,
      equipment: tier.equipment,
      injuries: injuries,
      isAiGenerated: true,
    );

    // Preset 2: complementary
    final preset2 = _generateComplementary(
      preset1: preset1,
      tier: tier,
      difficulty: difficulty,
      injuries: injuries,
    );

    return [preset1, preset2];
  }

  /// Generate the full discover pool (~6 suggestions).
  static List<QuickWorkoutPreset> generateDiscoverPool(User user) {
    final tier = _equipmentTier(user.equipmentList);
    final duration = _clampDuration(user.workoutDuration);
    final difficulty = _mapFitnessLevel(user.fitnessLevel);
    final injuries = user.injuriesList;
    final recommendations = generateRecommendations(user);

    final candidates = <QuickWorkoutPreset>[
      QuickWorkoutPreset.create(
        duration: duration,
        focus: 'upper_body',
        difficulty: difficulty,
        goal: 'hypertrophy',
        equipment: tier.equipment,
        injuries: injuries,
        isAiGenerated: true,
      ),
      QuickWorkoutPreset.create(
        duration: duration,
        focus: 'lower_body',
        difficulty: difficulty,
        goal: 'hypertrophy',
        equipment: tier.equipment,
        injuries: injuries,
        isAiGenerated: true,
      ),
      QuickWorkoutPreset.create(
        duration: 10,
        focus: 'core',
        difficulty: difficulty,
        equipment: ['Bodyweight'],
        injuries: injuries,
        isAiGenerated: true,
      ),
      QuickWorkoutPreset.create(
        duration: 10,
        focus: 'stretch',
        difficulty: 'easy',
        equipment: ['Bodyweight'],
        injuries: injuries,
        isAiGenerated: true,
      ),
      QuickWorkoutPreset.create(
        duration: 15,
        focus: 'emom',
        difficulty: difficulty,
        equipment: tier.equipment,
        injuries: injuries,
        isAiGenerated: true,
      ),
      QuickWorkoutPreset.create(
        duration: 15,
        focus: 'cardio',
        difficulty: difficulty,
        equipment: ['Bodyweight'],
        injuries: injuries,
        isAiGenerated: true,
      ),
    ];

    // Filter out any that match existing recommendations
    return candidates
        .where((c) => !recommendations.any((r) => r.matchesConfig(c)))
        .toList();
  }

  // ── Private helpers ──

  static QuickWorkoutPreset _generateComplementary({
    required QuickWorkoutPreset preset1,
    required _EquipmentTier tier,
    required String? difficulty,
    required List<String> injuries,
  }) {
    final goal1 = preset1.goal ?? 'hypertrophy';

    // If primary is strength/hypertrophy, complement with cardio
    if (goal1 == 'strength' || goal1 == 'hypertrophy') {
      // If injuries include lower back or knee, pick upper body cardio-safe focus
      final focus =
          injuries.any((i) => i.toLowerCase() == 'knee' || i.toLowerCase() == 'ankle')
              ? 'upper_body'
              : 'cardio';
      return QuickWorkoutPreset.create(
        duration: 10,
        focus: focus,
        difficulty: difficulty,
        goal: 'endurance',
        equipment: ['Bodyweight'],
        injuries: injuries,
        isAiGenerated: true,
      );
    }

    // If primary is cardio/endurance, complement with strength
    return QuickWorkoutPreset.create(
      duration: 15,
      focus: 'full_body',
      difficulty: difficulty,
      goal: 'strength',
      equipment: tier.equipment,
      injuries: injuries,
      isAiGenerated: true,
    );
  }

  static _EquipmentTier _equipmentTier(List<String> userEquipment) {
    final lower = userEquipment.map((e) => e.toLowerCase()).toSet();
    if (lower.contains('barbell') &&
        (lower.contains('cable machine') || lower.contains('cable_machine') || lower.contains('machines'))) {
      return _EquipmentTier(
        equipment: [
          'Bodyweight', 'Dumbbells', 'Barbell', 'Cable Machine', 'Machines',
        ],
      );
    }
    if (lower.contains('dumbbells') || lower.contains('dumbbell')) {
      return _EquipmentTier(equipment: ['Bodyweight', 'Dumbbells']);
    }
    return _EquipmentTier(equipment: ['Bodyweight']);
  }

  static int _clampDuration(int? userDuration) {
    if (userDuration == null) return 15;
    return userDuration.clamp(10, 30);
  }

  static String? _mapFitnessLevel(String? level) {
    if (level == null) return null;
    switch (level.toLowerCase()) {
      case 'beginner':
        return 'easy';
      case 'intermediate':
        return 'medium';
      case 'advanced':
        return 'hard';
      case 'expert':
        return 'hell';
      default:
        return level.toLowerCase();
    }
  }

  static String _mapPrimaryGoal(String? primaryGoal) {
    if (primaryGoal == null) return 'hypertrophy';
    switch (primaryGoal.toLowerCase()) {
      case 'muscle_hypertrophy':
        return 'hypertrophy';
      case 'muscle_strength':
        return 'strength';
      case 'strength_hypertrophy':
        return 'hypertrophy';
      case 'weight_loss':
      case 'fat_loss':
        return 'endurance';
      default:
        return 'hypertrophy';
    }
  }
}

class _EquipmentTier {
  final List<String> equipment;
  const _EquipmentTier({required this.equipment});
}
