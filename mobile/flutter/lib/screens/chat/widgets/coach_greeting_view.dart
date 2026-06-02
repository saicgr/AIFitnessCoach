/// Coach Greeting View — the LIGHT, time-aware empty state for Ask Coach.
///
/// Shown when the user opens a new/empty chat outside the rich-briefing
/// windows (or when a briefing is unavailable). Renders the backend
/// `source=greeting` payload: a big time-of-day headline ("Good afternoon,
/// {Name}!"), a one-line body, and the greeting's 3 label-only suggestion
/// chips. Because the greeting rotates server-side on every call, the copy is
/// fresh each open.
///
/// If the greeting insight is unavailable (network error / not yet loaded),
/// the caller falls back to [EnhancedEmptyState] — this widget never invents
/// copy and assumes a valid greeting payload was passed in.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/theme_colors.dart';
import '../../../data/models/coach_persona.dart';
import '../../../data/providers/daily_coach_insight_provider.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/coach_avatar.dart';
import 'generic_blocks_renderer.dart';

class CoachGreetingView extends StatelessWidget {
  final DailyCoachInsight greeting;
  final CoachPersona coach;

  /// Suggestion chip tapped → send its label as a user chat message.
  final void Function(String label) onSuggestionTap;

  /// Route chip tapped → deep-link (greeting chips are usually label-only,
  /// but the contract allows a route, so we honour it).
  final void Function(String route) onRouteTap;

  const CoachGreetingView({
    super.key,
    required this.greeting,
    required this.coach,
    required this.onSuggestionTap,
    required this.onRouteTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    final accent = c.accent;
    final headline = greeting.headline.trim();
    final body = greeting.body.trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          const SizedBox(height: 24),

          // Coach avatar with accent glow.
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.25),
                  blurRadius: 32,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: CoachAvatar(
              coach: coach,
              size: 84,
              showBorder: true,
              borderWidth: 3,
              showShadow: false,
            ),
          ),
          const SizedBox(height: 24),

          // Big time-of-day headline (carries the user's name from backend).
          if (headline.isNotEmpty)
            Text(
              headline,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                height: 1.2,
                fontWeight: FontWeight.w800,
                color: c.textPrimary,
              ),
            ),
          if (headline.isNotEmpty && body.isNotEmpty)
            const SizedBox(height: 8),

          // One-line body.
          if (body.isNotEmpty)
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: c.textSecondary,
              ),
            ),

          // Grounded inline graphs (sleep ring / recovery / steps) — Fix 3:
          // the coach opening now shows the user's real data, not just a prompt.
          if (greeting.blocks.isNotEmpty) ...[
            const SizedBox(height: 18),
            GenericBlocksRenderer(blocks: greeting.blocks),
          ],
          const SizedBox(height: 28),

          // Suggestion chips as full-width tappable rows.
          for (final chip in greeting.chips) ...[
            _GreetingSuggestion(
              chip: chip,
              colors: c,
              accent: accent,
              onTap: () {
                HapticService.selection();
                if (chip.route != null && chip.route!.isNotEmpty) {
                  onRouteTap(chip.route!);
                } else {
                  onSuggestionTap(chip.label);
                }
              },
            ),
            const SizedBox(height: 10),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _GreetingSuggestion extends StatelessWidget {
  final InsightChip chip;
  final ThemeColors colors;
  final Color accent;
  final VoidCallback onTap;

  const _GreetingSuggestion({
    required this.chip,
    required this.colors,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: colors.isDark ? 0.10 : 0.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withValues(alpha: 0.28)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  chip.label,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: accent.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
