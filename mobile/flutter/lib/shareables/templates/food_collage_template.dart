import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/app_watermark.dart';
import '../widgets/food_image.dart';
import '../widgets/macro_viz.dart';

/// FoodCollage — a grid of food photos pulled from several food logs (a
/// whole meal, or a day), with a summed-macro footer band. Layout adapts to
/// the photo count: 1 → full bleed, 2 → split, 3 → 1-big + 2-small, 4+ → 2×2.
class FoodCollageTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const FoodCollageTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  static const double _gap = 4;

  @override
  Widget build(BuildContext context) {
    final aspect = data.aspect;
    final mul = aspect.bodyFontMultiplier;
    final accent = data.accentColor;
    final nutrition = data.nutrition ?? const ShareableNutrition();
    final urls = (data.foodImageUrls ?? const <String>[])
        .where((u) => u.trim().isNotEmpty)
        .toList();

    return ShareableCanvas(
      aspect: aspect,
      backgroundOverride: const [Color(0xFF0B0D12), Color(0xFF050608)],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 54, 20, 26),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: _grid(urls),
              ),
            ),
            SizedBox(height: 14 * mul),
            _footer(mul, accent, nutrition),
          ],
        ),
      ),
    );
  }

  Widget _cell(String? url) => FoodImage(
        url: url,
        fit: BoxFit.cover,
        fallbackBuilder: () => const ColoredBox(color: Color(0xFF161A22)),
      );

  Widget _grid(List<String> urls) {
    if (urls.isEmpty) return _cell(null);
    if (urls.length == 1) return _cell(urls.first);
    if (urls.length == 2) {
      return data.aspect == ShareableAspect.square
          ? Row(children: [
              Expanded(child: _cell(urls[0])),
              const SizedBox(width: _gap),
              Expanded(child: _cell(urls[1])),
            ])
          : Column(children: [
              Expanded(child: _cell(urls[0])),
              const SizedBox(height: _gap),
              Expanded(child: _cell(urls[1])),
            ]);
    }
    if (urls.length == 3) {
      return Column(children: [
        Expanded(flex: 3, child: _cell(urls[0])),
        const SizedBox(height: _gap),
        Expanded(
          flex: 2,
          child: Row(children: [
            Expanded(child: _cell(urls[1])),
            const SizedBox(width: _gap),
            Expanded(child: _cell(urls[2])),
          ]),
        ),
      ]);
    }
    final u = urls.take(4).toList();
    return Column(children: [
      Expanded(
        child: Row(children: [
          Expanded(child: _cell(u[0])),
          const SizedBox(width: _gap),
          Expanded(child: _cell(u[1])),
        ]),
      ),
      const SizedBox(height: _gap),
      Expanded(
        child: Row(children: [
          Expanded(child: _cell(u[2])),
          const SizedBox(width: _gap),
          Expanded(child: _cell(u[3])),
        ]),
      ),
    ]);
  }

  Widget _footer(double mul, Color accent, ShareableNutrition nutrition) {
    final label = (data.mealLabel?.trim().isNotEmpty ?? false)
        ? data.mealLabel!.trim()
        : data.title;
    return Container(
      padding: EdgeInsets.fromLTRB(18 * mul, 14 * mul, 18 * mul, 14 * mul),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20 * mul,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              if (data.periodLabel.trim().isNotEmpty)
                Text(
                  data.periodLabel,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 12 * mul,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          SizedBox(height: 12 * mul),
          MacroViz(
            nutrition: nutrition,
            style: MacroVizStyle.stackedBar,
            accentColor: accent,
            scale: mul,
          ),
          if (showWatermark) ...[
            SizedBox(height: 12 * mul),
            AppWatermark(textColor: Colors.white, fontSize: 12 * mul),
          ],
        ],
      ),
    );
  }
}
