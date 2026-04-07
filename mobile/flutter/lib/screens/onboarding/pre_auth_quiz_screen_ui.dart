part of 'pre_auth_quiz_screen.dart';

/// UI builder methods extracted from _PreAuthQuizScreenState
extension _PreAuthQuizScreenStateUI on _PreAuthQuizScreenState {

  /// Build the action button for the current question step — glassmorphic.
  Widget? _buildActionButton(bool isDark) {
    final t = OnboardingTheme.of(context);

    // Case 6 gets special "Generate" button with optional skip
    if (_currentQuestion == 6) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _canProceed ? _generateAndShowPreview : null,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: _canProceed
                          ? LinearGradient(
                              colors: t.buttonGradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: _canProceed ? null : t.cardFill,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: _canProceed ? t.buttonBorder : t.borderSubtle,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Generate My First Workout',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: _canProceed ? t.accent : t.textDisabled,
                          ),
                        ),
                        if (_canProceed) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.auto_awesome_rounded, size: 20, color: t.accent),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
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
                      color: t.textMuted,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
    }
    if (_currentQuestion == 7) {
      return null;
    }
    return QuizContinueButton(
      canProceed: _canProceed,
      isLastQuestion: _currentQuestion == _totalQuestions - 1,
      onPressed: _nextQuestion,
      onSkip: _isCurrentPageSkippable ? _skipCurrentPage : null,
      skipText: _currentQuestion == 10 ? 'Skip & Finish' : 'Skip',
    );
  }


  Widget _buildWorkoutDaysSelector({bool showHeader = true}) {
    final t = OnboardingTheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader) ...[
            Text(
              'Which days work best?',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: t.textPrimary,
              ),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 6),
            Text(
              'Select ${_selectedDays ?? 0} days for your workouts',
              style: TextStyle(
                fontSize: 15,
                color: t.textSecondary,
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 24),
          ],
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
