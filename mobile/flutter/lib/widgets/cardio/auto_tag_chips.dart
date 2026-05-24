import 'package:flutter/material.dart';

import '../../core/theme/accent_color_provider.dart';

/// Horizontal Wrap of "vibe" chips for a cardio session — Hill workout,
/// Negative split, New route, Dawn run, Dusk run, PR session.
///
/// Backed by `cardio_logs.tags` / `cardio_sessions.tags` (migration 2094).
/// Tags are computed server-side by `cardio_autotag_service.py` and may be
/// recomputed via `POST /cardio-logs/{id}/recompute-tags`.
///
/// Composition note: this widget is owned by SLICE_AUTOTAGS. The synced
/// workout detail screen (where the chips render) is wired up by a later
/// agent — that agent imports this widget and passes the row's `tags` list.
///
/// Layout uses `Wrap` so chips reflow on narrow screens (per
/// `feedback_no_overflow_adaptive_screens.md`). Empty list collapses to
/// `SizedBox.shrink` so we don't eat layout space when nothing applies.
class AutoTagChips extends StatelessWidget {
  final List<String> tags;

  /// Optional override for spacing between chips.
  final double spacing;

  /// Optional override for vertical runSpacing in the Wrap.
  final double runSpacing;

  const AutoTagChips({
    super.key,
    required this.tags,
    this.spacing = 6,
    this.runSpacing = 6,
  });

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);

    // Filter to known tags only — defensive in case the server ships a tag
    // we don't have a UI mapping for yet (forward-compatible).
    final knownTags = tags.where(_tagMeta.containsKey).toList();
    if (knownTags.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: [
        for (final tag in knownTags)
          _AutoTagChip(
            meta: _tagMeta[tag]!,
            accent: accent,
            isDark: isDark,
          ),
      ],
    );
  }
}

/// Static metadata for each tag. Kept top-level so other surfaces (e.g.
/// the Wrapped recap) can render the same icon + label without duplicating
/// the mapping.
class _TagMeta {
  final String emoji;
  final String label;
  final Color tint;
  const _TagMeta(this.emoji, this.label, this.tint);
}

const Map<String, _TagMeta> _tagMeta = {
  'is_hill_workout': _TagMeta('🏔', 'Hill workout', Color(0xFF8B6F47)), // earthy brown
  'is_negative_split': _TagMeta('📈', 'Negative split', Color(0xFF4ADE80)), // accent green
  'is_new_route': _TagMeta('🌄', 'New route', Color(0xFF38BDF8)), // accent blue
  'is_dawn_run': _TagMeta('🌅', 'Dawn run', Color(0xFFFB923C)), // orange
  'is_dusk_run': _TagMeta('🌇', 'Dusk run', Color(0xFFA855F7)), // purple
  'is_pr_session': _TagMeta('🏆', 'PR session', Color(0xFFFBBF24)), // gold
};

class _AutoTagChip extends StatelessWidget {
  final _TagMeta meta;
  final Color accent;
  final bool isDark;

  const _AutoTagChip({
    required this.meta,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Blend the tag's semantic tint with the user's accent so chips feel
    // cohesive with the rest of the app's color scheme but still readable
    // as distinct categories.
    final base = Color.lerp(meta.tint, accent, 0.18) ?? meta.tint;
    final bg = base.withValues(alpha: isDark ? 0.16 : 0.10);
    final border = base.withValues(alpha: isDark ? 0.45 : 0.30);
    final fg = isDark ? base.withValues(alpha: 0.95) : _darken(base, 0.20);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(meta.emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            meta.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Color _darken(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    final l = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(l).toColor();
  }
}
