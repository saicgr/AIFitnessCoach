import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/body_analyzer.dart';
import 'body_analyzer_hero.dart';
import 'score_ring.dart';
import 'package:fitwiz/core/constants/branding.dart';

/// Exports a shareable snapshot of the Body Analyzer result.
///
/// Uses the same `RepaintBoundary` → `toImage()` pattern as
/// `share_stats_sheet.dart` so there's no new dependency.
class ShareBodyAnalyzerSheet extends StatelessWidget {
  final BodyAnalyzerSnapshot snapshot;

  const ShareBodyAnalyzerSheet({super.key, required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final key = GlobalKey();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RepaintBoundary(
              key: key,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.nearBlack
                      : AppColorsLight.nearWhite,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BodyAnalyzerHero(
                      score: snapshot.overallRating ?? 0,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ScoreRing(
                            label: 'Body Fat',
                            value: '${(snapshot.bodyFatPercent ?? 0).toStringAsFixed(0)}%',
                            fill: ((snapshot.bodyFatPercent ?? 0) / 40).clamp(0.0, 1.0),
                            color: const Color(0xFF3498DB),
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ScoreRing(
                            label: 'Muscle Mass',
                            value: '${(snapshot.muscleMassPercent ?? 0).toStringAsFixed(0)}%',
                            fill: ((snapshot.muscleMassPercent ?? 0) / 60).clamp(0.0, 1.0),
                            color: const Color(0xFFF5A623),
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ScoreRing(
                            label: 'Symmetry',
                            value: '${((snapshot.symmetryScore ?? 0) / 10).round()}/10',
                            fill: ((snapshot.symmetryScore ?? 0) / 100).clamp(0.0, 1.0),
                            color: const Color(0xFFB24BF3),
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '@${Branding.appName} · Body Analyzer',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textMuted
                            : AppColorsLight.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _shareAsImage(context, key),
                icon: const Icon(Icons.ios_share, size: 18),
                label: const Text('Share image'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _shareAsImage(BuildContext context, GlobalKey key) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      await Share.shareXFiles(
        [XFile.fromData(Uint8List.fromList(bytes), name: 'body-analyzer.png', mimeType: 'image/png')],
        text: 'My Body Analyzer snapshot',
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Share failed')),
        );
      }
    }
  }
}
