/// F3.39 — Compact mood check-in strip with 5 emoji options. Tapping
/// records the mood (best-effort) and routes to chat with the source tag
/// so the coach can follow up. Stateless beyond the tap action.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/providers/mood_history_provider.dart';
import '../../../../data/services/haptic_service.dart';

class MoodCheckinStrip extends ConsumerWidget {
  const MoodCheckinStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ThemeColors.of(context);

    // Hide once the user has already checked in today.
    try {
      final todayMood = ref.watch(todayMoodCheckinProvider).valueOrNull;
      if (todayMood != null) return const SizedBox.shrink();
    } catch (_) {}
    const moods = <({String emoji, String label})>[
      (emoji: '😞', label: 'Low'),
      (emoji: '😕', label: 'Meh'),
      (emoji: '😐', label: 'OK'),
      (emoji: '🙂', label: 'Good'),
      (emoji: '🤩', label: 'Great'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'How are you feeling?',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final m in moods)
                _MoodButton(
                  emoji: m.emoji,
                  label: m.label,
                  onTap: () {
                    HapticService.light();
                    context.push('/chat?source=mood_checkin&mood=${m.label.toLowerCase()}');
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoodButton extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;
  const _MoodButton({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: c.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
