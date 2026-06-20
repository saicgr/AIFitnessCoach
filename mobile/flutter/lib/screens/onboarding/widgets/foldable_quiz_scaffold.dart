import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/window_mode_provider.dart';
import 'onboarding_theme.dart';

/// Reusable foldable-adaptive scaffold for onboarding screens.
class FoldableQuizScaffold extends ConsumerWidget {
  final String headerTitle;
  final String? headerSubtitle;
  final Widget? headerExtra;
  final Widget? headerOverlay;
  final Widget? progressBar;

  /// Main body. NOTE: `content` is placed inside an `Expanded` and is NOT
  /// wrapped in a scroll view by this scaffold — it MUST manage its own
  /// overflow (be a `SingleChildScrollView`/`ListView`/`CustomScrollView`, or
  /// be guaranteed to fit). A fixed `Column` taller than the viewport here
  /// will overflow and push `button` off-screen. Prefer the pinned [button]
  /// slot for the CTA so it is always reachable above a scrollable body.
  final Widget content;

  /// Pinned action rendered OUTSIDE the scrollable [content] area — always
  /// visible at the bottom regardless of content height.
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

  static bool isVerticalHinge(Rect? hingeBounds) {
    if (hingeBounds == null) return true;
    return hingeBounds.height > hingeBounds.width;
  }

  static bool shouldUseFoldableLayout(WindowModeState windowState) {
    if (windowState.isFoldable && windowState.hingeBounds != null) {
      return isVerticalHinge(windowState.hingeBounds);
    }
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

  Widget _buildPhoneLayout(BuildContext context) {
    return Column(
      children: [
        if (headerOverlay != null) SizedBox(width: double.infinity, child: headerOverlay!),
        if (progressBar != null) progressBar!,
        if (progressBar != null) const SizedBox(height: 8),
        Expanded(child: content),
        if (button != null) ...[
          const SizedBox(height: 8),
          button!,
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFoldableLayout(BuildContext context, WindowModeState windowState) {
    final t = OnboardingTheme.of(context);
    final hingeBounds = windowState.hingeBounds;
    final safeLeft = MediaQuery.of(context).padding.left;
    final rawHingeLeft = hingeBounds?.left ?? MediaQuery.of(context).size.width / 2;
    final hingeLeft = (rawHingeLeft - safeLeft).clamp(100.0, double.infinity);
    final hingeWidth = hingeBounds?.width ?? 0;

    return Column(
      children: [
        if (headerOverlay != null) SizedBox(width: double.infinity, child: headerOverlay!),
        if (progressBar != null) ...[
          progressBar!,
          const SizedBox(height: 16),
        ],
        Expanded(
          child: Row(
            children: [
              SizedBox(
                width: hingeLeft,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          headerTitle,
                          style: TextStyle(
                            fontSize: 26, fontWeight: FontWeight.w700,
                            color: t.textPrimary, height: 1.3, letterSpacing: -0.5,
                          ),
                        ),
                        if (headerSubtitle != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            headerSubtitle!,
                            style: TextStyle(
                              fontSize: 15, color: t.textSecondary,
                              fontWeight: FontWeight.w500, height: 1.4,
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
              SizedBox(width: hingeWidth),
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
    );
  }
}
