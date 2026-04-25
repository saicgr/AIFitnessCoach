import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/fitwiz_watermark.dart';
import '../widgets/photo_backdrop.dart';
import '../widgets/shareable_hero_number.dart';

/// PhotoSplit — 50/50 split layout. Half the canvas is the user's photo,
/// the other half is a solid accent panel with hero number + 4 stat tiles.
/// Vertical split (photo top / panel bottom) on portrait + story; flips
/// to horizontal (photo left / panel right) on square so the panel
/// doesn't squish.
class PhotoSplitTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const PhotoSplitTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    final mul = data.aspect.bodyFontMultiplier;
    final accent = data.accentColor;
    final stats = data.highlights.where((h) => h.isPopulated).take(4).toList();
    final horizontal = data.aspect == ShareableAspect.square;

    final photoPane = PhotoBackdrop(
      path: data.customPhotoPath,
      fallbackGradient: [
        Color.lerp(accent, Colors.black, 0.30)!,
        Color.lerp(accent, Colors.black, 0.65)!,
      ],
      topScrim: 0.10,
      bottomScrim: 0.30,
    );

    final dataPane = Container(
      color: const Color(0xFF0B0F19),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            data.periodLabel.toUpperCase(),
            style: TextStyle(
              color: accent,
              fontSize: 11 * mul,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22 * mul,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 18),
          ShareableHeroNumber(
            data: data,
            size: data.aspect == ShareableAspect.story ? 96 : 72,
            unitSize: 16 * mul,
            stacked: false,
            color: Colors.white,
            unitColor: accent,
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.4,
            children: [
              for (final s in stats) _statCell(s, mul, accent),
            ],
          ),
          const Spacer(),
          if (showWatermark)
            FitWizWatermark(
              textColor: Colors.white,
              fontSize: 12 * mul,
            ),
        ],
      ),
    );

    return ShareableCanvas(
      aspect: data.aspect,
      backgroundOverride: const [Color(0xFF0B0F19), Color(0xFF050810)],
      child: horizontal
          ? Row(
              children: [
                Expanded(child: photoPane),
                Expanded(child: dataPane),
              ],
            )
          : Column(
              children: [
                Expanded(flex: 5, child: photoPane),
                Expanded(flex: 6, child: dataPane),
              ],
            ),
    );
  }

  Widget _statCell(ShareableMetric m, double mul, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            m.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 9 * mul,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          Text(
            m.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14 * mul,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
