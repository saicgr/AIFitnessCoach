part of 'pre_auth_quiz_screen.dart';

/// UI builder methods extracted from _PreAuthQuizScreenState
extension _PreAuthQuizScreenStateUI on _PreAuthQuizScreenState {

  /// Build the action button for the current question step.
  Widget? _buildActionButton(bool isDark) {
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    // Case 6 gets special "Generate" button with optional skip
    if (_currentQuestion == 6) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _canProceed ? _generateAndShowPreview : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canProceed
                      ? AppColors.orange
                      : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
                  foregroundColor: _canProceed
                      ? Colors.white
                      : (isDark ? AppColors.textMuted : AppColorsLight.textMuted),
                  elevation: _canProceed ? 4 : 0,
                  shadowColor: _canProceed ? AppColors.orange.withValues(alpha: 0.4) : Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Generate My First Workout',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_canProceed) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.auto_awesome_rounded, size: 20),
                    ],
                  ],
                ),
              ),
            ),
            // Skip option below the generate button
            if (!_canProceed)
              GestureDetector(
                onTap: _skipCurrentPage,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Skip, let AI decide',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
    }
    // Case 7 (personalization gate) has its own action buttons
    if (_currentQuestion == 7) {
      return null;
    }
    // All other cases: standard continue button with optional skip
    return QuizContinueButton(
      canProceed: _canProceed,
      isLastQuestion: _currentQuestion == _totalQuestions - 1,
      onPressed: _nextQuestion,
      onSkip: _isCurrentPageSkippable ? _skipCurrentPage : null,
      skipText: _currentQuestion == 10 ? 'Skip & Finish' : 'Skip',
    );
  }


  Widget _buildWorkoutDaysSelector({bool showHeader = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader) ...[
            // Title
            Text(
              'Which days work best?',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF0A0A0A),
              ),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 6),
            Text(
              'Select ${_selectedDays ?? 0} days for your workouts',
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFFD4D4D8)
                    : const Color(0xFF52525B),
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 24),
          ],
          // Days of week selector
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDayCheckbox(1, 'Monday', 300.ms),
                const SizedBox(height: 12),
                _buildDayCheckbox(2, 'Tuesday', 350.ms),
                const SizedBox(height: 12),
                _buildDayCheckbox(3, 'Wednesday', 400.ms),
                const SizedBox(height: 12),
                _buildDayCheckbox(4, 'Thursday', 450.ms),
                const SizedBox(height: 12),
                _buildDayCheckbox(5, 'Friday', 500.ms),
                const SizedBox(height: 12),
                _buildDayCheckbox(6, 'Saturday', 550.ms),
                const SizedBox(height: 12),
                _buildDayCheckbox(7, 'Sunday', 600.ms),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
