import 'package:flutter/foundation.dart';

/// 6-axis fitness profile powering the Discover peek sheet's dual-overlay
/// radar chart. Returned by GET /api/v1/leaderboard/user-profile/{id}.
///
/// Axis order (indices 0-5): Strength, Muscle, Recovery, Consistency,
/// Endurance, Nutrition. Each value 0.0-1.0.
@immutable
class FitnessProfile {
  /// Target user's scores. `null` entries mean the axis is privacy-hidden OR
  /// the user has 0 data on that axis (caller decides how to render).
  final List<double?> targetScores;

  /// Viewer's own scores. Drawn on top of target's shape in the radar.
  final List<double?> viewerScores;

  /// Target user's bio. Null if not set or stats are hidden.
  final String? targetBio;

  /// True when target has `profile_stats_visible = false`. Peek sheet should
  /// collapse the radar + bio in favor of a "Stats hidden" message.
  final bool targetStatsHidden;

  /// Axis labels matching the index order of the score lists.
  final List<String> axisLabels;

  const FitnessProfile({
    required this.targetScores,
    required this.viewerScores,
    this.targetBio,
    this.targetStatsHidden = false,
    this.axisLabels = const [
      'Strength', 'Muscle', 'Recovery',
      'Consistency', 'Endurance', 'Nutrition',
    ],
  });

  factory FitnessProfile.fromJson(Map<String, dynamic> json) {
    List<double?> parseList(dynamic raw) {
      if (raw is! List) return List.filled(6, null);
      return raw.map((v) => v == null ? null : (v as num).toDouble()).toList();
    }

    return FitnessProfile(
      targetScores: parseList(json['target_scores']),
      viewerScores: parseList(json['viewer_scores']),
      targetBio: json['target_bio'] as String?,
      targetStatsHidden: json['target_stats_hidden'] as bool? ?? false,
      axisLabels: (json['axis_labels'] as List?)?.cast<String>() ??
          const [
            'Strength', 'Muscle', 'Recovery',
            'Consistency', 'Endurance', 'Nutrition',
          ],
    );
  }

  /// Whether the target has zero activity across all 6 axes — used to show
  /// the "log your first workout to build your shape" placeholder instead
  /// of an empty radar dot.
  bool get targetIsEmpty {
    if (targetStatsHidden) return false; // different state
    return targetScores.every((v) => v == null || v == 0.0);
  }

  /// Axis values with nulls coerced to 0 for rendering the radar shape.
  List<double> targetForRadar() =>
      targetScores.map((v) => v ?? 0.0).toList(growable: false);

  List<double> viewerForRadar() =>
      viewerScores.map((v) => v ?? 0.0).toList(growable: false);
}
