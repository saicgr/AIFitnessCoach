part of 'stats_welcome_screen.dart';

/// UI builder methods extracted from _StatsWelcomeScreenState
extension _StatsWelcomeScreenStateUI on _StatsWelcomeScreenState {

  /// Hero claim - the main selling point, BIG and bold
  Widget _buildHeroClaim(ThemeColors colors) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Column(
      children: [
        // Main claim - one line, BIG type
        Text(
          'Your AI Fitness Coach',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w900,
            color: colors.accent,
            height: 1.1,
            letterSpacing: -1,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 12),

        // Supporting tagline
        Text(
          'AI-powered workouts tailored to you',
          style: TextStyle(
            fontSize: 16,
            color: colors.textSecondary,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 20),

        // Micro-benefits (Fitbod-style)
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: [
            _buildMicroBenefit('Adapts to your equipment', Icons.fitness_center, textSecondary),
            _buildMicroBenefit('Progressive overload built-in', Icons.trending_up, textSecondary),
            _buildMicroBenefit('Rest timer + tracking', Icons.timer, textSecondary),
          ],
        ),
      ],
    );
  }


  Widget _buildMicroBenefit(String text, IconData icon, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: textColor.withOpacity(0.7)),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: textColor.withOpacity(0.8),
            height: 1.2,
          ),
        ),
      ],
    );
  }


  Widget _buildStatDescription(bool isDark) {
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final longDesc = _StatsWelcomeScreenState._stats[_currentStatIndex]['longDescription'] as String;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          longDesc,
          key: ValueKey(_currentStatIndex),
          style: TextStyle(
            fontSize: 13,
            color: textSecondary,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }


  Widget _buildGetStartedButton(bool isDark, ThemeColors colors) {
    final accentColor = colors.accent;
    final accentContrast = colors.accentContrast;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          // Save selected language
          ref.read(languageProvider.notifier).setLanguage(_selectedLanguage);
          // Navigate to how it works screen (sets expectations before quiz)
          context.go('/how-it-works');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: accentContrast,
          elevation: 6,
          shadowColor: accentColor.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(27),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Get Started — Free',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: accentContrast,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, size: 20, color: accentContrast),
          ],
        ),
      ),
    );
  }

}
