import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/api_client.dart';
import '../constants/api_constants.dart';

/// Accessibility mode types
enum AccessibilityMode {
  standard,
  senior,
  kids, // Coming soon
}

/// Accessibility settings model
class AccessibilitySettings {
  final AccessibilityMode mode;
  final double fontScale; // 1.0 for normal, 1.3-1.5 for senior
  final bool highContrast;
  final bool largeButtons;
  final bool reduceAnimations;

  const AccessibilitySettings({
    this.mode = AccessibilityMode.standard,
    this.fontScale = 1.0,
    this.highContrast = false,
    this.largeButtons = false,
    this.reduceAnimations = false,
  });

  /// Get effective font scale based on mode
  double get effectiveFontScale {
    if (mode == AccessibilityMode.senior) {
      return fontScale > 1.0 ? fontScale : 1.35;
    }
    return fontScale;
  }

  /// Get effective button height based on mode
  double get effectiveButtonHeight {
    if (mode == AccessibilityMode.senior || largeButtons) {
      return 64.0;
    }
    return 48.0;
  }

  /// Check if simplified navigation should be used
  bool get useSimplifiedNav => mode == AccessibilityMode.senior;

  /// Check if we're in senior mode
  bool get isSeniorMode => mode == AccessibilityMode.senior;

  /// Check if we're in standard mode
  bool get isStandardMode => mode == AccessibilityMode.standard;

  AccessibilitySettings copyWith({
    AccessibilityMode? mode,
    double? fontScale,
    bool? highContrast,
    bool? largeButtons,
    bool? reduceAnimations,
  }) {
    return AccessibilitySettings(
      mode: mode ?? this.mode,
      fontScale: fontScale ?? this.fontScale,
      highContrast: highContrast ?? this.highContrast,
      largeButtons: largeButtons ?? this.largeButtons,
      reduceAnimations: reduceAnimations ?? this.reduceAnimations,
    );
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'font_scale': fontScale,
        'high_contrast': highContrast,
        'large_buttons': largeButtons,
        'reduce_animations': reduceAnimations,
      };

  /// Create from JSON
  factory AccessibilitySettings.fromJson(Map<String, dynamic> json) {
    return AccessibilitySettings(
      mode: AccessibilityMode.values.firstWhere(
        (e) => e.name == json['mode'] || (e == AccessibilityMode.standard && json['mode'] == 'normal'),
        orElse: () => AccessibilityMode.standard,
      ),
      fontScale: (json['font_scale'] as num?)?.toDouble() ?? 1.0,
      highContrast: json['high_contrast'] as bool? ?? false,
      largeButtons: json['large_buttons'] as bool? ?? false,
      reduceAnimations: json['reduce_animations'] as bool? ?? false,
    );
  }

  /// Create senior mode defaults
  factory AccessibilitySettings.senior() {
    return const AccessibilitySettings(
      mode: AccessibilityMode.senior,
      fontScale: 1.35,
      highContrast: true,
      largeButtons: true,
      reduceAnimations: false,
    );
  }
}

/// Accessibility settings notifier with local + backend persistence
class AccessibilityNotifier extends StateNotifier<AccessibilitySettings> {
  final SharedPreferences _prefs;
  final ApiClient? _apiClient;

  static const String _prefsKey = 'accessibility_settings';

  AccessibilityNotifier(this._prefs, this._apiClient)
      : super(const AccessibilitySettings()) {
    _loadFromPrefs();
  }

  /// Load settings from SharedPreferences
  void _loadFromPrefs() {
    final json = _prefs.getString(_prefsKey);
    if (json != null) {
      try {
        final data = Map<String, dynamic>.from(
          Uri.splitQueryString(json).map((k, v) => MapEntry(k, _parseValue(v))),
        );
        state = AccessibilitySettings.fromJson(data);
        debugPrint(
            '♿ [Accessibility] Loaded from prefs: mode=${state.mode.name}');
      } catch (e) {
        debugPrint('♿ [Accessibility] Error loading from prefs: $e');
      }
    }
  }

  dynamic _parseValue(String value) {
    if (value == 'true') return true;
    if (value == 'false') return false;
    final numValue = double.tryParse(value);
    if (numValue != null) return numValue;
    return value;
  }

  /// Save settings to SharedPreferences
  Future<void> _saveToPrefs() async {
    final json = state.toJson();
    final encoded = json.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    await _prefs.setString(_prefsKey, encoded);
    debugPrint('♿ [Accessibility] Saved to prefs: mode=${state.mode.name}');
  }

  /// Sync settings to backend
  Future<void> syncToBackend() async {
    if (_apiClient == null) return;

    try {
      final userId = await _apiClient.getUserId();
      if (userId == null) {
        debugPrint('♿ [Accessibility] No user ID, skipping backend sync');
        return;
      }

      await _apiClient.put(
        '${ApiConstants.users}/$userId',
        data: {
          'accessibility_mode': state.mode.name,
          'accessibility_settings': state.toJson(),
        },
      );
      debugPrint('♿ [Accessibility] Synced to backend');
    } catch (e) {
      debugPrint('♿ [Accessibility] Error syncing to backend: $e');
    }
  }

  /// Load settings from backend
  Future<void> loadFromBackend() async {
    if (_apiClient == null) return;

    try {
      final userId = await _apiClient.getUserId();
      if (userId == null) return;

      final response = await _apiClient.get('${ApiConstants.users}/$userId');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final modeStr = data['accessibility_mode'] as String?;
        if (modeStr != null) {
          final mode = AccessibilityMode.values.firstWhere(
            (e) => e.name == modeStr || (e == AccessibilityMode.standard && modeStr == 'normal'),
            orElse: () => AccessibilityMode.standard,
          );
          state = state.copyWith(mode: mode);
          await _saveToPrefs();
          debugPrint('♿ [Accessibility] Loaded from backend: mode=${mode.name}');
        }
      }
    } catch (e) {
      debugPrint('♿ [Accessibility] Error loading from backend: $e');
    }
  }

  /// Set accessibility mode
  Future<void> setMode(AccessibilityMode mode) async {
    if (mode == AccessibilityMode.senior) {
      state = AccessibilitySettings.senior();
    } else {
      state = const AccessibilitySettings();
    }
    await _saveToPrefs();
    await syncToBackend();
  }

  /// Update font scale
  Future<void> setFontScale(double scale) async {
    state = state.copyWith(fontScale: scale);
    await _saveToPrefs();
    await syncToBackend();
  }

  /// Toggle high contrast
  Future<void> toggleHighContrast() async {
    state = state.copyWith(highContrast: !state.highContrast);
    await _saveToPrefs();
    await syncToBackend();
  }

  /// Toggle large buttons
  Future<void> toggleLargeButtons() async {
    state = state.copyWith(largeButtons: !state.largeButtons);
    await _saveToPrefs();
    await syncToBackend();
  }

  /// Toggle reduce animations
  Future<void> toggleReduceAnimations() async {
    state = state.copyWith(reduceAnimations: !state.reduceAnimations);
    await _saveToPrefs();
    await syncToBackend();
  }

  /// Reset to standard mode
  Future<void> resetToStandard() async {
    state = const AccessibilitySettings();
    await _saveToPrefs();
    await syncToBackend();
  }
}

/// Provider for SharedPreferences (must be overridden in main.dart)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be provided');
});

/// Accessibility settings provider
final accessibilityProvider =
    StateNotifierProvider<AccessibilityNotifier, AccessibilitySettings>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final apiClient = ref.watch(apiClientProvider);
  return AccessibilityNotifier(prefs, apiClient);
});

/// Helper extension for context-based font scaling
extension AccessibilityContext on BuildContext {
  /// Get scaled font size based on accessibility settings
  double scaledFontSize(double baseSize, WidgetRef ref) {
    final settings = ref.watch(accessibilityProvider);
    return baseSize * settings.effectiveFontScale;
  }

  /// Get button height based on accessibility settings
  double buttonHeight(WidgetRef ref) {
    final settings = ref.watch(accessibilityProvider);
    return settings.effectiveButtonHeight;
  }
}
