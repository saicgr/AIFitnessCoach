part of 'pre_auth_quiz_screen.dart';

/// Map a selected fitness level to a reasonable default training-experience
/// bucket. IDs must match `_experienceOptions` in `quiz_fitness_level.dart`.
/// Used to pre-fill the second question on the combined Level+Experience
/// screen so the user sees a sensible default they can still change.
String? _defaultExperienceForLevel(String level) {
  switch (level) {
    case 'beginner':
      return 'less_than_6_months';
    case 'intermediate':
      return '6_months_to_2_years';
    case 'advanced':
      return '2_to_5_years';
    default:
      return null;
  }
}

/// Methods extracted from _PreAuthQuizScreenState
extension __PreAuthQuizScreenStateExt on _PreAuthQuizScreenState {

  Future<void> _saveCurrentQuestionData() async {
    // 13-SCREEN FLOW (Progressive Profiling)
    // Phase 1 (Required): 0-Goals, 1-Fitness+Experience, 2-Schedule, 3-WorkoutDays[COND], 4-Equipment, 5-Limitations, 6-PrimaryGoal+Generate
    // Phase 2 (Optional): 7-PersonalizationGate, 8-MuscleFocus, 9-TrainingStyle, 10-Progression(pace)
    // Phase 3 (Optional): 11-NutritionGate, 12-NutritionDetails

    switch (_currentQuestion) {
      // PHASE 1: REQUIRED (Screens 0-6)
      case 0: // Goals (multi-select)
        if (_selectedGoals.isNotEmpty) {
          await ref.read(preAuthQuizProvider.notifier).setGoals(_selectedGoals.toList());
        }
        break;

      case 1: // Fitness Level + Training Experience (optional)
        if (_selectedLevel != null) {
          await ref.read(preAuthQuizProvider.notifier).setFitnessLevel(_selectedLevel!);
        }
        if (_selectedTrainingExperience != null) {
          await ref.read(preAuthQuizProvider.notifier).setTrainingExperience(_selectedTrainingExperience!);
        }
        if (_selectedActivityLevel != null) {
          await ref.read(preAuthQuizProvider.notifier).setActivityLevel(_selectedActivityLevel!);
        }
        break;

      case 2: // Schedule (days/week + duration)
        await _saveDaysData();
        break;

      case 3: // Workout Days [CONDITIONAL - only if feature flag enabled]
        if (_PreAuthQuizScreenState._featureFlagWorkoutDays && _selectedWorkoutDays.isNotEmpty) {
          await ref.read(preAuthQuizProvider.notifier).setWorkoutDays(_selectedWorkoutDays.toList()..sort());
        }
        break;

      case 4: // Equipment (environment + equipment list)
        await _saveEquipmentData();
        if (_selectedEnvironment != null) {
          await ref.read(preAuthQuizProvider.notifier).setWorkoutEnvironment(_selectedEnvironment!);
        }
        break;

      case 5: // Injuries/Limitations (NEW POSITION - moved from old Screen 9)
        if (_selectedLimitations.isNotEmpty) {
          final limitationsList = _selectedLimitations.toList();
          if (_selectedLimitations.contains('other') && _customLimitation != null && _customLimitation!.isNotEmpty) {
            limitationsList.remove('other');
            limitationsList.add('other: $_customLimitation');
          }
          await ref.read(preAuthQuizProvider.notifier).setLimitations(limitationsList);
        }
        break;

      case 6: // Primary Goal (saved when user clicks "Generate My First Workout")
        if (_selectedPrimaryGoal != null) {
          await ref.read(preAuthQuizProvider.notifier).setPrimaryGoal(_selectedPrimaryGoal!);
        }
        break;

      // PHASE 2: OPTIONAL PERSONALIZATION (Screens 7-10)
      case 7: // Personalization Gate (no data to save, just navigation)
        break;

      case 8: // Muscle Focus Points
        await _saveMuscleFocusData();
        break;

      case 9: // Training Style (split + workout type + variety)
        if (_selectedTrainingSplit != null) {
          await ref.read(preAuthQuizProvider.notifier).setTrainingSplit(_selectedTrainingSplit!);
        }
        if (_selectedWorkoutType != null) {
          await ref.read(preAuthQuizProvider.notifier).setWorkoutTypePreference(_selectedWorkoutType!);
        }
        if (_selectedWorkoutVariety != null) {
          await ref.read(preAuthQuizProvider.notifier).setWorkoutVariety(_selectedWorkoutVariety!);
        }
        break;

      case 10: // Progression pace only (limitations moved to Screen 5)
        if (_selectedProgressionPace != null) {
          await ref.read(preAuthQuizProvider.notifier).setProgressionPace(_selectedProgressionPace!);
        }
        break;

      // PHASE 3: OPTIONAL NUTRITION (Screens 11-12) — REMOVED
      // case 11: // Nutrition Opt-In Gate (handled in button callbacks)
      //   break;
      // case 12: // Nutrition Details (merged nutrition + fasting)
      //   await _saveNutritionData();
      //   await _saveFastingData();
      //   break;
    }
  }


  /// Generate workout preview and navigate to plan preview screen
  ///
  /// Shows instant template-based preview without waiting for AI generation.
  /// Background AI generation is NOT started here because the user hasn't
  /// authenticated yet (this is a pre-auth quiz). Real AI generation happens
  /// later in WorkoutGenerationScreen after sign-in.
  Future<void> _generateAndShowPreview() async {
    try {
      // Save current primary goal selection
      await _saveCurrentQuestionData();

      // Log analytics
      AnalyticsService.logWorkoutGenerated(
        primaryGoal: _selectedPrimaryGoal ?? 'unknown',
        duration: _workoutDurationMax ?? 60,
        equipment: _selectedEquipment.toList(),
      );

      // Get current quiz data
      final quizData = ref.read(preAuthQuizProvider);

      if (!mounted) return;

      // Generate instant template-based workout preview
      final templateWorkout = TemplateWorkoutGenerator.generateTemplateWorkout(quizData);

      debugPrint('✅ [Onboarding] Generated template workout: ${templateWorkout.name}');
      debugPrint('   Exercises: ${templateWorkout.exercises.length}');
      debugPrint('   Duration: ${templateWorkout.estimatedDurationMinutes} min');

      // Show plan preview immediately with template workout
      final navigator = Navigator.of(context);
      await navigator.push(
        MaterialPageRoute(
          builder: (_) => PlanPreviewScreen(
            quizData: quizData,
            generatedWorkout: templateWorkout,
            onContinue: () {
              navigator.pop();
              if (!mounted) return;
              setState(() => _currentQuestion = 7); // Go to personalization gate
              _questionController.forward(from: 0);
            },
            onStartNow: () {
              navigator.pop();
              if (!mounted) return;
              setState(() => _skipPersonalization = true);
              _finishOnboarding(); // Screens 11-12 (nutrition gate) removed — finish directly
            },
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ [Onboarding] Failed to generate preview: $e');
      // Show error and stay on current screen
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate workout: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }


  /// Finish onboarding and navigate to coach selection
  Future<void> _finishOnboarding() async {
    try {
      // Save final screen data
      await _saveCurrentQuestionData();

      // Mark onboarding as complete
      await ref.read(preAuthQuizProvider.notifier).setIsComplete(true);

      // Log analytics
      final skippedScreens = _skipPersonalization ? 4 : 0; // Screens 7-10 skipped
      AnalyticsService.logOnboardingCompleted(
        totalScreens: _totalQuestions,
        skippedScreens: skippedScreens,
        nutritionOptedIn: _nutritionEnabled ?? false,
        personalizationCompleted: !_skipPersonalization,
      );

      // Track quiz completion
      ref.read(posthogServiceProvider).capture(
        eventName: 'onboarding_quiz_completed',
        properties: {
          'total_screens': _totalQuestions,
          'skipped_screens': skippedScreens,
          'personalization_completed': !_skipPersonalization,
        },
      );

      // Navigate to sign-in screen (user must create account before coach selection)
      // Flow: Pre-Auth Quiz → Sign In → Coach Selection → Paywall → Home
      if (mounted) {
        context.go('/sign-in');
      }
    } catch (e) {
      debugPrint('❌ [Onboarding] Failed to finish onboarding: $e');
      // Show error but still try to navigate
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save onboarding data. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  /// Extra widget shown in the scaffold's left pane (foldable only).
  /// Used for info buttons that belong near the question title.
  Widget? _getStepHeaderExtra(BuildContext context, int step) {
    final textSecondary = OnboardingTheme.of(context).textSecondary;

    Widget buildTip({
      required IconData icon,
      required Color color,
      required String title,
      required String body,
      List<({IconData icon, String text})>? bullets,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 16, color: color),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (bullets != null) ...[
            const SizedBox(height: 12),
            ...bullets.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(b.icon, size: 15, color: color.withValues(alpha: 0.7)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          b.text,
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      );
    }

    switch (step) {
      case 0:
        return buildTip(
          icon: Icons.flag_rounded,
          color: AppColors.onboardingAccent,
          title: 'Your goals shape everything',
          body: 'We use your goals to determine training split, exercise selection, and how fast you progress.',
          bullets: [
            (icon: Icons.fitness_center, text: 'Exercise type & volume'),
            (icon: Icons.speed, text: 'Intensity & rest periods'),
            (icon: Icons.trending_up, text: 'Weekly progression rate'),
          ],
        );
      case 1:
        return buildTip(
          icon: Icons.person_outline,
          color: const Color(0xFF3B82F6),
          title: 'Calibrating your baseline',
          body: 'Fitness level helps set the right starting point — proper weights, rep ranges, and exercise complexity.',
        );
      case 2:
        return buildTip(
          icon: Icons.calendar_today_rounded,
          color: AppColors.green,
          title: 'Consistency beats intensity',
          body: 'We\'ll build the optimal training split for your schedule. More days isn\'t always better — recovery matters.',
          bullets: [
            (icon: Icons.looks_two, text: '2-3 days → Full Body'),
            (icon: Icons.looks_4, text: '4 days → Upper/Lower'),
            (icon: Icons.looks_5, text: '5-6 days → Push/Pull/Legs'),
          ],
        );
      case 3:
        return buildTip(
          icon: Icons.event_available,
          color: const Color(0xFFA855F7),
          title: 'Smart scheduling',
          body: 'Your chosen days help us space workouts optimally for muscle recovery between sessions.',
        );
      case 4:
        return buildTip(
          icon: Icons.home_rounded,
          color: AppColors.cyan,
          title: 'Matched to your setup',
          body: 'Every exercise will be chosen based on what equipment you actually have. No substitutions needed.',
          bullets: [
            (icon: Icons.check_circle_outline, text: 'Only exercises you can do'),
            (icon: Icons.swap_horiz, text: 'Smart alternatives when needed'),
          ],
        );
      case 5:
        return buildTip(
          icon: Icons.shield_outlined,
          color: AppColors.green,
          title: 'Safety first',
          body: 'Telling us about injuries ensures we avoid exercises that could cause pain or setbacks.',
        );
      case 6:
        return QuizPrimaryGoal.buildInfoButton(context);
      case 7:
        return buildTip(
          icon: Icons.tune_rounded,
          color: AppColors.onboardingAccent,
          title: 'Fine-tuning your plan',
          body: 'These optional details make your workouts even more personalized. Skip if you prefer AI defaults.',
        );
      case 8:
        return buildTip(
          icon: Icons.accessibility_new,
          color: const Color(0xFFEF4444),
          title: 'Target weak points',
          body: 'Selected muscles get extra volume and priority placement in your workouts.',
        );
      case 9:
        return buildTip(
          icon: Icons.view_week_rounded,
          color: const Color(0xFF3B82F6),
          title: 'Training philosophy',
          body: 'Each style structures your week differently. Let AI decide if you\'re unsure — it adapts to your schedule.',
        );
      case 10:
        return buildTip(
          icon: Icons.speed_rounded,
          color: AppColors.green,
          title: 'Your progression speed',
          body: 'Controls how quickly weights, reps, and difficulty increase each week.',
        );
      case 11:
      case 12:
        return buildTip(
          icon: Icons.restaurant_rounded,
          color: AppColors.onboardingAccent,
          title: 'Fuel your training',
          body: 'Nutrition tracking is optional but powerful. AI calculates macros based on your goals and activity level.',
        );
      default:
        return null;
    }
  }


  Widget _buildCurrentQuestion({bool showHeader = true}) {
    // 13-SCREEN FLOW (Progressive Profiling)
    // Phase 1 (Required): 0-Goals, 1-Fitness+Exp, 2-Schedule, 3-WorkoutDays[COND], 4-Equipment, 5-Limitations, 6-PrimaryGoal+Generate
    // Phase 2 (Optional): 7-PersonalizationGate, 8-MuscleFocus, 9-TrainingStyle, 10-Progression(pace)
    // Phase 3 (Optional): 11-NutritionGate, 12-NutritionDetails

    switch (_currentQuestion) {
      // PHASE 1: REQUIRED (Screens 0-6)
      case 0: // Goals (multi-select)
        return _buildGoalQuestion(showHeader: showHeader);

      case 1: // Fitness Level + Training Experience (combined, experience optional)
        return QuizFitnessLevel(
          key: const ValueKey('fitness_level'),
          selectedLevel: _selectedLevel,
          selectedExperience: _selectedTrainingExperience,
          selectedActivityLevel: _selectedActivityLevel,
          onLevelChanged: (level) => setState(() {
            _selectedLevel = level;
            // Seed a reasonable experience bucket only if the user hasn't
            // picked one yet — they can still override. Mapping:
            //   beginner → <6mo, intermediate → 6mo-2yrs, advanced → 2-5yrs.
            _selectedTrainingExperience ??= _defaultExperienceForLevel(level);
          }),
          onExperienceChanged: (exp) => setState(() => _selectedTrainingExperience = exp),
          onActivityLevelChanged: (level) => setState(() => _selectedActivityLevel = level),
          showHeader: showHeader,
        );

      case 2: // Schedule (days/week + duration combined)
        return _buildDaysSelector(showHeader: showHeader);

      case 3: // Workout Days [CONDITIONAL - only if feature flag enabled]
        if (_PreAuthQuizScreenState._featureFlagWorkoutDays) {
          return _buildWorkoutDaysSelector(showHeader: showHeader);
        }
        return const SizedBox.shrink();

      case 4: // Equipment (2-step: environment + equipment list)
        return _buildEquipmentSelector(showHeader: showHeader);

      case 5: // Injuries/Limitations (NEW POSITION - moved from old Phase 2)
        return QuizLimitations(
          key: const ValueKey('limitations'),
          selectedLimitations: _selectedLimitations.toList(),
          customLimitation: _customLimitation,
          onLimitationsChanged: (limitations) => setState(() {
            _selectedLimitations.clear();
            _selectedLimitations.addAll(limitations);
          }),
          onCustomLimitationChanged: (customText) => setState(() {
            _customLimitation = customText;
          }),
          showHeader: showHeader,
        );

      case 6: // Training Focus (Primary Goal) + Generate Preview
        return _buildPrimaryGoal(showHeader: showHeader);

      // PHASE 2: OPTIONAL PERSONALIZATION (Screens 7-10, shown AFTER preview)
      case 7: // Personalization Gate
        return QuizPersonalizationGate(
          key: const ValueKey('personalization_gate'),
          onPersonalize: () {
            HapticFeedback.mediumImpact();
            setState(() => _skipPersonalization = false);
            _nextQuestion();
          },
          onSkip: () {
            HapticFeedback.selectionClick();
            AnalyticsService.logPersonalizationSkipped();
            setState(() => _skipPersonalization = true);
            _finishOnboarding(); // Screens 11-12 (nutrition gate) removed — finish directly
          },
        );

      case 8: // Muscle Focus Points
        return _buildMuscleFocus(showHeader: showHeader);

      case 9: // Training Style (workout type + variety only; split moved to dedicated screen)
        return QuizTrainingStyle(
          key: const ValueKey('training_style'),
          selectedSplit: _selectedTrainingSplit,
          selectedWorkoutType: _selectedWorkoutType,
          selectedWorkoutVariety: _selectedWorkoutVariety,
          daysPerWeek: _selectedDays ?? 4,
          onSplitChanged: (split) => setState(() => _selectedTrainingSplit = split),
          onWorkoutTypeChanged: (type) => setState(() => _selectedWorkoutType = type),
          onWorkoutVarietyChanged: (variety) => setState(() => _selectedWorkoutVariety = variety),
          onDaysPerWeekChanged: (newDays) async {
            setState(() => _selectedDays = newDays);
            await ref.read(preAuthQuizProvider.notifier).setDaysPerWeek(newDays);
          },
          showHeader: showHeader,
          showSplitSection: false,
        );

      case 10: // Progression pace only (limitations already collected in Screen 5)
        return QuizProgressionConstraints(
          key: const ValueKey('progression_pace'),
          selectedPace: _selectedProgressionPace,
          fitnessLevel: _selectedLevel ?? 'intermediate',
          onPaceChanged: (pace) => setState(() => _selectedProgressionPace = pace),
          showHeader: showHeader,
        );

      // PHASE 3: OPTIONAL NUTRITION (Screens 11-12) — REMOVED
      // case 11: // Nutrition Opt-In Gate
      //   return QuizNutritionGate(...);
      // case 12: // Nutrition Details (merged nutrition + fasting)
      //   return _buildNutritionGoals(showHeader: showHeader);

      default:
        return const SizedBox.shrink();
    }
  }


  Widget _buildDayCheckbox(int day, String label, Duration delay) {
    final t = OnboardingTheme.of(context);
    final isSelected = _selectedWorkoutDays.contains(day);
    final canSelect = _selectedWorkoutDays.length < (_selectedDays ?? 7);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          if (_selectedWorkoutDays.contains(day)) {
            _selectedWorkoutDays.remove(day);
          } else if (canSelect || isSelected) {
            _selectedWorkoutDays.add(day);
          }
        });
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: t.cardSelectedGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isSelected ? null : t.cardFill,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? t.borderSelected : t.borderDefault,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? t.checkIcon : t.checkBorderUnselected,
                      width: 2,
                    ),
                    color: isSelected ? t.checkBg : Colors.transparent,
                  ),
                  child: isSelected
                      ? Icon(Icons.check, size: 16, color: t.checkIcon)
                      : null,
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: t.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: delay).slideX(begin: -0.05);
  }


  Widget _buildNutritionGoals({bool showHeader = true}) {
    return QuizNutritionGoals(
      key: const ValueKey('nutrition_goals'),
      selectedGoals: _selectedNutritionGoals,
      selectedRestrictions: _selectedDietaryRestrictions,
      showHeader: showHeader,
      onToggle: (id) {
        setState(() {
          if (_selectedNutritionGoals.contains(id)) {
            _selectedNutritionGoals.remove(id);
          } else {
            _selectedNutritionGoals.add(id);
          }
        });
      },
      onRestrictionToggle: (id) {
        setState(() {
          // Handle "none" special case - clears all other restrictions
          if (id == 'none') {
            if (_selectedDietaryRestrictions.contains('none')) {
              _selectedDietaryRestrictions.remove('none');
            } else {
              _selectedDietaryRestrictions.clear();
              _selectedDietaryRestrictions.add('none');
            }
          } else {
            // Remove "none" if selecting another restriction
            _selectedDietaryRestrictions.remove('none');
            if (_selectedDietaryRestrictions.contains(id)) {
              _selectedDietaryRestrictions.remove(id);
            } else {
              _selectedDietaryRestrictions.add(id);
            }
          }
        });
      },
      // Meals per day
      mealsPerDay: _mealsPerDay,
      onMealsPerDayChanged: (meals) => setState(() => _mealsPerDay = meals),
      // Pass user data for nutrition targets preview (calculate age from DOB)
      age: _dateOfBirth != null ? _calculateAge(_dateOfBirth!) : null,
      gender: _gender,
      heightCm: _heightCm,
      weightKg: _weightKg,
      activityLevel: _selectedActivityLevel,
      weightDirection: _weightDirection,
      weightChangeRate: _weightChangeRate,
      goalWeightKg: _goalWeightKg,
      workoutDaysPerWeek: _selectedDays,
    );
  }


  /// Handle environment selection - pre-populates equipment based on environment
  void _handleEnvironmentChange(String envId) {
    setState(() {
      // If tapping the same environment, deselect it and clear equipment
      if (_selectedEnvironment == envId) {
        _selectedEnvironment = null;
        _selectedEquipment.clear();
        _otherSelectedEquipment.clear();
        return;
      }

      _selectedEnvironment = envId;

      // Pre-populate equipment based on environment
      _selectedEquipment.clear();
      _otherSelectedEquipment.clear();

      switch (envId) {
        case 'home':
          _selectedEquipment.addAll(['bodyweight']);
          break;
        case 'home_gym':
          _selectedEquipment.addAll([
            'bodyweight',
            'dumbbells',
            'barbell',
            'resistance_bands',
            'pull_up_bar',
            'kettlebell',
          ]);
          break;
        case 'commercial_gym':
          _selectedEquipment.addAll([
            'bodyweight',
            'dumbbells',
            'barbell',
            'resistance_bands',
            'pull_up_bar',
            'kettlebell',
            'cable_machine',
            'bench',
            'squat_rack',
            'dip_station',
            'smith_machine',
            'leg_press',
            'lat_pulldown',
            'medicine_ball',
            'trx',
            'full_gym',
          ]);
          break;
        case 'hotel':
          _selectedEquipment.addAll([
            'bodyweight',
            'dumbbells',
            'resistance_bands',
          ]);
          break;
      }
    });
  }


  void _showEquipmentInfo(BuildContext context, String equipmentId, bool isDark) {
    final t = OnboardingTheme.of(context);
    final textPrimary = t.textPrimary;
    final textSecondary = t.textSecondary;

    String title;
    String description;
    if (equipmentId == 'dumbbells') {
      title = 'Dumbbell Count';
      description = 'Single dumbbell: Unilateral exercises only (one arm at a time)\n\n'
          'Pair of dumbbells: Full range of exercises including bilateral movements';
    } else {
      title = 'Kettlebell Count';
      description = 'Single kettlebell: Perfect for swings, Turkish get-ups, and single-arm work\n\n'
          'Multiple kettlebells: Allows for double KB exercises and weight progression';
    }

    showGlassSheet(
      context: context,
      builder: (ctx) => GlassSheet(
        child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.accent),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Got it'),
                  ),
                ),
              ],
            ),
        ),
      ),
    );
  }

}
