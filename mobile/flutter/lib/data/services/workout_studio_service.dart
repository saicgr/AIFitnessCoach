import '../../core/constants/api_constants.dart';
import '../models/workout_studio_models.dart';
import 'api_client.dart';

/// Client for the Workout Customization Studio + adaptation engine.
/// Wraps the instant (no-LLM) backend endpoints:
///   POST /workouts/customize, /{id}/adapt, /{id}/shuffle, /{id}/feedback
///   GET/POST/PUT/DELETE /workout-presets
class WorkoutStudioService {
  final ApiClient _apiClient;
  WorkoutStudioService(this._apiClient);

  String get _base => ApiConstants.workouts;

  /// Live preview (no DB row) — fired on each slider change. Sub-second.
  Future<BuiltWorkout> preview(WorkoutBuildParams params) async {
    final res = await _apiClient.post(
      '$_base/customize',
      data: {'params': params.toJson(), 'persist': false},
    );
    return BuiltWorkout.fromJson(Map<String, dynamic>.from(res.data));
  }

  /// Persist what was previewed. Passing [prebuilt] guarantees WYSIWYG —
  /// the exact previewed workout is saved (no re-roll).
  Future<BuiltWorkout> persist(
    WorkoutBuildParams params, {
    BuiltWorkout? prebuilt,
    String? name,
  }) async {
    final res = await _apiClient.post(
      '$_base/customize',
      data: {
        'params': params.toJson(),
        'persist': true,
        if (name != null) 'name': name,
        if (prebuilt != null) 'prebuilt': prebuilt.toJson(),
      },
    );
    return BuiltWorkout.fromJson(Map<String, dynamic>.from(res.data));
  }

  /// Adapt an existing workout. [replaceInPlace] mutates the source (detail
  /// 'Adjust', client keeps an undo snapshot); otherwise a new workout is
  /// forked (preserves the original — chat 'I have back pain').
  Future<BuiltWorkout> adapt(
    String workoutId, {
    WorkoutBuildParams? params,
    String? constraintsText,
    bool replaceInPlace = false,
    BuiltWorkout? prebuilt,
  }) async {
    final res = await _apiClient.post(
      '$_base/$workoutId/adapt',
      data: {
        if (params != null) 'params': params.toJson(),
        if (constraintsText != null) 'constraints_text': constraintsText,
        'replace_in_place': replaceInPlace,
        if (prebuilt != null) 'prebuilt': prebuilt.toJson(),
      },
    );
    return BuiltWorkout.fromJson(Map<String, dynamic>.from(res.data));
  }

  /// Re-roll the same workout with fresh exercises (Surprise me).
  Future<BuiltWorkout> shuffle(String workoutId) async {
    final res = await _apiClient.post('$_base/$workoutId/shuffle');
    return BuiltWorkout.fromJson(Map<String, dynamic>.from(res.data));
  }

  /// Thumbs up (1) / down (-1) / clear (0) on a workout. Soft signal.
  Future<void> sendThumbs(String workoutId, int thumbs, {String? reason}) async {
    await _apiClient.post(
      '$_base/$workoutId/feedback',
      data: {'thumbs': thumbs, if (reason != null) 'reason': reason},
    );
  }

  // ── Presets ────────────────────────────────────────────────────────────

  Future<List<WorkoutPreset>> listPresets() async {
    final res = await _apiClient.get(ApiConstants.workoutPresets);
    final data = res.data;
    if (data is List) {
      return data
          .map((e) => WorkoutPreset.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  Future<WorkoutPreset> createPreset(String name, WorkoutBuildParams params) async {
    final res = await _apiClient.post(
      ApiConstants.workoutPresets,
      data: {'name': name, 'params': params.toJson()},
    );
    return WorkoutPreset.fromJson(Map<String, dynamic>.from(res.data));
  }

  Future<WorkoutPreset> updatePreset(String id,
      {String? name, WorkoutBuildParams? params}) async {
    final res = await _apiClient.put(
      '${ApiConstants.workoutPresets}/$id',
      data: {
        if (name != null) 'name': name,
        if (params != null) 'params': params.toJson(),
      },
    );
    return WorkoutPreset.fromJson(Map<String, dynamic>.from(res.data));
  }

  Future<void> deletePreset(String id) async {
    await _apiClient.delete('${ApiConstants.workoutPresets}/$id');
  }
}
