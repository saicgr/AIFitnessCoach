/// Rest timer overlay widget
///
/// Displays the rest countdown between sets or exercises.
/// Now includes smart weight suggestions based on RPE/RIR!
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/weight_suggestion_service.dart';
import '../../../data/models/exercise.dart';

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

    return Container(
      color: bgColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // REST label
              _buildRestLabel(),

              const SizedBox(height: 12),

              // Large timer
              _buildTimer(textColor),

              const SizedBox(height: 16),

              // Progress bar
              _buildProgressBar(isDark),

              const SizedBox(height: 32),

              // Weight suggestion section (loading or card)
              if (isRestBetweenSets) ...[
                if (isLoadingWeightSuggestion)
                  _buildLoadingWeightSuggestion(cardBg, textColor, subtitleColor, isDark)
                else if (weightSuggestion != null)
                  _buildWeightSuggestionCard(cardBg, textColor, subtitleColor, isDark),
              ],

              // AI Coach encouragement message (only if no weight suggestion and not loading)
              if (restMessage.isNotEmpty && weightSuggestion == null && !isLoadingWeightSuggestion)
                _buildEncouragementMessage(cardBg, textColor),

              const SizedBox(height: 24),

              // Next up section
              _buildNextUpSection(cardBg, textColor, subtitleColor),

              const SizedBox(height: 16),

              // Log 1RM button
              if (onLog1RM != null)
                _build1RMPrompt(cardBg, textColor, subtitleColor),

              const Spacer(flex: 2),

              // Skip Rest button
              _buildSkipButton(isDark),

              const SizedBox(height: 32),
            ],
          ),
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
    return Container(
      height: 6,
      width: 200,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.15) : AppColorsLight.cardBorder,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 6,
          width: 200 * restProgress,
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
  ) {
    final suggestion = weightSuggestion!;

    // Determine colors based on suggestion type
    Color accentColor;
    IconData icon;
    String actionLabel;

    switch (suggestion.type) {
      case SuggestionType.increase:
        accentColor = AppColors.success;
        icon = Icons.trending_up;
        actionLabel = 'Go heavier';
      case SuggestionType.decrease:
        accentColor = AppColors.orange;
        icon = Icons.trending_down;
        actionLabel = 'Go lighter';
      case SuggestionType.maintain:
        accentColor = AppColors.cyan;
        icon = Icons.trending_flat;
        actionLabel = 'Keep it up';
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
          // Header row
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
                    Row(
                      children: [
                        Text(
                          suggestion.aiPowered ? 'AI WEIGHT COACH' : 'WEIGHT SUGGESTION',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: accentColor,
                            letterSpacing: 1,
                          ),
                        ),
                        if (suggestion.aiPowered) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.purple.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '✨ AI',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: AppColors.purple,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      actionLabel,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Confidence indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(suggestion.confidence * 100).round()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Weight change display
          if (!suggestion.isNoChange)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    suggestion.formattedDelta,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.arrow_forward,
                    color: subtitleColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${suggestion.suggestedWeight.toStringAsFixed(1)} kg',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),

          // Reason text
          Text(
            suggestion.reason,
            style: TextStyle(
              fontSize: 14,
              color: subtitleColor,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 8),

          // Encouragement
          Text(
            suggestion.encouragement,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),

          const SizedBox(height: 16),

          // Action buttons
          if (onAcceptWeightSuggestion != null || onDismissWeightSuggestion != null)
            Row(
              children: [
                // Dismiss button
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
                        'Keep Current',
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
                // Accept button
                if (onAcceptWeightSuggestion != null && !suggestion.isNoChange)
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
                      icon: const Icon(Icons.check, size: 20),
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
}
