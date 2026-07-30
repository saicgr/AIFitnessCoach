import 'package:flutter/material.dart';

/// Bottom-edge affordance for an onboarding body that sits above a pinned
/// footer (Continue / HOLD TO COMMIT / Quick start).
///
/// The class of bug this exists to kill: a body whose content is taller than
/// its box, ending in a HARD CUT exactly where the sticky footer begins. The
/// user reads that as "the card is clipped by the button", because nothing on
/// screen says the content continues. Two onboarding screens shipped it
/// (commitment pact, fitness check) and both were reported as broken UI.
///
/// Wrap the scrollable body in this and it paints a short fade plus a chevron
/// at the bottom edge whenever there IS more content below, and nothing at all
/// when the content fits. It never changes layout height, so the footer below
/// it cannot move.
///
/// Usage:
/// ```dart
/// OnboardingScrollEdge(
///   background: scaffoldBackgroundColor,
///   child: SingleChildScrollView(child: ...),
/// )
/// ```
class OnboardingScrollEdge extends StatefulWidget {
  /// The scrollable body. MUST be scrollable (SingleChildScrollView /
  /// ListView / CustomScrollView) — the fade is driven by its scroll metrics.
  final Widget child;

  /// Colour the fade resolves to — normally the screen background, so the
  /// fade reads as the content dissolving rather than a grey band.
  final Color background;

  /// Height of the fade band.
  final double fadeHeight;

  const OnboardingScrollEdge({
    super.key,
    required this.child,
    required this.background,
    this.fadeHeight = 28,
  });

  @override
  State<OnboardingScrollEdge> createState() => _OnboardingScrollEdgeState();
}

class _OnboardingScrollEdgeState extends State<OnboardingScrollEdge> {
  bool _more = false;

  /// Only a VERTICAL scrollable can put content "below the fold". Onboarding
  /// bodies routinely contain horizontal scrollables — the three measurement
  /// rulers on the personalization gate, the equipment carousels — and every
  /// one of them dispatches ScrollNotification / ScrollMetricsNotification
  /// through this listener. Without the axis test a ruler sitting anywhere but
  /// its right-hand end reports `extentAfter > 2`, which painted a bottom fade
  /// and a "more below" chevron on a body that had nothing below it (and made
  /// it flicker away as the user dragged the ruler to its end).
  /// `null` = this notification says nothing about "is there more BELOW"
  /// (it came from a horizontal scrollable) and must be IGNORED, not read as
  /// "no more content" — otherwise dragging a ruler would clear a fade the
  /// vertical body legitimately needs.
  bool? _readMetrics(ScrollMetrics m) {
    if (m.axis != Axis.vertical || !m.hasPixels) return null;
    return m.extentAfter > 2;
  }

  void _update(bool? next) {
    if (next == null || next == _more) return;
    // Metrics arrive during layout/paint; defer so we never setState mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && next != _more) setState(() => _more = next);
    });
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (n) {
        _update(_readMetrics(n.metrics));
        return false;
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          _update(_readMetrics(n.metrics));
          return false;
        },
        child: Stack(
          children: [
            widget.child,
            if (_more)
              PositionedDirectional(
                start: 0,
                end: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: Container(
                    height: widget.fadeHeight,
                    alignment: Alignment.bottomCenter,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          widget.background.withValues(alpha: 0),
                          widget.background,
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.55)
                          : Colors.black.withValues(alpha: 0.45),
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
