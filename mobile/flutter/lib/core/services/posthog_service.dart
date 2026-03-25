import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

/// PostHog analytics service provider
final posthogServiceProvider = Provider<PosthogService>((ref) {
  return PosthogService();
});

/// Wrapper around the PostHog Flutter SDK.
///
/// Provides a clean API for event tracking, user identification,
/// screen tracking, and feature flags. All methods are fire-and-forget
/// with try-catch error handling — PostHog SDK handles offline
/// queuing and batching internally.
class PosthogService {
  Posthog get _posthog => Posthog();

  /// Identify a user after authentication.
  /// Call on sign-in and on app launch when session is restored.
  Future<void> identify({
    required String userId,
    Map<String, Object>? userProperties,
    Map<String, Object>? userPropertiesSetOnce,
  }) async {
    try {
      await _posthog.identify(
        userId: userId,
        userProperties: userProperties,
        userPropertiesSetOnce: userPropertiesSetOnce,
      );
      if (kDebugMode) {
        debugPrint('📊 [PostHog] Identified user: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [PostHog] identify failed: $e');
      }
    }
  }

  /// Reset identity on sign-out (generates new anonymous ID).
  Future<void> reset() async {
    try {
      await _posthog.reset();
      if (kDebugMode) {
        debugPrint('📊 [PostHog] Identity reset');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [PostHog] reset failed: $e');
      }
    }
  }

  /// Capture a named event with optional properties.
  Future<void> capture({
    required String eventName,
    Map<String, Object>? properties,
  }) async {
    try {
      await _posthog.capture(
        eventName: eventName,
        properties: properties,
      );
      if (kDebugMode) {
        debugPrint('📊 [PostHog] Event: $eventName');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [PostHog] capture failed: $e');
      }
    }
  }

  /// Track a screen view. Used by the GoRouter observer.
  Future<void> screen({
    required String screenName,
    Map<String, Object>? properties,
  }) async {
    try {
      await _posthog.screen(
        screenName: screenName,
        properties: properties,
      );
      if (kDebugMode) {
        debugPrint('📊 [PostHog] Screen: $screenName');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [PostHog] screen failed: $e');
      }
    }
  }

  /// Check a feature flag value.
  Future<bool> isFeatureEnabled(String flagKey) async {
    try {
      final result = await _posthog.isFeatureEnabled(flagKey);
      return result;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [PostHog] isFeatureEnabled failed: $e');
      }
      return false;
    }
  }

  /// Get a feature flag payload (for multivariate flags).
  Future<dynamic> getFeatureFlagPayload(String flagKey) async {
    try {
      return await _posthog.getFeatureFlagPayload(flagKey);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [PostHog] getFeatureFlagPayload failed: $e');
      }
      return null;
    }
  }

  /// Capture an error event with structured properties.
  Future<void> captureError({
    required String errorType,
    required String message,
    String? screenName,
    Map<String, Object>? extra,
  }) async {
    await capture(
      eventName: 'app_error',
      properties: {
        'error_type': errorType,
        'error_message': message,
        if (screenName != null) 'screen_name': screenName,
        ...?extra,
      },
    );
  }

  /// Assign user to a group for group analytics.
  Future<void> group({
    required String groupType,
    required String groupKey,
    Map<String, Object>? groupProperties,
  }) async {
    try {
      await _posthog.group(
        groupType: groupType,
        groupKey: groupKey,
        groupProperties: groupProperties,
      );
      if (kDebugMode) {
        debugPrint('📊 [PostHog] Group: $groupType/$groupKey');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [PostHog] group failed: $e');
      }
    }
  }
}
