import 'dart:io';
import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/app_watermark.dart';

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
                  const SizedBox(height: 16),
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
                  // Workout title (e.g. "Steady Ground Strength") — separate
                  // from caption when caption is the user's name.
                  if (data.userDisplayName != null &&
                      data.userDisplayName!.trim().isNotEmpty &&
                      data.title.trim().isNotEmpty &&
                      data.title.trim() != data.userDisplayName!.trim()) ...[
                    const SizedBox(height: 2),
                    Text(
                      data.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF1A1A1A).withValues(alpha: 0.75),
                        fontSize: 13 * mul,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (subline.trim().isNotEmpty) ...[
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
                  ],
                  // Real workout stats from the completed session — duration,
                  // sets, reps, exercises, volume — pulled from highlights.
                  ..._buildStatsBlock(data, mul),
                  const SizedBox(height: 10),
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
                        AppWatermark(
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

  /// Build a row of mini stat tiles (DURATION · SETS · REPS · EXERCISES)
  /// pulled from the highlights array. Picks up to 4 most-relevant metrics
  /// so the polaroid reads like a real photo caption + receipt.
  List<Widget> _buildStatsBlock(Shareable data, double mul) {
    bool matches(String label, List<String> needles) {
      final upper = label.toUpperCase();
      return needles.any(upper.contains);
    }
    final preferred = <String, ShareableMetric>{};
    for (final h in data.highlights) {
      if (h.value.trim().isEmpty) continue;
      if (preferred.containsKey('duration') == false &&
          matches(h.label, ['DURATION', 'TIME'])) {
        preferred['duration'] = h;
        continue;
      }
      if (preferred.containsKey('sets') == false &&
          matches(h.label, ['SETS'])) {
        preferred['sets'] = h;
        continue;
      }
      if (preferred.containsKey('reps') == false &&
          matches(h.label, ['REPS'])) {
        preferred['reps'] = h;
        continue;
      }
      if (preferred.containsKey('exercises') == false &&
          matches(h.label, ['EXERCISE'])) {
        preferred['exercises'] = h;
        continue;
      }
      if (preferred.containsKey('volume') == false &&
          matches(h.label, ['VOLUME'])) {
        preferred['volume'] = h;
        continue;
      }
    }
    final order = const ['duration', 'sets', 'reps', 'exercises', 'volume'];
    final picks = order
        .map((k) => preferred[k])
        .whereType<ShareableMetric>()
        .take(4)
        .toList();
    if (picks.isEmpty) return const [];

    return [
      const SizedBox(height: 14),
      Container(
        height: 1,
        color: const Color(0xFF1A1A1A).withValues(alpha: 0.12),
      ),
      const SizedBox(height: 10),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: picks.map((m) {
          return Expanded(
            child: Column(
              children: [
                Text(
                  m.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Times New Roman',
                    color: const Color(0xFF1A1A1A),
                    fontSize: 18 * mul,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  m.label.toUpperCase(),
                  style: TextStyle(
                    color: const Color(0xFF1A1A1A).withValues(alpha: 0.55),
                    fontSize: 8.5 * mul,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    ];
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
