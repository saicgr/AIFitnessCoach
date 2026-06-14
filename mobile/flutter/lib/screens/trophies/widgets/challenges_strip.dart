import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/services/haptic_service.dart';

import '../../../l10n/generated/app_localizations.dart';
/// CHALLENGES — Signature hairline rows with a JOIN pill. Each row carries an
/// emoji, the challenge name + meta, and a JOIN affordance routing into the
/// existing leaderboard screen.
class ChallengesStrip extends ConsumerWidget {
  const ChallengesStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    final endsLabel =
        'Ends ${endOfMonth.month.toString().padLeft(2, '0')}/${endOfMonth.day.toString().padLeft(2, '0')}';

    final challenges = <_ChallengeData>[
      _ChallengeData(
        title: AppLocalizations.of(context).challengesStripMonthlyRunChallenge,
        subtitle: AppLocalizations.of(context).challengesStrip25KmTarget,
        endsLabel: endsLabel,
        emoji: '🏃',
      ),
      _ChallengeData(
        title: 'Monthly Cycling Challenge',
        subtitle: AppLocalizations.of(context).challengesStrip100KmTarget,
        endsLabel: endsLabel,
        emoji: '🚴',
      ),
      _ChallengeData(
        title: 'Consistency Week',
        subtitle: AppLocalizations.of(context).challengesStrip5WorkoutsIn7,
        endsLabel: endsLabel,
        emoji: '🔥',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          for (int i = 0; i < challenges.length; i++)
            _ChallengeRow(
              data: challenges[i],
              isLast: i == challenges.length - 1,
            ),
        ],
      ),
    );
  }
}


class _ChallengeData {
  final String title;
  final String subtitle;
  final String endsLabel;
  final String emoji;

  const _ChallengeData({
    required this.title,
    required this.subtitle,
    required this.endsLabel,
    required this.emoji,
  });
}


class _ChallengeRow extends StatelessWidget {
  final _ChallengeData data;
  final bool isLast;

  const _ChallengeRow({required this.data, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: isLast
          ? null
          : const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.hairline)),
            ),
      child: Row(
        children: [
          Text(data.emoji, style: const TextStyle(fontSize: 21)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  data.title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ZType.lbl(12, color: tc.textPrimary, weight: FontWeight.w800, letterSpacing: 1),
                ),
                const SizedBox(height: 2),
                Text(
                  '${data.subtitle} · ${data.endsLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, color: tc.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _JoinPill(onTap: () {
            HapticService.light();
            GoRouter.of(context).push('/xp-leaderboard');
          }),
        ],
      ),
    );
  }
}


class _JoinPill extends StatelessWidget {
  final VoidCallback onTap;
  const _JoinPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          'JOIN',
          style: ZType.lbl(10, color: tc.textSecondary, weight: FontWeight.w800, letterSpacing: 1.8),
        ),
      ),
    );
  }
}
