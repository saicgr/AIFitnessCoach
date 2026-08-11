/// Glassmorphic centred dialog — the `showDialog` counterpart to
/// [GlassSheet]/[showGlassSheet].
///
/// Dialogs were the one modal surface still painting a flat opaque
/// `ThemeColors.elevated` card while every bottom sheet in the app used the
/// blurred glass treatment, so a dialog opened over Home read as a different
/// design language than a sheet opened from the same screen.
///
/// Every visual token here comes from [GlassSheetStyle] — the SAME class the
/// sheets read — so the two surfaces cannot drift apart. There is deliberately
/// no local blur/radius/border/background constant in this file.
///
/// Usage:
/// ```dart
/// final result = await showGlassDialog<String>(
///   context: context,
///   builder: (ctx) => GlassDialog(
///     child: Column(mainAxisSize: MainAxisSize.min, children: [...]),
///   ),
/// );
/// ```
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import 'glass_sheet.dart';

/// Shows a [GlassDialog]-shaped route with the glass scrim.
///
/// Thin wrapper over [showDialog] so callers get the right barrier without
/// having to remember [GlassSheetStyle.dialogBarrierColor]. The builder should
/// return a [GlassDialog].
Future<T?> showGlassDialog<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
  Color? barrierColor,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    useRootNavigator: useRootNavigator,
    barrierColor: barrierColor ?? GlassSheetStyle.dialogBarrierColor(),
    builder: builder,
  );
}

/// Transparent centred dialog that blurs the content behind it.
///
/// Mirrors [GlassSheet]'s construction — `ClipRRect` → `BackdropFilter` →
/// decorated `Container` → transparency `Material` — with two differences that
/// are inherent to being a dialog rather than a sheet: the radius is applied to
/// ALL FOUR corners (a sheet only rounds its top, because its bottom edge is
/// off-screen), and there is no drag handle or keyboard/home-indicator inset
/// (a dialog is centred by the route, not bottom-anchored).
class GlassDialog extends StatelessWidget {
  final Widget child;

  /// Inner padding around [child]. The default matches the app's standard
  /// dialog inset.
  final EdgeInsetsGeometry padding;

  /// Distance from the dialog to the screen edges.
  final EdgeInsets insetPadding;

  final double blurSigma;
  final double borderRadius;

  /// Caps the dialog's width so it doesn't stretch edge-to-edge on a tablet.
  final double maxWidth;

  /// When true, renders a fully opaque surface with no blur — for a dialog
  /// whose content must stay legible over busy backgrounds. Mirrors
  /// [GlassSheet.opaque].
  final bool opaque;

  const GlassDialog({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.insetPadding = const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
    this.blurSigma = GlassSheetStyle.blurSigma,
    this.borderRadius = GlassSheetStyle.borderRadius,
    this.maxWidth = 420,
    this.opaque = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(borderRadius);

    final container = Container(
      decoration: BoxDecoration(
        color: opaque
            ? GlassSheetStyle.opaqueBackgroundColor(isDark)
            : GlassSheetStyle.backgroundColor(isDark),
        borderRadius: radius,
        border: Border.all(
          color: GlassSheetStyle.borderColor(isDark),
          width: 0.5,
        ),
      ),
      // Same reason as GlassSheet's: descendant Material widgets (buttons,
      // ListTile, InkWell) paint their ink on the nearest Material ancestor.
      // Without this the decorated container above would occlude that ink.
      child: Material(
        type: MaterialType.transparency,
        child: Padding(padding: padding, child: child),
      ),
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: insetPadding,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: ClipRRect(
          borderRadius: radius,
          child: opaque
              ? container
              : BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                  child: container,
                ),
        ),
      ),
    );
  }
}
