import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/providers/xp_provider.dart';
import '../../../data/services/haptic_service.dart';
import 'components/components.dart';
import 'gym_profile_switcher.dart';

/// Clean, minimal header for the "Minimalist" home screen preset.
///
/// Layout:
/// ```
/// [Gym Profile Switcher - collapsed tabs]
/// Hey, {name}         [XP badge (level)] [bell icon]
/// ```
class MinimalHeader extends ConsumerWidget {
  const MinimalHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final xpState = ref.watch(xpProvider);
    final accentColor = ref.watch(accentColorProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Gym Profile Switcher - takes remaining space
          const Expanded(
            child: GymProfileSwitcher(collapsed: true),
          ),

          // XP Level Badge
          InkWell(
            onTap: () {
              HapticService.light();
              context.push('/xp-goals');
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: accentColor.getColor(isDark),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '${xpState.currentLevel}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),

          const SizedBox(width: 4),

          // Notification Bell
          NotificationBellButton(isDark: isDark),
        ],
      ),
    );
  }
}
