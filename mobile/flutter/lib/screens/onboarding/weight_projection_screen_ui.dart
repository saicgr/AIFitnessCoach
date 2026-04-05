part of 'weight_projection_screen.dart';

/// Methods extracted from _WeightProjectionScreenState
extension __WeightProjectionScreenStateExt on _WeightProjectionScreenState {

  /// Build an alternate screen for users who selected "Maintain" weight goal
  Widget _buildMaintainScreen(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color background,
    double currentWeight,
    bool useMetric,
  ) {
    final displayWeight = useMetric ? currentWeight : currentWeight * 2.20462;
    final unit = useMetric ? 'kg' : 'lbs';

    final maintainBackButton = Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: GlassBackButton(
          onTap: () {
            HapticFeedback.lightImpact();
            context.go('/personal-info');
          },
        ),
      ),
    );

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: FoldableQuizScaffold(
          headerTitle: "You're at Your Ideal Weight!",
          headerSubtitle: "Let's keep you there! We'll focus on maintaining your current physique while improving your fitness.",
          headerExtra: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.glassSurface : AppColorsLight.glassSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.green.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppColors.green,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '${displayWeight.round()} $unit',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
          headerOverlay: maintainBackButton,
          content: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Show title/celebration inline only on phone
                Consumer(builder: (context, ref, _) {
                  final windowState = ref.watch(windowModeProvider);
                  if (FoldableQuizScaffold.shouldUseFoldableLayout(windowState)) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    children: [
                      const SizedBox(height: 40),

                      // Celebration emoji
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.green.withValues(alpha: 0.2),
                              AppColors.orange.withValues(alpha: 0.2),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            '✨',
                            style: TextStyle(fontSize: 48),
                          ),
                        ),
                      ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.8, 0.8)),

                      const SizedBox(height: 32),

                      // Title
                      Text(
                        "You're at Your Ideal Weight!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                          height: 1.3,
                        ),
                      ).animate().fadeIn(delay: 300.ms).slideY(begin: -0.1),

                      const SizedBox(height: 16),

                      // Current weight display
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.glassSurface : AppColorsLight.glassSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.green.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.green,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${displayWeight.round()} $unit',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.95, 0.95)),

                      const SizedBox(height: 32),

                      // Subtitle
                      Text(
                        "Let's keep you there! We'll focus on maintaining your current physique while improving your overall fitness, strength, and energy levels.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: textSecondary,
                          height: 1.5,
                        ),
                      ).animate().fadeIn(delay: 500.ms),
                    ],
                  );
                }),

                const SizedBox(height: 40),

                // Benefits cards
                _buildMaintainBenefitCard(
                  isDark,
                  textPrimary,
                  textSecondary,
                  Icons.fitness_center,
                  'Build Strength',
                  'Gain muscle while maintaining weight',
                  AppColors.purple,
                  600,
                ),
                const SizedBox(height: 12),
                _buildMaintainBenefitCard(
                  isDark,
                  textPrimary,
                  textSecondary,
                  Icons.bolt,
                  'Boost Energy',
                  'Optimize nutrition for peak performance',
                  AppColors.orange,
                  700,
                ),
                const SizedBox(height: 12),
                _buildMaintainBenefitCard(
                  isDark,
                  textPrimary,
                  textSecondary,
                  Icons.favorite,
                  'Stay Healthy',
                  'Balanced lifestyle for long-term wellness',
                  AppColors.coral,
                  800,
                ),

                const SizedBox(height: 48),

                // CTA Button
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();

                    // Track weight goal set (maintain)
                    ref.read(posthogServiceProvider).capture(
                      eventName: 'onboarding_weight_goal_set',
                      properties: {
                        'goal_weight_kg': currentWeight,
                        'current_weight_kg': currentWeight,
                        'direction': 'maintain',
                      },
                    );

                    context.go('/training-split');
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.orange, Color(0xFFEA580C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.orange.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.rocket_launch, color: Colors.white, size: 20),
                        SizedBox(width: 10),
                        Text(
                          'Continue to Your Plan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.2),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
