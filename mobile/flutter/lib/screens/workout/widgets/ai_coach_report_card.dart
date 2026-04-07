import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/workout.dart';
import '../../../widgets/lottie_animations.dart';
import '../../library/providers/muscle_group_images_provider.dart';

/// Compact AI Coach report card for the workout complete screen.
/// Shows AI insight, muscles worked with images, and quick performance stats.
class AiCoachReportCard extends StatelessWidget {
  final List<WorkoutExercise> exercises;
  final String? aiSummary;
  final bool isLoadingSummary;
  final bool isExpanded;
  final VoidCallback? onToggleExpand;
  final int totalSets;
  final double totalVolumeKg;
  final int durationSeconds;
  final List<Map<String, dynamic>> newPRs;
  final PerformanceComparisonInfo? performanceComparison;

  const AiCoachReportCard({
    super.key,
    required this.exercises,
    this.aiSummary,
    this.isLoadingSummary = false,
    this.isExpanded = false,
    this.onToggleExpand,
    this.totalSets = 0,
    this.totalVolumeKg = 0,
    this.durationSeconds = 0,
    this.newPRs = const [],
    this.performanceComparison,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muscles = _extractMuscles();

    return GestureDetector(
      onTap: isLoadingSummary ? null : onToggleExpand,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.orange.withOpacity(0.08),
              AppColors.purple.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.orange.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Section 1: AI Insight
            _AiInsightSection(
              aiSummary: aiSummary,
              isLoading: isLoadingSummary,
              isExpanded: isExpanded,
            ),

            if (muscles.isNotEmpty) ...[
              Divider(
                height: 20,
                thickness: 0.5,
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.08),
              ),
              // Section 2: Muscles Worked
              _MusclesWorkedStrip(muscles: muscles),
            ],

            Divider(
              height: 20,
              thickness: 0.5,
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.08),
            ),

            // Section 3: Quick Stats
            _QuickStatsRow(
              totalSets: totalSets,
              totalVolumeKg: totalVolumeKg,
              durationSeconds: durationSeconds,
              prCount: newPRs.length,
              performanceComparison: performanceComparison,
            ),
          ],
        ),
      ),
    );
  }

  List<_MuscleData> _extractMuscles() {
    final Map<String, _MuscleData> muscleMap = {};

    for (final exercise in exercises) {
      final muscleName = exercise.primaryMuscle ?? exercise.muscleGroup;
      if (muscleName != null && muscleName.isNotEmpty) {
        final normalized = _normalizeMuscle(muscleName);
        final existing = muscleMap[normalized];
        muscleMap[normalized] = _MuscleData(
          name: normalized,
          imagePath: _findMuscleImage(normalized),
          sets: (existing?.sets ?? 0) + (exercise.sets ?? 0),
          isPrimary: true,
        );
      }

      // Parse secondary muscles
      final secondaries = _parseSecondaryMuscles(exercise.secondaryMuscles);
      for (final sec in secondaries) {
        final normalized = _normalizeMuscle(sec);
        if (!muscleMap.containsKey(normalized)) {
          muscleMap[normalized] = _MuscleData(
            name: normalized,
            imagePath: _findMuscleImage(normalized),
            sets: 0,
            isPrimary: false,
          );
        }
      }
    }

    // Sort: primary first (by sets desc), then secondary
    final result = muscleMap.values.toList()
      ..sort((a, b) {
        if (a.isPrimary != b.isPrimary) return a.isPrimary ? -1 : 1;
        return b.sets.compareTo(a.sets);
      });
    return result;
  }

  static String _normalizeMuscle(String name) {
    // Strip parenthetical suffixes like "Triceps (triceps brachii)" → "Triceps"
    final stripped = name.trim().replaceAll(RegExp(r'\s*\(.*\)\s*$'), '');
    final lower = stripped.toLowerCase();
    const aliases = {
      'upper back': 'Back',
      'lats': 'Back',
      'latissimus dorsi': 'Back',
      'rear delts': 'Shoulders',
      'front delts': 'Shoulders',
      'side delts': 'Shoulders',
      'deltoids': 'Shoulders',
      'pecs': 'Chest',
      'pectorals': 'Chest',
      'abs': 'Core',
      'abdominals': 'Core',
      'obliques': 'Core',
      'quads': 'Quadriceps',
      'hamstrings': 'Hamstrings',
      'glutes': 'Glutes',
      'gluteus': 'Glutes',
      'calves': 'Calves',
      'biceps': 'Biceps',
      'triceps': 'Triceps',
      'forearms': 'Forearms',
      'lower back': 'Lower Back',
      'hip flexors': 'Hips',
      'hips': 'Hips',
      'chest': 'Chest',
      'back': 'Back',
      'shoulders': 'Shoulders',
      'core': 'Core',
      'arms': 'Arms',
      'legs': 'Legs',
      'quadriceps': 'Quadriceps',
    };
    return aliases[lower] ?? _titleCase(stripped);
  }

  static String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s.split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }

  static String? _findMuscleImage(String normalized) {
    // Direct lookup
    if (muscleGroupAssets.containsKey(normalized)) {
      return muscleGroupAssets[normalized];
    }
    // Case-insensitive fallback
    for (final entry in muscleGroupAssets.entries) {
      if (entry.key.toLowerCase() == normalized.toLowerCase()) {
        return entry.value;
      }
    }
    return null;
  }

  static List<String> _parseSecondaryMuscles(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    }
    if (value is String && value.isNotEmpty) {
      return value.split(RegExp(r'[,;]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }
    return [];
  }
}

// ─── Data model ─────────────────────────────────────────────────

class _MuscleData {
  final String name;
  final String? imagePath;
  final int sets;
  final bool isPrimary;

  const _MuscleData({
    required this.name,
    this.imagePath,
    required this.sets,
    required this.isPrimary,
  });
}

// ─── Section 1: AI Insight ──────────────────────────────────────

class _AiInsightSection extends StatelessWidget {
  final String? aiSummary;
  final bool isLoading;
  final bool isExpanded;

  const _AiInsightSection({
    this.aiSummary,
    this.isLoading = false,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.orange, AppColors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.auto_awesome, size: 13, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: isLoading
              ? const SizedBox(
                  height: 32,
                  child: Center(
                    child: LottieLoading(size: 20, color: AppColors.orange),
                  ),
                )
              : Text(
                  aiSummary ?? 'Great workout! Keep up the momentum.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.4,
                  ),
                  maxLines: isExpanded ? null : 2,
                  overflow: isExpanded ? null : TextOverflow.ellipsis,
                ),
        ),
        if (!isLoading && (aiSummary?.length ?? 0) > 80)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              size: 16,
              color: AppColors.textMuted,
            ),
          ),
      ],
    );
  }
}

// ─── Section 2: Muscles Worked ──────────────────────────────────

class _MusclesWorkedStrip extends StatelessWidget {
  final List<_MuscleData> muscles;

  const _MusclesWorkedStrip({required this.muscles});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Muscles Worked',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: muscles.map((muscle) {
            return _MuscleChip(muscle: muscle);
          }).toList(),
        ),
      ],
    );
  }
}

class _MuscleChip extends StatelessWidget {
  final _MuscleData muscle;

  const _MuscleChip({required this.muscle});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final borderColor = muscle.isPrimary
        ? AppColors.orange.withOpacity(0.6)
        : AppColors.purple.withOpacity(0.3);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 2),
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.03),
          ),
          child: ClipOval(
            child: muscle.imagePath != null
                ? Image.asset(
                    muscle.imagePath!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.fitness_center,
                      size: 18,
                      color: textMuted,
                    ),
                  )
                : Icon(
                    Icons.fitness_center,
                    size: 18,
                    color: textMuted,
                  ),
          ),
        ),
        const SizedBox(height: 2),
        SizedBox(
          width: 52,
          child: Text(
            muscle.name,
            style: TextStyle(fontSize: 9, color: textMuted),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (muscle.sets > 0)
          Text(
            '${muscle.sets}s',
            style: TextStyle(
              fontSize: 8,
              color: muscle.isPrimary ? AppColors.orange : textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

// ─── Section 3: Quick Stats ─────────────────────────────────────

class _QuickStatsRow extends StatelessWidget {
  final int totalSets;
  final double totalVolumeKg;
  final int durationSeconds;
  final int prCount;
  final PerformanceComparisonInfo? performanceComparison;

  const _QuickStatsRow({
    required this.totalSets,
    required this.totalVolumeKg,
    required this.durationSeconds,
    required this.prCount,
    this.performanceComparison,
  });

  @override
  Widget build(BuildContext context) {
    // Compute stats
    final volumePercent = performanceComparison?.workoutComparison.volumeDiffPercent;
    final minutes = durationSeconds > 0 ? durationSeconds / 60.0 : 1.0;
    final workRate = totalVolumeKg / minutes;
    final avgPerSet = totalSets > 0 ? totalVolumeKg / totalSets : 0.0;

    return Row(
      children: [
        // Stat 1: Volume change or absolute volume
        Expanded(
          child: _MiniStat(
            icon: Icons.trending_up,
            value: volumePercent != null
                ? '${volumePercent >= 0 ? '+' : ''}${volumePercent.toStringAsFixed(0)}%'
                : '${totalVolumeKg.toStringAsFixed(0)}kg',
            label: volumePercent != null ? 'vs Last' : 'Volume',
            color: volumePercent != null
                ? (volumePercent >= 0 ? AppColors.green : Colors.redAccent)
                : AppColors.green,
          ),
        ),
        const SizedBox(width: 6),
        // Stat 2: Work rate
        Expanded(
          child: _MiniStat(
            icon: Icons.speed,
            value: '${workRate.toStringAsFixed(0)}',
            label: 'kg/min',
            color: AppColors.purple,
          ),
        ),
        const SizedBox(width: 6),
        // Stat 3: PRs or Avg/Set
        Expanded(
          child: prCount > 0
              ? _MiniStat(
                  icon: Icons.emoji_events,
                  value: '$prCount',
                  label: prCount == 1 ? 'PR' : 'PRs',
                  color: AppColors.orange,
                )
              : _MiniStat(
                  icon: Icons.fitness_center,
                  value: '${avgPerSet.toStringAsFixed(1)}',
                  label: 'kg/set',
                  color: AppColors.orange,
                ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 8, color: textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
