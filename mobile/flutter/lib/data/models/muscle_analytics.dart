import 'package:json_annotation/json_annotation.dart';
import 'package:intl/intl.dart';


part 'muscle_analytics_part_muscle_intensity.dart';
part 'muscle_analytics.g.dart';


// ============================================================================
// Muscle Heatmap Data
// ============================================================================

/// Intensity data for muscle body diagram visualization
@JsonSerializable()
class MuscleHeatmapData {
  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'time_range')
  final String timeRange;

  @JsonKey(name: 'muscle_intensities')
  final List<MuscleIntensity> muscleIntensities;

  @JsonKey(name: 'max_intensity')
  final double? maxIntensity;

  @JsonKey(name: 'min_intensity')
  final double? minIntensity;

  @JsonKey(name: 'last_updated')
  final String? lastUpdated;

  const MuscleHeatmapData({
    required this.userId,
    required this.timeRange,
    this.muscleIntensities = const [],
    this.maxIntensity,
    this.minIntensity,
    this.lastUpdated,
  });

  factory MuscleHeatmapData.fromJson(Map<String, dynamic> json) =>
      _$MuscleHeatmapDataFromJson(json);

  Map<String, dynamic> toJson() => _$MuscleHeatmapDataToJson(this);

  /// Get intensity for a specific muscle
  double getIntensityForMuscle(String muscleId) {
    final muscle = muscleIntensities.firstWhere(
      (m) => m.muscleId.toLowerCase() == muscleId.toLowerCase(),
      orElse: () => MuscleIntensity(muscleId: muscleId, intensity: 0),
    );
    return muscle.intensity;
  }

  /// Get normalized intensity (0-1) for a muscle
  double getNormalizedIntensity(String muscleId) {
    if (maxIntensity == null || maxIntensity == 0) return 0;
    return getIntensityForMuscle(muscleId) / maxIntensity!;
  }

  /// Get muscles sorted by intensity (highest first)
  List<MuscleIntensity> get sortedByIntensity {
    final sorted = List<MuscleIntensity>.from(muscleIntensities);
    sorted.sort((a, b) => b.intensity.compareTo(a.intensity));
    return sorted;
  }

  /// Get top N trained muscles
  List<MuscleIntensity> getTopMuscles(int count) {
    return sortedByIntensity.take(count).toList();
  }

  /// Get neglected muscles (below threshold)
  List<MuscleIntensity> getNeglectedMuscles({double threshold = 0.2}) {
    if (maxIntensity == null || maxIntensity == 0) return [];
    return muscleIntensities
        .where((m) => (m.intensity / maxIntensity!) < threshold)
        .toList();
  }

  /// Check if there's any data
  bool get hasData => muscleIntensities.isNotEmpty;
}

