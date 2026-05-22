/// Context-aware suggested-question chips for the Cycle screen (Phase F).
///
/// The question set changes with the current phase and tracking mode (see
/// [cycleSuggestedQuestions]); tapping a chip opens the coach chat seeded
/// with that exact question.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../data/models/hormonal_health.dart';
import '../cycle_chat.dart';

class CycleSuggestedChips extends StatelessWidget {
  final CyclePhase? phase;
  final CycleTrackingMode mode;
  final Color accent;

  const CycleSuggestedChips({
    super.key,
    required this.phase,
    required this.mode,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final questions = cycleSuggestedQuestions(phase: phase, mode: mode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.forum_rounded, size: 14, color: accent),
            const SizedBox(width: 6),
            Text(
              'Ask your coach',
              style: TextStyle(
                color: fg.withValues(alpha: 0.6),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Wrap (not Row) so chips reflow on the smallest device.
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < questions.length; i++)
              _Chip(
                label: questions[i],
                accent: accent,
                fg: fg,
                isDark: isDark,
                onTap: () => openCycleChat(context, questions[i]),
              ).animate().fadeIn(
                    delay: (60 * i).ms,
                    duration: 280.ms,
                  ),
          ],
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color accent;
  final Color fg;
  final bool isDark;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.accent,
    required this.fg,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: fg.withValues(alpha: 0.85),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.north_east_rounded, size: 11, color: accent),
          ],
        ),
      ),
    );
  }
}
