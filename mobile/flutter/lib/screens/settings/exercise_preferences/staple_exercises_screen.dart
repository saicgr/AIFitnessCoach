import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/staples_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/widgets/skeleton/skeleton.dart';
import '../../../data/models/exercise.dart';
import '../../../data/providers/gym_profile_provider.dart';
import '../../../data/repositories/exercise_preferences_repository.dart';
import '../../../data/repositories/library_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/exercise_image.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../widgets/pill_app_bar.dart';
import '../../../widgets/staple_choice_sheet.dart';
import '../../library/components/exercise_detail_sheet.dart';
import 'widgets/empty_state_with_suggestions.dart';
import 'widgets/exercise_picker_sheet.dart';

import '../../../l10n/generated/app_localizations.dart';
part 'staple_exercises_screen_part_staple_exercise_tile.dart';


/// Screen for managing staple exercises (core lifts that never rotate).
/// When [embedded] is true, renders without Scaffold/AppBar for use inside tabs.
class StapleExercisesScreen extends ConsumerWidget {
  final bool embedded;
  const StapleExercisesScreen({super.key, this.embedded = false});

  Future<void> _showAddExercisePicker(BuildContext context, WidgetRef ref) async {
    HapticFeedback.lightImpact();

    // Loop allows user to go back from choice sheet to re-pick exercise
    while (true) {
      final staplesState = ref.read(staplesProvider);
      final excludeNames = staplesState.staples
          .map((s) => s.exerciseName.toLowerCase())
          .toSet();

      final result = await showExercisePickerSheet(
        context,
        ref,
        type: ExercisePickerType.staple,
        excludeExercises: excludeNames,
      );

      if (result == null || !context.mounted) return;

      // Show choice sheet before saving
      final choice = await showStapleChoiceSheet(
        context,
        exerciseName: result.exerciseName,
      );
      if (choice == null) return; // Cancelled
      if (choice.goBack) continue; // Go back to picker

      final success = await ref.read(staplesProvider.notifier).addStaple(
        result.exerciseName,
        libraryId: result.exerciseId,
        muscleGroup: result.muscleGroup,
        reason: result.reason,
        addToCurrentWorkout: choice.addToday,
        section: choice.section,
        gymProfileId: choice.gymProfileId,
        swapExerciseId: choice.swapExerciseId,
        cardioParams: choice.cardioParams,
        userSets: choice.userSets,
        userReps: choice.userReps,
        userRestSeconds: choice.userRestSeconds,
        userWeightLbs: choice.userWeightLbs,
        targetDays: choice.targetDays,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? AppLocalizations.of(context)!.stapleExercisesScreenAddedAsAStaple(result.exerciseName)
                  : 'Failed to add exercise',
            ),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
      break; // Done — exit the picker loop
    }
  }

  /// Quick-add from a suggestion chip: skip the exercise picker and go
  /// straight to the staple choice sheet with the name pre-filled.
  Future<void> _quickAddSuggestion(
    BuildContext context,
    WidgetRef ref,
    SuggestedExercise suggestion,
  ) async {
    // Guard against dupes — suggestions can collide with already-added staples.
    final isAlreadyStaple = ref
        .read(staplesProvider)
        .staples
        .any((s) => s.exerciseName.toLowerCase() == suggestion.name.toLowerCase());
    if (isAlreadyStaple) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.stapleExercisesScreenIsAlreadyAStaple(suggestion.name)),
          backgroundColor: AppColors.cyan,
        ),
      );
      return;
    }

    final choice = await showStapleChoiceSheet(
      context,
      exerciseName: suggestion.name,
    );
    if (choice == null || choice.goBack) return;

    final success = await ref.read(staplesProvider.notifier).addStaple(
      suggestion.name,
      muscleGroup: suggestion.muscleGroup,
      addToCurrentWorkout: choice.addToday,
      section: choice.section,
      gymProfileId: choice.gymProfileId,
      swapExerciseId: choice.swapExerciseId,
      cardioParams: choice.cardioParams,
      userSets: choice.userSets,
      userReps: choice.userReps,
      userRestSeconds: choice.userRestSeconds,
      userWeightLbs: choice.userWeightLbs,
      targetDays: choice.targetDays,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? AppLocalizations.of(context)!.stapleExercisesScreenAddedAsAStaple2(suggestion.name)
                : 'Failed to add exercise',
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    final staplesState = ref.watch(staplesProvider);

    final body = Stack(
      children: [
        staplesState.isLoading
            // Cache-first: layout-matched skeleton on the cold first load only;
            // re-opens render instantly from the retained app-scoped provider.
            ? _buildSkeleton()
            : staplesState.staples.isEmpty
                ? _buildEmptyState(context, ref, textMuted)
                : _buildStaplesList(
                    context,
                    ref,
                    staplesState.staples,
                    isDark,
                    textPrimary,
                    textMuted,
                    elevated,
                  ),
      ],
    );

    if (embedded) return body;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PillAppBar(
        title: AppLocalizations.of(context).trainingPreferencesStapleExercises,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticService.light();
          _showAddExercisePicker(context, ref);
        },
        backgroundColor: AppColors.cyan,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: body,
    );
  }

  /// Layout-matched skeleton for the cold first load. Mirrors the info banner
  /// + staple list-tile rows so the swap to real content does not reflow.
  Widget _buildSkeleton() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SkeletonBox(height: 64, radius: 12),
        ),
        Expanded(
          child: SkeletonList(
            scrollable: true,
            itemCount: 5,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (_, __) => const SkeletonCard(leadingSize: 44),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, Color textMuted) {
    return EmptyStateWithSuggestions(
      heroIcon: Icons.push_pin_rounded,
      accentColor: AppColors.cyan,
      heroTitle: 'Lock in your core lifts',
      heroSubtitle:
          'Staples never rotate out. Pick the lifts you want to hit every week — your plan will build around them.',
      sectionLabel: 'QUICK ADD',
      primaryButtonLabel: 'Browse Full Library',
      primaryButtonIcon: Icons.menu_book_rounded,
      suggestions: kPopularStaples,
      onSuggestionTap: (s) => _quickAddSuggestion(context, ref, s),
      onBrowseLibrary: () => _showAddExercisePicker(context, ref),
    );
  }

  Widget _buildStaplesList(
    BuildContext context,
    WidgetRef ref,
    List<StapleExercise> staples,
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color elevated,
  ) {
    final profileCount = ref.read(gymProfilesProvider).valueOrNull?.length ?? 1;

    return Column(
      children: [
        // Info banner
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (isDark ? AppColors.purple : AppColorsLight.purple).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (isDark ? AppColors.purple : AppColorsLight.purple).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.push_pin,
                color: isDark ? AppColors.purple : AppColorsLight.purple,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).stapleExercisesTheseCoreLiftsWill,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white : AppColorsLight.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Staples list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: staples.length,
            itemBuilder: (context, index) {
              final staple = staples[index];
              return _StapleExerciseTile(
                staple: staple,
                isDark: isDark,
                textPrimary: textPrimary,
                textMuted: textMuted,
                elevated: elevated,
                showProfileBadge: profileCount >= 2,
                onEdit: () {
                  HapticFeedback.lightImpact();
                  _showEditStapleSheet(context, ref, staple);
                },
                onRemove: () async {
                  HapticFeedback.lightImpact();
                  final confirmed = await _showRemoveDialog(
                    context,
                    staple.exerciseName,
                    isDark,
                  );
                  if (confirmed == true) {
                    ref
                        .read(staplesProvider.notifier)
                        .removeStaple(staple.id);
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// Detect exercise type for showing appropriate fields in edit sheet
  static _ExerciseType _detectExerciseType(StapleExercise staple) {
    final name = staple.exerciseName.toLowerCase();
    final eq = staple.equipment?.toLowerCase() ?? '';
    final cat = staple.category?.toLowerCase() ?? '';

    // Cardio equipment
    if (eq.contains('treadmill') || name.contains('treadmill')) {
      return _ExerciseType.treadmill;
    }
    if (eq.contains('bike') || name.contains('bike')) {
      return _ExerciseType.bike;
    }
    if (eq.contains('rower') || name.contains('rower')) {
      return _ExerciseType.rower;
    }
    if (eq.contains('elliptical') || name.contains('elliptical')) {
      return _ExerciseType.elliptical;
    }
    if (cat == 'cardio') return _ExerciseType.cardioGeneric;

    // Timed / isometric exercises
    if (name.contains('plank') || name.contains('hold') || name.contains('hang') ||
        name.contains('wall sit') || name.contains('isometric') ||
        name.contains('static') || cat == 'isometric' || cat == 'stretching') {
      return _ExerciseType.timed;
    }

    return _ExerciseType.strength;
  }

  Future<void> _showEditStapleSheet(
    BuildContext context,
    WidgetRef ref,
    StapleExercise staple,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    final exerciseType = _detectExerciseType(staple);

    String selectedSection = staple.section;
    final setsController = TextEditingController(
      text: staple.userSets?.toString() ?? '',
    );
    final repsController = TextEditingController(
      text: staple.userReps ?? '',
    );
    final restController = TextEditingController(
      text: staple.userRestSeconds?.toString() ?? '',
    );
    // Weight field (backend field: user_weight_lbs)
    final weightController = TextEditingController(
      text: staple.userWeightLbs?.toStringAsFixed(
        staple.userWeightLbs! % 1 == 0 ? 0 : 1,
      ) ?? '',
    );
    // Duration field (for timed/cardio)
    final durationController = TextEditingController(
      text: staple.defaultDurationSeconds != null
          ? (staple.defaultDurationSeconds! / 60).toStringAsFixed(0)
          : '',
    );
    // Speed field (for treadmill)
    final speedController = TextEditingController(
      text: staple.defaultSpeedMph?.toStringAsFixed(1) ?? '',
    );
    // Incline field (for treadmill)
    final inclineController = TextEditingController(
      text: staple.defaultInclinePercent?.toStringAsFixed(0) ?? '',
    );
    // RPM field (for bike)
    final rpmController = TextEditingController(
      text: staple.defaultRpm?.toString() ?? '',
    );
    // Resistance field (for bike/elliptical)
    final resistanceController = TextEditingController(
      text: staple.defaultResistanceLevel?.toString() ?? '',
    );
    // Stroke rate field (for rower)
    final strokeRateController = TextEditingController(
      text: staple.strokeRateSpm?.toString() ?? '',
    );

    List<int> selectedDays = List<int>.from(staple.targetDays ?? []);

    // Determine initial day target mode from existing data
    // null/empty = workout days, all 7 = every day, otherwise = custom
    String dayTargetMode;
    if (selectedDays.isEmpty) {
      dayTargetMode = 'workoutDays';
    } else if (selectedDays.length == 7) {
      dayTargetMode = 'everyDay';
    } else {
      dayTargetMode = 'custom';
    }

    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final userWorkoutDays = ref.read(currentUserProvider).valueOrNull?.workoutDays ?? [];

    Widget buildField({
      required TextEditingController controller,
      required String label,
      String? suffix,
      String? hint,
      TextInputType keyboardType = TextInputType.number,
    }) {
      return TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: textMuted, fontSize: 13),
          suffixText: suffix,
          suffixStyle: TextStyle(color: textMuted, fontSize: 12),
          hintText: hint,
          hintStyle: TextStyle(
            color: textMuted.withValues(alpha: 0.5),
            fontSize: 12,
          ),
          filled: true,
          fillColor: elevatedColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
      );
    }

    final result = await showGlassSheet<bool>(
      context: context,
      builder: (sheetContext) => GlassSheet(
        child: StatefulBuilder(
          builder: (context, setSheetState) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.stapleExercisesScreenEdit(staple.exerciseName),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Section selector
                  Text(
                    AppLocalizations.of(context).stapleExercisesSection,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: ['main', 'warmup', 'stretches'].map((s) {
                      final isSelected = selectedSection == s;
                      final label = s == 'main'
                          ? 'Main'
                          : s == 'warmup'
                              ? 'Warmup'
                              : 'Stretch';
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsetsDirectional.only(end: s != 'stretches' ? 8 : 0,
                          ),
                          child: ChoiceChip(
                            label: Text(label),
                            selected: isSelected,
                            onSelected: (_) {
                              setSheetState(() => selectedSection = s);
                            },
                            selectedColor: AppColors.cyan,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : textMuted,
                              fontSize: 13,
                            ),
                            backgroundColor: elevatedColor,
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // --- Type-specific fields ---
                  if (exerciseType == _ExerciseType.strength) ...[
                    // Strength: Weight + Sets + Reps + Rest
                    Text(
                      AppLocalizations.of(context).stapleExercisesWeightSetsRepsRest,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: buildField(
                            controller: weightController,
                            label: AppLocalizations.of(context).workoutSummaryAdvancedWeight,
                            suffix: 'lbs',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: buildField(
                            controller: setsController,
                            label: AppLocalizations.of(context).workoutSummaryGeneralSets,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: buildField(
                            controller: repsController,
                            label: AppLocalizations.of(context).workoutSummaryGeneralReps,
                            hint: AppLocalizations.of(context).stapleExercisesEG812,
                            keyboardType: TextInputType.text,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: buildField(
                            controller: restController,
                            label: AppLocalizations.of(context).workoutSummaryAdvancedRest,
                            suffix: 'sec',
                          ),
                        ),
                      ],
                    ),
                  ] else if (exerciseType == _ExerciseType.timed) ...[
                    // Timed: Duration + Sets + Rest
                    Text(
                      AppLocalizations.of(context).stapleExercisesDurationSetsRest,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: buildField(
                            controller: durationController,
                            label: AppLocalizations.of(context).workoutSummaryGeneralDuration,
                            suffix: 'min',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: buildField(
                            controller: setsController,
                            label: AppLocalizations.of(context).workoutSummaryGeneralSets,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: buildField(
                            controller: restController,
                            label: AppLocalizations.of(context).workoutSummaryAdvancedRest,
                            suffix: 'sec',
                          ),
                        ),
                      ],
                    ),
                  ] else if (exerciseType == _ExerciseType.treadmill) ...[
                    // Treadmill: Duration + Speed + Incline
                    Text(
                      AppLocalizations.of(context).stapleExercisesTreadmillSettings,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: buildField(
                            controller: durationController,
                            label: AppLocalizations.of(context).workoutSummaryGeneralDuration,
                            suffix: 'min',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: buildField(
                            controller: speedController,
                            label: AppLocalizations.of(context).warmupPhaseSpeed,
                            suffix: 'mph',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: buildField(
                            controller: inclineController,
                            label: AppLocalizations.of(context).warmupPhaseIncline,
                          ),
                        ),
                      ],
                    ),
                  ] else if (exerciseType == _ExerciseType.bike) ...[
                    // Bike: Duration + RPM + Resistance
                    Text(
                      AppLocalizations.of(context).stapleExercisesBikeSettings,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: buildField(
                            controller: durationController,
                            label: AppLocalizations.of(context).workoutSummaryGeneralDuration,
                            suffix: 'min',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: buildField(
                            controller: rpmController,
                            label: 'RPM',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: buildField(
                            controller: resistanceController,
                            label: AppLocalizations.of(context).stapleExercisesResistance,
                          ),
                        ),
                      ],
                    ),
                  ] else if (exerciseType == _ExerciseType.rower) ...[
                    // Rower: Duration + Stroke Rate
                    Text(
                      AppLocalizations.of(context).stapleExercisesRowerSettings,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: buildField(
                            controller: durationController,
                            label: AppLocalizations.of(context).workoutSummaryGeneralDuration,
                            suffix: 'min',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: buildField(
                            controller: strokeRateController,
                            label: AppLocalizations.of(context).stapleExercisesStrokeRate,
                            suffix: 'spm',
                          ),
                        ),
                      ],
                    ),
                  ] else if (exerciseType == _ExerciseType.elliptical) ...[
                    // Elliptical: Duration + Resistance
                    Text(
                      AppLocalizations.of(context).stapleExercisesEllipticalSettings,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: buildField(
                            controller: durationController,
                            label: AppLocalizations.of(context).workoutSummaryGeneralDuration,
                            suffix: 'min',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: buildField(
                            controller: resistanceController,
                            label: AppLocalizations.of(context).stapleExercisesResistance,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Generic cardio: Duration only
                    Text(
                      AppLocalizations.of(context).stapleExercisesCardioSettings,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    buildField(
                      controller: durationController,
                      label: AppLocalizations.of(context).workoutSummaryGeneralDuration,
                      suffix: 'min',
                    ),
                  ],

                  const SizedBox(height: 20),
                  // Day picker
                  Text(
                    AppLocalizations.of(context).stapleExercisesTargetDays,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Builder(builder: (_) {
                    String subtitle;
                    switch (dayTargetMode) {
                      case 'workoutDays':
                        subtitle = userWorkoutDays.isNotEmpty
                            ? userWorkoutDays.map((d) => dayLabels[d]).join(', ')
                            : 'Your scheduled workout days';
                      case 'everyDay':
                        subtitle = 'Sun - Sat';
                      default:
                        subtitle = selectedDays.isNotEmpty
                            ? (selectedDays.toList()..sort()).map((d) => dayLabels[d]).join(', ')
                            : 'Select days below';
                    }
                    return Text(subtitle, style: TextStyle(fontSize: 12, color: textMuted));
                  }),
                  const SizedBox(height: 8),
                  // 3-option segmented control
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: elevatedColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        for (final entry in [
                          ('workoutDays', 'Workout Days'),
                          ('everyDay', 'Every Day'),
                          ('custom', 'Custom'),
                        ])
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                HapticService.light();
                                setSheetState(() => dayTargetMode = entry.$1);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: dayTargetMode == entry.$1
                                      ? AppColors.cyan.withValues(alpha: 0.15)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  border: dayTargetMode == entry.$1
                                      ? Border.all(color: AppColors.cyan.withValues(alpha: 0.3))
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  entry.$2,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: dayTargetMode == entry.$1 ? FontWeight.w600 : FontWeight.w400,
                                    color: dayTargetMode == entry.$1 ? textColor : textMuted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Custom day picker (only when Custom is selected)
                  if (dayTargetMode == 'custom') ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: List.generate(7, (i) {
                        final isSelected = selectedDays.contains(i);
                        final isWorkoutDay = userWorkoutDays.contains(i);
                        return FilterChip(
                          label: Text(dayLabels[i]),
                          selected: isSelected,
                          onSelected: (_) {
                            setSheetState(() {
                              if (isSelected) {
                                selectedDays.remove(i);
                              } else {
                                selectedDays.add(i);
                              }
                            });
                          },
                          selectedColor: AppColors.cyan,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : textMuted,
                            fontSize: 12,
                          ),
                          backgroundColor: elevatedColor,
                          side: BorderSide(
                            color: isWorkoutDay && !isSelected
                                ? AppColors.cyan.withValues(alpha: 0.4)
                                : Colors.transparent,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          visualDensity: VisualDensity.compact,
                        );
                      }),
                    ),
                    if (userWorkoutDays.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          AppLocalizations.of(context).stapleExercisesHighlightedYourWorkoutDay,
                          style: TextStyle(fontSize: 11, color: textMuted.withValues(alpha: 0.6)),
                        ),
                      ),
                  ],
                  const SizedBox(height: 24),
                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(sheetContext, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cyan,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context).vacationModeSaveChanges,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (result == true && context.mounted) {
      final sets = int.tryParse(setsController.text);
      final reps = repsController.text.trim().isEmpty ? null : repsController.text.trim();
      final rest = int.tryParse(restController.text);

      // Build cardio params map from type-specific fields
      Map<String, double>? cardioParams;
      if (exerciseType != _ExerciseType.strength) {
        final params = <String, double>{};
        final duration = double.tryParse(durationController.text);
        if (duration != null) params['duration_seconds'] = duration * 60;

        if (exerciseType == _ExerciseType.treadmill) {
          final speed = double.tryParse(speedController.text);
          if (speed != null) params['speed_mph'] = speed;
          final incline = double.tryParse(inclineController.text);
          if (incline != null) params['incline_percent'] = incline;
        } else if (exerciseType == _ExerciseType.bike) {
          final rpm = double.tryParse(rpmController.text);
          if (rpm != null) params['rpm'] = rpm;
          final resistance = double.tryParse(resistanceController.text);
          if (resistance != null) params['resistance_level'] = resistance;
        } else if (exerciseType == _ExerciseType.rower) {
          final strokeRate = double.tryParse(strokeRateController.text);
          if (strokeRate != null) params['stroke_rate_spm'] = strokeRate;
        } else if (exerciseType == _ExerciseType.elliptical) {
          final resistance = double.tryParse(resistanceController.text);
          if (resistance != null) params['resistance_level'] = resistance;
        }

        if (params.isNotEmpty) cardioParams = params;
      }

      // Parse weight for strength exercises
      final weight = exerciseType == _ExerciseType.strength
          ? double.tryParse(weightController.text)
          : null;

      final success = await ref.read(staplesProvider.notifier).updateStaple(
        staple.id,
        section: selectedSection,
        userSets: sets,
        userReps: reps,
        userRestSeconds: rest,
        userWeightLbs: weight,
        targetDays: dayTargetMode == 'everyDay'
            ? [0, 1, 2, 3, 4, 5, 6]
            : dayTargetMode == 'custom' && selectedDays.isNotEmpty
                ? selectedDays
                : null,
        cardioParams: cardioParams,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? AppLocalizations.of(context)!.stapleExercisesScreenUpdated(staple.exerciseName)
                  : 'Failed to update exercise',
            ),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    }

    setsController.dispose();
    repsController.dispose();
    restController.dispose();
    weightController.dispose();
    durationController.dispose();
    speedController.dispose();
    inclineController.dispose();
    rpmController.dispose();
    resistanceController.dispose();
    strokeRateController.dispose();
  }

  Future<bool?> _showRemoveDialog(
    BuildContext context,
    String exerciseName,
    bool isDark,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
        title: Text(AppLocalizations.of(context).stapleExercisesRemoveStaple),
        content: Text(
          AppLocalizations.of(context)!.stapleExercisesScreenRemoveFromYourStaples(exerciseName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              AppLocalizations.of(context).buttonCancel,
              style: TextStyle(
                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppLocalizations.of(context).workoutPlanDrawerRemove,
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

