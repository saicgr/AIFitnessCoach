import 'package:flutter/material.dart';

import '../../workout/widgets/share_templates/_share_common.dart';
import '_report_common.dart';

/// Trading Card — 1:1 baseball-card layout with rarity border derived from
/// the hero magnitude, user name + initials plate, stat line, and up to
/// three highlight rows.
class ReportTradingCardTemplate extends StatelessWidget {
  final ReportShareData data;
  final bool showWatermark;

  const ReportTradingCardTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    final hero = heroMetricFor(data);
    final heroNumber = double.tryParse(hero) ?? 0;
    // Repurpose the workout rarityForVolume ladder — for report metrics the
    // raw "bigger is rarer" mapping still reads correctly.
    final rarity = rarityForVolume(heroNumber * 10, useKg: false);
    final rarityBorder = rarityColor(rarity);
    final accent = data.accentColor;
    final name = (data.userDisplayName ?? 'Lifter').toUpperCase();
    final initials = initialsOf(data.userDisplayName);

    return RepaintBoundary(
      child: Container(
        color: const Color(0xFF05050A),
        padding: const EdgeInsets.all(18),
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: rarityBorder, width: 3),
              boxShadow: [
                BoxShadow(
                  color: rarityBorder.withValues(alpha: 0.5),
                  blurRadius: 32,
                ),
              ],
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: 0.28),
                  const Color(0xFF0B0B14),
                  rarityBorder.withValues(alpha: 0.12),
                ],
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    ShareTrackedCaps(
                      data.title,
                      size: 9,
                      color: Colors.white.withValues(alpha: 0.7),
                      letterSpacing: 2.5,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: rarityBorder,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        rarityLabel(rarity),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: rarity == ShareRarity.diamond ||
                                  rarity == ShareRarity.platinum
                              ? Colors.black
                              : Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Avatar plate — initials only; a network avatar would require
                // async loading and can't be captured synchronously without
                // first pre-warming the cache, so the initials treatment keeps
                // captures reliable.
                Container(
                  width: 78,
                  height: 78,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: rarityBorder, width: 2),
                    gradient: LinearGradient(
                      colors: [
                        accent.withValues(alpha: 0.45),
                        accent.withValues(alpha: 0.15),
                      ],
                    ),
                  ),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                ShareTrackedCaps(
                  data.periodLabel,
                  size: 9,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                const Spacer(),
                ShareHeroNumber(
                  value: hero,
                  unit: heroUnitFor(data).isEmpty ? null : heroUnitFor(data),
                  size: 72,
                  color: Colors.white,
                ),
                const Spacer(),
                // Highlight strip — up to 3 mini stats.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: data.highlights.take(3).map((h) {
                    return Expanded(
                      child: Column(
                        children: [
                          Text(
                            h.value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          ShareTrackedCaps(
                            h.label,
                            size: 8,
                            color: Colors.white.withValues(alpha: 0.6),
                            letterSpacing: 1.3,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                if (showWatermark) const ShareWatermarkBadge(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
