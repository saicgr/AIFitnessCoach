/// F3.54 — Group challenge progress tile. Reads the user's active group
/// challenges and surfaces the first one with a progress bar. Collapses
/// when none are active.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/user_provider.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../data/providers/social_provider.dart';
import '../../../../data/services/haptic_service.dart';

class GroupChallengeProgress extends ConsumerWidget {
  const GroupChallengeProgress({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ThemeColors.of(context);

    String? userId;
    try {
      userId = ref.watch(currentUserProvider.select((u) => u.valueOrNull?.id));
    } catch (_) {}
    if (userId == null) return const SizedBox.shrink();

    List<Map<String, dynamic>>? challenges;
    try {
      challenges = ref.watch(userActiveChallengesProvider(userId)).valueOrNull;
    } catch (_) {}
    if (challenges == null || challenges.isEmpty) {
      return const SizedBox.shrink();
    }

    final ch = challenges.first;
    final title = (ch['title'] ?? ch['name'] ?? 'Group challenge').toString();
    final current = _asDouble(ch['progress'] ?? ch['current'] ?? 0);
    final target = _asDouble(ch['target'] ?? ch['goal'] ?? 0);
    final progress =
        target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final unit = (ch['unit'] ?? '').toString();
    final participants =
        (ch['participant_count'] ?? ch['participants'] ?? '').toString();

    return GestureDetector(
      onTap: () {
        HapticService.light();
        context.push('/social?tab=challenges');
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text('🤝', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: c.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (participants.isNotEmpty)
                  Text(
                    '$participants joined',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: c.textMuted,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: c.cardBorder.withValues(alpha: 0.6),
                valueColor: AlwaysStoppedAnimation<Color>(c.accent),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              target > 0
                  ? '${_fmt(current)} / ${_fmt(target)}${unit.isNotEmpty ? ' $unit' : ''}'
                  : 'In progress',
              style: TextStyle(
                fontSize: 11,
                color: c.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _asDouble(Object? v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}
