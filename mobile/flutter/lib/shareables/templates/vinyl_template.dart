import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/app_watermark.dart';

/// Vinyl record — black disc with concentric grooves and an orange
/// brand-color center label. The hero number rides on the label like
/// a record's run-time. Side-A vibe.
class VinylTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const VinylTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    final mul = data.aspect.bodyFontMultiplier;
    final hero = data.heroValue == null
        ? data.title
        : '${data.heroPrefix ?? ''}${data.heroValue}${data.heroSuffix ?? ''}';
    final unit = data.heroUnitSingular.toUpperCase();

    return ShareableCanvas(
      aspect: data.aspect,
      backgroundOverride: const [Color(0xFF050505), Color(0xFF050505), Color(0xFF050505)],
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      ...List.generate(
                        7,
                        (i) => Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.06),
                              width: 0.8,
                            ),
                          ),
                          margin: EdgeInsets.all(40.0 + i * 36),
                        ),
                      ),
                      // Center label — brand orange.
                      LayoutBuilder(
                        builder: (ctx, c) {
                          final size = c.maxWidth * 0.34;
                          return Container(
                            width: size,
                            height: size,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.orange,
                                  Color(0xFFFF6B00),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'SIDE A',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12 * mul,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10),
                                      child: Text(
                                        hero,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 28 * mul,
                                          fontWeight: FontWeight.w900,
                                          height: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (unit.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        unit,
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 9 * mul,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      // Center hole.
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (data.title.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                data.title.toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18 * mul,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                ),
              ),
            ],
            if (showWatermark) ...[
              const SizedBox(height: 16),
              const AppWatermark(textColor: Colors.white60),
            ],
          ],
        ),
      ),
    );
  }
}
