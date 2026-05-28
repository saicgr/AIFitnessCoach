/// F3.69 — Tomorrow's workout preview tile.
///
/// Evening sub-card that previews tomorrow's planned session so the user
/// can mentally prep. Tap routes to the workouts list.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/providers/today_workout_provider.dart';
import '../../../../data/services/haptic_service.dart';

class TomorrowPreviewTile extends ConsumerWidget {
  final bool show;
  final String? workoutName;
  final String? workoutType;
  final int? durationMin;
  final int? exerciseCount;

  const TomorrowPreviewTile({
    super.key,
    this.show = true,
    this.workoutName,
    this.workoutType,
    this.durationMin,
    this.exerciseCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!show) return const SizedBox.shrink();
    final c = ThemeColors.of(context);

    // Pull tomorrow's planned workout from the real provider. Constructor
    // overrides win (used by previews / tests); otherwise watch live.
    final tomorrow = ref.watch(tomorrowWorkoutProvider).valueOrNull;
    final resolvedName = workoutName ?? tomorrow?.name;
    final resolvedType = workoutType ?? tomorrow?.type;
    final resolvedDuration = durationMin ?? tomorrow?.durationMinutes;
    final resolvedExerciseCount = exerciseCount ?? tomorrow?.exerciseCount;
    final hasWorkout = resolvedName != null && resolvedName.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticService.light();
          context.push('/workouts');
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('🌅', style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    'TOMORROW',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: c.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                hasWorkout ? resolvedName : 'Rest day',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (hasWorkout) ...[
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (resolvedType != null)
                      _MetaText(text: resolvedType, c: c),
                    if (resolvedDuration != null)
                      _MetaText(text: '${resolvedDuration}m', c: c),
                    if (resolvedExerciseCount != null)
                      _MetaText(text: '$resolvedExerciseCount exercises', c: c),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 2),
                Text(
                  'Recovery is the work, too.',
                  style: TextStyle(
                      fontSize: 12,
                      color: c.textSecondary,
                      height: 1.3),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaText extends StatelessWidget {
  final String text;
  final ThemeColors c;
  const _MetaText({required this.text, required this.c});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
          fontSize: 11.5,
          color: c.textSecondary,
          fontWeight: FontWeight.w600),
    );
  }
}
