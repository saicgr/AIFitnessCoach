import 'package:flutter/material.dart';
import '../../../core/theme/theme_colors.dart';

/// Signature-v2 PRICE anchor — a compact mini bar chart with a Monthly/Yearly
/// toggle.
///
/// Honest framing: it does NOT sum these into a fake "$60 stack" (nobody
/// subscribes to all of them). Each bar shows what ONE comprehensive category
/// app charges for ONE job; Zealova is the shortest (cheapest) bar AND does all
/// of it. Bar length ∝ price, so "we're priced under the whole category, for all
/// of it" reads instantly. Prices are published US 2026 tiers (see docs/pricing
/// research): MyFitnessPal $19.99/$79.99, Fitbod $15.99/$95.99, Noom
/// ~$17.42/$209, MacroFactor $11.99/$71.99, Cronometer $10.99/$59.88.
///
/// Cheap single-purpose apps (Cal AI, Lose It, Hevy, recipe apps) are
/// intentionally NOT here — they cost less precisely because they do a sliver,
/// so a "shortest bar" chart can't honestly include them. Their jobs show up in
/// the feature marquee above instead.
///
/// PRICING SOURCE OF TRUTH — verified 2026-08-23 (see `_pricesVerifiedLabel`,
/// shown in-UI so the comparison is visibly dated rather than an unstamped
/// hardcoded claim). Re-verify and bump the date at least quarterly; this
/// repo has been through a competitor trademark dispute before
/// (`TRADEMARK_TAKEDOWN_RESPONSE.md`), so both the price AND the product name
/// need to stay accurate, not just plausible:
///   - Gravl: $10.99/mo, $59.99/yr — gravl.ai pricing page.
///   - Google Health (formerly Fitbit Premium, AI Health Coach added
///     2026-05-19): $9.99/mo, $99/yr — blog.google Health Coach launch post.
///   - Bevel: $5.99/mo, $49.99/yr — help.bevel.health/en/articles/11583937.
///   - MyFitnessPal Premium: $19.99/mo, $79.99/yr — official pricing.
///   - Fitbod: $15.99/mo, $95.99/yr — fitbod.me/faqs.
///   - Noom Weight: $69.99/mo month-to-month, $209/yr (~$17.42/mo
///     equivalent — the MONTHLY column must show the real month-to-month
///     price, not the annual-plan's per-month average).
///   - MacroFactor: $11.99/mo, $71.99/yr.
///   - Cronometer Gold: $10.99/mo, $59.99/yr.
///   - Zero: $9.99/mo, $69.99/yr.
///   - WaterMinder Premium: $2.99/mo, $19.99/yr.
class PaywallPriceComparison extends StatefulWidget {
  final ThemeColors colors;

  const PaywallPriceComparison({super.key, required this.colors});

  @override
  State<PaywallPriceComparison> createState() => _PaywallPriceComparisonState();
}

class _PaywallPriceComparisonState extends State<PaywallPriceComparison> {
  bool _yearly = false;

  // name, what it does, monthly, yearly — see the source-of-truth doc
  // comment above the class for the citation + verification date behind
  // every figure here.
  static const _rivals = <_Rival>[
    // AI-coach rivals first — the most on-message for "your coach can do".
    _Rival('Gravl', 'AI workouts', 10.99, 59.99),
    _Rival('Google Health', 'AI coach', 9.99, 99.00),
    _Rival('Bevel', 'longevity', 5.99, 49.99),
    _Rival('MyFitnessPal', 'nutrition', 19.99, 79.99),
    _Rival('Fitbod', 'workouts', 15.99, 95.99),
    _Rival('Noom', 'coaching', 69.99, 209.00),
    _Rival('MacroFactor', 'macros', 11.99, 71.99),
    _Rival('Cronometer', 'micros', 10.99, 59.99),
    _Rival('Zero', 'fasting', 9.99, 69.99),
    _Rival('WaterMinder', 'hydration', 2.99, 19.99),
  ];

  /// Shown at the foot of the card so the comparison reads as a dated claim
  /// (and an audit trail) rather than an unstamped hardcoded number — see
  /// the source-of-truth doc comment above the class.
  static const String _pricesVerifiedLabel = 'Prices verified Aug 2026';

  /// Collapsed by default — only the top AI-coach rivals show, keeping the
  /// screen non-scrolling. Users can expand to compare every single-job app.
  static const int _collapsedCount = 3;
  bool _expanded = false;
  static const double _zMonthly = 7.99;
  static const double _zYearly = 59.99;

  ThemeColors get colors => widget.colors;

  double _price(_Rival r) => _yearly ? r.yearly : r.monthly;
  double get _zPrice => _yearly ? _zYearly : _zMonthly;

  double get _max {
    var m = _zPrice;
    for (final r in _rivals) {
      final p = _price(r);
      if (p > m) m = p;
    }
    return m;
  }

  static String _fmt(double v) => v == v.roundToDouble()
      ? '\$${v.toStringAsFixed(0)}'
      : '\$${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final max = _max;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border(top: BorderSide(color: colors.accent, width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Premium "ceiling" anchor — a 1-on-1 human coach. Positions Zealova's
          // AI coach as premium VALUE (you'd pay $149–199/mo for a person), not
          // "cheap". Kept as a callout, not a bar (it would dwarf the others).
          Container(
            margin: const EdgeInsets.only(bottom: 11),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: colors.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: colors.accent.withValues(alpha: 0.22)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.workspace_premium_outlined,
                  size: 16,
                  color: colors.accent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.3,
                        color: colors.textSecondary,
                      ),
                      children: [
                        const TextSpan(text: 'Online 1-on-1 coaching like '),
                        const TextSpan(
                          text: 'Future',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const TextSpan(text: ' runs '),
                        TextSpan(
                          text: '\$149–199/mo',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: colors.accent,
                          ),
                        ),
                        const TextSpan(text: '; an in-person trainer is '),
                        TextSpan(
                          text: '\$60–100+/session',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: colors.accent,
                          ),
                        ),
                        const TextSpan(text: '. You get a coach + all of this:'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'WHAT APPS LIKE THESE CHARGE',
                  style: TextStyle(
                    fontFamily: 'Barlow Condensed',
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 1.6,
                    color: colors.accent,
                  ),
                ),
              ),
              _toggle(),
            ],
          ),
          Text(
            'each does one job',
            style: TextStyle(fontSize: 10.5, color: colors.textMuted),
          ),
          const SizedBox(height: 8),
          // Collapsed by default (top AI-coach rivals) → non-scrolling. The
          // page wraps this card in a scroll-when-needed layout, so expanding
          // the full lineup scrolls the page on short phones instead of
          // overflowing.
          //
          // No AnimatedSize here: the parent screen sizes this card through
          // IntrinsicHeight, which queries the CURRENT (target) intrinsic
          // height of this tree — but AnimatedSize lerps its actual render
          // height from the old size over time, so for ~220ms after a toggle
          // the real content was taller/shorter than IntrinsicHeight had
          // already allocated, throwing a RenderFlex overflow mid-animation.
          // Resizing instantly keeps the two in lockstep.
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final r
                  in (_expanded
                      ? _rivals
                      : _rivals.take(_collapsedCount))) ...[
                _bar(
                  name: r.name,
                  note: r.note,
                  price: _fmt(_price(r)),
                  frac: _price(r) / max,
                  isZealova: false,
                ),
                const SizedBox(height: 4),
              ],
            ],
          ),
          _expandToggle(),
          const SizedBox(height: 6),
          _bar(
            name: 'Zealova',
            note: 'all of it',
            price: _fmt(_zPrice),
            frac: _zPrice / max,
            isZealova: true,
          ),
          const SizedBox(height: 7),
          Text(
            'Each app does one job. Zealova does all of them — plus fasting, '
            'hydration, recipe import & more.',
            style: TextStyle(
              fontSize: 10.5,
              height: 1.3,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          // Date-stamps the whole comparison so a stale figure reads as
          // "this was true as of the date shown" rather than an
          // unqualified, permanently-hardcoded claim.
          Text(
            _pricesVerifiedLabel,
            style: TextStyle(fontSize: 9, color: colors.textMuted),
          ),
        ],
      ),
    );
  }

  /// "See all N apps ⌄" / "Show fewer ⌃" — reveals the full single-job lineup.
  Widget _expandToggle() {
    final hidden = _rivals.length - _collapsedCount;
    if (hidden <= 0) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _expanded ? 'Show fewer' : 'See all ${_rivals.length} apps',
              style: TextStyle(
                fontFamily: 'Barlow Condensed',
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
                letterSpacing: 1,
                color: colors.accent,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              _expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: colors.accent,
            ),
          ],
        ),
      ),
    );
  }

  /// Monthly | Yearly segmented pill.
  Widget _toggle() {
    return Container(
      height: 24,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _seg('MO', !_yearly, () => setState(() => _yearly = false)),
          _seg('YR', _yearly, () => setState(() => _yearly = true)),
        ],
      ),
    );
  }

  Widget _seg(String label, bool on, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? colors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Barlow Condensed',
            fontWeight: FontWeight.w800,
            fontSize: 11,
            letterSpacing: 1,
            color: on ? const Color(0xFF160B03) : colors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _bar({
    required String name,
    required String note,
    required String price,
    required double frac,
    required bool isZealova,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.1,
                  fontWeight: isZealova ? FontWeight.w800 : FontWeight.w700,
                  color: isZealova ? colors.textPrimary : colors.textSecondary,
                ),
              ),
              Text(
                note,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 8.5,
                  height: 1.1,
                  color: isZealova ? colors.accent : colors.textMuted,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: frac.clamp(0.1, 1.0),
              child: Container(
                height: 9,
                decoration: BoxDecoration(
                  color: isZealova
                      ? colors.accent
                      : colors.textMuted.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 62,
          child: isZealova
              ? Text(
                  price,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'Anton',
                    fontSize: 17,
                    color: colors.accent,
                  ),
                )
              : Text(
                  price,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textMuted,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: colors.textMuted,
                  ),
                ),
        ),
      ],
    );
  }
}

class _Rival {
  final String name;
  final String note;
  final double monthly;
  final double yearly;
  const _Rival(this.name, this.note, this.monthly, this.yearly);
}
