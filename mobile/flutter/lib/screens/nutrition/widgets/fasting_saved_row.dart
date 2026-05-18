/// Fasting / Saved split row — sits at the top of the Nutrition "Daily" view
/// where the logging-streak banner used to be.
///
/// Two equal-width tappable cards:
///  - LEFT  "Fasting >": live fasting state (active elapsed / "X left", or
///    "Start a fast" when idle). Tapping routes to `/fasting`.
///  - RIGHT "Saved >": entry point to the user's Saved hub — bookmarked
///    recipes, foods and scanned menus. Tapping pushes [SavedHubScreen].
///    Shows a saved-count when available.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/theme_colors.dart';
import '../../../core/widgets/line_icon.dart';
import '../../../data/providers/fasting_provider.dart';
import '../../../data/providers/recipe_providers.dart';
import '../saved_hub_screen.dart';

class FastingSavedRow extends ConsumerWidget {
  final String userId;
  final bool isDark;

  const FastingSavedRow({
    super.key,
    required this.userId,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(child: _FastingCard(userId: userId, isDark: isDark)),
        const SizedBox(width: 12),
        Expanded(child: _SavedCard(userId: userId, isDark: isDark)),
      ],
    );
  }
}

/// Shared card chrome — rounded, themed, with an icon, label + chevron header
/// and a single-line value below. Matches the visual weight of the old
/// streak banner.
class _SplitCard extends StatelessWidget {
  final String label;
  final String iconName;
  final String value;
  final ThemeColors colors;
  final VoidCallback onTap;

  const _SplitCard({
    required this.label,
    required this.iconName,
    required this.value,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: colors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    alignment: Alignment.center,
                    child: LineIcon(iconName, size: 17, color: colors.accent),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      size: 20, color: colors.textMuted),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FastingCard extends ConsumerWidget {
  final String userId;
  final bool isDark;

  const _FastingCard({required this.userId, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.colors(context);
    final fasting = ref.watch(fastingProvider);

    String value;
    if (fasting.hasFast) {
      // Live-updating elapsed seconds for the active fast.
      final elapsedSeconds = ref.watch(fastingTimerProvider).value;
      final remainingMinutes = fasting.activeFast!.goalDurationMinutes -
          fasting.activeFast!.elapsedMinutes;
      if (remainingMinutes > 0) {
        value = '${fasting.remainingTimeFormatted} left';
      } else {
        value = elapsedSeconds != null
            ? _fmtElapsed(elapsedSeconds)
            : fasting.elapsedTimeFormatted;
      }
    } else {
      value = 'Start a fast';
    }

    return _SplitCard(
      label: 'Fasting',
      iconName: 'fasting',
      value: value,
      colors: colors,
      onTap: () => context.push('/fasting'),
    );
  }

  static String _fmtElapsed(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    return '${h}h ${m}m fasting';
  }
}

class _SavedCard extends ConsumerWidget {
  final String userId;
  final bool isDark;

  const _SavedCard({required this.userId, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.colors(context);
    final favorites = userId.isNotEmpty
        ? ref.watch(favoriteRecipesProvider(userId))
        : null;

    // Saved-recipe count is a quick at-a-glance hint; the hub itself also
    // surfaces saved foods and menus.
    final String value = favorites?.maybeWhen(
          data: (resp) {
            final count = resp.totalCount;
            if (count <= 0) return 'Recipes, foods & menus';
            return count == 1 ? '1 saved recipe' : '$count saved recipes';
          },
          orElse: () => 'Recipes, foods & menus',
        ) ??
        'Recipes, foods & menus';

    return _SplitCard(
      label: 'Saved',
      iconName: 'nutrition',
      value: value,
      colors: colors,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SavedHubScreen(userId: userId, isDark: isDark),
          ),
        );
      },
    );
  }
}
