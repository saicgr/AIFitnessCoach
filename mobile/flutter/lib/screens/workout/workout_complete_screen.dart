import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/workout.dart';
import '../../data/repositories/workout_repository.dart';

class WorkoutCompleteScreen extends ConsumerStatefulWidget {
  final Workout workout;
  final int duration;
  final int calories;

  const WorkoutCompleteScreen({
    super.key,
    required this.workout,
    required this.duration,
    required this.calories,
  });

  @override
  ConsumerState<WorkoutCompleteScreen> createState() => _WorkoutCompleteScreenState();
}

class _WorkoutCompleteScreenState extends ConsumerState<WorkoutCompleteScreen> {
  int _rating = 0;
  String _difficulty = 'just_right';
  bool _isSubmitting = false;
  String? _aiSummary;
  bool _isLoadingSummary = true;

  @override
  void initState() {
    super.initState();
    _loadWorkoutSummary();
  }

  Future<void> _loadWorkoutSummary() async {
    try {
      final workoutRepo = ref.read(workoutRepositoryProvider);
      // Simulate loading AI summary (in real app, this would be an API call)
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _aiSummary = _generateSummary();
        _isLoadingSummary = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingSummary = false;
      });
    }
  }

  String _generateSummary() {
    final workout = widget.workout;
    final minutes = widget.duration ~/ 60;
    final exercises = workout.exercises.length;

    final summaries = [
      "Great workout! You crushed ${exercises} exercises in $minutes minutes. Your consistency is building real strength.",
      "Solid session! You're making progress every time you show up. Keep pushing, and the results will follow.",
      "Another workout in the books! Your dedication is paying off. Recovery is just as important - rest well tonight.",
      "Well done! You completed all $exercises exercises. Focus on form next time to maximize gains.",
    ];

    return summaries[DateTime.now().second % summaries.length];
  }

  Future<void> _submitFeedback() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please rate your workout'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Submit feedback to backend (would be an API call in real app)
      await Future.delayed(const Duration(seconds: 1));

      // Refresh workouts
      await ref.read(workoutsProvider.notifier).refresh();

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit feedback'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    if (mins > 0) {
      return '$mins min ${secs > 0 ? '$secs sec' : ''}';
    }
    return '$secs sec';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureBlack,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 24),

                // Success Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.success.withOpacity(0.3),
                        AppColors.cyan.withOpacity(0.2),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.celebration,
                    size: 48,
                    color: AppColors.success,
                  ),
                ).animate().scale(
                  duration: 500.ms,
                  curve: Curves.elasticOut,
                ),

                const SizedBox(height: 24),

                // Title
                Text(
                  'Workout Complete!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

                const SizedBox(height: 8),

                Text(
                  widget.workout.name ?? 'Workout',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 32),

                // Stats Grid
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        icon: Icons.timer,
                        value: _formatDuration(widget.duration),
                        label: 'Duration',
                        color: AppColors.cyan,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatTile(
                        icon: Icons.fitness_center,
                        value: '${widget.workout.exercises.length}',
                        label: 'Exercises',
                        color: AppColors.purple,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatTile(
                        icon: Icons.local_fire_department,
                        value: '${widget.calories}',
                        label: 'Calories',
                        color: AppColors.orange,
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

                const SizedBox(height: 24),

                // AI Summary
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.elevated,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.cyan.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              size: 16,
                              color: AppColors.cyan,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'AI Coach Feedback',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.cyan,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _isLoadingSummary
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.cyan,
                                ),
                              ),
                            )
                          : Text(
                              _aiSummary ?? 'Great workout! Keep up the momentum.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                height: 1.5,
                              ),
                            ),
                    ],
                  ),
                ).animate().fadeIn(delay: 500.ms),

                const SizedBox(height: 32),

                // Rating Section
                Text(
                  'How was your workout?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starIndex = index + 1;
                    return GestureDetector(
                      onTap: () => setState(() => _rating = starIndex),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          starIndex <= _rating
                              ? Icons.star
                              : Icons.star_border,
                          size: 40,
                          color: starIndex <= _rating
                              ? AppColors.orange
                              : AppColors.textMuted,
                        ),
                      ),
                    );
                  }),
                ).animate().fadeIn(delay: 600.ms),

                const SizedBox(height: 24),

                // Difficulty Feedback
                Text(
                  'How was the difficulty?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    _DifficultyOption(
                      label: 'Too Easy',
                      icon: Icons.sentiment_very_satisfied,
                      isSelected: _difficulty == 'too_easy',
                      onTap: () => setState(() => _difficulty = 'too_easy'),
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 12),
                    _DifficultyOption(
                      label: 'Just Right',
                      icon: Icons.sentiment_satisfied,
                      isSelected: _difficulty == 'just_right',
                      onTap: () => setState(() => _difficulty = 'just_right'),
                      color: AppColors.cyan,
                    ),
                    const SizedBox(width: 12),
                    _DifficultyOption(
                      label: 'Too Hard',
                      icon: Icons.sentiment_dissatisfied,
                      isSelected: _difficulty == 'too_hard',
                      onTap: () => setState(() => _difficulty = 'too_hard'),
                      color: AppColors.error,
                    ),
                  ],
                ).animate().fadeIn(delay: 700.ms),

                const SizedBox(height: 40),

                // Done Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitFeedback,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.pureBlack,
                            ),
                          )
                        : const Text(
                            'Done',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.1),

                const SizedBox(height: 16),

                TextButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Skip Feedback'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Stat Tile
// ─────────────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Difficulty Option
// ─────────────────────────────────────────────────────────────────

class _DifficultyOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _DifficultyOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.2) : AppColors.elevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : AppColors.cardBorder,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? color : AppColors.textMuted,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? color : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
