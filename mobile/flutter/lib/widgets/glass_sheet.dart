import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Standard glassmorphic bottom sheet styling constants
class GlassSheetStyle {
  GlassSheetStyle._();

  static const double borderRadius = 28.0;
  static const double blurSigma = 12.0;
  static const double handleWidth = 40.0;
  static const double handleHeight = 4.0;
  static const double handleTopPadding = 12.0;

  static Color barrierColor() => Colors.black.withValues(alpha: 0.2);

  static Color backgroundColor(bool isDark) => isDark
      ? Colors.black.withValues(alpha: 0.5)
      : Colors.white.withValues(alpha: 0.7);

  static Color borderColor(bool isDark) => isDark
      ? Colors.white.withValues(alpha: 0.15)
      : Colors.black.withValues(alpha: 0.08);

  static Color handleColor(bool isDark) => isDark
      ? AppColors.textMuted.withValues(alpha: 0.5)
      : AppColorsLight.textMuted.withValues(alpha: 0.5);
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
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useRootNavigator: useRootNavigator,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    barrierColor: GlassSheetStyle.barrierColor(),
    builder: builder,
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

  const GlassSheet({
    super.key,
    required this.child,
    this.maxHeightFraction = 0.9,
    this.blurSigma = GlassSheetStyle.blurSigma,
    this.borderRadius = GlassSheetStyle.borderRadius,
    this.showHandle = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * maxHeightFraction,
          ),
          decoration: BoxDecoration(
            color: GlassSheetStyle.backgroundColor(isDark),
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
            ],
          ),
        ),
      ),
    );
  }
}

/// Standard handle bar for glass sheets
class GlassSheetHandle extends StatelessWidget {
  final bool isDark;

  const GlassSheetHandle({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: GlassSheetStyle.handleTopPadding),
      child: Center(
        child: Container(
          width: GlassSheetStyle.handleWidth,
          height: GlassSheetStyle.handleHeight,
          decoration: BoxDecoration(
            color: GlassSheetStyle.handleColor(isDark),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
