import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/utils/safe_num.dart';
import '../../../../data/models/home_layout.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../data/providers/ai_insights_provider.dart';
import '../../../../data/providers/neat_provider.dart';
import '../../../../data/providers/nutrition_preferences_provider.dart';
import '../../../../data/providers/recovery_provider.dart';
import '../../../../data/providers/scores_provider.dart';
import '../../../../data/providers/social_provider.dart';
import '../../../../data/models/user_xp.dart';
import '../../../../data/providers/xp_provider.dart';
import '../../../../data/repositories/hydration_repository.dart';
import '../../../../data/repositories/measurements_repository.dart';
import '../../../../data/repositories/nutrition_repository.dart';
import '../../../../data/repositories/workout_repository.dart';
import '../../../../data/services/haptic_service.dart';

part 'new_tiles_part_personal_records_card.dart';
part 'new_tiles_part_active_challenge_card.dart';
part 'new_tiles_part_my_journey_card.dart';


/// ============================================================
/// STREAK COUNTER CARD
/// Shows current workout streak with fire animation
/// ============================================================
class StreakCounterCard extends ConsumerWidget {
  final TileSize size;
  final bool isDark;

  const StreakCounterCard({
    super.key,
    this.size = TileSize.half,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // M5: TODO - Ideally use ref.watch(workoutsProvider.select((s) => s.valueOrNull?.currentStreak))
    // but currentStreak is a getter on the notifier, not on the state value.
    final workoutsNotifier = ref.read(workoutsProvider.notifier);
    final currentStreak = workoutsNotifier.currentStreak;

    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final orangeColor = AppColors.orange;

    if (size == TileSize.compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: orangeColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // M6: orangeColor is from AppColors (not const-constructable with dynamic color)
            Icon(Icons.local_fire_department, color: orangeColor, size: 20),
            const SizedBox(width: 6),
            Text(
              '$currentStreak',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: currentStreak > 0 ? orangeColor : textColor,
              ),
            ),
          ],
        ),
      );
    }

    // Half or Full size
    return Container(
      margin: size == TileSize.full
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 4)
          : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: orangeColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: orangeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.local_fire_department, color: orangeColor, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                'Streak',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$currentStreak',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: currentStreak > 0 ? orangeColor : textColor,
            ),
          ),
          Text(
            currentStreak == 1 ? 'day' : 'days',
            style: TextStyle(fontSize: 14, color: textMuted),
          ),
          if (currentStreak > 0) ...[
            const SizedBox(height: 8),
            Text(
              currentStreak >= 7
                  ? 'Amazing streak! Keep going!'
                  : 'Keep the fire burning!',
              style: TextStyle(
                fontSize: 12,
                color: textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
