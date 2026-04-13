import 'dart:async';
import 'package:flutter/material.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/glass_sheet.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import '../../core/animations/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/posthog_service.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/warmup_duration_provider.dart';
import '../../core/utils/difficulty_utils.dart';
import '../../data/models/workout.dart';
import '../../data/models/exercise.dart';
import '../../data/models/workout_generation_params.dart';
import '../../data/models/coach_persona.dart';
import '../ai_settings/ai_settings_screen.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/models/sauna_log.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/sauna_repository.dart';
import '../../data/services/haptic_service.dart';
import 'widgets/sauna_dialog.dart';
import '../home/widgets/components/training_program_selector.dart';
import 'widgets/workout_actions_sheet.dart';
import 'widgets/exercise_swap_sheet.dart';
import 'widgets/exercise_add_sheet.dart';
import 'widgets/expanded_exercise_card.dart';
import 'widgets/superset_indicator.dart';
import 'widgets/superset_reorder_sheet.dart';
import 'package:flutter/services.dart';
import '../../widgets/fasting_training_warning.dart';
import '../../widgets/coach_avatar.dart';
import '../../models/equipment_item.dart';
import '../../core/providers/environment_equipment_provider.dart';
import 'widgets/edit_workout_equipment_sheet.dart';
import '../../core/providers/avoided_provider.dart';
import '../../data/providers/today_workout_provider.dart';
import 'widgets/workout_detail_helpers.dart';
import 'widgets/workout_detail_ai_insights.dart';

part 'workout_detail_screen_ui.dart';

part 'workout_detail_screen_ui_1.dart';
part 'workout_detail_screen_ui_2.dart';
part 'workout_detail_screen_warmup.dart';


class WorkoutDetailScreen extends ConsumerStatefulWidget {
  final String workoutId;
  /// Optional pre-loaded workout to display immediately while refreshing.
  final Workout? initialWorkout;
  /// When true, hides the coach avatar + "Let's Go" FAB (used inside summary).
  final bool isSummaryMode;

  const WorkoutDetailScreen({super.key, required this.workoutId, this.initialWorkout, this.isSummaryMode = false});

  @override
  ConsumerState<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends ConsumerState<WorkoutDetailScreen>
    with WorkoutDetailAIInsightsMixin {
  Workout? _workout;
  bool _isLoading = true;
  String? _error;
  String? _workoutSummary;
  bool _isLoadingSummary = true;  // Start as true to show loading immediately
  bool _isWarmupExpanded = false;  // For warmup section
  bool _isStretchesExpanded = false;  // For stretches section
  bool _isChallengeExpanded = false;  // For challenge exercise section
  bool _isEquipmentExpanded = false;  // For equipment section
  String? _trainingSplit;  // Training program type from user preferences
  WorkoutGenerationParams? _generationParams;  // AI reasoning and parameters
  bool _isLoadingParams = false;  // Loading state for generation params
  bool _isAIReasoningExpanded = false;  // For AI reasoning section
  bool _isMoreInfoExpanded = false;  // For More Info section (AI insights)
  bool? _useKgOverride;  // Local override for kg/lbs toggle
  int? _pendingSupersetIndex;  // Index of exercise waiting to be paired via menu

  // Equipment edit revert state
  List<WorkoutExercise>? _originalExercises;  // Snapshot before equipment changes
  bool _hasEquipmentModifications = false;  // Track if equipment was modified

  // Warmup/stretch exercises loaded from API
  List<Map<String, dynamic>>? _warmupData;
  List<Map<String, dynamic>>? _stretchData;

  // Auto-save state for exercise modifications
  Timer? _autoSaveTimer;
  bool _isSaving = false;
  bool _isFavorite = false;

  // Sauna post-workout logging
  SaunaLog? _saunaLog;
  bool _isLoadingSauna = false;
  bool _secondaryLoadsStarted = false;

  @override
  void initState() {
    super.initState();
    // If we have an initial workout, show it immediately (no loading spinner)
    if (widget.initialWorkout != null) {
      _workout = widget.initialWorkout;
      _isFavorite = widget.initialWorkout!.isFavorite ?? false;
      _isLoading = false;
      // Fire secondary loads immediately since workout data is already available
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startSecondaryLoads();
      });
    }
    _loadWorkout();
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    // Use dynamic accent color from provider
    final accentColor = ref.colors(context).accent;
    // Use paddingOf to only rebuild on padding changes, not all MediaQuery changes
    final safePadding = MediaQuery.paddingOf(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: accentColor),
        ),
      );
    }

    if (_error != null || _workout == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load workout',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: textMuted,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _loadWorkout,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            ),
            // Floating pill back button — matches success-state styling
            Positioned(
              top: safePadding.top + 8,
              left: 16,
              child: GestureDetector(
                onTap: () {
                  HapticService.light();
                  if (context.canPop()) context.pop();
                },
                child: Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1C1C1E) : elevatedColor,
                    borderRadius: BorderRadius.circular(22),
                    border: isDark ? null : Border.all(color: cardBorder.withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: isDark ? Colors.white : AppColorsLight.textPrimary,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final workout = _workout!;
    final exercises = workout.exercises;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Spacer for top bar
              SliverToBoxAdapter(
                child: SizedBox(height: safePadding.top + 60),
              ),

              // Type badges row - single line horizontal scroll
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Workout Type Badge - now with semantic color
                        _buildLabeledBadge(
                          label: 'Type',
                          value: (workout.type ?? 'strength').capitalize(),
                          color: AppColors.getWorkoutTypeColor(workout.type ?? 'strength'),
                          backgroundColor: AppColors.getWorkoutTypeColor(workout.type ?? 'strength').withValues(alpha: 0.15),
                        ),
                        const SizedBox(width: 8),
                        // Difficulty Badge - special animated version for Hell
                        if ((workout.difficulty ?? 'medium').toLowerCase() == 'hell')
                          const AnimatedHellBadge()
                        else
                          _buildLabeledBadge(
                            label: 'Difficulty',
                            value: DifficultyUtils.getDisplayName(workout.difficulty ?? 'medium'),
                            color: DifficultyUtils.getColor(workout.difficulty ?? 'medium'),
                            backgroundColor: DifficultyUtils.getColor(workout.difficulty ?? 'medium').withValues(alpha: 0.15),
                          ),
                        // Training Program Badge (only show if we have a valid program name)
                        if (_trainingSplit != null && _getTrainingProgramName(_trainingSplit!) != null) ...[
                          const SizedBox(width: 8),
                          _buildLabeledBadge(
                            label: 'Program',
                            value: _getTrainingProgramName(_trainingSplit!)!,
                            color: accentColor,
                            backgroundColor: accentColor.withValues(alpha: 0.15),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // Fasting Training Warning (if applicable)
              SliverToBoxAdapter(
                child: FastingTrainingWarning(
                  workoutIntensity: workout.difficulty,
                  workoutType: workout.type,
                  durationMinutes: workout.durationMinutes,
                ),
              ),

              // Stats Row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  WorkoutDetailStatCard(
                    icon: Icons.timer_outlined,
                    value: '${workout.bestDurationMinutes}',
                    label: 'min',
                    color: accentColor,
                  ),
                  const SizedBox(width: 12),
                  WorkoutDetailStatCard(
                    icon: Icons.fitness_center,
                    value: '${exercises.length}',
                    label: 'exercises',
                    color: accentColor,
                  ),
                  const SizedBox(width: 12),
                  WorkoutDetailStatCard(
                    icon: Icons.local_fire_department,
                    value: '${workout.estimatedCalories}',
                    label: 'cal',
                    color: const Color(0xFFF97316),  // Orange fire color
                    useAnimatedFire: true,
                  ),
                ],
              ),
            ).animate()
              .fadeIn(duration: AppAnimations.fast, curve: AppAnimations.fastOut)
              .slideY(begin: 0.05, end: 0, duration: AppAnimations.quick, curve: AppAnimations.decelerate),
          ),

          // ─────────────────────────────────────────────────────────────────
          // EQUIPMENT SECTION (Collapsible)
          // ─────────────────────────────────────────────────────────────────
          if (workout.equipmentNeeded.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _buildCollapsibleSectionHeader(
                  title: 'EQUIPMENT',
                  icon: Icons.fitness_center,
                  color: Colors.blueGrey,
                  isExpanded: _isEquipmentExpanded,
                  onTap: () => setState(() => _isEquipmentExpanded = !_isEquipmentExpanded),
                  itemCount: workout.equipmentNeeded.length,
                  subtitle: workout.equipmentNeeded.take(3).join(', ') + (workout.equipmentNeeded.length > 3 ? '...' : ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Revert button (only shown when modifications exist)
                      if (_hasEquipmentModifications)
                        GestureDetector(
                          onTap: _revertToOriginalExercises,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Text(
                              'Revert',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ),
                      // Edit button
                      GestureDetector(
                        onTap: () => _showEditEquipmentSheet(workout),
                        child: Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Equipment items (shown when expanded)
            if (_isEquipmentExpanded)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: workout.equipmentNeeded.map((equipment) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: elevatedColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 14,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              equipment,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ).animate()
                .fadeIn(duration: AppAnimations.fast, curve: AppAnimations.fastOut)
                .slideY(begin: 0.05, end: 0, duration: AppAnimations.quick, curve: AppAnimations.decelerate),
              ),
          ],

          // ─────────────────────────────────────────────────────────────────
          // POST-WORKOUT SECTION (Sauna - only for completed workouts)
          // ─────────────────────────────────────────────────────────────────
          if (workout.isCompleted == true && !_isLoadingSauna)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _saunaLog != null
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE65100).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE65100).withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.hot_tub_rounded, size: 20, color: Color(0xFFE65100)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_saunaLog!.durationMinutes} min sauna',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                                    ),
                                  ),
                                  if (_saunaLog!.estimatedCalories != null)
                                    Text(
                                      '~${_saunaLog!.estimatedCalories} cal burned',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: _deleteSaunaLog,
                              child: Icon(
                                Icons.close,
                                size: 18,
                                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                              ),
                            ),
                          ],
                        ),
                      )
                    : TextButton.icon(
                        onPressed: _addSaunaToWorkout,
                        icon: const Icon(Icons.hot_tub_rounded, size: 18),
                        label: const Text('Add Sauna Time'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFE65100),
                        ),
                      ),
              ),
            ),

          // ─────────────────────────────────────────────────────────────────
          // WARMUP SECTION (Collapsible)
          // ─────────────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _buildCollapsibleSectionHeader(
                title: 'WARM UP',
                icon: Icons.whatshot,
                color: AppColors.orange,
                isExpanded: _isWarmupExpanded,
                onTap: () {
                  setState(() => _isWarmupExpanded = !_isWarmupExpanded);
                  // Lazy-load warmup/stretch data on first expand
                  if (_isWarmupExpanded && _warmupData == null) {
                    _loadWarmupAndStretches();
                  }
                },
                itemCount: _getWarmupExercises().length,
                toggleValue: ref.watch(warmupDurationProvider).warmupEnabled,
                onToggleChanged: (value) {
                  ref.read(warmupDurationProvider.notifier).setWarmupEnabled(value);
                },
              ),
            ),
          ),

          // Warmup items (shown when expanded)
          if (_isWarmupExpanded)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildWarmupStretchItem(
                  _getWarmupExercises()[index],
                  AppColors.orange,
                ),
                childCount: _getWarmupExercises().length,
              ),
            ),

          // ─────────────────────────────────────────────────────────────────
          // EXERCISES SECTION (with + icon)
          // ─────────────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.fitness_center, color: accentColor, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'EXERCISES',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textMuted,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${exercises.length}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // kg/lb toggle button
                  GestureDetector(
                    onTap: () {
                      HapticService.light();
                      _toggleUnit();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.swap_horiz,
                            color: accentColor,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            (_useKgOverride ?? ref.watch(useKgForWorkoutProvider)) ? 'kg' : 'lbs',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Add exercise button (+ icon)
                  GestureDetector(
                    onTap: () async {
                      await _flushPendingAutoSave();
                      if (!context.mounted) return;
                      final currentExerciseNames = exercises.map((e) => e.name).toList();
                      final updatedWorkout = await showExerciseAddSheet(
                        context,
                        ref,
                        workoutId: widget.workoutId,
                        workoutType: _workout?.type ?? 'strength',
                        currentExerciseNames: currentExerciseNames,
                      );
                      if (updatedWorkout != null && context.mounted) {
                        setState(() => _workout = updatedWorkout);
                        ref.invalidate(todayWorkoutProvider);
                        ref.invalidate(workoutsProvider);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Icon(
                        Icons.add,
                        color: accentColor,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Exercise List with superset grouping, drag-to-superset, and reordering
          SliverReorderableList(
            itemCount: groupExercisesForDisplay(exercises).length,
            onReorder: _reorderExercises,
            proxyDecorator: (child, index, animation) {
              return AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  final elevation = Tween<double>(begin: 0, end: 8).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeOut),
                  ).value;
                  return Material(
                    elevation: elevation,
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.transparent,
                    shadowColor: accentColor.withValues(alpha: 0.3),
                    child: child,
                  );
                },
                child: child,
              );
            },
            itemBuilder: (context, index) {
              final displayItems = groupExercisesForDisplay(exercises);
              if (index >= displayItems.length) return const SizedBox.shrink();
              final item = displayItems[index];

              // ─── SUPERSET GROUPED CARD (supports 2+ exercises) ───
              if (item.isSuperset) {
                // Build list of exercise widgets for the superset
                // Pass onSupersetDrop AND reorderIndex to enable DragTarget for adding more exercises
                final supersetExercises = item.supersetIndices!
                    .map((idx) => _buildExerciseCard(
                          exercises[idx],
                          idx,
                          accentColor,
                          reorderIndex: idx,  // Required for DragTarget to be created
                          onSupersetDrop: (draggedIndex) => _createSuperset(draggedIndex, idx),
                          supersetPairingIndex: _pendingSupersetIndex,
                        ))
                    .toList();

                return AnimationConfiguration.staggeredList(
                  key: ValueKey('superset-${item.groupNumber}'),
                  position: index,
                  duration: AppAnimations.listItem,
                  child: SlideAnimation(
                    verticalOffset: 20,
                    curve: AppAnimations.fastOut,
                    child: FadeInAnimation(
                      curve: AppAnimations.fastOut,
                      child: SupersetGroupCard(
                        groupNumber: item.groupNumber!,
                        isActive: false,
                        reorderIndex: index,
                        exercises: supersetExercises,
                        onBreakSuperset: () => _breakSuperset(item.groupNumber!),
                        onSwapOrder: item.exerciseCount == 2
                            ? () => _swapSupersetOrder(item.groupNumber!)
                            : null,
                        onReorderExercises: item.exerciseCount >= 3
                            ? () => _showReorderSheet(item.groupNumber!, item.supersetIndices!)
                            : null,
                      ),
                    ),
                  ),
                );
              }

              // ─── SINGLE EXERCISE ───
              // Drag strip handles both reordering (short drag) and superset creation (long-press drag)
              final exerciseIndex = item.singleIndex!;
              final exercise = exercises[exerciseIndex];
              final isPendingPair = _pendingSupersetIndex == exerciseIndex;

              return AnimationConfiguration.staggeredList(
                key: ValueKey('exercise-$exerciseIndex-${exercise.id ?? exercise.name}'),
                position: index,
                duration: AppAnimations.listItem,
                child: SlideAnimation(
                  verticalOffset: 20,
                  curve: AppAnimations.fastOut,
                  child: FadeInAnimation(
                    curve: AppAnimations.fastOut,
                    child: _buildExerciseCard(
                        exercise,
                        exerciseIndex,
                        accentColor,
                        reorderIndex: index,
                        isPendingPair: isPendingPair,
                        onSupersetDrop: (draggedIndex) => _createSuperset(draggedIndex, exerciseIndex),
                        supersetPairingIndex: _pendingSupersetIndex,
                      ),
                  ),
                ),
              );
            },
          ),

          // ─────────────────────────────────────────────────────────────────
          // CHALLENGE SECTION (Collapsible) - For beginners and intermediate
          // ─────────────────────────────────────────────────────────────────
          if (workout.hasChallenge)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _buildCollapsibleSectionHeader(
                  title: 'WANT A CHALLENGE?',
                  icon: Icons.local_fire_department,
                  color: Colors.orange,
                  isExpanded: _isChallengeExpanded,
                  onTap: () => setState(() => _isChallengeExpanded = !_isChallengeExpanded),
                  itemCount: 1,
                  subtitle: workout.challengeExercise?.progressionFrom != null
                      ? 'Progression from ${workout.challengeExercise!.progressionFrom}'
                      : 'Try this advanced exercise',
                ),
              ),
            ),

          // Challenge exercise item (shown when expanded)
          if (workout.hasChallenge && _isChallengeExpanded)
            SliverToBoxAdapter(
              child: _buildChallengeExerciseCard(workout.challengeExercise!),
            ),

          // ─────────────────────────────────────────────────────────────────
          // STRETCHES SECTION (Collapsible)
          // ─────────────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _buildCollapsibleSectionHeader(
                title: 'COOL DOWN STRETCHES',
                icon: Icons.self_improvement,
                color: AppColors.purple,
                isExpanded: _isStretchesExpanded,
                onTap: () {
                  setState(() => _isStretchesExpanded = !_isStretchesExpanded);
                  // Lazy-load warmup/stretch data on first expand
                  if (_isStretchesExpanded && _stretchData == null) {
                    _loadWarmupAndStretches();
                  }
                },
                itemCount: _getStretchExercises().length,
                toggleValue: ref.watch(warmupDurationProvider).stretchEnabled,
                onToggleChanged: (value) {
                  ref.read(warmupDurationProvider.notifier).setStretchEnabled(value);
                },
              ),
            ),
          ),

          // Stretches items (shown when expanded)
          if (_isStretchesExpanded)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildWarmupStretchItem(
                  _getStretchExercises()[index],
                  AppColors.green,
                ),
                childCount: _getStretchExercises().length,
              ),
            ),

          // ─────────────────────────────────────────────────────────────────
          // MORE INFO SECTION (Collapsible) - AI Insights moved here
          // ─────────────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _buildCollapsibleSectionHeader(
                title: 'MORE INFO',
                icon: Icons.lightbulb_outline,
                color: accentColor,
                isExpanded: _isMoreInfoExpanded,
                onTap: () => setState(() => _isMoreInfoExpanded = !_isMoreInfoExpanded),
                itemCount: 3,  // Summary, Muscles, AI Reasoning
                subtitle: 'AI insights & exercise details',
              ),
            ),
          ),

          // More Info content (shown when expanded)
          if (_isMoreInfoExpanded) ...[
            // Workout Summary Section (AI-generated)
            if (_workoutSummary != null || _isLoadingSummary)
              SliverToBoxAdapter(
                child: buildWorkoutSummarySection(
                  workoutSummary: _workoutSummary,
                  isLoadingSummary: _isLoadingSummary,
                  onTapInsights: () => _workoutSummary != null
                      ? showAIInsightsPopup(
                          summaryJson: _workoutSummary!,
                          workoutId: widget.workoutId,
                          onSummaryUpdated: (newSummary) => setState(() => _workoutSummary = newSummary),
                        )
                      : null,
                ),
              ),

            // Targeted Muscles Section
            SliverToBoxAdapter(
              child: buildTargetedMusclesSection(workout.primaryMuscles),
            ),

            // AI Reasoning Section (expandable)
            if (_generationParams != null || _isLoadingParams)
              SliverToBoxAdapter(
                child: buildAIReasoningSection(
                  generationParams: _generationParams,
                  isLoadingParams: _isLoadingParams,
                  isExpanded: _isAIReasoningExpanded,
                  onToggle: () => setState(() => _isAIReasoningExpanded = !_isAIReasoningExpanded),
                  onViewParameters: () {
                    if (_generationParams != null) showViewParametersModal(_generationParams!);
                  },
                ),
              ),
          ],

          // Bottom padding for FAB and floating nav bar
          const SliverToBoxAdapter(
            child: SizedBox(height: 140),
          ),
        ],
      ),
      // Floating top bar - positioned below status bar
      Positioned(
        top: safePadding.top + 8,
        left: 16,
        right: 16,
        child: Row(
          children: [
            // Back button - floating pill
            GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E) : AppColorsLight.elevated,
                  borderRadius: BorderRadius.circular(22),
                  border: isDark ? null : Border.all(color: cardBorder.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: isDark ? Colors.white : AppColorsLight.textPrimary,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Workout name in center
            Expanded(
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E) : AppColorsLight.elevated,
                  borderRadius: BorderRadius.circular(22),
                  border: isDark ? null : Border.all(color: cardBorder.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          workout.name ?? 'Workout',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColorsLight.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_isSaving) ...[
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: isDark ? Colors.white54 : AppColorsLight.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Favorite button - floating pill
            GestureDetector(
              onTap: _toggleFavorite,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E) : AppColorsLight.elevated,
                  borderRadius: BorderRadius.circular(22),
                  border: isDark ? null : Border.all(color: cardBorder.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    key: ValueKey(_isFavorite),
                    color: _isFavorite ? Colors.redAccent : (isDark ? Colors.white : AppColorsLight.textPrimary),
                    size: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Menu button - floating pill
            GestureDetector(
              onTap: () => _showWorkoutActions(context, ref, workout),
              child: Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E) : AppColorsLight.elevated,
                  borderRadius: BorderRadius.circular(22),
                  border: isDark ? null : Border.all(color: cardBorder.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.more_vert_rounded,
                  color: isDark ? Colors.white : AppColorsLight.textPrimary,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
      ],
      ),

      // Custom floating buttons: AI + Play (hidden in summary mode)
      floatingActionButton: widget.isSummaryMode ? null : _buildFloatingButtons(context, ref, workout),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // Warmup and stretch methods extracted to workout_detail_screen_warmup.dart
}

// Helper widgets and classes are extracted to:
// - widgets/workout_detail_helpers.dart (StatCard, AnimatedFireIcon, AnimatedHellBadge, ExerciseDisplayItem, equipment helpers)
// - widgets/workout_detail_ai_insights.dart (AI insights mixin)
