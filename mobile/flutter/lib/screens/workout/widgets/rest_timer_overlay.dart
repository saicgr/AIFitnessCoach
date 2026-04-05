/// Rest timer overlay widget
///
/// Displays the rest countdown between sets or exercises.
/// Now includes smart weight suggestions based on RPE/RIR!
/// Also includes AI-powered rest time suggestions.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/weight_suggestion_service.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/rest_suggestion.dart';
import '../../../data/models/coach_persona.dart';
import '../../../widgets/coach_avatar.dart';
import 'rest_suggestion_card.dart';

part 'rest_timer_overlay_ui.dart';


/// Rest timer overlay displayed between sets or exercises
class RestTimerOverlay extends StatelessWidget {
  /// Current rest seconds remaining
  final int restSecondsRemaining;

  /// Initial rest duration for progress calculation
  final int initialRestDuration;

  /// Current rest encouragement message
  final String restMessage;

  /// Current exercise
  final WorkoutExercise currentExercise;

  /// Number of completed sets for current exercise
  final int completedSetsCount;

  /// Total sets for current exercise
  final int totalSets;

  /// Next exercise (null if last exercise)
  final WorkoutExercise? nextExercise;

  /// Whether this is rest between exercises (not sets)
  final bool isRestBetweenExercises;

  /// Callback to skip rest
  final VoidCallback onSkipRest;

  /// Callback to log 1RM
  final VoidCallback? onLog1RM;

  /// Weight suggestion for the next set (optional)
  final WeightSuggestion? weightSuggestion;

  /// Whether AI is currently fetching a weight suggestion
  final bool isLoadingWeightSuggestion;

  /// Callback when user accepts weight suggestion
  final ValueChanged<double>? onAcceptWeightSuggestion;

  /// Callback when user dismisses weight suggestion
  final VoidCallback? onDismissWeightSuggestion;

  /// Rest time suggestion from AI (optional)
  final RestSuggestion? restSuggestion;

  /// Whether AI is currently fetching a rest suggestion
  final bool isLoadingRestSuggestion;

  /// Callback when user accepts rest suggestion (updates timer)
  final ValueChanged<int>? onAcceptRestSuggestion;

  /// Callback when user dismisses rest suggestion
  final VoidCallback? onDismissRestSuggestion;

  /// Current RPE value (optional)
  final int? currentRpe;

  /// Current RIR value (optional)
  final int? currentRir;

  /// Callback when RPE changes
  final ValueChanged<int?>? onRpeChanged;

  /// Callback when RIR changes
  final ValueChanged<int?>? onRirChanged;

  /// Last set performance data for display
  final int? lastSetReps;
  final int? lastSetTargetReps;
  final double? lastSetWeight;

  /// Callback when user wants to ask AI Coach a question
  final VoidCallback? onAskAICoach;

  /// Coach persona for personalized "Ask Coach" button
  final CoachPersona? coachPersona;

  const RestTimerOverlay({
    super.key,
    required this.restSecondsRemaining,
    required this.initialRestDuration,
    required this.restMessage,
    required this.currentExercise,
    required this.completedSetsCount,
    required this.totalSets,
    this.nextExercise,
    this.isRestBetweenExercises = false,
    required this.onSkipRest,
    this.onLog1RM,
    this.weightSuggestion,
    this.isLoadingWeightSuggestion = false,
    this.onAcceptWeightSuggestion,
    this.onDismissWeightSuggestion,
    this.restSuggestion,
    this.isLoadingRestSuggestion = false,
    this.onAcceptRestSuggestion,
    this.onDismissRestSuggestion,
    this.currentRpe,
    this.currentRir,
    this.onRpeChanged,
    this.onRirChanged,
    this.lastSetReps,
    this.lastSetTargetReps,
    this.lastSetWeight,
    this.onAskAICoach,
    this.coachPersona,
  });

  /// Rest progress (1.0 = full, 0.0 = done)
  double get restProgress =>
      initialRestDuration > 0 ? restSecondsRemaining / initialRestDuration : 0.0;

  /// Whether this is rest between sets (not exercises)
  bool get isRestBetweenSets =>
      !isRestBetweenExercises && completedSetsCount < totalSets;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? AppColors.pureBlack.withOpacity(0.92)
        : AppColorsLight.surface.withOpacity(0.98);
    final cardBg =
        isDark ? AppColors.elevated.withOpacity(0.8) : AppColorsLight.elevated;
    final textColor = isDark ? Colors.white : AppColorsLight.textPrimary;
    final subtitleColor =
        isDark ? Colors.white70 : AppColorsLight.textSecondary;

    // Check if screen is compact (small height)
    final screenHeight = MediaQuery.of(context).size.height;
    final isCompactScreen = screenHeight < 750;

    return Container(
      color: bgColor,
      child: SafeArea(
        child: Column(
          children: [
            // Fixed header: REST label, timer, progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  SizedBox(height: isCompactScreen ? 8 : 16),
                  _buildRestLabel(isDark),
                  const SizedBox(height: 8),
                  _buildTimer(textColor),
                  const SizedBox(height: 12),
                  _buildProgressBar(isDark),
                  SizedBox(height: isCompactScreen ? 12 : 20),
                ],
              ),
            ),

            // Scrollable content area
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: isCompactScreen ? 4 : 8,
                ),
                child: Column(
                  children: [
                    // Rest suggestion section (loading or card)
                    if (isRestBetweenSets) ...[
                      if (isLoadingRestSuggestion)
                        const RestSuggestionLoadingCard()
                      else if (restSuggestion != null)
                        RestSuggestionCard(
                          suggestion: restSuggestion!,
                          onAcceptSuggestion: (seconds) {
                            HapticFeedback.mediumImpact();
                            onAcceptRestSuggestion?.call(seconds);
                          },
                          onQuickRest: (seconds) {
                            HapticFeedback.mediumImpact();
                            onAcceptRestSuggestion?.call(seconds);
                          },
                          onDismiss: onDismissRestSuggestion,
                          isCompact: isCompactScreen,
                        ),
                    ],

                    // Spacing between rest and weight suggestions
                    if (isRestBetweenSets && (restSuggestion != null || isLoadingRestSuggestion))
                      SizedBox(height: isCompactScreen ? 10 : 16),

                    // Weight suggestion section (loading or card)
                    if (isRestBetweenSets) ...[
                      if (isLoadingWeightSuggestion)
                        _buildLoadingWeightSuggestion(cardBg, textColor, subtitleColor, isDark)
                      else if (weightSuggestion != null)
                        _buildWeightSuggestionCard(cardBg, textColor, subtitleColor, isDark, isCompactScreen),
                    ],

                    // RPE/RIR compact input section
                    if (onRpeChanged != null) ...[
                      SizedBox(height: isCompactScreen ? 10 : 16),
                      _buildRpeRirSection(context, cardBg, textColor, subtitleColor, isDark, isCompactScreen),
                    ],

                    // Coach Review section
                    if ((currentRpe != null || currentRir != null) && lastSetReps != null) ...[
                      SizedBox(height: isCompactScreen ? 10 : 16),
                      _buildCoachReviewSection(cardBg, textColor, subtitleColor, isDark),
                    ],

                    // AI Coach encouragement message
                    if (restMessage.isNotEmpty &&
                        weightSuggestion == null &&
                        !isLoadingWeightSuggestion &&
                        restSuggestion == null &&
                        !isLoadingRestSuggestion)
                      _buildEncouragementMessage(cardBg, textColor, isDark),

                    SizedBox(height: isCompactScreen ? 12 : 20),

                    // Next up section
                    _buildNextUpSection(cardBg, textColor, subtitleColor),

                    SizedBox(height: isCompactScreen ? 10 : 16),

                    // Log 1RM button
                    if (onLog1RM != null)
                      _build1RMPrompt(cardBg, textColor, subtitleColor, isDark),

                    // Ask AI Coach button
                    if (onAskAICoach != null) ...[
                      SizedBox(height: isCompactScreen ? 10 : 16),
                      _buildAskAICoachButton(cardBg, textColor, subtitleColor, isDark),
                    ],

                    // Extra padding at bottom for scroll
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Fixed footer: Skip Rest button
            Padding(
              padding: EdgeInsets.fromLTRB(24, 8, 24, isCompactScreen ? 12 : 24),
              child: _buildSkipButton(isDark),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildRestLabel(bool isDark) {
    final purple = isDark ? AppColors.purple : _darkenColor(AppColors.purple);
    return Text(
      'REST',
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: purple.withOpacity(isDark ? 0.8 : 1.0),
        letterSpacing: 6,
      ),
    );
  }

  Widget _buildTimer(Color textColor) {
    return Text(
      '${restSecondsRemaining}s',
      style: TextStyle(
        fontSize: 80,
        fontWeight: FontWeight.bold,
        color: textColor,
        height: 1,
      ),
    );
  }

  Widget _buildProgressBar(bool isDark) {
    final purple = isDark ? AppColors.purple : _darkenColor(AppColors.purple);
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use responsive width: max 200px or 60% of available width
        final screenWidth = MediaQuery.of(context).size.width;
        final progressWidth = screenWidth < 380 ? screenWidth * 0.5 : 200.0;
        return Container(
          height: 6,
          width: progressWidth,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.15) : AppColorsLight.cardBorder,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 6,
              width: progressWidth * restProgress,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    purple,
                    purple.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEncouragementMessage(Color cardBg, Color textColor, bool isDark) {
    final purple = isDark ? AppColors.purple : _darkenColor(AppColors.purple);
    final bgOpacity = isDark ? 0.2 : 0.15;
    final borderOpacity = isDark ? 0.3 : 0.4;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: purple.withOpacity(borderOpacity),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: purple.withOpacity(bgOpacity),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.psychology,
              color: purple,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              restMessage,
              style: TextStyle(
                fontSize: 15,
                color: textColor,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildNextUpSection(
    Color cardBg,
    Color textColor,
    Color subtitleColor,
  ) {
    if (isRestBetweenSets) {
      // Rest between sets - show current exercise set info
      return _buildNextSetCard(cardBg, textColor, subtitleColor);
    } else if (nextExercise != null) {
      // Rest between exercises - show next exercise
      return _buildNextExerciseCard(cardBg, textColor, subtitleColor);
    }
    return const SizedBox.shrink();
  }

  Widget _buildNextExerciseCard(
    Color cardBg,
    Color textColor,
    Color subtitleColor,
  ) {
    final next = nextExercise!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.skip_next,
              color: Colors.green,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NEXT UP',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.withOpacity(0.8),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  next.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${next.sets ?? 3} sets · ${next.reps ?? 10} reps${next.weight != null && next.weight! > 0 ? ' · ${next.weight}kg' : ''}',
                  style: TextStyle(
                    fontSize: 13,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 200.ms, duration: 400.ms)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _build1RMPrompt(
    Color cardBg,
    Color textColor,
    Color subtitleColor,
    bool isDark,
  ) {
    final orange = isDark ? AppColors.orange : _darkenColor(AppColors.orange);
    final bgOpacity = isDark ? 0.2 : 0.15;
    final borderOpacity = isDark ? 0.3 : 0.4;
    return GestureDetector(
      onTap: onLog1RM,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: orange.withOpacity(borderOpacity),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: orange.withOpacity(bgOpacity),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.fitness_center,
                color: orange,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Log 1RM',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: orange,
                  ),
                ),
                Text(
                  'Track your max',
                  style: TextStyle(
                    fontSize: 11,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: orange.withOpacity(0.7),
              size: 20,
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 300.ms, duration: 400.ms)
        .slideY(begin: 0.1, end: 0);
  }

  /// Ask AI Coach button - opens chat for questions during rest
  Widget _buildAskAICoachButton(
    Color cardBg,
    Color textColor,
    Color subtitleColor,
    bool isDark,
  ) {
    // Get coach name and colors
    final coachName = _getCoachShortName(coachPersona);
    final coachColor = coachPersona?.primaryColor ?? AppColors.purple;
    final coach = coachPersona ?? CoachPersona.defaultCoach;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onAskAICoach?.call();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: coachColor.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CoachAvatar(
              coach: coach,
              size: 30,
              showBorder: true,
              borderWidth: 1.5,
              showShadow: false,
              enableTapToView: false, // Tap triggers "Ask Coach" button
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ask $coachName',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: coachColor,
                  ),
                ),
                Text(
                  'Get tips for your next set',
                  style: TextStyle(
                    fontSize: 11,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: coachColor.withOpacity(0.7),
              size: 20,
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 350.ms, duration: 400.ms)
        .slideY(begin: 0.1, end: 0);
  }

  /// Get short display name for the coach
  String _getCoachShortName(CoachPersona? coach) {
    if (coach == null) return 'AI Coach';

    switch (coach.id) {
      case 'coach_mike':
        return 'Mike';
      case 'dr_sarah':
        return 'Sarah';
      case 'sergeant_max':
        return 'Max';
      case 'zen_maya':
        return 'Maya';
      case 'hype_danny':
        return 'Danny';
      case 'custom':
        final firstName = coach.name.split(' ').first;
        return firstName.length > 6 ? firstName.substring(0, 6) : firstName;
      default:
        final firstName = coach.name.split(' ').first;
        return firstName.length > 6 ? firstName.substring(0, 6) : firstName;
    }
  }

  /// Loading state for AI weight suggestion
  Widget _buildLoadingWeightSuggestion(
    Color cardBg,
    Color textColor,
    Color subtitleColor,
    bool isDark,
  ) {
    final cyan = isDark ? AppColors.cyan : _darkenColor(AppColors.cyan);
    final bgOpacity = isDark ? 0.2 : 0.15;
    final borderOpacity = isDark ? 0.3 : 0.4;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cyan.withValues(alpha: borderOpacity),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cyan.withValues(alpha: bgOpacity),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(cyan),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI WEIGHT COACH',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: cyan,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Analyzing your performance...',
                  style: TextStyle(
                    fontSize: 14,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildSkipButton(bool isDark) {
    final purple = isDark ? AppColors.purple : _darkenColor(AppColors.purple);
    return TextButton.icon(
      onPressed: onSkipRest,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        backgroundColor:
            isDark ? Colors.white.withValues(alpha: 0.1) : AppColorsLight.cardBorder,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      icon: Icon(Icons.skip_next, color: purple, size: 20),
      label: Text(
        'Skip Rest',
        style: TextStyle(
          color: purple,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    );
  }

  /// Show info dialog for RPE/RIR explanation
  void _showInfoDialog(
    BuildContext context,
    String title,
    String content,
    bool isDark,
  ) {
    final backgroundColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final subtitleColor = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: cyan,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: SingleChildScrollView(
            child: Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: subtitleColor,
                height: 1.5,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it',
              style: TextStyle(
                color: cyan,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Get color for RPE value (5-10 scale)
  Color _getRpeColor(int rpe) {
    if (rpe <= 6) return AppColors.success;
    if (rpe <= 7) return AppColors.cyan;
    if (rpe <= 8) return AppColors.orange;
    return AppColors.coral;
  }

  /// Get color for RIR value (0-5 scale)
  Color _getRirColor(int rir) {
    if (rir >= 4) return AppColors.success;
    if (rir >= 2) return AppColors.cyan;
    if (rir >= 1) return AppColors.orange;
    return AppColors.coral;
  }

  /// Darken a color for better visibility in light mode
  Color _darkenColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness * 0.7).clamp(0.0, 1.0)).toColor();
  }
}
