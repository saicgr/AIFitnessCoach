// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_tour_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppTourSession _$AppTourSessionFromJson(Map<String, dynamic> json) =>
    AppTourSession(
      sessionId: json['session_id'] as String,
      userId: json['user_id'] as String?,
      deviceId: json['device_id'] as String?,
      source:
          $enumDecodeNullable(_$TourSourceEnumMap, json['source']) ??
          TourSource.firstLaunch,
      stepsCompleted:
          (json['steps_completed'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      currentStep: json['current_step'] as String,
      status:
          $enumDecodeNullable(_$TourStatusEnumMap, json['status']) ??
          TourStatus.inProgress,
      startedAt: DateTime.parse(json['started_at'] as String),
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
      skippedAt: json['skipped_at'] == null
          ? null
          : DateTime.parse(json['skipped_at'] as String),
      skipStep: json['skip_step'] as String?,
      demoWorkoutStarted: json['demo_workout_started'] as bool? ?? false,
      demoWorkoutCompleted: json['demo_workout_completed'] as bool? ?? false,
      planPreviewViewed: json['plan_preview_viewed'] as bool? ?? false,
      deepLinksClicked:
          (json['deep_links_clicked'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
    );

Map<String, dynamic> _$AppTourSessionToJson(AppTourSession instance) =>
    <String, dynamic>{
      'session_id': instance.sessionId,
      'user_id': instance.userId,
      'device_id': instance.deviceId,
      'source': _$TourSourceEnumMap[instance.source]!,
      'steps_completed': instance.stepsCompleted,
      'current_step': instance.currentStep,
      'status': _$TourStatusEnumMap[instance.status]!,
      'started_at': instance.startedAt.toIso8601String(),
      'completed_at': instance.completedAt?.toIso8601String(),
      'skipped_at': instance.skippedAt?.toIso8601String(),
      'skip_step': instance.skipStep,
      'demo_workout_started': instance.demoWorkoutStarted,
      'demo_workout_completed': instance.demoWorkoutCompleted,
      'plan_preview_viewed': instance.planPreviewViewed,
      'deep_links_clicked': instance.deepLinksClicked,
      'duration_seconds': instance.durationSeconds,
    };

const _$TourSourceEnumMap = {
  TourSource.firstLaunch: 'first_launch',
  TourSource.settingsRestart: 'settings_restart',
  TourSource.marketing: 'marketing',
  TourSource.deepLink: 'deep_link',
};

const _$TourStatusEnumMap = {
  TourStatus.inProgress: 'in_progress',
  TourStatus.completed: 'completed',
  TourStatus.skipped: 'skipped',
};

TourStartResponse _$TourStartResponseFromJson(Map<String, dynamic> json) =>
    TourStartResponse(
      sessionId: json['session_id'] as String,
      shouldShowTour: json['should_show_tour'] as bool,
      tourConfig: json['tour_config'] == null
          ? null
          : TourConfig.fromJson(json['tour_config'] as Map<String, dynamic>),
      startedAt: DateTime.parse(json['started_at'] as String),
    );

Map<String, dynamic> _$TourStartResponseToJson(TourStartResponse instance) =>
    <String, dynamic>{
      'session_id': instance.sessionId,
      'should_show_tour': instance.shouldShowTour,
      'tour_config': instance.tourConfig,
      'started_at': instance.startedAt.toIso8601String(),
    };

TourConfig _$TourConfigFromJson(Map<String, dynamic> json) => TourConfig(
  totalSteps: (json['total_steps'] as num).toInt(),
  steps:
      (json['steps'] as List<dynamic>?)
          ?.map((e) => TourStepConfig.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  allowSkipTour: json['allow_skip_tour'] as bool? ?? true,
  showDemoWorkoutCta: json['show_demo_workout_cta'] as bool? ?? true,
);

Map<String, dynamic> _$TourConfigToJson(TourConfig instance) =>
    <String, dynamic>{
      'total_steps': instance.totalSteps,
      'steps': instance.steps,
      'allow_skip_tour': instance.allowSkipTour,
      'show_demo_workout_cta': instance.showDemoWorkoutCta,
    };

TourStepConfig _$TourStepConfigFromJson(Map<String, dynamic> json) =>
    TourStepConfig(
      id: json['id'] as String,
      title: json['title'] as String,
      canSkip: json['can_skip'] as bool? ?? true,
    );

Map<String, dynamic> _$TourStepConfigToJson(TourStepConfig instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'can_skip': instance.canSkip,
    };

StepCompletedResponse _$StepCompletedResponseFromJson(
  Map<String, dynamic> json,
) => StepCompletedResponse(
  success: json['success'] as bool,
  stepId: json['step_id'] as String,
  timeSpentSeconds: (json['time_spent_seconds'] as num?)?.toInt(),
  hasMoreSteps: json['has_more_steps'] as bool,
  nextStepId: json['next_step_id'] as String?,
);

Map<String, dynamic> _$StepCompletedResponseToJson(
  StepCompletedResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'step_id': instance.stepId,
  'time_spent_seconds': instance.timeSpentSeconds,
  'has_more_steps': instance.hasMoreSteps,
  'next_step_id': instance.nextStepId,
};

TourCompletedResponse _$TourCompletedResponseFromJson(
  Map<String, dynamic> json,
) => TourCompletedResponse(
  success: json['success'] as bool,
  totalDurationSeconds: (json['total_duration_seconds'] as num).toInt(),
  stepsCompletedCount: (json['steps_completed_count'] as num).toInt(),
  demoWorkoutStarted: json['demo_workout_started'] as bool? ?? false,
  message: json['message'] as String?,
);

Map<String, dynamic> _$TourCompletedResponseToJson(
  TourCompletedResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'total_duration_seconds': instance.totalDurationSeconds,
  'steps_completed_count': instance.stepsCompletedCount,
  'demo_workout_started': instance.demoWorkoutStarted,
  'message': instance.message,
};

TourStatusResponse _$TourStatusResponseFromJson(Map<String, dynamic> json) =>
    TourStatusResponse(
      shouldShowTour: json['should_show_tour'] as bool,
      reason: json['reason'] as String?,
      previousSession: json['previous_session'] == null
          ? null
          : AppTourSession.fromJson(
              json['previous_session'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$TourStatusResponseToJson(TourStatusResponse instance) =>
    <String, dynamic>{
      'should_show_tour': instance.shouldShowTour,
      'reason': instance.reason,
      'previous_session': instance.previousSession,
    };
