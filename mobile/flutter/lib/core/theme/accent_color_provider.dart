import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/providers/gym_profile_provider.dart' show gymAccentColorProvider;

/// Available accent colors for the app
enum AccentColor {
  black,   // Pure black/white (monochrome)
  cyan,    // Cyan accent
  purple,  // Purple accent
  orange,  // Orange accent - default
  green,   // Green accent
  blue,    // Blue accent
  red,     // Red accent
  pink,    // Pink accent
  teal,    // Teal accent
  indigo,  // Indigo accent
  amber,   // Amber/Gold accent
  lime,    // Lime green accent
}

/// Extension to get display name and color value
extension AccentColorExtension on AccentColor {
  String get displayName {
    switch (this) {
      case AccentColor.black:
        return 'Monochrome';
      case AccentColor.cyan:
        return 'Cyan';
      case AccentColor.purple:
        return 'Purple';
      case AccentColor.orange:
        return 'Orange';
      case AccentColor.green:
        return 'Green';
      case AccentColor.blue:
        return 'Blue';
      case AccentColor.red:
        return 'Red';
      case AccentColor.pink:
        return 'Pink';
      case AccentColor.teal:
        return 'Teal';
      case AccentColor.indigo:
        return 'Indigo';
      case AccentColor.amber:
        return 'Amber';
      case AccentColor.lime:
        return 'Lime';
    }
  }

  /// Get the actual Color value for this accent
  /// Returns theme-appropriate color (e.g., white in dark mode for black accent)
  Color getColor(bool isDark) {
    switch (this) {
      case AccentColor.black:
        return isDark ? Colors.white : Colors.black;
      case AccentColor.cyan:
        return const Color(0xFF00BCD4);
      case AccentColor.purple:
        return const Color(0xFF9C27B0);
      case AccentColor.orange:
        return const Color(0xFFFF9800);
      case AccentColor.green:
        return const Color(0xFF4CAF50);
      case AccentColor.blue:
        return const Color(0xFF2196F3);
      case AccentColor.red:
        return const Color(0xFFF44336);
      case AccentColor.pink:
        return const Color(0xFFE91E63);
      case AccentColor.teal:
        return const Color(0xFF009688);
      case AccentColor.indigo:
        return const Color(0xFF3F51B5);
      case AccentColor.amber:
        return const Color(0xFFFFC107);
      case AccentColor.lime:
        return const Color(0xFFCDDC39);
    }
  }

  /// Get the preview color (always shows the actual color, not theme-adjusted)
  Color get previewColor {
    switch (this) {
      case AccentColor.black:
        return Colors.black;
      case AccentColor.cyan:
        return const Color(0xFF00BCD4);
      case AccentColor.purple:
        return const Color(0xFF9C27B0);
      case AccentColor.orange:
        return const Color(0xFFFF9800);
      case AccentColor.green:
        return const Color(0xFF4CAF50);
      case AccentColor.blue:
        return const Color(0xFF2196F3);
      case AccentColor.red:
        return const Color(0xFFF44336);
      case AccentColor.pink:
        return const Color(0xFFE91E63);
      case AccentColor.teal:
        return const Color(0xFF009688);
      case AccentColor.indigo:
        return const Color(0xFF3F51B5);
      case AccentColor.amber:
        return const Color(0xFFFFC107);
      case AccentColor.lime:
        return const Color(0xFFCDDC39);
    }
  }

  /// Whether this is a light color that needs dark text/icons on top
  bool get isLightColor {
    switch (this) {
      case AccentColor.amber:
      case AccentColor.lime:
        return true;
      default:
        return false;
    }
  }

  /// Cosmetic ID that unlocks this color (null = free for everyone).
  /// Mirrors the seeded cosmetics catalog (migration 1936).
  String? get gatingCosmeticId {
    switch (this) {
      case AccentColor.indigo:
        return 'theme_iron';
      case AccentColor.amber:
        return 'theme_gold';
      default:
        return null;
    }
  }

  /// Level at which this color becomes available (null = from start).
  int? get unlockLevel {
    switch (this) {
      case AccentColor.indigo:
        return 10;
      case AccentColor.amber:
        return 75;
      default:
        return null;
    }
  }
}

/// Accent color provider - stores user's selected accent color
final accentColorProvider = StateNotifierProvider<AccentColorNotifier, AccentColor>((ref) {
  return AccentColorNotifier();
});

/// Notifier to manage accent color state
class AccentColorNotifier extends StateNotifier<AccentColor> {
  static const _key = 'accent_color';

  AccentColorNotifier() : super(AccentColor.orange) {
    _load();
  }

  /// Load saved accent color preference
  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString(_key) ?? 'orange';
      debugPrint('🎨 [AccentColor] Loaded accent: $value');
      state = AccentColor.values.firstWhere(
        (e) => e.name == value,
        orElse: () => AccentColor.orange,
      );
    } catch (e) {
      debugPrint('❌ [AccentColor] Error loading: $e');
    }
  }

  /// Set new accent color
  Future<void> setAccent(AccentColor color) async {
    debugPrint('🎨 [AccentColor] Setting accent to: ${color.name}');
    state = color;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, color.name);
      debugPrint('🎨 [AccentColor] Saved accent to prefs');
    } catch (e) {
      debugPrint('❌ [AccentColor] Error saving: $e');
    }
  }
}

/// Resolved accent — combines the user's enum-based [AccentColor] with an
/// optional accentOverride Color (currently used by the active gym profile).
///
/// Returned by [AccentColorScope.of] so that all existing call sites of
/// `AccentColorScope.of(context).getColor(isDark)` transparently apply
/// the accentOverride. Switching on `.accent` (the underlying enum) still works
/// where call sites need the original semantic color identity.
class ResolvedAccent {
  /// The user-selected accent. Always present — falls back to the default.
  final AccentColor accent;

  /// Higher-priority accentOverride (e.g. active gym profile color). When
  /// non-null, [getColor] / [previewColor] return this color directly.
  final Color? accentOverride;

  const ResolvedAccent({required this.accent, this.accentOverride});

  /// Returns the accentOverride if present, else the enum-based color for the
  /// requested brightness. Drop-in replacement for [AccentColor.getColor].
  Color getColor(bool isDark) => accentOverride ?? accent.getColor(isDark);

  /// Preview color (theme-independent). Override wins when set.
  Color get previewColor => accentOverride ?? accent.previewColor;

  /// Display name for the user-facing accent. The accentOverride is anonymous
  /// (no name) — fall back to the enum's display name.
  String get displayName => accent.displayName;

  /// Whether the visible color is a light tone that needs dark text/icons
  /// on top. Computed from the actual rendered color when an accentOverride is
  /// in play, so a light gym color also reports as light.
  bool isLightFor(bool isDark) {
    final c = getColor(isDark);
    return c.computeLuminance() > 0.55;
  }
}

/// InheritedWidget to provide accent color to the entire widget tree
/// Wrap your MaterialApp with AccentColorScope for automatic accent color support
class AccentColorScope extends InheritedWidget {
  final AccentColor accent;

  /// Optional accentOverride color that takes precedence over the enum-based
  /// accent. Wired from `gymAccentColorProvider` so the active gym
  /// profile's chosen color tints every widget that reads accent via
  /// `AccentColorScope.of(context).getColor(isDark)`.
  final Color? accentOverride;

  const AccentColorScope({
    super.key,
    required this.accent,
    this.accentOverride,
    required super.child,
  });

  /// Get the resolved accent (enum + accentOverride) from the nearest ancestor.
  static ResolvedAccent? maybeOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AccentColorScope>();
    if (scope == null) return null;
    return ResolvedAccent(accent: scope.accent, accentOverride: scope.accentOverride);
  }

  /// Get the resolved accent, or default to orange if not found.
  static ResolvedAccent of(BuildContext context) {
    return maybeOf(context) ?? const ResolvedAccent(accent: AccentColor.orange);
  }

  @override
  bool updateShouldNotify(AccentColorScope oldWidget) {
    return accent != oldWidget.accent || accentOverride != oldWidget.accentOverride;
  }
}

/// Consumer widget that wraps the app with AccentColorScope
/// Use this in your main.dart to enable dynamic accent colors throughout
class AccentColorScopeWrapper extends ConsumerWidget {
  final Widget child;

  const AccentColorScopeWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(accentColorProvider);
    // Active gym profile color takes priority over the user's app-level
    // accent. Wired here (not just into MaterialApp ColorScheme) because
    // most widgets read accent through AccentColorScope, not Theme.of.
    final gymOverride = ref.watch(gymAccentColorProvider);
    return AccentColorScope(
      accent: accent,
      accentOverride: gymOverride,
      child: child,
    );
  }
}
