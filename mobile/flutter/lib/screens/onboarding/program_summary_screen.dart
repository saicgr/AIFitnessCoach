import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import 'pre_auth_quiz_screen.dart';

/// Program summary screen shown after workout generation completes.
///
/// Displays a 2x2 grid of user selections, value props, and
/// action buttons to start training or regenerate.
class ProgramSummaryScreen extends ConsumerWidget {
  const ProgramSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary = isDark ? const Color(0xFFD4D4D8) : const Color(0xFF52525B);
    final quizData = ref.watch(preAuthQuizProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    children: [
                      const SizedBox(height: 24),

                      // Success icon
                      Center(
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.success.withValues(alpha: 0.2),
                                AppColors.success.withValues(alpha: 0.08),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: AppColors.success,
                            size: 40,
                          ),
                        ),
                      ).animate().fadeIn(delay: 100.ms).scale(begin: const Offset(0.8, 0.8)),

                      const SizedBox(height: 20),

                      // Title
                      Center(
                        child: Text(
                          'Your Program is Ready',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                      ).animate().fadeIn(delay: 200.ms),

                      const SizedBox(height: 6),

                      Center(
                        child: Text(
                          'Personalized for your goals and equipment',
                          style: TextStyle(
                            fontSize: 14,
                            color: textSecondary,
                          ),
                        ),
                      ).animate().fadeIn(delay: 250.ms),

                      const SizedBox(height: 28),

                      // 2x2 summary grid
                      _buildSummaryGrid(context, isDark, textPrimary, textSecondary, quizData),

                      const SizedBox(height: 28),

                      // Value props
                      _buildValueProps(isDark, textPrimary, textSecondary),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom action buttons
            _buildActionButtons(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryGrid(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    PreAuthQuizData quizData,
  ) {
    final goalLabel = _formatGoal(quizData.primaryGoal ?? quizData.goal);
    final equipmentLabel = _formatEquipment(quizData.equipment);
    final levelLabel = _formatLevel(quizData.fitnessLevel);
    final daysLabel = '${quizData.daysPerWeek ?? 4}/week';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryTile(
                icon: Icons.flag_rounded,
                iconColor: AppColors.orange,
                label: 'Goal',
                value: goalLabel,
                isDark: isDark,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                delay: 300.ms,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryTile(
                icon: Icons.fitness_center_rounded,
                iconColor: isDark ? AppColors.cyan : AppColorsLight.cyan,
                label: 'Equipment',
                value: equipmentLabel,
                isDark: isDark,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                delay: 350.ms,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryTile(
                icon: Icons.trending_up_rounded,
                iconColor: AppColors.green,
                label: 'Level',
                value: levelLabel,
                isDark: isDark,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                delay: 400.ms,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryTile(
                icon: Icons.calendar_today_rounded,
                iconColor: const Color(0xFFA855F7),
                label: 'Workouts',
                value: daysLabel,
                isDark: isDark,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                delay: 450.ms,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Duration delay,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.glassSurface : AppColorsLight.glassSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.glassBorder : AppColorsLight.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ).animate().fadeIn(delay: delay).slideY(begin: 0.08);
  }

  Widget _buildValueProps(bool isDark, Color textPrimary, Color textSecondary) {
    final props = [
      (
        icon: Icons.smart_toy_rounded,
        title: 'AI Coach',
        desc: 'Adapts workouts based on your progress',
      ),
      (
        icon: Icons.shield_rounded,
        title: 'Injury Awareness',
        desc: 'Avoids exercises that stress your limitations',
      ),
      (
        icon: Icons.restaurant_rounded,
        title: 'Nutrition Integration',
        desc: 'Macros and meals aligned to your training',
      ),
      (
        icon: Icons.trending_up_rounded,
        title: 'Progressive Overload',
        desc: 'Automatically increases challenge over time',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "What's included",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ).animate().fadeIn(delay: 500.ms),
        const SizedBox(height: 12),
        ...props.asMap().entries.map((entry) {
          final index = entry.key;
          final prop = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(prop.icon, color: AppColors.orange, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prop.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        prop.desc,
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: (550 + index * 50).ms).slideX(begin: -0.03);
        }),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.glassBorder : AppColorsLight.cardBorder,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary: Start Training
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                context.go('/home');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                elevation: 2,
                shadowColor: AppColors.orange.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow_rounded, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Start Training',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Secondary: Generate New Program
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                // Navigate to workout generation screen to regenerate
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const _RegenerateWrapper(),
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh_rounded, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Generate New Program',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatGoal(String? goal) {
    if (goal == null) return 'General Fitness';
    switch (goal) {
      case 'muscle_hypertrophy':
        return 'Build Muscle';
      case 'muscle_strength':
        return 'Get Stronger';
      case 'strength_hypertrophy':
        return 'Strength + Size';
      case 'lose_weight':
      case 'weight_loss':
        return 'Lose Weight';
      case 'build_muscle':
        return 'Build Muscle';
      case 'stay_fit':
        return 'Stay Fit';
      case 'improve_endurance':
        return 'Endurance';
      default:
        return goal.replaceAll('_', ' ').split(' ').map(
          (w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w,
        ).join(' ');
    }
  }

  String _formatEquipment(List<String>? equipment) {
    if (equipment == null || equipment.isEmpty) return 'Bodyweight';
    if (equipment.contains('full_gym')) return 'Full Gym';
    if (equipment.length <= 2) {
      return equipment.map((e) => e.replaceAll('_', ' ')).map(
        (w) => w.split(' ').map((s) => s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : s).join(' '),
      ).join(', ');
    }
    return '${equipment.length} items';
  }

  String _formatLevel(String? level) {
    if (level == null) return 'Intermediate';
    switch (level) {
      case 'beginner':
        return 'Beginner';
      case 'intermediate':
        return 'Intermediate';
      case 'advanced':
        return 'Advanced';
      default:
        return level[0].toUpperCase() + level.substring(1);
    }
  }
}

/// Wrapper that navigates to WorkoutGenerationScreen for regeneration.
/// This avoids a circular import by using go_router.
class _RegenerateWrapper extends StatelessWidget {
  const _RegenerateWrapper();

  @override
  Widget build(BuildContext context) {
    // Navigate to generation screen via router
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.go('/workout-generation');
    });
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
