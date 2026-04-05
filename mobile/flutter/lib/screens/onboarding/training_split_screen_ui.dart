part of 'training_split_screen.dart';

/// UI builder methods extracted from _TrainingSplitScreenState
extension _TrainingSplitScreenStateUI on _TrainingSplitScreenState {

  Widget _buildHeader(bool isDark, Color textPrimary, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.orange,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.fitness_center, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Training Split',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'How do you want to structure your workouts?',
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ).animate().fadeIn().slideY(begin: -0.1),
    );
  }


  Widget _buildProgressIndicator(bool isDark) {
    const orange = Color(0xFFF97316);
    final inactiveColor = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    // Current step index (0-based): this is step 3 (Split)
    const currentStep = 2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          _buildStepDot(1, 'Sign In', true, orange, isDark, 0),
          _buildProgressLine(0, currentStep, orange, inactiveColor, 1),
          _buildStepDot(2, 'About You', true, orange, isDark, 2),
          _buildProgressLine(1, currentStep, orange, inactiveColor, 3),
          _buildStepDot(3, 'Split', true, orange, isDark, 4),
          _buildProgressLine(2, currentStep, orange, inactiveColor, 5),
          _buildStepDot(4, 'Privacy', false, orange, isDark, 6),
          _buildProgressLine(3, currentStep, orange, inactiveColor, 7),
          _buildStepDot(5, 'Coach', false, orange, isDark, 8),
        ],
      ),
    );
  }


  Widget _buildProgressLine(int segmentIndex, int currentStep, Color activeColor, Color inactiveColor, int animOrder) {
    final isComplete = segmentIndex < currentStep;
    final delay = 100 + (animOrder * 80);

    return Expanded(
      child: Container(
        height: 2,
        color: inactiveColor,
        child: isComplete
            ? Container(height: 2, color: activeColor)
                .animate()
                .scaleX(begin: 0, end: 1, alignment: Alignment.centerLeft,
                    delay: Duration(milliseconds: delay), duration: 300.ms,
                    curve: Curves.easeOut)
            : null,
      ),
    );
  }


  Widget _buildStepDot(int step, String label, bool isComplete, Color activeColor, bool isDark, int animOrder) {
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final delay = 100 + (animOrder * 80);

    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isComplete ? activeColor : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
            shape: BoxShape.circle,
            border: Border.all(
              color: isComplete ? activeColor : (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
              width: 2,
            ),
          ),
          child: Center(
            child: isComplete
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text(
                    '$step',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: textSecondary,
                    ),
                  ),
          ),
        ).animate()
         .scaleXY(begin: 0, end: 1, delay: Duration(milliseconds: delay), duration: 300.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: isComplete ? activeColor : textSecondary,
            fontWeight: isComplete ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }


  Widget _buildContinueButton(bool isDark) {
    const orange = Color(0xFFF97316);
    final hasSelection = _selectedSplit != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            (isDark ? AppColors.pureBlack : AppColorsLight.pureWhite).withValues(alpha: 0),
            isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: GestureDetector(
          onTap: (_isLoading || !hasSelection) ? null : _continueToNextScreen,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: hasSelection ? orange : orange.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 20, color: Colors.white),
                      ],
                    ),
            ),
          ),
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
      ),
    );
  }

}
