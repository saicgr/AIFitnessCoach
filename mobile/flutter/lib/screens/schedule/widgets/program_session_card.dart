import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/workout.dart';
import 'program_color.dart';

/// Photo-forward, program-aware session card for the agenda.
///
/// There's no per-program cover art field yet, so the background is a
/// deterministic dark gradient derived from the program's [accent] (see
/// [ProgramColors.cardGradient]) — never blank. The title sits in Anton over a
/// bottom scrim, with a colored tag ("HYROX · W1D1") and meta (min · exercises),
/// matching screen A of the v9 mockup.
class ProgramSessionCard extends StatelessWidget {
  final Workout workout;

  /// The program tag, e.g. "HYROX · W1D1" or a fallback like "STRENGTH".
  final String tagLabel;

  /// Resolved program accent (or a type color for non-program workouts).
  final Color accent;

  /// "Main" / "Extra" pill shown on stacked (multi-session) days; null hides it.
  final String? slotBadge;

  /// True when the workout has no curated-program provenance (the always-on AI
  /// program). Surfaces a sparkle "AI" badge mirroring the home hero so the
  /// agenda names a session's source the same way the carousel does.
  final bool isAi;

  /// Slimmer card used for add-on / extra sessions.
  final bool compact;

  final VoidCallback onTap;

  /// When provided AND the session belongs to a curated program (not AI), the
  /// program tag pill becomes tappable and grows a trailing chevron that opens
  /// that program's detail screen — parity with the home hero's program badge.
  final VoidCallback? onOpenProgram;

  const ProgramSessionCard({
    super.key,
    required this.workout,
    required this.tagLabel,
    required this.accent,
    required this.onTap,
    this.slotBadge,
    this.isAi = false,
    this.compact = false,
    this.onOpenProgram,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = workout.isCompleted ?? false;
    final minutes = workout.bestDurationMinutes;
    final exCount = workout.exerciseCount;
    final meta = StringBuffer('$minutes min');
    if (exCount > 0) {
      meta.write(' · $exCount exercise${exCount == 1 ? '' : 's'}');
    }

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: BoxConstraints(minHeight: compact ? 66 : 96),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          // Bottom-align the (non-positioned) content so the title sits low
          // like a photo card — WITHOUT a flex Spacer, which would need a
          // finite height the unbounded ListView item can't supply.
          child: Stack(
            alignment: Alignment.bottomLeft,
            children: [
              // Base gradient + accent glow (stand-in for cover art).
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: ProgramColors.cardGradient(accent),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: ProgramColors.cardGlow(accent),
                  ),
                ),
              ),
              // Bottom scrim for text legibility.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.05),
                        Colors.black.withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                ),
              ),
              // Left accent rail.
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(width: 4, color: accent),
              ),
              // Content.
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 12, 13, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        if (slotBadge != null) ...[
                          _Pill(
                            text: slotBadge!,
                            bg: Colors.white.withValues(alpha: 0.18),
                            fg: Colors.white,
                          ),
                          const SizedBox(width: 6),
                        ],
                        if (isAi) ...[
                          _Pill(
                            text: 'AI',
                            bg: ProgramColors.ai.withValues(alpha: 0.20),
                            fg: Colors.white,
                            icon: Icons.auto_awesome_rounded,
                            iconColor: ProgramColors.ai,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Flexible(child: _buildProgramPill()),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      workout.name ?? 'Workout',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ZType.disp(
                        compact ? 15 : 17,
                        color: Colors.white,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      meta.toString(),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                    ),
                  ],
                ),
              ),
              if (isCompleted)
                Positioned(
                  right: 11,
                  top: 11,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// The program tag pill — tappable with a trailing chevron when there's a
  /// curated program to open (mirrors the home hero badge); plain otherwise.
  Widget _buildProgramPill() {
    final canOpen = onOpenProgram != null && !isAi;
    final pill = _Pill(
      text: tagLabel,
      bg: accent,
      fg: Colors.white,
      trailingIcon: canOpen ? Icons.chevron_right_rounded : null,
    );
    if (!canOpen) return pill;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onOpenProgram,
      child: pill,
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  final IconData? icon;
  final Color? iconColor;
  final IconData? trailingIcon;
  const _Pill({
    required this.text,
    required this.bg,
    required this.fg,
    this.icon,
    this.iconColor,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        icon != null ? 6 : 7,
        3,
        trailingIcon != null ? 4 : 7,
        3,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: iconColor ?? fg),
            const SizedBox(width: 3),
          ],
          Flexible(
            child: Text(
              text.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ZType.lbl(9.5, color: fg, letterSpacing: 0.6),
            ),
          ),
          if (trailingIcon != null) ...[
            const SizedBox(width: 1),
            Icon(trailingIcon, size: 14, color: fg.withValues(alpha: 0.92)),
          ],
        ],
      ),
    );
  }
}

/// Ghosted, dashed-cyan placeholder shown on a training day that an AI program
/// owns but hasn't materialized yet. Tapping triggers the generate-for-date
/// path. Intentionally NOT photo-forward (there's no art) — see mockup screen A
/// Fri / screen B.
class AiPlaceholderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const AiPlaceholderCard({
    super.key,
    required this.onTap,
    this.title = 'AI workout',
    this.subtitle = 'Not yet generated · tap to build now',
  });

  @override
  Widget build(BuildContext context) {
    const cyan = ProgramColors.ai;
    final tc = ThemeColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 66),
        padding: const EdgeInsets.fromLTRB(15, 12, 13, 12),
        decoration: BoxDecoration(
          color: cyan.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cyan.withValues(alpha: 0.45)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: cyan.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                'AI PROGRAM',
                style: ZType.lbl(9.5, color: cyan, letterSpacing: 0.6),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: tc.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11.5, color: tc.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
