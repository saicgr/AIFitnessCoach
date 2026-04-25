import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../core/utils/safe_num.dart';
import '../../../data/models/trophy.dart';
import '../../../data/services/haptic_service.dart';

/// Horizontal strip of in-progress trophies (badges the user hasn't yet
/// earned but is making progress toward). Card shows icon, title,
/// progress bar, and — where applicable — a reset-date pill.
class InProgressStrip extends ConsumerWidget {
  final List<TrophyProgress> trophies;

  const InProgressStrip({super.key, required this.trophies});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (trophies.isEmpty) {
      return const _EmptyInProgress();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final height = (148 * textScale).clamp(148.0, 200.0);

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: trophies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => _InProgressCard(
          progress: trophies[i],
          accent: accent,
          isDark: isDark,
        ),
      ),
    );
  }
}


class _InProgressCard extends StatelessWidget {
  final TrophyProgress progress;
  final Color accent;
  final bool isDark;

  const _InProgressCard({
    required this.progress,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final border =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final bg = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          HapticService.light();
        },
        child: Container(
          width: 150,
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
          decoration: BoxDecoration(
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        progress.trophy.icon,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${safePercent(progress.progressFraction * 100)}%',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textSecondary
                          : AppColorsLight.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Flexible(
                child: Text(
                  progress.trophy.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color:
                        isDark ? Colors.white : AppColorsLight.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.progressFraction,
                  minHeight: 6,
                  backgroundColor: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _EmptyInProgress extends StatelessWidget {
  const _EmptyInProgress();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Text(
        'Log a workout to unlock your first badges in progress.',
        style: TextStyle(color: muted, fontSize: 13, height: 1.35),
      ),
    );
  }
}
