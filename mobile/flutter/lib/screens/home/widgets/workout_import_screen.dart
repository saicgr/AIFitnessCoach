import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/heart_rate_provider.dart';
import '../../../data/models/workout.dart';
import '../../../data/providers/health_import_provider.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../../data/services/health_import_service.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../widgets/sheet_header.dart';

// ---------------------------------------------------------------------------
// Public API: call this to show the import sheet from home_screen.dart
// ---------------------------------------------------------------------------

/// Shows the workout import bottom sheet for a list of pending imports.
///
/// Displays one workout at a time. After the user imports or skips each one,
/// the sheet advances to the next. Closes automatically when all are handled.
Future<void> showWorkoutImportSheet(BuildContext context, WidgetRef ref) {
  return showGlassSheet(
    context: context,
    builder: (ctx) => GlassSheet(
      showHandle: true,
      maxHeightFraction: 0.85,
      child: _WorkoutImportContent(parentRef: ref),
    ),
  );
}

// ---------------------------------------------------------------------------
// Sheet content (ConsumerStatefulWidget so we can trigger HR enrichment)
// ---------------------------------------------------------------------------

class _WorkoutImportContent extends ConsumerStatefulWidget {
  final WidgetRef parentRef;

  const _WorkoutImportContent({required this.parentRef});

  @override
  ConsumerState<_WorkoutImportContent> createState() =>
      _WorkoutImportContentState();
}

class _WorkoutImportContentState extends ConsumerState<_WorkoutImportContent> {
  int _currentIndex = 0;
  String _selectedDifficulty = 'intermediate';
  bool _hrEnriched = false;

  @override
  void initState() {
    super.initState();
    _triggerHREnrichment();
  }

  void _triggerHREnrichment() {
    // Enrich the current workout with HR data in the background.
    final state = ref.read(healthImportProvider);
    if (state.pendingImports.isNotEmpty &&
        _currentIndex < state.pendingImports.length) {
      final current = state.pendingImports[_currentIndex];
      if (current.avgHeartRate == null) {
        ref
            .read(healthImportProvider.notifier)
            .enrichCurrentWorkoutHR(_currentIndex);
      }
    }
  }

  /// Find a matching FitWiz workout for the same date that is not completed.
  Workout? _findMatchingWorkout(
      List<Workout> workouts, PendingWorkoutImport pending) {
    final pendingDate = DateTime(
      pending.startTime.year,
      pending.startTime.month,
      pending.startTime.day,
    );
    for (final w in workouts) {
      if (w.id == null) continue;
      if (w.isCompleted == true) continue;
      if (w.scheduledDate == null) continue;
      try {
        final scheduled = DateTime.parse(w.scheduledDate!);
        final scheduledDate = DateTime(
          scheduled.year,
          scheduled.month,
          scheduled.day,
        );
        if (scheduledDate == pendingDate) return w;
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  IconData _activityIcon(String type) {
    switch (type) {
      case 'strength':
        return Icons.fitness_center;
      case 'cardio':
        return Icons.directions_run;
      case 'flexibility':
        return Icons.self_improvement;
      case 'hiit':
        return Icons.local_fire_department;
      default:
        return Icons.fitness_center;
    }
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }

  String _formatDateTime(DateTime dt) {
    return DateFormat('EEE, MMM d').format(dt) +
        ' at ' +
        DateFormat('h:mm a').format(dt);
  }

  String _activityLabel(String type) {
    switch (type) {
      case 'strength':
        return 'Strength Training';
      case 'cardio':
        return 'Cardio';
      case 'flexibility':
        return 'Flexibility';
      case 'hiit':
        return 'HIIT';
      default:
        return 'Workout';
    }
  }

  void _handleImport(PendingWorkoutImport pending) {
    HapticService.medium();
    ref
        .read(healthImportProvider.notifier)
        .importAsNewWorkout(pending, _selectedDifficulty);
  }

  void _handleSkip(PendingWorkoutImport pending) {
    HapticService.light();
    ref.read(healthImportProvider.notifier).skipWorkout(pending);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    final importState = ref.watch(healthImportProvider);
    final pending = importState.pendingImports;

    // Auto-close when no more pending imports.
    if (pending.isEmpty && !importState.isImporting) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
      return const SizedBox.shrink();
    }

    // Clamp current index.
    if (_currentIndex >= pending.length) {
      _currentIndex = pending.isEmpty ? 0 : pending.length - 1;
    }

    // When HR data arrives, mark enriched so we skip re-fetching.
    final current = pending.isNotEmpty ? pending[_currentIndex] : null;
    if (current != null && current.avgHeartRate != null && !_hrEnriched) {
      _hrEnriched = true;
    }

    // Look for matching FitWiz workout.
    final workoutsAsync = ref.watch(workoutsProvider);
    final matchingWorkout = workoutsAsync.whenOrNull(
      data: (workouts) =>
          current != null ? _findMatchingWorkout(workouts, current) : null,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        SheetHeader(
          icon: Icons.download_rounded,
          iconColor: AppColors.orange,
          title: 'Workout Detected',
          subtitle: pending.length > 1
              ? '${_currentIndex + 1} of ${pending.length}'
              : null,
          showHandle: false,
          onClose: () => Navigator.pop(context),
        ),

        // Body
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: current == null
                ? const SizedBox.shrink()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // -------- Workout summary card --------
                      _buildSummaryCard(
                        context,
                        current,
                        isDark: isDark,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        textMuted: textMuted,
                        cardBorder: cardBorder,
                        elevated: elevated,
                      ),

                      const SizedBox(height: 20),

                      // -------- Effort rating --------
                      Text(
                        'How hard was this workout?',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildEffortButtons(isDark, textPrimary, cardBorder),

                      const SizedBox(height: 24),

                      // -------- Action buttons --------
                      if (importState.isImporting)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: isDark
                                  ? AppColors.accent
                                  : AppColorsLight.accent,
                            ),
                          ),
                        )
                      else ...[
                        // If there's a matching FitWiz workout, show two-option layout
                        if (matchingWorkout != null) ...[
                          _buildPrimaryButton(
                            label:
                                'Mark "${matchingWorkout.name ?? 'Workout'}" as done',
                            onPressed: () {
                              HapticService.medium();
                              ref
                                  .read(healthImportProvider.notifier)
                                  .markExistingWorkoutComplete(
                                    current,
                                    matchingWorkout.id!,
                                  );
                            },
                            isDark: isDark,
                          ),
                          const SizedBox(height: 8),
                          _buildSecondaryButton(
                            label: 'Import as separate workout',
                            onPressed: () => _handleImport(current),
                            isDark: isDark,
                            textSecondary: textSecondary,
                          ),
                        ] else ...[
                          _buildPrimaryButton(
                            label: 'Import Workout',
                            onPressed: () => _handleImport(current),
                            isDark: isDark,
                          ),
                        ],

                        const SizedBox(height: 8),
                        _buildTextButton(
                          label: 'Skip',
                          onPressed: () => _handleSkip(current),
                          textSecondary: textSecondary,
                        ),
                      ],

                      // Error message
                      if (importState.error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: AppColors.error, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  importState.error!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Safe area padding
                      SizedBox(
                          height: MediaQuery.of(context).viewPadding.bottom +
                              16),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  // ===================================================================
  // SUMMARY CARD
  // ===================================================================

  Widget _buildSummaryCard(
    BuildContext context,
    PendingWorkoutImport workout, {
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
    required Color cardBorder,
    required Color elevated,
  }) {
    final typeColor = AppColors.getWorkoutTypeColor(workout.activityType);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: icon + activity type + source
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _activityIcon(workout.activityType),
                  color: typeColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _activityLabel(workout.activityType),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    if (workout.sourceName != null)
                      Text(
                        'from ${workout.sourceName}',
                        style: TextStyle(fontSize: 13, color: textMuted),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Date / time row
          _InfoRow(
            icon: Icons.calendar_today_rounded,
            text: _formatDateTime(workout.startTime),
            textColor: textSecondary,
          ),

          const SizedBox(height: 8),

          // Duration
          _InfoRow(
            icon: Icons.timer_outlined,
            text: _formatDuration(workout.durationMinutes),
            textColor: textSecondary,
          ),

          // Calories
          if (workout.caloriesBurned != null) ...[
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.local_fire_department_outlined,
              text: '${workout.caloriesBurned!.round()} cal burned',
              textColor: textSecondary,
            ),
          ],

          // Distance
          if (workout.distanceMeters != null &&
              workout.distanceMeters! > 0) ...[
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.straighten_rounded,
              text:
                  '${(workout.distanceMeters! / 1000).toStringAsFixed(2)} km',
              textColor: textSecondary,
            ),
          ],

          // Heart rate summary (lazy-loaded via enrichment)
          if (workout.avgHeartRate != null) ...[
            const SizedBox(height: 12),
            _buildHeartRateSection(workout, textPrimary, textSecondary),
          ],
        ],
      ),
    );
  }

  Widget _buildHeartRateSection(
    PendingWorkoutImport workout,
    Color textPrimary,
    Color textSecondary,
  ) {
    final zone = getHeartRateZone(workout.avgHeartRate!);
    final zoneColor = Color(zone.colorValue);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // HR numbers
        Row(
          children: [
            Icon(Icons.favorite_rounded, size: 16, color: AppColors.red),
            const SizedBox(width: 6),
            Text(
              'Avg ${workout.avgHeartRate} bpm',
              style: TextStyle(fontSize: 13, color: textSecondary),
            ),
            if (workout.maxHeartRate != null) ...[
              Text(
                '  |  Max ${workout.maxHeartRate} bpm',
                style: TextStyle(fontSize: 13, color: textSecondary),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        // Zone indicator bar
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (workout.avgHeartRate! / 200).clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: zoneColor.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(zoneColor),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: zoneColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                zone.shortLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: zoneColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ===================================================================
  // EFFORT BUTTONS
  // ===================================================================

  Widget _buildEffortButtons(
      bool isDark, Color textPrimary, Color cardBorder) {
    const efforts = [
      ('Easy', 'beginner', AppColors.green),
      ('Medium', 'intermediate', AppColors.warning),
      ('Hard', 'advanced', AppColors.orange),
    ];

    return Row(
      children: efforts.map((e) {
        final isSelected = _selectedDifficulty == e.$2;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: e.$2 != 'advanced' ? 8 : 0,
            ),
            child: GestureDetector(
              onTap: () {
                HapticService.selection();
                setState(() => _selectedDifficulty = e.$2);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? e.$3.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? e.$3 : cardBorder,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    e.$1,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? e.$3 : textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ===================================================================
  // ACTION BUTTONS
  // ===================================================================

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback onPressed,
    required bool isDark,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: isDark ? AppColors.accent : AppColorsLight.accent,
          foregroundColor:
              isDark ? AppColors.accentContrast : AppColorsLight.accentContrast,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required String label,
    required VoidCallback onPressed,
    required bool isDark,
    required Color textSecondary,
  }) {
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: cardBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textSecondary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildTextButton({
    required String label,
    required VoidCallback onPressed,
    required Color textSecondary,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: TextButton(
        onPressed: onPressed,
        child: Text(
          label,
          style: TextStyle(fontSize: 14, color: textSecondary),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper widget: icon + text row
// ---------------------------------------------------------------------------

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color textColor;

  const _InfoRow({
    required this.icon,
    required this.text,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: textColor),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: textColor),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
