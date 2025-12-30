import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import '../../core/animations/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_provider.dart';
import '../../data/models/workout.dart';
import '../../data/models/exercise.dart';
import '../../data/models/workout_generation_params.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../home/widgets/components/training_program_selector.dart';
import 'widgets/workout_actions_sheet.dart';
import 'widgets/exercise_swap_sheet.dart';
import 'widgets/exercise_add_sheet.dart';
import 'widgets/expanded_exercise_card.dart';
import 'package:flutter/services.dart';
import '../../widgets/floating_chat/floating_chat_provider.dart';
import '../../widgets/fasting_training_warning.dart';

class WorkoutDetailScreen extends ConsumerStatefulWidget {
  final String workoutId;

  const WorkoutDetailScreen({super.key, required this.workoutId});

  @override
  ConsumerState<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends ConsumerState<WorkoutDetailScreen> {
  Workout? _workout;
  bool _isLoading = true;
  String? _error;
  String? _workoutSummary;
  bool _isLoadingSummary = true;  // Start as true to show loading immediately
  bool _isWarmupExpanded = false;  // For warmup section
  bool _isStretchesExpanded = false;  // For stretches section
  String? _trainingSplit;  // Training program type from user preferences
  WorkoutGenerationParams? _generationParams;  // AI reasoning and parameters
  bool _isLoadingParams = false;  // Loading state for generation params
  bool _isAIReasoningExpanded = false;  // For AI reasoning section

  @override
  void initState() {
    super.initState();
    _loadWorkout();
  }

  Future<void> _loadWorkout() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final workoutRepo = ref.read(workoutRepositoryProvider);
      final workout = await workoutRepo.getWorkout(widget.workoutId);
      setState(() {
        _workout = workout;
        _isLoading = false;
      });
      // Load workout summary, training split, and generation params after workout loads
      _loadWorkoutSummary();
      _loadTrainingSplit();
      _loadGenerationParams();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTrainingSplit() async {
    try {
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id;
      if (userId == null) return;

      final workoutRepo = ref.read(workoutRepositoryProvider);
      final prefs = await workoutRepo.getProgramPreferences(userId);
      if (mounted && prefs?.trainingSplit != null) {
        // Resolve 'dont_know' to actual split based on workout days
        final resolvedSplit = _resolveTrainingSplit(
          prefs!.trainingSplit!,
          prefs.workoutDays?.length ?? 3,
        );
        setState(() {
          _trainingSplit = resolvedSplit;
        });
      }
    } catch (e) {
      debugPrint('❌ [WorkoutDetail] Failed to load training split: $e');
    }
  }

  /// Resolve 'dont_know' to actual training split based on workout days count
  String _resolveTrainingSplit(String split, int numDays) {
    if (split.toLowerCase() != 'dont_know') {
      return split;  // Already a specific split
    }

    // Auto-pick based on days per week (matches backend logic)
    if (numDays <= 3) {
      return 'full_body';
    } else if (numDays == 4) {
      return 'upper_lower';
    } else if (numDays <= 6) {
      return 'push_pull_legs';
    } else {
      return 'full_body';
    }
  }

  Future<void> _loadWorkoutSummary() async {
    if (_workout == null) {
      debugPrint('🔍 [WorkoutDetail] Cannot load summary - workout is null');
      return;
    }

    debugPrint('🔍 [WorkoutDetail] Starting to load workout summary for: ${widget.workoutId}');
    setState(() => _isLoadingSummary = true);

    try {
      final workoutRepo = ref.read(workoutRepositoryProvider);
      final summary = await workoutRepo.getWorkoutSummary(widget.workoutId);
      debugPrint('🔍 [WorkoutDetail] Got summary response: ${summary != null ? "yes (${summary.length} chars)" : "null"}');
      if (mounted) {
        setState(() {
          _workoutSummary = summary;
          _isLoadingSummary = false;
        });
        debugPrint('✅ [WorkoutDetail] Summary state updated - summary: ${_workoutSummary != null}, loading: $_isLoadingSummary');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [WorkoutDetail] Failed to load workout summary: $e');
      debugPrint('❌ [WorkoutDetail] Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isLoadingSummary = false);
      }
    }
  }

  /// Load generation parameters and AI reasoning for the workout
  Future<void> _loadGenerationParams() async {
    if (_workout == null) {
      debugPrint('🔍 [WorkoutDetail] Cannot load generation params - workout is null');
      return;
    }

    debugPrint('🔍 [WorkoutDetail] Loading generation params for: ${widget.workoutId}');
    setState(() => _isLoadingParams = true);

    try {
      final workoutRepo = ref.read(workoutRepositoryProvider);
      final params = await workoutRepo.getWorkoutGenerationParams(widget.workoutId);
      if (mounted) {
        setState(() {
          _generationParams = params;
          _isLoadingParams = false;
        });
        debugPrint('✅ [WorkoutDetail] Generation params loaded - ${params?.exerciseReasoning.length ?? 0} exercise reasons');
      }
    } catch (e) {
      debugPrint('❌ [WorkoutDetail] Failed to load generation params: $e');
      if (mounted) {
        setState(() => _isLoadingParams = false);
      }
    }
  }

  /// Convert training split ID to display name
  /// Returns the program name if found, or throws for unrecognized splits
  String _getTrainingProgramName(String splitId) {
    // Split should already be resolved (dont_know -> actual split) by _resolveTrainingSplit
    // Look up the program - must exist in our known list
    final program = defaultTrainingPrograms.where((p) => p.id == splitId).firstOrNull;
    if (program == null) {
      // Unknown split ID - this is a data integrity issue that should be fixed
      throw StateError('Unknown training split: $splitId - this should not happen');
    }
    return program.name;
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🔍 [WorkoutDetail] build() - _isLoading: $_isLoading, _isLoadingSummary: $_isLoadingSummary, _workoutSummary: ${_workoutSummary != null}');

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.cyan),
        ),
      );
    }

    if (_error != null || _workout == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text(
                'Failed to load workout',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _loadWorkout,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    final workout = _workout!;
    final typeColor = AppColors.getWorkoutTypeColor(workout.type ?? 'strength');
    final exercises = workout.exercises;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Spacer for top bar
              SliverToBoxAdapter(
                child: SizedBox(height: MediaQuery.of(context).padding.top + 60),
              ),

              // Type badges row - with explicit labels for clarity
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Workout Type Badge
                      _buildLabeledBadge(
                        label: 'Type',
                        value: (workout.type ?? 'strength').capitalize(),
                        color: typeColor,
                        backgroundColor: typeColor.withOpacity(0.2),
                      ),
                      // Difficulty Badge
                      _buildLabeledBadge(
                        label: 'Difficulty',
                        value: (workout.difficulty ?? 'Medium').capitalize(),
                        color: AppColors.getDifficultyColor(workout.difficulty ?? 'medium'),
                        backgroundColor: glassSurface,
                      ),
                      // Training Program Badge
                      if (_trainingSplit != null)
                        _buildLabeledBadge(
                          label: 'Program',
                          value: _getTrainingProgramName(_trainingSplit!),
                          color: AppColors.purple,
                          backgroundColor: AppColors.purple.withOpacity(0.15),
                        ),
                    ],
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

              // Workout Summary Section (AI-generated)
              if (_workoutSummary != null || _isLoadingSummary)
                SliverToBoxAdapter(
                  child: _buildWorkoutSummarySection(),
                ),

              // Targeted Muscles Section
              SliverToBoxAdapter(
                child: _buildTargetedMusclesSection(workout.primaryMuscles),
              ),

              // AI Reasoning Section (expandable)
              if (_generationParams != null || _isLoadingParams)
                SliverToBoxAdapter(
                  child: _buildAIReasoningSection(),
                ),

              // Stats Row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _StatCard(
                    icon: Icons.timer_outlined,
                    value: '${workout.durationMinutes ?? 45}',
                    label: 'min',
                    color: AppColors.cyan,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    icon: Icons.fitness_center,
                    value: '${exercises.length}',
                    label: 'exercises',
                    color: AppColors.purple,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    icon: Icons.local_fire_department,
                    value: '${workout.estimatedCalories}',
                    label: 'cal',
                    color: AppColors.orange,
                  ),
                ],
              ),
            ).animate()
              .fadeIn(duration: AppAnimations.fast, curve: AppAnimations.fastOut)
              .slideY(begin: 0.05, end: 0, duration: AppAnimations.quick, curve: AppAnimations.decelerate),
          ),

          // Equipment Section
          if (workout.equipmentNeeded.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EQUIPMENT NEEDED',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textMuted,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
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
                  ],
                ),
              ).animate()
              .fadeIn(duration: AppAnimations.fast, curve: AppAnimations.fastOut)
              .slideY(begin: 0.05, end: 0, duration: AppAnimations.quick, curve: AppAnimations.decelerate),
            ),
          ],

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
                onTap: () => setState(() => _isWarmupExpanded = !_isWarmupExpanded),
                itemCount: _getWarmupExercises().length,
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
                      color: AppColors.cyan.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.fitness_center, color: AppColors.cyan, size: 16),
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
                      color: AppColors.cyan.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${exercises.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.cyan,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Add exercise button (+ icon)
                  GestureDetector(
                    onTap: () async {
                      final currentExerciseNames = exercises.map((e) => e.name).toList();
                      final updatedWorkout = await showExerciseAddSheet(
                        context,
                        ref,
                        workoutId: widget.workoutId,
                        workoutType: _workout?.type ?? 'strength',
                        currentExerciseNames: currentExerciseNames,
                      );
                      if (updatedWorkout != null) {
                        setState(() => _workout = updatedWorkout);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.cyan.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.cyan.withOpacity(0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: AppColors.cyan,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Exercise List with inline set tables
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final exercise = exercises[index];
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: AppAnimations.listItem,
                  child: SlideAnimation(
                    verticalOffset: 20,
                    curve: AppAnimations.fastOut,
                    child: FadeInAnimation(
                      curve: AppAnimations.fastOut,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          print('🎯 [WorkoutDetail] Exercise tapped at index $index: ${exercise.name}');
                          context.push('/exercise-detail', extra: exercise);
                        },
                        child: ExpandedExerciseCard(
                          key: ValueKey(exercise.id ?? index),
                          exercise: exercise,
                          index: index,
                          workoutId: widget.workoutId,
                          initiallyExpanded: false,
                          onTap: () {
                            print('🎯 [Card] onTap called for: ${exercise.name}');
                            context.push('/exercise-detail', extra: exercise);
                          },
                          onSwap: () async {
                            final updatedWorkout = await showExerciseSwapSheet(
                              context,
                              ref,
                              workoutId: widget.workoutId,
                              exercise: exercise,
                            );
                            if (updatedWorkout != null) {
                              setState(() => _workout = updatedWorkout);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
              childCount: exercises.length,
            ),
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
                color: AppColors.green,
                isExpanded: _isStretchesExpanded,
                onTap: () => setState(() => _isStretchesExpanded = !_isStretchesExpanded),
                itemCount: _getStretchExercises().length,
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

          // Bottom padding for FAB and floating nav bar
          const SliverToBoxAdapter(
            child: SizedBox(height: 140),
          ),
        ],
      ),
      // Floating top bar - positioned below status bar
      Positioned(
        top: MediaQuery.of(context).padding.top + 8,
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
                  border: isDark ? null : Border.all(color: cardBorder.withOpacity(0.3)),
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
                  border: isDark ? null : Border.all(color: cardBorder.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
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
                  border: isDark ? null : Border.all(color: cardBorder.withOpacity(0.3)),
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

      // Custom floating buttons: AI + Play
      floatingActionButton: _buildFloatingButtons(context, ref, workout),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildFloatingButtons(BuildContext context, WidgetRef ref, Workout workout) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // AI Coach Button
        GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            // Navigate to full chat screen for proper keyboard handling
            context.push('/chat');
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.purple, AppColors.cyan],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cyan.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Let's Go Button - custom styled to ensure full text visibility
        GestureDetector(
          onTap: () => context.push('/active-workout', extra: workout),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 28),
            decoration: BoxDecoration(
              color: AppColors.cyan,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cyan.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.bolt_rounded,
                  size: 24,
                  color: AppColors.pureBlack,
                ),
                const SizedBox(width: 8),
                const Text(
                  "Let's Go",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: 0.5,
                    color: AppColors.pureBlack,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showWorkoutActions(
    BuildContext context,
    WidgetRef ref,
    Workout workout,
  ) async {
    await showWorkoutActionsSheet(
      context,
      ref,
      workout,
      onRefresh: () {
        _loadWorkout();
      },
    );
  }

  /// Strip markdown formatting from text
  String _stripMarkdown(String text) {
    return text
        .replaceAll(RegExp(r'\*\*'), '')  // Bold
        .replaceAll(RegExp(r'\*'), '')    // Italic
        .replaceAll(RegExp(r'#{1,6}\s*'), '') // Headers
        .replaceAll(RegExp(r'^-\s*', multiLine: true), '') // List items
        .replaceAll(RegExp(r'^•\s*', multiLine: true), '') // Bullet points
        .replaceAll(RegExp(r'`'), '')     // Code
        .replaceAll(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), r'\1') // Links
        .trim();
  }

  /// Get color from string name
  Color _getColorFromName(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'cyan':
        return AppColors.cyan;
      case 'purple':
        return AppColors.purple;
      case 'orange':
        return AppColors.orange;
      case 'green':
        return AppColors.green;
      default:
        return AppColors.cyan;
    }
  }

  /// Parse structured JSON insights
  Map<String, dynamic>? _parseInsightsJson(String? summary) {
    if (summary == null) return null;
    try {
      return json.decode(summary) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('⚠️ [WorkoutDetail] Failed to parse insights JSON: $e');
      return null;
    }
  }

  /// Build a labeled badge with "Label: Value" format for clarity
  Widget _buildLabeledBadge({
    required String label,
    required String value,
    required Color color,
    required Color backgroundColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: labelColor,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutSummarySection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    // Try to parse JSON insights
    final insights = _parseInsightsJson(_workoutSummary);
    String? shortPreview;

    if (insights != null) {
      // Use headline from structured JSON
      shortPreview = insights['headline'] as String?;
    } else if (_workoutSummary != null) {
      // Fallback: strip markdown and take first few words
      final cleanSummary = _stripMarkdown(_workoutSummary!);
      final words = cleanSummary.split(' ');
      if (words.length <= 6) {
        shortPreview = cleanSummary;
      } else {
        shortPreview = '${words.take(6).join(' ')}...';
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: GestureDetector(
        onTap: _workoutSummary != null ? () => _showAIInsightsPopup(_workoutSummary!) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.purple.withOpacity(0.15),
                AppColors.cyan.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.purple.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.purple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppColors.purple,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI INSIGHTS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: textMuted,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (_isLoadingSummary)
                      Text(
                        'Generating insights...',
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else if (shortPreview != null)
                      Text(
                        shortPreview,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (!_isLoadingSummary && _workoutSummary != null)
                Icon(
                  Icons.open_in_new,
                  color: AppColors.purple.withOpacity(0.7),
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    ).animate()
      .fadeIn(duration: AppAnimations.fast, curve: AppAnimations.fastOut)
      .slideY(begin: 0.05, end: 0, duration: AppAnimations.quick, curve: AppAnimations.decelerate);
  }

  /// Show AI insights in a draggable popup modal with formatted sections
  void _showAIInsightsPopup(String summaryJson) {
    // Use actual brightness to support ThemeMode.system
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    // Parse JSON insights - use mutable state that persists across rebuilds
    var currentSummary = summaryJson;
    var insights = _parseInsightsJson(currentSummary);
    var headline = insights?['headline'] as String? ?? 'Workout Insights';
    var sections = (insights?['sections'] as List<dynamic>?) ?? [];
    var isRegenerating = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalContext) => StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> regenerateInsights() async {
            setModalState(() => isRegenerating = true);
            try {
              final workoutRepo = ref.read(workoutRepositoryProvider);
              final newSummary = await workoutRepo.regenerateWorkoutSummary(widget.workoutId);
              if (newSummary != null) {
                currentSummary = newSummary;
                insights = _parseInsightsJson(newSummary);
                headline = insights?['headline'] as String? ?? 'Workout Insights';
                sections = (insights?['sections'] as List<dynamic>?) ?? [];
                // Also update the parent state
                setState(() {
                  _workoutSummary = newSummary;
                });
              }
            } catch (e) {
              debugPrint('❌ Error regenerating insights: $e');
            }
            setModalState(() => isRegenerating = false);
          }

          return DraggableScrollableSheet(
            initialChildSize: 0.45,
            minChildSize: 0.25,
            maxChildSize: 0.75,
            builder: (context, scrollController) => Container(
              decoration: BoxDecoration(
                color: elevatedColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Draggable handle bar
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: textMuted.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  // Header with headline
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 12, 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.purple.withOpacity(0.3),
                                AppColors.cyan.withOpacity(0.2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: AppColors.purple,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            headline,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        // Regenerate button
                        IconButton(
                          onPressed: isRegenerating ? null : regenerateInsights,
                          tooltip: 'Regenerate insights',
                          icon: isRegenerating
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.cyan,
                                  ),
                                )
                              : Icon(Icons.refresh, color: AppColors.cyan),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, color: textMuted),
                        ),
                      ],
                    ),
                  ),
                  // Divider
                  Divider(
                    color: cardBorder.withOpacity(0.3),
                    height: 1,
                  ),
                  // Content - structured sections
                  Expanded(
                    child: isRegenerating
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(color: AppColors.cyan),
                                const SizedBox(height: 16),
                                Text(
                                  'Generating new insights...',
                                  style: TextStyle(color: textMuted),
                                ),
                              ],
                            ),
                          )
                        : ListView(
                            controller: scrollController,
                            padding: const EdgeInsets.all(20),
                            children: [
                              if (sections.isNotEmpty)
                                ...sections.map((section) {
                                  final icon = section['icon'] as String? ?? '💡';
                                  final title = section['title'] as String? ?? 'Tip';
                                  final content = section['content'] as String? ?? '';
                                  final colorName = section['color'] as String? ?? 'cyan';
                                  final color = _getColorFromName(colorName);

                                  return _buildInsightSection(icon, title, content, color, textPrimary);
                                })
                              else
                                // Fallback for non-JSON or parse error
                                Text(
                                  _stripMarkdown(currentSummary),
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: textPrimary,
                                    height: 1.6,
                                  ),
                                ),
                              // Extra padding at bottom
                              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Build a single insight section with icon, colored title, and content
  Widget _buildInsightSection(String icon, String title, String content, Color color, Color textPrimary) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Text(
            icon,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          // Title + Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 14,
                    color: textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Extract just the main muscle name (remove parenthetical details)
  String _shortenMuscleName(String muscle) {
    // Extract just the main name before parentheses
    // e.g., "Quadriceps (Quadriceps Femoris)" -> "Quadriceps"
    final match = RegExp(r'^([^(]+)').firstMatch(muscle);
    if (match != null) {
      return match.group(1)!.trim();
    }
    // If comma separated, take first part
    if (muscle.contains(',')) {
      return muscle.split(',').first.trim();
    }
    return muscle.trim();
  }

  /// Build targeted muscles section - compact version
  Widget _buildTargetedMusclesSection(List<String> muscles) {
    if (muscles.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    // Extract unique short muscle names
    final shortMuscles = muscles
        .map(_shortenMuscleName)
        .toSet()
        .take(6) // Max 6 muscles shown
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: cardBorder.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.cyan.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.accessibility_new,
                color: AppColors.cyan,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: shortMuscles.map((muscle) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.cyan.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      muscle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.cyan,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(duration: AppAnimations.fast, curve: AppAnimations.fastOut)
      .slideY(begin: 0.05, end: 0, duration: AppAnimations.quick, curve: AppAnimations.decelerate);
  }

  /// Build AI Reasoning section - expandable section showing why exercises were selected
  Widget _buildAIReasoningSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          // Expandable header
          GestureDetector(
            onTap: () => setState(() => _isAIReasoningExpanded = !_isAIReasoningExpanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.green.withOpacity(0.15),
                    AppColors.cyan.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: Radius.circular(_isAIReasoningExpanded ? 0 : 12),
                  bottomRight: Radius.circular(_isAIReasoningExpanded ? 0 : 12),
                ),
                border: Border.all(
                  color: AppColors.green.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.psychology,
                      color: AppColors.green,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WHY THESE EXERCISES?',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: textMuted,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (_isLoadingParams)
                          Text(
                            'Loading AI reasoning...',
                            style: TextStyle(
                              fontSize: 13,
                              color: textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        else
                          Text(
                            'Tap to see AI reasoning for exercise selection',
                            style: TextStyle(
                              fontSize: 12,
                              color: textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    _isAIReasoningExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.green,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
          // Expanded content
          if (_isAIReasoningExpanded && _generationParams != null)
            Container(
              decoration: BoxDecoration(
                color: elevatedColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                border: Border.all(
                  color: cardBorder.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overall workout reasoning
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: AppColors.purple,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Workout Design',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.purple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _generationParams!.workoutReasoning,
                          style: TextStyle(
                            fontSize: 13,
                            color: textPrimary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: cardBorder.withOpacity(0.3), height: 1),
                  // Exercise-specific reasoning
                  if (_generationParams!.exerciseReasoning.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.fitness_center,
                                color: AppColors.cyan,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Exercise Selection',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.cyan,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ..._generationParams!.exerciseReasoning.take(5).map((er) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.only(top: 6, right: 10),
                                    decoration: BoxDecoration(
                                      color: AppColors.cyan,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          er.exerciseName,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          er.reasoning,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: textSecondary,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          if (_generationParams!.exerciseReasoning.length > 5)
                            Text(
                              '+ ${_generationParams!.exerciseReasoning.length - 5} more exercises...',
                              style: TextStyle(
                                fontSize: 12,
                                color: textMuted,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ),
                  // View Parameters button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: GestureDetector(
                      onTap: () => _showViewParametersModal(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.orange.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.tune,
                              color: AppColors.orange,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'View All Parameters Sent to AI',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ).animate()
      .fadeIn(duration: AppAnimations.fast, curve: AppAnimations.fastOut)
      .slideY(begin: 0.05, end: 0, duration: AppAnimations.quick, curve: AppAnimations.decelerate);
  }

  /// Show modal with all parameters sent to AI
  void _showViewParametersModal() {
    if (_generationParams == null) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final params = _generationParams!;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: elevatedColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Draggable handle
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: textMuted.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 12, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.orange.withOpacity(0.3),
                            AppColors.purple.withOpacity(0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.tune,
                        color: AppColors.orange,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'AI Generation Parameters',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: textMuted),
                    ),
                  ],
                ),
              ),
              Divider(color: cardBorder.withOpacity(0.3), height: 1),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // User Profile Section
                    _buildParamsSection(
                      title: 'User Profile',
                      icon: Icons.person,
                      color: AppColors.cyan,
                      items: [
                        if (params.userProfile.fitnessLevel != null)
                          _ParamItem('Fitness Level', params.userProfile.fitnessLevel!.capitalize()),
                        if (params.userProfile.goals.isNotEmpty)
                          _ParamItem('Goals', params.userProfile.goals.join(', ')),
                        if (params.userProfile.equipment.isNotEmpty)
                          _ParamItem('Equipment', params.userProfile.equipment.join(', ')),
                        if (params.userProfile.injuries.isNotEmpty)
                          _ParamItem('Injuries/Limitations', params.userProfile.injuries.join(', ')),
                        if (params.userProfile.age != null)
                          _ParamItem('Age', '${params.userProfile.age}'),
                        if (params.userProfile.gender != null)
                          _ParamItem('Gender', params.userProfile.gender!.capitalize()),
                      ],
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    const SizedBox(height: 16),
                    // Program Preferences Section
                    _buildParamsSection(
                      title: 'Program Preferences',
                      icon: Icons.settings,
                      color: AppColors.purple,
                      items: [
                        if (params.programPreferences.difficulty != null)
                          _ParamItem('Difficulty', params.programPreferences.difficulty!.capitalize()),
                        if (params.programPreferences.durationMinutes != null)
                          _ParamItem('Duration', '${params.programPreferences.durationMinutes} min'),
                        if (params.programPreferences.workoutType != null)
                          _ParamItem('Workout Type', params.programPreferences.workoutType!.capitalize()),
                        if (params.programPreferences.trainingSplit != null)
                          _ParamItem('Training Split', params.programPreferences.trainingSplit!.replaceAll('_', ' ').capitalize()),
                        if (params.programPreferences.focusAreas.isNotEmpty)
                          _ParamItem('Focus Areas', params.programPreferences.focusAreas.join(', ')),
                        if (params.programPreferences.workoutDays.isNotEmpty)
                          _ParamItem('Workout Days', params.programPreferences.workoutDays.join(', ')),
                      ],
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    const SizedBox(height: 16),
                    // Workout Specifics Section
                    _buildParamsSection(
                      title: 'Workout Specifics',
                      icon: Icons.fitness_center,
                      color: AppColors.green,
                      items: [
                        _ParamItem('Workout Name', params.workoutName ?? 'N/A'),
                        _ParamItem('Type', (params.workoutType ?? 'N/A').capitalize()),
                        _ParamItem('Difficulty', (params.difficulty ?? 'N/A').capitalize()),
                        _ParamItem('Duration', '${params.durationMinutes ?? 0} min'),
                        _ParamItem('Generation Method', (params.generationMethod ?? 'ai').toUpperCase()),
                        if (params.targetMuscles.isNotEmpty)
                          _ParamItem('Target Muscles', params.targetMuscles.join(', ')),
                      ],
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    const SizedBox(height: 24),
                    // Info box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cyan.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.cyan.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.cyan,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'These parameters were used by the AI to generate personalized exercises that match your fitness level, goals, and available equipment.',
                              style: TextStyle(
                                fontSize: 13,
                                color: textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build a section in the parameters modal
  Widget _buildParamsSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<_ParamItem> items,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    // Filter out empty items
    final validItems = items.where((item) => item.value.isNotEmpty && item.value != 'N/A').toList();
    if (validItems.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Divider(color: cardBorder.withOpacity(0.3), height: 1),
          // Items
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: validItems.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item.value,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Build collapsible section header for warmup/stretches
  Widget _buildCollapsibleSectionHeader({
    required String title,
    required IconData icon,
    required Color color,
    required bool isExpanded,
    required VoidCallback onTap,
    required int itemCount,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 12),
            Text(
              title,
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
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$itemCount',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            const Spacer(),
            Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  /// Build warmup exercises (static list for now)
  List<Map<String, String>> _getWarmupExercises() {
    return [
      {'name': 'Jumping Jacks', 'duration': '60 sec'},
      {'name': 'Arm Circles', 'duration': '30 sec'},
      {'name': 'Hip Circles', 'duration': '30 sec'},
      {'name': 'Leg Swings', 'duration': '30 sec each'},
      {'name': 'Light Cardio', 'duration': '2-3 min'},
    ];
  }

  /// Build stretch exercises (static list for now)
  List<Map<String, String>> _getStretchExercises() {
    return [
      {'name': 'Quad Stretch', 'duration': '30 sec each'},
      {'name': 'Hamstring Stretch', 'duration': '30 sec each'},
      {'name': 'Shoulder Stretch', 'duration': '30 sec each'},
      {'name': 'Chest Opener', 'duration': '30 sec'},
      {'name': 'Cat-Cow Stretch', 'duration': '60 sec'},
    ];
  }

  /// Build warmup/stretch item
  Widget _buildWarmupStretchItem(Map<String, String> item, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: glassSurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.fitness_center, color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item['name'] ?? '',
              style: TextStyle(
                fontSize: 14,
                color: textPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              item['duration'] ?? '',
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Stat Card
// ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  TextSpan(
                    text: ' $label',
                    style: TextStyle(
                      fontSize: 12,
                      color: textMuted,
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
}


// ─────────────────────────────────────────────────────────────────
// Param Item (helper for parameters modal)
// ─────────────────────────────────────────────────────────────────

class _ParamItem {
  final String label;
  final String value;

  _ParamItem(this.label, this.value);
}


// ─────────────────────────────────────────────────────────────────
// String Extension
// ─────────────────────────────────────────────────────────────────

extension _StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}
