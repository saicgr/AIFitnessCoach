import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/posthog_service.dart';
import '../../l10n/generated/app_localizations.dart';
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

    final l10n = AppLocalizations.of(context)!;
    return _withConfetti(Scaffold(
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
                              begin: AlignmentDirectional.topStart,
                              end: AlignmentDirectional.bottomEnd,
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
                          l10n.programSummaryYourProgramIsReady,
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
                          l10n.programSummaryPersonalizedForYourGoals,
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
                      _buildValueProps(context, isDark, textPrimary, textSecondary),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom action buttons
            _buildActionButtons(context, isDark, ref),
          ],
        ),
      ),
    ));
  }

  Widget _buildSummaryGrid(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    PreAuthQuizData quizData,
  ) {
    final goalLabel = _formatGoal(context, quizData.primaryGoal ?? quizData.goal);
    final equipmentLabel = _formatEquipment(context, quizData.equipment);
    final levelLabel = _formatLevel(context, quizData.fitnessLevel);
    final daysLabel = '${quizData.daysPerWeek ?? 4}/week';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryTile(
                icon: Icons.flag_rounded,
                iconColor: AppColors.orange,
                label: AppLocalizations.of(context)!.challengeCreateFieldGoal,
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
                label: AppLocalizations.of(context)!.programSummaryEquipment,
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
                label: AppLocalizations.of(context)!.programSummaryLevel,
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
                label: AppLocalizations.of(context)!.navWorkouts,
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

  Widget _buildValueProps(BuildContext context, bool isDark, Color textPrimary, Color textSecondary) {
    final l10n = AppLocalizations.of(context)!;
    final props = [
      (
        icon: Icons.smart_toy_rounded,
        title: l10n.authIntroAiCoach,
        desc: l10n.programSummaryAdaptsWorkoutsBasedOn,
      ),
      (
        icon: Icons.shield_rounded,
        title: l10n.programSummaryInjuryAwareness,
        desc: l10n.programSummaryAvoidsExercisesThatStress,
      ),
      (
        icon: Icons.restaurant_rounded,
        title: l10n.programSummaryNutritionIntegration,
        desc: l10n.programSummaryMacrosAndMealsAligned,
      ),
      (
        icon: Icons.trending_up_rounded,
        title: l10n.programSummaryProgressiveOverload,
        desc: l10n.programSummaryAutomaticallyIncreasesChalle,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.programSummaryWhatSIncluded,
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

  Widget _buildActionButtons(BuildContext context, bool isDark, WidgetRef ref) {
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
                // Track program confirmed
                ref.read(posthogServiceProvider).capture(
                  eventName: 'onboarding_program_confirmed',
                );
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_arrow_rounded, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.programSummaryStartTraining,
                    style: const TextStyle(
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.refresh_rounded, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    AppLocalizations.of(context)!.programSummaryGenerateNewProgram,
                    style: const TextStyle(
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

  /// Overlays an auto-playing confetti burst on the plan-reveal screen
  /// (Calorii-audit P6.2). The single wrapping paren keeps the change balanced.
  Widget _withConfetti(Widget child) {
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        const IgnorePointer(child: _PlanRevealConfetti()),
      ],
    );
  }

  String _formatGoal(BuildContext context, String? goal) {
    final l10n = AppLocalizations.of(context)!;
    if (goal == null) return l10n.programSummaryGeneralFitness;
    switch (goal) {
      case 'muscle_hypertrophy':
      case 'build_muscle':
        return l10n.programSummaryBuildMuscle;
      case 'muscle_strength':
        return l10n.programSummaryGetStronger;
      case 'strength_hypertrophy':
        return l10n.programSummaryStrengthSize;
      case 'lose_weight':
      case 'weight_loss':
        return l10n.programSummaryLoseWeight;
      case 'stay_fit':
        return l10n.programSummaryStayFit;
      case 'improve_endurance':
        return l10n.programSummaryEndurance;
      default:
        return goal.replaceAll('_', ' ').split(' ').map(
          (w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w,
        ).join(' ');
    }
  }

  String _formatEquipment(BuildContext context, List<String>? equipment) {
    final l10n = AppLocalizations.of(context)!;
    if (equipment == null || equipment.isEmpty) return l10n.programSummaryBodyweight;
    if (equipment.contains('full_gym')) return l10n.programSummaryFullGym;
    if (equipment.length <= 2) {
      return equipment.map((e) => e.replaceAll('_', ' ')).map(
        (w) => w.split(' ').map((s) => s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : s).join(' '),
      ).join(', ');
    }
    return l10n.programSummaryNItems(equipment.length);
  }

  String _formatLevel(BuildContext context, String? level) {
    final l10n = AppLocalizations.of(context)!;
    if (level == null) return l10n.programSummaryIntermediateLabel;
    switch (level) {
      case 'beginner':
        return l10n.programSummaryBeginnerLabel;
      case 'intermediate':
        return l10n.programSummaryIntermediateLabel;
      case 'advanced':
        return l10n.programSummaryAdvancedLabel;
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

/// Auto-playing confetti burst for the plan-reveal moment.
class _PlanRevealConfetti extends StatefulWidget {
  const _PlanRevealConfetti();

  @override
  State<_PlanRevealConfetti> createState() => _PlanRevealConfettiState();
}

class _PlanRevealConfettiState extends State<_PlanRevealConfetti> {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _confetti.play();
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConfettiWidget(
        confettiController: _confetti,
        blastDirectionality: BlastDirectionality.explosive,
        emissionFrequency: 0.05,
        numberOfParticles: 22,
        maxBlastForce: 18,
        minBlastForce: 8,
        gravity: 0.25,
        shouldLoop: false,
        colors: const [
          Color(0xFF22C55E),
          Color(0xFF3B82F6),
          Color(0xFFF59E0B),
          Color(0xFFEC4899),
          Color(0xFF8B5CF6),
        ],
      ),
    );
  }
}
