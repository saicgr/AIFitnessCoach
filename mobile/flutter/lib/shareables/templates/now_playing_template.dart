import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/app_watermark.dart';
import 'package:fitwiz/core/constants/branding.dart';

/// NowPlaying — Spotify-style "Now Working Out" status card. Blurred album-
/// art-style background (uses heroImageUrl or customPhotoPath), play bar
/// with progress = workout %, track name = workout title, artist =
/// "Zealova".
class NowPlayingTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const NowPlayingTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    final mul = data.aspect.bodyFontMultiplier;
    final accent = data.accentColor;
    final source = data.heroImageUrl ?? data.customPhotoPath;

    return ShareableCanvas(
      aspect: data.aspect,
      backgroundOverride: const [Color(0xFF000000), Color(0xFF000000)],
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (source != null && source.isNotEmpty)
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 36, sigmaY: 36),
                child: source.startsWith('http')
                    ? Image.network(source,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _bgGradient(accent))
                    : Image.file(File(source),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _bgGradient(accent)),
              ),
            )
          else
            Positioned.fill(child: _bgGradient(accent)),
          // Dim scrim.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(36, 80, 36, 56),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.expand_more_rounded,
                        color: Colors.white, size: 22 * mul),
                    const SizedBox(width: 6),
                    Text(
                      'NOW WORKING OUT',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11 * mul,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.4,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.more_horiz_rounded,
                        color: Colors.white.withValues(alpha: 0.7)),
                  ],
                ),
                const Spacer(),
                AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: source != null && source.isNotEmpty
                        ? (source.startsWith('http')
                            ? Image.network(source,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _albumArtFallback(accent))
                            : Image.file(File(source),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _albumArtFallback(accent)))
                        : _albumArtFallback(accent),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  data.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30 * mul,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${Branding.appName}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 14 * mul,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.check_circle_rounded,
                        size: 14 * mul, color: accent),
                  ],
                ),
                const SizedBox(height: 22),
                // Progress bar.
                Stack(
                  children: [
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: 0.78,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Positioned(
                      left: MediaQuery.of(context).size.width * 0,
                      top: -3,
                      child: FractionallySizedBox(
                        widthFactor: 0.78,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      _progressLabel(data),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11 * mul,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      data.periodLabel,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11 * mul,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Icon(Icons.shuffle_rounded,
                        color: Colors.white.withValues(alpha: 0.75),
                        size: 22 * mul),
                    Icon(Icons.skip_previous_rounded,
                        color: Colors.white, size: 36 * mul),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.pause_rounded,
                          color: Colors.black, size: 36 * mul),
                    ),
                    Icon(Icons.skip_next_rounded,
                        color: Colors.white, size: 36 * mul),
                    Icon(Icons.repeat_rounded,
                        color: Colors.white.withValues(alpha: 0.75),
                        size: 22 * mul),
                  ],
                ),
                const Spacer(),
                if (showWatermark)
                  Center(
                    child: AppWatermark(
                      textColor: Colors.white,
                      fontSize: 12 * mul,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _progressLabel(Shareable d) {
    final hero = shareableHeroString(d);
    final unit = shareableHeroUnit(d);
    if (hero != '—' && hero.isNotEmpty) {
      return unit.isEmpty ? hero : '$hero $unit';
    }
    return d.title;
  }

  Widget _bgGradient(Color accent) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accent,
            Color.lerp(accent, Colors.black, 0.7)!,
          ],
        ),
      ),
    );
  }

  Widget _albumArtFallback(Color accent) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent,
            Color.lerp(accent, Colors.black, 0.6)!,
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.fitness_center_rounded,
            size: 88, color: Colors.white70),
      ),
    );
  }
}
