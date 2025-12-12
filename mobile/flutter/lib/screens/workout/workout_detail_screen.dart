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
import '../../data/repositories/workout_repository.dart';
import 'widgets/workout_actions_sheet.dart';
import 'widgets/exercise_swap_sheet.dart';
import 'widgets/expanded_exercise_card.dart';
import 'package:flutter/services.dart';
import '../../widgets/floating_chat/floating_chat_provider.dart';

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
      // Load workout summary after workout loads
      _loadWorkoutSummary();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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

              // Type badges row
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          workout.type?.toUpperCase() ?? 'STRENGTH',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: typeColor,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: glassSurface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          (workout.difficulty ?? 'Medium').capitalize(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.getDifficultyColor(
                              workout.difficulty ?? 'medium',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
                    onTap: () {
                      // TODO: Add exercise functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Add exercise feature coming soon!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
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

          // Bottom padding for FAB
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
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
            ref.read(floatingChatProvider.notifier).expand();
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
        // Play Button (smaller)
        FloatingActionButton(
          heroTag: 'start_workout',
          onPressed: () => context.push('/active-workout', extra: workout),
          backgroundColor: AppColors.cyan,
          foregroundColor: AppColors.pureBlack,
          elevation: 8,
          child: const Icon(Icons.play_arrow_rounded, size: 28),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final surfaceColor = isDark ? AppColors.surface : AppColorsLight.surface;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    // Parse JSON insights
    final insights = _parseInsightsJson(summaryJson);
    final headline = insights?['headline'] as String? ?? 'Workout Insights';
    final sections = (insights?['sections'] as List<dynamic>?) ?? [];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.25,
        maxChildSize: 0.7,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: surfaceColor,
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
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
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
                child: ListView(
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

                        return _buildInsightSection(icon, title, content, color);
                      })
                    else
                      // Fallback for non-JSON or parse error
                      Text(
                        _stripMarkdown(summaryJson),
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
      ),
    );
  }

  /// Build a single insight section with icon, colored title, and content
  Widget _buildInsightSection(String icon, String title, String content, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

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
// String Extension
// ─────────────────────────────────────────────────────────────────

extension _StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}
