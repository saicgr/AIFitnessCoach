part of 'rest_timer_overlay.dart';

/// Methods extracted from RestTimerOverlay
extension _RestTimerOverlayExt on RestTimerOverlay {

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
                Builder(builder: (context) {
                  final purple = isDark ? AppColors.purple : _darkenColor(AppColors.purple);
                  final badgeBgOpacity = isDark ? 0.15 : 0.12;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: purple.withValues(alpha: badgeBgOpacity),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 12,
                          color: purple,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'AI',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: purple,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
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
        feedbackColor = isDark ? AppColors.coral : _darkenColor(AppColors.coral);
      } else if (rir == 1) {
        feedback = "Great effort! One rep left is solid intensity.";
        feedbackIcon = Icons.check_circle;
        feedbackColor = isDark ? AppColors.success : _darkenColor(AppColors.success);
      } else if (rir == 2) {
        feedback = "Perfect zone! 2 RIR is ideal for hypertrophy.";
        feedbackIcon = Icons.star;
        feedbackColor = isDark ? AppColors.cyan : _darkenColor(AppColors.cyan);
      } else if (rir == 3) {
        feedback = "Good effort. Consider adding weight next set.";
        feedbackIcon = Icons.trending_up;
        feedbackColor = isDark ? AppColors.success : _darkenColor(AppColors.success);
      } else {
        feedback = "Plenty left in the tank. Try increasing the weight.";
        feedbackIcon = Icons.fitness_center;
        feedbackColor = isDark ? AppColors.orange : _darkenColor(AppColors.orange);
      }
    } else if (rpe != null) {
      if (rpe >= 10) {
        feedback = "Max effort reached. Ensure adequate rest before the next set.";
        feedbackIcon = Icons.warning_amber_rounded;
        feedbackColor = isDark ? AppColors.coral : _darkenColor(AppColors.coral);
      } else if (rpe >= 8) {
        feedback = "Great intensity! This is the ideal training zone.";
        feedbackIcon = Icons.star;
        feedbackColor = isDark ? AppColors.cyan : _darkenColor(AppColors.cyan);
      } else if (rpe >= 7) {
        feedback = "Moderate effort. You can push a bit harder next set.";
        feedbackIcon = Icons.trending_up;
        feedbackColor = isDark ? AppColors.success : _darkenColor(AppColors.success);
      } else {
        feedback = "Light effort. Consider increasing weight or reps.";
        feedbackIcon = Icons.fitness_center;
        feedbackColor = isDark ? AppColors.orange : _darkenColor(AppColors.orange);
      }
    } else {
      return const SizedBox.shrink();
    }

    final purple = isDark ? AppColors.purple : _darkenColor(AppColors.purple);
    final bgOpacity = isDark ? 0.15 : 0.12;
    final borderOpacity = isDark ? 0.3 : 0.4;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: feedbackColor.withValues(alpha: borderOpacity),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: feedbackColor.withValues(alpha: bgOpacity),
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
                      color: purple,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'COACH REVIEW',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: purple,
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
    final orange = isDark ? AppColors.orange : _darkenColor(AppColors.orange);
    final bgOpacity = isDark ? 0.2 : 0.15;
    final borderOpacity = isDark ? 0.3 : 0.4;
    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: orange.withValues(alpha: borderOpacity),
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
                  color: orange.withValues(alpha: bgOpacity),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.speed,
                  color: orange,
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

}
