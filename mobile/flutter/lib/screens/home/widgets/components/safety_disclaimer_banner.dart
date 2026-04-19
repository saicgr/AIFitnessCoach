import 'package:flutter/material.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/services/haptic_service.dart';

/// Non-blocking safety disclaimer card shown at the top of the workout review
/// sheet whenever the user has flagged a significant injury load (≥3) or the
/// backend returned `safety_mode=true` for the generated plan.
///
/// Design intent:
/// - Gentle, informational, never-blocking. The user can dismiss for the
///   current session (state is intentionally NOT persisted — we want it to
///   re-surface on the next regeneration so the user reconfirms risk).
/// - Two visual modes:
///     1. `safetyMode == true` → warning-amber tone, strong PT recommendation.
///     2. `injuryCount >= 3`   → informational tone, soft PT reminder.
/// - Styling reuses theme tokens from `ThemeColors.of(context)` (warning,
///   textPrimary, elevated, cardBorder) — NEVER hardcoded. Adapts to both
///   light and dark mode automatically.
/// - Accessibility-first: labeled via `Semantics`, dismiss has a tooltip,
///   respects `MediaQuery.accessibleNavigation` (skips slide-in animation
///   when reduce-motion is on).
///
/// Composable: drop into any scroll view / column above the sheet content.
/// Returns `SizedBox.shrink()` when nothing needs to be shown so parents
/// can include it unconditionally.
///
/// TODO(i18n): all copy is English-only for v1. Wrap with localization
/// lookups once the app introduces `AppLocalizations`.
class SafetyDisclaimerBanner extends StatefulWidget {
  /// Number of injuries flagged by the user for this regeneration.
  /// Banner is hidden if `< 3` AND `safetyMode` is false.
  final int injuryCount;

  /// Backend-triggered safety mode flag. When true the generator fell back
  /// to a curated PT-mobility plan and we render the stronger amber warning.
  final bool safetyMode;

  /// Optional: list of injury labels to hint to the user WHICH injuries are
  /// influencing the plan (e.g. "shoulder, lower back, knee"). Not required —
  /// when null or empty we fall back to the numeric count only.
  final List<String>? injuryLabels;

  /// Optional: handler for a "Learn more" link (e.g. opens a PT info sheet
  /// or routes to `/settings/medical-disclaimer`). When null the link is
  /// hidden entirely.
  final VoidCallback? onLearnMore;

  const SafetyDisclaimerBanner({
    super.key,
    required this.injuryCount,
    this.safetyMode = false,
    this.injuryLabels,
    this.onLearnMore,
  });

  @override
  State<SafetyDisclaimerBanner> createState() => _SafetyDisclaimerBannerState();
}

class _SafetyDisclaimerBannerState extends State<SafetyDisclaimerBanner>
    with SingleTickerProviderStateMixin {
  // Per-session dismissal state. Intentionally NOT persisted — the banner
  // should re-appear on each regeneration so the user revalidates risk.
  bool _dismissed = false;

  late final AnimationController _animController;
  late final Animation<double> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _slide = Tween<double>(begin: -16, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    // Drive the entrance animation on first frame so it doesn't miss the
    // initial paint. Reduce-motion users will see the card immediately at
    // full opacity — we still call forward() so listeners settle, but the
    // transform is bypassed in build().
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleDismiss() {
    HapticService.light();
    // Run reverse animation then hide. If already dismissed mid-animation
    // this is a no-op.
    _animController.reverse().then((_) {
      if (mounted) setState(() => _dismissed = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Edge case: degrade gracefully when called with no reason to show.
    // This lets parents include the widget unconditionally above the
    // review sheet content.
    if (widget.injuryCount < 3 && !widget.safetyMode) {
      return const SizedBox.shrink();
    }
    if (_dismissed) return const SizedBox.shrink();

    final colors = ThemeColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.of(context).accessibleNavigation;

    // Visual tokens differ per mode. Both modes read from theme — no
    // hardcoded colors.
    final bool isSafetyMode = widget.safetyMode;
    final Color toneColor =
        isSafetyMode ? colors.warning : colors.textSecondary;
    final IconData toneIcon = isSafetyMode
        ? Icons.health_and_safety_outlined
        : Icons.info_outline;

    final String headline = isSafetyMode
        ? 'Safety mode active'
        : '${widget.injuryCount} injuries flagged';

    final String body = isSafetyMode
        ? "With the injuries you've selected, we've built a gentler plan. "
            'We strongly recommend consulting a physical therapist before training.'
        : "This AI plan aims to avoid aggravating those areas, but it's not "
            'a substitute for medical advice. Consider consulting a physical therapist.';

    // Optional injury label strip — only shown if the caller passed labels.
    final bool hasLabels =
        widget.injuryLabels != null && widget.injuryLabels!.isNotEmpty;

    // Background is elevated surface tinted subtly by the tone color so the
    // card integrates with the existing glass/card patterns used across the
    // home screen widgets. Border uses the tone color at low alpha for a
    // gentle outline (stronger in safety mode).
    final double toneAlpha = isSafetyMode ? 0.45 : 0.25;
    final double bgTintAlpha = isSafetyMode ? (isDark ? 0.12 : 0.08) : 0.04;

    final Widget card = Container(
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          toneColor.withValues(alpha: bgTintAlpha),
          colors.elevated,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: toneColor.withValues(alpha: toneAlpha),
          width: 1,
        ),
        boxShadow: isSafetyMode
            ? [
                BoxShadow(
                  color: toneColor.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tone icon — boxed to match the feature-tip banner vocabulary
            // and to give the icon enough visual weight at 24dp.
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: toneColor.withValues(alpha: isDark ? 0.18 : 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(toneIcon, color: toneColor, size: 20),
            ),
            const SizedBox(width: 12),

            // Headline + body + optional labels + optional Learn more link.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    headline,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: colors.textSecondary,
                    ),
                  ),
                  if (hasLabels) ...[
                    const SizedBox(height: 8),
                    _InjuryLabelStrip(
                      labels: widget.injuryLabels!,
                      toneColor: toneColor,
                      textColor: colors.textSecondary,
                    ),
                  ],
                  if (widget.onLearnMore != null) ...[
                    const SizedBox(height: 8),
                    // Using a compact TextButton keeps the tap target
                    // accessible (≥44dp via InkWell internals) without
                    // stealing visual weight from the headline.
                    InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () {
                        HapticService.light();
                        widget.onLearnMore!();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Learn more',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: toneColor,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
                              color: toneColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Dismiss — per-session only. Accessible tooltip + semantics.
            Tooltip(
              message: 'Dismiss disclaimer',
              child: IconButton(
                onPressed: _handleDismiss,
                icon: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: colors.textMuted,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
                splashRadius: 18,
              ),
            ),
          ],
        ),
      ),
    );

    // Screen-reader friendly summary. We combine headline + body so VoiceOver
    // / TalkBack announces the full context with a single focus.
    final semanticsLabel = '$headline. $body';

    final Widget semanticsWrapped = Semantics(
      label: semanticsLabel,
      container: true,
      liveRegion: true,
      child: card,
    );

    // Respect reduce-motion preferences — skip the slide/fade animation
    // entirely when the user has accessibility mode enabled. This is
    // preferable to animating at 0-duration because it also avoids the
    // post-frame callback latency.
    if (reduceMotion) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: semanticsWrapped,
      );
    }

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Transform.translate(
            offset: Offset(0, _slide.value),
            child: Opacity(opacity: _fade.value, child: child),
          ),
        );
      },
      child: semanticsWrapped,
    );
  }
}

/// Compact chip-row that summarizes the selected injury labels. Rendered
/// with `Wrap` so long lists gracefully reflow onto a second row instead of
/// overflowing the card horizontally.
class _InjuryLabelStrip extends StatelessWidget {
  final List<String> labels;
  final Color toneColor;
  final Color textColor;

  const _InjuryLabelStrip({
    required this.labels,
    required this.toneColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    // Defensive: nothing to render.
    if (labels.isEmpty) return const SizedBox.shrink();

    // Cap displayed labels to keep the banner compact — anything beyond the
    // limit is summarized as "+N more". Prevents a 10-injury list from
    // pushing the card taller than the content below it.
    const int maxVisible = 4;
    final int overflow = labels.length - maxVisible;
    final List<String> visible =
        overflow > 0 ? labels.take(maxVisible).toList() : labels;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final label in visible)
          _InjuryChip(label: label, toneColor: toneColor, textColor: textColor),
        if (overflow > 0)
          _InjuryChip(
            label: '+$overflow more',
            toneColor: toneColor,
            textColor: textColor,
          ),
      ],
    );
  }
}

class _InjuryChip extends StatelessWidget {
  final String label;
  final Color toneColor;
  final Color textColor;

  const _InjuryChip({
    required this.label,
    required this.toneColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: toneColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: toneColor.withValues(alpha: 0.28),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
          height: 1.2,
        ),
      ),
    );
  }
}
