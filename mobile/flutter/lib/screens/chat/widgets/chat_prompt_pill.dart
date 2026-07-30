import 'package:flutter/material.dart';

import '../../../core/theme/theme_colors.dart';
import '../../../data/services/haptic_service.dart';

/// The ONE visual treatment for "a thing you can tap to say something to the
/// coach" — empty-state suggestions, quick-action pills above the composer,
/// suggested replies under a coach turn, briefing/greeting chips.
///
/// Before this existed the same viewport carried three different treatments
/// (E2E #33): a grey glass pill with a per-suggestion rainbow icon, an
/// accent-tinted pill, and a horizontally-clipped grey strip. Three looks
/// imply three kinds of thing — they are all prompts. One shape, one tint,
/// one type ramp; the ICON is what differentiates a prompt, not its colour.
///
/// [icon] is optional (a plain text prompt has none). [selected] paints the
/// solid accent fill for a pill that represents an active choice.
class ChatPromptPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  /// Solid-accent variant, for a pill whose state is "on".
  final bool selected;

  /// Dimmed + non-interactive while a request the pill fired is in flight.
  final bool enabled;

  const ChatPromptPill({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.onLongPress,
    this.selected = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    final accent = c.accent;
    final fg = selected ? c.accentContrast : accent;

    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Material(
        color: selected ? accent : accent.withValues(alpha: 0.10),
        shape: StadiumBorder(
          side: BorderSide(
            color: accent.withValues(alpha: selected ? 0.0 : 0.30),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled
              ? () {
                  HapticService.selection();
                  onTap();
                }
              : null,
          onLongPress: enabled ? onLongPress : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 15, color: fg),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
