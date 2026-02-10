import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/window_mode_provider.dart';

/// Reusable foldable-adaptive scaffold for onboarding screens.
///
/// On phone / closed foldable: standard vertical Column layout.
/// On book-fold open (vertical hinge): Supporting Pane pattern —
///   header content on the left pane, interactive content on the right pane.
class FoldableQuizScaffold extends ConsumerWidget {
  /// Title text displayed in the left pane on foldable, or above content on phone.
  final String headerTitle;

  /// Subtitle text displayed below the title.
  final String? headerSubtitle;

  /// Extra widget below the subtitle (illustration, icon, progress dots, etc.).
  final Widget? headerExtra;

  /// Floating overlay spanning full width (back button, step counter, etc.).
  final Widget? headerOverlay;

  /// Progress bar widget shown above the content area.
  final Widget? progressBar;

  /// Main interactive content (quiz options, form fields) — right pane on foldable.
  final Widget content;

  /// Button pinned at the bottom of the content area (continue, generate, etc.).
  final Widget? button;

  const FoldableQuizScaffold({
    super.key,
    required this.headerTitle,
    this.headerSubtitle,
    this.headerExtra,
    this.headerOverlay,
    this.progressBar,
    required this.content,
    this.button,
  });

  /// Determine hinge orientation: true = vertical hinge (book-fold),
  /// false = horizontal hinge (flip phone).
  static bool isVerticalHinge(Rect? hingeBounds) {
    if (hingeBounds == null) return true; // default to book-fold
    return hingeBounds.height > hingeBounds.width;
  }

  /// Whether the current window state should use a foldable side-by-side layout.
  static bool shouldUseFoldableLayout(WindowModeState windowState) {
    final posture = windowState.foldablePosture;
    if (posture == FoldablePosture.none) return false;
    return isVerticalHinge(windowState.hingeBounds);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final windowState = ref.watch(windowModeProvider);
    final useFoldable = shouldUseFoldableLayout(windowState);

    if (useFoldable) {
      return _buildFoldableLayout(context, windowState);
    }
    return _buildPhoneLayout(context);
  }

  // ─── Phone / closed layout ────────────────────────────────────────

  Widget _buildPhoneLayout(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            if (headerOverlay != null) const SizedBox(height: 72),
            if (progressBar != null) progressBar!,
            if (progressBar != null) const SizedBox(height: 32),
            Expanded(child: content),
            if (button != null) ...[
              const SizedBox(height: 8),
              button!,
            ],
            const SizedBox(height: 16),
          ],
        ),
        if (headerOverlay != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: headerOverlay!,
          ),
      ],
    );
  }

  // ─── Foldable side-by-side layout (vertical hinge) ────────────────

  Widget _buildFoldableLayout(BuildContext context, WindowModeState windowState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    final hingeBounds = windowState.hingeBounds;
    final safeLeft = MediaQuery.of(context).padding.left;
    final rawHingeLeft =
        hingeBounds?.left ?? MediaQuery.of(context).size.width / 2;
    final hingeLeft = (rawHingeLeft - safeLeft).clamp(100.0, double.infinity);
    final hingeWidth = hingeBounds?.width ?? 0;

    return Stack(
      children: [
        Column(
          children: [
            if (headerOverlay != null) const SizedBox(height: 72),
            // Progress bar spans full width across both panes
            if (progressBar != null) ...[
              progressBar!,
              const SizedBox(height: 16),
            ],
            Expanded(
              child: Row(
                children: [
                  // ── Left pane (header / context) ──
                  SizedBox(
                    width: hingeLeft,
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              headerTitle,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                                height: 1.3,
                                letterSpacing: -0.5,
                              ),
                            ),
                            if (headerSubtitle != null) ...[
                              const SizedBox(height: 10),
                              Text(
                                headerSubtitle!,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: textSecondary,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                              ),
                            ],
                            if (headerExtra != null) ...[
                              const SizedBox(height: 24),
                              headerExtra!,
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Hinge gap ──
                  SizedBox(width: hingeWidth),

                  // ── Right pane (interactive content) ──
                  Expanded(
                    child: Column(
                      children: [
                        const SizedBox(height: 4),
                        Expanded(child: content),
                        if (button != null) ...[
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: button!,
                          ),
                        ],
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (headerOverlay != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: headerOverlay!,
          ),
      ],
    );
  }
}
