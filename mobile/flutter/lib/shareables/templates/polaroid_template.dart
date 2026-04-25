import 'dart:io';
import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/fitwiz_watermark.dart';

/// Polaroid — off-white frame on slight rotation, centered photo (uses
/// `data.heroImageUrl` first, then `customPhotoPath`, fallback gradient).
/// Handwritten-style caption + date stamp at the bottom.
class PolaroidTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const PolaroidTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    final mul = data.aspect.bodyFontMultiplier;
    final accent = data.accentColor;
    final caption = (data.userDisplayName?.isNotEmpty == true
            ? data.userDisplayName!
            : data.title)
        .trim();
    final hero = shareableHeroString(data);
    final unit = shareableHeroUnit(data);
    final subline = (hero != '—' && hero.isNotEmpty)
        ? (unit.isEmpty ? hero : '$hero $unit')
        : data.periodLabel;

    return ShareableCanvas(
      aspect: data.aspect,
      backgroundOverride: const [Color(0xFF1B1A18), Color(0xFF0F0E0C)],
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(56),
          child: Transform.rotate(
            angle: -0.04,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFAF6EE),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.55),
                    blurRadius: 30,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 56),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: _photoOrGradient(accent),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Times New Roman',
                      color: const Color(0xFF1A1A1A),
                      fontSize: 22 * mul,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subline,
                    style: TextStyle(
                      color: const Color(0xFF1A1A1A).withValues(alpha: 0.55),
                      fontSize: 13 * mul,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        data.periodLabel.toUpperCase(),
                        style: TextStyle(
                          color: const Color(0xFF8B0000).withValues(alpha: 0.7),
                          fontSize: 9 * mul,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                      if (showWatermark)
                        FitWizWatermark(
                          textColor: const Color(0xFF1A1A1A),
                          fontSize: 10 * mul,
                          iconSize: 14,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _photoOrGradient(Color accent) {
    final source = data.heroImageUrl ?? data.customPhotoPath;
    if (source == null || source.isEmpty) {
      return _gradient(accent);
    }
    if (source.startsWith('http')) {
      return Image.network(
        source,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _gradient(accent),
      );
    }
    return Image.file(
      File(source),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _gradient(accent),
    );
  }

  Widget _gradient(Color accent) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent,
            Color.lerp(accent, Colors.black, 0.55)!,
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.fitness_center_rounded,
          color: Colors.white54,
          size: 96,
        ),
      ),
    );
  }
}
