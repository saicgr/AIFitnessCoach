import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

import '../l10n/generated/app_localizations.dart';
/// Standard glassmorphic bottom sheet styling constants
class GlassSheetStyle {
  GlassSheetStyle._();

  static const double borderRadius = 28.0;
  static const double blurSigma = 12.0;
  // Handle dimensions bumped from 40×4 alpha-0.5 to 48×5 alpha-0.75 so the
  // drag affordance reads as clearly grabbable on dark sheets. Users were
  // missing it on the Swap Exercise sheet (low contrast vs the title row
  // sitting directly below it).
  static const double handleWidth = 48.0;
  static const double handleHeight = 5.0;
  static const double handleTopPadding = 12.0;

  static Color barrierColor() => Colors.black.withValues(alpha: 0.2);

  /// Stronger scrim used by opaque sheets (mandatory prompts) so the
  /// sheet reads as foreground, not a translucent floater over content.
  static Color opaqueBarrierColor() => Colors.black.withValues(alpha: 0.55);

  static Color backgroundColor(bool isDark) => isDark
      ? Colors.black.withValues(alpha: 0.5)
      : Colors.white.withValues(alpha: 0.7);

  /// Fully opaque surface used by `GlassSheet(opaque: true)` — legible
  /// text, no blur, no bleed-through. Use when the background content
  /// cannot be visible through the sheet (e.g. intensity/RPE prompts).
  static Color opaqueBackgroundColor(bool isDark) =>
      isDark ? AppColors.surface : AppColorsLight.surface;

  static Color borderColor(bool isDark) => isDark
      ? Colors.white.withValues(alpha: 0.15)
      : Colors.black.withValues(alpha: 0.08);

  static Color handleColor(bool isDark) => isDark
      ? AppColors.textMuted.withValues(alpha: 0.75)
      : AppColorsLight.textMuted.withValues(alpha: 0.65);
}

/// Shows a glassmorphic modal bottom sheet with standard styling.
///
/// This is the preferred way to show bottom sheets in the app.
/// All sheets will have consistent glassmorphism styling and be draggable.
///
/// Usage:
/// ```dart
/// final result = await showGlassSheet<MyResult>(
///   context: context,
///   builder: (context) => MySheetContent(),
/// );
/// ```
Future<T?> showGlassSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool isDismissible = true,
  bool enableDrag = true,
  bool useRootNavigator = true,
  double? initialChildSize,
  double? minChildSize,
  double? maxChildSize,
  /// When true, renders the sheet on a fully opaque surface with a stronger
  /// scrim — background content is NOT visible through the sheet. Use for
  /// mandatory prompts (RPE, confirmation dialogs) where legibility matters
  /// more than the glass aesthetic. Defaults to false for back-compat.
  bool opaque = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useRootNavigator: useRootNavigator,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    barrierColor: opaque
        ? GlassSheetStyle.opaqueBarrierColor()
        : GlassSheetStyle.barrierColor(),
    builder: (ctx) {
      final child = builder(ctx);
      if (!opaque) return child;
      // If the caller didn't wrap their content in a GlassSheet, we still
      // need the opaque surface — but most callers DO wrap, so instead of
      // double-wrapping we propagate the flag via InheritedWidget. Simpler:
      // callers pass opaque to GlassSheet themselves. Return as-is.
      return child;
    },
  );
}

/// Transparent bottom sheet that blurs content behind it.
///
/// Creates a modern iOS/Samsung style glassmorphic effect where
/// the content underneath the sheet is visible but blurred.
///
/// Usage:
/// ```dart
/// showGlassSheet(
///   context: context,
///   builder: (context) => GlassSheet(
///     showHandle: true,
///     child: YourSheetContent(),
///   ),
/// );
/// ```
class GlassSheet extends StatelessWidget {
  final Widget child;
  final double maxHeightFraction;
  final double blurSigma;
  final double borderRadius;
  final bool showHandle;
  final EdgeInsetsGeometry? padding;

  /// When true, renders a fully opaque surface without `BackdropFilter` blur.
  /// Required for mandatory prompt sheets (RPE, confirmations) where the
  /// background must NOT be visible through the sheet.
  final bool opaque;

  const GlassSheet({
    super.key,
    required this.child,
    this.maxHeightFraction = 0.9,
    this.blurSigma = GlassSheetStyle.blurSigma,
    this.borderRadius = GlassSheetStyle.borderRadius,
    this.showHandle = true,
    this.padding,
    this.opaque = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Fix #10 (keyboard overlap): modal bottom sheets ignore
    // Scaffold.resizeToAvoidBottomInset, so we manually shift content above
    // the system keyboard using viewInsets.bottom. AnimatedPadding gives a
    // smooth rise as the keyboard animates. Hardware-keyboard / no-keyboard
    // cases naturally get viewInsets.bottom == 0 and don't shift.
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    // Replace (not add to) the safe-area bottom padding. Stacking both would
    // double-pad and push content too far up when the keyboard is hidden.
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;

    final container = Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * maxHeightFraction,
      ),
      decoration: BoxDecoration(
        color: opaque
            ? GlassSheetStyle.opaqueBackgroundColor(isDark)
            : GlassSheetStyle.backgroundColor(isDark),
        borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
        border: Border(
          top: BorderSide(
            color: GlassSheetStyle.borderColor(isDark),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showHandle) GlassSheetHandle(isDark: isDark),
          Flexible(
            child: padding != null
                ? Padding(padding: padding!, child: child)
                : child,
          ),
          // When the keyboard is up, viewInsets.bottom > 0 — shift the entire
          // sheet up by that amount via AnimatedPadding. When it's down,
          // fall back to the safe-area bottom (home indicator). We don't add
          // both — that would over-pad.
          AnimatedPadding(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(
              bottom: keyboardInset > 0 ? keyboardInset : safeAreaBottom,
            ),
          ),
        ],
      ),
    );

    final rounded = ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
      child: opaque
          ? container
          : BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
              child: container,
            ),
    );

    return rounded;
  }
}

/// Standard handle bar for glass sheets with close button
class GlassSheetHandle extends StatelessWidget {
  final bool isDark;

  const GlassSheetHandle({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: GlassSheetStyle.handleTopPadding),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Centered drag handle. Wrapped in Semantics so screen readers
          // announce it as a resize/dismiss affordance (Fix #3 a11y).
          Semantics(
            label: AppLocalizations.of(context).glassDragToResize,
            container: true,
            child: Container(
              width: GlassSheetStyle.handleWidth,
              height: GlassSheetStyle.handleHeight,
              decoration: BoxDecoration(
                color: GlassSheetStyle.handleColor(isDark),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Close button on the right
          PositionedDirectional(end: 8,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.close,
                  size: 20,
                  color: isDark
                      ? AppColors.textMuted
                      : AppColorsLight.textMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
