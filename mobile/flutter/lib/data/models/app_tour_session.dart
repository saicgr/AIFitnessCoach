import 'package:json_annotation/json_annotation.dart';

part 'app_tour_session.g.dart';

/// Status of the tour session
enum TourStatus {
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('completed')
  completed,
  @JsonValue('skipped')
  skipped,
}

/// The source from which the tour was started
enum TourSource {
  @JsonValue('first_launch')
  firstLaunch,
  @JsonValue('settings_restart')
  settingsRestart,
  @JsonValue('marketing')
  marketing,
  @JsonValue('deep_link')
  deepLink,
}

/// Represents a complete app tour session with tracking data.
///
/// This model tracks the user's progress through the onboarding tour,
/// including which steps they've completed, interactions with demos,
/// and analytics for understanding user behavior.
@JsonSerializable()
class AppTourSession {
  /// Unique session identifier
  @JsonKey(name: 'session_id')
  final String sessionId;

  /// User ID if authenticated, null for guest/anonymous
  @JsonKey(name: 'user_id')
  final String? userId;

  /// Device identifier for anonymous tracking
  @JsonKey(name: 'device_id')
  final String? deviceId;

  /// How the tour was initiated
  final TourSource source;

  /// List of step IDs that have been completed
  @JsonKey(name: 'steps_completed')
  final List<String> stepsCompleted;

  /// Currently active step ID
  @JsonKey(name: 'current_step')
  final String currentStep;

  /// Current status of the tour
  final TourStatus status;

  /// When the tour session started
  @JsonKey(name: 'started_at')
  final DateTime startedAt;

  /// When the tour was completed (null if not completed)
  @JsonKey(name: 'completed_at')
  final DateTime? completedAt;

  /// When the tour was skipped (null if not skipped)
  @JsonKey(name: 'skipped_at')
  final DateTime? skippedAt;

  /// The step at which the tour was skipped (null if not skipped)
  @JsonKey(name: 'skip_step')
  final String? skipStep;

  /// Whether the user started a demo workout during the tour
  @JsonKey(name: 'demo_workout_started')
  final bool demoWorkoutStarted;

  /// Whether the user completed a demo workout during the tour
  @JsonKey(name: 'demo_workout_completed')
  final bool demoWorkoutCompleted;

  /// Whether the user viewed the plan preview
  @JsonKey(name: 'plan_preview_viewed')
  final bool planPreviewViewed;

  /// List of deep link routes clicked during the tour
  @JsonKey(name: 'deep_links_clicked')
  final List<String> deepLinksClicked;

  /// Total duration of the tour in seconds
  @JsonKey(name: 'duration_seconds')
  final int? durationSeconds;

  const AppTourSession({
    required this.sessionId,
    this.userId,
    this.deviceId,
    this.source = TourSource.firstLaunch,
    this.stepsCompleted = const [],
    required this.currentStep,
    this.status = TourStatus.inProgress,
    required this.startedAt,
    this.completedAt,
    this.skippedAt,
    this.skipStep,
    this.demoWorkoutStarted = false,
    this.demoWorkoutCompleted = false,
    this.planPreviewViewed = false,
    this.deepLinksClicked = const [],
    this.durationSeconds,
  });

  factory AppTourSession.fromJson(Map<String, dynamic> json) =>
      _$AppTourSessionFromJson(json);

  Map<String, dynamic> toJson() => _$AppTourSessionToJson(this);

  /// Create a copy with modified properties
  AppTourSession copyWith({
    String? sessionId,
    String? userId,
    String? deviceId,
    TourSource? source,
    List<String>? stepsCompleted,
    String? currentStep,
    TourStatus? status,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? skippedAt,
    String? skipStep,
    bool? demoWorkoutStarted,
    bool? demoWorkoutCompleted,
    bool? planPreviewViewed,
    List<String>? deepLinksClicked,
    int? durationSeconds,
  }) {
    return AppTourSession(
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      deviceId: deviceId ?? this.deviceId,
      source: source ?? this.source,
      stepsCompleted: stepsCompleted ?? this.stepsCompleted,
      currentStep: currentStep ?? this.currentStep,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      skippedAt: skippedAt ?? this.skippedAt,
      skipStep: skipStep ?? this.skipStep,
      demoWorkoutStarted: demoWorkoutStarted ?? this.demoWorkoutStarted,
      demoWorkoutCompleted: demoWorkoutCompleted ?? this.demoWorkoutCompleted,
      planPreviewViewed: planPreviewViewed ?? this.planPreviewViewed,
      deepLinksClicked: deepLinksClicked ?? this.deepLinksClicked,
      durationSeconds: durationSeconds ?? this.durationSeconds,
    );
  }

  /// Check if the tour is complete
  bool get isCompleted => status == TourStatus.completed;

  /// Check if the tour was skipped
  bool get isSkipped => status == TourStatus.skipped;

  /// Check if the tour is still in progress
  bool get isInProgress => status == TourStatus.inProgress;

  /// Get the number of completed steps
  int get completedStepCount => stepsCompleted.length;
}

/// Response from the tour start API endpoint
@JsonSerializable()
class TourStartResponse {
  /// The session ID for tracking this tour
  @JsonKey(name: 'session_id')
  final String sessionId;

  /// Whether the tour should be shown to this user
  @JsonKey(name: 'should_show_tour')
  final bool shouldShowTour;

  /// Configuration for the tour (optional customization)
  @JsonKey(name: 'tour_config')
  final TourConfig? tourConfig;

  /// When the tour session started
  @JsonKey(name: 'started_at')
  final DateTime startedAt;

  const TourStartResponse({
    required this.sessionId,
    required this.shouldShowTour,
    this.tourConfig,
    required this.startedAt,
  });

  factory TourStartResponse.fromJson(Map<String, dynamic> json) =>
      _$TourStartResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TourStartResponseToJson(this);
}

/// Configuration options for the tour experience
@JsonSerializable()
class TourConfig {
  /// Total number of steps in the tour
  @JsonKey(name: 'total_steps')
  final int totalSteps;

  /// List of step configurations
  final List<TourStepConfig> steps;

  /// Whether the user can skip the entire tour
  @JsonKey(name: 'allow_skip_tour')
  final bool allowSkipTour;

  /// Whether to show the demo workout CTA
  @JsonKey(name: 'show_demo_workout_cta')
  final bool showDemoWorkoutCta;

  const TourConfig({
    required this.totalSteps,
    this.steps = const [],
    this.allowSkipTour = true,
    this.showDemoWorkoutCta = true,
  });

  factory TourConfig.fromJson(Map<String, dynamic> json) =>
      _$TourConfigFromJson(json);

  Map<String, dynamic> toJson() => _$TourConfigToJson(this);
}

/// Configuration for a single tour step
@JsonSerializable()
class TourStepConfig {
  /// Step identifier
  final String id;

  /// Step title (can be overridden from backend)
  final String title;

  /// Whether this step can be skipped individually
  @JsonKey(name: 'can_skip')
  final bool canSkip;

  const TourStepConfig({
    required this.id,
    required this.title,
    this.canSkip = true,
  });

  factory TourStepConfig.fromJson(Map<String, dynamic> json) =>
      _$TourStepConfigFromJson(json);

  Map<String, dynamic> toJson() => _$TourStepConfigToJson(this);
}

/// Response from step completion API
@JsonSerializable()
class StepCompletedResponse {
  /// Whether the step was successfully recorded
  final bool success;

  /// The step that was completed
  @JsonKey(name: 'step_id')
  final String stepId;

  /// Time spent on this step in seconds
  @JsonKey(name: 'time_spent_seconds')
  final int? timeSpentSeconds;

  /// Whether there are more steps remaining
  @JsonKey(name: 'has_more_steps')
  final bool hasMoreSteps;

  /// Next step ID (null if this was the last step)
  @JsonKey(name: 'next_step_id')
  final String? nextStepId;

  const StepCompletedResponse({
    required this.success,
    required this.stepId,
    this.timeSpentSeconds,
    required this.hasMoreSteps,
    this.nextStepId,
  });

  factory StepCompletedResponse.fromJson(Map<String, dynamic> json) =>
      _$StepCompletedResponseFromJson(json);

  Map<String, dynamic> toJson() => _$StepCompletedResponseToJson(this);
}

/// Response from tour completion API
@JsonSerializable()
class TourCompletedResponse {
  /// Whether the tour was successfully completed
  final bool success;

  /// Total duration of the tour in seconds
  @JsonKey(name: 'total_duration_seconds')
  final int totalDurationSeconds;

  /// Number of steps completed
  @JsonKey(name: 'steps_completed_count')
  final int stepsCompletedCount;

  /// Whether demo workout was started
  @JsonKey(name: 'demo_workout_started')
  final bool demoWorkoutStarted;

  /// Message to show the user
  final String? message;

  const TourCompletedResponse({
    required this.success,
    required this.totalDurationSeconds,
    required this.stepsCompletedCount,
    this.demoWorkoutStarted = false,
    this.message,
  });

  factory TourCompletedResponse.fromJson(Map<String, dynamic> json) =>
      _$TourCompletedResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TourCompletedResponseToJson(this);
}

/// Response from tour status check API
@JsonSerializable()
class TourStatusResponse {
  /// Whether the tour should be shown
  @JsonKey(name: 'should_show_tour')
  final bool shouldShowTour;

  /// Reason for the decision
  final String? reason;

  /// Previous session info if exists
  @JsonKey(name: 'previous_session')
  final AppTourSession? previousSession;

  const TourStatusResponse({
    required this.shouldShowTour,
    this.reason,
    this.previousSession,
  });

  factory TourStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$TourStatusResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TourStatusResponseToJson(this);
}
