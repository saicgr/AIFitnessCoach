/// Body Analyzer models.
///
/// Mirrors backend Pydantic schemas in `backend/models/gemini_schemas.py`
/// plus the row shape of `public.body_analyzer_snapshots` and
/// `public.program_retune_proposals`.
library;

import 'package:json_annotation/json_annotation.dart';

part 'body_analyzer.g.dart';

/// One posture issue Gemini flagged in the photos.
@JsonSerializable()
class PostureFinding {
  final String issue; // forward_head_posture | rounded_shoulders | anterior_pelvic_tilt | uneven_shoulders | knee_valgus | scapular_winging
  final int severity; // 1..3
  final String description;
  @JsonKey(name: 'corrective_exercise_tag')
  final String correctiveExerciseTag;

  const PostureFinding({
    required this.issue,
    required this.severity,
    required this.description,
    required this.correctiveExerciseTag,
  });

  factory PostureFinding.fromJson(Map<String, dynamic> json) =>
      _$PostureFindingFromJson(json);
  Map<String, dynamic> toJson() => _$PostureFindingToJson(this);
}

/// A persisted body_analyzer_snapshots row.
@JsonSerializable()
class BodyAnalyzerSnapshot {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'overall_rating')
  final int? overallRating;
  @JsonKey(name: 'body_type')
  final String? bodyType;
  @JsonKey(name: 'body_fat_percent')
  final double? bodyFatPercent;
  @JsonKey(name: 'muscle_mass_percent')
  final double? muscleMassPercent;
  @JsonKey(name: 'symmetry_score')
  final int? symmetryScore;
  @JsonKey(name: 'body_age')
  final int? bodyAge;
  @JsonKey(name: 'feedback_text')
  final String? feedbackText;
  @JsonKey(name: 'improvement_tips', defaultValue: <String>[])
  final List<String> improvementTips;
  @JsonKey(name: 'posture_findings', defaultValue: <PostureFinding>[])
  final List<PostureFinding> postureFindings;
  @JsonKey(name: 'front_photo_id')
  final String? frontPhotoId;
  @JsonKey(name: 'back_photo_id')
  final String? backPhotoId;
  @JsonKey(name: 'side_left_photo_id')
  final String? sideLeftPhotoId;
  @JsonKey(name: 'side_right_photo_id')
  final String? sideRightPhotoId;
  @JsonKey(name: 'created_at')
  final String? createdAt;

  const BodyAnalyzerSnapshot({
    required this.id,
    required this.userId,
    this.overallRating,
    this.bodyType,
    this.bodyFatPercent,
    this.muscleMassPercent,
    this.symmetryScore,
    this.bodyAge,
    this.feedbackText,
    this.improvementTips = const [],
    this.postureFindings = const [],
    this.frontPhotoId,
    this.backPhotoId,
    this.sideLeftPhotoId,
    this.sideRightPhotoId,
    this.createdAt,
  });

  factory BodyAnalyzerSnapshot.fromJson(Map<String, dynamic> json) =>
      _$BodyAnalyzerSnapshotFromJson(json);
  Map<String, dynamic> toJson() => _$BodyAnalyzerSnapshotToJson(this);
}

/// POST /body-analyzer/analyze request
@JsonSerializable()
class BodyAnalyzerRequest {
  @JsonKey(name: 'photo_ids')
  final List<String> photoIds;
  @JsonKey(name: 'include_measurements')
  final bool includeMeasurements;
  @JsonKey(name: 'user_context')
  final String? userContext;

  const BodyAnalyzerRequest({
    required this.photoIds,
    this.includeMeasurements = true,
    this.userContext,
  });

  factory BodyAnalyzerRequest.fromJson(Map<String, dynamic> json) =>
      _$BodyAnalyzerRequestFromJson(json);
  Map<String, dynamic> toJson() => _$BodyAnalyzerRequestToJson(this);
}

/// POST /body-analyzer/analyze response
@JsonSerializable()
class BodyAnalyzerAnalyzeResponse {
  final BodyAnalyzerSnapshot snapshot;
  @JsonKey(name: 'seeded_muscle_focus_points', defaultValue: false)
  final bool seededMuscleFocusPoints;

  const BodyAnalyzerAnalyzeResponse({
    required this.snapshot,
    this.seededMuscleFocusPoints = false,
  });

  factory BodyAnalyzerAnalyzeResponse.fromJson(Map<String, dynamic> json) =>
      _$BodyAnalyzerAnalyzeResponseFromJson(json);
}

/// Photo-measurement extraction result
@JsonSerializable()
class PhotoMeasurementEstimate {
  final String metric;
  @JsonKey(name: 'value_cm')
  final double valueCm;
  final double confidence;
  final String method;

  const PhotoMeasurementEstimate({
    required this.metric,
    required this.valueCm,
    required this.confidence,
    this.method = 'photo_ratio',
  });

  factory PhotoMeasurementEstimate.fromJson(Map<String, dynamic> json) =>
      _$PhotoMeasurementEstimateFromJson(json);
  Map<String, dynamic> toJson() => _$PhotoMeasurementEstimateToJson(this);
}

@JsonSerializable()
class PhotoMeasurementExtractionResponse {
  @JsonKey(defaultValue: <PhotoMeasurementEstimate>[])
  final List<PhotoMeasurementEstimate> estimates;
  @JsonKey(name: 'scale_reference_detected', defaultValue: false)
  final bool scaleReferenceDetected;
  @JsonKey(name: 'overall_confidence')
  final double overallConfidence;

  const PhotoMeasurementExtractionResponse({
    this.estimates = const [],
    this.scaleReferenceDetected = false,
    required this.overallConfidence,
  });

  factory PhotoMeasurementExtractionResponse.fromJson(Map<String, dynamic> json) =>
      _$PhotoMeasurementExtractionResponseFromJson(json);
}

/// Body age payload
@JsonSerializable()
class BodyAgeResult {
  @JsonKey(name: 'body_age')
  final int bodyAge;
  @JsonKey(name: 'chronological_age')
  final int chronologicalAge;
  final int delta;

  const BodyAgeResult({
    required this.bodyAge,
    required this.chronologicalAge,
    required this.delta,
  });

  factory BodyAgeResult.fromJson(Map<String, dynamic> json) =>
      _$BodyAgeResultFromJson(json);
}

/// Retune proposal — `proposalJson` holds the full structured deltas as a
/// free-form map so the UI can iterate without a second model layer.
@JsonSerializable()
class RetuneProposal {
  final String id;
  @JsonKey(name: 'body_analyzer_snapshot_id')
  final String bodyAnalyzerSnapshotId;
  @JsonKey(name: 'proposal_json')
  final Map<String, dynamic> proposalJson;
  final String reasoning;
  final double? confidence;
  final String status;
  @JsonKey(name: 'expires_at')
  final String? expiresAt;
  @JsonKey(name: 'created_at')
  final String? createdAt;

  const RetuneProposal({
    required this.id,
    required this.bodyAnalyzerSnapshotId,
    required this.proposalJson,
    required this.reasoning,
    this.confidence,
    required this.status,
    this.expiresAt,
    this.createdAt,
  });

  factory RetuneProposal.fromJson(Map<String, dynamic> json) =>
      _$RetuneProposalFromJson(json);
}

/// Preview diff (from /retune-proposal/{id}/preview).
@JsonSerializable()
class RetunePreview {
  final Map<String, dynamic> before;
  final Map<String, dynamic> after;
  @JsonKey(name: 'field_diffs', defaultValue: <Map<String, dynamic>>[])
  final List<Map<String, dynamic>> fieldDiffs;
  @JsonKey(name: 'muscle_focus_diffs', defaultValue: <Map<String, dynamic>>[])
  final List<Map<String, dynamic>> muscleFocusDiffs;
  final String reasoning;
  @JsonKey(name: 'posture_corrective_tags', defaultValue: <String>[])
  final List<String> postureCorrectiveTags;
  @JsonKey(name: 'priority_muscles', defaultValue: <String>[])
  final List<String> priorityMuscles;
  @JsonKey(name: 'rest_days_per_week_suggested')
  final int restDaysPerWeekSuggested;
  final double confidence;

  const RetunePreview({
    required this.before,
    required this.after,
    required this.fieldDiffs,
    required this.muscleFocusDiffs,
    required this.reasoning,
    required this.postureCorrectiveTags,
    required this.priorityMuscles,
    required this.restDaysPerWeekSuggested,
    required this.confidence,
  });

  factory RetunePreview.fromJson(Map<String, dynamic> json) =>
      _$RetunePreviewFromJson(json);
}

/// Apply response
@JsonSerializable()
class RetuneApplyResponse {
  @JsonKey(name: 'proposal_id')
  final String proposalId;
  final String status;
  @JsonKey(name: 'applied_at')
  final String appliedAt;
  @JsonKey(name: 'updated_user', defaultValue: <String, dynamic>{})
  final Map<String, dynamic> updatedUser;

  const RetuneApplyResponse({
    required this.proposalId,
    required this.status,
    required this.appliedAt,
    required this.updatedUser,
  });

  factory RetuneApplyResponse.fromJson(Map<String, dynamic> json) =>
      _$RetuneApplyResponseFromJson(json);
}

/// POST /body-analyzer/apply-posture-correctives response
@JsonSerializable()
class ApplyCorrectivesResponse {
  @JsonKey(name: 'exercises_added', defaultValue: <Map<String, dynamic>>[])
  final List<Map<String, dynamic>> exercisesAdded;
  @JsonKey(name: 'issues_addressed', defaultValue: <String>[])
  final List<String> issuesAddressed;

  const ApplyCorrectivesResponse({
    this.exercisesAdded = const [],
    this.issuesAddressed = const [],
  });

  factory ApplyCorrectivesResponse.fromJson(Map<String, dynamic> json) =>
      _$ApplyCorrectivesResponseFromJson(json);
}

/// Deload trigger
@JsonSerializable()
class DeloadCheckResult {
  @JsonKey(name: 'needs_deload')
  final bool needsDeload;
  final String reason;

  const DeloadCheckResult({required this.needsDeload, required this.reason});

  factory DeloadCheckResult.fromJson(Map<String, dynamic> json) =>
      _$DeloadCheckResultFromJson(json);
}

/// Audio coach brief
@JsonSerializable()
class AudioCoachBrief {
  @JsonKey(name: 'brief_id')
  final String briefId;
  @JsonKey(name: 'brief_date')
  final String briefDate;
  @JsonKey(name: 'script_text')
  final String scriptText;
  @JsonKey(name: 'audio_url')
  final String? audioUrl;
  @JsonKey(name: 'duration_seconds')
  final int? durationSeconds;
  @JsonKey(name: 'coach_persona_id')
  final String? coachPersonaId;
  @JsonKey(defaultValue: false)
  final bool listened;

  const AudioCoachBrief({
    required this.briefId,
    required this.briefDate,
    required this.scriptText,
    this.audioUrl,
    this.durationSeconds,
    this.coachPersonaId,
    this.listened = false,
  });

  factory AudioCoachBrief.fromJson(Map<String, dynamic> json) =>
      _$AudioCoachBriefFromJson(json);
}

/// Menstrual cycle log
@JsonSerializable()
class MenstrualCycleLog {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'cycle_start_date')
  final String cycleStartDate;
  @JsonKey(name: 'cycle_length_days', defaultValue: 28)
  final int cycleLengthDays;
  @JsonKey(name: 'period_length_days', defaultValue: 5)
  final int periodLengthDays;
  final String? notes;

  const MenstrualCycleLog({
    required this.id,
    required this.userId,
    required this.cycleStartDate,
    this.cycleLengthDays = 28,
    this.periodLengthDays = 5,
    this.notes,
  });

  factory MenstrualCycleLog.fromJson(Map<String, dynamic> json) =>
      _$MenstrualCycleLogFromJson(json);
  Map<String, dynamic> toJson() => _$MenstrualCycleLogToJson(this);
}

/// Weekly-volume-per-muscle row (feeds the bars widget).
@JsonSerializable()
class WeeklyVolumeEntry {
  @JsonKey(name: 'muscle_group')
  final String muscleGroup;
  @JsonKey(name: 'weekly_sets', defaultValue: 0)
  final int weeklySets;
  @JsonKey(name: 'weekly_volume_kg', defaultValue: 0.0)
  final double weeklyVolumeKg;
  @JsonKey(name: 'cap_sets')
  final int? capSets;
  @JsonKey(name: 'pct_of_cap')
  final double? pctOfCap;

  const WeeklyVolumeEntry({
    required this.muscleGroup,
    this.weeklySets = 0,
    this.weeklyVolumeKg = 0.0,
    this.capSets,
    this.pctOfCap,
  });

  factory WeeklyVolumeEntry.fromJson(Map<String, dynamic> json) =>
      _$WeeklyVolumeEntryFromJson(json);
}
