part of 'plan_preview_screen.dart';

/// UI builder methods extracted from _PlanPreviewScreenState
extension _PlanPreviewScreenStateUI on _PlanPreviewScreenState {
  Widget _buildLoadingState(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated AI icon
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_pulseController.value * 0.1),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: AppColors.cyanGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.cyan.withOpacity(
                            0.3 + _pulseController.value * 0.2,
                          ),
                          blurRadius: 24 + _pulseController.value * 12,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            Text(
              AppLocalizations.of(context)!.planPreviewScreenBuildingYour4Week,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                AppLocalizations.of(
                  context,
                )!.planPreviewScreenAnalyzingYourGoalsFitness,
                style: TextStyle(
                  fontSize: 15,
                  color: textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 32),

            // Loading progress steps
            _buildLoadingSteps(textPrimary, textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalizedHeader(
    bool isDark,
    PreAuthQuizData quizData,
    Color textPrimary,
    Color textSecondary,
  ) {
    final goalDisplay = _formatGoal(quizData.goal ?? 'build_muscle');
    final surface = isDark ? const Color(0xFF141416) : AppColorsLight.elevated;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        // Signature v2: top-only orange hairline (a non-uniform 4-side border
        // + radius throws at paint — see capability_and_community_screen).
        border: const Border(top: BorderSide(color: _kSigAccent, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _kSigAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  // Spark reads "personalized by AI", not a generic person.
                  Icons.auto_awesome,
                  color: _kSigAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(
                        context,
                      )!.planPreviewScreenThisIsYourPersonalized.toUpperCase(),
                      style: TextStyle(
                        fontFamily: _kSigDisplay,
                        fontSize: 19,
                        height: 1.05,
                        letterSpacing: 0.3,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      AppLocalizations.of(
                        context,
                      )!.planPreviewScreenDesignedBasedOnYour.toUpperCase(),
                      style: TextStyle(
                        fontFamily: _kSigLabel,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.4,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // User's selections summary
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSummaryChip(Icons.flag_outlined, goalDisplay, _kSigAccent),
              _buildSummaryChip(
                Icons.calendar_today,
                AppLocalizations.of(
                  context,
                )!.planPreviewScreenDaysPerWeek(quizData.daysPerWeek ?? 3),
                _kSigAccent,
              ),
              _buildSummaryChip(
                Icons.trending_up,
                _formatLevel(quizData.fitnessLevel ?? 'intermediate'),
                _kSigAccent,
              ),
              _buildSummaryChip(
                Icons.fitness_center,
                _formatEquipment(quizData.equipment?.length ?? 0),
                _kSigAccent,
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 300.ms).slideY(begin: 0.05);
  }

  Widget _buildWorkoutDayCard(
    String dayName,
    Map<String, dynamic> workout,
    Color textPrimary,
    Color textSecondary,
  ) {
    final color = workout['color'] as Color;
    final exercises = workout['exercises'] as List<Map<String, dynamic>>;

    return ExpansionTile(
      // Expanded by default so the real exercise-library thumbnails are visible
      // at a glance — a preview that shows actual movements reads as real.
      initiallyExpanded: true,
      shape: const Border(),
      collapsedShape: const Border(),
      tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      childrenPadding: const EdgeInsetsDirectional.only(
        start: 14,
        end: 14,
        bottom: 14,
      ),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(workout['icon'] as IconData, color: color, size: 22),
      ),
      title: Row(
        children: [
          Text(
            dayName,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              workout['type'] as String,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
      subtitle: Text(
        AppLocalizations.of(context)!.planPreviewScreenExercisesMin(
          exercises.length,
          workout['duration'] as int,
        ),
        style: TextStyle(fontSize: 12, color: textSecondary),
      ),
      children: [
        // Exercises list
        ...exercises.asMap().entries.map((entry) {
          final idx = entry.key;
          final exercise = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                // Real exercise-library thumbnail (resolved by name via
                // /exercise-images/{name}); falls back to an equipment-matched
                // icon when the library has no illustration.
                ExerciseImage(
                  exerciseName: exercise['name'] as String,
                  width: 44,
                  height: 44,
                  borderRadius: 10,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise['name'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        // setsReps · muscle, in the signature letter-spaced label
                        '${exercise['setsReps']}  ·  ${exercise['muscle']}'
                            .toUpperCase(),
                        style: TextStyle(
                          fontFamily: _kSigLabel,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAchievementsSection(
    bool isDark,
    PreAuthQuizData quizData,
    Color textPrimary,
    Color textSecondary,
    Color elevatedColor,
    Color borderColor,
  ) {
    // Goal-aware 4-week narrative — the card claims "This is YOUR Personalized
    // Plan", so the milestones must reflect the user's actual goal (an
    // endurance plan should not promise "Build strength foundation").
    final milestones = _milestonesForGoal(quizData.goal ?? 'build_muscle');
    final icons = [
      Icons.school,
      Icons.foundation,
      Icons.trending_up,
      Icons.emoji_events,
    ];
    final achievements = [
      for (var i = 0; i < milestones.length; i++)
        {'week': i + 1, 'text': milestones[i], 'icon': icons[i]},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_outlined, color: AppColors.orange, size: 20),
              const SizedBox(width: 10),
              Text(
                AppLocalizations.of(
                  context,
                )!.planPreviewScreenWhatYouLlAchieve.toUpperCase(),
                style: TextStyle(
                  fontFamily: _kSigDisplay,
                  fontSize: 20,
                  letterSpacing: 0.5,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...achievements.map((achievement) {
            final isCurrentWeek = achievement['week'] == (_selectedWeek + 1);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isCurrentWeek
                          ? AppColors.orange.withOpacity(0.15)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      achievement['icon'] as IconData,
                      size: 18,
                      color: isCurrentWeek ? AppColors.orange : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!
                              .planPreviewScreenWeekNumber(
                                achievement['week'] as int,
                              )
                              .toUpperCase(),
                          style: TextStyle(
                            fontFamily: _kSigLabel,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            color: isCurrentWeek
                                ? AppColors.orange
                                : textSecondary,
                          ),
                        ),
                        Text(
                          achievement['text'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isCurrentWeek
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isCurrentWeek ? textPrimary : textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isCurrentWeek)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        AppLocalizations.of(
                          context,
                        )!.planPreviewScreenViewing.toUpperCase(),
                        style: TextStyle(
                          fontFamily: _kSigLabel,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: AppColors.orange,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.05);
  }

  Widget _buildBottomCTAs(bool isDark, Color textPrimary) {
    // Onboarding conversion v6: inside the funnel this screen is a
    // personalized pre-paywall reveal, so it gets a single forward CTA
    // into the value screen — not the guest-timer's subscribe / continue-
    // free fork.
    if (widget.fromOnboarding) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.elevated : AppColorsLight.elevated,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                context.go('/onboarding-value');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.onboardingAccent,
                foregroundColor: const Color(0xFF160B03),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                AppLocalizations.of(context)!.buttonContinue.toUpperCase(),
                style: const TextStyle(
                  fontFamily: _kSigLabel,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.5,
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevated : AppColorsLight.elevated,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Try One Workout Free button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                context.push('/demo-workout');
              },
              icon: const Icon(Icons.play_circle_filled, size: 22),
              label: Text(
                AppLocalizations.of(
                  context,
                )!.planPreviewScreenTryOneWorkoutFree,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Subscribe for full access
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      context.push('/paywall-pricing');
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.cyan),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(
                        context,
                      )!.planPreviewScreenSubscribeForFullAccess,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.cyan,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.go('/home');
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.green),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.green.withOpacity(0.08),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.planPreviewScreenContinueFree,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
