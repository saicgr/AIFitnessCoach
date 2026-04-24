import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/trophy.dart';

/// 3-column grid of Personal-Best medals. If the user hasn't earned any
/// yet, we show an empty-state tile that names the common PR categories
/// so the section never renders as a blank grid.
class PersonalBestsGrid extends StatelessWidget {
  final List<TrophyProgress> trophies;

  const PersonalBestsGrid({super.key, required this.trophies});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (trophies.isEmpty) {
      return _PBEmptyState(isDark: isDark);
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemCount: trophies.length,
      itemBuilder: (_, i) => _PBMedal(
        progress: trophies[i],
        isDark: isDark,
      ),
    );
  }
}


class _PBMedal extends StatelessWidget {
  final TrophyProgress progress;
  final bool isDark;

  const _PBMedal({required this.progress, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final border =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          // Gold→orange medal disc
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color(0xFFFDE68A), Color(0xFFF59E0B)],
              ),
            ),
            child: Center(
              child: Text(
                progress.trophy.icon,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            progress.trophy.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white : AppColorsLight.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            progress.isEarned ? 'Earned' : 'No data',
            style: TextStyle(
              color: isDark
                  ? AppColors.textMuted
                  : AppColorsLight.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}


class _PBEmptyState extends StatelessWidget {
  final bool isDark;
  const _PBEmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final categories = [
      ('Heaviest Lift', '💪'),
      ('Longest Session', '⏱️'),
      ('Most Volume', '📈'),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemCount: categories.length,
      itemBuilder: (_, i) {
        final (label, emoji) = categories[i];
        final bg =
            isDark ? AppColors.elevated : AppColorsLight.elevated;
        final border =
            isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Column(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.06),
                ),
                child: Center(
                  child: Opacity(
                    opacity: 0.5,
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.85)
                      : AppColorsLight.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'No data',
                style: TextStyle(
                  color: isDark
                      ? AppColors.textMuted
                      : AppColorsLight.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
