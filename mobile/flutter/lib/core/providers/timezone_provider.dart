import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../data/repositories/auth_repository.dart';
import '../../data/services/api_client.dart';
import '../constants/api_constants.dart';

/// Common timezones grouped by region for user selection
class TimezoneData {
  final String id;
  final String displayName;
  final String region;

  const TimezoneData({
    required this.id,
    required this.displayName,
    required this.region,
  });

  /// Get current UTC offset for this timezone
  String get currentOffset {
    try {
      final location = tz.getLocation(id);
      final now = tz.TZDateTime.now(location);
      final offset = now.timeZoneOffset;
      final hours = offset.inHours;
      final minutes = (offset.inMinutes % 60).abs();
      final sign = hours >= 0 ? '+' : '';
      if (minutes == 0) {
        return 'UTC$sign$hours';
      }
      return 'UTC$sign$hours:${minutes.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }
}

/// Common timezones for selection
const commonTimezones = [
  // Americas
  TimezoneData(id: 'America/New_York', displayName: 'Eastern Time', region: 'Americas'),
  TimezoneData(id: 'America/Chicago', displayName: 'Central Time', region: 'Americas'),
  TimezoneData(id: 'America/Denver', displayName: 'Mountain Time', region: 'Americas'),
  TimezoneData(id: 'America/Los_Angeles', displayName: 'Pacific Time', region: 'Americas'),
  TimezoneData(id: 'America/Anchorage', displayName: 'Alaska', region: 'Americas'),
  TimezoneData(id: 'Pacific/Honolulu', displayName: 'Hawaii', region: 'Americas'),
  TimezoneData(id: 'America/Toronto', displayName: 'Toronto', region: 'Americas'),
  TimezoneData(id: 'America/Vancouver', displayName: 'Vancouver', region: 'Americas'),
  TimezoneData(id: 'America/Mexico_City', displayName: 'Mexico City', region: 'Americas'),
  TimezoneData(id: 'America/Sao_Paulo', displayName: 'Sao Paulo', region: 'Americas'),
  TimezoneData(id: 'America/Buenos_Aires', displayName: 'Buenos Aires', region: 'Americas'),

  // Europe
  TimezoneData(id: 'Europe/London', displayName: 'London', region: 'Europe'),
  TimezoneData(id: 'Europe/Paris', displayName: 'Paris', region: 'Europe'),
  TimezoneData(id: 'Europe/Berlin', displayName: 'Berlin', region: 'Europe'),
  TimezoneData(id: 'Europe/Rome', displayName: 'Rome', region: 'Europe'),
  TimezoneData(id: 'Europe/Madrid', displayName: 'Madrid', region: 'Europe'),
  TimezoneData(id: 'Europe/Amsterdam', displayName: 'Amsterdam', region: 'Europe'),
  TimezoneData(id: 'Europe/Moscow', displayName: 'Moscow', region: 'Europe'),
  TimezoneData(id: 'Europe/Istanbul', displayName: 'Istanbul', region: 'Europe'),

  // Asia
  TimezoneData(id: 'Asia/Kolkata', displayName: 'India (IST)', region: 'Asia'),
  TimezoneData(id: 'Asia/Dubai', displayName: 'Dubai', region: 'Asia'),
  TimezoneData(id: 'Asia/Singapore', displayName: 'Singapore', region: 'Asia'),
  TimezoneData(id: 'Asia/Hong_Kong', displayName: 'Hong Kong', region: 'Asia'),
  TimezoneData(id: 'Asia/Tokyo', displayName: 'Tokyo', region: 'Asia'),
  TimezoneData(id: 'Asia/Seoul', displayName: 'Seoul', region: 'Asia'),
  TimezoneData(id: 'Asia/Shanghai', displayName: 'Shanghai', region: 'Asia'),
  TimezoneData(id: 'Asia/Bangkok', displayName: 'Bangkok', region: 'Asia'),
  TimezoneData(id: 'Asia/Jakarta', displayName: 'Jakarta', region: 'Asia'),
  TimezoneData(id: 'Asia/Manila', displayName: 'Manila', region: 'Asia'),

  // Pacific / Oceania
  TimezoneData(id: 'Australia/Sydney', displayName: 'Sydney', region: 'Pacific'),
  TimezoneData(id: 'Australia/Melbourne', displayName: 'Melbourne', region: 'Pacific'),
  TimezoneData(id: 'Australia/Perth', displayName: 'Perth', region: 'Pacific'),
  TimezoneData(id: 'Pacific/Auckland', displayName: 'Auckland', region: 'Pacific'),

  // Africa / Middle East
  TimezoneData(id: 'Africa/Cairo', displayName: 'Cairo', region: 'Africa'),
  TimezoneData(id: 'Africa/Johannesburg', displayName: 'Johannesburg', region: 'Africa'),
  TimezoneData(id: 'Africa/Lagos', displayName: 'Lagos', region: 'Africa'),

  // UTC
  TimezoneData(id: 'UTC', displayName: 'UTC', region: 'UTC'),
];

/// Timezone provider state
class TimezoneState {
  final String timezone;
  final bool isLoading;
  final String? error;

  const TimezoneState({
    this.timezone = 'UTC',
    this.isLoading = false,
    this.error,
  });

  TimezoneState copyWith({
    String? timezone,
    bool? isLoading,
    String? error,
  }) {
    return TimezoneState(
      timezone: timezone ?? this.timezone,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Get display name for current timezone
  String get displayName {
    final tz = commonTimezones.where((t) => t.id == timezone).firstOrNull;
    return tz?.displayName ?? timezone;
  }
}

/// Timezone state provider
final timezoneProvider = StateNotifierProvider<TimezoneNotifier, TimezoneState>((ref) {
  return TimezoneNotifier(ref);
});

/// Timezone notifier for managing timezone state
class TimezoneNotifier extends StateNotifier<TimezoneState> {
  static const _timezoneKey = 'user_timezone';
  final Ref _ref;

  TimezoneNotifier(this._ref) : super(const TimezoneState()) {
    _init();
  }

  /// Initialize timezone from user profile or device
  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    try {
      // First try to get from user profile
      final authState = _ref.read(authStateProvider);
      if (authState.user?.timezone != null && authState.user!.timezone!.isNotEmpty) {
        state = TimezoneState(timezone: authState.user!.timezone!);
        debugPrint('🕐 [Timezone] Loaded from user profile: ${state.timezone}');
        return;
      }

      // Then try local storage
      final prefs = await SharedPreferences.getInstance();
      final savedTimezone = prefs.getString(_timezoneKey);
      if (savedTimezone != null && savedTimezone.isNotEmpty) {
        state = TimezoneState(timezone: savedTimezone);
        debugPrint('🕐 [Timezone] Loaded from local storage: ${state.timezone}');
        // Sync to backend if user is logged in but doesn't have timezone set
        if (authState.user != null) {
          _syncToBackend(savedTimezone);
        }
        return;
      }

      // Finally, detect from device and auto-sync to backend
      final deviceTimezone = await _detectDeviceTimezone();
      state = TimezoneState(timezone: deviceTimezone);
      debugPrint('🕐 [Timezone] Detected from device: ${state.timezone}');

      // Auto-sync detected timezone to backend and local storage
      await _autoSyncTimezone(deviceTimezone);
    } catch (e) {
      debugPrint('❌ [Timezone] Init error: $e');
      state = TimezoneState(timezone: 'UTC', error: e.toString());
    }
  }

  /// Auto-sync timezone to backend (called on first detection)
  Future<void> _autoSyncTimezone(String timezone) async {
    try {
      // Save locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_timezoneKey, timezone);

      // Sync to backend if user is logged in
      final apiClient = _ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId != null) {
        await apiClient.put(
          '${ApiConstants.users}/$userId',
          data: {'timezone': timezone},
        );
        debugPrint('✅ [Timezone] Auto-synced to backend: $timezone');
      }
    } catch (e) {
      debugPrint('⚠️ [Timezone] Auto-sync failed (non-critical): $e');
      // Don't throw - auto-sync failure is non-critical
    }
  }

  /// Sync timezone to backend without blocking
  void _syncToBackend(String timezone) {
    Future(() async {
      try {
        final apiClient = _ref.read(apiClientProvider);
        final userId = await apiClient.getUserId();

        if (userId != null) {
          await apiClient.put(
            '${ApiConstants.users}/$userId',
            data: {'timezone': timezone},
          );
          debugPrint('✅ [Timezone] Background sync to backend: $timezone');
        }
      } catch (e) {
        debugPrint('⚠️ [Timezone] Background sync failed: $e');
      }
    });
  }

  /// Detect timezone from device using the OS-level IANA identifier.
  /// Returns a proper IANA timezone like "America/Chicago", never an abbreviation.
  Future<String> _detectDeviceTimezone() async {
    try {
      // flutter_timezone reads the device's OS-level IANA timezone directly
      // (e.g., "America/Chicago", "Asia/Kolkata") — no guessing from offsets
      final deviceTzInfo = await FlutterTimezone.getLocalTimezone();
      final deviceTz = deviceTzInfo.identifier;
      if (deviceTz.isNotEmpty && deviceTz != 'Etc/UTC') {
        debugPrint('🕐 [Timezone] Device IANA timezone: $deviceTz');
        return deviceTz;
      }
    } catch (e) {
      debugPrint('⚠️ [Timezone] FlutterTimezone.getLocalTimezone() failed: $e');
    }

    // Last resort: try offset-based matching against known IANA zones
    try {
      final now = DateTime.now();
      final offset = now.timeZoneOffset;
      for (final tzData in commonTimezones) {
        try {
          final location = tz.getLocation(tzData.id);
          final tzNow = tz.TZDateTime.now(location);
          if (tzNow.timeZoneOffset == offset) {
            debugPrint('🕐 [Timezone] Matched from offset ${offset.inHours}h: ${tzData.id}');
            return tzData.id;
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('❌ [Timezone] Offset matching error: $e');
    }

    debugPrint('⚠️ [Timezone] Could not detect — falling back to UTC');
    return 'UTC';
  }

  /// Set timezone and sync to backend
  Future<void> setTimezone(String timezone) async {
    if (timezone == state.timezone) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Save locally first
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_timezoneKey, timezone);

      // Update backend
      final apiClient = _ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId != null) {
        await apiClient.put(
          '${ApiConstants.users}/$userId',
          data: {'timezone': timezone},
        );
        debugPrint('✅ [Timezone] Synced to backend: $timezone');
      }

      // Refresh user to get updated data
      await _ref.read(authStateProvider.notifier).refreshUser();

      state = TimezoneState(timezone: timezone);
      debugPrint('✅ [Timezone] Updated to: $timezone');
    } catch (e) {
      debugPrint('❌ [Timezone] Update error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Refresh timezone from user profile
  Future<void> refresh() async {
    final authState = _ref.read(authStateProvider);
    if (authState.user?.timezone != null && authState.user!.timezone!.isNotEmpty) {
      state = TimezoneState(timezone: authState.user!.timezone!);
    }
  }
}
