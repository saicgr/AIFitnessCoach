import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../onboarding/pre_auth_quiz_screen.dart';

/// Full Plan Preview Screen
/// Shows the user's complete personalized 4-week workout plan BEFORE asking them to subscribe
/// This addresses the user complaint: "After giving all the personal information, it requires subscription to see the personal plan."
class PlanPreviewScreen extends ConsumerStatefulWidget {
  const PlanPreviewScreen({super.key});

  @override
  ConsumerState<PlanPreviewScreen> createState() => _PlanPreviewScreenState();
}

class _PlanPreviewScreenState extends ConsumerState<PlanPreviewScreen>
    with SingleTickerProviderStateMixin {
  int _selectedWeek = 0;
  bool _isLoading = true;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Simulate loading the personalized plan
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quizData = ref.watch(preAuthQuizProvider);
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: _isLoading
          ? _buildLoadingState(isDark, textPrimary, textSecondary)
          : _buildPlanContent(isDark, quizData, textPrimary, textSecondary),
    );
  }

  Widget _buildLoadingState(bool isDark, Color textPrimary, Color textSecondary) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated AI icon
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_pulseController.value * 0.1),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: AppColors.cyanGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.cyan.withOpacity(0.3 + _pulseController.value * 0.2),
                          blurRadius: 24 + _pulseController.value * 12,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            Text(
              'Building Your 4-Week Plan...',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                'Analyzing your goals, fitness level, and equipment to create the perfect program',
                style: TextStyle(
                  fontSize: 15,
                  color: textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 32),

            // Loading progress steps
            _buildLoadingSteps(textPrimary, textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSteps(Color textPrimary, Color textSecondary) {
    final steps = [
      {'text': 'Personalizing exercises...', 'delay': 0},
      {'text': 'Optimizing workout split...', 'delay': 400},
      {'text': 'Calculating progression...', 'delay': 800},
    ];

    return Column(
      children: steps.map((step) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: AppColors.success, size: 18),
              const SizedBox(width: 8),
              Text(
                step['text'] as String,
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                ),
              ),
            ],
          ).animate(delay: Duration(milliseconds: step['delay'] as int)).fadeIn(),
        );
      }).toList(),
    );
  }

  Widget _buildPlanContent(
    bool isDark,
    PreAuthQuizData quizData,
    Color textPrimary,
    Color textSecondary,
  ) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final borderColor = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return SafeArea(
      child: Column(
        children: [
          // Header
          _buildHeader(isDark, textPrimary, textSecondary),

          // Week selector tabs
          _buildWeekTabs(isDark, textPrimary, textSecondary, elevatedColor),

          // Plan content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // "This is YOUR personalized plan" header
                  _buildPersonalizedHeader(isDark, quizData, textPrimary, textSecondary),

                  const SizedBox(height: 20),

                  // Weekly workouts
                  ..._buildWeeklyWorkouts(isDark, quizData, textPrimary, textSecondary, elevatedColor, borderColor),

                  const SizedBox(height: 24),

                  // What you'll achieve section
                  _buildAchievementsSection(isDark, textPrimary, textSecondary, elevatedColor, borderColor),

                  const SizedBox(height: 120), // Space for CTAs
                ],
              ),
            ),
          ),

          // Bottom CTAs
          _buildBottomCTAs(isDark, textPrimary),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color textPrimary, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? AppColors.elevated : AppColorsLight.elevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: textSecondary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your 4-Week Plan',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.visibility, color: Colors.green, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            'FREE PREVIEW',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildWeekTabs(bool isDark, Color textPrimary, Color textSecondary, Color elevatedColor) {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(4, (index) {
          final isSelected = _selectedWeek == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedWeek = index);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.cyan : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    'Week ${index + 1}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 300.ms);
  }

  Widget _buildPersonalizedHeader(
    bool isDark,
    PreAuthQuizData quizData,
    Color textPrimary,
    Color textSecondary,
  ) {
    final goalDisplay = _formatGoal(quizData.goal ?? 'build_muscle');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cyan.withOpacity(0.15),
            AppColors.teal.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColors.cyanGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This is YOUR Personalized Plan',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Designed based on your quiz answers',
                      style: TextStyle(
                        fontSize: 13,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // User's selections summary
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSummaryChip(Icons.flag_outlined, goalDisplay, AppColors.cyan),
              _buildSummaryChip(Icons.calendar_today, '${quizData.daysPerWeek ?? 3} days/week', AppColors.purple),
              _buildSummaryChip(Icons.trending_up, _formatLevel(quizData.fitnessLevel ?? 'intermediate'), AppColors.orange),
              _buildSummaryChip(Icons.fitness_center, '${quizData.equipment?.length ?? 3} equipment', AppColors.teal),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 300.ms).slideY(begin: 0.05);
  }

  Widget _buildSummaryChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildWeeklyWorkouts(
    bool isDark,
    PreAuthQuizData quizData,
    Color textPrimary,
    Color textSecondary,
    Color elevatedColor,
    Color borderColor,
  ) {
    final daysPerWeek = quizData.daysPerWeek ?? 3;
    final workoutDays = quizData.workoutDays ?? [0, 2, 4]; // Default Mon, Wed, Fri
    final goal = quizData.goal ?? 'build_muscle';

    // Generate workout schedule based on quiz answers
    final workouts = _generateWorkoutSchedule(goal, daysPerWeek, workoutDays, _selectedWeek);

    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    return List.generate(7, (dayIndex) {
      final workout = workouts[dayIndex];
      final isWorkoutDay = workout != null;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          decoration: BoxDecoration(
            color: elevatedColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isWorkoutDay ? (workout['color'] as Color).withOpacity(0.3) : borderColor,
            ),
          ),
          child: isWorkoutDay
              ? _buildWorkoutDayCard(dayNames[dayIndex], workout, textPrimary, textSecondary)
              : _buildRestDayCard(dayNames[dayIndex], textPrimary, textSecondary),
        ).animate(delay: Duration(milliseconds: 250 + dayIndex * 50)).fadeIn().slideX(begin: 0.02),
      );
    });
  }

  Widget _buildWorkoutDayCard(
    String dayName,
    Map<String, dynamic> workout,
    Color textPrimary,
    Color textSecondary,
  ) {
    final color = workout['color'] as Color;
    final exercises = workout['exercises'] as List<Map<String, dynamic>>;

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      childrenPadding: const EdgeInsets.only(left: 14, right: 14, bottom: 14),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          workout['icon'] as IconData,
          color: color,
          size: 22,
        ),
      ),
      title: Row(
        children: [
          Text(
            dayName,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              workout['type'] as String,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
      subtitle: Text(
        '${exercises.length} exercises - ${workout['duration']} min',
        style: TextStyle(
          fontSize: 12,
          color: textSecondary,
        ),
      ),
      children: [
        // Exercises list
        ...exercises.asMap().entries.map((entry) {
          final idx = entry.key;
          final exercise = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${idx + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color,
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
                        exercise['name'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        exercise['setsReps'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  exercise['muscle'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRestDayCard(String dayName, Color textPrimary, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.self_improvement,
              color: Colors.grey,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dayName,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
              Text(
                'Rest & Recovery',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color elevatedColor,
    Color borderColor,
  ) {
    final achievements = [
      {'week': 1, 'text': 'Master the movement patterns', 'icon': Icons.school},
      {'week': 2, 'text': 'Build strength foundation', 'icon': Icons.foundation},
      {'week': 3, 'text': 'Increase intensity & volume', 'icon': Icons.trending_up},
      {'week': 4, 'text': 'Peak performance week', 'icon': Icons.emoji_events},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_outlined, color: AppColors.cyan, size: 20),
              const SizedBox(width: 10),
              Text(
                'What You\'ll Achieve',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...achievements.map((achievement) {
            final isCurrentWeek = achievement['week'] == (_selectedWeek + 1);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isCurrentWeek
                          ? AppColors.cyan.withOpacity(0.15)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      achievement['icon'] as IconData,
                      size: 18,
                      color: isCurrentWeek ? AppColors.cyan : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Week ${achievement['week']}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isCurrentWeek ? AppColors.cyan : textSecondary,
                          ),
                        ),
                        Text(
                          achievement['text'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isCurrentWeek ? FontWeight.w600 : FontWeight.normal,
                            color: isCurrentWeek ? textPrimary : textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isCurrentWeek)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.cyan.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'VIEWING',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.cyan,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.05);
  }

  Widget _buildBottomCTAs(bool isDark, Color textPrimary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevated : AppColorsLight.elevated,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Try One Workout Free button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                context.push('/demo-workout');
              },
              icon: const Icon(Icons.play_circle_filled, size: 22),
              label: const Text(
                'Try One Workout Free',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Subscribe for full access
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      context.push('/paywall-pricing');
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.cyan),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Subscribe for Full Access',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.cyan,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.go('/home');
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.green),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.green.withOpacity(0.08),
                  ),
                  child: Text(
                    'Continue Free',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Generate workout schedule based on quiz answers
  Map<int, Map<String, dynamic>?> _generateWorkoutSchedule(
    String goal,
    int daysPerWeek,
    List<int> workoutDays,
    int weekIndex,
  ) {
    final schedule = <int, Map<String, dynamic>?>{};

    // Initialize all days as rest days
    for (int i = 0; i < 7; i++) {
      schedule[i] = null;
    }

    // Get workout types based on goal
    final workoutTypes = _getWorkoutTypesForGoal(goal, daysPerWeek);

    // Assign workouts to selected days
    for (int i = 0; i < workoutDays.length && i < workoutTypes.length; i++) {
      final dayIndex = workoutDays[i];
      final workoutType = workoutTypes[i];

      schedule[dayIndex] = {
        'type': workoutType['name'],
        'icon': workoutType['icon'],
        'color': workoutType['color'],
        'duration': 45 + (weekIndex * 5), // Progressive duration
        'exercises': _getExercisesForWorkout(workoutType['id'] as String, weekIndex),
      };
    }

    return schedule;
  }

  List<Map<String, dynamic>> _getWorkoutTypesForGoal(String goal, int daysPerWeek) {
    switch (goal) {
      case 'build_muscle':
      case 'increase_strength':
        if (daysPerWeek >= 4) {
          return [
            {'id': 'push', 'name': 'Push', 'icon': Icons.fitness_center, 'color': AppColors.purple},
            {'id': 'pull', 'name': 'Pull', 'icon': Icons.fitness_center, 'color': AppColors.electricBlue},
            {'id': 'legs', 'name': 'Legs', 'icon': Icons.directions_walk, 'color': AppColors.teal},
            {'id': 'upper', 'name': 'Upper', 'icon': Icons.fitness_center, 'color': AppColors.purple},
            {'id': 'lower', 'name': 'Lower', 'icon': Icons.directions_walk, 'color': AppColors.teal},
            {'id': 'full', 'name': 'Full Body', 'icon': Icons.accessibility_new, 'color': AppColors.orange},
            {'id': 'arms', 'name': 'Arms', 'icon': Icons.fitness_center, 'color': AppColors.coral},
          ];
        } else {
          return [
            {'id': 'upper', 'name': 'Upper Body', 'icon': Icons.fitness_center, 'color': AppColors.purple},
            {'id': 'lower', 'name': 'Lower Body', 'icon': Icons.directions_walk, 'color': AppColors.teal},
            {'id': 'full', 'name': 'Full Body', 'icon': Icons.accessibility_new, 'color': AppColors.orange},
          ];
        }

      case 'lose_weight':
        return [
          {'id': 'hiit', 'name': 'HIIT', 'icon': Icons.flash_on, 'color': AppColors.coral},
          {'id': 'strength', 'name': 'Strength', 'icon': Icons.fitness_center, 'color': AppColors.purple},
          {'id': 'cardio', 'name': 'Cardio', 'icon': Icons.directions_run, 'color': AppColors.orange},
          {'id': 'hiit', 'name': 'HIIT', 'icon': Icons.flash_on, 'color': AppColors.coral},
          {'id': 'full', 'name': 'Full Body', 'icon': Icons.accessibility_new, 'color': AppColors.teal},
          {'id': 'recovery', 'name': 'Active Recovery', 'icon': Icons.self_improvement, 'color': AppColors.success},
          {'id': 'cardio', 'name': 'Cardio', 'icon': Icons.directions_run, 'color': AppColors.orange},
        ];

      case 'improve_endurance':
        return [
          {'id': 'cardio', 'name': 'Cardio', 'icon': Icons.directions_run, 'color': AppColors.orange},
          {'id': 'intervals', 'name': 'Intervals', 'icon': Icons.timer, 'color': AppColors.coral},
          {'id': 'endurance', 'name': 'Endurance', 'icon': Icons.directions_bike, 'color': AppColors.teal},
          {'id': 'tempo', 'name': 'Tempo', 'icon': Icons.speed, 'color': AppColors.electricBlue},
          {'id': 'long', 'name': 'Long Run', 'icon': Icons.directions_run, 'color': AppColors.orange},
          {'id': 'recovery', 'name': 'Recovery', 'icon': Icons.self_improvement, 'color': AppColors.success},
          {'id': 'cross', 'name': 'Cross Train', 'icon': Icons.pool, 'color': AppColors.purple},
        ];

      default:
        return [
          {'id': 'full', 'name': 'Full Body', 'icon': Icons.accessibility_new, 'color': AppColors.purple},
          {'id': 'cardio', 'name': 'Cardio', 'icon': Icons.directions_run, 'color': AppColors.orange},
          {'id': 'strength', 'name': 'Strength', 'icon': Icons.fitness_center, 'color': AppColors.electricBlue},
          {'id': 'flexibility', 'name': 'Flexibility', 'icon': Icons.self_improvement, 'color': AppColors.teal},
          {'id': 'hiit', 'name': 'HIIT', 'icon': Icons.flash_on, 'color': AppColors.coral},
          {'id': 'active', 'name': 'Active', 'icon': Icons.directions_walk, 'color': AppColors.success},
          {'id': 'core', 'name': 'Core', 'icon': Icons.circle_outlined, 'color': AppColors.purple},
        ];
    }
  }

  List<Map<String, dynamic>> _getExercisesForWorkout(String workoutId, int weekIndex) {
    // Base sets and reps that progress each week
    final baseSets = 3 + (weekIndex ~/ 2);
    final baseReps = 10 + weekIndex;

    switch (workoutId) {
      case 'push':
        return [
          {'name': 'Bench Press', 'setsReps': '$baseSets x $baseReps', 'muscle': 'Chest'},
          {'name': 'Overhead Press', 'setsReps': '$baseSets x ${baseReps - 2}', 'muscle': 'Shoulders'},
          {'name': 'Incline Dumbbell Press', 'setsReps': '$baseSets x $baseReps', 'muscle': 'Upper Chest'},
          {'name': 'Tricep Dips', 'setsReps': '$baseSets x ${baseReps + 2}', 'muscle': 'Triceps'},
          {'name': 'Lateral Raises', 'setsReps': '3 x 15', 'muscle': 'Shoulders'},
        ];
      case 'pull':
        return [
          {'name': 'Deadlift', 'setsReps': '$baseSets x ${baseReps - 4}', 'muscle': 'Back'},
          {'name': 'Pull-Ups', 'setsReps': '$baseSets x ${baseReps - 2}', 'muscle': 'Lats'},
          {'name': 'Barbell Rows', 'setsReps': '$baseSets x $baseReps', 'muscle': 'Back'},
          {'name': 'Face Pulls', 'setsReps': '3 x 15', 'muscle': 'Rear Delts'},
          {'name': 'Bicep Curls', 'setsReps': '$baseSets x $baseReps', 'muscle': 'Biceps'},
        ];
      case 'legs':
      case 'lower':
        return [
          {'name': 'Squats', 'setsReps': '$baseSets x $baseReps', 'muscle': 'Quads'},
          {'name': 'Romanian Deadlift', 'setsReps': '$baseSets x $baseReps', 'muscle': 'Hamstrings'},
          {'name': 'Leg Press', 'setsReps': '$baseSets x ${baseReps + 2}', 'muscle': 'Legs'},
          {'name': 'Walking Lunges', 'setsReps': '3 x 12 each', 'muscle': 'Legs'},
          {'name': 'Calf Raises', 'setsReps': '4 x 15', 'muscle': 'Calves'},
        ];
      case 'upper':
        return [
          {'name': 'Bench Press', 'setsReps': '$baseSets x $baseReps', 'muscle': 'Chest'},
          {'name': 'Barbell Rows', 'setsReps': '$baseSets x $baseReps', 'muscle': 'Back'},
          {'name': 'Shoulder Press', 'setsReps': '$baseSets x ${baseReps - 2}', 'muscle': 'Shoulders'},
          {'name': 'Pull-Ups', 'setsReps': '$baseSets x ${baseReps - 4}', 'muscle': 'Lats'},
          {'name': 'Dips', 'setsReps': '$baseSets x $baseReps', 'muscle': 'Chest/Triceps'},
        ];
      case 'full':
        return [
          {'name': 'Squats', 'setsReps': '3 x 12', 'muscle': 'Legs'},
          {'name': 'Push-Ups', 'setsReps': '3 x 15', 'muscle': 'Chest'},
          {'name': 'Dumbbell Rows', 'setsReps': '3 x 12', 'muscle': 'Back'},
          {'name': 'Lunges', 'setsReps': '3 x 10 each', 'muscle': 'Legs'},
          {'name': 'Plank', 'setsReps': '3 x 45s', 'muscle': 'Core'},
        ];
      case 'hiit':
        return [
          {'name': 'Burpees', 'setsReps': '30s x 4', 'muscle': 'Full Body'},
          {'name': 'Mountain Climbers', 'setsReps': '30s x 4', 'muscle': 'Core'},
          {'name': 'Jump Squats', 'setsReps': '30s x 4', 'muscle': 'Legs'},
          {'name': 'High Knees', 'setsReps': '30s x 4', 'muscle': 'Cardio'},
          {'name': 'Box Jumps', 'setsReps': '30s x 4', 'muscle': 'Power'},
        ];
      case 'cardio':
        return [
          {'name': 'Treadmill Run', 'setsReps': '20 min', 'muscle': 'Cardio'},
          {'name': 'Rowing Machine', 'setsReps': '10 min', 'muscle': 'Full Body'},
          {'name': 'Stair Climber', 'setsReps': '10 min', 'muscle': 'Legs'},
        ];
      default:
        return [
          {'name': 'Exercise 1', 'setsReps': '3 x 12', 'muscle': 'Primary'},
          {'name': 'Exercise 2', 'setsReps': '3 x 12', 'muscle': 'Secondary'},
          {'name': 'Exercise 3', 'setsReps': '3 x 12', 'muscle': 'Tertiary'},
        ];
    }
  }

  String _formatGoal(String goal) {
    switch (goal) {
      case 'build_muscle':
        return 'Build Muscle';
      case 'lose_weight':
        return 'Lose Weight';
      case 'increase_strength':
        return 'Get Stronger';
      case 'improve_endurance':
        return 'Build Endurance';
      case 'stay_active':
        return 'Stay Active';
      case 'athletic_performance':
        return 'Athletic Performance';
      default:
        return 'Fitness Journey';
    }
  }

  String _formatLevel(String level) {
    switch (level) {
      case 'beginner':
        return 'Beginner';
      case 'intermediate':
        return 'Intermediate';
      case 'advanced':
        return 'Advanced';
      default:
        return 'Intermediate';
    }
  }
}
