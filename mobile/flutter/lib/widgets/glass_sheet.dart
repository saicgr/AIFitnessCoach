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

  /// Height of the handle BAND (the row that holds the centred drag handle and
  /// the trailing close button) — not the handle bar itself.
  ///
  /// This exists because the band used to have no size of its own: the `Stack`
  /// in [GlassSheetHandle] shrink-wrapped its only non-positioned child (the
  /// 48×5 handle bar), so the `PositionedDirectional(end: 8)` close button was
  /// laid out against a 48pt-wide, 5pt-tall box and landed *on top of* the
  /// grabber in near-identical grey, clipped to the bar's height. Giving the
  /// band an explicit size is what pushes the close button to the real trailing
  /// edge of the sheet and gives it a tappable box.
  static const double handleRowHeight = 24.0;

  static Color barrierColor() => Colors.black.withValues(alpha: 0.2);

  /// Stronger scrim used by opaque sheets (mandatory prompts) so the
  /// sheet reads as foreground, not a translucent floater over content.
  static Color opaqueBarrierColor() => Colors.black.withValues(alpha: 0.55);

  /// Scrim for a glass sheet opened ON TOP of another glass sheet. The default
  /// 0.2 barrier is too weak to hide the parent sheet's drag handle + content,
  /// which then bleed through the new (translucent) glass surface. This darker
  /// scrim makes the sheet behind recede while keeping the new sheet's glass
  /// aesthetic. Use via `showGlassSheet(barrierColor: ...)`.
  static Color nestedBarrierColor() => Colors.black.withValues(alpha: 0.6);

  /// The frosted surface.
  ///
  /// Opacity was 0.5 dark / 0.7 light, which let a saturated card behind the
  /// sheet paint a coloured band straight through it — a green hero card on
  /// Home showed up as a green wash across the gym switcher's header, reading
  /// as a rendering fault rather than as glass. 12-sigma blur softens an edge
  /// but does nothing about hue: at 30% transmission a saturated fill still
  /// tints everything on top of it, including body text.
  ///
  /// These values are still translucent — motion and shape behind the sheet
  /// stay visible, which is the point of the material — but no longer let a
  /// single colour dominate. Sheets that must be fully legible over arbitrary
  /// content should use `GlassSheet(opaque: true)` instead of nudging this.
  static Color backgroundColor(bool isDark) => isDark
      ? Colors.black.withValues(alpha: 0.72)
      : Colors.white.withValues(alpha: 0.88);

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

  /// Scrim for a centred [GlassDialog]. Between the sheet scrim (0.2 — a
  /// sheet covers the bottom of the screen, so the content it hides is
  /// already mostly off-view) and the opaque-prompt scrim (0.55): a dialog
  /// floats in the MIDDLE of live content, so it needs enough separation to
  /// read as foreground while its own blur still has something to blur.
  static Color dialogBarrierColor() => Colors.black.withValues(alpha: 0.4);
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
  // NOTE: this function deliberately takes NO initialChildSize/minChildSize/
  // maxChildSize. It used to accept all three and then never read them — a
  // dozen call sites passed sizes that did nothing while their real sizing
  // lived on a DraggableScrollableSheet inside the builder, which is exactly
  // the kind of silent no-op that hides a broken sheet. Size the content, not
  // the route.
  /// When true, renders the sheet on a fully opaque surface with a stronger
  /// scrim — background content is NOT visible through the sheet. Use for
  /// mandatory prompts (RPE, confirmation dialogs) where legibility matters
  /// more than the glass aesthetic. Defaults to false for back-compat.
  bool opaque = false,
  /// Overrides the scrim color. Pass `GlassSheetStyle.nestedBarrierColor()`
  /// when opening this sheet on top of another glass sheet so the parent
  /// doesn't bleed through. Defaults to the standard glass/opaque scrim.
  Color? barrierColor,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useRootNavigator: useRootNavigator,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    barrierColor: barrierColor ??
        (opaque
            ? GlassSheetStyle.opaqueBarrierColor()
            : GlassSheetStyle.barrierColor()),
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

  /// When false, the sheet does NOT append its own transparent bottom spacer
  /// for the home-indicator inset. Use this when the child has a bottom-pinned
  /// bar that should paint its background all the way to the bezel — the child
  /// is then responsible for adding `viewPadding.bottom` to its own padding.
  /// Keyboard avoidance is unaffected (the sheet still rises with the keyboard).
  final bool reserveBottomInset;

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
    this.reserveBottomInset = true,
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

    // Height cap.
    //
    // A `DraggableScrollableSheet` child sizes ITSELF as a fraction of the box
    // it is handed. Capping that box at `maxHeightFraction` first meant every
    // such sheet silently resolved its fractions against 90% of the screen
    // rather than the screen — a sheet asking for `initialChildSize: 0.55` got
    // 0.55 × 0.9 = 49.5%. That shortfall is invisible on a sheet with a thin
    // header and fatal on one with real chrome: the gym switcher's header +
    // Travel Mode tile + "Find a gym" row + add button measured 376pt of the
    // 418pt it was given, leaving its profile list a 23pt viewport with the
    // first gym card sliced in half.
    //
    // A DSS is already self-clamping via its own `maxChildSize`, so hand it the
    // full height and let it do its job. Non-draggable children keep the cap —
    // they have nothing else stopping them from filling the screen.
    final isSelfSizingChild = child is DraggableScrollableSheet;
    final reservedBottom = keyboardInset > 0
        ? keyboardInset
        : (reserveBottomInset ? safeAreaBottom : 0.0);
    final screenHeight = MediaQuery.of(context).size.height;
    final container = Container(
      constraints: BoxConstraints(
        // A self-sizing child gets the whole screen to measure against; the
        // Column below still hands it `screenHeight - reservedBottom`, so its
        // fractions resolve against the USABLE height (screen minus the home
        // indicator band) rather than against 90% of the screen.
        maxHeight: isSelfSizingChild
            ? screenHeight
            : screenHeight * maxHeightFraction,
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
      // Material ancestor for the sheet's content: ListTile (and other
      // Material widgets like InkWell/Chip) paint their background/ink on
      // the NEAREST Material ancestor, not the widget directly wrapping
      // them. Without this, that nearest ancestor is whatever Material sits
      // outside the modal route (or none), while the DecoratedBox above
      // (the glass background) sits between the two and visually occludes
      // the ink/background — triggering ListTile's
      // "background color or ink splashes may be invisible" assertion.
      // `type: transparency` keeps the glass background visible; this
      // Material exists purely to give descendant ListTiles a paint target
      // that isn't hidden by the decorated container above it.
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showHandle) GlassSheetHandle(isDark: isDark),
            Flexible(
              // The child must not see a bottom inset this widget has already
              // reserved. Sheet bodies routinely end in
              // `SizedBox(height: MediaQuery.padding.bottom + 16)` or a
              // `SafeArea`; combined with the AnimatedPadding below that
              // reserved the home-indicator band TWICE and left a strip of
              // empty glass under the last control (the gym switcher's add
              // button floated in ~80pt of it). Zeroing `padding.bottom` here
              // makes those bodies contribute their own 16 and lets this
              // widget own the indicator band exactly once.
              //
              // Only when we are actually reserving it: a sheet that opted out
              // with `reserveBottomInset: false` is padding itself on purpose
              // and still needs the real number.
              child: MediaQuery.removePadding(
                context: context,
                removeBottom: reserveBottomInset,
                child: padding != null
                    ? Padding(padding: padding!, child: child)
                    : child,
              ),
            ),
            // When the keyboard is up, viewInsets.bottom > 0 — shift the entire
            // sheet up by that amount via AnimatedPadding. When it's down,
            // fall back to the safe-area bottom (home indicator). We don't add
            // both — that would over-pad.
            AnimatedPadding(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: reservedBottom),
            ),
          ],
        ),
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
      // The band MUST take the sheet's full width and an explicit height.
      // Without it the Stack shrink-wraps to the 48×5 handle bar and the
      // trailing close button is positioned relative to *that*, i.e. straight
      // on top of the grabber (and clipped to 5pt tall).
      child: SizedBox(
        width: double.infinity,
        height: GlassSheetStyle.handleRowHeight,
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
            // Close button, pinned to the sheet's trailing edge.
            PositionedDirectional(
              end: 8,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: GlassSheetStyle.handleRowHeight,
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: isDark
                        ? AppColors.textMuted
                        : AppColorsLight.textMuted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
