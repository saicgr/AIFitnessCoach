import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/accent_color_provider.dart';
import '../../../data/services/haptic_service.dart';

/// Horizontal strip of active async challenges. Each card shows the
/// challenge name, end-date, and a JOIN button. Tapping JOIN navigates
/// to the challenge detail (hooked into the existing leaderboard screen).
///
/// For the first ship we surface two bundled monthly challenges that are
/// always available — matches the reference screenshot's "April Run" /
/// "April Cycling" cards. The backend's `/leaderboard/async-challenge`
/// endpoint can later drive this list dynamically.
class ChallengesStrip extends ConsumerWidget {
  const ChallengesStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);

    final now = DateTime.now();
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    final endsLabel =
        'Ends ${endOfMonth.month.toString().padLeft(2, '0')}/${endOfMonth.day.toString().padLeft(2, '0')}';

    final challenges = <_ChallengeData>[
      _ChallengeData(
        title: 'Monthly Run Challenge',
        subtitle: '25 km target',
        endsLabel: endsLabel,
        emoji: '🏃',
        gradient: const [Color(0xFF22C55E), Color(0xFF86EFAC)],
      ),
      _ChallengeData(
        title: 'Monthly Cycling Challenge',
        subtitle: '100 km target',
        endsLabel: endsLabel,
        emoji: '🚴',
        gradient: const [Color(0xFF3B82F6), Color(0xFF60A5FA)],
      ),
      _ChallengeData(
        title: 'Consistency Week',
        subtitle: '5 workouts in 7 days',
        endsLabel: endsLabel,
        emoji: '🔥',
        gradient: const [Color(0xFFF97316), Color(0xFFFBBF24)],
      ),
    ];

    // Adaptive height — scales with user text size so the JOIN button
    // can't overflow when iOS/Android Dynamic Type is cranked up.
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final height = (180 * textScale).clamp(180.0, 240.0);

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: challenges.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => _ChallengeCard(
          data: challenges[i],
          accent: accent,
          isDark: isDark,
        ),
      ),
    );
  }
}


class _ChallengeData {
  final String title;
  final String subtitle;
  final String endsLabel;
  final String emoji;
  final List<Color> gradient;

  const _ChallengeData({
    required this.title,
    required this.subtitle,
    required this.endsLabel,
    required this.emoji,
    required this.gradient,
  });
}


class _ChallengeCard extends StatelessWidget {
  final _ChallengeData data;
  final Color accent;
  final bool isDark;

  const _ChallengeCard({
    required this.data,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: data.gradient,
        ),
        boxShadow: [
          BoxShadow(
            color: data.gradient.first.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.emoji,
            style: TextStyle(
              fontSize: 40,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  data.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.endsLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  HapticService.light();
                  GoRouter.of(context).push('/xp-leaderboard');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.55),
                      width: 1.2,
                    ),
                  ),
                  child: const Text(
                    'JOIN',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
