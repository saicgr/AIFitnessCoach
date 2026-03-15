import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/accent_color_provider.dart';
import 'app_tour_controller.dart';
import 'app_tour_spotlight.dart';
import 'app_tour_tooltip_card.dart';

/// Full-screen tour overlay that spotlights a widget and shows a tooltip card.
/// Place this as the last child of the app's root Stack so it appears above everything.
class AppTourOverlay extends ConsumerStatefulWidget {
  const AppTourOverlay({super.key});

  @override
  ConsumerState<AppTourOverlay> createState() => _AppTourOverlayState();
}

class _AppTourOverlayState extends ConsumerState<AppTourOverlay>
    with SingleTickerProviderStateMixin {
  Rect _previousRect = Rect.zero;
  int _retryCount = 0;
  String? _lastStepId;
  static const int _maxRetries = 10;
  late final AnimationController _gradientController;

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _gradientController.dispose();
    super.dispose();
  }

  /// Get the bounding rect of a widget in global screen coordinates
  Rect _getTargetRect(GlobalKey key) {
    try {
      final context = key.currentContext;
      if (context == null) return Rect.zero;
      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.attached) return Rect.zero;
      final position = renderBox.localToGlobal(Offset.zero);
      return position & renderBox.size;
    } catch (_) {
      return Rect.zero;
    }
  }

  /// Determine tooltip Y position: above or below the spotlight rect
  double _tooltipTop({
    required Rect spotlightRect,
    required double cardHeight,
    required double screenHeight,
    required TooltipPosition position,
    required double spotlightPadding,
  }) {
    if (position == TooltipPosition.center) {
      return (screenHeight - cardHeight) / 2;
    }
    const gap = 24.0;
    final spaceBelow = screenHeight - (spotlightRect.bottom + spotlightPadding);
    final spaceAbove = spotlightRect.top - spotlightPadding;
    if (position == TooltipPosition.above) {
      return (spotlightRect.top - spotlightPadding - gap - cardHeight)
          .clamp(24.0, screenHeight - cardHeight - 24);
    }
    // Default: below; fallback to above if not enough space
    if (spaceBelow >= cardHeight + gap) {
      return spotlightRect.bottom + spotlightPadding + gap;
    } else if (spaceAbove >= cardHeight + gap) {
      return spotlightRect.top - spotlightPadding - gap - cardHeight;
    }
    return (screenHeight - cardHeight) / 2;
  }

  @override
  Widget build(BuildContext context) {
    final tourState = ref.watch(appTourControllerProvider);

    if (!tourState.isVisible) return const SizedBox.shrink();

    final step = tourState.currentTourStep;
    if (step == null) return const SizedBox.shrink();

    final screenSize = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = ref.read(accentColorProvider).getColor(isDark);
    final controller = ref.read(appTourControllerProvider.notifier);

    // Reset retry counter whenever the step changes
    if (step.id != _lastStepId) {
      _lastStepId = step.id;
      _retryCount = 0;
    }

    final targetRect = _getTargetRect(step.targetKey);
    final isTargetFound = targetRect != Rect.zero;

    // Use previous rect as animation start, then update for next step
    final beginRect = _previousRect == Rect.zero ? targetRect : _previousRect;
    final endRect = isTargetFound ? targetRect : Rect.zero;

    // Continuously re-measure the target rect while the tour is visible.
    // Async data loads (e.g. profile) can shift widgets after the initial
    // measurement, so we must keep tracking until the tour step changes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final currentTour = ref.read(appTourControllerProvider);
      if (!currentTour.isVisible) return;

      final freshRect = _getTargetRect(step.targetKey);
      final freshFound = freshRect != Rect.zero;

      if (freshFound) {
        // Check if target is off-screen (above or below visible area)
        final screenH = MediaQuery.of(context).size.height;
        final isOffScreen = freshRect.bottom < 0 || freshRect.top > screenH;
        if (isOffScreen) {
          // Scroll the target into view
          final targetContext = step.targetKey.currentContext;
          if (targetContext != null) {
            Scrollable.ensureVisible(
              targetContext,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              alignment: 0.3, // Position target at ~30% from top
            ).then((_) {
              if (mounted) setState(() {});
            });
          }
          return;
        }
        if (freshRect != _previousRect) {
          _previousRect = freshRect;
          setState(() {}); // target moved, update spotlight
        } else {
          // Even if unchanged, schedule another check for future shifts
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) setState(() {});
          });
        }
        _retryCount = 0;
      } else {
        // Target not found — try scrolling it into view
        final targetContext = step.targetKey.currentContext;
        if (targetContext != null) {
          Scrollable.ensureVisible(
            targetContext,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            alignment: 0.3,
          ).then((_) {
            if (mounted) setState(() {});
          });
        } else if (_retryCount < _maxRetries) {
          _retryCount++;
          setState(() {}); // re-check now the frame has settled
        }
      }
    });

    const spotlightPadding = 10.0;
    const estimatedCardHeight = 180.0;

    final tooltipTop = isTargetFound
        ? _tooltipTop(
            spotlightRect: targetRect,
            cardHeight: estimatedCardHeight,
            screenHeight: screenSize.height,
            position: step.position,
            spotlightPadding: spotlightPadding,
          )
        : (screenSize.height - estimatedCardHeight) / 2;

    final cardWidth = (screenSize.width - 48).clamp(0.0, 360.0);
    final tooltipLeft = ((screenSize.width - cardWidth) / 2).clamp(24.0, double.infinity);

    return Positioned.fill(
      child: GestureDetector(
        // Tapping overlay background advances the tour
        onTap: () => controller.next(),
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // Spotlight painter with animated rect transition
            Positioned.fill(
              child: TweenAnimationBuilder<Rect?>(
                tween: RectTween(begin: beginRect, end: endRect),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                builder: (_, rect, __) {
                  final paintRect = rect ?? endRect;
                  final hasGradient = step.highlightColors != null;
                  final radius = step.cornerRadius ?? 12.0;
                  if (hasGradient) {
                    return AnimatedBuilder(
                      animation: _gradientController,
                      builder: (_, __) => CustomPaint(
                        painter: AppTourSpotlightPainter(
                          spotlightRect: paintRect,
                          ringColor: accentColor,
                          cornerRadius: radius,
                          spotlightPadding: spotlightPadding,
                          ringGradientColors: step.highlightColors,
                          gradientRotation: _gradientController.value,
                        ),
                      ),
                    );
                  }
                  return CustomPaint(
                    painter: AppTourSpotlightPainter(
                      spotlightRect: paintRect,
                      ringColor: accentColor,
                      cornerRadius: radius,
                      spotlightPadding: spotlightPadding,
                    ),
                  );
                },
              ),
            ),
            // Tooltip card — absorbs taps so they don't advance the tour
            Positioned(
              left: tooltipLeft,
              top: tooltipTop,
              child: GestureDetector(
                onTap: () {},
                behavior: HitTestBehavior.opaque,
                child: AppTourTooltipCard(
                  title: step.title,
                  description: step.description,
                  currentStep: tourState.currentStep + 1,
                  totalSteps: tourState.steps.length,
                  isDark: isDark,
                  accentColor: accentColor,
                  onNext: () => controller.next(),
                  onPrev: tourState.currentStep > 0 ? () => controller.prev() : null,
                  onSkip: () => controller.dismiss(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
