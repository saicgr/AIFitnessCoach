import 'package:flutter/material.dart';
import '_share_common.dart';

/// Trading Card — baseball/Pokémon-style square layout with rarity
/// badge, user name + avatar, stat line, top move. Rarity is derived
/// from session volume via [rarityForVolume].
class TradingCardTemplate extends StatelessWidget {
  final String workoutName;
  final String? userDisplayName;
  final String? userAvatarUrl;
  final double? totalVolumeKg;
  final int totalSets;
  final int? currentStreak;
  final String? topExercise;
  final double? topExerciseWeightKg;
  final DateTime completedAt;
  final bool showWatermark;
  final String weightUnit;

  const TradingCardTemplate({
    super.key,
    required this.workoutName,
    this.userDisplayName,
    this.userAvatarUrl,
    this.totalVolumeKg,
    required this.totalSets,
    this.currentStreak,
    this.topExercise,
    this.topExerciseWeightKg,
    required this.completedAt,
    this.showWatermark = true,
    this.weightUnit = 'lbs',
  });

  @override
  Widget build(BuildContext context) {
    final useKg = weightUnit == 'kg';
    final displayVol = totalVolumeKg == null
        ? 0.0
        : (useKg ? totalVolumeKg! : totalVolumeKg! * 2.20462);
    final rarity = rarityForVolume(displayVol, useKg: useKg);
    final accent = rarityColor(rarity);
    final cardName = (userDisplayName ?? 'ANONYMOUS').toUpperCase();
    final topLift = topExercise?.toUpperCase() ?? workoutName.toUpperCase();

    return Container(
      color: const Color(0xFF05050A),
      padding: const EdgeInsets.all(14),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent, width: 3),
            boxShadow: [
              BoxShadow(color: accent.withValues(alpha: 0.5), blurRadius: 30),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: 0.22),
                const Color(0xFF080810),
                accent.withValues(alpha: 0.12),
              ],
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              // Header row
              Row(
                children: [
                  ShareTrackedCaps(
                    'FITWIZ TRAINER',
                    size: 9,
                    color: Colors.white.withValues(alpha: 0.7),
                    letterSpacing: 2.5,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: accent,
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
              const SizedBox(height: 12),
              // Avatar + name
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: accent, width: 2),
                      ),
                      child: ClipOval(
                        child: userAvatarUrl != null
                            ? Image.network(
                                userAvatarUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _initialsAvatar(cardName, accent),
                              )
                            : _initialsAvatar(cardName, accent),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cardName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            workoutName.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              color: accent,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Stat line
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: accent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statCol('VOL', formatShareWeightCompact(totalVolumeKg, useKg: useKg), accent),
                    _statCol('SETS', '$totalSets', accent),
                    _statCol('STREAK', '${currentStreak ?? 0}d', accent),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Top move
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShareTrackedCaps(
                      'TOP MOVE',
                      size: 8,
                      color: accent,
                      letterSpacing: 2,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      topLift,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (topExerciseWeightKg != null)
                      Text(
                        formatShareWeight(topExerciseWeightKg, useKg: useKg),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '#${completedAt.year}${completedAt.month.toString().padLeft(2, '0')}${completedAt.day.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.white.withValues(alpha: 0.4),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  ShareWatermarkBadge(enabled: showWatermark),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCol(String label, String value, Color accent) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: accent,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _initialsAvatar(String name, Color accent) {
    final initials = name
        .split(RegExp(r'\s+'))
        .take(2)
        .map((w) => w.isEmpty ? '' : w[0])
        .join();
    return Container(
      color: accent.withValues(alpha: 0.18),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }
}
