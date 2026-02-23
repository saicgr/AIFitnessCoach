/// Centralized spacing and radius constants for the app.
///
/// Based on the existing 8px grid system used throughout the codebase.
/// These constants document the values already in use and provide
/// a single source of truth for future development.
///
/// ```dart
/// SizedBox(height: AppSpacing.md)
/// BorderRadius.circular(AppRadius.md)
/// ```
class AppSpacing {
  AppSpacing._();

  /// 4px - tight spacing (icon gaps, inline padding)
  static const double xs = 4;

  /// 8px - small spacing (between related items)
  static const double sm = 8;

  /// 16px - medium spacing (section padding, card padding)
  static const double md = 16;

  /// 24px - large spacing (between sections)
  static const double lg = 24;

  /// 32px - extra large spacing (screen-level padding)
  static const double xl = 32;

  /// 48px - extra extra large spacing (hero sections)
  static const double xxl = 48;
}

/// Centralized border radius constants for the app.
///
/// Documents the radius values already used in the codebase:
/// - Chips/small elements: 8
/// - Input fields/cards: 12
/// - Large cards/dialogs: 16
/// - Buttons/pills: 24
/// - Bottom sheets: 28
class AppRadius {
  AppRadius._();

  /// 8px - chips, tags, small elements
  static const double sm = 8;

  /// 12px - input fields, snackbars, list items
  static const double md = 12;

  /// 16px - cards, glass surfaces
  static const double lg = 16;

  /// 24px - buttons, large cards, dialogs
  static const double xl = 24;

  /// 28px - bottom sheets, elevated buttons
  static const double sheet = 28;
}
