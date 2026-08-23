import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// THE app accent lives here and NOWHERE else.
//
// History (E2E register rows 13c + 15): the accent used to be decided in three
// places at once — `AccentColorScopeWrapper` (fixed by 4662b7d8), `app.dart`'s
// `effectivePrimary` feeding `ColorScheme.primary`, and ~1,600 widget-level
// hardcoded accent-family literals. Because one of those sources (the gym
// profile colour) resolves ASYNCHRONOUSLY, the same screen painted orange on
// one launch and cyan on the next, and neighbouring surfaces disagreed inside a
// single frame (orange screen, cyan "Quick check-in" sheet).
//
// The contract now:
//   • `accentColorProvider` is the ONLY input.
//   • `appPrimaryColorProvider` is the ONLY thing `MaterialApp` may pass as
//     `ColorScheme.primary`. It takes no override parameter, so a
//     load-timing-dependent colour cannot be reintroduced without deleting it.
//   • `AccentColorScope.colorOf(context)` / `context.accentColor` is the ONLY
//     thing a widget may read for "the accent".
//   • `AccentColorScope` no longer accepts an override colour at all.
//
// gymAccentColorProvider is intentionally NOT imported here. The active gym's
// colour is a per-gym identity signal — gym-identifying UI (the gym chip, the
// Switch Gym sheet) should import it directly from
// data/providers/gym_profile_provider.dart and scope it to that widget.
//
// A regression gate lives beside this file: `accent_source_gate.dart`.
// ─────────────────────────────────────────────────────────────────────────────

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

  /// Resets the LIVE accent to the default (orange) without touching the
  /// persisted preference. `accent_color` is a device-wide SharedPreferences
  /// key with no user scoping, so a brand-new pre-auth onboarding session on
  /// a device that previously had a different account signed in otherwise
  /// inherits that account's accent choice — the whole point of the
  /// pre-auth flow is a single deterministic brand colour (see
  /// `AppColors.onboardingAccent`), not whatever a stranger last picked.
  /// Called once from `IntroScreen`, which only ever renders for a signed-out
  /// visitor, so this can never clobber a genuinely active session.
  /// Deliberately does NOT persist — a user who backs out to sign in to
  /// their EXISTING account must still get their own saved preference back.
  void resetForNewOnboarding() {
    state = AccentColor.orange;
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

/// The single fully-resolved app accent.
///
/// Deliberately has NO override field. The previous `accentOverride` (wired to
/// the active gym profile's colour) is what made the accent load-timing
/// dependent — see the header comment. Removing the field, rather than merely
/// stopping one caller from setting it, is what makes the regression
/// impossible: there is no longer an API through which a second accent source
/// can be injected.
class ResolvedAccent {
  /// The user-selected accent. Always present — falls back to the default.
  final AccentColor accent;

  const ResolvedAccent({required this.accent});

  /// The accent colour for the requested brightness.
  Color getColor(bool isDark) => accent.getColor(isDark);

  /// Preview color (theme-independent).
  Color get previewColor => accent.previewColor;

  /// Display name for the user-facing accent.
  String get displayName => accent.displayName;

  /// Whether the visible color is a light tone that needs dark text/icons
  /// on top.
  bool isLightFor(bool isDark) => getColor(isDark).computeLuminance() > 0.55;
}

/// THE colour `MaterialApp`'s `ColorScheme.primary` must be built from.
///
/// `app.dart` must read this and nothing else. It takes no override argument
/// on purpose: `effectivePrimary = gymOverride ?? accent.getColor(isDark)` is
/// exactly the expression that made the whole app repaint when an async fetch
/// landed (register row 15, still live in `app.dart` after 4662b7d8).
final appPrimaryColorProvider = Provider.family<Color, bool>((ref, isDark) {
  return ref.watch(accentColorProvider).getColor(isDark);
});

/// InheritedWidget to provide accent color to the entire widget tree
/// Wrap your MaterialApp with AccentColorScope for automatic accent color support
class AccentColorScope extends InheritedWidget {
  final AccentColor accent;

  const AccentColorScope({
    super.key,
    required this.accent,
    required super.child,
  });

  /// Get the resolved accent from the nearest ancestor.
  static ResolvedAccent? maybeOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AccentColorScope>();
    if (scope == null) return null;
    return ResolvedAccent(accent: scope.accent);
  }

  /// Get the resolved accent, or default to orange if not found.
  static ResolvedAccent of(BuildContext context) {
    return maybeOf(context) ?? const ResolvedAccent(accent: AccentColor.orange);
  }

  /// The one-liner every surface should use for "the accent colour".
  ///
  /// Resolves brightness from the ambient [Theme], so a widget never has to
  /// re-derive `isDark` (a place where surfaces used to diverge).
  static Color colorOf(BuildContext context) {
    return of(context).getColor(Theme.of(context).brightness == Brightness.dark);
  }

  @override
  bool updateShouldNotify(AccentColorScope oldWidget) {
    return accent != oldWidget.accent;
  }
}

/// `context.accentColor` — the shortest correct way to read the accent.
///
/// Exists so that "read the theme" is strictly less typing than hardcoding a
/// colour; the regression gate (`accent_source_gate.dart`) points offenders
/// here.
extension AccentColorContext on BuildContext {
  Color get accentColor => AccentColorScope.colorOf(this);
}

/// Consumer widget that wraps the app with AccentColorScope
/// Use this in your main.dart to enable dynamic accent colors throughout
class AccentColorScopeWrapper extends ConsumerWidget {
  final Widget child;

  const AccentColorScopeWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(accentColorProvider);

    // The active gym profile's colour deliberately does NOT repaint the whole
    // app any more.
    //
    // It used to: `accentOverride: ref.watch(gymAccentColorProvider)`. That
    // provider resolves `activeGymProfileProvider?.profileColor`, and the gym
    // profile loads ASYNCHRONOUSLY (cache-first, then network). So every screen
    // painted in the user's accent (orange) before the profile landed and the
    // gym's colour (cyan) after it — the same screen, same account, rendering a
    // different colour depending on load timing, and flipping mid-session as
    // the fetch completed.
    //
    // Observed directly: Home rendered cyan, and after nothing but an app
    // relaunch, orange. The active-workout screen and the meal-log sheet did
    // the same across runs. Colour is the user's fastest signal for "this is
    // the important thing"; when the primary action is orange one launch and
    // cyan the next, the accent stops carrying meaning.
    //
    // The user's chosen accent is now the single source of truth for the app
    // accent, so it is stable from first frame. `gymAccentColorProvider` is
    // still exported and should be read directly by gym-identifying UI (the
    // gym chip, the Switch Gym sheet) where a per-gym colour is meaningful and
    // scoped.
    return AccentColorScope(
      accent: accent,
      child: child,
    );
  }
}
