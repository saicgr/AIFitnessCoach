import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/audio_preferences.dart';
import '../services/api_client.dart';

/// Audio preferences repository provider
final audioPreferencesRepositoryProvider =
    Provider<AudioPreferencesRepository>((ref) {
  return AudioPreferencesRepository(ref.watch(apiClientProvider));
});

/// Repository for managing audio preferences.
///
/// Provides methods to get and update audio preferences including
/// background music settings, TTS volume, and audio ducking.
class AudioPreferencesRepository {
  final ApiClient _client;

  AudioPreferencesRepository(this._client);

  // ============================================
  // GET AUDIO PREFERENCES
  // ============================================

  /// Get current audio preferences for a user.
  ///
  /// If no preferences exist, the API will create defaults:
  /// - allow_background_music: true
  /// - tts_volume: 1.0
  /// - audio_ducking: true
  /// - duck_volume_level: 0.3
  /// - mute_during_video: true
  Future<AudioPreferences> getPreferences(String userId) async {
    try {
      debugPrint('🔊 [AudioPrefsRepo] Getting preferences for $userId');
      final response = await _client.get('/audio-preferences/$userId');

      if (response.data == null) {
        debugPrint('🔊 [AudioPrefsRepo] No data returned, using defaults');
        return AudioPreferences.defaults(userId);
      }

      final prefs = AudioPreferences.fromJson(response.data);
      debugPrint('✅ [AudioPrefsRepo] Got preferences: backgroundMusic=${prefs.allowBackgroundMusic}, ducking=${prefs.audioDucking}');
      return prefs;
    } catch (e) {
      debugPrint('❌ [AudioPrefsRepo] Error getting preferences: $e');
      rethrow;
    }
  }

  // ============================================
  // UPDATE AUDIO PREFERENCES
  // ============================================

  /// Update audio preferences.
  ///
  /// Only sends the fields that need to be updated.
  Future<AudioPreferences> updatePreferences({
    required String userId,
    bool? allowBackgroundMusic,
    double? ttsVolume,
    bool? audioDucking,
    double? duckVolumeLevel,
    bool? muteDuringVideo,
  }) async {
    try {
      debugPrint('🔊 [AudioPrefsRepo] Updating preferences for $userId');

      // Build update payload with only non-null fields
      final updateData = <String, dynamic>{};
      if (allowBackgroundMusic != null) {
        updateData['allow_background_music'] = allowBackgroundMusic;
      }
      if (ttsVolume != null) {
        updateData['tts_volume'] = ttsVolume;
      }
      if (audioDucking != null) {
        updateData['audio_ducking'] = audioDucking;
      }
      if (duckVolumeLevel != null) {
        updateData['duck_volume_level'] = duckVolumeLevel;
      }
      if (muteDuringVideo != null) {
        updateData['mute_during_video'] = muteDuringVideo;
      }

      if (updateData.isEmpty) {
        debugPrint('🔊 [AudioPrefsRepo] No changes to update');
        return await getPreferences(userId);
      }

      debugPrint('🔊 [AudioPrefsRepo] Update payload: $updateData');

      final response = await _client.put(
        '/audio-preferences/$userId',
        data: updateData,
      );

      final prefs = AudioPreferences.fromJson(response.data);
      debugPrint('✅ [AudioPrefsRepo] Preferences updated successfully');
      return prefs;
    } catch (e) {
      debugPrint('❌ [AudioPrefsRepo] Error updating preferences: $e');
      rethrow;
    }
  }

  /// Update a single audio preference by type.
  Future<AudioPreferences> updateSinglePreference({
    required String userId,
    required AudioPreferenceType type,
    required dynamic value,
  }) async {
    switch (type) {
      case AudioPreferenceType.allowBackgroundMusic:
        return updatePreferences(userId: userId, allowBackgroundMusic: value as bool);
      case AudioPreferenceType.ttsVolume:
        return updatePreferences(userId: userId, ttsVolume: value as double);
      case AudioPreferenceType.audioDucking:
        return updatePreferences(userId: userId, audioDucking: value as bool);
      case AudioPreferenceType.duckVolumeLevel:
        return updatePreferences(userId: userId, duckVolumeLevel: value as double);
      case AudioPreferenceType.muteDuringVideo:
        return updatePreferences(userId: userId, muteDuringVideo: value as bool);
    }
  }
}

/// Audio preference types for individual toggle/slider updates
enum AudioPreferenceType {
  allowBackgroundMusic,
  ttsVolume,
  audioDucking,
  duckVolumeLevel,
  muteDuringVideo,
}
