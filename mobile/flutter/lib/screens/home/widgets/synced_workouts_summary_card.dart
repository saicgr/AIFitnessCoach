import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/workout.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../widgets/main_shell.dart' show floatingNavBarVisibleProvider;

/// Single carousel slide that aggregates all Health-Connect / Apple-Health
/// synced workouts for one day. Replaces the prior "one cyan card per synced
/// row" design which crowded the carousel when a watch logged 6+ activities.
class SyncedWorkoutsSummaryCard extends StatelessWidget {
  final DateTime date;
  final List<Workout> workouts;
  final bool isToday;

  const SyncedWorkoutsSummaryCard({
    super.key,
    required this.date,
    required this.workouts,
    required this.isToday,
  });

  int get _totalDurationMinutes =>
      workouts.fold(0, (sum, w) => sum + w.bestDurationMinutes);

  int get _totalCalories =>
      workouts.fold(0, (sum, w) => sum + w.estimatedCalories);

  Set<String> get _platforms =>
      workouts.map((w) => w.syncedPlatformLabel).toSet();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cyan = AppColors.cyan;
    final count = workouts.length;
    final platformLabel = _platforms.length == 1
        ? _platforms.first
        : '${_platforms.length} sources';
    final dayLabel = isToday
        ? 'Today'
        : '${_weekdayName(date.weekday)} ${date.month}/${date.day}';

    return GestureDetector(
      onTap: () {
        HapticService.light();
        final container = ProviderScope.containerOf(context, listen: false);
        container.read(floatingNavBarVisibleProvider.notifier).state = false;
        showGlassSheet<void>(
          context: context,
          builder: (_) => GlassSheet(
            child: _SyncedWorkoutsSheet(
              date: date,
              workouts: workouts,
              isToday: isToday,
            ),
          ),
        ).whenComplete(() {
          Future.microtask(() {
            try {
              container.read(floatingNavBarVisibleProvider.notifier).state = true;
            } catch (_) {}
          });
        });
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cyan.withValues(alpha: isDark ? 0.28 : 0.22),
              cyan.withValues(alpha: isDark ? 0.12 : 0.10),
            ],
          ),
          border: Border.all(color: cyan.withValues(alpha: 0.45), width: 1),
          boxShadow: [
            BoxShadow(
              color: cyan.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Pill(
                  label: dayLabel.toUpperCase(),
                  color: cyan,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _Pill(
                  label: 'SYNCED',
                  color: cyan,
                  isDark: isDark,
                ),
                const Spacer(),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cyan,
                    boxShadow: [
                      BoxShadow(
                        color: cyan.withValues(alpha: 0.5),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.favorite_rounded,
                      color: Colors.white, size: 20),
                ),
              ],
            ),
            const Spacer(),
            Text(
              count == 1 ? '1 synced workout' : '$count synced workouts',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'from $platformLabel',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _Stat(
                  icon: Icons.timer_outlined,
                  value: _totalDurationMinutes > 0
                      ? '${_totalDurationMinutes}m'
                      : '—',
                  isDark: isDark,
                ),
                const SizedBox(width: 22),
                _Stat(
                  icon: Icons.local_fire_department_outlined,
                  value:
                      _totalCalories > 0 ? '$_totalCalories cal' : '—',
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: cyan.withValues(alpha: isDark ? 0.18 : 0.14),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: cyan.withValues(alpha: 0.3), width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart, size: 16, color: cyan),
                  const SizedBox(width: 8),
                  Text(
                    'View all $count',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _weekdayName(int weekday) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[(weekday - 1) % 7];
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;
  const _Pill({required this.label, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.22 : 0.16),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : Colors.black87,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String value;
  final bool isDark;
  const _Stat({required this.icon, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: isDark ? Colors.white : Colors.black87),
        const SizedBox(width: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _SyncedWorkoutsSheet extends StatelessWidget {
  final DateTime date;
  final List<Workout> workouts;
  final bool isToday;

  const _SyncedWorkoutsSheet({
    required this.date,
    required this.workouts,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surface : Colors.white;
    final cyan = AppColors.cyan;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(Icons.favorite_rounded, color: cyan, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isToday
                            ? 'Today\'s synced workouts'
                            : 'Synced ${date.month}/${date.day}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 22),
                      color: isDark ? Colors.white70 : Colors.black54,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  itemCount: workouts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) =>
                      _SyncedRow(workout: workouts[i], isDark: isDark),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SyncedRow extends StatelessWidget {
  final Workout workout;
  final bool isDark;
  const _SyncedRow({required this.workout, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cyan = AppColors.cyan;
    final meta = workout.generationMetadata ?? const <String, dynamic>{};
    final activityKind = meta['hc_activity_kind']?.toString();
    final startIso = meta['start_time_iso']?.toString();
    final endIso = meta['end_time_iso']?.toString();
    final steps = meta['steps'] ?? meta['total_steps'];

    final timeRange = _formatTimeRange(startIso, endIso);
    final calories = workout.estimatedCalories;
    final duration = workout.bestDurationMinutes;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: cyan.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cyan.withValues(alpha: 0.2),
                ),
                child: Icon(Icons.favorite_rounded,
                    color: cyan, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workout.name?.isNotEmpty == true
                          ? workout.name!
                          : (activityKind ?? 'Workout'),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      workout.syncedPlatformLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              if (timeRange != null)
                Text(
                  timeRange,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              if (duration > 0)
                _MiniStat(
                    icon: Icons.timer_outlined,
                    label: '${duration}m',
                    isDark: isDark),
              if (calories > 0)
                _MiniStat(
                    icon: Icons.local_fire_department_outlined,
                    label: '$calories cal',
                    isDark: isDark),
              if (steps != null)
                _MiniStat(
                    icon: Icons.directions_walk,
                    label: '$steps steps',
                    isDark: isDark),
              if (activityKind != null && workout.name?.isEmpty != false)
                _MiniStat(
                    icon: Icons.category_outlined,
                    label: activityKind,
                    isDark: isDark),
            ],
          ),
        ],
      ),
    );
  }

  static String? _formatTimeRange(String? startIso, String? endIso) {
    DateTime? parse(String? iso) {
      if (iso == null || iso.isEmpty) return null;
      try {
        return DateTime.parse(iso).toLocal();
      } catch (_) {
        return null;
      }
    }

    final start = parse(startIso);
    if (start == null) return null;
    final end = parse(endIso);
    String fmt(DateTime t) {
      final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
      final m = t.minute.toString().padLeft(2, '0');
      final am = t.hour < 12 ? 'AM' : 'PM';
      return '$h:$m $am';
    }

    if (end == null) return fmt(start);
    return '${fmt(start)} – ${fmt(end)}';
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  const _MiniStat(
      {required this.icon, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: isDark ? Colors.white60 : Colors.black54),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      ],
    );
  }
}
