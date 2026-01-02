import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/exercise_progression.dart';
import '../../../data/providers/exercise_progression_provider.dart';

/// A card that displays exercise progression suggestions after workout completion.
///
/// Shows when the user has completed exercises with "too easy" feedback,
/// suggesting they progress to harder variants based on leverage mechanics.
class ProgressionSuggestionCard extends ConsumerStatefulWidget {
  /// List of progression suggestions to display
  final List<ProgressionSuggestion> suggestions;

  /// Callback when a progression is accepted
  final Function(ProgressionSuggestion suggestion)? onAccepted;

  /// Callback when a progression is dismissed
  final Function(ProgressionSuggestion suggestion)? onDismissed;

  const ProgressionSuggestionCard({
    super.key,
    required this.suggestions,
    this.onAccepted,
    this.onDismissed,
  });

  @override
  ConsumerState<ProgressionSuggestionCard> createState() =>
      _ProgressionSuggestionCardState();
}

class _ProgressionSuggestionCardState
    extends ConsumerState<ProgressionSuggestionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _unlockAnimationController;
  late Animation<double> _unlockAnimation;
  int _currentIndex = 0;
  bool _isAnimatingUnlock = false;
  String? _unlockedExercise;

  @override
  void initState() {
    super.initState();
    _unlockAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _unlockAnimation = CurvedAnimation(
      parent: _unlockAnimationController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _unlockAnimationController.dispose();
    super.dispose();
  }

  void _handleAccept(ProgressionSuggestion suggestion) async {
    HapticFeedback.mediumImpact();

    setState(() {
      _isAnimatingUnlock = true;
      _unlockedExercise = suggestion.suggestedExercise;
    });

    // Play unlock animation
    _unlockAnimationController.forward(from: 0);

    // Accept the progression
    final notifier = ref.read(exerciseProgressionProvider.notifier);
    final success = await notifier.acceptProgression(suggestion.id);

    if (success) {
      await Future.delayed(const Duration(milliseconds: 800));
      widget.onAccepted?.call(suggestion);

      // Move to next suggestion or close
      if (_currentIndex < widget.suggestions.length - 1) {
        setState(() {
          _currentIndex++;
          _isAnimatingUnlock = false;
          _unlockedExercise = null;
        });
      }
    }

    setState(() {
      _isAnimatingUnlock = false;
    });
  }

  void _handleDismiss(ProgressionSuggestion suggestion) async {
    HapticFeedback.lightImpact();

    final notifier = ref.read(exerciseProgressionProvider.notifier);
    await notifier.dismissProgression(suggestion.id);

    widget.onDismissed?.call(suggestion);

    // Move to next suggestion or close
    if (_currentIndex < widget.suggestions.length - 1) {
      setState(() {
        _currentIndex++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final suggestion = widget.suggestions[_currentIndex];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.success.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.success.withOpacity(0.15),
                  AppColors.cyan.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                // Unlock icon with animation
                AnimatedBuilder(
                  animation: _unlockAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isAnimatingUnlock
                          ? 1.0 + (_unlockAnimation.value * 0.3)
                          : 1.0,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _isAnimatingUnlock
                              ? AppColors.success.withOpacity(0.3)
                              : AppColors.success.withOpacity(0.2),
                          shape: BoxShape.circle,
                          boxShadow: _isAnimatingUnlock
                              ? [
                                  BoxShadow(
                                    color: AppColors.success.withOpacity(0.4),
                                    blurRadius: 20 * _unlockAnimation.value,
                                    spreadRadius: 5 * _unlockAnimation.value,
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          _isAnimatingUnlock ? Icons.lock_open : Icons.trending_up,
                          color: AppColors.success,
                          size: 24,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isAnimatingUnlock
                            ? 'Exercise Unlocked!'
                            : 'Ready to Level Up!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.suggestions.length > 1
                            ? '${_currentIndex + 1} of ${widget.suggestions.length} progressions'
                            : 'Based on your performance',
                        style: TextStyle(
                          fontSize: 12,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                // Progress dots
                if (widget.suggestions.length > 1)
                  Row(
                    children: List.generate(
                      widget.suggestions.length,
                      (index) => Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(left: 4),
                        decoration: BoxDecoration(
                          color: index == _currentIndex
                              ? AppColors.success
                              : textMuted.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Progression content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Exercise comparison
                Row(
                  children: [
                    // Current exercise
                    Expanded(
                      child: _ExerciseBox(
                        exerciseName: suggestion.currentExercise,
                        difficultyLevel: suggestion.currentDifficulty,
                        label: 'Current',
                        isCurrent: true,
                      ),
                    ),
                    // Arrow
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        children: [
                          Icon(
                            Icons.arrow_forward,
                            color: AppColors.success,
                            size: 28,
                          )
                              .animate(
                                onPlay: (c) => c.repeat(),
                              )
                              .shimmer(
                                duration: 1500.ms,
                                color: AppColors.success.withOpacity(0.5),
                              ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '+${suggestion.difficultyIncrease}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Suggested exercise
                    Expanded(
                      child: _ExerciseBox(
                        exerciseName: suggestion.suggestedExercise,
                        difficultyLevel: suggestion.suggestedDifficulty,
                        label: 'Next Level',
                        isCurrent: false,
                        isUnlocking: _isAnimatingUnlock &&
                            _unlockedExercise == suggestion.suggestedExercise,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Reason explanation
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: 16,
                            color: AppColors.orange,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Why this progression?',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        suggestion.reason,
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                          height: 1.4,
                        ),
                      ),
                      if (suggestion.leverageExplanation != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.science_outlined,
                              size: 14,
                              color: textMuted,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                suggestion.leverageExplanation!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: textMuted,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Action buttons
                Row(
                  children: [
                    // Dismiss button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isAnimatingUnlock
                            ? null
                            : () => _handleDismiss(suggestion),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textSecondary,
                          side: BorderSide(
                            color: isDark
                                ? AppColors.cardBorder
                                : AppColorsLight.cardBorder,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Keep Current',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Accept button
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isAnimatingUnlock
                            ? null
                            : () => _handleAccept(suggestion),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isAnimatingUnlock) ...[
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                            ] else ...[
                              const Icon(Icons.upgrade, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Try Next Level',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}

/// Individual exercise box showing name and difficulty
class _ExerciseBox extends StatelessWidget {
  final String exerciseName;
  final int difficultyLevel;
  final String label;
  final bool isCurrent;
  final bool isUnlocking;

  const _ExerciseBox({
    required this.exerciseName,
    required this.difficultyLevel,
    required this.label,
    required this.isCurrent,
    this.isUnlocking = false,
  });

  Color _getDifficultyColor() {
    if (difficultyLevel <= 2) return AppColors.success;
    if (difficultyLevel <= 4) return AppColors.cyan;
    if (difficultyLevel <= 6) return AppColors.orange;
    if (difficultyLevel <= 8) return AppColors.coral;
    return AppColors.purple;
  }

  String _getDifficultyLabel() {
    if (difficultyLevel <= 2) return 'Beginner';
    if (difficultyLevel <= 4) return 'Easy';
    if (difficultyLevel <= 6) return 'Medium';
    if (difficultyLevel <= 8) return 'Hard';
    return 'Expert';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final difficultyColor = _getDifficultyColor();

    Widget content = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrent
            ? (isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.03))
            : difficultyColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent ? cardBorder : difficultyColor.withOpacity(0.3),
          width: isCurrent ? 1 : 2,
        ),
      ),
      child: Column(
        children: [
          // Label
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isCurrent ? textMuted : difficultyColor,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          // Exercise name
          Text(
            exerciseName,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          // Difficulty badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: difficultyColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _getDifficultyLabel(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: difficultyColor,
              ),
            ),
          ),
        ],
      ),
    );

    // Add unlock animation if unlocking
    if (isUnlocking) {
      content = content
          .animate(
            onPlay: (c) => c.repeat(reverse: true),
          )
          .shimmer(
            duration: 800.ms,
            color: AppColors.success.withOpacity(0.3),
          )
          .scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.05, 1.05),
            duration: 400.ms,
          );
    }

    return content;
  }
}

/// Compact version of the suggestion card for showing in a list
class ProgressionSuggestionTile extends ConsumerWidget {
  final ProgressionSuggestion suggestion;
  final VoidCallback? onTap;

  const ProgressionSuggestionTile({
    super.key,
    required this.suggestion,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.success.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.trending_up,
                color: AppColors.success,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${suggestion.currentExercise} -> ${suggestion.suggestedExercise}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    suggestion.reason,
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Difficulty badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '+${suggestion.difficultyIncrease}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty state when there are no progression suggestions
class NoProgressionSuggestionsCard extends StatelessWidget {
  const NoProgressionSuggestionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.trending_up,
            size: 40,
            color: textMuted.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'Keep Going!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Complete a few more "easy" sessions to unlock progressions',
            style: TextStyle(
              fontSize: 13,
              color: textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
