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

  /// When true, the card-placement logic reserves extra bottom clearance for
  /// the floating main navigation bar (~76pt). Set this on tours that run on
  /// screens hosting the main nav (Discover, leaderboards, home tabs) so a
  /// card placed *below* its spotlight target doesn't slide under the nav.
  /// Leave false for sheet-hosted tours and full-screen modals that have no
  /// main nav bar.
  final bool hasMainNavBar;

  /// Extra bottom clearance (pt) on top of [mainNavClearance], for screens
  /// that float a SECOND control above the main nav — e.g. Discover's
  /// XP/Volume/Streaks board switcher or Nutrition's Daily/Recipes/Patterns
  /// tab pill. Without this the card's safe band extends under that pill and
  /// the card visually collides with it.
  final double extraBottomClearance;

  const EmptyStateTipTour({
    super.key,
    required this.tourId,
    required this.tips,
    this.forceShow = false,
    this.alignment = Alignment.bottomCenter,
    this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 24),
    this.hasMainNavBar = false,
    this.extraBottomClearance = 0,
  });

  /// Height of the floating main navigation bar plus the gap between it and
  /// a tour card placed just above it. Used to pad `bottomSafe` so cards
  /// below their target clear the nav.
  static const double mainNavClearance = 76;

  /// Clear the persisted dismissal flag for one specific tour.
  static Future<void> reset(String tourId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey(tourId));
  }

  /// Mark a tour as seen without showing it. Screens call this when the
  /// user has *demonstrably* figured out the action the tour covers — e.g.
  /// they logged their first meal — so we never nag them with an
  /// onboarding hint they no longer need.
  static Future<void> markSeen(String tourId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_storageKey(tourId), true);
      debugPrint('🎯 [Tour] markSeen($tourId)');
    } catch (e) {
      debugPrint('❌ [Tour] markSeen($tourId) failed: $e');
    }
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

  /// Attached to the tip card so we can read its *actual* laid-out size
  /// every frame. Card height is content-driven (body length, dot count,
  /// theme text scaling) and unknown ahead of layout — without a real
  /// measurement the placement logic can't tell whether a side has room,
  /// which is exactly how the "Log a meal" card ended up clipped under
  /// the status bar. Once measured, the card rect is hard-clamped into
  /// the safe viewport.
  final GlobalKey _cardKey = GlobalKey();

  /// Last measured card size (tour-local space). Null until the first
  /// post-frame measurement lands.
  final ValueNotifier<Size?> _cardSize = ValueNotifier<Size?>(null);

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
    _cardSize.dispose();
    super.dispose();
  }

  /// Scroll the current step's target widget into view so its spotlight
  /// cutout is actually on-screen. Without this, a step whose anchor sits
  /// below the fold (e.g. Discover's Rising Stars under a tall hero card)
  /// showed a card with no visible highlight box.
  void _ensureTargetVisible() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed || _step >= widget.tips.length) return;
      final ctx = widget.tips[_step].targetKey?.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        alignment: 0.3, // target sits ~30% down the viewport
      );
    });
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
      if (_cardSize.value != null) _cardSize.value = null;
      return;
    }
    if (_step >= widget.tips.length) return;
    final tip = widget.tips[_step];
    final next = _resolveTargetRect(tip);
    // Rect's == is value-based — only notify listeners on real movement.
    if (next != _targetRect.value) {
      _targetRect.value = next;
    }
    // Measure the card so the placement logic can clamp it fully into
    // the safe viewport. Size's == is value-based, so this only notifies
    // when the card actually resizes (step change, text reflow).
    final cardCtx = _cardKey.currentContext;
    final cardBox = cardCtx?.findRenderObject();
    if (cardBox is RenderBox && cardBox.hasSize) {
      if (cardBox.size != _cardSize.value) {
        _cardSize.value = cardBox.size;
      }
    }
  }

  Future<void> _checkSeen() async {
    if (widget.forceShow) {
      if (!mounted) return;
      setState(() {
        _visible = true;
        _ready = true;
      });
      _ensureTargetVisible();
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(EmptyStateTipTour._storageKey(widget.tourId)) ?? false;
    if (!mounted) return;
    setState(() {
      _visible = !seen;
      _ready = true;
    });
    if (!seen) _ensureTargetVisible();
    // If the tour just became visible to the user, schedule an auto-mark
    // so any exit path (tab switch, back gesture, tap-to-log via the
    // spotlit target, force-kill) counts as "seen". Without this, only
    // the X button and final-step Next ever persisted dismissal — every
    // other dismissal route re-showed the tour next visit.
    if (!seen && widget.tips.isNotEmpty) {
      _scheduleAutoMarkSeen();
    }
  }

  /// Once the tour has been visible for a beat, write the seen flag so
  /// the user never sees it again — regardless of how they leave the
  /// screen. 1s is long enough to count as a real impression but short
  /// enough that a misnavigation pop within milliseconds doesn't burn
  /// the dismissal flag.
  void _scheduleAutoMarkSeen() {
    Future<void>.delayed(const Duration(seconds: 1), () async {
      if (!mounted || _disposed) return;
      // Don't auto-mark in forceShow mode — Reset Tips path expects the
      // user to see the tour again on the next entry too.
      if (widget.forceShow) return;
      // If the tour was already dismissed via X / final-Next during the
      // 1s window, _visible is false — _markSeenIfShown is a no-op write
      // (already persisted by _dismiss).
      await _markSeenIfShown();
    });
  }

  Future<void> _markSeenIfShown() async {
    final key = EmptyStateTipTour._storageKey(widget.tourId);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, true);
    } catch (e, stack) {
      debugPrint('🎯 [Tour] auto-mark $key FAILED: $e\n$stack');
    }
  }

  Future<void> _dismiss() async {
    // Persist FIRST, hide second — if the user backgrounds the app
    // between these two steps we'd rather have the flag saved and the
    // UI still showing (next launch will hide it) than the inverse.
    final key = EmptyStateTipTour._storageKey(widget.tourId);
    try {
      final prefs = await SharedPreferences.getInstance();
      final ok = await prefs.setBool(key, true);
      debugPrint('🎯 [Tour] Dismissed $key (persisted=$ok)');
    } catch (e, stack) {
      // Don't swallow — if persistence fails we'll keep nagging the user
      // every visit. Log loud so the failure surfaces in dev/QA.
      debugPrint('❌ [Tour] Failed to persist dismiss for $key: $e\n$stack');
    }
    if (!mounted) return;
    setState(() => _visible = false);
  }

  void _next() {
    if (_step < widget.tips.length - 1) {
      setState(() => _step++);
      _ensureTargetVisible();
    } else {
      // Fire-and-forget but propagate any errors via the debugPrint inside.
      // We can't await in this synchronous handler without delaying the
      // tap response, and the dismiss path already updates state on its own.
      // ignore: discarded_futures
      _dismiss();
    }
  }

  void _prev() {
    if (_step > 0) {
      setState(() => _step--);
      _ensureTargetVisible();
    }
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

    // The spotlight-targeted branch needs the card wrapped in a keyed
    // box so it can be measured each frame. Legacy (no target) branch
    // doesn't clamp, so it uses the bare `card`.
    final measuredCard = KeyedSubtree(key: _cardKey, child: card);

    // No target → simple aligned card (legacy behaviour).
    //
    // The tour content is hosted inside a `Positioned.fill` / `Overlay`
    // subtree that has no `Material` ancestor. Without one, every `Text`
    // in `_TipCard` falls back to Flutter's debug "no DefaultTextStyle"
    // rendering — the yellow double-underline. `MaterialType.transparency`
    // restores a Material (hence a `DefaultTextStyle`) ancestor without
    // painting any background, shadow, or ink, so the card keeps its own
    // blurred rounded look untouched.
    if (tip.targetKey == null) {
      return Material(
        type: MaterialType.transparency,
        child: Align(alignment: widget.alignment, child: card),
      );
    }

    // Per-frame ValueListenableBuilder: the ticker keeps `_targetRect` in
    // sync with the highlighted widget's actual on-screen position, so
    // the spotlight + card auto-track scrolls, sheet drags, keyboard
    // pushes, animated reflows, etc. without the parent doing anything.
    return ValueListenableBuilder<Rect?>(
      valueListenable: _targetRect,
      builder: (context, rect, _) {
        return ValueListenableBuilder<Size?>(
          valueListenable: _cardSize,
          builder: (context, cardSize, _) {
            return _buildTargetedTour(context, rect, cardSize, tip, measuredCard);
          },
        );
      },
    );
  }

  /// Builds the spotlight + clamped card for a tip that has a target.
  Widget _buildTargetedTour(
    BuildContext context,
    Rect? rect,
    Size? cardSize,
    EmptyStateTip tip,
    Widget measuredCard,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    {
        final mq = MediaQuery.of(context);
        final screenSize = mq.size;
        // Hard safe-area edges the card must never cross. `topSafe`
        // covers the status bar / notch / Dynamic Island; `bottomSafe`
        // covers the home indicator plus, on nav-hosting screens, the
        // floating main nav bar. A small margin keeps the card off the
        // very pixel edge.
        const edgeMargin = 12.0;
        final topSafe = mq.padding.top + edgeMargin;
        final bottomSafe = mq.padding.bottom +
            edgeMargin +
            (widget.hasMainNavBar ? EmptyStateTipTour.mainNavClearance : 0) +
            widget.extraBottomClearance;
        // Usable vertical band for the card.
        final safeTop = topSafe;
        final safeBottom = screenSize.height - bottomSafe;
        // 16pt gap between spotlight ring and card.
        const gap = 16.0;
        // Horizontal inset of the card from the screen edges.
        const sideInset = 16.0;

        // The card's outer width includes the tour's `padding`; the
        // visible card itself is clamped to 360 inside `_TipCard`. Use
        // the measured size when available, otherwise an estimate so the
        // very first frame still places sensibly.
        final cardH = cardSize?.height ?? 220.0;
        // Never let the card claim more than the safe band — a long tip
        // on a tiny screen (iPhone SE) must still show its X / Next row.
        final maxCardH =
            (safeBottom - safeTop).clamp(80.0, double.infinity);
        final effectiveCardH = cardH.clamp(0.0, maxCardH);

        Widget positionedCard;
        if (rect == null) {
          // No layout yet — fall back to a bottom-anchored card sitting
          // inside the safe band.
          positionedCard = Positioned(
            left: sideInset,
            right: sideInset,
            bottom: bottomSafe,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxCardH),
                child: measuredCard,
              ),
            ),
          );
        } else {
          // Spotlight (cutout) rect including the tip's padding.
          final spotTop = rect.top - tip.targetPadding.top;
          final spotBottom = rect.bottom + tip.targetPadding.bottom;

          // Room on each side BETWEEN the spotlight and the safe edge.
          final spaceBelow = safeBottom - (spotBottom + gap);
          final spaceAbove = (spotTop - gap) - safeTop;

          // Prefer the side that can fully contain the card; if neither
          // can, prefer the side with more room (the card will then be
          // clamped and may overlap the target — acceptable; clipping is
          // not).
          final fitsBelow = spaceBelow >= effectiveCardH;
          final fitsAbove = spaceAbove >= effectiveCardH;
          final bool placeBelow;
          if (fitsBelow && !fitsAbove) {
            placeBelow = true;
          } else if (fitsAbove && !fitsBelow) {
            placeBelow = false;
          } else {
            // Both fit, or neither fits — go with the roomier side.
            placeBelow = spaceBelow >= spaceAbove;
          }

          // Desired top of the card before clamping.
          final desiredTop = placeBelow
              ? spotBottom + gap
              : spotTop - gap - effectiveCardH;

          // Clamp the card fully inside the safe band. If the band is
          // shorter than the card (extreme small screen), top pins to
          // safeTop and the inner SingleChildScrollView in `_TipCard`
          // handles the overflow — every control stays reachable.
          final lowerBound = safeTop;
          final upperBound = (safeBottom - effectiveCardH)
              .clamp(safeTop, double.infinity);
          final clampedTop = desiredTop.clamp(lowerBound, upperBound);

          positionedCard = Positioned(
            left: sideInset,
            right: sideInset,
            top: clampedTop,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxCardH),
                child: measuredCard,
              ),
            ),
          );
        }

        // Wrap the whole spotlight overlay in a transparent Material so
        // every `Text` in `_TipCard` has a `Material` (and thus a
        // `DefaultTextStyle`) ancestor — otherwise the tour, hosted in a
        // bare `Overlay`/`Positioned.fill` subtree, renders all card text
        // with Flutter's debug yellow double-underline.
        // `MaterialType.transparency` adds NO background, shadow, or ink,
        // so the spotlight scrim and the card's blurred rounded styling
        // are visually unchanged.
        return Material(
          type: MaterialType.transparency,
          child: Stack(
          children: [
            // Tap-anywhere-to-dismiss on the dim layer. The rect's
            // cutout area visually invites the user to interact with
            // the highlighted control, but if they instead tap the
            // dimmed region we treat that as "I get it, skip the
            // tour" and persist the seen flag immediately.
            //
            // `CustomPaint` defaults to `Size.zero` when given no child
            // and no `size`, which is why the original implementation
            // could draw the dim/cutout in some layouts and silently
            // render nothing in others (the painter was running but on
            // a zero-size canvas). Forcing `Size.infinite` via the
            // builder makes the painter cover the entire
            // Positioned.fill region so the spotlight always renders.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _dismiss,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return CustomPaint(
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                      painter: _SpotlightPainter(
                        target: rect,
                        padding: tip.targetPadding,
                        radius: tip.targetRadius,
                        accent: isDark ? AppColors.cyan : AppColorsLight.cyan,
                      ),
                    );
                  },
                ),
              ),
            ),
            // Card sits above the dim and absorbs taps — its own
            // Next / Got it / Close buttons drive navigation.
            positionedCard,
          ],
          ),
        );
    }
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
/// target, plus a clean accent ring at the cutout edge so the eye snaps
/// to it.
///
/// IMPORTANT: the scrim is a single, EVEN semi-transparent black — there
/// is intentionally no gradient anywhere. An earlier version drew the
/// ring with `MaskFilter.blur(BlurStyle.outer)`; on the light theme the
/// accent resolves to a dark grey (`AppColorsLight.cyan == 0xFF424242`),
/// so that outer blur smeared a grey halo from the bright cutout into
/// the black dim — reading as an ugly white→grey→black vertical band,
/// and bleeding over the bottom nav bar whenever the target sat low on
/// the screen. The ring is now a crisp stroke with no mask blur.
class _SpotlightPainter extends CustomPainter {
  final Rect? target;
  final EdgeInsets padding;
  final double radius;
  final Color accent;

  /// Single flat scrim alpha — kept as a constant so the "no target" and
  /// "with cutout" branches can never drift apart and produce a seam.
  static const double _scrimAlpha = 0.62;

  _SpotlightPainter({
    required this.target,
    required this.padding,
    required this.radius,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scrimPaint = Paint()
      ..color = Colors.black.withValues(alpha: _scrimAlpha)
      ..isAntiAlias = true;

    // No target rect yet → full-screen even dim, no cutout. Keeps the
    // visual contract stable (user sees they're in a guided step) even
    // before layout has resolved the highlighted widget's position.
    if (target == null) {
      canvas.drawRect(Offset.zero & size, scrimPaint);
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
    final holeRRect = RRect.fromRectAndRadius(hole, r);

    // Even scrim with a clean rounded cutout punched out. `Path.combine`
    // difference yields a hard, gradient-free edge — the highlighted
    // widget shows through at full brightness, everything else (incl.
    // the bottom nav bar) sits under one uniform dim.
    final overlay = Path()..addRect(Offset.zero & size);
    final cutout = Path()..addRRect(holeRRect);
    final dimmed = Path.combine(PathOperation.difference, overlay, cutout);
    canvas.drawPath(dimmed, scrimPaint);

    // Clean accent ring hugging the cutout edge. No `MaskFilter.blur` —
    // a blurred outer halo bleeds the (possibly dark-grey) accent into
    // the scrim and over the nav bar. A crisp 2px stroke + a single
    // low-alpha 4px stroke just inside it gives a subtle glow with a
    // solid, uniform color and no fading band.
    canvas.drawRRect(
      holeRRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..isAntiAlias = true
        ..color = accent.withValues(alpha: 0.22),
    );
    canvas.drawRRect(
      holeRRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..isAntiAlias = true
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
    // Fully opaque — the card sits over the dark tour scrim, so any
    // translucency muddies the fill and hurts text contrast. Glass feel
    // still comes from the BackdropFilter blur + shadow.
    final bg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
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
          // Scrollable so a tall tip (long body wrapping to several lines,
          // many step dots) never overflows when the placement logic has
          // to squeeze the card into a tight slot beside the spotlight.
          child: SingleChildScrollView(
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

/// Mounts an [EmptyStateTipTour] into the ROOT [Overlay] for its lifetime.
///
/// Rendering the tour as a `Positioned.fill` child of a screen places its
/// dim scrim BELOW the main nav bar / floating tab bars (those are drawn by
/// the shell, above the screen) — so the bars and their fade-to-white
/// gradients paint over the scrim, leaving a grey/white band during the
/// tour. Inserting into the root overlay puts the scrim above everything,
/// dimming the whole screen evenly.
///
/// Return an instance of this from a tour's `overlay()` and drop it into
/// the screen's stack — it renders as a zero-size widget and tears the
/// overlay entry down on dispose (i.e. when the user leaves the screen).
class RootOverlayTipTourHost extends StatefulWidget {
  final String tourId;
  final List<EmptyStateTip> tips;
  final bool hasMainNavBar;
  final double extraBottomClearance;

  const RootOverlayTipTourHost({
    super.key,
    required this.tourId,
    required this.tips,
    this.hasMainNavBar = false,
    this.extraBottomClearance = 0,
  });

  @override
  State<RootOverlayTipTourHost> createState() => _RootOverlayTipTourHostState();
}

class _RootOverlayTipTourHostState extends State<RootOverlayTipTourHost> {
  OverlayEntry? _entry;

  @override
  void initState() {
    super.initState();
    final tourId = widget.tourId;
    final tips = widget.tips;
    final hasMainNavBar = widget.hasMainNavBar;
    final extraBottomClearance = widget.extraBottomClearance;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // rootOverlay: true → the app-level Overlay, above the shell route
      // (and thus above the floating nav bar).
      final overlay = Overlay.of(context, rootOverlay: true);
      final entry = OverlayEntry(
        builder: (_) => Positioned.fill(
          child: EmptyStateTipTour(
            tourId: tourId,
            tips: tips,
            hasMainNavBar: hasMainNavBar,
            extraBottomClearance: extraBottomClearance,
          ),
        ),
      );
      _entry = entry;
      overlay.insert(entry);
    });
  }

  @override
  void dispose() {
    _entry?.remove();
    _entry = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
