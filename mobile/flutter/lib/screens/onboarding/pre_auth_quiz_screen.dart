import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/glass_sheet.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/posthog_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/onboarding_repository.dart';
import '../../data/services/api_client.dart';
import '../../data/services/template_workout_generator.dart';
import '../../core/constants/api_constants.dart';
import 'widgets/quiz_progress_bar.dart';
import 'widgets/quiz_header.dart';
import 'widgets/quiz_continue_button.dart';
import 'widgets/quiz_multi_select.dart';
import 'widgets/quiz_fitness_level.dart';
import 'widgets/quiz_days_selector.dart';
import 'widgets/quiz_equipment.dart';
import 'widgets/quiz_training_preferences.dart';
import 'widgets/quiz_motivation.dart';
import 'widgets/quiz_nutrition_goals.dart';
import 'widgets/quiz_fasting.dart';
import 'widgets/equipment_search_sheet.dart';
import 'widgets/quiz_primary_goal.dart';
import 'widgets/quiz_muscle_focus.dart';
import 'widgets/quiz_limitations.dart';
import 'widgets/quiz_personalization_gate.dart';
import 'widgets/quiz_training_style.dart';
import 'widgets/quiz_progression_constraints.dart';
import 'widgets/quiz_nutrition_gate.dart';
import 'widgets/did_you_know_chip.dart';
import 'widgets/foldable_quiz_scaffold.dart';
import '../../core/providers/window_mode_provider.dart';
import 'plan_preview_screen.dart';

// Re-export so existing imports of PreAuthQuizData/preAuthQuizProvider from this file still work
export 'pre_auth_quiz_data.dart';

import 'pre_auth_quiz_data.dart';

part 'pre_auth_quiz_screen_ui.dart';

part 'pre_auth_quiz_screen_ext.dart';


// The PreAuthQuizData class, PreAuthQuizNotifier, and preAuthQuizProvider
// have been extracted to pre_auth_quiz_data.dart for maintainability.
// They are re-exported above so all existing imports remain valid.

/// Pre-auth quiz screen with animated questions.
/// Data model (PreAuthQuizData, PreAuthQuizNotifier, preAuthQuizProvider)
/// is in pre_auth_quiz_data.dart and re-exported from this file.
class PreAuthQuizScreen extends ConsumerStatefulWidget {
  const PreAuthQuizScreen({super.key});

  @override
  ConsumerState<PreAuthQuizScreen> createState() => _PreAuthQuizScreenState();
}

class _PreAuthQuizScreenState extends ConsumerState<PreAuthQuizScreen>
    with TickerProviderStateMixin {
  int _currentQuestion = 0;

  // Feature flag for conditional workout days screen
  static const bool _featureFlagWorkoutDays = false;

  // Dynamic total - 13 screens base, minus 1 if workout days feature disabled
  // New flow: 0-Goals, 1-Fitness+Exp, 2-Schedule, 3-WorkoutDays[COND], 4-Equipment,
  //           5-Limitations, 6-PrimaryGoal+Generate, 7-PersonalizationGate, 8-MuscleFocus,
  //           9-TrainingStyle, 10-Progression(pace), 11-NutritionGate, 12-NutritionDetails
  int get _totalQuestions {
    int total = 11; // Flow: 11 screens total (screens 11-12 nutrition gate removed)
    if (!_featureFlagWorkoutDays) {
      total -= 1; // Skip Screen 3 (Workout Days)
    }
    return total;
  }

  // Question 1: Goals (multi-select)
  final Set<String> _selectedGoals = {};
  // Question 2: Fitness Level + Training Experience
  String? _selectedLevel;
  String? _selectedTrainingExperience;
  // Question 3: Body Metrics (name, DOB, gender, height, weight, goal weight)
  String? _name;
  DateTime? _dateOfBirth;
  String? _gender;  // 'male', 'female', or 'other'
  double? _heightCm;
  double? _weightKg;
  double? _goalWeightKg;
  bool _useMetric = true;
  // Two-step weight goal
  String? _weightDirection;  // lose, gain, maintain
  double? _weightChangeAmount;  // Amount to change in kg
  String? _weightChangeRate;  // slow, moderate, fast
  // Activity level (added to fitness level screen)
  String? _selectedActivityLevel;
  // Lifestyle (Sleep quality and Obstacles)
  String? _selectedSleepQuality;
  final Set<String> _selectedObstacles = {};
  // Dietary restrictions (added to nutrition goals screen)
  final Set<String> _selectedDietaryRestrictions = {};
  // Question 4: Days per week + which days + duration
  int? _selectedDays;
  final Set<int> _selectedWorkoutDays = {};
  int? _workoutDurationMin;  // Min duration in minutes (e.g., 45 for "45-60" range)
  int? _workoutDurationMax;  // Max duration in minutes (e.g., 60 for "45-60" range)
  // Question 5: Equipment
  final Set<String> _selectedEquipment = {};
  final Set<String> _otherSelectedEquipment = {};
  final List<String> _customEquipment = [];  // User-added equipment not in predefined list
  int _dumbbellCount = 2;
  int _kettlebellCount = 1;
  String? _selectedEnvironment;  // Workout environment (home, home_gym, commercial_gym, hotel)
  // Question 6: Training Preferences (Split + Workout Type + Variety + Progression Pace)
  String? _selectedTrainingSplit;
  String? _selectedWorkoutType;
  String? _selectedWorkoutVariety;  // 'consistent' or 'varied'
  String? _selectedProgressionPace;
  // Question 7: Nutrition Goals
  final Set<String> _selectedNutritionGoals = {};
  int? _mealsPerDay;  // 4, 5, or 6 meals per day
  // Question 8: Fasting Interest & Protocol
  bool? _interestedInFasting;
  String? _selectedFastingProtocol;
  TimeOfDay _wakeTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _sleepTime = const TimeOfDay(hour: 23, minute: 0);
  // Question 9: Motivations
  final Set<String> _selectedMotivations = {};
  // Question 10: Primary Goal (muscle_hypertrophy, muscle_strength, strength_hypertrophy)
  String? _selectedPrimaryGoal;
  // Question 11: Muscle Focus Points (max 5 total)
  Map<String, int> _muscleFocusPoints = {};

  // NEW: Phase 2 and Phase 3 tracking
  bool _skipPersonalization = false;  // Track if user skipped Phase 2
  bool? _nutritionEnabled;  // Track nutrition opt-in
  final Set<String> _selectedLimitations = {'none'};  // Physical limitations (default: none)
  String? _customLimitation;  // Custom limitation text when "Other" is selected

  late AnimationController _progressController;
  late AnimationController _questionController;

  /// Calculate age from date of birth
  int _calculateAge(DateTime dateOfBirth) {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _questionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _questionController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndResetIfNeeded();
    });
  }

  Future<void> _checkAndResetIfNeeded() async {
    final quizData = ref.read(preAuthQuizProvider);
    final authState = ref.read(authStateProvider);

    if (authState.status == AuthStatus.authenticated &&
        authState.user != null &&
        !quizData.isComplete) {
      debugPrint('Resetting backend onboarding data...');
      ref.read(onboardingStateProvider.notifier).reset();

      try {
        final apiClient = ref.read(apiClientProvider);
        await apiClient.post('${ApiConstants.users}/${authState.user!.id}/reset-onboarding');
      } catch (e) {
        debugPrint('Failed to reset backend onboarding: $e');
        // Don't navigate away on failure - the user is already on the quiz
      }
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _questionController.dispose();
    super.dispose();
  }

  /// Whether the current page collects non-essential data and can be skipped.
  /// Essential pages (goals, fitnessLevel, daysPerWeek, equipment) cannot be skipped.
  bool get _isCurrentPageSkippable {
    switch (_currentQuestion) {
      case 0:  // Goals - ESSENTIAL
      case 1:  // Fitness Level - ESSENTIAL
      case 2:  // Schedule (days/week + duration) - ESSENTIAL
      case 4:  // Equipment - ESSENTIAL
        return false;
      case 3:  // Workout Days (conditional) - optional
      case 5:  // Limitations - optional
      case 6:  // Primary Goal - optional (not in isComplete)
      case 8:  // Muscle Focus - optional (Phase 2)
      case 9:  // Training Style - optional (Phase 2)
      case 10: // Progression Pace - optional (Phase 2)
        return true;
      // case 12: // Nutrition Details - optional (Phase 3) — REMOVED
      default: // Gate screens (7) have their own skip handling
        return false;
    }
  }

  /// Skip the current page without saving its data, advancing to the next screen.
  void _skipCurrentPage() {
    HapticFeedback.lightImpact();
    AnalyticsService.logScreenView('onboarding_skip_$_currentQuestion');

    // Special handling for Screen 6: skip primary goal and go straight to generate
    if (_currentQuestion == 6) {
      _generateAndShowPreview();
      return;
    }

    // Special handling for Screen 2 -> Skip Screen 3 if feature flag disabled
    if (_currentQuestion == 2 && !_featureFlagWorkoutDays) {
      setState(() => _currentQuestion = 4);
      _questionController.forward(from: 0);
      return;
    }

    // Screen 10 is now the last screen - skip means finish
    if (_currentQuestion == 10) {
      _finishOnboarding();
      return;
    }

    setState(() {
      _currentQuestion++;
    });
    _questionController.forward(from: 0);
  }

  /// Calculate progress value with phase-aware behavior
  /// Phase 1 (0-5): Show 0-100% progress
  /// Phase 2 & 3 (6+): Stay at 100% to show Phase 1 completion
  double get _progress {
    if (_currentQuestion <= 6) {
      return (_currentQuestion + 1) / 7;  // Phase 1 only (7 screens: 0-6)
    }
    return 1.0;  // User-selected: Fill to 100% for optional phases
  }

  void _nextQuestion() async {
    HapticFeedback.mediumImpact();

    await _saveCurrentQuestionData();

    // Log analytics for current screen
    AnalyticsService.logScreenView('onboarding_screen_$_currentQuestion');

    // Special handling for Screen 2 -> Skip Screen 3 if feature flag disabled
    if (_currentQuestion == 2 && !_featureFlagWorkoutDays) {
      setState(() => _currentQuestion = 4); // Skip to equipment
      _questionController.forward(from: 0);
      return;
    }

    // Special handling for Screen 6 (Primary Goal + Generate Preview)
    // Note: This should be triggered by button in _buildPrimaryGoal, not auto-advance
    // The preview screen will handle navigation to Screen 7 or 11

    // Screen 10 (Progression Pace) is now the last optional screen —
    // screens 11-12 (nutrition gate) have been removed from the flow.
    if (_currentQuestion == 10) {
      _finishOnboarding();
      return;
    }

    setState(() {
      _currentQuestion++;
    });
    _questionController.forward(from: 0);
  }

  Future<void> _saveDaysData() async {
    debugPrint('🔍 [Quiz] Saving days data: days=$_selectedDays, duration=$_workoutDurationMin-$_workoutDurationMax');
    if (_selectedDays != null) {
      await ref.read(preAuthQuizProvider.notifier).setDaysPerWeek(_selectedDays!);
    }
    if (_selectedWorkoutDays.isNotEmpty) {
      await ref.read(preAuthQuizProvider.notifier).setWorkoutDays(_selectedWorkoutDays.toList()..sort());
    }
    if (_workoutDurationMin != null && _workoutDurationMax != null) {
      await ref.read(preAuthQuizProvider.notifier).setWorkoutDuration(_workoutDurationMin!, _workoutDurationMax!);
      debugPrint('✅ [Quiz] Saved workout duration range: $_workoutDurationMin-$_workoutDurationMax min');
    } else {
      debugPrint('⚠️ [Quiz] workoutDuration is null, not saving!');
    }
  }

  Future<void> _saveEquipmentData() async {
    if (_selectedEquipment.isNotEmpty || _otherSelectedEquipment.isNotEmpty) {
      final hasFullGym = _selectedEquipment.contains('full_gym');
      final allEquipment = {..._selectedEquipment, ..._otherSelectedEquipment}.toList();
      await ref.read(preAuthQuizProvider.notifier).setEquipment(
        allEquipment,
        dumbbellCount: _selectedEquipment.contains('dumbbells') ? (hasFullGym ? 2 : _dumbbellCount) : null,
        kettlebellCount: _selectedEquipment.contains('kettlebell') ? (hasFullGym ? 2 : _kettlebellCount) : null,
        customEquipment: _customEquipment.isNotEmpty ? _customEquipment : null,
      );
    }
  }

  Future<void> _saveTrainingPreferencesData() async {
    if (_selectedTrainingSplit != null) {
      await ref.read(preAuthQuizProvider.notifier).setTrainingSplit(_selectedTrainingSplit!);
    }
    if (_selectedWorkoutType != null) {
      await ref.read(preAuthQuizProvider.notifier).setWorkoutTypePreference(_selectedWorkoutType!);
    }
    if (_selectedProgressionPace != null) {
      await ref.read(preAuthQuizProvider.notifier).setProgressionPace(_selectedProgressionPace!);
    }
    if (_selectedSleepQuality != null) {
      await ref.read(preAuthQuizProvider.notifier).setSleepQuality(_selectedSleepQuality!);
    }
    if (_selectedObstacles.isNotEmpty) {
      await ref.read(preAuthQuizProvider.notifier).setObstacles(_selectedObstacles.toList());
    }
  }

  Future<void> _saveNutritionData() async {
    if (_selectedNutritionGoals.isNotEmpty) {
      await ref.read(preAuthQuizProvider.notifier).setNutritionGoals(_selectedNutritionGoals.toList());
    }
    if (_selectedDietaryRestrictions.isNotEmpty) {
      await ref.read(preAuthQuizProvider.notifier).setDietaryRestrictions(_selectedDietaryRestrictions.toList());
    }
    if (_mealsPerDay != null) {
      await ref.read(preAuthQuizProvider.notifier).setMealsPerDay(_mealsPerDay!);
    }
  }

  Future<void> _saveFastingData() async {
    if (_interestedInFasting != null) {
      String formatTime(TimeOfDay time) {
        return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      }
      await ref.read(preAuthQuizProvider.notifier).setFastingPreferences(
        interested: _interestedInFasting!,
        protocol: _selectedFastingProtocol,
        wakeTime: formatTime(_wakeTime),
        sleepTime: formatTime(_sleepTime),
      );
    }
  }

  Future<void> _saveMotivationData() async {
    if (_selectedMotivations.isNotEmpty) {
      await ref.read(preAuthQuizProvider.notifier).setMotivations(_selectedMotivations.toList());
    }
  }

  Future<void> _savePrimaryGoalData() async {
    if (_selectedPrimaryGoal != null) {
      await ref.read(preAuthQuizProvider.notifier).setPrimaryGoal(_selectedPrimaryGoal!);
    }
  }

  Future<void> _saveMuscleFocusData() async {
    // Save even if empty - clearing all focus points is valid
    await ref.read(preAuthQuizProvider.notifier).setMuscleFocusPoints(_muscleFocusPoints);
  }

  void _previousQuestion() {
    if (_currentQuestion > 0) {
      HapticFeedback.lightImpact();
      setState(() {
        _currentQuestion--;
      });
      _questionController.forward(from: 0);
    }
  }

  bool get _canProceed {
    // 13-SCREEN FLOW (Progressive Profiling)
    // Phase 1 (Required): 0-Goals, 1-Fitness+Exp, 2-Schedule, 3-WorkoutDays[COND], 4-Equipment, 5-Limitations, 6-PrimaryGoal+Generate
    // Phase 2 (Optional): 7-PersonalizationGate, 8-MuscleFocus, 9-TrainingStyle, 10-Progression(pace)
    // Phase 3 (Optional): 11-NutritionGate, 12-NutritionDetails

    switch (_currentQuestion) {
      // PHASE 1: REQUIRED (Screens 0-6)
      case 0: // Goals (must select at least 1)
        return _selectedGoals.isNotEmpty;

      case 1: // Fitness Level + Training Experience + Activity Level (all required)
        return _selectedLevel != null &&
               _selectedTrainingExperience != null &&
               _selectedActivityLevel != null;

      case 2: // Schedule (days/week + duration both required)
        return _selectedDays != null &&
               _workoutDurationMax != null &&
               _selectedWorkoutDays.length == _selectedDays;

      case 3: // Workout Days [CONDITIONAL - only if feature flag enabled]
        if (_featureFlagWorkoutDays) {
          return _selectedWorkoutDays.length >= (_selectedDays ?? 0);
        }
        return true;

      case 4: // Equipment (must select environment + at least 1 equipment)
        return _selectedEnvironment != null &&
               (_selectedEquipment.isNotEmpty || _otherSelectedEquipment.isNotEmpty);

      case 5: // Injuries/Limitations (always valid - defaults to 'none')
        return true;

      case 6: // Primary Goal (must select 1, but "Generate" button handles navigation)
        return _selectedPrimaryGoal != null;

      // PHASE 2: OPTIONAL PERSONALIZATION (Screens 7-10, all optional)
      case 7: // Personalization Gate (no validation, just navigation)
        return true;

      case 8: // Muscle Focus Points (optional, 0-5 total)
        final totalPoints = _muscleFocusPoints.values.fold(0, (sum, val) => sum + val);
        return totalPoints <= 5;

      case 9: // Training Style (optional)
        return true;

      case 10: // Progression pace (optional)
        return true;

      // PHASE 3: OPTIONAL NUTRITION (Screens 11-12)
      case 11: // Nutrition Opt-In Gate (no validation, buttons handle navigation)
        return true;

      case 12: // Nutrition Details (all optional)
        return true;

      default:
        return false;
    }
  }

  /// Get the title for a given quiz step (used by FoldableQuizScaffold left pane).
  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'What are your fitness goals?';
      case 1:
        return "What's your current fitness level?";
      case 2:
        return 'How many days per week can you train?';
      case 3:
        return 'Which days work best?';
      case 4:
        return 'What equipment do you have access to?';
      case 5:
        return 'Any injuries or limitations?';
      case 6:
        return 'What is your primary training focus?';
      case 7:
        return 'Personalize Your Plan';
      case 8:
        return 'Would you like to give extra focus to any muscles?';
      case 9:
        return 'Training Style';
      case 10:
        return 'Progression Pace';
      case 11:
        return 'Nutrition Setup';
      case 12:
        return 'What are your nutrition goals?';
      default:
        return '';
    }
  }

  /// Get the subtitle for a given quiz step.
  String? _getStepSubtitle(int step) {
    switch (step) {
      case 0:
        return 'Select all that apply';
      case 1:
        return "Be honest - we'll adjust as you progress";
      case 2:
        return 'Consistency beats intensity - pick what you can maintain';
      case 3:
        return 'Select ${_selectedDays ?? 0} days for your workouts';
      case 4:
        return "Select all that apply - we'll design workouts around what you have";
      case 5:
        return "We'll avoid exercises that stress these areas";
      case 6:
        return 'This helps us customize your workout intensity and rep ranges';
      case 8:
        return 'Allocate up to 5 focus points to prioritize specific muscle groups';
      case 9:
        return 'Choose how you want to structure your workouts';
      case 10:
        return 'How fast do you want to progress?';
      case 12:
        return 'Select all that apply';
      default:
        return null;
    }
  }

  /// Contextual "Did you know?" hints shown below quiz content on select steps.
  String? _getDidYouKnowHint(int step) {
    switch (step) {
      case 0:
        return 'FitWiz tracks 52 skill progressions — from wall pushups to one-arm pushups.';
      case 2:
        return 'Missed a day? AI auto-adjusts your week — no guilt, no wasted workouts.';
      case 4:
        return 'FitWiz supports 23+ equipment types and adapts every exercise to your setup.';
      case 5:
        return 'AI automatically avoids 200+ exercises that could stress your injured areas.';
      case 6:
        return 'Your plan updates every month with progressive overload built in.';
      case 9:
        return 'Chat with your AI coach anytime to swap exercises or change your split.';
      case 12:
        return 'Snap a photo of your meal — AI estimates calories and macros instantly.';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final windowState = ref.watch(windowModeProvider);
    final isFoldableOpen = FoldableQuizScaffold.shouldUseFoldableLayout(windowState);

    // Onboarding always uses a rich gradient regardless of system theme
    // to maintain the glassmorphic aesthetic from the intro screen.
    final onboardingGradient = isDark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A1628), Color(0xFF0D2137), Color(0xFF061220)],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A6B5A), Color(0xFF2D9E8A), Color(0xFF1A6B5A)],
          );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: onboardingGradient),
        child: Theme(
          // Force dark theme inside quiz so all widgets render white text
          // on the gradient background (glassmorphic aesthetic).
          data: Theme.of(context).copyWith(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Colors.transparent,
            colorScheme: Theme.of(context).colorScheme.copyWith(
              brightness: Brightness.dark,
            ),
          ),
          child: SafeArea(
          child: FoldableQuizScaffold(
            headerTitle: _getStepTitle(_currentQuestion),
            headerSubtitle: _getStepSubtitle(_currentQuestion),
            headerExtra: isFoldableOpen ? _getStepHeaderExtra(context, _currentQuestion) : null,
            progressBar: QuizProgressBar(progress: _progress),
            headerOverlay: QuizHeader(
              currentQuestion: _currentQuestion,
              totalQuestions: _totalQuestions,
              canGoBack: _currentQuestion > 0,
              onBack: _previousQuestion,
              onBackToWelcome: () {
                HapticFeedback.lightImpact();
                context.go('/intro');
              },
            ),
            content: Column(
              children: [
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.1, 0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          )),
                          child: child,
                        ),
                      );
                    },
                    child: _buildCurrentQuestion(showHeader: !isFoldableOpen),
                  ),
                ),
                if (_getDidYouKnowHint(_currentQuestion) != null)
                  DidYouKnowChip(
                    key: ValueKey('hint_$_currentQuestion'),
                    text: _getDidYouKnowHint(_currentQuestion)!,
                  ),
              ],
            ),
            button: _buildActionButton(isDark),
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildDaysSelector({bool showHeader = true}) {
    return QuizDaysSelector(
      key: const ValueKey('days_selector'),
      selectedDays: _selectedDays,
      selectedWorkoutDays: _selectedWorkoutDays,
      workoutDurationMin: _workoutDurationMin,
      workoutDurationMax: _workoutDurationMax,
      showHeader: showHeader,
      onDaysChanged: (days) {
        setState(() {
          _selectedDays = days;
          if (_selectedWorkoutDays.length > days) {
            _selectedWorkoutDays.clear();
          }
        });
      },
      onWorkoutDayToggled: (day) {
        setState(() {
          if (_selectedWorkoutDays.contains(day)) {
            _selectedWorkoutDays.remove(day);
          } else if (_selectedWorkoutDays.length < (_selectedDays ?? 7)) {
            _selectedWorkoutDays.add(day);
          }
        });
      },
      onDurationChanged: (minDuration, maxDuration) {
        setState(() {
          _workoutDurationMin = minDuration;
          _workoutDurationMax = maxDuration;
        });
        // Save immediately to provider to ensure it's never lost
        ref.read(preAuthQuizProvider.notifier).setWorkoutDuration(minDuration, maxDuration);
      },
    );
  }

  Widget _buildEquipmentSelector({bool showHeader = true}) {
    return QuizEquipment(
      key: const ValueKey('equipment'),
      selectedEquipment: _selectedEquipment,
      dumbbellCount: _dumbbellCount,
      kettlebellCount: _kettlebellCount,
      onEquipmentToggled: (id) => _handleEquipmentToggle(id),
      onDumbbellCountChanged: (count) => setState(() => _dumbbellCount = count),
      onKettlebellCountChanged: (count) => setState(() => _kettlebellCount = count),
      onInfoTap: _showEquipmentInfo,
      onOtherTap: _showOtherEquipmentSheet,
      otherSelectedEquipment: _otherSelectedEquipment,
      selectedEnvironment: _selectedEnvironment,
      onEnvironmentChanged: _handleEnvironmentChange,
      showHeader: showHeader,
    );
  }

  Widget _buildTrainingPreferences() {
    return QuizTrainingPreferences(
      key: const ValueKey('training_preferences'),
      selectedSplit: _selectedTrainingSplit,
      selectedWorkoutType: _selectedWorkoutType,
      selectedProgressionPace: _selectedProgressionPace,
      selectedSleepQuality: _selectedSleepQuality,
      selectedObstacles: _selectedObstacles,
      onSplitChanged: (split) => setState(() => _selectedTrainingSplit = split),
      onWorkoutTypeChanged: (type) => setState(() => _selectedWorkoutType = type),
      onProgressionPaceChanged: (pace) => setState(() => _selectedProgressionPace = pace),
      onSleepQualityChanged: (quality) => setState(() => _selectedSleepQuality = quality),
      onObstacleToggle: (id) {
        setState(() {
          if (_selectedObstacles.contains(id)) {
            _selectedObstacles.remove(id);
          } else if (_selectedObstacles.length < 3) {
            _selectedObstacles.add(id);
          }
        });
      },
    );
  }

  Widget _buildFasting() {
    return QuizFasting(
      key: const ValueKey('fasting'),
      interestedInFasting: _interestedInFasting,
      selectedProtocol: _selectedFastingProtocol,
      onInterestChanged: (interested) => setState(() => _interestedInFasting = interested),
      onProtocolChanged: (protocol) => setState(() => _selectedFastingProtocol = protocol),
      // Pass user data for recommendations
      fitnessLevel: _selectedLevel,
      weightDirection: _weightDirection,
      activityLevel: _selectedActivityLevel,
      // Sleep schedule
      wakeTime: _wakeTime,
      sleepTime: _sleepTime,
      onWakeTimeChanged: (time) => setState(() => _wakeTime = time),
      onSleepTimeChanged: (time) => setState(() => _sleepTime = time),
      // Meals per day for validation
      mealsPerDay: _mealsPerDay,
      onMealsPerDayChanged: (meals) => setState(() => _mealsPerDay = meals),
    );
  }

  Widget _buildMotivation() {
    return QuizMotivation(
      key: const ValueKey('motivation'),
      selectedMotivations: _selectedMotivations,
      onToggle: (id) {
        setState(() {
          if (_selectedMotivations.contains(id)) {
            _selectedMotivations.remove(id);
          } else {
            _selectedMotivations.add(id);
          }
        });
      },
    );
  }

  Widget _buildPrimaryGoal({bool showHeader = true}) {
    final options = [
      {
        'id': 'muscle_hypertrophy',
        'label': 'Hypertrophy',  // ← SHORTENED from "Muscle Hypertrophy"
        'description': '8–12 reps • muscle size',  // ← CONDENSED to concise format
        'icon': Icons.fitness_center_rounded,
        'color': AppColors.orange, // Vibrant orange for visibility
      },
      {
        'id': 'muscle_strength',
        'label': 'Strength',  // ← SHORTENED from "Muscle Strength"
        'description': '3–6 reps • heavy & powerful',  // ← CONDENSED
        'icon': Icons.bolt_rounded,
        'color': const Color(0xFF3B82F6), // Bright blue
      },
      {
        'id': 'strength_hypertrophy',
        'label': 'Balanced',  // ← SHORTENED from "Both Strength & Hypertrophy"
        'description': '6–10 reps • size + strength',  // ← CONDENSED
        'icon': Icons.all_inclusive_rounded,
        'color': const Color(0xFF8B5CF6), // Vibrant purple
      },
      {
        'id': 'endurance',
        'label': 'Endurance',  // ← KEEP as-is
        'description': '12+ reps • stamina',  // ← CONDENSED
        'icon': Icons.directions_run_rounded,
        'color': const Color(0xFF10B981), // Vibrant green
      },
    ];

    return QuizPrimaryGoal(
      key: const ValueKey('primary_goal'),
      question: 'What is your primary training focus?',
      subtitle: 'This helps us customize your workout intensity and rep ranges',
      options: options,
      selectedValue: _selectedPrimaryGoal,
      onSelect: (value) {
        setState(() => _selectedPrimaryGoal = value);
      },
      showHeader: showHeader,
    );
  }

  Widget _buildMuscleFocus({bool showHeader = true}) {
    return QuizMuscleFocus(
      key: const ValueKey('muscle_focus'),
      question: 'Would you like to give extra focus to any muscles?',
      subtitle: 'Allocate up to 5 focus points to prioritize specific muscle groups in your workouts',
      showHeader: showHeader,
      focusPoints: _muscleFocusPoints,
      onPointsChanged: (points) {
        setState(() => _muscleFocusPoints = points);
      },
    );
  }

  Widget _buildGoalQuestion({bool showHeader = true}) {
    final goals = [
      {'id': 'build_muscle', 'label': 'Build Muscle', 'icon': Icons.fitness_center, 'color': AppColors.orange},
      {'id': 'lose_weight', 'label': 'Lose Weight', 'icon': Icons.monitor_weight_outlined, 'color': AppColors.orange},
      {'id': 'increase_strength', 'label': 'Get Stronger', 'icon': Icons.bolt, 'color': AppColors.orange},
      {'id': 'improve_endurance', 'label': 'Build Endurance', 'icon': Icons.directions_run, 'color': AppColors.purple},
      {'id': 'stay_active', 'label': 'Stay Active', 'icon': Icons.favorite_outline, 'color': AppColors.green},
      {'id': 'athletic_performance', 'label': 'Athletic Performance', 'icon': Icons.sports_martial_arts, 'color': const Color(0xFF3B82F6)}, // Bright blue
    ];

    return QuizMultiSelect(
      key: const ValueKey('goals'),
      question: 'What are your fitness goals?',
      subtitle: 'Select all that apply',
      options: goals,
      selectedValues: _selectedGoals,
      onToggle: (value) {
        setState(() {
          if (_selectedGoals.contains(value)) {
            _selectedGoals.remove(value);
          } else {
            _selectedGoals.add(value);
          }
        });
      },
      showHeader: showHeader,
    );
  }

  void _handleEquipmentToggle(String id) {
    setState(() {
      if (id == 'full_gym') {
        if (_selectedEquipment.contains('full_gym')) {
          _selectedEquipment.clear();
        } else {
          _selectedEquipment.clear();
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
            'full_gym',
          ]);
        }
      } else {
        if (_selectedEquipment.contains(id)) {
          _selectedEquipment.remove(id);
          _selectedEquipment.remove('full_gym');
        } else {
          _selectedEquipment.add(id);
        }
      }
    });
  }

  void _showOtherEquipmentSheet() {
    showGlassSheet(
      context: context,
      builder: (ctx) => GlassSheet(
        child: EquipmentSearchSheet(
        selectedEquipment: _otherSelectedEquipment,
        allEquipment: EquipmentSearchSheet.databaseEquipment,
        initialCustomEquipment: _customEquipment,
        onSelectionChanged: (selected) {
          setState(() {
            _otherSelectedEquipment.clear();
            _otherSelectedEquipment.addAll(selected);
          });
        },
        onCustomEquipmentChanged: (customList) {
          setState(() {
            _customEquipment.clear();
            _customEquipment.addAll(customList);
          });
        },
        ),
      ),
    );
  }
}
