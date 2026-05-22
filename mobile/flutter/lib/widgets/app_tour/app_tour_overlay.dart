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
    with TickerProviderStateMixin {
  Rect _previousRect = Rect.zero;
  int _retryCount = 0;
  String? _lastStepId;
  static const int _maxRetries = 30;
  late final AnimationController _gradientController;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  bool _wasVisible = false;

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _fadeController.dispose();
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
    // Default: below — but auto-flip ABOVE when the target sits in the lower
    // half of the screen. Mirrors the smart placement in the legacy
    // EmptyStateTipTour (empty_state_tip_tour.dart:299-306). Without this,
    // a target near the bottom shows a long bubble cramped between the target
    // and the bottom safe area, often partially off-screen.
    final targetCenterY = spotlightRect.center.dy;
    final shouldFlipAbove = targetCenterY > screenHeight * 0.55;
    if (shouldFlipAbove && spaceAbove >= cardHeight + gap) {
      return spotlightRect.top - spotlightPadding - gap - cardHeight;
    }
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

    if (!tourState.isVisible) {
      if (_wasVisible) {
        _wasVisible = false;
        _fadeController.reset();
      }
      return const SizedBox.shrink();
    }

    // Trigger fade-in when tour first becomes visible
    if (!_wasVisible) {
      _wasVisible = true;
      _fadeController.forward();
    }

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

    // Oversized-target rule (mirrors EmptyStateTipTour): a target that
    // spans most of the usable height has no meaningful spotlight — a
    // near-full-screen cutout just dims thin margins and leaves nowhere
    // to place the card. Treat it as targetless: even full dim, no
    // cutout, card bottom-anchored.
    final mqPadding = MediaQuery.of(context).padding;
    final usableHeight =
        screenSize.height - mqPadding.top - mqPadding.bottom;
    final isOversized = isTargetFound &&
        usableHeight > 0 &&
        targetRect.height >= usableHeight * 0.7;
    // Draw a real spotlight cutout + adjacent card only for a found,
    // reasonably-sized target.
    final spotlightActive = isTargetFound && !isOversized;

    // Check if target is off-screen (above or below visible area)
    final isOffScreen = isTargetFound &&
        (targetRect.bottom < 0 || targetRect.top > screenSize.height);

    // Use previous rect as animation start, then update for next step
    final beginRect = _previousRect == Rect.zero ? targetRect : _previousRect;
    final endRect = spotlightActive ? targetRect : Rect.zero;

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
          // Delay before retry — target widget may still be loading data
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) setState(() {});
          });
        } else {
          debugPrint(
              '⚠️ [AppTour] step "${step.id}" target not found after '
              '$_maxRetries retries — showing card without a spotlight');
        }
      }
    });

    // Target found but scrolled off-screen → render nothing for this frame;
    // the post-frame callback above scrolls it in and rebuilds. (Transient.)
    if (isOffScreen) {
      return const SizedBox.shrink();
    }
    // NOTE: when the target is genuinely not found we do NOT bail out — the
    // build continues and renders the card CENTERED with a plain full dim
    // (no cutout). Bailing with SizedBox.shrink() made the whole tour
    // silently vanish the instant a step pointed at a missing widget — the
    // user-reported "hit Next and it closes". The retry above still runs;
    // if the target appears later the spotlight upgrades in on the next
    // rebuild.

    const spotlightPadding = 10.0;
    // Generous estimate: longer descriptions (e.g. the Home / Nutrition nav
    // steps) wrap to 3-4 lines, pushing the card past the old 180px guess.
    // Under-estimating placed the card too low when anchored `above`, which
    // pushed the progress dots + Next button off the bottom of the screen —
    // the user-reported "no Next button on Home/Nutrition" symptom. The card
    // itself now hard-caps its own height (see AppTourTooltipCard.maxHeight)
    // and scrolls the description if it would exceed this estimate, so the
    // dots + Next/Got it footer are ALWAYS rendered on every step.
    const estimatedCardHeight = 260.0;
    final safeBottom = mqPadding.bottom;
    final safeTop = mqPadding.top;

    final double rawTop;
    if (spotlightActive) {
      rawTop = _tooltipTop(
        spotlightRect: targetRect,
        cardHeight: estimatedCardHeight,
        screenHeight: screenSize.height,
        position: step.position,
        spotlightPadding: spotlightPadding,
      );
    } else if (isOversized) {
      // Oversized target → bottom-anchor the card (the clamp below keeps
      // it fully on-screen above the bottom safe area).
      rawTop = screenSize.height - estimatedCardHeight - safeBottom - 24.0;
    } else {
      // Target genuinely not found → centered card with a plain full dim.
      rawTop = (screenSize.height - estimatedCardHeight) / 2;
    }
    // Hard clamp so the card (and its dots + Next button footer) is always
    // fully on-screen regardless of how tall the description renders.
    final maxTop =
        screenSize.height - estimatedCardHeight - safeBottom - 24.0;
    final tooltipTop = rawTop.clamp(24.0, maxTop > 24.0 ? maxTop : 24.0);

    final cardWidth = (screenSize.width - 48).clamp(0.0, 360.0);
    final tooltipLeft = ((screenSize.width - cardWidth) / 2).clamp(24.0, double.infinity);
    // Hard ceiling for the card: never taller than the gap between the top
    // safe area and the bottom safe area (minus breathing room). The card
    // scrolls its description internally if the content would exceed this,
    // guaranteeing the dots + Next footer stay visible on every step/tab.
    final cardMaxHeight =
        (screenSize.height - safeTop - safeBottom - 48.0)
            .clamp(200.0, double.infinity);

    return Positioned.fill(
      child: FadeTransition(
        opacity: _fadeAnimation,
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
                  // The scrim dims the FULL screen — leaving a bottom
                  // strip undimmed produced an ugly grey->white band
                  // behind the floating bars during the tour. The nav bar
                  // renders on top anyway; a cutout still punches through
                  // for steps that spotlight a nav item.
                  // `Size.infinite` so the painter covers the full
                  // Positioned.fill canvas. CustomPaint without an
                  // explicit size or child renders at zero size — which
                  // matched the user-reported "tooltip card with no
                  // dim/cutout visible" symptom on Discover.
                  if (hasGradient) {
                    return AnimatedBuilder(
                      animation: _gradientController,
                      builder: (_, __) => CustomPaint(
                        size: Size.infinite,
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
                    size: Size.infinite,
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
                  maxHeight: cardMaxHeight,
                  onNext: () => controller.next(),
                  onPrev: tourState.currentStep > 0 ? () => controller.prev() : null,
                  onSkip: () => controller.dismiss(),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
