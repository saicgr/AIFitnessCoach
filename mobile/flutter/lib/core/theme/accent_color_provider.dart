import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// InheritedWidget to provide accent color to the entire widget tree
/// Wrap your MaterialApp with AccentColorScope for automatic accent color support
class AccentColorScope extends InheritedWidget {
  final AccentColor accent;

  const AccentColorScope({
    super.key,
    required this.accent,
    required super.child,
  });

  /// Get the current accent color from the nearest ancestor
  static AccentColor? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AccentColorScope>()?.accent;
  }

  /// Get the current accent color, or default to orange if not found
  static AccentColor of(BuildContext context) {
    return maybeOf(context) ?? AccentColor.orange;
  }

  @override
  bool updateShouldNotify(AccentColorScope oldWidget) {
    return accent != oldWidget.accent;
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
    return AccentColorScope(
      accent: accent,
      child: child,
    );
  }
}
