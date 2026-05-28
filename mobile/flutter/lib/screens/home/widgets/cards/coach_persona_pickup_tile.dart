/// F3.88 — Coach persona pickup tile.
///
/// Compact tile that nudges the user to (re)pick their coach persona during
/// the first week if they haven't yet, or when they've engaged with the
/// AI Coach <2 times. Tapping deep-links to /settings/ai-coach for persona
/// selection. Collapses silently when the persona is already in use.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/services/haptic_service.dart';

class CoachPersonaPickupSignal {
  final bool personaSelected;
  final int coachInteractions; // last 7 days
  const CoachPersonaPickupSignal({
    required this.personaSelected,
    required this.coachInteractions,
  });
}

/// `personaSelected` reads the real `coach_selected` flag from the auth user
/// profile. Interaction count is left at 0 until a chat-engagement endpoint
/// lands — that way the tile still surfaces correctly in the dominant case
/// (persona not yet picked).
// TODO(backend): GET /api/v1/chat/engagement?days=7 for coachInteractions.
final coachPersonaPickupSignalProvider =
    Provider.autoDispose<CoachPersonaPickupSignal?>((ref) {
  try {
    final user = ref.watch(authStateProvider).user;
    if (user == null) return null;
    return CoachPersonaPickupSignal(
      personaSelected: user.coachSelected ?? false,
      coachInteractions: 0,
    );
  } catch (_) {
    return null;
  }
});

class CoachPersonaPickupTile extends ConsumerWidget {
  const CoachPersonaPickupTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    CoachPersonaPickupSignal? signal;
    try {
      signal = ref.watch(coachPersonaPickupSignalProvider);
    } catch (_) {
      return const SizedBox.shrink();
    }
    if (signal == null) return const SizedBox.shrink();
    if (signal.personaSelected && signal.coachInteractions >= 2) {
      return const SizedBox.shrink();
    }

    final c = ThemeColors.of(context);
    final isFirstTime = !signal.personaSelected;
    final headline =
        isFirstTime ? 'Pick your coach voice' : 'Try chatting with your coach';
    final body = isFirstTime
        ? 'A few personas: warm, drill-sergeant, science-nerd, zen. Pick the voice that gets through to you.'
        : 'You\'ve barely tapped your coach this week. One quick question often unblocks a stall.';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticService.light();
          context.push(isFirstTime ? '/settings/ai-coach' : '/chat');
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: c.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isFirstTime
                      ? Icons.record_voice_over_rounded
                      : Icons.chat_bubble_rounded,
                  size: 18,
                  color: c.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headline,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      body,
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.35,
                        color: c.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: c.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
