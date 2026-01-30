import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/workout.dart';
import 'pre_auth_quiz_screen.dart';

/// Plan preview screen shown after user selects primary goal and clicks "Generate My First Workout"
///
/// Displays:
/// - Summary card with user's selections
/// - AI-generated workout preview (actual exercises from Gemini)
/// - Two action buttons:
///   1. "Start Workout" → Skip to Screen 10 (Nutrition Gate, then coach selection)
///   2. "Personalize (2 min)" → Navigate to Screen 6 (Personalization Gate)
class PlanPreviewScreen extends StatelessWidget {
  final PreAuthQuizData quizData;
  final Workout? generatedWorkout;  // ← ADDED: Actual generated workout
  final VoidCallback onContinue;
  final VoidCallback onStartNow;

  const PlanPreviewScreen({
    super.key,
    required this.quizData,
    this.generatedWorkout,  // ← ADDED: Optional (for backwards compatibility)
    required this.onContinue,
    required this.onStartNow,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary = isDark ? const Color(0xFFD4D4D8) : const Color(0xFF52525B);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0A1628), AppColors.pureBlack],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Color(0xFFF8F9FA)],
                ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Main content column
              Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 68, 20, 12),  // Increased top padding to avoid back button overlap
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(
                      'Your Personalized Plan',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ).animate().fadeIn(delay: 100.ms).slideY(begin: -0.1),
                    const SizedBox(height: 6),
                    // ← ADDED: Trust badge with info button
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 14,
                          color: AppColors.orange,
                        ).animate()
                          .fadeIn(delay: 200.ms)
                          .then()
                          .shimmer(duration: 1500.ms, delay: 500.ms),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'AI-generated • Adjusts as you progress',
                            style: TextStyle(
                              fontSize: 13,
                              color: textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => _showAIInfoBottomSheet(context, isDark),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.info_outline_rounded,
                              size: 16,
                              color: textSecondary.withOpacity(0.6),
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 200.ms),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    // Summary Card
                    _buildSummaryCard(isDark, textPrimary, textSecondary),
                    const SizedBox(height: 24),

                    // Sample Workout Preview
                    _buildWorkoutPreview(isDark, textPrimary, textSecondary),
                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // Action buttons - ← UPDATED: Better CTA labels
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Primary: Start Workout
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          onStartNow();  // ← Swapped: Primary is "Start Workout"
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.orange,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shadowColor: AppColors.orange.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Start Workout',  // ← UPDATED: More action-oriented
                              style: TextStyle(
                                fontSize: 17,  // ← Slightly larger
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.fitness_center_rounded, size: 20),  // ← Changed icon
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.1),
                    const SizedBox(height: 12),

                    // Secondary: Personalize (optional but prominent)
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton(
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              onContinue();  // ← Swapped: Secondary is personalization
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.orange,
                              side: BorderSide(
                                color: AppColors.orange,
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              backgroundColor: AppColors.orange.withValues(alpha: 0.08),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Personalize (2 min)',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.tune_rounded, size: 18),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Info text explaining what personalization includes
                        InkWell(
                          onTap: () => _showPersonalizeInfoBottomSheet(context, isDark),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 14,
                                  color: textSecondary.withOpacity(0.6),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Includes injury accommodations',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: textSecondary.withOpacity(0.8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.1),
                  ],
                ),
              ),
            ],
          ),

            // Floating back button (top-left)
            Positioned(
              top: 16,
              left: 16,
              child: _FloatingBackButton(
                isDark: isDark,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildSummaryCard(bool isDark, Color textPrimary, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.all(16),  // ← REDUCED from 20 to 16
      decoration: BoxDecoration(
        color: isDark ? AppColors.glassSurface : AppColorsLight.glassSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.glassBorder : AppColorsLight.cardBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ← ADDED: Plan summary line at top
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: AppColors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getPlanSummary(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Equipment
          if (quizData.workoutEnvironment != null)
            _buildSummaryItem(
              Icons.home_rounded,
              'Environment',
              _formatEnvironment(quizData.workoutEnvironment!),
              isDark,
              textPrimary,
              textSecondary,
            ),
          const SizedBox(height: 10),  // ← REDUCED spacing

          // Primary Goal
          if (quizData.primaryGoal != null)
            _buildSummaryItem(
              Icons.stars_rounded,
              'Training Focus',
              _formatPrimaryGoal(quizData.primaryGoal!),
              isDark,
              textPrimary,
              textSecondary,
            ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05);
  }

  Widget _buildSummaryItem(
    IconData icon,
    String label,
    String value,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.orange,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkoutPreview(bool isDark, Color textPrimary, Color textSecondary) {
    // Use generated workout if available, otherwise show static template
    final hasGeneratedWorkout = generatedWorkout != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.glassSurface : AppColorsLight.glassSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.glassBorder : AppColorsLight.cardBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  hasGeneratedWorkout ? 'Your AI-Generated Workout' : 'Sample Workout Preview',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ),
              if (hasGeneratedWorkout)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 12,
                        color: AppColors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'AI',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hasGeneratedWorkout ? (generatedWorkout!.name ?? 'Day 1') : 'Day 1: ${_getWorkoutTitle()}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.orange,
            ),
          ),
          const SizedBox(height: 14),

          // Exercise list - show real exercises if available
          ..._buildExerciseList(isDark, textPrimary, textSecondary),

          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.orange,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hasGeneratedWorkout
                        ? 'Full 4-week plan generates after setup • Workouts vary each week'
                        : 'Full plan builds after this step • Workouts vary based on your progress',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.05);
  }

  List<Widget> _buildExerciseList(bool isDark, Color textPrimary, Color textSecondary) {
    // Use actual generated exercises if available
    final exercises = generatedWorkout != null && generatedWorkout!.exercises.isNotEmpty
        ? generatedWorkout!.exercises.take(4).map((exercise) {
            return {
              'name': exercise.name,
              'sets': '${exercise.sets ?? 3} sets × ${exercise.reps ?? 10} reps',
            };
          }).toList()
        : _getSampleExercises();

    return exercises.asMap().entries.map((entry) {
      final index = entry.key;
      final exercise = entry.value;
      return Padding(
        padding: EdgeInsets.only(bottom: index < exercises.length - 1 ? 10 : 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.orange.withValues(alpha: 0.15),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.orange,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise['name']!,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    exercise['sets']!,
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  // ← REMOVED: Info box is redundant (personalization gate is next screen)

  // Helper methods
  String _formatGoals(List<String> goals) {
    if (goals.isEmpty) return 'Not specified';
    final formatted = goals.map((g) => _capitalize(g.replaceAll('_', ' '))).toList();
    if (formatted.length == 1) return formatted.first;
    if (formatted.length == 2) return '${formatted[0]} & ${formatted[1]}';
    return '${formatted.sublist(0, formatted.length - 1).join(', ')} & ${formatted.last}';
  }

  String _formatEnvironment(String env) {
    switch (env) {
      case 'commercial_gym':
        return 'Commercial Gym';
      case 'home_gym':
        return 'Home Gym';
      case 'home':
        return 'Home';
      case 'hotel':
        return 'Hotel/Travel';
      default:
        return _capitalize(env.replaceAll('_', ' '));
    }
  }

  String _formatPrimaryGoal(String goal) {
    switch (goal) {
      case 'muscle_strength':
        return 'Muscle Strength';
      case 'muscle_hypertrophy':
        return 'Muscle Hypertrophy';
      case 'endurance':
        return 'Endurance';
      case 'strength_hypertrophy':
        return 'Strength + Hypertrophy';
      default:
        return _capitalize(goal.replaceAll('_', ' '));
    }
  }

  String _getWorkoutTitle() {
    final goal = quizData.primaryGoal;
    if (goal == 'muscle_strength' || goal == 'strength_hypertrophy') {
      return 'Push (Chest, Shoulders, Triceps)';
    } else if (goal == 'muscle_hypertrophy') {
      return 'Upper Body Hypertrophy';
    } else {
      return 'Full Body Circuit';
    }
  }

  List<Map<String, String>> _getSampleExercises() {
    final goal = quizData.primaryGoal;
    final equipment = quizData.equipment ?? [];
    final hasBarbell = equipment.contains('barbell') || equipment.contains('full_gym');
    final hasDumbbells = equipment.contains('dumbbells') || equipment.contains('full_gym');

    if (goal == 'muscle_strength' || goal == 'strength_hypertrophy') {
      return [
        {
          'name': hasBarbell ? 'Barbell Bench Press' : (hasDumbbells ? 'Dumbbell Bench Press' : 'Push-Ups'),
          'sets': '4 sets × 6-8 reps',
        },
        {
          'name': hasDumbbells ? 'Dumbbell Shoulder Press' : 'Pike Push-Ups',
          'sets': '3 sets × 8-10 reps',
        },
        {
          'name': 'Tricep Dips',
          'sets': '3 sets × 10-12 reps',
        },
        {
          'name': hasDumbbells ? 'Dumbbell Lateral Raises' : 'Shoulder Taps',
          'sets': '3 sets × 12-15 reps',
        },
      ];
    } else if (goal == 'muscle_hypertrophy') {
      return [
        {
          'name': hasDumbbells ? 'Dumbbell Bench Press' : 'Push-Ups',
          'sets': '4 sets × 10-12 reps',
        },
        {
          'name': hasBarbell ? 'Barbell Rows' : (hasDumbbells ? 'Dumbbell Rows' : 'Bodyweight Rows'),
          'sets': '4 sets × 10-12 reps',
        },
        {
          'name': hasDumbbells ? 'Dumbbell Shoulder Press' : 'Pike Push-Ups',
          'sets': '3 sets × 12-15 reps',
        },
        {
          'name': hasDumbbells ? 'Bicep Curls' : 'Chin-Ups',
          'sets': '3 sets × 12-15 reps',
        },
      ];
    } else {
      return [
        {
          'name': 'Jump Squats',
          'sets': '3 sets × 15 reps',
        },
        {
          'name': 'Push-Ups',
          'sets': '3 sets × 15 reps',
        },
        {
          'name': 'Mountain Climbers',
          'sets': '3 sets × 30 seconds',
        },
        {
          'name': 'Plank',
          'sets': '3 sets × 45 seconds',
        },
      ];
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Show bottom sheet explaining AI-generated workouts
  void _showAIInfoBottomSheet(BuildContext context, bool isDark) {
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary = isDark ? const Color(0xFFD4D4D8) : const Color(0xFF52525B);

    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with sparkle icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'AI-Powered Workouts',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Explanation text
            Text(
              'Your workout plan is intelligently generated using advanced AI that considers:',
              style: TextStyle(
                fontSize: 15,
                color: textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),

            // Features list
            _buildInfoItem(
              icon: Icons.fitness_center_rounded,
              title: 'Your Equipment',
              description: 'Exercises matched to what you have available',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              icon: Icons.trending_up_rounded,
              title: 'Your Goals',
              description: 'Training focus aligned with what you want to achieve',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              icon: Icons.science_rounded,
              title: 'Progressive Overload',
              description: 'Workouts adapt each week to keep you improving',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              icon: Icons.psychology_rounded,
              title: 'Smart Recovery',
              description: 'Balanced muscle group targeting for optimal results',
              isDark: isDark,
            ),

            const SizedBox(height: 24),

            // Close button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Got it',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  /// Show bottom sheet explaining personalization options
  void _showPersonalizeInfoBottomSheet(BuildContext context, bool isDark) {
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary = isDark ? const Color(0xFFD4D4D8) : const Color(0xFF52525B);

    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with tune icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: AppColors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Personalization',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Explanation text
            Text(
              'Take 2 minutes to fine-tune your plan:',
              style: TextStyle(
                fontSize: 15,
                color: textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),

            // Features list
            _buildInfoItem(
              icon: Icons.fitness_center,
              title: 'Muscle Targeting',
              description: 'Prioritize specific muscle groups (triceps, lats, etc.)',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              icon: Icons.view_week_rounded,
              title: 'Training Style',
              description: 'Choose PPL, Upper/Lower, Full Body, or let AI decide',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              icon: Icons.speed_rounded,
              title: 'Progression Pace',
              description: 'Set how quickly you want to increase difficulty',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              icon: Icons.health_and_safety_outlined,
              title: 'Limitations',
              description: 'Flag any injuries or joint issues to work around',
              isDark: isDark,
            ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textSecondary,
                        side: BorderSide(
                          color: isDark ? AppColors.glassBorder : AppColorsLight.cardBorder,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Maybe later',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.of(context).pop();
                        onContinue(); // Trigger personalization flow
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Personalize',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String description,
    required bool isDark,
  }) {
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary = isDark ? const Color(0xFFD4D4D8) : const Color(0xFF52525B);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.orange,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ← ADDED: Plan summary generator
  String _getPlanSummary() {
    final parts = <String>[];

    if (quizData.daysPerWeek != null) {
      parts.add('${quizData.daysPerWeek} days/week');
    }
    if (quizData.workoutDuration != null) {
      parts.add('${quizData.workoutDuration} min');
    }

    // Add training split based on days/week (simple heuristic)
    final days = quizData.daysPerWeek ?? 3;
    String split;
    if (days <= 2) {
      split = 'Full Body';
    } else if (days == 3) {
      split = 'PPL or Full Body';
    } else if (days == 4) {
      split = 'Upper/Lower';
    } else {
      split = 'PPL';
    }
    parts.add(split);

    return parts.join(' • ');
  }
}

/// Glassmorphic floating back button with blur effect
class _FloatingBackButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback onPressed;

  const _FloatingBackButton({
    required this.isDark,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.1),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.arrow_back_ios_rounded,
              size: 18,
              color: isDark ? Colors.white : const Color(0xFF0A0A0A),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1);
  }
}
