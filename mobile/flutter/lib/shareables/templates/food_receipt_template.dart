import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/app_watermark.dart';

/// FoodReceipt — the meal itemized as a thermal till receipt. Each
/// `ShareableFood` is a line item; a dashed rule, a TOTAL, the macro
/// subtotal and a faux barcode follow. Photo-less; works for any log type
/// but reads best for a multi-item meal.
class FoodReceiptTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const FoodReceiptTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  static const Color _paper = Color(0xFFF6F3EA);
  static const Color _ink = Color(0xFF1B1B1A);
  static const String _mono = 'monospace';

  @override
  Widget build(BuildContext context) {
    final aspect = data.aspect;
    final mul = aspect.bodyFontMultiplier;
    final accent = data.accentColor;
    final nutrition = data.nutrition ?? const ShareableNutrition();
    final items = data.foodItems ?? const <ShareableFood>[];
    final visible = items.take(11).toList();
    final overflow = items.length - visible.length;

    return ShareableCanvas(
      aspect: aspect,
      backgroundOverride: [
        Color.lerp(const Color(0xFF0C0D11), accent, 0.12) ??
            const Color(0xFF0C0D11),
        const Color(0xFF050608),
      ],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(34, 48, 34, 32),
        child: Center(
          child: Container(
            decoration: BoxDecoration(
              color: _paper,
              borderRadius: BorderRadius.circular(6),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 40,
                  offset: Offset(0, 18),
                ),
              ],
            ),
            padding: EdgeInsets.fromLTRB(
                28 * mul, 30 * mul, 28 * mul, 26 * mul),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'ZEALOVA KITCHEN',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: _mono,
                    color: _ink,
                    fontSize: 20 * mul,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(height: 4 * mul),
                Text(
                  [
                    if (data.mealLabel?.trim().isNotEmpty ?? false)
                      data.mealLabel!.trim().toUpperCase(),
                    if (data.periodLabel.trim().isNotEmpty) data.periodLabel,
                  ].join('  ·  '),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: _mono,
                    color: _ink.withValues(alpha: 0.6),
                    fontSize: 12 * mul,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 14 * mul),
                _dashed(),
                SizedBox(height: 12 * mul),
                if (visible.isEmpty)
                  _line(data.title, nutrition.calories, mul, bold: true)
                else
                  for (final f in visible)
                    Padding(
                      padding: EdgeInsets.only(bottom: 7 * mul),
                      child: _line(
                        f.amount?.trim().isNotEmpty ?? false
                            ? '${f.name}  ${f.amount!.trim()}'
                            : f.name,
                        f.calories,
                        mul,
                      ),
                    ),
                if (overflow > 0)
                  Padding(
                    padding: EdgeInsets.only(top: 2 * mul),
                    child: Text(
                      '... and $overflow more',
                      style: TextStyle(
                        fontFamily: _mono,
                        color: _ink.withValues(alpha: 0.55),
                        fontSize: 12 * mul,
                      ),
                    ),
                  ),
                SizedBox(height: 12 * mul),
                _dashed(),
                SizedBox(height: 12 * mul),
                _line('TOTAL', nutrition.calories, mul,
                    bold: true, suffix: ' kcal'),
                SizedBox(height: 10 * mul),
                Text(
                  // "—" for a genuinely-unknown macro, never a fabricated "0g".
                  'P ${shareableMacroGrams(nutrition.proteinG)}    '
                  'C ${shareableMacroGrams(nutrition.carbsG)}    '
                  'F ${shareableMacroGrams(nutrition.fatG)}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: _mono,
                    color: _ink.withValues(alpha: 0.75),
                    fontSize: 14 * mul,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                if (data.healthScore != null) ...[
                  SizedBox(height: 8 * mul),
                  Text(
                    'HEALTH SCORE  ${data.healthScore} / 10',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: _mono,
                      color: _ink.withValues(alpha: 0.6),
                      fontSize: 12 * mul,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                SizedBox(height: 16 * mul),
                _barcode(mul),
                SizedBox(height: 8 * mul),
                Text(
                  'FUEL LOGGED  ·  THANK YOU',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: _mono,
                    color: _ink.withValues(alpha: 0.6),
                    fontSize: 11 * mul,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
                if (showWatermark) ...[
                  SizedBox(height: 14 * mul),
                  Center(
                    child: AppWatermark(
                      textColor: _ink,
                      fontSize: 12 * mul,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _line(String name, int kcal, double mul,
      {bool bold = false, String suffix = ''}) {
    final style = TextStyle(
      fontFamily: _mono,
      color: _ink,
      fontSize: (bold ? 15 : 13.5) * mul,
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
        SizedBox(width: 10 * mul),
        Text(kcal > 0 ? '$kcal$suffix' : '—', style: style),
      ],
    );
  }

  Widget _dashed() {
    return LayoutBuilder(
      builder: (context, c) {
        final count = (c.maxWidth / 9).floor().clamp(1, 200);
        return Row(
          children: List.generate(
            count,
            (_) => Container(
              width: 5,
              height: 1.6,
              margin: const EdgeInsets.only(right: 4),
              color: _ink.withValues(alpha: 0.45),
            ),
          ),
        );
      },
    );
  }

  Widget _barcode(double mul) {
    // Deterministic faux barcode — a fixed width pattern cycled.
    const widths = [3.0, 1.5, 4.5, 2.0, 1.5, 3.5, 2.5, 1.5, 5.0, 2.0, 3.0, 1.5];
    return SizedBox(
      height: 44 * mul,
      child: LayoutBuilder(
        builder: (context, c) {
          final bars = <Widget>[];
          var used = 0.0;
          var i = 0;
          while (used < c.maxWidth - 4) {
            final w = widths[i % widths.length];
            bars.add(Container(
              width: w,
              color: i.isEven ? _ink : Colors.transparent,
              margin: const EdgeInsets.only(right: 1.5),
            ));
            used += w + 1.5;
            i++;
          }
          return Row(children: bars);
        },
      ),
    );
  }
}
