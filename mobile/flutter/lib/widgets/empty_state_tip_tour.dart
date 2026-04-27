import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_colors.dart';

/// Inspired by GymBeat's pervasive lightbulb tooltips on every empty state.
///
/// Drop [EmptyStateTipTour] anywhere a screen has a passive empty state and it
/// will overlay a lightbulb card with prev / next / got-it / skip + step dots.
/// State is persisted per [tourId] in `SharedPreferences` under the key
/// `has_seen_empty_tour_<tourId>`. The "Reset Tips" setting clears this prefix.
///
/// Usage:
/// ```dart
/// Stack(children: [
///   _MyEmptyStateBody(),
///   EmptyStateTipTour(
///     tourId: 'discover_v1',
///     tips: const [
///       EmptyStateTip(icon: Icons.bolt_outlined, title: 'Find your peers', body: 'Browse rising stars near you.'),
///       EmptyStateTip(icon: Icons.bar_chart_rounded, title: 'Compare ranks', body: 'Tap any user to see how you stack up.'),
///     ],
///   ),
/// ]);
/// ```
class EmptyStateTip {
  final IconData icon;
  final String title;
  final String body;

  /// Optional spotlight target. When provided, the tour dims the rest of
  /// the screen and draws a glowing ring around the widget attached to
  /// this key, so the tip text actually points at something. The target
  /// widget keeps receiving touches (the dim layer is non-blocking outside
  /// the tip card).
  final GlobalKey? targetKey;

  /// Padding around the spotlight cutout. Larger values = more breathing
  /// room around the highlighted widget.
  final EdgeInsets targetPadding;

  /// Corner radius of the spotlight cutout. Use Infinity for a circle.
  final double targetRadius;

  const EmptyStateTip({
    required this.icon,
    required this.title,
    required this.body,
    this.targetKey,
    this.targetPadding = const EdgeInsets.all(8),
    this.targetRadius = 18,
  });
}

class EmptyStateTipTour extends StatefulWidget {
  final String tourId;
  final List<EmptyStateTip> tips;

  /// When true the tour is rendered ignoring any persisted "has_seen" flag.
  /// Used by Reset-Tips flows that re-open the screen.
  final bool forceShow;

  /// Anchor the card. Defaults to bottom-center.
  final Alignment alignment;

  /// Bottom padding (only matters for default alignment).
  final EdgeInsetsGeometry padding;

  const EmptyStateTipTour({
    super.key,
    required this.tourId,
    required this.tips,
    this.forceShow = false,
    this.alignment = Alignment.bottomCenter,
    this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 24),
  });

  /// Clear the persisted dismissal flag for one specific tour.
  static Future<void> reset(String tourId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey(tourId));
  }

  /// Clear ALL empty-state tip-tour dismissals. Used by the Reset Tips setting.
  /// Returns the number of keys cleared.
  static Future<int> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where(
          (k) => k.startsWith(_storagePrefix),
        );
    var count = 0;
    for (final k in keys) {
      await prefs.remove(k);
      count++;
    }
    return count;
  }

  static const _storagePrefix = 'has_seen_empty_tour_';
  static String _storageKey(String tourId) => '$_storagePrefix$tourId';

  @override
  State<EmptyStateTipTour> createState() => _EmptyStateTipTourState();
}

class _EmptyStateTipTourState extends State<EmptyStateTipTour> {
  bool _ready = false;
  bool _visible = false;
  int _step = 0;
  bool _disposed = false;

  /// Live target rect for the current step, in this tour widget's local
  /// coordinate space. Re-resolved every post-frame so the spotlight
  /// tracks the highlighted widget through scrolls, sheet drags,
  /// keyboard insets, animated reflows, etc.
  ///
  /// We use a self-rescheduling `addPostFrameCallback` loop instead of a
  /// Ticker because tear-off callbacks captured at `initState` time
  /// don't always rebind to the new method body across Flutter Hot
  /// Reload — the loop re-looks-up `_pumpTargetRect` on every frame so
  /// edits land without a Hot Restart.
  final ValueNotifier<Rect?> _targetRect = ValueNotifier<Rect?>(null);

  @override
  void initState() {
    super.initState();
    _checkSeen();
    _scheduleNextPump();
  }

  @override
  void dispose() {
    _disposed = true;
    _targetRect.dispose();
    super.dispose();
  }

  void _scheduleNextPump() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed) return;
      _pumpTargetRect();
      _scheduleNextPump();
    });
  }

  void _pumpTargetRect() {
    if (!_ready || !_visible || widget.tips.isEmpty) {
      if (_targetRect.value != null) _targetRect.value = null;
      return;
    }
    if (_step >= widget.tips.length) return;
    final tip = widget.tips[_step];
    final next = _resolveTargetRect(tip);
    // Rect's == is value-based — only notify listeners on real movement.
    if (next != _targetRect.value) {
      _targetRect.value = next;
    }
  }

  Future<void> _checkSeen() async {
    if (widget.forceShow) {
      if (!mounted) return;
      setState(() {
        _visible = true;
        _ready = true;
      });
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(EmptyStateTipTour._storageKey(widget.tourId)) ?? false;
    if (!mounted) return;
    setState(() {
      _visible = !seen;
      _ready = true;
    });
  }

  Future<void> _dismiss() async {
    // Persist FIRST, hide second — if the user backgrounds the app
    // between these two steps we'd rather have the flag saved and the
    // UI still showing (next launch will hide it) than the inverse.
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(
          EmptyStateTipTour._storageKey(widget.tourId), true);
    } catch (_) {
      // Storage failure shouldn't trap the user inside the tour.
    }
    if (!mounted) return;
    setState(() => _visible = false);
  }

  void _next() {
    if (_step < widget.tips.length - 1) {
      setState(() => _step++);
    } else {
      _dismiss();
    }
  }

  void _prev() {
    if (_step > 0) setState(() => _step--);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready || !_visible || widget.tips.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tip = widget.tips[_step];
    final isLast = _step == widget.tips.length - 1;

    final card = Padding(
      padding: widget.padding,
      child: _TipCard(
        tip: tip,
        step: _step + 1,
        total: widget.tips.length,
        isLast: isLast,
        isDark: isDark,
        onNext: _next,
        onPrev: _step > 0 ? _prev : null,
        onClose: _dismiss,
      ),
    );

    // No target → simple aligned card (legacy behaviour).
    if (tip.targetKey == null) {
      return Align(alignment: widget.alignment, child: card);
    }

    // Per-frame ValueListenableBuilder: the ticker keeps `_targetRect` in
    // sync with the highlighted widget's actual on-screen position, so
    // the spotlight + card auto-track scrolls, sheet drags, keyboard
    // pushes, animated reflows, etc. without the parent doing anything.
    return ValueListenableBuilder<Rect?>(
      valueListenable: _targetRect,
      builder: (context, rect, _) {
        // Card placement: if we have a rect, flip the card to the
        // opposite half so it never covers the spotlight; otherwise
        // honour the configured alignment.
        final screenSize = MediaQuery.of(context).size;
        final placeBelow =
            rect == null ? true : rect.center.dy < screenSize.height / 2;
        final cardAlignment =
            placeBelow ? Alignment.bottomCenter : Alignment.topCenter;
        final cardPadding = placeBelow
            ? const EdgeInsets.fromLTRB(16, 0, 16, 24)
            : EdgeInsets.fromLTRB(
                16,
                MediaQuery.of(context).padding.top + 16,
                16,
                0,
              );

        return Stack(
          children: [
            // Tap-anywhere-to-dismiss on the dim layer. The rect's
            // cutout area visually invites the user to interact with
            // the highlighted control, but if they instead tap the
            // dimmed region we treat that as "I get it, skip the
            // tour" and persist the seen flag immediately.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _dismiss,
                child: CustomPaint(
                  painter: _SpotlightPainter(
                    target: rect,
                    padding: tip.targetPadding,
                    radius: tip.targetRadius,
                    accent: isDark ? AppColors.cyan : AppColorsLight.cyan,
                  ),
                ),
              ),
            ),
            // Card sits above the dim and absorbs taps — its own
            // Next / Got it / Close buttons drive navigation.
            Align(
              alignment: cardAlignment,
              child: Padding(padding: cardPadding, child: card),
            ),
          ],
        );
      },
    );
  }

  /// Resolve the rect of the tip's target widget *in this tour widget's
  /// own coordinate space*. The spotlight painter sits inside the same
  /// `Positioned.fill` as this state, so using screen-global coordinates
  /// drew the cutout offset by however far the host (e.g. a bottom
  /// sheet) sat from the top of the device — the user saw the cutout
  /// drift downward onto unrelated widgets.
  Rect? _resolveTargetRect(EmptyStateTip tip) {
    final key = tip.targetKey;
    if (key == null) return null;
    final ctx = key.currentContext;
    if (ctx == null) {
      // Target isn't laid out yet — schedule a rebuild so the spotlight
      // appears as soon as the frame settles.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
      return null;
    }
    final targetBox = ctx.findRenderObject();
    final tourBox = context.findRenderObject();
    if (targetBox is! RenderBox || !targetBox.hasSize) return null;
    if (tourBox is! RenderBox || !tourBox.hasSize) return null;
    // Convert via screen-global coords. The target and the tour are
    // typically sibling branches of an outer Stack (e.g. GlassSheet
    // body + Positioned.fill tour overlay), so neither is an ancestor
    // of the other — passing one as `ancestor:` to localToGlobal
    // would assert. Compute both in screen space, then subtract to
    // land in the tour's local coordinate system, which is what the
    // spotlight painter (also Positioned.fill inside this state's
    // Stack) paints against.
    final targetTopLeftScreen = targetBox.localToGlobal(Offset.zero);
    final tourTopLeftScreen = tourBox.localToGlobal(Offset.zero);
    final topLeftLocal = targetTopLeftScreen - tourTopLeftScreen;
    return topLeftLocal & targetBox.size;
  }
}

/// Paints a translucent dim layer with a rounded-rect cutout around the
/// target, plus a glowing ring at the cutout edge so the eye snaps to it.
class _SpotlightPainter extends CustomPainter {
  final Rect? target;
  final EdgeInsets padding;
  final double radius;
  final Color accent;

  _SpotlightPainter({
    required this.target,
    required this.padding,
    required this.radius,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // No target rect yet → full-screen dim, no cutout. Keeps the visual
    // contract stable (user sees they're in a guided step) even before
    // layout has resolved the highlighted widget's position.
    if (target == null) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = Colors.black.withValues(alpha: 0.62),
      );
      return;
    }

    final t = target!;
    final hole = Rect.fromLTRB(
      t.left - padding.left,
      t.top - padding.top,
      t.right + padding.right,
      t.bottom + padding.bottom,
    );
    final r = radius.isInfinite
        ? Radius.circular(hole.shortestSide / 2)
        : Radius.circular(radius);

    final overlay = Path()..addRect(Offset.zero & size);
    final cutout = Path()..addRRect(RRect.fromRectAndRadius(hole, r));
    final dimmed = Path.combine(PathOperation.difference, overlay, cutout);

    canvas.drawPath(
      dimmed,
      Paint()..color = Colors.black.withValues(alpha: 0.62),
    );

    // Glow ring
    final ringRect = RRect.fromRectAndRadius(hole, r);
    canvas.drawRRect(
      ringRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = accent.withValues(alpha: 0.95)
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 6),
    );
    canvas.drawRRect(
      ringRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = accent,
    );
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter old) =>
      old.target != target ||
      old.padding != padding ||
      old.radius != radius ||
      old.accent != accent;
}

class _TipCard extends StatelessWidget {
  final EmptyStateTip tip;
  final int step;
  final int total;
  final bool isLast;
  final bool isDark;
  final VoidCallback onNext;
  final VoidCallback? onPrev;
  final VoidCallback onClose;

  const _TipCard({
    required this.tip,
    required this.step,
    required this.total,
    required this.isLast,
    required this.isDark,
    required this.onNext,
    required this.onPrev,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final bg = isDark
        ? Colors.black.withValues(alpha: 0.78)
        : Colors.white.withValues(alpha: 0.94);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.06);
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark
        ? Colors.white.withValues(alpha: 0.65)
        : Colors.black.withValues(alpha: 0.6);

    final width = MediaQuery.of(context).size.width;
    final cardWidth = (width - 32).clamp(0.0, 360.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: cardWidth,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.lightbulb_outline_rounded, color: accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tip.title,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tip.body,
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: Icon(Icons.close_rounded, color: textSecondary, size: 18),
                    splashRadius: 18,
                    constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ...List.generate(total, (i) {
                    final active = i == step - 1;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(right: 4),
                      width: active ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: active ? accent : accent.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                  const Spacer(),
                  if (onPrev != null)
                    _CircleButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: onPrev!,
                      accent: accent,
                    ),
                  if (onPrev != null) const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onNext,
                    child: Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          isLast ? 'Got it' : 'Next',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color accent;

  const _CircleButton({required this.icon, required this.onTap, required this.accent});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: accent, size: 16),
      ),
    );
  }
}
