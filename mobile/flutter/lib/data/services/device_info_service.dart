import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:ui' as ui;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cryptography/cryptography.dart';
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

  /// Tell the backend about the device that just signed in. The backend
  /// records the fingerprint and emails the user if it's never been seen
  /// before — mirrors the GymBeat / Google "new sign-in to your account"
  /// alert. Safe to call repeatedly: known fingerprints just bump the
  /// last-seen timestamp, no email is sent.
  ///
  /// [isFirstSignin] should be true when this call follows a fresh sign-in,
  /// false on app warm-launches.
  Future<void> trackSignInDevice({bool isFirstSignin = true}) async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final pkg = await PackageInfo.fromPlatform();
      String? deviceModel;
      String? devicePlatform;
      String? osVersion;
      String installId;

      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        deviceModel = info.model;
        devicePlatform = 'android';
        osVersion = info.version.release;
        // androidId rotates on factory reset — stable enough for "is this
        // the same physical device" purposes.
        installId = info.id;
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        deviceModel = info.utsname.machine.isNotEmpty
            ? info.utsname.machine
            : info.model;
        devicePlatform = 'ios';
        osVersion = info.systemVersion;
        // identifierForVendor can be null on rare iOS edge cases (jailbreak,
        // restoring from backup mid-fingerprint). Fall back to name then a
        // synthetic constant so we never throw.
        final iosVendor = info.identifierForVendor;
        installId = (iosVendor != null && iosVendor.isNotEmpty)
            ? iosVendor
            : (info.name.isNotEmpty ? info.name : 'ios-unknown');
      } else {
        devicePlatform = 'web';
        installId = 'web-${pkg.buildNumber}';
      }

      // sha256(platform | model | os | install_id). Keeps PII off the
      // wire — the backend only stores the hash.
      final raw = '$devicePlatform|${deviceModel ?? ''}|'
          '${osVersion ?? ''}|$installId';
      final digest = await Sha256().hash(utf8.encode(raw));
      final fingerprint = digest.bytes
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();

      await _apiClient.post(
        '${ApiConstants.users}/me/security/track-device',
        data: <String, dynamic>{
          'fingerprint_hash': fingerprint,
          'platform': devicePlatform,
          'model': deviceModel,
          'os_version': osVersion,
          'app_version': '${pkg.version}+${pkg.buildNumber}',
          'is_first_signin': isFirstSignin,
        },
      );
      debugPrint('🔐 [DeviceInfo] track-device sent (fp=${fingerprint.substring(0, 8)}…)');
    } catch (e) {
      // Non-fatal — failing to register the device for security alerting
      // shouldn't block a user from using the app.
      debugPrint('⚠️ [DeviceInfo] trackSignInDevice failed: $e');
    }
  }
}
