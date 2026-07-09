import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/providers/window_mode_provider.dart';
import '../../core/services/posthog_service.dart';
import '../onboarding/widgets/foldable_quiz_scaffold.dart';
import '../onboarding/pre_auth_quiz_screen.dart';
import 'widgets/price_comparison.dart';

import '../../l10n/generated/app_localizations.dart';

/// Signature v2 single orange accent — used for the headline + CTA styling.
const Color _kSigAccent = Color(0xFFF97316);

/// Goal-mirrored headline line 2 — reflecting the user's own quiz goal back at
/// them converts far better than a generic capability line (2026 paywall
/// research: surface the goal from step 1 directly in the paywall headline).
String _goalHeadline(String? goal) {
  switch (goal) {
    case 'lose_weight':
      return 'TO LOSE THE WEIGHT';
    case 'increase_strength':
      return 'TO GET STRONGER';
    case 'improve_endurance':
      return 'TO GO THE DISTANCE';
    case 'stay_active':
      return 'TO STAY CONSISTENT';
    case 'athletic_performance':
      return 'TO PERFORM AT YOUR PEAK';
    case 'build_muscle':
      return 'TO BUILD MUSCLE';
    default:
      return 'TO REACH YOUR GOAL';
  }
}

/// Paywall Screen 1: Feature Highlights
/// Shows the key features users get with premium
class PaywallFeaturesScreen extends ConsumerStatefulWidget {
  const PaywallFeaturesScreen({super.key});

  @override
  ConsumerState<PaywallFeaturesScreen> createState() =>
      _PaywallFeaturesScreenState();
}

class _PaywallFeaturesScreenState extends ConsumerState<PaywallFeaturesScreen> {
  @override
  void initState() {
    super.initState();
    // Track the screen view (the old build-time microtask fired on every
    // rebuild). The A/B-experiment load was dropped here once the single-screen
    // grid removed the only experiment-gated element (the credibility strip).
    Future.microtask(() {
      ref
          .read(posthogServiceProvider)
          .capture(eventName: 'paywall_features_viewed');
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.colors(context);
    final windowState = ref.watch(windowModeProvider);
    final isFoldable = FoldableQuizScaffold.shouldUseFoldableLayout(
      windowState,
    );

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: FoldableQuizScaffold(
          headerTitle: '',
          headerExtra: _buildPremiumSummary(colors),
          // Headline + auto-scrolling feature MARQUEE + price anchor. The
          // marquee occupies the Expanded middle region. Flex-when-room,
          // scroll-when-needed: ConstrainedBox(minHeight) + IntrinsicHeight
          // keeps this pixel-identical on phones where everything fits (the
          // page doesn't scroll; the marquee absorbs the slack), while short
          // phones — or expanding the full price lineup — scroll the content
          // instead of overflowing the bottom. The CTA lives in the scaffold's
          // pinned button slot either way.
          content: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: LayoutBuilder(
              builder: (context, viewport) => SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: viewport.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                // Show title inline only on phone
                if (!isFoldable) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: colors.accentGradient,
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/app_icon.png',
                        width: 54,
                        height: 54,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.fitness_center,
                          size: 28,
                          color: colors.accentContrast,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'EVERYTHING YOU NEED',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Anton',
                      fontSize: 24,
                      height: 1.05,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    _goalHeadline(ref.watch(preAuthQuizProvider).goal),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Anton',
                      fontSize: 24,
                      height: 1.05,
                      color: _kSigAccent,
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                if (isFoldable) const SizedBox(height: 8),

                // Premium auto-scrolling FEATURE MARQUEE — two rows of chips
                // gliding in OPPOSITE directions, seamless infinite loop, with a
                // left+right edge fade for the "infinite rail" feel. Occupies the
                // flexible middle region; only the chips animate horizontally —
                // the page itself never scrolls.
                // The two marquee rows have a fixed min height (38 + 12 + 38 =
                // 88px). On short viewports the phone title block + price
                // comparison squeeze this Expanded below 88px, which used to
                // overflow (RenderFlex +19px). Scale the block DOWN to the
                // available height instead — a no-op at normal heights (scale
                // 1.0, pixel-identical to before), graceful uniform shrink when
                // tight. The SizedBox pins the marquees' width (otherwise
                // unbounded inside FittedBox's intrinsic-size measure) to the
                // available content width.
                        // NOTE: width is pinned from the OUTER LayoutBuilder
                        // (viewport) — a LayoutBuilder here would crash under
                        // IntrinsicHeight (no intrinsic-dimension support).
                        Expanded(
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: SizedBox(
                                width: viewport.maxWidth,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _Marquee(
                                      chips: _marqueeRowTop,
                                      // ~13 px/s — slow, calm, premium glide.
                                      pixelsPerSecond: 13,
                                      reverse: false,
                                      colors: colors,
                                    ),
                                    const SizedBox(height: 12),
                                    _Marquee(
                                      chips: _marqueeRowBottom,
                                      // Slightly different speed so the two
                                      // rows never sync into a visible "block"
                                      // moving together.
                                      pixelsPerSecond: 16,
                                      reverse: true,
                                      colors: colors,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── Signature v2: PRICE anchor vs the single-purpose
                        // apps a user would otherwise stack (MyFitnessPal /
                        // Fitbod / Gravl…) ──
                        PaywallPriceComparison(colors: colors),

                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          button: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                // Straight to pricing: the standalone /paywall-timeline screen
                // duplicated the trial timeline the pricing offer page already
                // shows (Today / In 5 days / In 7 days) — users saw the same
                // content twice in a row.
                onPressed: () => context.push('/paywall-pricing'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kSigAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                // Explicit forward CTA — users previously couldn't tell how to
                // proceed, so this reads "CONTINUE" rather than "Learn more".
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'CONTINUE',
                      style: TextStyle(
                        fontFamily: 'Barlow Condensed',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumSummary(ThemeColors colors) {
    final categories = [
      (
        icon: Icons.fitness_center,
        label: AppLocalizations.of(context).paywallFeaturesAiWorkouts,
        count: AppLocalizations.of(context).paywallFeatures14Features,
      ),
      (
        icon: Icons.restaurant_rounded,
        label: AppLocalizations.of(context).settingsNutritionSection,
        count: AppLocalizations.of(context).paywallFeatures3Tools,
      ),
      (
        icon: Icons.healing_outlined,
        label: AppLocalizations.of(context).paywallFeaturesSafety,
        count: AppLocalizations.of(context).paywallFeaturesInjuryAware,
      ),
      (
        icon: Icons.trending_up,
        label: AppLocalizations.of(context).navProgress,
        count: AppLocalizations.of(context).paywallFeatures52Skills,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Centered app icon
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: colors.accentGradient,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/app_icon.png',
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.fitness_center,
                  size: 32,
                  color: colors.accentContrast,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Title — goal-mirrored (reflects the user's quiz goal).
        Text(
          'EVERYTHING YOU NEED',
          style: TextStyle(
            fontFamily: 'Anton',
            fontSize: 28,
            height: 1.05,
            color: colors.textPrimary,
          ),
        ),
        Text(
          _goalHeadline(ref.watch(preAuthQuizProvider).goal),
          style: const TextStyle(
            fontFamily: 'Anton',
            fontSize: 28,
            height: 1.05,
            color: _kSigAccent,
          ),
        ),
        const SizedBox(height: 20),

        // Feature category cards
        ...categories.map(
          (cat) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colors.accent.withValues(alpha: 0.12),
                ),
              ),
              child: Row(
                children: [
                  Icon(cat.icon, size: 18, color: colors.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      cat.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    cat.count,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Trial callout
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colors.accent.withValues(alpha: 0.1),
                colors.accent.withValues(alpha: 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.accent.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.card_giftcard, size: 18, color: colors.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).paywallPricing7DayFreeTrial2,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A single feature for the marquee: small Material icon + short label.
typedef _Feat = (IconData, String);

// Breadth across the two rows — core + deep capabilities. Split so each row
// reads as a distinct mix rather than core-on-top / deep-on-bottom.
// Every chip uses a clean Material monoline glyph (Icons.*) — NEVER an emoji
// character (emojis read as AI slop). The breadth (~15 per row) is the point:
// the rail should feel like it never ends.
// Both rows LEAD with the differentiators competitors lack (form check, menu
// scan, injury-safe, AI personas, recipe import) — the moat is seen first,
// before the marquee scrolls. Table-stakes (barcode, wearable sync, plate calc)
// trail. No "7-day free trial" chip — that's an offer (covered by the timeline +
// pricing), not a feature.
const List<_Feat> _marqueeRowTop = [
  (Icons.auto_fix_high, 'AI workouts'),
  (Icons.videocam_outlined, 'AI form check'),
  (Icons.menu_book_outlined, 'Menu scan'),
  (Icons.chat_bubble_outline, 'AI coach chat'),
  (Icons.receipt_long_outlined, 'Recipe import'),
  (Icons.camera_alt_outlined, 'Photo food logging'),
  (Icons.movie_outlined, '1,722 exercises · HD video demos'),
  (Icons.calculate_outlined, 'Adaptive TDEE engine'),
  (Icons.emoji_events_outlined, '52+ skill progressions'),
  (Icons.view_week_outlined, 'Superset builder'),
  (Icons.local_drink_outlined, 'Fasting + water'),
  (Icons.mic_none_rounded, 'Voice logging'),
  (Icons.qr_code_scanner, 'Barcode scan'),
  (Icons.local_offer_outlined, 'Streak freezes'),
  (Icons.event_note_outlined, 'Weekly recap'),
  (Icons.groups_rounded, 'Active community'),
];

const List<_Feat> _marqueeRowBottom = [
  (Icons.healing_outlined, 'Injury-safe plans'),
  (Icons.psychology_outlined, '5 AI coach personas'),
  (Icons.map_outlined, 'Muscle heatmap analysis'),
  (Icons.restaurant_menu, 'Menu ordering'),
  (Icons.handyman_outlined, 'Custom equipment'),
  (Icons.battery_charging_full_rounded, 'Recovery score'),
  (Icons.bar_chart_rounded, 'Muscle balance'),
  (Icons.local_fire_department, 'Hell Mode'),
  (Icons.directions_run_rounded, 'Rest-day cardio'),
  (Icons.watch_outlined, 'Wearable sync'),
  (Icons.speed_outlined, 'RPE/RIR logging'),
  (Icons.scale_outlined, 'Plate calculator'),
  (Icons.ac_unit_rounded, 'Deload weeks'),
  (Icons.insights_rounded, 'Progress photos & charts'),
  (Icons.tune_rounded, 'Fully customizable'),
];

/// One signature-v2 chip: a small orange icon + UPPERCASE Barlow Condensed
/// label in a rounded surface pill with a top hairline.
class _FeatureChip extends StatelessWidget {
  final _Feat feat;
  final ThemeColors colors;

  const _FeatureChip({required this.feat, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(13),
        // Uniform outline — a NON-uniform Border (accent top + gray sides) plus
        // borderRadius throws "borderRadius can only be given on borders with
        // uniform colors" at paint time. Tint the whole hairline with the
        // accent for the signature-v2 look without the crash.
        border: Border.all(color: _kSigAccent.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(feat.$1, size: 16, color: _kSigAccent),
          const SizedBox(width: 7),
          Text(
            feat.$2.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Barlow Condensed',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// A premium horizontal auto-scrolling marquee row.
///
/// A [Ticker] advances a [ScrollController] at [pixelsPerSecond]; the chip row
/// is rendered twice back-to-back, and when the offset passes one copy's width
/// it subtracts that width — giving a seamless infinite loop with no visible
/// seam or jump. [reverse] runs the row right-to-left. A horizontal edge-fade
/// [ShaderMask] gives the "infinite rail" look.
class _Marquee extends StatefulWidget {
  final List<_Feat> chips;
  final double pixelsPerSecond;
  final bool reverse;
  final ThemeColors colors;

  const _Marquee({
    required this.chips,
    required this.pixelsPerSecond,
    required this.reverse,
    required this.colors,
  });

  @override
  State<_Marquee> createState() => _MarqueeState();
}

class _MarqueeState extends State<_Marquee>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ScrollController _controller = ScrollController();
  Duration _lastTick = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    // Start the ticker after the first frame so the controller is attached and
    // maxScrollExtent is known.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Reverse rows start one copy in so they can scroll "backwards" toward
      // zero and wrap forward seamlessly.
      if (widget.reverse && _controller.hasClients) {
        _controller.jumpTo(_oneCopyWidth());
      }
      _ticker.start();
    });
  }

  /// Width of ONE chip-row copy. The content is two identical copies, so the
  /// total content width is `maxScrollExtent + viewportDimension`; half of that
  /// is exactly one copy. (Using `maxScrollExtent / 2` would be short by half a
  /// viewport and leave a visible seam at the wrap.)
  double _oneCopyWidth() {
    final p = _controller.position;
    return (p.maxScrollExtent + p.viewportDimension) / 2;
  }

  void _onTick(Duration elapsed) {
    final dtMs = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    if (!_controller.hasClients) return;
    final oneCopy = _oneCopyWidth();
    if (oneCopy <= 0) return;

    final delta = widget.pixelsPerSecond * dtMs;
    var next = widget.reverse
        ? _controller.offset - delta
        : _controller.offset + delta;

    // Seamless wrap: keep the offset within [0, oneCopy) so copy-1 and copy-2
    // are visually interchangeable.
    if (next >= oneCopy) {
      next -= oneCopy;
    } else if (next < 0) {
      next += oneCopy;
    }
    _controller.jumpTo(next);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The chip row, rendered twice for the seamless loop.
    Widget rowCopy() => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final f in widget.chips) ...[
          _FeatureChip(feat: f, colors: widget.colors),
          const SizedBox(width: 8),
        ],
      ],
    );

    // Edge fade: mask opaque in the middle, transparent at the L/R edges, so
    // the chips dissolve into the background for the "infinite rail" feel.
    return ShaderMask(
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          Colors.black,
          Colors.black,
          Colors.transparent,
        ],
        stops: [0.0, 0.08, 0.92, 1.0],
      ).createShader(rect),
      blendMode: BlendMode.dstIn,
      child: SizedBox(
        height: 38,
        child: ListView(
          controller: _controller,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          children: [rowCopy(), rowCopy()],
        ),
      ),
    );
  }
}
