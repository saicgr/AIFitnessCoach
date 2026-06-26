import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/training_preferences_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/services/haptic_service.dart';

/// The synthetic "active plan" card for users who have NO active PRIMARY
/// program assignment — i.e. they're on the default **AI-decides** adaptive
/// plan. This is the user's REAL current training plan (the AI generates each
/// day from their training prefs), so it's shown as an active card, never an
/// empty state.
///
/// Label is derived read-only from the user's actual prefs via
/// [trainingPreferencesProvider] (workout type) + [currentUserProvider]
/// (training-day count) — no fake data. Tap routes to Workout Settings, where
/// the split + days that shape the adaptive plan live.
///
/// Shared so the home "My Programs" card AND the Program Library's "Your
/// Programs" hub render the SAME card in their Active section.
class AiAdaptivePlanCard extends ConsumerWidget {
  const AiAdaptivePlanCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tc = ThemeColors.of(context);
    final accent = tc.accent;

    final prefs = ref.watch(trainingPreferencesProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;

    // "Adaptive · Strength · 4×/week" — built from real prefs. Pieces drop out
    // gracefully when unknown (e.g. days not set yet).
    final typeLabel = prefs.workoutType.displayName;
    final daysPerWeek = user?.workoutDays.length ?? 0;
    final subParts = <String>[
      'Adaptive',
      if (typeLabel.isNotEmpty) typeLabel,
      if (daysPerWeek > 0) '$daysPerWeek×/week',
    ];
    final subtitle = subParts.join(' · ');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          HapticService.selection();
          // Split + days that shape the adaptive plan live in Workout Settings.
          context.push('/settings/workout-settings');
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: tc.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: accent.withValues(alpha: 0.4)),
                ),
                child: Icon(Icons.auto_awesome, size: 20, color: accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'AI Coach · Adaptive Plan',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: tc.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _ActiveBadge(accent: accent),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: tc.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your coach builds each day around your recovery and goals.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: tc.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.tune_rounded, size: 16, color: tc.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  final Color accent;
  const _ActiveBadge({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Text(
        'ACTIVE',
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: accent,
        ),
      ),
    );
  }
}
