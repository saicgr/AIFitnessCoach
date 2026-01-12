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
import 'rest_suggestion_card.dart';

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
                  _buildRestLabel(),
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
                      _buildEncouragementMessage(cardBg, textColor),

                    SizedBox(height: isCompactScreen ? 12 : 20),

                    // Next up section
                    _buildNextUpSection(cardBg, textColor, subtitleColor),

                    SizedBox(height: isCompactScreen ? 10 : 16),

                    // Log 1RM button
                    if (onLog1RM != null)
                      _build1RMPrompt(cardBg, textColor, subtitleColor),

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

  Widget _buildRestLabel() {
    return Text(
      'REST',
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.purple.withOpacity(0.8),
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
                    AppColors.purple,
                    AppColors.purple.withOpacity(0.7),
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

  Widget _buildEncouragementMessage(Color cardBg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.purple.withOpacity(0.3),
          width: 1,
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
              Icons.psychology,
              color: AppColors.purple,
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

  Widget _buildNextSetCard(
    Color cardBg,
    Color textColor,
    Color subtitleColor,
  ) {
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
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.replay,
              color: Colors.orange,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NEXT SET',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.withOpacity(0.8),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentExercise.name,
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
                  'Set ${completedSetsCount + 1} of $totalSets',
                  style: TextStyle(
                    fontSize: 13,
                    color: subtitleColor,
                  ),
                ),
                // Show target reps and weight for next set
                if (currentExercise.reps != null || currentExercise.weight != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (currentExercise.reps != null) ...[
                        Icon(
                          Icons.repeat,
                          size: 12,
                          color: subtitleColor.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${currentExercise.reps} reps',
                          style: TextStyle(
                            fontSize: 12,
                            color: subtitleColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      if (currentExercise.reps != null &&
                          currentExercise.weight != null &&
                          currentExercise.weight! > 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            '·',
                            style: TextStyle(
                              fontSize: 12,
                              color: subtitleColor.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      if (currentExercise.weight != null &&
                          currentExercise.weight! > 0) ...[
                        Icon(
                          Icons.fitness_center,
                          size: 12,
                          color: subtitleColor.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${currentExercise.weight!.toStringAsFixed(currentExercise.weight! == currentExercise.weight!.roundToDouble() ? 0 : 1)} kg',
                          style: TextStyle(
                            fontSize: 12,
                            color: subtitleColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
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
  ) {
    return GestureDetector(
      onTap: onLog1RM,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.orange.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.fitness_center,
                color: AppColors.orange,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Log 1RM',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.orange,
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
              color: AppColors.orange.withOpacity(0.7),
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
            color: AppColors.purple.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.purple.withOpacity(0.3),
                    AppColors.cyan.withOpacity(0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: AppColors.purple,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Ask AI Coach',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.purple,
                  ),
                ),
                Text(
                  'Have a question?',
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
              color: AppColors.purple.withOpacity(0.7),
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

  /// Loading state for AI weight suggestion
  Widget _buildLoadingWeightSuggestion(
    Color cardBg,
    Color textColor,
    Color subtitleColor,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.cyan.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.cyan.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyan),
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
                    color: AppColors.cyan,
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

  Widget _buildWeightSuggestionCard(
    Color cardBg,
    Color textColor,
    Color subtitleColor,
    bool isDark,
    [bool isCompact = false]
  ) {
    final suggestion = weightSuggestion!;

    // Determine colors and labels based on suggestion type
    Color accentColor;
    IconData icon;
    String actionLabel;
    String actionDescription;

    switch (suggestion.type) {
      case SuggestionType.increase:
        accentColor = AppColors.success;
        icon = Icons.trending_up;
        actionLabel = 'Go heavier';
        actionDescription = 'You can handle more weight';
      case SuggestionType.decrease:
        accentColor = AppColors.orange;
        icon = Icons.trending_down;
        actionLabel = 'Go lighter';
        actionDescription = 'Reduce to maintain good form';
      case SuggestionType.maintain:
        accentColor = AppColors.cyan;
        icon = Icons.check_circle_outline;
        actionLabel = 'Perfect weight';
        actionDescription = 'This weight is working well';
    }

    // Build performance summary
    // Only show if data is valid (reps > 0, since 0 reps is invalid)
    String? performanceSummary;
    if (lastSetReps != null && lastSetReps! > 0 && lastSetWeight != null) {
      final weightStr = lastSetWeight == lastSetWeight!.roundToDouble()
          ? '${lastSetWeight!.toInt()}kg'
          : '${lastSetWeight!.toStringAsFixed(1)}kg';
      if (lastSetTargetReps != null && lastSetTargetReps! > 0) {
        performanceSummary = 'You did $lastSetReps/$lastSetTargetReps reps at $weightStr';
      } else {
        performanceSummary = 'You did $lastSetReps reps at $weightStr';
      }
    }

    // Build RPE/RIR summary
    String? effortSummary;
    if (currentRpe != null || currentRir != null) {
      if (currentRir != null) {
        final rirDescriptions = {
          0: 'at failure',
          1: '1 rep left',
          2: '2 reps left - ideal zone',
          3: '3 reps left - good effort',
          4: '4+ reps left - too easy',
          5: '5+ reps left - much too easy',
        };
        effortSummary = 'RIR $currentRir (${rirDescriptions[currentRir] ?? ''})';
      } else if (currentRpe != null) {
        final rpeDescriptions = {
          5: 'very light',
          6: 'light effort',
          7: 'moderate effort',
          8: 'hard - ideal zone',
          9: 'very hard',
          10: 'max effort',
        };
        effortSummary = 'RPE $currentRpe (${rpeDescriptions[currentRpe] ?? ''})';
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with icon and title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      actionLabel,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      actionDescription,
                      style: TextStyle(
                        fontSize: 13,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
              // AI badge (small, subtle)
              if (suggestion.aiPowered)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 12,
                        color: AppColors.purple,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'AI',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.purple,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // Performance summary section
          if (performanceSummary != null || effortSummary != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (performanceSummary != null)
                    Row(
                      children: [
                        Icon(
                          Icons.fitness_center,
                          size: 14,
                          color: subtitleColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            performanceSummary,
                            style: TextStyle(
                              fontSize: 13,
                              color: textColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (performanceSummary != null && effortSummary != null)
                    const SizedBox(height: 6),
                  if (effortSummary != null)
                    Row(
                      children: [
                        Icon(
                          Icons.speed,
                          size: 14,
                          color: subtitleColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            effortSummary,
                            style: TextStyle(
                              fontSize: 13,
                              color: textColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

          // Weight change display (for increase/decrease only)
          if (!suggestion.isNoChange) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (lastSetWeight != null) ...[
                    Text(
                      lastSetWeight == lastSetWeight!.roundToDouble()
                          ? '${lastSetWeight!.toInt()}'
                          : lastSetWeight!.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: subtitleColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward,
                      color: accentColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    '${suggestion.suggestedWeight.toStringAsFixed(1)} kg',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      suggestion.formattedDelta,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Action buttons
          if (onAcceptWeightSuggestion != null || onDismissWeightSuggestion != null)
            Row(
              children: [
                // For maintain suggestion - single "Got it" button
                if (suggestion.isNoChange && onDismissWeightSuggestion != null)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        onDismissWeightSuggestion!();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        lastSetWeight != null && lastSetWeight! > 0
                            ? 'Keep ${lastSetWeight == lastSetWeight!.roundToDouble() ? lastSetWeight!.toInt() : lastSetWeight!.toStringAsFixed(1)} kg'
                            : 'Got it',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                // For increase/decrease - two buttons
                if (!suggestion.isNoChange) ...[
                  if (onDismissWeightSuggestion != null)
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          onDismissWeightSuggestion!();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: subtitleColor.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                        child: Text(
                          lastSetWeight != null && lastSetWeight! > 0
                              ? 'Keep ${lastSetWeight == lastSetWeight!.roundToDouble() ? lastSetWeight!.toInt() : lastSetWeight!.toStringAsFixed(1)} kg'
                              : 'Keep Weight',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: subtitleColor,
                          ),
                        ),
                      ),
                    ),
                  if (onAcceptWeightSuggestion != null &&
                      onDismissWeightSuggestion != null)
                    const SizedBox(width: 12),
                  if (onAcceptWeightSuggestion != null)
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          onAcceptWeightSuggestion!(suggestion.suggestedWeight);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: Icon(
                          suggestion.type == SuggestionType.increase
                              ? Icons.add
                              : Icons.remove,
                          size: 18,
                        ),
                        label: Text(
                          'Use ${suggestion.suggestedWeight.toStringAsFixed(1)} kg',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0)
        .shimmer(
          delay: 500.ms,
          duration: 1000.ms,
          color: accentColor.withValues(alpha: 0.1),
        );
  }

  Widget _buildSkipButton(bool isDark) {
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
      icon: const Icon(Icons.skip_next, color: AppColors.purple, size: 20),
      label: const Text(
        'Skip Rest',
        style: TextStyle(
          color: AppColors.purple,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    );
  }

  /// Coach Review section - provides AI feedback based on RPE/RIR
  Widget _buildCoachReviewSection(
    Color cardBg,
    Color textColor,
    Color subtitleColor,
    bool isDark,
  ) {
    // Generate coach feedback based on RPE/RIR values
    String feedback;
    IconData feedbackIcon;
    Color feedbackColor;

    // Use local variables for null safety promotion
    final rir = currentRir;
    final rpe = currentRpe;

    if (rir != null) {
      if (rir == 0) {
        feedback = "You went to failure. Make sure you can recover for the next set.";
        feedbackIcon = Icons.warning_amber_rounded;
        feedbackColor = AppColors.coral;
      } else if (rir == 1) {
        feedback = "Great effort! One rep left is solid intensity.";
        feedbackIcon = Icons.check_circle;
        feedbackColor = AppColors.success;
      } else if (rir == 2) {
        feedback = "Perfect zone! 2 RIR is ideal for hypertrophy.";
        feedbackIcon = Icons.star;
        feedbackColor = AppColors.cyan;
      } else if (rir == 3) {
        feedback = "Good effort. Consider adding weight next set.";
        feedbackIcon = Icons.trending_up;
        feedbackColor = AppColors.success;
      } else {
        feedback = "Plenty left in the tank. Try increasing the weight.";
        feedbackIcon = Icons.fitness_center;
        feedbackColor = AppColors.orange;
      }
    } else if (rpe != null) {
      if (rpe >= 10) {
        feedback = "Max effort reached. Ensure adequate rest before the next set.";
        feedbackIcon = Icons.warning_amber_rounded;
        feedbackColor = AppColors.coral;
      } else if (rpe >= 8) {
        feedback = "Great intensity! This is the ideal training zone.";
        feedbackIcon = Icons.star;
        feedbackColor = AppColors.cyan;
      } else if (rpe >= 7) {
        feedback = "Moderate effort. You can push a bit harder next set.";
        feedbackIcon = Icons.trending_up;
        feedbackColor = AppColors.success;
      } else {
        feedback = "Light effort. Consider increasing weight or reps.";
        feedbackIcon = Icons.fitness_center;
        feedbackColor = AppColors.orange;
      }
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: feedbackColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: feedbackColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              feedbackIcon,
              color: feedbackColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 12,
                      color: AppColors.purple,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'COACH REVIEW',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.purple,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  feedback,
                  style: TextStyle(
                    fontSize: 13,
                    color: textColor,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 200.ms, duration: 300.ms)
        .slideY(begin: 0.1, end: 0);
  }

  /// Compact RPE/RIR input section for rest period
  Widget _buildRpeRirSection(
    BuildContext context,
    Color cardBg,
    Color textColor,
    Color subtitleColor,
    bool isDark,
    [bool isCompact = false]
  ) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.orange.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.speed,
                  color: AppColors.orange,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Rate Last Set',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const Spacer(),
              Text(
                'optional',
                style: TextStyle(
                  fontSize: 11,
                  color: subtitleColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 10 : 16),

          // RPE Selection
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      isCompact ? 'RPE' : 'RPE (Rate of Perceived Exertion)',
                      style: TextStyle(
                        fontSize: isCompact ? 11 : 12,
                        fontWeight: FontWeight.w500,
                        color: subtitleColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _showInfoDialog(
                      context,
                      'RPE - Rate of Perceived Exertion',
                      'RPE is a scale from 5-10 that measures how hard you feel you\'re working during exercise.\n\n'
                      '• 5-6: Easy, could talk normally\n'
                      '• 7: Moderate, slightly breathless\n'
                      '• 8: Hard, difficult to talk\n'
                      '• 9: Very hard, near max effort\n'
                      '• 10: Maximum effort\n\n'
                      'Why it matters:\n'
                      '• Ensures you\'re training at the right intensity\n'
                      '• Prevents overtraining and injury\n'
                      '• Helps AI suggest better weights for your next set\n'
                      '• Enables smarter workout adjustments over time',
                      isDark,
                    ),
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: isCompact ? 14 : 16,
                      color: subtitleColor.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isCompact ? 6 : 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(6, (index) {
                    final rpe = index + 5; // 5-10 scale
                    final isSelected = currentRpe == rpe;
                    final buttonSize = isCompact ? 38.0 : 44.0;
                    return Padding(
                      padding: EdgeInsets.only(right: isCompact ? 6 : 8),
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onRpeChanged?.call(isSelected ? null : rpe);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: buttonSize,
                          height: buttonSize,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _getRpeColor(rpe)
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.05)),
                            borderRadius: BorderRadius.circular(isCompact ? 10 : 12),
                            border: Border.all(
                              color: isSelected
                                  ? _getRpeColor(rpe)
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.15)
                                      : Colors.black.withValues(alpha: 0.1)),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '$rpe',
                              style: TextStyle(
                                fontSize: isCompact ? 14 : 16,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white : textColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 10 : 14),

          // RIR Selection
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      isCompact ? 'RIR' : 'RIR (Reps in Reserve)',
                      style: TextStyle(
                        fontSize: isCompact ? 11 : 12,
                        fontWeight: FontWeight.w500,
                        color: subtitleColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _showInfoDialog(
                      context,
                      'RIR - Reps in Reserve',
                      'RIR tells you how many more reps you could have done before reaching failure.\n\n'
                      '• 5: Very easy, many reps left\n'
                      '• 3-4: Moderate effort\n'
                      '• 2: Hard, close to failure\n'
                      '• 1: Very hard, 1 rep left\n'
                      '• 0: Failure, no more reps possible\n\n'
                      'Why it matters:\n'
                      '• For muscle growth, aim for 1-3 RIR\n'
                      '• For strength, 2-4 RIR is often optimal\n'
                      '• AI uses this to suggest weight adjustments\n'
                      '• Helps detect fatigue and prevent overtraining',
                      isDark,
                    ),
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: isCompact ? 14 : 16,
                      color: subtitleColor.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isCompact ? 6 : 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(6, (index) {
                    final rir = 5 - index; // 5-0 (reverse order)
                    final isSelected = currentRir == rir;
                    final buttonSize = isCompact ? 38.0 : 44.0;
                    return Padding(
                      padding: EdgeInsets.only(right: isCompact ? 6 : 8),
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onRirChanged?.call(isSelected ? null : rir);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: buttonSize,
                          height: buttonSize,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _getRirColor(rir)
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.05)),
                            borderRadius: BorderRadius.circular(isCompact ? 10 : 12),
                            border: Border.all(
                              color: isSelected
                                  ? _getRirColor(rir)
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.15)
                                      : Colors.black.withValues(alpha: 0.1)),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '$rir',
                              style: TextStyle(
                                fontSize: isCompact ? 14 : 16,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white : textColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 100.ms, duration: 300.ms)
        .slideY(begin: 0.1, end: 0);
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
}
