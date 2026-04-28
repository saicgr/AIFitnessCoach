import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health/health.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/sauna_log.dart';
import '../../../data/providers/today_workout_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/sauna_repository.dart';
import '../../../data/services/health_service.dart';
import '../../../widgets/glass_sheet.dart';
import 'package:fitwiz/core/constants/branding.dart';

/// Bottom sheet showing today's completed workouts and their calorie contributions
class CaloriesBurnedSheet extends ConsumerStatefulWidget {
  final double totalBurned;

  const CaloriesBurnedSheet({super.key, required this.totalBurned});

  @override
  ConsumerState<CaloriesBurnedSheet> createState() => _CaloriesBurnedSheetState();
}

class _CaloriesBurnedSheetState extends ConsumerState<CaloriesBurnedSheet> {
  List<_WorkoutEntry> _healthWorkouts = [];
  bool _loadingHealth = true;
  DailySaunaSummary? _saunaSummary;
  bool _loadingSauna = true;

  @override
  void initState() {
    super.initState();
    _loadHealthWorkouts();
    _loadSaunaSummary();
  }

  Future<void> _loadSaunaSummary() async {
    try {
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id;
      if (userId == null) {
        if (mounted) setState(() => _loadingSauna = false);
        return;
      }
      final repo = ref.read(saunaRepositoryProvider);
      final summary = await repo.getDailySummary(userId);
      if (mounted) {
        setState(() {
          _saunaSummary = summary;
          _loadingSauna = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading sauna summary: $e');
      if (mounted) setState(() => _loadingSauna = false);
    }
  }

  Future<void> _loadHealthWorkouts() async {
    try {
      final healthService = ref.read(healthServiceProvider);
      final sessions = await healthService.getWorkoutSessions(days: 1);

      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);

      final todaySessions = sessions.where((p) =>
          p.dateFrom.isAfter(todayStart) || p.dateFrom.isAtSameMomentAs(todayStart));

      final entries = <_WorkoutEntry>[];
      for (final point in todaySessions) {
        final workout = point.value as WorkoutHealthValue;
        final duration = point.dateTo.difference(point.dateFrom).inMinutes;
        final calories = workout.totalEnergyBurned?.toDouble();

        entries.add(_WorkoutEntry(
          name: _formatActivityType(workout.workoutActivityType),
          durationMinutes: duration < 1 ? 1 : duration,
          caloriesBurned: calories,
          startTime: point.dateFrom,
          source: point.sourceName,
          isFromHealth: true,
        ));
      }

      if (mounted) {
        setState(() {
          _healthWorkouts = entries;
          _loadingHealth = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading health workouts: $e');
      if (mounted) {
        setState(() => _loadingHealth = false);
      }
    }
  }

  /// Rough kcal estimate when Zealova hasn't stored per-workout calories.
  /// Uses ~5 kcal/min (moderate strength training MET ≈ 5 for a 75 kg user).
  /// Returns null when duration is 0 so the tile collapses the kcal pill.
  static double? _estimateCaloriesFromDuration(int durationMinutes) {
    if (durationMinutes <= 0) return null;
    return (durationMinutes * 5).toDouble();
  }

  String _formatActivityType(HealthWorkoutActivityType type) {
    final name = type.name;
    // Convert ENUM_NAME to Title Case
    return name
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final green = isDark ? AppColors.green : AppColorsLight.green;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    // Get Zealova completed workouts
    final todayState = ref.watch(todayWorkoutProvider);
    final todayData = todayState.valueOrNull;
    final completedWorkout = todayData?.completedWorkout;
    final extraWorkouts = todayData?.extraTodayWorkouts
            .where((w) => w.isCompleted)
            .toList() ??
        [];

    // Build combined list
    final fitWizWorkouts = <_WorkoutEntry>[];
    if (completedWorkout != null) {
      fitWizWorkouts.add(_WorkoutEntry(
        name: completedWorkout.name,
        durationMinutes: completedWorkout.durationMinutes,
        // Zealova doesn't store per-workout calories — estimate from duration
        // using a moderate-intensity MET (~5 kcal/min) so the per-source
        // breakdown shows a non-zero in-app contribution.
        caloriesBurned: _estimateCaloriesFromDuration(completedWorkout.durationMinutes),
        source: '${Branding.appName}',
        isFromHealth: false,
      ));
    }
    for (final w in extraWorkouts) {
      fitWizWorkouts.add(_WorkoutEntry(
        name: w.name,
        durationMinutes: w.durationMinutes,
        caloriesBurned: _estimateCaloriesFromDuration(w.durationMinutes),
        source: '${Branding.appName}',
        isFromHealth: false,
      ));
    }

    final hasSauna = _saunaSummary != null && _saunaSummary!.entries.isNotEmpty;
    final hasAnyWorkouts =
        fitWizWorkouts.isNotEmpty || _healthWorkouts.isNotEmpty || hasSauna;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.local_fire_department, color: green, size: 22),
              const SizedBox(width: 8),
              Text(
                "Today's Activity",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${widget.totalBurned.toInt()} kcal',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Calories burned from workouts today',
            style: TextStyle(fontSize: 13, color: textMuted),
          ),
          const SizedBox(height: 12),

          // Per-source breakdown so users can see how much came from in-app
          // workouts vs HealthKit/wearable sync vs sauna. Without this users
          // can't reconcile (e.g.) "I only did 1 set in the app but it says
          // 526 kcal" — the 526 is from a synced wearable session.
          Builder(builder: (_) {
            final inApp = fitWizWorkouts.fold<double>(
              0.0,
              (acc, w) => acc + (w.caloriesBurned ?? 0),
            );
            final synced = _healthWorkouts.fold<double>(
              0.0,
              (acc, w) => acc + (w.caloriesBurned ?? 0),
            );
            final saunaTotal = _saunaSummary?.entries.fold<double>(
                  0.0,
                  (acc, e) => acc + (e.estimatedCalories ?? 0).toDouble(),
                ) ??
                0.0;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _BreakdownChip(
                  label: 'In-app',
                  value: inApp.round(),
                  color: AppColors.cyan,
                ),
                _BreakdownChip(
                  label: 'Synced',
                  value: synced.round(),
                  color: AppColors.green,
                ),
                if (saunaTotal > 0)
                  _BreakdownChip(
                    label: 'Sauna',
                    value: saunaTotal.round(),
                    color: const Color(0xFFE65100),
                  ),
              ],
            );
          }),
          const SizedBox(height: 16),

          // Zealova workouts section
          if (fitWizWorkouts.isNotEmpty) ...[
            _SectionLabel(label: '${Branding.appName} Workouts', color: AppColors.cyan),
            const SizedBox(height: 8),
            for (final w in fitWizWorkouts)
              _WorkoutTile(
                entry: w,
                isDark: isDark,
                elevated: elevated,
                cardBorder: cardBorder,
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
            const SizedBox(height: 12),
          ],

          // Health platform workouts section
          if (_loadingHealth)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: green,
                  ),
                ),
              ),
            )
          else if (_healthWorkouts.isNotEmpty) ...[
            _SectionLabel(
              label: 'Synced from Health',
              color: AppColors.green,
            ),
            const SizedBox(height: 8),
            for (final w in _healthWorkouts)
              _WorkoutTile(
                entry: w,
                isDark: isDark,
                elevated: elevated,
                cardBorder: cardBorder,
                textPrimary: textPrimary,
                textMuted: textMuted,
                timeLabel: w.startTime != null ? _formatTime(w.startTime!) : null,
              ),
          ],

          // Sauna section
          if (!_loadingSauna && _saunaSummary != null && _saunaSummary!.entries.isNotEmpty) ...[
            _SectionLabel(
              label: 'Sauna',
              color: const Color(0xFFE65100),
            ),
            const SizedBox(height: 8),
            for (final entry in _saunaSummary!.entries)
              _WorkoutTile(
                entry: _WorkoutEntry(
                  name: 'Sauna Session',
                  durationMinutes: entry.durationMinutes,
                  caloriesBurned: entry.estimatedCalories?.toDouble(),
                  source: '${Branding.appName}',
                  isFromHealth: false,
                ),
                isDark: isDark,
                elevated: elevated,
                cardBorder: cardBorder,
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
            const SizedBox(height: 12),
          ],

          // Empty state
          if (!_loadingHealth && !hasAnyWorkouts && (_saunaSummary == null || _saunaSummary!.entries.isEmpty))
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(Icons.fitness_center, size: 36, color: textMuted),
                  const SizedBox(height: 8),
                  Text(
                    'No workouts recorded today',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Complete a workout or sync from your health app',
                    style: TextStyle(fontSize: 12, color: textMuted),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Section header label
class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;

  const _SectionLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

/// Individual workout tile
class _WorkoutTile extends StatelessWidget {
  final _WorkoutEntry entry;
  final bool isDark;
  final Color elevated;
  final Color cardBorder;
  final Color textPrimary;
  final Color textMuted;
  final String? timeLabel;

  const _WorkoutTile({
    required this.entry,
    required this.isDark,
    required this.elevated,
    required this.cardBorder,
    required this.textPrimary,
    required this.textMuted,
    this.timeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = entry.isFromHealth ? AppColors.green : AppColors.cyan;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                entry.isFromHealth
                    ? Icons.watch_outlined
                    : Icons.fitness_center,
                size: 18,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '${entry.durationMinutes} min',
                        style: TextStyle(fontSize: 12, color: textMuted),
                      ),
                      if (entry.source != null) ...[
                        Text(
                          '  ·  ',
                          style: TextStyle(fontSize: 12, color: textMuted),
                        ),
                        Text(
                          entry.source!,
                          style: TextStyle(fontSize: 12, color: textMuted),
                        ),
                      ],
                      if (timeLabel != null) ...[
                        Text(
                          '  ·  ',
                          style: TextStyle(fontSize: 12, color: textMuted),
                        ),
                        Text(
                          timeLabel!,
                          style: TextStyle(fontSize: 12, color: textMuted),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (entry.caloriesBurned != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${entry.caloriesBurned!.toInt()} kcal',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.orange,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Per-source breakdown chip rendered above the sectioned list.
class _BreakdownChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _BreakdownChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$value kcal',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Internal data model for workout entries
class _WorkoutEntry {
  final String name;
  final int durationMinutes;
  final double? caloriesBurned;
  final DateTime? startTime;
  final String? source;
  final bool isFromHealth;

  const _WorkoutEntry({
    required this.name,
    required this.durationMinutes,
    this.caloriesBurned,
    this.startTime,
    this.source,
    required this.isFromHealth,
  });
}

/// Helper to show the calories burned sheet
void showCaloriesBurnedSheet(BuildContext context, double totalBurned) {
  showGlassSheet(
    context: context,
    useRootNavigator: true,
    builder: (context) => GlassSheet(
      child: CaloriesBurnedSheet(totalBurned: totalBurned),
    ),
  );
}
