import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import 'pre_auth_quiz_screen.dart';

/// Personalized preview screen that shows value before requiring sign-in
/// This demonstrates what the user will get based on their quiz answers
class PersonalizedPreviewScreen extends ConsumerStatefulWidget {
  const PersonalizedPreviewScreen({super.key});

  @override
  ConsumerState<PersonalizedPreviewScreen> createState() => _PersonalizedPreviewScreenState();
}

class _PersonalizedPreviewScreenState extends ConsumerState<PersonalizedPreviewScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _showContent = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Show loading animation then reveal content
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _showContent = true);
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
                  colors: [Color(0xFFE3F2FD), Color(0xFFF5F5F5), Colors.white],
                ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(isDark, textSecondary),

              // Content
              Expanded(
                child: _showContent
                    ? _buildPreviewContent(isDark, quizData, textPrimary, textSecondary)
                    : _buildLoadingState(isDark, textPrimary),
              ),

              // CTA Button
              if (_showContent) _buildCTAButton(isDark),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.go('/pre-auth-quiz'),
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              color: textSecondary,
              size: 20,
            ),
          ),
          const Spacer(),
          // Progress indicator - 80% complete
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.cyan.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: AppColors.cyan, size: 16),
                const SizedBox(width: 6),
                Text(
                  '80% Complete',
                  style: TextStyle(
                    color: AppColors.cyan,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildLoadingState(bool isDark, Color textPrimary) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Animated AI icon
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (_pulseController.value * 0.1),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: AppColors.cyanGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cyan.withOpacity(0.3 + _pulseController.value * 0.2),
                      blurRadius: 20 + _pulseController.value * 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 24),

        Text(
          'Creating your personalized plan...',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'Analyzing your goals and preferences',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewContent(
    bool isDark,
    PreAuthQuizData quizData,
    Color textPrimary,
    Color textSecondary,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // "Your Plan is Ready" header
          _buildPlanReadyHeader(isDark, textPrimary)
              .animate()
              .fadeIn(delay: 100.ms)
              .slideY(begin: 0.1),

          const SizedBox(height: 24),

          // Summary Card
          _buildSummaryCard(isDark, quizData, textPrimary, textSecondary)
              .animate()
              .fadeIn(delay: 200.ms)
              .slideY(begin: 0.1),

          const SizedBox(height: 20),

          // Sample Week Preview
          _buildWeekPreview(isDark, quizData, textPrimary, textSecondary)
              .animate()
              .fadeIn(delay: 300.ms)
              .slideY(begin: 0.1),

          const SizedBox(height: 20),

          // Features List
          _buildFeaturesList(isDark, textPrimary, textSecondary)
              .animate()
              .fadeIn(delay: 400.ms)
              .slideY(begin: 0.1),

          const SizedBox(height: 100), // Space for CTA button
        ],
      ),
    );
  }

  Widget _buildPlanReadyHeader(bool isDark, Color textPrimary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Success icon
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: AppColors.cyanGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.cyan.withOpacity(0.3),
                blurRadius: 16,
                spreadRadius: 0,
              ),
            ],
          ),
          child: const Icon(
            Icons.check_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),

        const SizedBox(height: 16),

        Text(
          'Your Plan is Ready!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        Text(
          'Based on your answers, we\'ve designed a personalized fitness journey just for you',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    bool isDark,
    PreAuthQuizData quizData,
    Color textPrimary,
    Color textSecondary,
  ) {
    final cardColor = isDark ? AppColors.elevated : Colors.white;
    final borderColor = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    // Format goal name
    String goalDisplay = _formatGoal(quizData.goal ?? 'build_muscle');
    String levelDisplay = _formatLevel(quizData.fitnessLevel ?? 'intermediate');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Goal badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: AppColors.cyanGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.flag_outlined, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  goalDisplay,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                isDark,
                textPrimary,
                textSecondary,
                '${quizData.daysPerWeek ?? 3}',
                'days/week',
                Icons.calendar_today_outlined,
              ),
              Container(
                width: 1,
                height: 40,
                color: borderColor,
              ),
              _buildStatItem(
                isDark,
                textPrimary,
                textSecondary,
                levelDisplay,
                'level',
                Icons.trending_up,
              ),
              Container(
                width: 1,
                height: 40,
                color: borderColor,
              ),
              _buildStatItem(
                isDark,
                textPrimary,
                textSecondary,
                '${quizData.equipment?.length ?? 1}',
                'equipment',
                Icons.fitness_center,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    String value,
    String label,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: AppColors.cyan, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildWeekPreview(
    bool isDark,
    PreAuthQuizData quizData,
    Color textPrimary,
    Color textSecondary,
  ) {
    final cardColor = isDark ? AppColors.elevated : Colors.white;
    final borderColor = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final daysPerWeek = quizData.daysPerWeek ?? 3;

    // Sample workout types based on goal
    final workoutTypes = _getSampleWorkouts(quizData.goal ?? 'build_muscle', daysPerWeek);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month, color: AppColors.cyan, size: 20),
              const SizedBox(width: 8),
              Text(
                'Your Week Preview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Week days
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
              final isWorkoutDay = index < workoutTypes.length;
              final workout = isWorkoutDay ? workoutTypes[index] : null;

              return Column(
                children: [
                  Text(
                    dayNames[index],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isWorkoutDay
                          ? (workout?['color'] as Color).withOpacity(0.15)
                          : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
                      borderRadius: BorderRadius.circular(10),
                      border: isWorkoutDay
                          ? Border.all(color: workout?['color'] as Color, width: 1.5)
                          : null,
                    ),
                    child: Icon(
                      isWorkoutDay
                          ? (workout?['icon'] as IconData)
                          : Icons.remove,
                      color: isWorkoutDay
                          ? (workout?['color'] as Color)
                          : textSecondary.withOpacity(0.3),
                      size: 18,
                    ),
                  ),
                ],
              );
            }),
          ),

          const SizedBox(height: 16),

          // Legend
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: workoutTypes.toSet().map((workout) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: workout['color'] as Color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    workout['name'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      color: textSecondary,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getSampleWorkouts(String goal, int daysPerWeek) {
    final workouts = <Map<String, dynamic>>[];

    switch (goal) {
      case 'build_muscle':
      case 'increase_strength':
        final types = [
          {'name': 'Push', 'icon': Icons.fitness_center, 'color': AppColors.purple},
          {'name': 'Pull', 'icon': Icons.fitness_center, 'color': AppColors.electricBlue},
          {'name': 'Legs', 'icon': Icons.directions_walk, 'color': AppColors.teal},
          {'name': 'Upper', 'icon': Icons.fitness_center, 'color': AppColors.purple},
          {'name': 'Lower', 'icon': Icons.directions_walk, 'color': AppColors.teal},
          {'name': 'Full Body', 'icon': Icons.accessibility_new, 'color': AppColors.orange},
          {'name': 'Arms', 'icon': Icons.fitness_center, 'color': AppColors.coral},
        ];
        for (int i = 0; i < daysPerWeek && i < types.length; i++) {
          workouts.add(types[i]);
        }
        break;

      case 'lose_weight':
        final types = [
          {'name': 'HIIT', 'icon': Icons.flash_on, 'color': AppColors.coral},
          {'name': 'Cardio', 'icon': Icons.directions_run, 'color': AppColors.orange},
          {'name': 'Strength', 'icon': Icons.fitness_center, 'color': AppColors.purple},
          {'name': 'HIIT', 'icon': Icons.flash_on, 'color': AppColors.coral},
          {'name': 'Active Recovery', 'icon': Icons.self_improvement, 'color': AppColors.teal},
          {'name': 'Full Body', 'icon': Icons.accessibility_new, 'color': AppColors.purple},
          {'name': 'Cardio', 'icon': Icons.directions_run, 'color': AppColors.orange},
        ];
        for (int i = 0; i < daysPerWeek && i < types.length; i++) {
          workouts.add(types[i]);
        }
        break;

      case 'improve_endurance':
        final types = [
          {'name': 'Cardio', 'icon': Icons.directions_run, 'color': AppColors.orange},
          {'name': 'Intervals', 'icon': Icons.timer, 'color': AppColors.coral},
          {'name': 'Endurance', 'icon': Icons.directions_bike, 'color': AppColors.teal},
          {'name': 'Tempo', 'icon': Icons.speed, 'color': AppColors.electricBlue},
          {'name': 'Long Run', 'icon': Icons.directions_run, 'color': AppColors.orange},
          {'name': 'Recovery', 'icon': Icons.self_improvement, 'color': AppColors.success},
          {'name': 'Cross Train', 'icon': Icons.pool, 'color': AppColors.purple},
        ];
        for (int i = 0; i < daysPerWeek && i < types.length; i++) {
          workouts.add(types[i]);
        }
        break;

      default:
        final types = [
          {'name': 'Full Body', 'icon': Icons.accessibility_new, 'color': AppColors.purple},
          {'name': 'Cardio', 'icon': Icons.directions_run, 'color': AppColors.orange},
          {'name': 'Strength', 'icon': Icons.fitness_center, 'color': AppColors.electricBlue},
          {'name': 'Flexibility', 'icon': Icons.self_improvement, 'color': AppColors.teal},
          {'name': 'HIIT', 'icon': Icons.flash_on, 'color': AppColors.coral},
          {'name': 'Active', 'icon': Icons.directions_walk, 'color': AppColors.success},
          {'name': 'Core', 'icon': Icons.circle_outlined, 'color': AppColors.purple},
        ];
        for (int i = 0; i < daysPerWeek && i < types.length; i++) {
          workouts.add(types[i]);
        }
    }

    return workouts;
  }

  Widget _buildFeaturesList(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    final features = [
      {
        'icon': Icons.auto_awesome,
        'title': 'AI-Powered Coaching',
        'description': 'Personalized workouts that adapt to your progress',
        'color': AppColors.cyan,
      },
      {
        'icon': Icons.play_circle_outline,
        'title': '1,700+ Exercise Videos',
        'description': 'HD demos for perfect form every time',
        'color': AppColors.purple,
      },
      {
        'icon': Icons.trending_up,
        'title': 'Smart Progression',
        'description': 'Automatic adjustments as you get stronger',
        'color': AppColors.success,
      },
      {
        'icon': Icons.restaurant_menu,
        'title': 'Nutrition Guidance',
        'description': 'Meal suggestions aligned with your goals',
        'color': AppColors.orange,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "What's Included",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),

        const SizedBox(height: 12),

        ...features.asMap().entries.map((entry) {
          final index = entry.key;
          final feature = entry.value;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (feature['color'] as Color).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    feature['icon'] as IconData,
                    color: feature['color'] as Color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature['title'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        feature['description'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 20,
                ),
              ],
            ),
          ).animate(delay: (index * 80).ms).fadeIn().slideX(begin: 0.05);
        }),
      ],
    );
  }

  Widget _buildCTAButton(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Main CTA
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                context.go('/sign-in');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: AppColors.cyan.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Save My Plan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Subtext
          Text(
            'Free account • No credit card required',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1);
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
