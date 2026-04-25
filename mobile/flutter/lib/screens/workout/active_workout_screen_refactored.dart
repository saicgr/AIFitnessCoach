/// Active Workout Screen — state class and initialization.
/// Business logic lives in mixins/ (flow, sets, navigation, sheets, UI, AI, PRs, timer).
library;

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/set_progression.dart';
import '../../core/providers/favorites_provider.dart';
import '../../core/providers/sound_preferences_provider.dart';
import '../../core/providers/tts_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/weight_increments_provider.dart';
import '../../core/providers/window_mode_provider.dart';
import '../../core/providers/active_workout_phase_provider.dart';
import '../../core/providers/workout_mini_player_provider.dart';
import '../../core/providers/workout_ui_mode_provider.dart';
import '../../core/services/fatigue_service.dart';
import '../../core/services/posthog_service.dart';
import '../../core/services/pre_set_insight_engine.dart';
import '../../core/services/weight_suggestion_service.dart';
import '../../core/services/workout_tour_steps.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../widgets/app_tour/app_tour_controller.dart';
import '../../core/utils/default_weights.dart';
import '../../data/models/exercise.dart';
import '../../data/models/parsed_exercise.dart';
import '../../data/models/rest_suggestion.dart';
import '../../data/models/smart_weight_suggestion.dart';
import '../../data/models/workout.dart';
import '../../data/providers/gym_profile_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/services/api_client.dart';
import '../../data/services/exercise_history_batch_service.dart';
import '../../data/services/live_activity_service.dart';
import '../../data/services/pr_detection_service.dart';
import '../../data/services/workout_notification_service.dart';
import '../../screens/onboarding/widgets/foldable_quiz_scaffold.dart';
import '../../widgets/glass_sheet.dart';
import '../settings/equipment/environment_list_screen.dart';
import 'controllers/workout_timer_controller.dart';
import 'foldable/foldable_warmup_layout.dart';
import 'models/workout_state.dart';
import 'widgets/action_chips_row.dart';
import 'widgets/quick_adjust_sheet.dart';
import 'widgets/ai_input_preview_sheet.dart';
import 'widgets/barbell_plate_indicator.dart';
import 'widgets/exercise_add_sheet.dart';
import 'widgets/exercise_options_sheet.dart' show RepProgressionType;
import 'widgets/exercise_swap_sheet.dart';
import 'widgets/fatigue_alert_modal.dart';
import 'widgets/set_tracking_table.dart';
import 'widgets/stretch_phase_screen.dart';
import 'widgets/warmup_phase_screen.dart';
// Prime sheet kept for re-enable when BLE / voice pre-prompt is needed.
// import 'widgets/workout_permissions_prime_sheet.dart';
import 'mixins/pr_manager_mixin.dart';
import 'mixins/timer_rest_mixin.dart';
import 'mixins/ai_features_mixin.dart';
import 'mixins/set_logging_mixin.dart';
import 'mixins/exercise_navigation_mixin.dart';
import 'mixins/workout_flow_mixin.dart';
import 'mixins/workout_sheets_mixin.dart';
import 'mixins/workout_ui_builders_mixin.dart';
import 'widgets/exercise_info_sheet.dart';
import 'widgets/breathing_guide_sheet.dart';
import 'shared/exercise_instruction_copy.dart';
import '../../core/services/exercise_info_service.dart';

part 'exercise_details_sheet_content.dart';
part 'progression_selector_sheet.dart';

/// Active workout screen with modular composition
class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  final Workout workout;
  final String? challengeId;
  final Map<String, dynamic>? challengeData;

  const ActiveWorkoutScreen({
    super.key,
    required this.workout,
    this.challengeId,
    this.challengeData,
  });

  @override
  ConsumerState<ActiveWorkoutScreen> createState() =>
      _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState
    extends ConsumerState<ActiveWorkoutScreen>
    with WidgetsBindingObserver, PRManagerMixin, TimerRestMixin, AIFeaturesMixin, SetLoggingMixin, ExerciseNavigationMixin, WorkoutFlowMixin, WorkoutSheetsMixin, WorkoutUIBuildersMixin {
  // ── Concrete overrides for abstract declarations in mixins ──
  // These delegate to extension methods that provide the actual logic.

  @override
  void showSupersetSheet() => WorkoutSheetsMixinUI(this).showSupersetSheet();

  @override
  void applyProgressionTargets(int exerciseIndex, SetProgressionPattern pattern, {double? overrideWeight}) =>
      SetLoggingMixinUI(this).applyProgressionTargets(exerciseIndex, pattern, overrideWeight: overrideWeight);

  @override
  void showBarTypeSelectorImpl(WorkoutExercise exercise) =>
      WorkoutSheetsMixinUI(this).showBarTypeSelectorImpl(exercise);

  @override
  void showNumberInputDialogImpl(TextEditingController controller, bool isDecimal) =>
      WorkoutSheetsMixinUI(this).showNumberInputDialogImpl(controller, isDecimal);

  @override
  void showProgressionPicker(int exerciseIndex) =>
      WorkoutSheetsMixinUI(this).showProgressionPicker(exerciseIndex);

  @override
  void onSupersetFromDrag(int sourceIndex, int targetIndex) {
    // Implementation from ExerciseNavigationMixin part file
    // Handled via ExerciseNavigationMixin's part file methods
    HapticFeedback.mediumImpact();
    final draggedExercise = exercises[sourceIndex];
    final targetExercise = exercises[targetIndex];
    final existingGroupId = targetExercise.supersetGroup;
    final draggedGroupId = draggedExercise.supersetGroup;
    int groupId;
    String snackbarMessage;

    if (existingGroupId != null) {
      groupId = existingGroupId;
      int maxOrder = 0;
      for (final ex in exercises) {
        if (ex.supersetGroup == groupId && ex.supersetOrder != null) {
          if (ex.supersetOrder! > maxOrder) maxOrder = ex.supersetOrder!;
        }
      }
      final updatedList = List<WorkoutExercise>.from(exercises);
      updatedList[sourceIndex] = draggedExercise.copyWith(
        supersetGroup: groupId,
        supersetOrder: maxOrder + 1,
      );
      setState(() => exercises = updatedList);
      snackbarMessage = '${draggedExercise.name} added to superset';
    } else if (draggedGroupId != null) {
      groupId = draggedGroupId;
      final updatedList = List<WorkoutExercise>.from(exercises);
      int maxOrder = 0;
      for (final ex in exercises) {
        if (ex.supersetGroup == groupId && ex.supersetOrder != null) {
          if (ex.supersetOrder! > maxOrder) maxOrder = ex.supersetOrder!;
        }
      }
      updatedList[targetIndex] = targetExercise.copyWith(
        supersetGroup: groupId,
        supersetOrder: maxOrder + 1,
      );
      setState(() => exercises = updatedList);
      snackbarMessage = '${targetExercise.name} added to superset';
    } else {
      groupId = DateTime.now().millisecondsSinceEpoch;
      final updatedList = List<WorkoutExercise>.from(exercises);
      updatedList[sourceIndex] = draggedExercise.copyWith(
        supersetGroup: groupId,
        supersetOrder: 0,
      );
      updatedList[targetIndex] = targetExercise.copyWith(
        supersetGroup: groupId,
        supersetOrder: 1,
      );
      setState(() => exercises = updatedList);
      snackbarMessage = 'Superset created: ${draggedExercise.name} + ${targetExercise.name}';
    }

    precomputeSupersetIndicesImpl();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.link, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(snackbarMessage)),
        ]),
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.purple,
      ),
    );
  }

  /// Override of [WorkoutFlowMixin.logAllSetPerformances] that stamps every
  /// set-performance record with `logging_mode: 'advanced'`.
  ///
  /// The bulk endpoint payload is built locally (not from SetLog.toJson), so
  /// we re-implement the record construction here and add the tier tag. Easy
  /// and Simple screens are expected to provide their own overrides with
  /// `'easy'` / `'simple'` respectively — that's how product measures tier
  /// adoption via `performance_logs.logging_mode` without touching the
  /// shared SetLoggingMixin path.
  @override
  Future<void> logAllSetPerformances(String workoutLogId, String userId) async {
    final workoutRepo = ref.read(workoutRepositoryProvider);

    final records = <Map<String, dynamic>>[];
    for (int i = 0; i < exercises.length; i++) {
      final exercise = exercises[i];
      final sets = completedSets[i] ?? [];
      final pattern = _exerciseProgressionPattern[i] ??
          SetProgressionPattern.pyramidUp;

      for (int j = 0; j < sets.length; j++) {
        final setLog = sets[j];
        final setTarget = exercise.getTargetForSet(j + 1);
        records.add({
          'workout_log_id': workoutLogId,
          'user_id': userId,
          'exercise_id':
              exercise.exerciseId ?? exercise.libraryId ?? exercise.name,
          'exercise_name': exercise.name,
          'set_number': j + 1,
          'reps_completed': setLog.reps,
          'weight_kg': setLog.weight,
          'is_completed': true,
          'set_type': 'working',
          if (setLog.rpe != null) 'rpe': setLog.rpe!.toDouble(),
          if (setLog.rir != null) 'rir': setLog.rir,
          if (setLog.notes.isNotEmpty) 'notes': setLog.notes,
          if (setLog.aiInputSource != null && setLog.aiInputSource!.isNotEmpty)
            'ai_input_source': setLog.aiInputSource,
          'target_weight_kg':
              setTarget?.targetWeightKg ?? exercise.weight?.toDouble(),
          if ((setTarget?.targetReps ?? exercise.reps) != null)
            'target_reps': setTarget?.targetReps ?? exercise.reps,
          'progression_model': pattern.storageKey,
          if (setLog.durationSeconds != null)
            'set_duration_seconds': setLog.durationSeconds,
          if (setLog.restDurationSeconds != null)
            'rest_duration_seconds': setLog.restDurationSeconds,
          // Tier analytics — Advanced viewport always tags as 'advanced'.
          // Legacy rows (pre-tier) will remain NULL in the DB and are
          // treated as 'advanced' in analytics per the plan.
          'logging_mode': setLog.loggingMode ?? 'advanced',
        });
      }
    }

    if (records.isEmpty) {
      debugPrint('💪 No sets to log');
      return;
    }
    final inserted = await workoutRepo.logSetPerformancesBulk(records);
    debugPrint(
      '💪 Bulk-logged $inserted / ${records.length} set performances (advanced)',
    );
  }

  // Phase state — default to warmup. initState overrides to `active` when
  // a lower tier (Easy/Simple) has already passed warmup for this workout.
  WorkoutPhase _currentPhase = WorkoutPhase.warmup;

  // Workout state
  int _currentExerciseIndex = 0;
  bool _isResting = false;
  bool _isRestingBetweenExercises = false;
  bool _isPaused = false;
  /// True while the app is in the background (paused/inactive/hidden).
  /// Gates per-tick notification refresh so the shade entry doesn't
  /// flicker back into view while the user is looking at the screen.
  bool _isAppBackgrounded = false;
  bool _showInstructions = false;
  /// Whether to hide the AI Coach FAB for this session (user long-pressed to hide)
  bool _hideAICoachForSession = false;

  /// Coach tip bubble state
  bool _showCoachTip = false;
  String? _coachTipMessage;
  // ignore: unused_field
  final bool _coachTipSent = false; // Legacy — tips now tracked per-exercise in AIFeaturesMixin

  // Video state
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isVideoPlaying = true;
  String? _imageUrl;
  bool _isLoadingMedia = true;

  // Timer controller
  late WorkoutTimerController _timerController;
  String _currentRestMessage = '';

  // Set tracking
  final Map<int, List<SetLog>> _completedSets = {};

  // Input controllers
  late TextEditingController _repsController;
  late TextEditingController _repsRightController; // For L/R mode
  late TextEditingController _weightController;
  bool _useKg = true; // Initialized from user preference
  bool _unitInitialized = false; // Track if unit has been initialized from user preference
  double _weightIncrement = 2.5; // Default weight increment (kg)

  // Set tracking overlay
  final Map<int, List<Map<String, dynamic>>> _previousSets = {};
  final Map<int, int> _totalSetsPerExercise = {};
  final Map<int, RepProgressionType> _repProgressionPerExercise = {};
  int _viewingExerciseIndex = 0;

  // Exercises list
  late List<WorkoutExercise> _exercises;

  // Tracking state
  int _totalDrinkIntakeMl = 0;
  final List<Map<String, dynamic>> _drinkEvents = [];
  bool _warmupSkipped = false;
  bool _stretchSkipped = false;
  bool _isActiveRowExpanded = true;
  final List<Map<String, dynamic>> _restIntervals = [];
  final Map<int, int> _exerciseTimeSeconds = {};
  DateTime? _currentExerciseStartTime;
  bool _isDoneButtonPressed = false;
  int? _justCompletedSetIndex;
  final Map<String, double> _exerciseMaxWeights = {};
  // Per-set timing
  DateTime? _currentSetStartTime;
  final Map<int, List<int>> _actualRestDurations = {}; // exercise index → rest durations per set gap

  // Per-exercise progression pattern (persisted across sessions)
  final Map<int, SetProgressionPattern> _exerciseProgressionPattern = {};
  /// Stored peak/working weight per exercise (derived when pattern is applied).
  final Map<int, double> _exerciseWorkingWeight = {};
  /// Override bar type per exercise (null = auto-detect from equipment field).
  final Map<int, String> _exerciseBarType = {};

  // RPE/RIR and weight suggestion state. Both start null — the old
  // silent default of RIR=3 was writing "moderate" onto every set the
  // user logged without ever being prompted, making the Advanced
  // Summary look like bogus hardcoded data. Now each set opens the
  // IntensityPromptSheet and the user must pick an effort.
  int? _lastSetRpe;
  int? _lastSetRir;
  WeightSuggestion? _currentWeightSuggestion;
  bool _isLoadingWeightSuggestion = false; // Loading state for AI suggestion
  SetLog? _pendingSetLog; // Set waiting for RPE/RIR input

  // Fatigue detection state
  FatigueAlertData? _fatigueAlertData;
  bool _showFatigueAlert = false;

  // PR detection service
  late PRDetectionService _prDetectionService;

  // Rest suggestion state (AI-powered)
  RestSuggestion? _restSuggestion;
  bool _isLoadingRestSuggestion = false;

  // Inline rest row state
  bool _showInlineRest = false;
  int _inlineRestDuration = 90; // Default rest duration
  String? _inlineRestAiTip;
  bool _isLoadingAiTip = false;
  String? _inlineRestAchievementPrompt;
  int? _inlineRestCurrentRpe;
  AdaptationFeedback? _inlineRestAdaptationFeedback;

  // Warmup/stretch state (fetched from API)
  List<WarmupExerciseData>? _warmupExercises;
  List<StretchExerciseData>? _stretchExercises;
  bool _isWarmupLoading = true;
  // V2 UI flag - MacroFactor style design
  final bool _useV2Design = true;

  // L/R mode for unilateral exercises
  bool _isLeftRightMode = false;

  // Drag-to-action state (Delete/Swap zones at top of screen)
  bool _isDragActive = false;
  int? _draggedExerciseIndex;

  // Tracks exercises the user explicitly skipped (treated as "done" for navigation)
  final Set<int> _skippedExercises = {};

  // AI/UI interaction counters for analytics
  int _aiCoachOpened = 0;
  int _aiChatMessagesSent = 0;
  int _aiWeightSuggestionsShown = 0;
  int _aiWeightSuggestionsAccepted = 0;
  int _fatigueAlertsTriggered = 0;
  int _coachTipsShown = 0;
  int _coachTipsDismissed = 0;
  int _restSuggestionsShown = 0;
  int _exerciseInfoOpened = 0;
  int _breathingGuideOpened = 0;
  int _exerciseSwapsRequested = 0;
  int _videoViews = 0;

  // Superset round tracking
  // Maps superset group ID -> set of exercise indices that have completed a set in this round
  // Reset when all exercises in the superset complete their set for the round
  final Map<int, Set<int>> _supersetRoundProgress = {};

  // ── Pre-Set Coaching Banner state ──
  // Stable per-workout timestamp — drives deterministic copy selection so
  // banner text is stable across rebuilds inside one workout but varies
  // across separate workouts.
  final int _workoutStartEpochMs = DateTime.now().millisecondsSinceEpoch;
  // Cached per-set history for each exercise name; populated by a single
  // batch call at workout start.
  Map<String, List<SessionSummary>> _preSetHistoryByExerciseName = const {};
  bool _preSetHistoryLoaded = false;
  // Exercise indices the user has explicitly dismissed the banner for.
  final Set<int> _dismissedPreSetBannerIndices = {};
  // Cached computed copy per exercise index (memoized so rebuilds don't
  // re-run the pattern engine unnecessarily).
  final Map<int, String?> _cachedPreSetCopy = {};

  // Pre-computed superset indices cache (groupId -> sorted exercise indices)
  // Built once in initState and when exercises change, avoids repeated iteration/sorting
  Map<int, List<int>> _supersetIndicesCache = {};

  // ── Tier-aware tour subscriptions ──
  // Persists `tour_seen_<tier>` after the current tier's walkthrough finishes.
  ProviderSubscription<AppTourState>? _tourSeenSub;
  // Watches workout-UI tier changes; if the user flips tier mid-tour, aborts
  // the current tour and re-fires the new tier's tour (if unseen).
  ProviderSubscription<WorkoutUiModeState>? _tierSwitchSub;

  // ── Mixin @override getters/setters ──
  @override PRDetectionService get prDetectionService => _prDetectionService;
  @override List<WorkoutExercise> get exercises => _exercises;
  @override set exercises(List<WorkoutExercise> value) => _exercises = value;
  @override int get currentExerciseIndex => _currentExerciseIndex;
  @override set currentExerciseIndex(int value) => _currentExerciseIndex = value;
  @override Map<int, List<SetLog>> get completedSets => _completedSets;
  @override Map<int, int> get totalSetsPerExercise => _totalSetsPerExercise;
  @override Map<String, double> get exerciseMaxWeights => _exerciseMaxWeights;
  @override List<Map<String, dynamic>> get restIntervals => _restIntervals;
  @override WorkoutTimerController get timerController => _timerController;
  @override bool get isResting => _isResting;
  @override set isResting(bool value) => _isResting = value;
  @override bool get isRestingBetweenExercises => _isRestingBetweenExercises;
  @override set isRestingBetweenExercises(bool value) => _isRestingBetweenExercises = value;
  @override String get currentRestMessage => _currentRestMessage;
  @override set currentRestMessage(String value) => _currentRestMessage = value;
  @override bool get showInlineRest => _showInlineRest;
  @override set showInlineRest(bool value) => _showInlineRest = value;
  @override int get inlineRestDuration => _inlineRestDuration;
  @override set inlineRestDuration(int value) => _inlineRestDuration = value;
  @override String? get inlineRestAiTip => _inlineRestAiTip;
  @override set inlineRestAiTip(String? value) => _inlineRestAiTip = value;
  @override bool get isLoadingAiTip => _isLoadingAiTip;
  @override set isLoadingAiTip(bool value) => _isLoadingAiTip = value;
  @override String? get inlineRestAchievementPrompt => _inlineRestAchievementPrompt;
  @override set inlineRestAchievementPrompt(String? value) => _inlineRestAchievementPrompt = value;
  @override int? get inlineRestCurrentRpe => _inlineRestCurrentRpe;
  @override set inlineRestCurrentRpe(int? value) => _inlineRestCurrentRpe = value;
  @override AdaptationFeedback? get inlineRestAdaptationFeedback => _inlineRestAdaptationFeedback;
  @override set inlineRestAdaptationFeedback(AdaptationFeedback? value) => _inlineRestAdaptationFeedback = value;
  @override RestSuggestion? get restSuggestion => _restSuggestion;
  @override set restSuggestion(RestSuggestion? value) => _restSuggestion = value;
  @override bool get isLoadingRestSuggestion => _isLoadingRestSuggestion;
  @override set isLoadingRestSuggestion(bool value) => _isLoadingRestSuggestion = value;
  @override int? get lastSetRpe => _lastSetRpe;
  @override set lastSetRpe(int? value) => _lastSetRpe = value;
  @override int? get lastSetRir => _lastSetRir;
  @override set lastSetRir(int? value) => _lastSetRir = value;
  @override bool get useKg => _useKg;
  @override set useKg(bool value) => _useKg = value;
  @override double get weightIncrement => _weightIncrement;
  @override set weightIncrement(double value) => _weightIncrement = value;
  @override int get viewingExerciseIndex => _viewingExerciseIndex;
  @override set viewingExerciseIndex(int value) => _viewingExerciseIndex = value;
  @override TextEditingController get weightController => _weightController;
  @override TextEditingController get repsController => _repsController;
  @override TextEditingController get repsRightController => _repsRightController;
  @override Map<int, SetProgressionPattern> get exerciseProgressionPattern => _exerciseProgressionPattern;
  @override Map<int, double> get exerciseWorkingWeight => _exerciseWorkingWeight;
  @override Map<int, String> get exerciseBarType => _exerciseBarType;
  @override WeightSuggestion? get currentWeightSuggestion => _currentWeightSuggestion;
  @override set currentWeightSuggestion(WeightSuggestion? value) => _currentWeightSuggestion = value;
  @override bool get isLoadingWeightSuggestion => _isLoadingWeightSuggestion;
  @override set isLoadingWeightSuggestion(bool value) => _isLoadingWeightSuggestion = value;
  @override FatigueAlertData? get fatigueAlertData => _fatigueAlertData;
  @override set fatigueAlertData(FatigueAlertData? value) => _fatigueAlertData = value;
  @override bool get showFatigueAlert => _showFatigueAlert;
  @override set showFatigueAlert(bool value) => _showFatigueAlert = value;
  @override bool get showCoachTip => _showCoachTip;
  @override set showCoachTip(bool value) => _showCoachTip = value;
  @override String? get coachTipMessage => _coachTipMessage;
  @override set coachTipMessage(String? value) => _coachTipMessage = value;
  @override VideoPlayerController? get videoController => _videoController;
  @override set videoController(VideoPlayerController? value) => _videoController = value;
  @override bool get isVideoInitialized => _isVideoInitialized;
  @override set isVideoInitialized(bool value) => _isVideoInitialized = value;
  @override bool get isVideoPlaying => _isVideoPlaying;
  @override set isVideoPlaying(bool value) => _isVideoPlaying = value;
  @override String? get imageUrl => _imageUrl;
  @override set imageUrl(String? value) => _imageUrl = value;
  @override bool get isLoadingMedia => _isLoadingMedia;
  @override set isLoadingMedia(bool value) => _isLoadingMedia = value;
  @override Map<int, List<Map<String, dynamic>>> get previousSets => _previousSets;
  @override Map<String, List<SessionSummary>> get preSetHistoryByExerciseName => _preSetHistoryByExerciseName;
  @override Map<int, RepProgressionType> get repProgressionPerExercise => _repProgressionPerExercise;
  @override bool get unitInitialized => _unitInitialized;
  @override SetLog? get pendingSetLog => _pendingSetLog;
  @override set pendingSetLog(SetLog? value) => _pendingSetLog = value;
  @override bool get isLeftRightMode => _isLeftRightMode;
  @override set isLeftRightMode(bool value) => _isLeftRightMode = value;
  @override bool get isDoneButtonPressed => _isDoneButtonPressed;
  @override set isDoneButtonPressed(bool value) => _isDoneButtonPressed = value;
  @override int? get justCompletedSetIndex => _justCompletedSetIndex;
  @override set justCompletedSetIndex(int? value) => _justCompletedSetIndex = value;
  @override Map<int, int> get exerciseTimeSeconds => _exerciseTimeSeconds;
  @override DateTime? get currentExerciseStartTime => _currentExerciseStartTime;
  @override set currentExerciseStartTime(DateTime? value) => _currentExerciseStartTime = value;
  @override WorkoutPhase get currentPhase => _currentPhase;
  @override set currentPhase(WorkoutPhase value) => _currentPhase = value;
  @override Map<int, Set<int>> get supersetRoundProgress => _supersetRoundProgress;
  @override Map<int, List<int>> get supersetIndicesCache => _supersetIndicesCache;
  @override set supersetIndicesCache(Map<int, List<int>> value) => _supersetIndicesCache = value;
  @override dynamic get workoutWidget => widget;
  @override int get totalDrinkIntakeMl => _totalDrinkIntakeMl;
  @override DateTime? get currentSetStartTime => _currentSetStartTime;
  @override set currentSetStartTime(DateTime? value) => _currentSetStartTime = value;
  @override Map<int, List<int>> get actualRestDurations => _actualRestDurations;
  @override set totalDrinkIntakeMl(int value) => _totalDrinkIntakeMl = value;
  @override List<Map<String, dynamic>> get drinkEvents => _drinkEvents;
  @override bool get warmupSkipped => _warmupSkipped;
  @override set warmupSkipped(bool value) => _warmupSkipped = value;
  @override bool get stretchSkipped => _stretchSkipped;
  @override set stretchSkipped(bool value) => _stretchSkipped = value;
  @override List<WarmupExerciseData>? get warmupExercises => _warmupExercises;
  @override set warmupExercises(List<WarmupExerciseData>? value) => _warmupExercises = value;
  @override List<StretchExerciseData>? get stretchExercises => _stretchExercises;
  @override set stretchExercises(List<StretchExerciseData>? value) => _stretchExercises = value;
  @override bool get isWarmupLoading => _isWarmupLoading;
  @override set isWarmupLoading(bool value) => _isWarmupLoading = value;
  @override bool get hideAICoachForSession => _hideAICoachForSession;
  @override set hideAICoachForSession(bool value) => _hideAICoachForSession = value;
  @override bool get showInstructions => _showInstructions;
  @override set showInstructions(bool value) => _showInstructions = value;
  @override bool get useV2Design => _useV2Design;
  @override bool get isActiveRowExpanded => _isActiveRowExpanded;
  @override set isActiveRowExpanded(bool value) => _isActiveRowExpanded = value;
  @override bool get isDragActive => _isDragActive;
  @override set isDragActive(bool value) => _isDragActive = value;
  @override int? get draggedExerciseIndex => _draggedExerciseIndex;
  @override set draggedExerciseIndex(int? value) => _draggedExerciseIndex = value;
  @override bool get isPaused => _isPaused;
  @override set isPaused(bool value) => _isPaused = value;
  @override Set<int> get skippedExercises => _skippedExercises;

  // AI/UI interaction counter getters and setters
  @override int get aiCoachOpened => _aiCoachOpened;
  set aiCoachOpened(int value) => _aiCoachOpened = value;
  @override int get aiChatMessagesSent => _aiChatMessagesSent;
  set aiChatMessagesSent(int value) => _aiChatMessagesSent = value;
  @override int get aiWeightSuggestionsShown => _aiWeightSuggestionsShown;
  @override set aiWeightSuggestionsShown(int value) => _aiWeightSuggestionsShown = value;
  @override int get aiWeightSuggestionsAccepted => _aiWeightSuggestionsAccepted;
  @override set aiWeightSuggestionsAccepted(int value) => _aiWeightSuggestionsAccepted = value;
  @override int get fatigueAlertsTriggered => _fatigueAlertsTriggered;
  @override set fatigueAlertsTriggered(int value) => _fatigueAlertsTriggered = value;
  @override int get coachTipsShown => _coachTipsShown;
  @override set coachTipsShown(int value) => _coachTipsShown = value;
  @override int get coachTipsDismissed => _coachTipsDismissed;
  @override set coachTipsDismissed(int value) => _coachTipsDismissed = value;
  @override int get restSuggestionsShown => _restSuggestionsShown;
  @override set restSuggestionsShown(int value) => _restSuggestionsShown = value;
  @override int get exerciseInfoOpened => _exerciseInfoOpened;
  @override set exerciseInfoOpened(int value) => _exerciseInfoOpened = value;
  @override int get breathingGuideOpened => _breathingGuideOpened;
  @override set breathingGuideOpened(int value) => _breathingGuideOpened = value;
  @override int get exerciseSwapsRequested => _exerciseSwapsRequested;
  set exerciseSwapsRequested(int value) => _exerciseSwapsRequested = value;
  @override int get videoViews => _videoViews;
  set videoViews(int value) => _videoViews = value;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // If the user swapped into Advanced mid-workout (from Easy / Simple —
    // neither of which shows warmup) skip straight to the active phase so
    // warmup doesn't re-trigger.
    if (ref.read(activeWorkoutWarmupDoneProvider)) {
      _currentPhase = WorkoutPhase.active;
    }
    _initializeWorkout();
    loadWarmupAndStretches();
    _startWarmupLoadingTimeout();
    checkWarmupEnabled();
    // BLE heart-rate auto-reconnect is disabled — keep the call commented so
    // we don't instantiate FlutterReactiveBle and trigger the Android
    // "Nearby Devices" system prompt. Mic permission now only fires when the
    // user taps the in-workout mic button, so no pre-prompt sheet is needed.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // initBleHrAutoReconnect();
      _attachTierTourListeners();
      triggerWorkoutTour();
      _prefetchPreSetHistory();
    });
  }

  /// Wires the two tier-aware tour listeners:
  /// 1. [WorkoutTourSeenListener] — writes `tour_seen_<tier>` when a tier
  ///    tour is dismissed by the user (completion or Skip).
  /// 2. A [ref.listenManual] on [workoutUiModeProvider] that aborts any
  ///    in-flight tier tour when the user flips tier, and re-fires the new
  ///    tier's tour if that tier's flag is still unseen.
  ///
  /// Both subscriptions are closed in [dispose].
  void _attachTierTourListeners() {
    _tourSeenSub = WorkoutTourSeenListener.attach(ref);

    _tierSwitchSub = ref.listenManual<WorkoutUiModeState>(
      workoutUiModeProvider,
      (previous, next) async {
        // Only act on actual tier changes — not loading / explicit-flag
        // mutations.
        if (previous == null) return;
        if (previous.mode == next.mode) return;

        final aborted = WorkoutTourService.abortIfTierTourRunning(ref);
        // If nothing was aborted AND the new tier has already been seen,
        // there's nothing to do — don't spam the user with a second tour on
        // a simple settings tweak.
        if (!mounted) return;
        final alreadySeen = await WorkoutTourService.hasSeen(next.mode);
        if (alreadySeen) {
          if (aborted != null) {
            debugPrint(
              '🔍 [WorkoutTour] Aborted ${aborted.asString} tour; '
              'new tier ${next.mode.asString} already seen — no re-fire',
            );
          }
          return;
        }

        // Give the controller a beat to settle (abort → state = default),
        // then re-fire for the new tier.
        await Future<void>.delayed(const Duration(milliseconds: 50));
        if (!mounted) return;
        await WorkoutTourService.maybeShowForTier(ref, next.mode);
      },
      fireImmediately: false,
    );
  }

  /// Batch-fetch last-N-sessions history for every exercise in this workout.
  /// Fires once on workout start; runs off the critical path so the screen
  /// paints immediately. Banner renders as soon as this completes.
  Future<void> _prefetchPreSetHistory() async {
    if (_exercises.isEmpty) return;
    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();
      if (userId == null || !mounted) return;

      final names = _exercises
          .map((e) => e.name)
          .where((n) => n.isNotEmpty)
          .toSet() // dedupe (supersets might repeat a name)
          .toList(growable: false);
      if (names.isEmpty) return;

      final service = ExerciseHistoryBatchService(apiClient);
      final histories = await service.fetchBatch(
        userId: userId,
        exerciseNames: names,
      );
      if (!mounted) return;
      setState(() {
        _preSetHistoryByExerciseName = histories;
        _preSetHistoryLoaded = true;
        _cachedPreSetCopy.clear(); // invalidate so banners re-compute
      });
    } catch (e) {
      // Service already logged with trace. Mark loaded=true so we stop
      // pretending we're waiting — banner just won't render.
      if (!mounted) return;
      setState(() => _preSetHistoryLoaded = true);
    }
  }

  /// If warmup loading takes too long, skip the loading screen
  /// so the user isn't stuck waiting. The warmup will either load
  /// in time or auto-skip to the active phase.
  /// Note: Render cold starts can take 10-30s, so we use a generous timeout
  /// but show a "skip" option after 3s in the loading screen.
  void _startWarmupLoadingTimeout() {
    // Show skip hint after 3s (handled by loading screen UI)
    // Actually abandon after 15s to handle Render cold starts
    Future.delayed(const Duration(seconds: 15), () {
      if (!mounted || !_isWarmupLoading) return;
      debugPrint('⚠️ [Warmup] Loading timeout (15s) — skipping loading screen');
      setState(() => _isWarmupLoading = false);
    });
  }

  void _initializeWorkout() {
    // Initialize exercises list
    _exercises = List.from(widget.workout.exercises);

    // Pre-compute superset indices cache for O(1) lookups
    precomputeSupersetIndices();

    // Guard: If no exercises, we cannot proceed
    // Note: Router should catch this case, but keep as a safety check
    if (_exercises.isEmpty) {
      debugPrint('❌ [ActiveWorkout] No exercises in workout! Cannot start.');
      // Initialize with defaults to prevent late init errors
      _repsController = TextEditingController(text: '10');
      _repsRightController = TextEditingController(text: '10');
      _weightController = TextEditingController(text: '0');
      _timerController = WorkoutTimerController();
      _prDetectionService = ref.read(prDetectionServiceProvider);
      // Schedule navigation back after build completes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/home');
        }
      });
      return;
    }

    // Initialize unit preference early (before weight controller setup)
    _useKg = ref.read(useKgForWorkoutProvider);
    _unitInitialized = true;

    // Track workout started event
    ref.read(posthogServiceProvider).capture(
      eventName: 'workout_started',
      properties: {
        'workout_id': widget.workout.id ?? '',
        'workout_name': widget.workout.name ?? '',
        'exercise_count': _exercises.length,
        'challenge_id': widget.challengeId ?? '',
      },
    );

    // Check if we're restoring from mini player
    final miniPlayerState = ref.read(workoutMiniPlayerProvider);
    final isRestoring = miniPlayerState.workout?.id == widget.workout.id &&
        miniPlayerState.workoutSeconds > 0;
    debugPrint('🔥 [Init] miniPlayer: workoutId=${miniPlayerState.workout?.id}, widgetId=${widget.workout.id}, timer=${miniPlayerState.workoutSeconds}, isRestoring=$isRestoring');

    if (isRestoring) {
      debugPrint('🎬 [ActiveWorkout] Restoring from mini player - timer: ${miniPlayerState.workoutSeconds}s, exercise: ${miniPlayerState.currentExerciseIndex}');
    }

    // Initialize input controllers
    final initialExerciseIndex = isRestoring ? miniPlayerState.currentExerciseIndex : 0;
    final initialExercise = _exercises[initialExerciseIndex.clamp(0, _exercises.length - 1)];
    // Use setTargets for initial values if available, fallback to legacy fields
    final firstSetTarget = initialExercise.getTargetForSet(1);
    _repsController = TextEditingController(
        text: (firstSetTarget?.targetReps ?? initialExercise.reps ?? 10).toString());
    _repsRightController = TextEditingController(
        text: (firstSetTarget?.targetReps ?? initialExercise.reps ?? 10).toString()); // Same initial reps for L/R
    // Weight: historical/reliable → equipment default → bar minimum → 0
    // Don't trust generic AI weights (e.g., 10 kg for everything)
    final aiWeight = (firstSetTarget?.targetWeightKg ?? initialExercise.weight ?? 0).toDouble();
    final useAiWeight = !isGenericWeight(aiWeight, initialExercise.weightSource);
    final userProfile = ref.read(authStateProvider).user;
    double initWeightDisplay;
    if (useAiWeight) {
      initWeightDisplay = _useKg
          ? aiWeight
          : kgToDisplayLbs(aiWeight, initialExercise.equipment,
                exerciseName: initialExercise.name,);
    } else {
      // Get default in user's display unit (already snapped to real increments)
      initWeightDisplay = getDefaultWeight(
        initialExercise.equipment,
        exerciseName: initialExercise.name,
        fitnessLevel: userProfile?.fitnessLevel,
        gender: userProfile?.gender,
        useKg: _useKg,
      );
    }
    _weightController = TextEditingController(
        text: initWeightDisplay > 0 ? initWeightDisplay.toStringAsFixed(initWeightDisplay % 1 == 0 ? 0 : 1) : '');

    // Restore exercise index if restoring
    if (isRestoring) {
      _currentExerciseIndex = miniPlayerState.currentExerciseIndex.clamp(0, _exercises.length - 1);
      _viewingExerciseIndex = _currentExerciseIndex;
      _isPaused = miniPlayerState.isPaused;
      _isResting = miniPlayerState.isResting;
      // Skip warmup phase when restoring - go directly to active workout
      _currentPhase = WorkoutPhase.active;
    }

    // Initialize timer controller
    _timerController = WorkoutTimerController();
    _timerController.onWorkoutTick = (_) {
      setState(() {});
      // Only refresh the notification while the app is backgrounded.
      // While foregrounded, the shade entry is hidden (cancelled in
      // `didChangeAppLifecycleState(resumed)`) — re-firing it every
      // second would cause it to flicker back into view.
      if (_isAppBackgrounded) {
        updateWorkoutNotification();
      }
    };
    _timerController.onRestTick = (secondsRemaining) {
      setState(() {});
      // Play countdown sound + voice at 3, 2, 1
      if (secondsRemaining <= 3 && secondsRemaining > 0) {
        ref.read(soundPreferencesProvider.notifier).playCountdown(secondsRemaining);
        ref.read(voiceAnnouncementsProvider.notifier).announceCountdownIfEnabled(secondsRemaining);
      }
    };
    _timerController.onRestComplete = handleRestComplete;

    // Initialize PR detection service
    _prDetectionService = ref.read(prDetectionServiceProvider);
    _prDetectionService.startNewWorkout();
    preloadPRHistory(ref);

    // Preload per-exercise progression patterns from SharedPreferences
    preloadProgressionPatterns();

    // Apply progression targets for the first exercise immediately
    // (don't wait for async preload — use default pattern)
    initControllersForExercise(_currentExerciseIndex);

    // Load coach persona for AI Coach button
    loadCoachPersona();

    // Start workout timer (restore time if returning from mini player)
    _timerController.startWorkoutTimer(initialSeconds: isRestoring ? miniPlayerState.workoutSeconds : 0);

    // Keep the screen on while working out — ignore failure (plugin missing on
    // non-mobile platforms, permission denied, etc.) so we never block the
    // workout from starting.
    unawaited(WakelockPlus.enable().catchError((e) {
      debugPrint('⚠️ [Wakelock] enable failed: $e');
    }));

    // Start the Live Activity (iOS Dynamic Island) / upgraded ongoing
    // notification (Android). Uses current state — will be refreshed on every
    // set/exercise/pause/rest transition via updateWorkoutNotification().
    final liveActivityState = buildLiveActivityState();
    if (liveActivityState != null) {
      unawaited(LiveActivityService.instance.start(liveActivityState));
    }

    // Initialize and show the persistent workout notification
    _initWorkoutNotification();

    // Announce workout start (only for fresh workouts, not restores)
    if (!isRestoring) {
      ref.read(voiceAnnouncementsProvider.notifier)
          .announceIfEnabled("Let's go! Starting ${widget.workout.name}");
    }

    // Restore rest timer if was resting
    if (isRestoring && miniPlayerState.isResting && miniPlayerState.restSecondsRemaining > 0) {
      _timerController.startRestTimer(miniPlayerState.restSecondsRemaining);
    }

    // Initialize tracking data
    for (int i = 0; i < _exercises.length; i++) {
      _completedSets[i] = [];
      final exercise = _exercises[i];
      // Use setTargets length if available (includes warmup sets), otherwise fall back to exercise.sets
      _totalSetsPerExercise[i] = exercise.hasSetTargets && exercise.setTargets!.isNotEmpty
          ? exercise.setTargets!.length
          : exercise.sets ?? 3;
      _previousSets[i] = [];
    }

    // Restore completed sets if restoring from mini player
    if (isRestoring && miniPlayerState.completedSets.isNotEmpty) {
      for (final entry in miniPlayerState.completedSets.entries) {
        final exerciseIndex = entry.key;
        final setMaps = entry.value;
        if (exerciseIndex < _exercises.length) {
          _completedSets[exerciseIndex] = setMaps.map((map) => SetLog(
            reps: (map['reps'] as num?)?.toInt() ?? 0,
            weight: (map['weight'] as num?)?.toDouble() ?? 0.0,
            setType: map['setType'] as String? ?? 'working',
            rpe: (map['rpe'] as num?)?.toInt(),
            rir: (map['rir'] as num?)?.toInt(),
            aiInputSource: map['aiInputSource'] as String?,
            // Mini-player restore → user was in Advanced when they minimized
            // (this screen is the Advanced viewport). Tag accordingly so the
            // logging_mode on the bulk POST is correct.
            loggingMode: (map['loggingMode'] as String?) ?? 'advanced',
          )).toList();
        }
      }
      debugPrint('🎬 [ActiveWorkout] Restored ${miniPlayerState.completedSets.length} exercise completed sets');
    }

    // Fetch historical data (fire-and-forget, doesn't block workout start)
    fetchExerciseHistory();

    // Fetch smart weight for first exercise based on history
    if (_exercises.isNotEmpty) {
      fetchSmartWeightForExercise(_exercises.first);
    }

    // Initialize time tracking
    _currentExerciseStartTime = DateTime.now();
    _currentSetStartTime = DateTime.now(); // First set starts when exercise loads
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // When the user minimized (instead of ending), the mini-player provider
    // now owns the notification / Live Activity lifecycle — don't cancel it
    // here or the ongoing surface will disappear the instant the screen pops.
    //
    // Reading `ref` inside dispose is normally legal up until super.dispose(),
    // but Crashlytics flagged "Cannot use ref after the widget was disposed"
    // here in production — likely because a parent's teardown ordering
    // disposes the provider scope before this State's dispose runs (e.g.
    // route rebuild with key change). Default to "not minimized" on failure
    // so we always clean up the ongoing notification rather than orphan it.
    bool minimized = false;
    try {
      minimized = ref.read(workoutMiniPlayerProvider).isMinimized;
    } catch (e) {
      debugPrint('⚠️ [ActiveWorkout] dispose ref unavailable, assuming not minimized: $e');
    }
    if (!minimized) {
      cancelWorkoutNotification();
      unawaited(LiveActivityService.instance.end());
    }
    // Release screen-wake regardless of minimize state — if the user
    // minimized to the mini-player, the mini-player screen takes over
    // wakelock management if it needs to.
    unawaited(WakelockPlus.disable().catchError((e) {
      debugPrint('⚠️ [Wakelock] disable failed: $e');
    }));
    _timerController.dispose();
    _videoController?.dispose();
    _repsController.dispose();
    _repsRightController.dispose();
    _weightController.dispose();
    _tourSeenSub?.close();
    _tierSwitchSub?.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Only manage the ongoing notification while a workout is actually in
    // progress — not during loading/error states with no exercises.
    if (exercises.isEmpty) return;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // App is going to the background while the user is mid-workout —
        // promote the ongoing notification immediately so they don't have to
        // wait for the next timer tick. Wire the remote-control callbacks
        // so Pause/Resume from the shade reaches the real screen timer.
        _isAppBackgrounded = true;
        WorkoutNotificationService.instance.onPauseResumePressed = togglePause;
        WorkoutNotificationService.instance.onStopPressed = () {
          // "Stop" just brings the app forward (showsUserInterface=true on
          // the action). The user completes the end-workout flow in-app so
          // the session persists to the DB.
        };
        WorkoutNotificationService.instance.onNotificationTapped = () {};
        updateWorkoutNotification();
        break;
      case AppLifecycleState.resumed:
        // User is back in the app looking at the workout — the shade entry
        // is redundant. Clear it so the two timers can't visibly desync.
        _isAppBackgrounded = false;
        cancelWorkoutNotification();
        break;
      case AppLifecycleState.detached:
        _isAppBackgrounded = false;
        break;
    }
  }

  /// Go back to warmup phase from active workout
  @override
  void goBackToWarmup() {
    HapticFeedback.lightImpact();
    setState(() {
      _currentPhase = WorkoutPhase.warmup;
    });
  }

  // ── Bridge methods for mixin cross-references ──

  @override
  void showQuitDialogImpl() => showQuitDialog();

  @override
  void precomputeSupersetIndicesImpl() => precomputeSupersetIndices();

  // ── Bridge methods for WorkoutUIBuildersMixin ──

  @override
  Future<void> toggleFavoriteExercise() async {
    if (_exercises.isEmpty || _currentExerciseIndex >= _exercises.length) return;
    final exercise = _exercises[_currentExerciseIndex];
    HapticFeedback.mediumImpact();
    await ref.read(favoritesProvider.notifier).toggleFavorite(
      exercise.name,
      exerciseId: exercise.id ?? exercise.libraryId,
    );
  }

  @override
  String formatDuration(int seconds) => formatDurationTimer(seconds);

  @override
  Set<int> getCompletedExerciseIndices() {
    final completed = <int>{};
    for (int i = 0; i < _exercises.length; i++) {
      if (isExerciseCompleted(i)) completed.add(i);
    }
    return completed;
  }

  /// Get all exercise indices in a superset group (returns from pre-computed cache)
  @override
  List<int> getSupersetIndices(int groupId) {
    return _supersetIndicesCache[groupId] ?? [];
  }

  /// Wire up callbacks and show the initial notification.
  Future<void> _initWorkoutNotification() async {
    final notifService = WorkoutNotificationService.instance;
    await notifService.initialize();

    // Wire action callbacks
    notifService.onPauseResumePressed = () {
      if (mounted) togglePause();
    };
    notifService.onStopPressed = () {
      if (mounted) {
        // Close via mini player provider so state is cleaned up consistently
        ref.read(workoutMiniPlayerProvider.notifier).close();
        if (mounted) context.pop();
      }
    };
    notifService.onNotificationTapped = () {
      // App is already open; no special navigation needed since we're on the
      // active workout screen. Flutter's engine will foreground the app.
    };

    updateWorkoutNotification();
  }

  /// Fetch smart weight suggestion for an exercise based on historical data
  ///
  /// This method fetches an AI-powered weight suggestion based on:
  /// - User's 1RM for this exercise (from strength_records)
  /// - Target reps and training goal
  /// - Last session performance (RPE-based modifier)
  /// - Equipment-aware rounding
  ///
  /// The weight controller is updated in the background without blocking UI.
  @override
  Future<void> fetchSmartWeightForExercise(WorkoutExercise exercise) async {
    // If previous session data exists, only override if weight is completely unset
    final prevSets = _previousSets[_currentExerciseIndex];
    if (prevSets != null && prevSets.isNotEmpty) {
      final prevWeight = (prevSets.last['weight'] as num?)?.toDouble() ?? 0.0;
      if (prevWeight > 0) {
        final currentWeight = double.tryParse(_weightController.text) ?? 0;
        if (currentWeight <= 0 && mounted) {
          final displayWeight = _useKg
              ? prevWeight
              : kgToDisplayLbs(prevWeight, exercise.equipment,
                exerciseName: exercise.name,);
          _weightController.text = displayWeight.toStringAsFixed(1);
        }
        return; // Previous session data exists — skip API call
      }
    }

    try {
      final apiClient = ref.read(apiClientProvider);
      // Resolve the user goal from the provider BEFORE the userId await so we
      // never touch `ref` again after a suspension point. Without this, if the
      // user pops/minimizes the workout during getUserId(), the second
      // ref.read for `activeGymProfileProvider` throws ref-after-disposed.
      final goal = TrainingGoal.fromString(
        ref.read(activeGymProfileProvider)?.goals.firstOrNull ?? 'hypertrophy',
      );

      final userId = await apiClient.getUserId();
      if (userId == null || !mounted) return;

      final suggestion = await WeightSuggestionService.getSmartWeight(
        dio: apiClient.dio,
        userId: userId,
        exerciseId: exercise.exerciseId ?? exercise.libraryId ?? '',
        exerciseName: exercise.name,
        targetReps: exercise.reps ?? 10,
        goal: goal,
        equipment: exercise.equipment ?? 'dumbbell',
      );

      if (mounted && suggestion != null && suggestion.suggestedWeight > 0) {
        // Enforce bar minimum and convert to display unit
        var suggestedKg = suggestion.suggestedWeight;
        final isBarbellExercise = isBarbell(exercise.equipment, exerciseName: exercise.name);
        final minBarKg = isBarbellExercise
            ? getBarWeight(exercise.equipment, useKg: true)
            : 0.0;
        if (suggestedKg < minBarKg) suggestedKg = minBarKg;
        final displaySuggested = _useKg
            ? suggestedKg
            : kgToDisplayLbs(suggestedKg, exercise.equipment,
                exerciseName: exercise.name,);
        final displayMinBar = _useKg
            ? minBarKg
            : kgToDisplayLbs(minBarKg, exercise.equipment,
                exerciseName: exercise.name,);

        // Only update if current weight is truly unset or below bar minimum
        // Do NOT override a valid planned weight (e.g., 45 lbs == bar weight)
        final currentWeight = double.tryParse(_weightController.text) ?? 0;
        if (currentWeight <= 0 || currentWeight < displayMinBar) {
          setState(() {
            _weightController.text = displaySuggested.toStringAsFixed(1);
          });
          debugPrint('✅ [SmartWeight] ${exercise.name}: ${suggestion.suggestedWeight}kg '
              '(confidence: ${(suggestion.confidence * 100).toInt()}%, '
              'source: ${suggestion.reasoning})');
        }
      }
    } catch (e) {
      debugPrint('⚠️ [SmartWeight] Failed for ${exercise.name}: $e');
      // Fall back to planned weight - already set in controller
    }
  }

  @override
  Future<void> handleV2Parsed(ParseWorkoutInputV2Response response) async {
    if (!response.hasData) return;

    final currentExerciseName = _exercises.isNotEmpty
        ? _exercises[_viewingExerciseIndex].name
        : null;

    // Show V2 preview sheet
    final result = await showAIInputPreview(
      context,
      ref,
      response: response,
      currentExerciseName: currentExerciseName,
      useKg: _useKg,
    );

    if (result == null || !result.hasData || !mounted) {
      return;
    }

    // Handle sets to log
    if (result.setsToLog.isNotEmpty) {
      await _logSetsFromAI(result.setsToLog);
    }

    // Handle exercises to add
    if (result.exercisesToAdd.isNotEmpty) {
      await addExercisesFromAI(result.exercisesToAdd);
    }
  }

  /// Log multiple sets from AI input to the current exercise
  Future<void> _logSetsFromAI(List<SetToLog> sets) async {
    if (sets.isEmpty || _exercises.isEmpty) return;

    final exerciseIndex = _viewingExerciseIndex;
    final exercise = _exercises[exerciseIndex];

    for (final aiSet in sets) {
      // Convert weight if necessary
      double weight = aiSet.weight;
      if (aiSet.isBodyweight) {
        weight = 0;
      } else if (_useKg && aiSet.unit == 'lbs') {
        weight = aiSet.weight / 2.20462;
      } else if (!_useKg && aiSet.unit == 'kg') {
        weight = kgToDisplayLbs(aiSet.weight, exercise.equipment,
                exerciseName: exercise.name,);
      }

      // Create a SetLog with AI input source for tracking.
      // `loggingMode: 'advanced'` tags this record as belonging to the
      // Advanced-tier UI for the cross-tier analytics the plan calls for
      // (performance_logs.logging_mode column). Easy/Simple mirror this
      // in their own tier paths.
      final setLog = SetLog(
        reps: aiSet.reps,
        weight: weight,
        setType: aiSet.isWarmup ? 'warmup' : 'working',
        targetReps: exercise.reps ?? aiSet.reps,
        // SetToLog.notes is a single String? (AI annotation); SetLog.notes is
        // a list. Wrap if present.
        notes: (aiSet.notes != null && aiSet.notes!.trim().isNotEmpty)
            ? [aiSet.notes!.trim()]
            : const [],
        aiInputSource: aiSet.originalInput.isNotEmpty ? aiSet.originalInput : null,
        loggingMode: 'advanced',
      );

      // Add to completed sets
      _completedSets[exerciseIndex] ??= [];
      _completedSets[exerciseIndex]!.add(setLog);
    }

    // Update total sets if more were added than expected
    final currentTotal = _totalSetsPerExercise[exerciseIndex] ?? 3;
    final completedCount = _completedSets[exerciseIndex]?.length ?? 0;
    if (completedCount > currentTotal) {
      _totalSetsPerExercise[exerciseIndex] = completedCount;
    }

    setState(() {});

    // Show success feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Logged ${sets.length} set${sets.length == 1 ? '' : 's'} for ${exercise.name}',
          ),
          backgroundColor: AppColors.green,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    debugPrint('✅ [Workout] Logged ${sets.length} sets via AI input');
  }

  @override
  Widget build(BuildContext context) {
    // Initialize weight unit from user preference on first build
    if (!_unitInitialized) {
      _unitInitialized = true;
      _useKg = ref.read(useKgForWorkoutProvider);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;

    // Foldable detection
    final windowState = ref.watch(windowModeProvider);
    final isFoldableOpen = FoldableQuizScaffold.shouldUseFoldableLayout(windowState);

    // Route to appropriate phase screen
    // debugPrint('🔥 [Build] _currentPhase=$_currentPhase, _isWarmupLoading=$_isWarmupLoading, _warmupExercises=${_warmupExercises?.length ?? 'null'}');
    switch (_currentPhase) {
      case WorkoutPhase.warmup:
        // Still loading warmup data from API - show loading
        if (_isWarmupLoading) {
          return buildWarmupLoadingScreen();
        }
        // Skip warmup if API returned no exercises
        if (_warmupExercises == null || _warmupExercises!.isEmpty) {
          debugPrint('🔥 [Build] Warmup exercises null/empty — auto-skipping to active');
          // Schedule for next frame to avoid setState during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) handleWarmupComplete();
          });
          return buildWarmupLoadingScreen();
        }
        if (isFoldableOpen) {
          return FoldableWarmupLayout(
            windowState: windowState,
            workoutSeconds: _timerController.workoutSeconds,
            exercises: _warmupExercises!,
            onSkipWarmup: handleSkipWarmup,
            onWarmupComplete: handleWarmupComplete,
            onQuitRequested: showQuitDialog,
          );
        }
        return WarmupPhaseScreen(
          workoutSeconds: _timerController.workoutSeconds,
          exercises: _warmupExercises!,
          onSkipWarmup: handleSkipWarmup,
          onWarmupComplete: handleWarmupComplete,
          onQuitRequested: showQuitDialog,
          onIntervalsLogged: handleWarmupIntervalsLogged,
        );

      case WorkoutPhase.stretch:
        // Skip stretch if API didn't return personalized exercises
        if (_stretchExercises == null || _stretchExercises!.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) handleStretchComplete();
          });
          return const SizedBox.shrink();
        }
        return StretchPhaseScreen(
          workoutSeconds: _timerController.workoutSeconds,
          exercises: _stretchExercises!,
          onSkipAll: handleSkipStretch,
          onStretchComplete: handleStretchComplete,
        );

      case WorkoutPhase.complete:
        return buildCompletionScreen(isDark, backgroundColor);

      case WorkoutPhase.active:
        if (isFoldableOpen) {
          return buildFoldableActiveWorkout(windowState);
        }
        // Use V2 MacroFactor-style design
        if (_useV2Design) {
          return buildActiveWorkoutScreenV2(isDark, backgroundColor);
        }
        return buildActiveWorkoutScreen(isDark, backgroundColor);
    }
  }

  /// Calculate RIR algorithmically based on set type and position
  /// Based on RP Strength methodology: progressive intensity through sets
  int? _calculateRir(String? setType, int setIndex, int totalWorkingSets) {
    final type = (setType ?? 'working').toLowerCase();

    // Warmup sets don't have RIR - they're for preparation, not stimulation
    if (type == 'warmup') return null;

    // Failure/AMRAP sets are always RIR 0 (maximum effort)
    if (type == 'failure' || type == 'amrap') return 0;

    // Drop sets maintain high intensity (RIR 1)
    if (type == 'drop') return 1;

    // Working sets: progressive RIR decrease (3 → 2 → 1)
    if (totalWorkingSets <= 1) return 2;  // Single set = moderate intensity
    if (totalWorkingSets == 2) {
      return setIndex == 0 ? 3 : 1;  // First=3, Last=1
    }
    // 3+ working sets: distribute RIR across thirds (3→2→1)
    final position = setIndex / (totalWorkingSets - 1);  // 0.0 to 1.0
    if (position < 0.33) return 3;      // First third: conservative
    if (position < 0.67) return 2;      // Middle third: moderate
    return 1;                            // Last third: approaching failure
  }

  @override
  List<SetRowData> buildSetRowsForExercise(int exerciseIndex) {
    final exercise = _exercises[exerciseIndex];
    final totalSets = _totalSetsPerExercise[exerciseIndex] ?? exercise.sets ?? 3;
    final completedSets = _completedSets[exerciseIndex] ?? [];
    final previousSets = _previousSets[exerciseIndex] ?? [];
    final setTargets = exercise.setTargets ?? [];

    // Count working sets for RIR calculation
    final totalWorkingSets = setTargets.isNotEmpty
        ? setTargets.where((t) => t.setType.toLowerCase() == 'working').length
        : totalSets;

    final List<SetRowData> rows = [];
    int workingSetIndex = 0;

    for (int i = 0; i < totalSets; i++) {
      final isCompleted = i < completedSets.length;
      final isActive = i == completedSets.length && exerciseIndex == _viewingExerciseIndex;

      // Get target data from AI
      SetTarget? setTarget;
      if (i < setTargets.length) {
        setTarget = setTargets[i];
      }

      // Track working set index for RIR calculation
      final isWorkingSet = setTarget?.setType.toLowerCase() == 'working' ||
          (setTarget == null && i >= 0); // Fallback assumes all are working sets
      final currentWorkingIndex = isWorkingSet ? workingSetIndex : 0;
      if (setTarget?.setType.toLowerCase() == 'working') {
        workingSetIndex++;
      }

      // Get previous session data
      double? prevWeight;
      int? prevReps;
      int? prevRir;
      if (i < previousSets.length) {
        prevWeight = (previousSets[i]['weight'] as num?)?.toDouble();
        prevReps = previousSets[i]['reps'] as int?;
        prevRir = previousSets[i]['rir'] as int?;
      }

      // Get actual values if completed
      double? actualWeight;
      int? actualReps;
      if (isCompleted) {
        actualWeight = completedSets[i].weight;
        actualReps = completedSets[i].reps;
      }

      // Calculate RIR: use AI value if available, otherwise derive from RPE,
      // otherwise fall back to the algorithmic pyramid.
      //
      // RIR ≈ 10 − RPE (standard RP-Strength mapping). The AI often emits
      // `target_rpe` (1–10) but not `target_rir`, so without this mapping the
      // pyramid intent gets dropped on the floor for Walking / Hollow Body
      // Hold / anything where the prompt chose RPE over RIR.
      int? rirFromRpe;
      if (setTarget?.targetRpe != null && setTarget!.targetRpe! > 0) {
        final rpe = setTarget.targetRpe!;
        rirFromRpe = (10 - rpe).clamp(0, 5);
      }
      final calculatedRir = setTarget?.targetRir ??
          rirFromRpe ??
          _calculateRir(setTarget?.setType, currentWorkingIndex, totalWorkingSets);

      // Get actual RIR from completed set log
      int? actualRir;
      if (isCompleted) {
        actualRir = completedSets[i].rir;
      }

      // Detect bodyweight / timed so the TARGET cell renders the right shape.
      final eqLower = (exercise.equipment ?? '').toLowerCase();
      final isBodyweightEx = eqLower.contains('bodyweight') ||
          eqLower.contains('body weight') ||
          eqLower == 'none' ||
          eqLower == 'no equipment';
      final isTimedEx = exercise.isTimedExercise;

      rows.add(SetRowData(
        setNumber: i + 1,
        isWarmup: setTarget?.isWarmup ?? false,
        isCompleted: isCompleted,
        isActive: isActive,
        isTimedExercise: isTimedEx,
        isBodyweight: isBodyweightEx,
        // Per-set hold target (planks, hollow body) — the true target.
        targetHoldSeconds: setTarget?.targetHoldSeconds ?? exercise.holdSeconds,
        // Exercise-level duration (cardio-style warmups like Walking).
        targetDurationSeconds: exercise.durationSeconds,
        // TARGET weight: use history → AI (if reliable) → equipment default
        // targetWeight is in kg internally — display layer converts to user's unit
        targetWeight: (() {
          // If a progression pattern wrote this setTarget, trust it directly
          final hasProgression = _exerciseProgressionPattern.containsKey(exerciseIndex);
          if (hasProgression && setTarget?.targetWeightKg != null && setTarget!.targetWeightKg! > 0) {
            return setTarget.targetWeightKg!;
          }
          // Otherwise: historical → previous session → equipment default
          final aiWt = setTarget?.targetWeightKg ?? exercise.weight?.toDouble();
          if (aiWt != null && !isGenericWeight(aiWt, exercise.weightSource)) {
            return aiWt;
          }
          if (prevWeight != null && prevWeight > 0) return prevWeight;
          final userProfile = ref.read(authStateProvider).user;
          final defaultDisplay = getDefaultWeight(exercise.equipment,
            exerciseName: exercise.name,
            fitnessLevel: userProfile?.fitnessLevel,
            gender: userProfile?.gender,
            useKg: _useKg);
          if (defaultDisplay <= 0) return aiWt;
          return _useKg ? defaultDisplay : defaultDisplay * 0.453592;
        })(),
        targetReps: setTarget?.targetReps != null ? setTarget!.targetReps.toString() : '${exercise.reps ?? 8}-${(exercise.reps ?? 8) + 2}',
        targetRir: calculatedRir,
        actualWeight: actualWeight,
        actualReps: actualReps,
        actualRir: actualRir,
        previousWeight: prevWeight,
        previousReps: prevReps,
        previousRir: prevRir,
        durationSeconds: isCompleted ? completedSets[i].durationSeconds : null,
        // Show rest taken AFTER this set (from actualRestDurations), not rest before
        restDurationSeconds: isCompleted
            ? (() {
                final rests = _actualRestDurations[exerciseIndex];
                return (rests != null && i < rests.length) ? rests[i] : null;
              })()
            : null,
      ));
    }

    return rows;
  }

  // ── Pre-Set Coaching Banner ─────────────────────────────────────────────
  //
  // The engine now exposes a per-set API (`PreSetInsightEngine.insightForSet`)
  // that returns a fresh insight for every focal row — not just pre-Set-1.
  // Behaviour summary:
  //   • Set 0 (pre-Set-1): full exercise-level insight (same patterns as
  //     before — "averaged 9 reps last session below 10-12 range, lighten up").
  //   • Set N > 0: per-set signals (RIR-drift on that specific set last
  //     session, rep-range miss on that set, PR-near using current stepper
  //     context). Returns null if nothing to say → banner collapses.
  //
  // Caches and dismiss-tracking are now keyed by (exerciseIndex, setIndex)
  // so dismissing set 3's banner doesn't silence set 4, and the cache never
  // bleeds between sets. `_preSetHistoryByExerciseName` is still prefetched
  // once per workout by `_prefetchPreSetHistory()` — no extra network calls.

  /// Returns the 0-based index of the *next* working set to log for the
  /// given exercise. Warmup sets don't advance this counter — they live on
  /// the rail but don't gate the banner.
  int _nextWorkingSetIndex(int exerciseIndex) {
    final logs = _completedSets[exerciseIndex] ?? const <SetLog>[];
    int count = 0;
    for (final l in logs) {
      if (l.setType.toLowerCase() == 'warmup') continue;
      if (l.reps <= 0) continue;
      count++;
    }
    return count;
  }

  @override
  String? preSetBannerMessageFor(int exerciseIndex) {
    // History still loading — skip silently; will pop in when ready.
    if (!_preSetHistoryLoaded) return null;
    if (exerciseIndex < 0 || exerciseIndex >= _exercises.length) return null;
    // Setting toggle off → no banner.
    if (!ref.read(preSetInsightEnabledProvider)) return null;

    final setIndex = _nextWorkingSetIndex(exerciseIndex);
    // Once the user finishes every set, the banner collapses permanently —
    // there's no "next set" to coach.
    final total = _totalSetsPerExercise[exerciseIndex] ?? 0;
    if (total > 0 && setIndex >= total) return null;

    // Per-set dismiss: dismissing set 3's banner doesn't silence set 4.
    final dismissKey = exerciseIndex * 100 + setIndex;
    if (_dismissedPreSetBannerIndices.contains(dismissKey)) return null;

    if (_cachedPreSetCopy.containsKey(dismissKey)) {
      return _cachedPreSetCopy[dismissKey];
    }

    final exercise = _exercises[exerciseIndex];
    final sessions = _preSetHistoryByExerciseName[exercise.name] ?? const [];
    final pattern = _exerciseProgressionPattern[exerciseIndex]
        ?? SetProgressionPattern.pyramidUp;

    // Parse today's target rep range from setTargets[0] → exercise.reps → skip.
    int? tmin;
    int? tmax;
    final firstWorking = (exercise.setTargets ?? const [])
        .where((t) => !t.isWarmup && t.targetReps > 0)
        .fold<SetTarget?>(null, (acc, t) => acc ?? t);
    if (firstWorking != null) {
      tmin = firstWorking.targetReps;
      tmax = firstWorking.targetReps;
    } else if (exercise.reps != null && exercise.reps! > 0) {
      tmin = exercise.reps;
      tmax = exercise.reps;
    }
    if (tmin == null || tmax == null) {
      _cachedPreSetCopy[dismissKey] = null;
      return null;
    }

    final isBodyweight = (exercise.weight == null || exercise.weight == 0) &&
        (exercise.equipment == null ||
         {'bodyweight', 'bodyweight_only', 'none', ''}
            .contains(exercise.equipment!.toLowerCase()));

    final now = DateTime.now();
    final todayIso = DateTime(now.year, now.month, now.day)
        .toIso8601String()
        .split('T')
        .first;

    final input = ExerciseInsightInput(
      exerciseId: exercise.id ?? exercise.name,
      targetMinReps: tmin,
      targetMaxReps: tmax,
      pattern: pattern,
      isBodyweight: isBodyweight,
      useKg: _useKg,
      todayIso: todayIso,
      workoutStartEpochMs: _workoutStartEpochMs,
      history: sessions,
    );

    // Supply current focal-set context for the PR-near signal when available.
    // Advanced leaves the weight/reps steppers bound to live controllers —
    // pull their numeric values and convert back to kg for the engine.
    double? currentWeightKg;
    int? currentReps;
    if (exerciseIndex == _viewingExerciseIndex) {
      final weightRaw = double.tryParse(_weightController.text);
      if (weightRaw != null && weightRaw > 0) {
        currentWeightKg = _useKg ? weightRaw : weightRaw * 0.453592;
      }
      final repsRaw = int.tryParse(_repsController.text);
      if (repsRaw != null && repsRaw > 0) currentReps = repsRaw;
    }

    final copy = PreSetInsightEngine.insightForSet(
      input: input,
      setIndex: setIndex,
      tone: InsightTone.advanced,
      currentWeightKg: currentWeightKg,
      currentReps: currentReps,
    );
    _cachedPreSetCopy[dismissKey] = copy;
    return copy;
  }

  @override
  void dismissPreSetBanner(int exerciseIndex) {
    final setIndex = _nextWorkingSetIndex(exerciseIndex);
    final dismissKey = exerciseIndex * 100 + setIndex;
    if (_dismissedPreSetBannerIndices.add(dismissKey)) {
      setState(() {});
    }
  }

  @override
  List<ActionChipData> buildActionChipsForCurrentExercise() {
    // Get current progression pattern for this exercise
    final pattern = _exerciseProgressionPattern[_viewingExerciseIndex]
        ?? SetProgressionPattern.pyramidUp;

    // Get increment display string in user's unit
    final exercise = _exercises[_viewingExerciseIndex];
    final incrementState = ref.read(weightIncrementsProvider);
    final incrementValue = incrementState.getIncrement(exercise.equipment);
    final incrementUnit = incrementState.unit;
    final incrementLabel = '±${incrementValue % 1 == 0 ? incrementValue.toInt() : incrementValue} $incrementUnit';

    return [
      WorkoutActionChips.adjustToday,
      WorkoutActionChips.progression(label: pattern.chipLabel, icon: pattern.icon),
      WorkoutActionChips.superset,
      WorkoutActionChips.leftRight(isActive: _isLeftRightMode),
      WorkoutActionChips.incrementDisplay(label: incrementLabel),
      WorkoutActionChips.more,
    ];
  }

  /// Open the one-tap "Adjust Today" sheet, await server mutation, and
  /// apply the result to the in-memory exercises list so the set table
  /// re-renders with the trimmed/eased workout. Shows an undo toast with a
  /// 5s window; undo restores the pre-adjustment snapshot.
  @override
  Future<void> showQuickAdjustSheetForCurrentWorkout() async {
    final workoutId = widget.workout.id;
    if (workoutId == null) return;

    // Compute remaining indices (exercises with sets still not completed).
    final remainingIndices = <int>[];
    int estimatedSecondsRemaining = 0;
    for (int i = 0; i < _exercises.length; i++) {
      final totalSets = _totalSetsPerExercise[i] ?? (_exercises[i].sets ?? 3);
      final completed = _completedSets[i]?.length ?? 0;
      if (completed < totalSets) {
        remainingIndices.add(i);
        // 90s per set (work+rest) + 30s transition — matches server estimate.
        estimatedSecondsRemaining += (totalSets - completed) * 90 + 30;
      }
    }
    final estimatedMinutes =
        (estimatedSecondsRemaining / 60).ceil().clamp(1, 240);

    // Snapshot for undo. If the user taps undo within 5s we re-assign.
    final snapshot = List<WorkoutExercise>.from(_exercises);
    final snapshotTotalSets = Map<int, int>.from(_totalSetsPerExercise);

    final result = await showQuickAdjustSheet(
      context: context,
      ref: ref,
      workoutId: int.tryParse(workoutId) ?? 0,
      remainingIndices: remainingIndices,
      currentEstimatedMinutes: estimatedMinutes,
    );

    if (!mounted || result == null) return;

    if (result.shouldReschedule) {
      // Defer the reschedule flow to existing infra — show a confirm sheet.
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.coachMessage.isNotEmpty
            ? result.coachMessage
            : 'Reschedule today\'s workout?'),
        duration: const Duration(seconds: 4),
      ));
      return;
    }

    // Apply the server's updated exercises list to in-memory state so the
    // set-tracking table re-renders immediately.
    if (result.updatedExercises != null && result.updatedExercises!.isNotEmpty) {
      setState(() {
        // Replace exercises with the server-updated list. We convert via the
        // WorkoutExercise model so downstream widgets see the same shape.
        _exercises = result.updatedExercises!
            .map((e) => WorkoutExercise.fromJson(e))
            .toList();
        // Recompute total-sets map for the new list.
        _totalSetsPerExercise.clear();
        for (int i = 0; i < _exercises.length; i++) {
          _totalSetsPerExercise[i] = _exercises[i].sets ?? 3;
        }
        // Keep viewing index in-bounds after possible trim.
        if (_viewingExerciseIndex >= _exercises.length) {
          _viewingExerciseIndex = _exercises.length - 1;
        }
        if (_currentExerciseIndex >= _exercises.length) {
          _currentExerciseIndex = _exercises.length - 1;
        }
      });
    }

    // Non-blocking undo toast.
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result.coachMessage.isNotEmpty
          ? result.coachMessage
          : 'Workout adapted.'),
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () {
          if (!mounted) return;
          setState(() {
            _exercises = snapshot;
            _totalSetsPerExercise
              ..clear()
              ..addAll(snapshotTotalSets);
          });
        },
      ),
    ));
  }

  /// Show progression model selector bottom sheet.
  @override
  void showProgressionSheetImpl() {
    final exercise = _exercises[_viewingExerciseIndex];
    final currentPattern = _exerciseProgressionPattern[_viewingExerciseIndex]
        ?? SetProgressionPattern.pyramidUp;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Get working weight and increment for preview strings
    final incrementState = ref.read(weightIncrementsProvider);
    final increment = incrementState.getIncrement(exercise.equipment);
    final unit = incrementState.unit;
    final workingWeight = exercise.weight?.toDouble() ??
        (double.tryParse(_weightController.text) ?? 50);
    final baseReps = exercise.reps ?? 10;
    final totalSets = _totalSetsPerExercise[_viewingExerciseIndex] ?? 3;

    showGlassSheet<SetProgressionPattern>(
      context: context,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(GlassSheetStyle.borderRadius)),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: GlassSheetStyle.blurSigma,
            sigmaY: GlassSheetStyle.blurSigma,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: GlassSheetStyle.backgroundColor(isDark),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(GlassSheetStyle.borderRadius)),
              border: Border(
                top: BorderSide(
                  color: GlassSheetStyle.borderColor(isDark),
                  width: 0.5,
                ),
              ),
            ),
            child: DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.7,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              builder: (ctx, scrollController) {
                final exTypePreview = FatigueService.getExerciseType(exercise.muscleGroup, exercise.name);
                final userGoalPreview = ref.read(authStateProvider).user?.primaryGoal;
                return _ProgressionSelectorSheet(
                  currentPattern: currentPattern,
                  workingWeight: workingWeight,
                  totalSets: totalSets,
                  baseReps: baseReps,
                  increment: increment,
                  unit: unit,
                  isDark: isDark,
                  scrollController: scrollController,
                  trainingGoal: userGoalPreview,
                  exerciseType: exTypePreview,
                  onSelect: (pattern) {
                    Navigator.of(ctx).pop(pattern);
                  },
                );
              },
            ),
          ),
        ),
      ),
    ).then((selected) {
      if (selected != null && selected != currentPattern) {
        applyProgressionPattern(selected);
      }
    });
  }

  /// Show exercise details sheet (muscles, description, etc.)
  /// Hybrid approach: shows static data immediately, then loads AI insights
  @override
  void showExerciseDetailsSheet(WorkoutExercise exercise) {
    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        child: _ExerciseDetailsSheetContent(
          exercise: exercise,
        ),
      ),
    );
  }

  /// Show exercise add sheet during active workout
  @override
  Future<void> showExerciseAddSheetImpl() async {
    HapticFeedback.lightImpact();
    final workoutId = widget.workout.id;
    if (workoutId == null) return;

    final currentExerciseNames = _exercises.map((e) => e.name).toList();
    final updatedWorkout = await showExerciseAddSheet(
      context,
      ref,
      workoutId: workoutId,
      workoutType: widget.workout.type ?? 'strength',
      currentExerciseNames: currentExerciseNames,
    );

    if (updatedWorkout != null && mounted) {
      final oldCount = _exercises.length;
      setState(() {
        _exercises.clear();
        _exercises.addAll(updatedWorkout.exercises);
        precomputeSupersetIndices();
        // Initialize tracking for NEW exercises only — preserve existing tracking
        for (int i = oldCount; i < _exercises.length; i++) {
          _completedSets[i] = [];
          final exercise = _exercises[i];
          _totalSetsPerExercise[i] = exercise.hasSetTargets &&
                  exercise.setTargets!.isNotEmpty
              ? exercise.setTargets!.length
              : exercise.sets ?? 3;
          _previousSets[i] = [];
        }
      });
      // Fetch smart weight suggestions for new exercises
      for (int i = oldCount; i < _exercises.length; i++) {
        fetchSmartWeightForExercise(_exercises[i]);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_exercises.length - oldCount} exercise(s) added'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Save workout weight unit preference to backend (non-blocking).
  /// Uses direct API call to avoid refreshing auth state (which would navigate away from workout).
  @override
  Future<void> saveWeightUnitPreference(String unit) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();
      if (userId == null) return;
      await apiClient.put(
        '/users/$userId',
        data: {'workout_weight_unit': unit},
      );
      debugPrint('✅ [WorkoutWeightUnit] Saved preference: $unit');
    } catch (e) {
      debugPrint('⚠️ [WorkoutWeightUnit] Failed to save preference: $e');
    }
  }

  /// Get last session data for an exercise (from _previousSets)
  @override
  Map<String, dynamic>? getLastSessionData(int exerciseIndex) {
    final previousSets = _previousSets[exerciseIndex];
    if (previousSets == null || previousSets.isEmpty) {
      return null;
    }

    // Get the first set from previous session as "last" data
    final lastSet = previousSets.first;
    final weight = lastSet['weight'] as double?;
    final reps = lastSet['reps'] as int?;
    final date = lastSet['date'] as String?;

    if (weight != null && reps != null) {
      return {
        'weight': weight,
        'reps': reps,
        'date': date,
      };
    }
    return null;
  }

  /// Get PR data for an exercise (from _exerciseMaxWeights)
  @override
  Map<String, dynamic>? getPrData(int exerciseIndex) {
    if (exerciseIndex >= _exercises.length) return null;

    final exercise = _exercises[exerciseIndex];
    final prWeight = _exerciseMaxWeights[exercise.name];

    if (prWeight != null && prWeight > 0) {
      // We don't store PR reps, so estimate based on typical ranges
      // In a real implementation, you'd store both weight and reps for PR
      return {
        'weight': prWeight,
        'reps': 1, // Placeholder - ideally store actual PR reps
      };
    }
    return null;
  }

  /// Show exercise swap sheet for replacing an exercise
  @override
  Future<void> showSwapSheetForIndex(int exerciseIndex) async {
    if (exerciseIndex >= _exercises.length) return;
    final workoutId = widget.workout.id;
    if (workoutId == null) return;

    final exercise = _exercises[exerciseIndex];

    final updatedWorkout = await showExerciseSwapSheet(
      context,
      ref,
      workoutId: workoutId,
      exercise: exercise,
    );

    if (updatedWorkout != null && mounted) {
      // Update local state with the swapped exercise
      setState(() {
        _exercises.clear();
        _exercises.addAll(updatedWorkout.exercises);
        precomputeSupersetIndices();
        // Only reinitialize tracking for the swapped exercise — preserve others
        final swappedExercise = _exercises[exerciseIndex];
        _completedSets[exerciseIndex] = [];
        _totalSetsPerExercise[exerciseIndex] = swappedExercise.hasSetTargets &&
                swappedExercise.setTargets!.isNotEmpty
            ? swappedExercise.setTargets!.length
            : swappedExercise.sets ?? 3;
        _previousSets[exerciseIndex] = [];
      });

      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exercise swapped successfully'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

}
