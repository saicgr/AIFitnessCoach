/// F3.55 — Accountability partner nudge. Surfaces the user's accountability
/// partner (first friend in their friends list as a proxy) and offers a
/// one-tap check-in. Collapses if there are no friends.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/user_provider.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../data/providers/social_provider.dart';
import '../../../../data/services/haptic_service.dart';

class AccountabilityPartnerNudge extends ConsumerWidget {
  const AccountabilityPartnerNudge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ThemeColors.of(context);

    String? userId;
    try {
      userId = ref.watch(currentUserProvider).valueOrNull?.id;
    } catch (_) {}
    if (userId == null) return const SizedBox.shrink();

    List<Map<String, dynamic>>? friends;
    try {
      friends = ref.watch(friendsListProvider(userId)).valueOrNull;
    } catch (_) {}
    if (friends == null || friends.isEmpty) return const SizedBox.shrink();

    final partner = friends.first;
    final name = (partner['display_name'] ??
            partner['username'] ??
            partner['name'] ??
            'your partner')
        .toString();
    final partnerId = (partner['user_id'] ?? partner['id'] ?? '').toString();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: c.accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text('👋', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Check in with $name',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Send a quick hi or share today\'s session.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: c.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _Pill(
            label: 'Say hi',
            color: c.accent,
            onTap: () {
              HapticService.light();
              if (partnerId.isNotEmpty) {
                context.push('/social/dm/$partnerId');
              } else {
                context.push('/social');
              }
            },
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _Pill({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
      ),
    );
  }
}
