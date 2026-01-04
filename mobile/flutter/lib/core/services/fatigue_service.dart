/// Fatigue Detection Service
///
/// Provides methods to check for fatigue during active workouts
/// and get AI-recommended parameters for the next set.
library;

import 'package:dio/dio.dart';

import '../../screens/workout/widgets/fatigue_alert_modal.dart';
import '../../screens/workout/widgets/next_set_preview_card.dart';

/// Set data for fatigue check requests
class FatigueSetData {
  final int reps;
  final double weight;
  final int? rpe;
  final int? rir;
  final bool isFailure;
  final int? targetReps;

  const FatigueSetData({
    required this.reps,
    required this.weight,
    this.rpe,
    this.rir,
    this.isFailure = false,
    this.targetReps,
  });

  Map<String, dynamic> toJson() {
    return {
      'reps': reps,
      'weight': weight,
      'rpe': rpe,
      'rir': rir,
      'is_failure': isFailure,
      'target_reps': targetReps,
    };
  }
}

/// Service for fatigue detection API calls
class FatigueService {
  /// Check for fatigue based on completed sets
  ///
  /// Returns a [FatigueAlertData] with detection results.
  /// Returns null if the API call fails.
  static Future<FatigueAlertData?> checkFatigue({
    required Dio dio,
    required List<FatigueSetData> setsData,
    required double currentWeight,
    String exerciseType = 'compound',
    int? targetReps,
  }) async {
    try {
      print('🔍 [FatigueService] Checking fatigue with ${setsData.length} sets');

      final response = await dio.post(
        '/workouts/fatigue-check',
        data: {
          'sets_data': setsData.map((s) => s.toJson()).toList(),
          'current_weight': currentWeight,
          'exercise_type': exerciseType,
          'target_reps': targetReps,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final alertData = FatigueAlertData.fromJson(
          response.data as Map<String, dynamic>,
        );
        print('✅ [FatigueService] Fatigue check complete: '
            'detected=${alertData.fatigueDetected}, '
            'severity=${alertData.severityLabel}');
        return alertData;
      }

      print('⚠️ [FatigueService] Unexpected response: ${response.statusCode}');
      return null;
    } on DioException catch (e) {
      print('❌ [FatigueService] DioException: ${e.message}');
      return null;
    } catch (e) {
      print('❌ [FatigueService] Error checking fatigue: $e');
      return null;
    }
  }

  /// Get AI-recommended parameters for the next set
  ///
  /// Returns a [NextSetPreviewData] with recommendations.
  /// Returns null if the API call fails.
  static Future<NextSetPreviewData?> getNextSetPreview({
    required Dio dio,
    required List<FatigueSetData> setsData,
    required int currentSetNumber,
    required int totalSets,
    required int targetReps,
    required double currentWeight,
    double? estimated1RM,
    double targetIntensity = 0.75,
  }) async {
    try {
      print('🔍 [FatigueService] Getting next set preview for set '
          '${currentSetNumber + 1}/$totalSets');

      final response = await dio.post(
        '/workouts/next-set-preview',
        data: {
          'sets_data': setsData.map((s) => s.toJson()).toList(),
          'current_set_number': currentSetNumber,
          'total_sets': totalSets,
          'target_reps': targetReps,
          'current_weight': currentWeight,
          'estimated_1rm': estimated1RM,
          'target_intensity': targetIntensity,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final previewData = NextSetPreviewData.fromJson(
          response.data as Map<String, dynamic>,
        );
        print('✅ [FatigueService] Next set preview: '
            '${previewData.recommendedWeight}kg x ${previewData.recommendedReps}');
        return previewData;
      }

      print('⚠️ [FatigueService] Unexpected response: ${response.statusCode}');
      return null;
    } on DioException catch (e) {
      print('❌ [FatigueService] DioException: ${e.message}');
      return null;
    } catch (e) {
      print('❌ [FatigueService] Error getting next set preview: $e');
      return null;
    }
  }

  /// Combined fatigue check and next set preview in one call
  ///
  /// More efficient when you need both pieces of information.
  static Future<({FatigueAlertData? fatigue, NextSetPreviewData? preview})>
      checkFatigueWithPreview({
    required Dio dio,
    required List<FatigueSetData> setsData,
    required double currentWeight,
    required int currentSetNumber,
    required int totalSets,
    String exerciseType = 'compound',
    int? targetReps,
  }) async {
    try {
      print('🔍 [FatigueService] Combined check for set '
          '${currentSetNumber + 1}/$totalSets');

      final response = await dio.post(
        '/workouts/fatigue-check-with-preview',
        queryParameters: {
          'current_set_number': currentSetNumber,
          'total_sets': totalSets,
        },
        data: {
          'sets_data': setsData.map((s) => s.toJson()).toList(),
          'current_weight': currentWeight,
          'exercise_type': exerciseType,
          'target_reps': targetReps,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;

        FatigueAlertData? fatigueData;
        NextSetPreviewData? previewData;

        if (data['fatigue'] != null) {
          fatigueData = FatigueAlertData.fromJson(
            data['fatigue'] as Map<String, dynamic>,
          );
        }

        if (data['next_set'] != null) {
          previewData = NextSetPreviewData.fromJson(
            data['next_set'] as Map<String, dynamic>,
          );
        }

        print('✅ [FatigueService] Combined check complete: '
            'fatigue=${fatigueData?.fatigueDetected ?? false}, '
            'preview=${previewData?.recommendedWeight ?? 0}kg');

        return (fatigue: fatigueData, preview: previewData);
      }

      print('⚠️ [FatigueService] Unexpected response: ${response.statusCode}');
      return (fatigue: null, preview: null);
    } on DioException catch (e) {
      print('❌ [FatigueService] DioException: ${e.message}');
      return (fatigue: null, preview: null);
    } catch (e) {
      print('❌ [FatigueService] Error in combined check: $e');
      return (fatigue: null, preview: null);
    }
  }

  /// Determine exercise type from muscle group or exercise name
  static String getExerciseType(String? muscleGroup, String exerciseName) {
    final nameLower = exerciseName.toLowerCase();
    final muscleLower = muscleGroup?.toLowerCase() ?? '';

    // Compound exercises (multi-joint)
    final compoundKeywords = [
      'squat',
      'deadlift',
      'bench press',
      'overhead press',
      'row',
      'pull-up',
      'chin-up',
      'lunge',
      'dip',
      'clean',
      'snatch',
    ];

    for (final keyword in compoundKeywords) {
      if (nameLower.contains(keyword)) {
        return 'compound';
      }
    }

    // Bodyweight exercises
    final bodyweightKeywords = [
      'push-up',
      'pushup',
      'plank',
      'crunch',
      'sit-up',
      'situp',
      'mountain climber',
      'burpee',
      'jumping jack',
    ];

    for (final keyword in bodyweightKeywords) {
      if (nameLower.contains(keyword)) {
        return 'bodyweight';
      }
    }

    // Muscle group based classification
    if (muscleLower.contains('leg') ||
        muscleLower.contains('chest') ||
        muscleLower.contains('back')) {
      return 'compound';
    }

    if (muscleLower.contains('bicep') ||
        muscleLower.contains('tricep') ||
        muscleLower.contains('forearm') ||
        muscleLower.contains('calf')) {
      return 'isolation';
    }

    // Default to compound (safer for weight recommendations)
    return 'compound';
  }
}
