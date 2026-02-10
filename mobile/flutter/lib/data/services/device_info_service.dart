import 'dart:io' show Platform;
import 'dart:ui' as ui;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_constants.dart';
import 'api_client.dart';

/// Service that collects device info and persists it to the user profile.
///
/// Sends device model, platform, OS version, screen dimensions, and foldable
/// status to the backend. Cached via SharedPreferences so updates only happen
/// once every 7 days (or on first login).
class DeviceInfoService {
  static const _lastUpdateKey = 'device_info_last_update';
  static const _staleDays = 7;

  final ApiClient _apiClient;

  DeviceInfoService(this._apiClient);

  /// Update device info if stale (>7 days) or never sent.
  /// [userId] — the authenticated user's ID.
  /// [isFoldable] — from WindowModeProvider state.
  Future<void> updateIfNeeded({
    required String userId,
    bool isFoldable = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdate = prefs.getInt(_lastUpdateKey);

      if (lastUpdate != null) {
        final lastDate = DateTime.fromMillisecondsSinceEpoch(lastUpdate);
        final daysSince = DateTime.now().difference(lastDate).inDays;
        if (daysSince < _staleDays) {
          debugPrint('🔍 [DeviceInfo] Skipping update — last updated $daysSince days ago');
          return;
        }
      }

      await _sendDeviceInfo(userId: userId, isFoldable: isFoldable);

      // Mark update time
      await prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
      debugPrint('✅ [DeviceInfo] Device info updated for user $userId');
    } catch (e) {
      debugPrint('⚠️ [DeviceInfo] Failed to update device info: $e');
    }
  }

  Future<void> _sendDeviceInfo({
    required String userId,
    required bool isFoldable,
  }) async {
    final deviceInfo = DeviceInfoPlugin();
    String? deviceModel;
    String? devicePlatform;
    String? osVersion;

    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      deviceModel = info.model;
      devicePlatform = 'android';
      osVersion = info.version.release;
    } else if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      deviceModel = info.model;
      devicePlatform = 'ios';
      osVersion = info.systemVersion;
    }

    // Get screen dimensions (physical pixels)
    final window = ui.PlatformDispatcher.instance.views.first;
    final screenWidth = (window.physicalSize.width).round();
    final screenHeight = (window.physicalSize.height).round();

    final data = <String, dynamic>{
      if (deviceModel != null) 'device_model': deviceModel,
      if (devicePlatform != null) 'device_platform': devicePlatform,
      'is_foldable': isFoldable,
      if (osVersion != null) 'os_version': osVersion,
      'screen_width': screenWidth,
      'screen_height': screenHeight,
    };

    await _apiClient.put(
      '${ApiConstants.users}/$userId',
      data: data,
    );
  }
}
