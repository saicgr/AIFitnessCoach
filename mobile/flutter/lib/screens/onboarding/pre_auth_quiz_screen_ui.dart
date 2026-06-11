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
                              begin: AlignmentDirectional.topStart,
                              end: AlignmentDirectional.bottomEnd,
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
                          AppLocalizations.of(context)!.preAuthQuizGenerateMyFirstWorkout,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: _canProceed ? t.buttonText : t.textDisabled,
                          ),
                        ),
                        if (_canProceed) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.auto_awesome_rounded, size: 20, color: t.buttonText),
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
                    AppLocalizations.of(context)!.preAuthQuizSkipLetAiDecide,
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
      skipText: _currentQuestion == 10 ? AppLocalizations.of(context)!.preAuthQuizSkipAndFinish : AppLocalizations.of(context)!.onboardingSkip,
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
              AppLocalizations.of(context)!.preAuthQuizWhichDaysWorkBest,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: t.textPrimary,
              ),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 6),
            Text(
              AppLocalizations.of(context)!.quizDaysSelectorSelectNDays(_selectedDays ?? 0),
              style: TextStyle(
                fontSize: 15,
                color: t.textSecondary,
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 24),
          ],
          Expanded(
            child: Builder(builder: (ctx) {
              final l10n = AppLocalizations.of(ctx)!;
              return ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDayCheckbox(1, l10n.settingsCardPartMonday, 300.ms),
                const SizedBox(height: 12),
                _buildDayCheckbox(2, l10n.settingsCardPartTuesday, 350.ms),
                const SizedBox(height: 12),
                _buildDayCheckbox(3, l10n.settingsCardPartWednesday, 400.ms),
                const SizedBox(height: 12),
                _buildDayCheckbox(4, l10n.settingsCardPartThursday, 450.ms),
                const SizedBox(height: 12),
                _buildDayCheckbox(5, l10n.settingsCardPartFriday, 500.ms),
                const SizedBox(height: 12),
                _buildDayCheckbox(6, l10n.settingsCardPartSaturday, 550.ms),
                const SizedBox(height: 12),
                _buildDayCheckbox(7, l10n.settingsCardPartSunday, 600.ms),
                const SizedBox(height: 24),
              ],
            );
            }),
          ),
        ],
      ),
    );
  }

}
