import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/theme_colors.dart';

/// A collapsible intro education card for the Fasting Guide.
///
/// Collapsed by default: shows only the tinted accent header (icon halo +
/// eyebrow label + title + chevron). Tapping the header expands a smooth
/// animated reveal of the body copy and the key-stat callout chip.
///
/// Each card owns a distinct [accent] color. Cards stagger in with a gentle
/// fade + slide as the screen mounts.
class CollapsibleIntroCard extends StatefulWidget {
  final int index;
  final IconData icon;
  final Color accent;
  final String eyebrow;
  final String title;
  final String body;
  final String stat;
  final String statLabel;

  /// When true the card carries a subtle caution treatment (warning icon in
  /// the header) — used for the "Is it safe?" card.
  final bool isCaution;

  const CollapsibleIntroCard({
    super.key,
    required this.index,
    required this.icon,
    required this.accent,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.stat,
    required this.statLabel,
    this.isCaution = false,
  });

  @override
  State<CollapsibleIntroCard> createState() => _CollapsibleIntroCardState();
}

class _CollapsibleIntroCardState extends State<CollapsibleIntroCard> {
  /// Default state = collapsed.
  bool _expanded = false;

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final dark = colors.isDark;
    final accent = widget.accent;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.30)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: dark ? 0.16 : 0.10),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Tinted header band (always visible, tap to toggle) ─────
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _toggle,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: AlignmentDirectional.topStart,
                      end: AlignmentDirectional.bottomEnd,
                      colors: [
                        accent.withValues(alpha: dark ? 0.32 : 0.20),
                        accent.withValues(alpha: dark ? 0.10 : 0.06),
                      ],
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: accent.withValues(
                            alpha: _expanded ? 0.22 : 0.0),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Large expressive icon with a soft glow halo.
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              accent.withValues(alpha: 0.34),
                              accent.withValues(alpha: 0.12),
                            ],
                          ),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.55),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.35),
                              blurRadius: 14,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Icon(widget.icon, size: 27, color: accent),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.eyebrow.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                                color: accent,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.title,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.isCaution)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 6),
                          child: Icon(Icons.priority_high_rounded,
                              size: 20, color: accent),
                        ),
                      // Chevron rotates as the card expands.
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 24,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // ── Body + key-stat callout (animated expand/collapse) ─────
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity, height: 0),
              secondChild: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.body,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.5,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: dark ? 0.16 : 0.10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.stat,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.statLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 260),
              sizeCurve: Curves.easeOutCubic,
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 450.ms, delay: (widget.index * 110).ms)
        .slideY(begin: 0.10, end: 0, curve: Curves.easeOutCubic);
  }
}
