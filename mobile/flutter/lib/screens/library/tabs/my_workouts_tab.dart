import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/widgets/skeleton/skeleton_list.dart';
import '../../../data/models/workout.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../workout/import_workout_screen.dart';
import '../../common/app_refresh_indicator.dart';

/// Which slice of the user's `workouts` table this tab renders.
enum MyWorkoutsMode {
  /// Generated / planned workouts (AI, RAG, quick, staple…).
  generated,

  /// Workouts the user built themselves (full-screen builder → `manual`) or
  /// AI-imported (`ai_import`).
  custom,
}

/// The Library "Workouts" and "Custom" pills. Both read the same already-warmed
/// [workoutsProvider] (the `workouts` table) and partition by
/// `generation_method`:
///   • Custom  = `manual` (custom_builder) or `ai_import`
///   • Workouts = everything else, minus health-synced + logged rows
///
/// Saved/bookmarked workouts (the `saved_workouts` table) live behind the
/// Library header's ☆ icon, not here.
class MyWorkoutsTab extends ConsumerWidget {
  final MyWorkoutsMode mode;
  const MyWorkoutsTab({super.key, required this.mode});

  static bool _isCustom(Workout w) {
    final m = (w.generationMethod ?? '').toLowerCase();
    return m == 'manual' || m == 'ai_import';
  }

  static bool _isGenerated(Workout w) {
    final m = (w.generationMethod ?? '').toLowerCase();
    if (m == 'manual' || m == 'ai_import') return false;
    if (m == 'health_connect_import' || m == 'manual_log') return false;
    return true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tc = ThemeColors.of(context);
    final accent = ref.watch(accentColorProvider).getColor(isDark);
    final async = ref.watch(workoutsProvider);

    final all = async.valueOrNull ?? const <Workout>[];
    final list = all
        .where(mode == MyWorkoutsMode.custom ? _isCustom : _isGenerated)
        .toList()
      ..sort((a, b) =>
          (b.scheduledDate ?? '').compareTo(a.scheduledDate ?? ''));

    Future<void> refresh() => ref.read(workoutsProvider.notifier).refresh();

    return Column(
      children: [
        if (mode == MyWorkoutsMode.custom) _CustomActions(accent: accent),
        Expanded(
          child: Builder(
            builder: (_) {
              if (async.isLoading && all.isEmpty) {
                return const SkeletonList(
                  itemCount: 6,
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 24),
                  scrollable: true,
                  itemBuilder: _skeletonRow,
                );
              }
              if (async.hasError && all.isEmpty) {
                return _Empty(
                  icon: Icons.error_outline_rounded,
                  title: 'Could not load workouts',
                  subtitle: 'Pull down to retry.',
                  tc: tc,
                  onRefresh: refresh,
                );
              }
              if (list.isEmpty) {
                return _Empty(
                  icon: mode == MyWorkoutsMode.custom
                      ? Icons.construction_rounded
                      : Icons.fitness_center_rounded,
                  title: mode == MyWorkoutsMode.custom
                      ? 'No custom workouts yet'
                      : 'No workouts yet',
                  subtitle: mode == MyWorkoutsMode.custom
                      ? 'Tap "Build a workout" or "Import with AI" above to create one.'
                      : 'Your generated and planned workouts will show up here.',
                  tc: tc,
                  onRefresh: refresh,
                );
              }
              return AppRefreshIndicator(
                onRefresh: refresh,
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) =>
                      _WorkoutTile(workout: list[i], accent: accent),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Build + Import actions shown above the Custom workouts list.
class _CustomActions extends StatelessWidget {
  final Color accent;
  const _CustomActions({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              icon: Icons.construction_rounded,
              label: 'Build a workout',
              filled: true,
              accent: accent,
              onTap: () {
                HapticService.selection();
                context.push('/workout/build');
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionButton(
              icon: Icons.auto_awesome_rounded,
              label: 'Import with AI',
              filled: false,
              accent: accent,
              onTap: () {
                HapticService.selection();
                showImportWorkoutScreen(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final Color accent;
  final VoidCallback onTap;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.filled,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = filled
        ? const Color(0xFF160B03)
        : (isDark ? AppColors.textPrimary : AppColorsLight.textPrimary);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: filled ? accent : accent.withValues(alpha: 0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: filled ? fg : accent),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ZType.lbl(12, color: filled ? fg : accent, letterSpacing: 1.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutTile extends StatelessWidget {
  final Workout workout;
  final Color accent;
  const _WorkoutTile({required this.workout, required this.accent});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final name = (workout.name ?? 'Workout').trim();
    final exercises = workout.exerciseCount;
    final duration = workout.durationMinutes;
    final done = workout.isCompleted == true;

    final subtitleParts = <String>[
      '$exercises ${exercises == 1 ? 'exercise' : 'exercises'}',
      if (duration != null && duration > 0) '$duration min',
      if (done) 'completed',
    ];

    return Material(
      color: tc.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          HapticService.light();
          if (workout.id != null) {
            context.push('/workout/${workout.id}', extra: workout);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tc.elevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Icon(
                  done
                      ? Icons.check_circle_rounded
                      : Icons.fitness_center_rounded,
                  color: done ? accent : tc.textPrimary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: tc.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitleParts.join(' • ').toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          ZType.lbl(10.5, color: tc.textMuted, letterSpacing: 1.2),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: tc.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final ThemeColors tc;
  final Future<void> Function() onRefresh;
  const _Empty({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tc,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return AppRefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 90),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 48, color: tc.textMuted),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: tc.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: tc.textMuted, fontSize: 13.5, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _skeletonRow(BuildContext context, int index) =>
    const SkeletonCard(showLeading: true, leadingSize: 44, lines: 2);
