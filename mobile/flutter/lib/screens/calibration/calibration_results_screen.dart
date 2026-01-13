import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/context_logging_service.dart';
import '../../widgets/lottie_animations.dart';
import 'calibration_workout_screen.dart';
import 'widgets/ai_analysis_card.dart';
import 'widgets/exercise_breakdown_card.dart';
import 'widgets/suggested_adjustments_card.dart';
import 'widgets/calibration_action_buttons.dart';
import '../../data/models/calibration.dart';

/// Calibration Results Screen
/// Shows the user their calibration results and suggested fitness level
/// with AI analysis, exercise breakdown, and suggested adjustments.
class CalibrationResultsScreen extends ConsumerStatefulWidget {
  final bool fromOnboarding;
  final String calibrationId;
  final List<CalibrationExercise> exercises;
  final Map<String, dynamic> result;
  final int durationSeconds;

  const CalibrationResultsScreen({
    super.key,
    required this.fromOnboarding,
    required this.calibrationId,
    required this.exercises,
    required this.result,
    required this.durationSeconds,
  });

  @override
  ConsumerState<CalibrationResultsScreen> createState() => _CalibrationResultsScreenState();
}

class _CalibrationResultsScreenState extends ConsumerState<CalibrationResultsScreen> {
  bool _isProcessing = false;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    // Play confetti on load for successful calibration
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _confettiController.play();
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _acceptAdjustments() {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    HapticFeedback.mediumImpact();

    // Log acceptance
    ref.read(contextLoggingServiceProvider).logCalibrationAdjustmentsAccepted(
      widget.result['suggested_adjustments'] as Map<String, dynamic>,
    );

    // Show success toast
    _showSuccessToast('Settings updated successfully!');

    // Navigate based on onboarding flow
    // Correct flow: Coach → Paywall → Calibration → Workout Loading → Home
    if (widget.fromOnboarding) {
      context.go('/workout-loading');
    } else {
      context.go('/home');
    }
  }

  void _declineAdjustments() {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    HapticFeedback.lightImpact();

    // Log decline
    ref.read(contextLoggingServiceProvider).logCalibrationAdjustmentsDeclined();

    // Show info toast
    _showInfoToast('Keeping your original settings');

    // Navigate based on onboarding flow
    // Correct flow: Coach → Paywall → Calibration → Workout Loading → Home
    if (widget.fromOnboarding) {
      context.go('/workout-loading');
    } else {
      context.go('/home');
    }
  }

  void _showSuccessToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showInfoToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.cyan,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Build CalibrationAnalysis from result data
  CalibrationAnalysis _buildAnalysis() {
    final level = widget.result['level'] as String? ?? 'intermediate';
    final adjustments = widget.result['suggested_adjustments'] as Map<String, dynamic>? ?? {};

    // Build exercise results from calibration exercises
    final exerciseResults = widget.exercises.map((exercise) {
      String performanceIndicator = 'matched';
      final status = adjustments[_getAdjustmentKey(exercise.name)] as String?;
      if (status == 'good') {
        performanceIndicator = 'exceeded';
      } else if (status == 'focus' || status == 'needs_work') {
        performanceIndicator = 'below';
      }

      // For timed exercises (like plank), show time instead of reps
      int? repsToShow = exercise.repsCompleted;
      String aiComment = _getExerciseComment(exercise, status);

      // If this is a timed exercise with no reps, show the time held
      if (exercise.isTimed && exercise.secondsHeld != null && exercise.secondsHeld! > 0) {
        final minutes = exercise.secondsHeld! ~/ 60;
        final seconds = exercise.secondsHeld! % 60;
        final timeStr = minutes > 0
            ? '$minutes:${seconds.toString().padLeft(2, '0')}'
            : '${seconds}s';
        aiComment = 'Held for $timeStr. ${_getExerciseComment(exercise, status)}';
        // Don't show reps for pure timed exercises
        repsToShow = null;
      }

      return CalibrationExerciseResult(
        exerciseName: exercise.name,
        repsCompleted: repsToShow,
        setsCompleted: null, // Don't show sets for calibration (it's implicit)
        aiComment: aiComment,
        performanceIndicator: performanceIndicator,
      );
    }).toList();

    return CalibrationAnalysis(
      analysisSummary: _buildAnalysisSummary(level, adjustments),
      confidenceLevel: 0.85,
      isConfident: true,
      statedFitnessLevel: widget.result['stated_level'] as String? ?? level,
      detectedFitnessLevel: level,
      levelsMatch: (widget.result['stated_level'] as String?) == level,
      exerciseResults: exerciseResults,
      durationMinutes: widget.durationSeconds ~/ 60,
    );
  }

  String _getAdjustmentKey(String exerciseName) {
    if (exerciseName.toLowerCase().contains('push')) return 'push_strength';
    if (exerciseName.toLowerCase().contains('squat')) return 'leg_endurance';
    if (exerciseName.toLowerCase().contains('plank')) return 'core_stability';
    return exerciseName.toLowerCase().replaceAll(' ', '_');
  }

  String _getExerciseComment(CalibrationExercise exercise, String? status) {
    if (status == 'good') {
      return 'Great performance! This shows strong ability in this movement pattern.';
    } else if (status == 'focus') {
      return 'This is an area we can work on. Your workouts will help build strength here.';
    }
    return 'Solid performance. Right in line with expectations.';
  }

  String _buildAnalysisSummary(String level, Map<String, dynamic> adjustments) {
    final goodAreas = adjustments.entries.where((e) => e.value == 'good').length;
    final focusAreas = adjustments.entries.where((e) => e.value == 'focus').length;

    if (goodAreas > focusAreas) {
      return 'Excellent calibration session! Your performance shows strong overall fitness with particular strengths in multiple areas. Your workouts will be tailored to challenge you appropriately while continuing to build on your foundation.';
    } else if (focusAreas > goodAreas) {
      return 'Good calibration session! We\'ve identified some areas where we can help you improve. Your workouts will be designed to build strength progressively while focusing on proper form and technique.';
    }
    return 'Great calibration session! Your results show a balanced fitness profile. We\'ll design workouts that challenge you appropriately while helping you continue to progress.';
  }

  /// Build CalibrationSuggestedAdjustments from result data
  CalibrationSuggestedAdjustments _buildSuggestedAdjustments() {
    final level = widget.result['level'] as String? ?? 'intermediate';
    final statedLevel = widget.result['stated_level'] as String?;
    final adjustments = widget.result['suggested_adjustments'] as Map<String, dynamic>? ?? {};

    final shouldChangeFitnessLevel = statedLevel != null && statedLevel != level;

    // Determine weight multiplier based on performance
    final focusAreas = adjustments.entries.where((e) => e.value == 'focus').length;
    final goodAreas = adjustments.entries.where((e) => e.value == 'good').length;

    double? weightMultiplier;
    String? weightDescription;

    if (goodAreas > focusAreas && goodAreas >= 2) {
      weightMultiplier = 1.15;
      weightDescription = 'Your strong performance suggests you can handle more challenge';
    } else if (focusAreas > goodAreas && focusAreas >= 2) {
      weightMultiplier = 0.90;
      weightDescription = 'Starting with lighter weights will help build proper form';
    }

    return CalibrationSuggestedAdjustments(
      suggestedFitnessLevel: level,
      currentFitnessLevel: statedLevel,
      shouldChangeFitnessLevel: shouldChangeFitnessLevel,
      weightMultiplier: weightMultiplier,
      weightAdjustmentDescription: weightDescription,
      messageToUser: _buildMessageToUser(level, shouldChangeFitnessLevel, weightMultiplier),
      detailedRecommendations: _buildDetailedRecommendations(adjustments),
    );
  }

  String _buildMessageToUser(String level, bool levelChange, double? weightMultiplier) {
    if (levelChange && weightMultiplier != null) {
      return 'Based on your calibration, we recommend adjusting your fitness level and starting weights for optimal progress. These changes will help ensure your workouts are challenging but achievable.';
    } else if (levelChange) {
      return 'Your performance suggests a different fitness level than you selected. Updating this will help us create workouts that match your current abilities.';
    } else if (weightMultiplier != null) {
      return 'Your current fitness level is a great fit! We\'ll adjust your starting weights slightly based on your calibration performance.';
    }
    return 'Great news! Your current settings are well-matched to your calibration performance. We\'ll use these to create personalized workouts for you.';
  }

  List<String> _buildDetailedRecommendations(Map<String, dynamic> adjustments) {
    final recommendations = <String>[];

    if (adjustments['push_strength'] == 'good') {
      recommendations.add('Upper body pushing strength is excellent - we\'ll include challenging push exercises');
    } else if (adjustments['push_strength'] == 'focus') {
      recommendations.add('We\'ll progressively build your pushing strength with appropriate progressions');
    }

    if (adjustments['leg_endurance'] == 'good') {
      recommendations.add('Lower body endurance is strong - expect leg workouts that challenge your capacity');
    } else if (adjustments['leg_endurance'] == 'focus') {
      recommendations.add('We\'ll build your leg endurance with structured progressive training');
    }

    if (adjustments['core_stability'] == 'good') {
      recommendations.add('Core stability is excellent - we\'ll incorporate advanced core work');
    } else if (adjustments['core_stability'] == 'focus') {
      recommendations.add('Core exercises will be a focus to build a strong foundation');
    }

    return recommendations;
  }

  String _getLevelDisplayName(String level) {
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

  Color _getLevelColor(String level) {
    switch (level) {
      case 'beginner':
        return AppColors.success;
      case 'intermediate':
        return AppColors.cyan;
      case 'advanced':
        return AppColors.purple;
      default:
        return AppColors.cyan;
    }
  }

  String _getLevelDescription(String level) {
    switch (level) {
      case 'beginner':
        return 'We\'ll start with foundational exercises and gradually build your strength. Focus on form and consistency.';
      case 'intermediate':
        return 'You have a solid base. We\'ll challenge you with progressive overload and varied exercise selection.';
      case 'advanced':
        return 'You\'re ready for intense training. We\'ll push your limits with advanced techniques and periodization.';
      default:
        return 'We\'ll customize your workouts based on your results.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;

    final level = widget.result['level'] as String? ?? 'intermediate';
    final levelColor = _getLevelColor(level);

    // Build analysis and adjustments models
    final analysis = _buildAnalysis();
    final suggestedAdjustments = _buildSuggestedAdjustments();

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // App bar
                SliverAppBar(
                  backgroundColor: backgroundColor,
                  surfaceTintColor: Colors.transparent,
                  pinned: true,
                  automaticallyImplyLeading: false,
                  title: Text(
                    'Calibration Results',
                    style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  centerTitle: true,
                  actions: [
                    Container(
                      margin: const EdgeInsets.only(right: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, color: AppColors.success, size: 16),
                          const SizedBox(width: 6),
                          const Text(
                            'Complete',
                            style: TextStyle(
                              color: AppColors.success,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Content
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Header section with success animation
                      _buildHeaderSection(
                        isDark,
                        textPrimary,
                        textSecondary,
                        textMuted,
                        cyan,
                        purple,
                        levelColor,
                        level,
                      ),

                      const SizedBox(height: 24),

                      // AI Analysis card
                      AIAnalysisCard(
                        analysis: analysis,
                        isDark: isDark,
                      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05),

                      const SizedBox(height: 20),

                      // Exercise breakdown (collapsible)
                      ExerciseBreakdownCard(
                        exerciseResults: analysis.exerciseResults,
                        isDark: isDark,
                      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.05),

                      const SizedBox(height: 20),

                      // Suggested adjustments card
                      SuggestedAdjustmentsCard(
                        adjustments: suggestedAdjustments,
                        isDark: isDark,
                      ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.05),

                      const SizedBox(height: 24),

                      // Action buttons
                      CalibrationActionButtons(
                        hasChanges: suggestedAdjustments.hasChanges,
                        isProcessing: _isProcessing,
                        onAccept: _acceptAdjustments,
                        onDecline: _declineAdjustments,
                        isDark: isDark,
                      ),

                      const SizedBox(height: 20),

                      // Additional info
                      _buildAdditionalInfo(isDark, textSecondary, textMuted),

                      const SizedBox(height: 40),
                    ]),
                  ),
                ),
              ],
            ),
          ),

          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: [
                cyan,
                purple,
                AppColors.success,
                AppColors.orange,
              ],
              numberOfParticles: 30,
              maxBlastForce: 20,
              minBlastForce: 8,
              emissionFrequency: 0.05,
              gravity: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
    Color cyan,
    Color purple,
    Color levelColor,
    String level,
  ) {
    final durationMinutes = widget.durationSeconds ~/ 60;
    final durationSeconds = widget.durationSeconds % 60;

    return Column(
      children: [
        // Success animation
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                cyan.withValues(alpha: 0.2),
                purple.withValues(alpha: 0.2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: LottieSuccess(
              size: 100,
            ),
          ),
        ).animate().scale(
              begin: const Offset(0.5, 0.5),
              end: const Offset(1.0, 1.0),
              duration: 500.ms,
              curve: Curves.elasticOut,
            ),

        const SizedBox(height: 20),

        // Title
        Text(
          'Calibration Complete!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 200.ms),

        const SizedBox(height: 8),

        // Duration badge
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: cyan.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer_outlined,
                size: 16,
                color: cyan,
              ),
              const SizedBox(width: 6),
              Text(
                'Completed in $durationMinutes:${durationSeconds.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 13,
                  color: cyan,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 250.ms),

        const SizedBox(height: 16),

        // Level badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: levelColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: levelColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.emoji_events_outlined,
                color: levelColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Level',
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                  Text(
                    _getLevelDisplayName(level),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: levelColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.95, 0.95)),
      ],
    );
  }

  Widget _buildAdditionalInfo(bool isDark, Color textSecondary, Color textMuted) {
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    return Column(
      children: [
        // Re-test anytime info
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.refresh,
              size: 16,
              color: textMuted,
            ),
            const SizedBox(width: 8),
            Text(
              'You can re-test anytime from Settings',
              style: TextStyle(
                fontSize: 13,
                color: textMuted,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Link to view baselines
        TextButton.icon(
          onPressed: () {
            HapticFeedback.lightImpact();
            context.push('/settings/training/baselines');
          },
          icon: Icon(
            Icons.bar_chart,
            size: 18,
            color: cyan,
          ),
          label: Text(
            'View detailed baselines',
            style: TextStyle(
              fontSize: 13,
              color: cyan,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _buildResultRow({
    required bool isDark,
    required String label,
    required String value,
    required String status,
  }) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final isGood = status == 'good';

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: textPrimary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: (isGood ? AppColors.success : AppColors.orange).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isGood ? Icons.check_circle : Icons.trending_up,
                size: 14,
                color: isGood ? AppColors.success : AppColors.orange,
              ),
              const SizedBox(width: 4),
              Text(
                isGood ? 'Good' : 'Focus',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isGood ? AppColors.success : AppColors.orange,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
