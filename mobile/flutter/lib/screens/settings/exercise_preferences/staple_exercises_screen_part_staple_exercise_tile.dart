part of 'staple_exercises_screen.dart';


class _StapleExerciseTile extends ConsumerWidget {
  final StapleExercise staple;
  final bool isDark;
  final Color textPrimary;
  final Color textMuted;
  final Color elevated;
  final bool showProfileBadge;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const _StapleExerciseTile({
    required this.staple,
    required this.isDark,
    required this.textPrimary,
    required this.textMuted,
    required this.elevated,
    this.showProfileBadge = false,
    required this.onEdit,
    required this.onRemove,
  });

  void _showDetail(BuildContext context, WidgetRef ref) {
    // Browse mode resolves media + stats from the library row itself, so we
    // just thread the staple's libraryId + name through.
    openExerciseBrowse(
      context,
      name: staple.exerciseName,
      exerciseId: staple.libraryId,
      libraryId: staple.libraryId,
    );
  }

  Color _badgeColor(String? reason) {
    switch (reason) {
      case 'core_compound':
        return AppColors.cyan;  // accent-allowlist: no BuildContext available at this site (static/const data) - see accent rules edge case
      case 'favorite':
        return Colors.redAccent;  // accent-allowlist: categorical staple-reason badge legend (core_compound/favorite/rehab each need a distinct colour)
      case 'rehab':
        return Colors.green;  // accent-allowlist: success/positive state - must stay green regardless of accent
      case 'strength_focus':
        return Colors.orange;  // accent-allowlist: warning severity - must stay amber regardless of accent (table classifies Material Colors.orange as warning-family, distinct from the app's AppColors.orange accent)
      default:
        return AppColors.cyan;  // accent-allowlist: no BuildContext available at this site (static/const data) - see accent rules edge case
    }
  }

  IconData _badgeIcon(String? reason) {
    switch (reason) {
      case 'core_compound':
        return Icons.fitness_center;
      case 'favorite':
        return Icons.favorite;
      case 'rehab':
        return Icons.healing;
      case 'strength_focus':
        return Icons.trending_up;
      default:
        return Icons.push_pin;
    }
  }

  /// Renders the staple's customised prescription, e.g. "50 lb · 4 × 10 ·
  /// 90s rest" — mirrors the edit sheet's unit handling (`user_weight_lbs`
  /// is always stored in pounds; convert to the user's current workout
  /// weight unit for display, same as `_showEditStapleSheet`).
  String _prescriptionDisplay(WidgetRef ref) {
    final useKg = ref.watch(useKgForWorkoutProvider);
    final parts = <String>[];
    if (staple.userWeightLbs != null) {
      final weight = useKg
          ? WeightUtils.lbsToKg(staple.userWeightLbs!)
          : staple.userWeightLbs!;
      parts.add('${WeightUtils.formatWeightValue(weight)} ${WeightUtils.workoutUnitLabel(useKg)}');
    }
    final reps = staple.userReps?.trim();
    if (staple.userSets != null || (reps != null && reps.isNotEmpty)) {
      final sets = staple.userSets?.toString() ?? '-';
      parts.add(reps != null && reps.isNotEmpty ? '$sets × $reps' : '$sets sets');
    }
    if (staple.userRestSeconds != null) {
      parts.add('${staple.userRestSeconds}s rest');
    }
    return parts.join(' · ');
  }

  Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppColors.cyan;  // accent-allowlist: no BuildContext available at this site (static/const data) - see accent rules edge case
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _badgeColor(staple.reason);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(12),
        border: isDark ? null : Border.all(color: AppColorsLight.cardBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () => _showDetail(context, ref),
        leading: SizedBox(
          width: 56,
          height: 56,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ExerciseImage(
                exerciseName: staple.exerciseName,
                width: 56,
                height: 56,
                borderRadius: 12,
              ),
              // Play icon overlay to indicate tappable for video
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.play_circle_outline,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
              // Reason badge
              PositionedDirectional(end: -3,
                top: -3,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: elevated, width: 1.5),
                  ),
                  child: Icon(_badgeIcon(staple.reason), color: Colors.white, size: 10),
                ),
              ),
            ],
          ),
        ),
        title: Text(
          staple.exerciseName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section badge + muscle group row
            Row(
              children: [
                if (staple.section != 'main')
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: staple.section == 'warmup'
                            ? Colors.orange.withValues(alpha: 0.15)  // accent-allowlist: warning severity - must stay amber regardless of accent (table classifies Material Colors.orange as warning-family, distinct from the app's AppColors.orange accent)
                            : Colors.teal.withValues(alpha: 0.15),  // accent-allowlist: categorical warmup-vs-stretch section badge colour
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        staple.section == 'warmup' ? AppLocalizations.of(context).workoutSummaryAdvancedWarmup : AppLocalizations.of(context).stapleExercisesScreenStretch,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: staple.section == 'warmup' ? Colors.orange : Colors.teal,  // accent-allowlist: categorical warmup-vs-stretch section badge colour
                        ),
                      ),
                    ),
                  ),
                if (staple.muscleGroup != null)
                  Flexible(
                    child: Text(
                      staple.muscleGroup!,
                      style: TextStyle(
                        fontSize: 12,
                        color: textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
            if (staple.hasCustomPrescription)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        _prescriptionDisplay(ref),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: context.accentColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: context.accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        AppLocalizations.of(context).stapleExercisesScreenCustomised,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: context.accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (staple.isCardioEquipment)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  staple.cardioParamsDisplay,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            if (staple.reason != null)
              Text(
                _formatReason(staple.reason!),
                style: TextStyle(
                  fontSize: 11,
                  color: color.withValues(alpha: 0.8),
                ),
              ),
            if (showProfileBadge && (staple.gymProfileName != null || staple.gymProfileId == null))
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: staple.gymProfileColor != null
                            ? _parseColor(staple.gymProfileColor!)
                            : textMuted.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      staple.gymProfileName ?? AppLocalizations.of(context).stapleExercisesScreenAllProfiles,
                      style: TextStyle(
                        fontSize: 10,
                        color: textMuted.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit_outlined, color: context.accentColor),
              onPressed: onEdit,
              tooltip: AppLocalizations.of(context).commonEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),  // accent-allowlist: error/destructive - must stay red
              onPressed: onRemove,
              tooltip: AppLocalizations.of(context).workoutPlanDrawerRemove,
            ),
          ],
        ),
      ),
    );
  }

  String _formatReason(String reason) {
    switch (reason) {
      case 'core_compound':
        return 'Core Compound';
      case 'favorite':
        return 'Personal Favorite';
      case 'rehab':
        return 'Rehab / Recovery';
      case 'strength_focus':
        return 'Strength Focus';
      default:
        return reason.replaceAll('_', ' ').split(' ').map((w) =>
          w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
    }
  }
}


/// Exercise type classification for edit sheet field selection
enum _ExerciseType {
  strength,
  timed,
  treadmill,
  bike,
  rower,
  elliptical,
  cardioGeneric,
}

