import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_tour_session.dart';
import '../services/api_client.dart';

/// App tour repository provider
final appTourRepositoryProvider = Provider<AppTourRepository>((ref) {
  return AppTourRepository(ref.watch(apiClientProvider));
});

/// Repository for app tour operations including API calls and local storage.
///
/// Handles:
/// - Starting and tracking tour sessions with the backend
/// - Recording step completions and analytics
/// - Local persistence of tour completion status
/// - Checking whether to show the tour
class AppTourRepository {
  final ApiClient _client;

  // Local storage keys
  static const String _tourCompletedKey = 'tour_completed';
  static const String _tourSessionIdKey = 'tour_session_id';
  static const String _tourSkippedKey = 'tour_skipped';
  static const String _tourCompletedAtKey = 'tour_completed_at';
  static const String _tourSkippedAtKey = 'tour_skipped_at';
  static const String _tourLastStepKey = 'tour_last_step';

  AppTourRepository(this._client);

  // =========================================================================
  // API Methods
  // =========================================================================

  /// Start a new tour session
  ///
  /// POST /api/v1/demo/tour/start
  Future<TourStartResponse> startTour({
    String? userId,
    String? deviceId,
    TourSource source = TourSource.firstLaunch,
  }) async {
    try {
      debugPrint('[AppTour] Starting tour session for source: ${source.name}');

      final response = await _client.post(
        '/demo/tour/start',
        data: {
          if (userId != null) 'user_id': userId,
          if (deviceId != null) 'device_id': deviceId,
          'source': source.name,
        },
      );

      final result = TourStartResponse.fromJson(
        response.data as Map<String, dynamic>,
      );

      // Save session ID locally
      await _saveSessionId(result.sessionId);

      debugPrint('[AppTour] Tour started with session: ${result.sessionId}');
      return result;
    } catch (e) {
      debugPrint('[AppTour] Error starting tour: $e');
      rethrow;
    }
  }

  /// Record a step completion
  ///
  /// POST /api/v1/demo/tour/step-completed
  Future<StepCompletedResponse> completeStep({
    required String sessionId,
    required String stepId,
    int? timeSpentSeconds,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      debugPrint('[AppTour] Completing step: $stepId');

      final response = await _client.post(
        '/demo/tour/step-completed',
        data: {
          'session_id': sessionId,
          'step_id': stepId,
          if (timeSpentSeconds != null) 'time_spent_seconds': timeSpentSeconds,
          if (metadata != null) 'metadata': metadata,
        },
      );

      final result = StepCompletedResponse.fromJson(
        response.data as Map<String, dynamic>,
      );

      // Update local storage with last completed step
      await _saveLastStep(stepId);

      debugPrint('[AppTour] Step $stepId completed successfully');
      return result;
    } catch (e) {
      debugPrint('[AppTour] Error completing step: $e');
      rethrow;
    }
  }

  /// Complete the entire tour
  ///
  /// POST /api/v1/demo/tour/completed
  Future<TourCompletedResponse> completeTour({
    required String sessionId,
    int? totalDurationSeconds,
    bool demoWorkoutStarted = false,
    bool demoWorkoutCompleted = false,
    List<String>? deepLinksClicked,
  }) async {
    try {
      debugPrint('[AppTour] Completing tour session: $sessionId');

      final response = await _client.post(
        '/demo/tour/completed',
        data: {
          'session_id': sessionId,
          if (totalDurationSeconds != null)
            'total_duration_seconds': totalDurationSeconds,
          'demo_workout_started': demoWorkoutStarted,
          'demo_workout_completed': demoWorkoutCompleted,
          if (deepLinksClicked != null) 'deep_links_clicked': deepLinksClicked,
        },
      );

      final result = TourCompletedResponse.fromJson(
        response.data as Map<String, dynamic>,
      );

      // Mark tour as completed locally
      await _markTourCompleted();

      debugPrint('[AppTour] Tour completed successfully');
      return result;
    } catch (e) {
      debugPrint('[AppTour] Error completing tour: $e');
      rethrow;
    }
  }

  /// Skip the tour
  ///
  /// POST /api/v1/demo/tour/skipped
  Future<bool> skipTour({
    required String sessionId,
    required String skipStep,
    int? timeSpentSeconds,
  }) async {
    try {
      debugPrint('[AppTour] Skipping tour at step: $skipStep');

      await _client.post(
        '/demo/tour/skipped',
        data: {
          'session_id': sessionId,
          'skip_step': skipStep,
          if (timeSpentSeconds != null) 'time_spent_seconds': timeSpentSeconds,
        },
      );

      // Mark tour as skipped locally
      await _markTourSkipped(skipStep);

      debugPrint('[AppTour] Tour skipped successfully');
      return true;
    } catch (e) {
      debugPrint('[AppTour] Error skipping tour: $e');
      return false;
    }
  }

  /// Check if the tour should be shown
  ///
  /// GET /api/v1/demo/tour/status/{identifier}
  Future<TourStatusResponse> shouldShowTour({
    String? userId,
    String? deviceId,
  }) async {
    try {
      final identifier = userId ?? deviceId ?? 'anonymous';
      debugPrint('[AppTour] Checking tour status for: $identifier');

      final response = await _client.get(
        '/demo/tour/status/$identifier',
        queryParameters: {
          if (userId != null) 'user_id': userId,
          if (deviceId != null) 'device_id': deviceId,
        },
      );

      final result = TourStatusResponse.fromJson(
        response.data as Map<String, dynamic>,
      );

      debugPrint('[AppTour] Should show tour: ${result.shouldShowTour}');
      return result;
    } catch (e) {
      debugPrint('[AppTour] Error checking tour status: $e');
      // On error, check local storage
      final localCompleted = await isTourCompletedLocally();
      return TourStatusResponse(
        shouldShowTour: !localCompleted,
        reason: 'Fallback to local storage due to API error',
      );
    }
  }

  /// Log a deep link click during the tour
  ///
  /// POST /api/v1/demo/tour/deep-link-clicked
  Future<bool> logDeepLinkClick({
    required String sessionId,
    required String route,
    required String stepId,
  }) async {
    try {
      debugPrint('[AppTour] Logging deep link click: $route at step $stepId');

      await _client.post(
        '/demo/tour/deep-link-clicked',
        data: {
          'session_id': sessionId,
          'route': route,
          'step_id': stepId,
        },
      );

      return true;
    } catch (e) {
      debugPrint('[AppTour] Error logging deep link click: $e');
      return false;
    }
  }

  /// Log demo workout started
  ///
  /// POST /api/v1/demo/tour/demo-started
  Future<bool> logDemoWorkoutStarted({
    required String sessionId,
    required String stepId,
  }) async {
    try {
      debugPrint('[AppTour] Logging demo workout started at step: $stepId');

      await _client.post(
        '/demo/tour/demo-started',
        data: {
          'session_id': sessionId,
          'step_id': stepId,
        },
      );

      return true;
    } catch (e) {
      debugPrint('[AppTour] Error logging demo workout started: $e');
      return false;
    }
  }

  // =========================================================================
  // Local Storage Methods
  // =========================================================================

  /// Save the current session ID to local storage
  Future<void> _saveSessionId(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tourSessionIdKey, sessionId);
    } catch (e) {
      debugPrint('[AppTour] Error saving session ID: $e');
    }
  }

  /// Get the current session ID from local storage
  Future<String?> getSessionId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tourSessionIdKey);
    } catch (e) {
      debugPrint('[AppTour] Error getting session ID: $e');
      return null;
    }
  }

  /// Save the last completed step
  Future<void> _saveLastStep(String stepId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tourLastStepKey, stepId);
    } catch (e) {
      debugPrint('[AppTour] Error saving last step: $e');
    }
  }

  /// Get the last completed step
  Future<String?> getLastCompletedStep() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tourLastStepKey);
    } catch (e) {
      debugPrint('[AppTour] Error getting last step: $e');
      return null;
    }
  }

  /// Mark the tour as completed locally
  Future<void> _markTourCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_tourCompletedKey, true);
      await prefs.setString(
        _tourCompletedAtKey,
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      debugPrint('[AppTour] Error marking tour completed: $e');
    }
  }

  /// Mark the tour as skipped locally
  Future<void> _markTourSkipped(String skipStep) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_tourSkippedKey, true);
      await prefs.setString(
        _tourSkippedAtKey,
        DateTime.now().toIso8601String(),
      );
      await prefs.setString(_tourLastStepKey, skipStep);
    } catch (e) {
      debugPrint('[AppTour] Error marking tour skipped: $e');
    }
  }

  /// Check if the tour has been completed locally
  Future<bool> isTourCompletedLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_tourCompletedKey) ?? false;
    } catch (e) {
      debugPrint('[AppTour] Error checking tour completion: $e');
      return false;
    }
  }

  /// Check if the tour has been skipped locally
  Future<bool> isTourSkippedLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_tourSkippedKey) ?? false;
    } catch (e) {
      debugPrint('[AppTour] Error checking tour skipped: $e');
      return false;
    }
  }

  /// Check if the tour should be shown based on local storage
  Future<bool> shouldShowTourLocally() async {
    final completed = await isTourCompletedLocally();
    final skipped = await isTourSkippedLocally();
    return !completed && !skipped;
  }

  /// Reset local tour completion status (for settings restart)
  Future<void> resetTourCompletion() async {
    try {
      debugPrint('[AppTour] Resetting tour completion status');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tourCompletedKey);
      await prefs.remove(_tourSkippedKey);
      await prefs.remove(_tourSessionIdKey);
      await prefs.remove(_tourCompletedAtKey);
      await prefs.remove(_tourSkippedAtKey);
      await prefs.remove(_tourLastStepKey);
      debugPrint('[AppTour] Tour reset successfully');
    } catch (e) {
      debugPrint('[AppTour] Error resetting tour: $e');
    }
  }

  /// Get tour completion details from local storage
  Future<Map<String, dynamic>> getTourLocalStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'completed': prefs.getBool(_tourCompletedKey) ?? false,
        'skipped': prefs.getBool(_tourSkippedKey) ?? false,
        'session_id': prefs.getString(_tourSessionIdKey),
        'completed_at': prefs.getString(_tourCompletedAtKey),
        'skipped_at': prefs.getString(_tourSkippedAtKey),
        'last_step': prefs.getString(_tourLastStepKey),
      };
    } catch (e) {
      debugPrint('[AppTour] Error getting tour status: $e');
      return {};
    }
  }
}
