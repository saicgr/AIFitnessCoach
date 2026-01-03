import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/calibration_repository.dart';

/// Provider for strength baselines
final strengthBaselinesProvider = FutureProvider<List<StrengthBaseline>>((ref) async {
  final repository = ref.watch(calibrationRepositoryProvider);
  return repository.getStrengthBaselines();
});

/// Screen for viewing user's strength baselines from calibration
class StrengthBaselinesScreen extends ConsumerWidget {
  const StrengthBaselinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final baselinesAsync = ref.watch(strengthBaselinesProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.pureBlack : AppColorsLight.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.pureBlack : AppColorsLight.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Strength Baselines',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: textMuted),
            onPressed: () => ref.invalidate(strengthBaselinesProvider),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: baselinesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(context, error, ref, isDark, textPrimary, textMuted),
        data: (baselines) => baselines.isEmpty
            ? _buildEmptyState(context, isDark, textPrimary, textMuted)
            : _buildBaselinesList(context, baselines, isDark, textPrimary, textSecondary, textMuted, elevated, cardBorder),
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    Object error,
    WidgetRef ref,
    bool isDark,
    Color textPrimary,
    Color textMuted,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load baselines',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: TextStyle(
                fontSize: 14,
                color: textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(strengthBaselinesProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textMuted,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 80,
              color: textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Baselines Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Complete a calibration workout to establish your strength baselines. These help us personalize your training weights.',
              style: TextStyle(
                fontSize: 15,
                color: textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.push('/calibration/intro'),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Calibration'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBaselinesList(
    BuildContext context,
    List<StrengthBaseline> baselines,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
    Color elevated,
    Color cardBorder,
  ) {
    // Group baselines by muscle group
    final groupedBaselines = <String, List<StrengthBaseline>>{};
    for (final baseline in baselines) {
      final group = _formatMuscleGroup(baseline.muscleGroup);
      groupedBaselines.putIfAbsent(group, () => []).add(baseline);
    }

    // Get the most recent calibration date
    DateTime? mostRecentDate;
    for (final baseline in baselines) {
      if (mostRecentDate == null || baseline.calibratedAt.isAfter(mostRecentDate)) {
        mostRecentDate = baseline.calibratedAt;
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary card
        _buildSummaryCard(
          baselines: baselines,
          lastCalibratedAt: mostRecentDate,
          isDark: isDark,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          textMuted: textMuted,
          elevated: elevated,
          cardBorder: cardBorder,
        ),
        const SizedBox(height: 20),

        // Grouped baselines
        ...groupedBaselines.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  entry.key,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              ...entry.value.map((baseline) => _buildBaselineCard(
                    baseline: baseline,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    textMuted: textMuted,
                    elevated: elevated,
                    cardBorder: cardBorder,
                  )),
              const SizedBox(height: 8),
            ],
          );
        }),

        const SizedBox(height: 24),

        // Recalibrate button
        Center(
          child: TextButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              context.push('/calibration/intro');
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Recalibrate'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.cyan,
            ),
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSummaryCard({
    required List<StrengthBaseline> baselines,
    required DateTime? lastCalibratedAt,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
    required Color elevated,
    required Color cardBorder,
  }) {
    final daysSince = lastCalibratedAt != null
        ? DateTime.now().difference(lastCalibratedAt).inDays
        : 0;

    final needsRecalibration = daysSince > 30;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.insights,
                  color: AppColors.cyan,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Calibration Summary',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      '${baselines.length} exercises calibrated',
                      style: TextStyle(
                        fontSize: 13,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (lastCalibratedAt != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: needsRecalibration ? AppColors.warning : textMuted,
                ),
                const SizedBox(width: 8),
                Text(
                  'Last calibrated ${_formatDate(lastCalibratedAt)} ($daysSince days ago)',
                  style: TextStyle(
                    fontSize: 13,
                    color: needsRecalibration ? AppColors.warning : textMuted,
                  ),
                ),
              ],
            ),
            if (needsRecalibration) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.update, size: 14, color: AppColors.warning),
                    const SizedBox(width: 6),
                    Text(
                      'Recalibration recommended',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildBaselineCard({
    required StrengthBaseline baseline,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
    required Color elevated,
    required Color cardBorder,
  }) {
    final levelColor = _getLevelColor(baseline.strengthLevel);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          // Exercise info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  baseline.exerciseName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (baseline.baselineWeight > 0) ...[
                      Icon(Icons.fitness_center, size: 14, color: textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '${baseline.baselineWeight.toStringAsFixed(0)} lbs',
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (baseline.baselineReps > 0) ...[
                      Icon(Icons.repeat, size: 14, color: textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '${baseline.baselineReps} reps',
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
                if (baseline.estimatedOneRepMax > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.trending_up, size: 14, color: AppColors.purple),
                      const SizedBox(width: 4),
                      Text(
                        'Est. 1RM: ${baseline.estimatedOneRepMax.toStringAsFixed(0)} lbs',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.purple,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Strength level badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: levelColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _formatStrengthLevel(baseline.strengthLevel),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: levelColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMuscleGroup(String muscleGroup) {
    return muscleGroup
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  String _formatStrengthLevel(String level) {
    return level.isEmpty ? 'Unknown' : '${level[0].toUpperCase()}${level.substring(1)}';
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  Color _getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return AppColors.success;
      case 'intermediate':
        return AppColors.cyan;
      case 'advanced':
        return AppColors.purple;
      default:
        return AppColors.textMuted;
    }
  }
}
