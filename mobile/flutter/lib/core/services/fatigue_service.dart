/// Fatigue Detection Service
///
/// Provides methods to check for fatigue during active workouts
/// and get AI-recommended parameters for the next set.
library;

import 'package:flutter/foundation.dart';
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
  final double? targetWeight;
  final int? targetRir;

  const FatigueSetData({
    required this.reps,
    required this.weight,
    this.rpe,
    this.rir,
    this.isFailure = false,
    this.targetReps,
    this.targetWeight,
    this.targetRir,
  });

  Map<String, dynamic> toJson() {
    return {
      'reps': reps,
      'weight': weight,
      'rpe': rpe,
      'rir': rir,
      'is_failure': isFailure,
      'target_reps': targetReps,
      'target_weight': targetWeight,
      'target_rir': targetRir,
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
    String? progressionPattern,
  }) async {
    try {
      debugPrint('🔍 [FatigueService] Checking fatigue with ${setsData.length} sets'
          '${progressionPattern != null ? ' (pattern: $progressionPattern)' : ''}');

      final response = await dio.post(
        '/workouts/fatigue-check',
        data: {
          'sets_data': setsData.map((s) => s.toJson()).toList(),
          'current_weight': currentWeight,
          'exercise_type': exerciseType,
          'target_reps': targetReps,
          'progression_pattern': progressionPattern,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final alertData = FatigueAlertData.fromJson(
          response.data as Map<String, dynamic>,
        );
        debugPrint('✅ [FatigueService] Fatigue check complete: '
            'detected=${alertData.fatigueDetected}, '
            'severity=${alertData.severityLabel}');
        return alertData;
      }

      debugPrint('⚠️ [FatigueService] Unexpected response: ${response.statusCode}');
      return null;
    } on DioException catch (e) {
      debugPrint('❌ [FatigueService] DioException: ${e.message}');
      debugPrint('❌ [FatigueService] Response: ${e.response?.statusCode} ${e.response?.data}');
      return null;
    } catch (e) {
      debugPrint('❌ [FatigueService] Error checking fatigue: $e');
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
      debugPrint('🔍 [FatigueService] Getting next set preview for set '
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
        debugPrint('✅ [FatigueService] Next set preview: '
            '${previewData.recommendedWeight}kg x ${previewData.recommendedReps}');
        return previewData;
      }

      debugPrint('⚠️ [FatigueService] Unexpected response: ${response.statusCode}');
      return null;
    } on DioException catch (e) {
      debugPrint('❌ [FatigueService] DioException: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('❌ [FatigueService] Error getting next set preview: $e');
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
      debugPrint('🔍 [FatigueService] Combined check for set '
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

        debugPrint('✅ [FatigueService] Combined check complete: '
            'fatigue=${fatigueData?.fatigueDetected ?? false}, '
            'preview=${previewData?.recommendedWeight ?? 0}kg');

        return (fatigue: fatigueData, preview: previewData);
      }

      debugPrint('⚠️ [FatigueService] Unexpected response: ${response.statusCode}');
      return (fatigue: null, preview: null);
    } on DioException catch (e) {
      debugPrint('❌ [FatigueService] DioException: ${e.message}');
      return (fatigue: null, preview: null);
    } catch (e) {
      debugPrint('❌ [FatigueService] Error in combined check: $e');
      return (fatigue: null, preview: null);
    }
  }

  /// Determine exercise type from muscle group or exercise name
  static String getExerciseType(String? muscleGroup, String exerciseName) {
    final nameLower = exerciseName.toLowerCase();
    final muscleLower = muscleGroup?.toLowerCase() ?? '';

    // Compound exercises (multi-joint)
    // Synced with backend COMPOUND_LOWER + COMPOUND_UPPER in exercise_data.py
    // Uses specific press variants to avoid false-positives (pressdown, Tate press)
    final compoundKeywords = [
      // Lower body compounds
      'squat', 'pistol', 'deadlift', 'rack pull',
      'hip thrust', 'glute bridge', 'good morning',
      'lunge', 'split squat', 'step-up', 'step up',
      'leg press', 'hack squat',
      'clean', 'snatch', 'jerk', 'thruster',
      // Upper body press variants (specific to avoid matching "pressdown")
      'bench press', 'chest press', 'floor press', 'spoto press',
      'incline press', 'decline press', 'hammer press', 'squeeze press',
      'close grip press', 'neutral grip press',
      'press flat', 'press incline', 'press decline',
      'overhead press', 'shoulder press', 'shoulders press', 'military press',
      'push press', 'arnold press', 'z press', 'strict press',
      'seesaw press', 'behind neck press',
      'one arm press', 'alternate press', 'single arm press',
      'palms in press', 'palms back press', 'palms-back press',
      'side press',
      'smith machine press', 'machine press', 'landmine press',
      'cable resistance band press', 'bench seated press', 'press under',
      // Row, pull, push variants
      'row',
      'pull-up', 'pull up', 'pullup', 'chin-up', 'chin up', 'chinup',
      'pulldown', 'pull-down', 'pull down', 'muscle-up', 'muscle up',
      'push-up', 'push up', 'pushup',
      'dip',
      'farmer',
    ];

    for (final keyword in compoundKeywords) {
      if (nameLower.contains(keyword)) {
        return 'compound';
      }
    }

    // Bodyweight/conditioning exercises
    final bodyweightKeywords = [
      'plank', 'crunch', 'sit-up', 'situp',
      'burpee', 'bear crawl', 'box jump',
      'jumping jack', 'mountain climber',
      'flutter kick', 'leg raise', 'dead bug', 'bird dog',
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
