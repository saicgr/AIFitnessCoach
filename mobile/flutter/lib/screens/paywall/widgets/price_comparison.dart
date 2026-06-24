import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
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
class PaywallPriceComparison extends StatefulWidget {
  final ThemeColors colors;

  const PaywallPriceComparison({super.key, required this.colors});

  @override
  State<PaywallPriceComparison> createState() => _PaywallPriceComparisonState();
}

class _PaywallPriceComparisonState extends State<PaywallPriceComparison> {
  static const Color _accent = AppColors.orange;

  bool _yearly = false;

  // name, what it does, monthly, yearly (US 2026 list prices).
  static const _rivals = <_Rival>[
    // AI-coach rivals first — the most on-message for "your coach can do".
    _Rival('Gravl', 'AI workouts', 14.99, 69.99),
    _Rival('Google Health', 'AI coach', 9.99, 99.00),
    _Rival('Bevel', 'longevity', 14.99, 99.99),
    _Rival('MyFitnessPal', 'nutrition', 19.99, 79.99),
    _Rival('Fitbod', 'workouts', 15.99, 95.99),
    _Rival('Noom', 'coaching', 17.42, 209.00),
    _Rival('MacroFactor', 'macros', 11.99, 71.99),
    _Rival('Cronometer', 'micros', 10.99, 59.88),
    _Rival('Zero', 'fasting', 9.99, 69.99),
    _Rival('WaterMinder', 'hydration', 4.99, 4.99),
  ];

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
        border: const Border(top: BorderSide(color: _accent, width: 1)),
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
              color: _accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: _accent.withValues(alpha: 0.22)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.workspace_premium_outlined,
                  size: 16,
                  color: _accent,
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
                      children: const [
                        TextSpan(text: 'Online 1-on-1 coaching like '),
                        TextSpan(
                          text: 'Future',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        TextSpan(text: ' runs '),
                        TextSpan(
                          text: '\$149–199/mo',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: _accent,
                          ),
                        ),
                        TextSpan(text: '; an in-person trainer is '),
                        TextSpan(
                          text: '\$60–100+/session',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: _accent,
                          ),
                        ),
                        TextSpan(text: '. You get a coach + all of this:'),
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
              const Expanded(
                child: Text(
                  'WHAT APPS LIKE THESE CHARGE',
                  style: TextStyle(
                    fontFamily: 'Barlow Condensed',
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 1.6,
                    color: _accent,
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
          // marquee above sits in an Expanded that shrinks to absorb growth, so
          // expanding the full lineup doesn't overflow the page.
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: Column(
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
              style: const TextStyle(
                fontFamily: 'Barlow Condensed',
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
                letterSpacing: 1,
                color: _accent,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              _expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: _accent,
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
          color: on ? _accent : Colors.transparent,
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
                  color: isZealova ? _accent : colors.textMuted,
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
                      ? _accent
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
                  style: const TextStyle(
                    fontFamily: 'Anton',
                    fontSize: 17,
                    color: _accent,
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
