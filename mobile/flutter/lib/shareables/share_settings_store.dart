import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'shareable_data.dart';

/// Persisted "how the card looks" preferences for the share sheet —
/// aspect ratio, background mode, text scale and watermark visibility.
///
/// Stored client-side only (SharedPreferences). Template choice is tracked
/// separately by [RecentTemplatesStore]; favorites/order live in
/// `SharePreferences`. This store covers exactly the four visual knobs the
/// share sheet exposes so a returning user lands on the same look they
/// last shared with.
@immutable
class ShareSettings {
  final ShareableAspect aspect;
  final ShareBackground background;
  final double textScale;
  final bool showWatermark;
  final bool showPhoto;

  const ShareSettings({
    required this.aspect,
    required this.background,
    required this.textScale,
    required this.showWatermark,
    this.showPhoto = true,
  });

  /// First-run defaults — used when nothing has been persisted yet.
  static const fallback = ShareSettings(
    aspect: ShareableAspect.portrait,
    background: ShareBackground.themed,
    textScale: 1.5,
    showWatermark: true,
    showPhoto: true,
  );

  ShareSettings copyWith({
    ShareableAspect? aspect,
    ShareBackground? background,
    double? textScale,
    bool? showWatermark,
    bool? showPhoto,
  }) =>
      ShareSettings(
        aspect: aspect ?? this.aspect,
        background: background ?? this.background,
        textScale: textScale ?? this.textScale,
        showWatermark: showWatermark ?? this.showWatermark,
        showPhoto: showPhoto ?? this.showPhoto,
      );
}

/// Load / save helper for [ShareSettings]. All methods are fail-soft —
/// a corrupt or missing blob simply yields `null` (caller uses defaults).
class ShareSettingsStore {
  ShareSettingsStore._();

  static const _key = 'share_visual_settings_v1';

  /// Returns the persisted settings, or `null` when nothing is stored yet
  /// (or the blob is unreadable).
  static Future<ShareSettings?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;

      final aspect = ShareableAspect.values.firstWhere(
        (a) => a.name == json['aspect'],
        orElse: () => ShareSettings.fallback.aspect,
      );
      var background = ShareBackground.values.firstWhere(
        (b) => b.name == json['background'],
        orElse: () => ShareSettings.fallback.background,
      );
      // `video` requires a freshly-picked clip each session — never restore
      // straight into it (there would be no clip and the sheet would look
      // half-configured). Fall back to the themed default.
      if (background == ShareBackground.video) {
        background = ShareBackground.themed;
      }
      final scale = (json['textScale'] as num?)?.toDouble() ??
          ShareSettings.fallback.textScale;

      return ShareSettings(
        aspect: aspect,
        background: background,
        textScale: scale.clamp(1.0, 2.0),
        showWatermark: json['showWatermark'] as bool? ?? true,
      );
    } catch (e) {
      debugPrint('[ShareSettingsStore] load failed: $e');
      return null;
    }
  }

  /// Persists [settings]. Fire-and-forget — failures are non-fatal.
  static Future<void> save(ShareSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode({
          'aspect': settings.aspect.name,
          'background': settings.background.name,
          'textScale': settings.textScale,
          'showWatermark': settings.showWatermark,
        }),
      );
    } catch (e) {
      debugPrint('[ShareSettingsStore] save failed: $e');
    }
  }
}
