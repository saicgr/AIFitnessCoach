/// One row in the Timeline. Renders type icon, title + subtitle, source
/// chip ("Chat" / "Apple Health" / "AI Plan" / etc.), HH:MM timestamp,
/// optional achievement chips, optional coach_note + photo thumbnail.
library;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/timeline_entry.dart';
import '../../../l10n/generated/app_localizations.dart';

class TimelineEntryTile extends StatelessWidget {
  final TimelineEntry entry;
  final Color accent;
  final bool isDark;
  final VoidCallback onTap;

  const TimelineEntryTile({
    super.key,
    required this.entry,
    required this.accent,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final iconBg = _domainColor(entry.type);

    // Samsung-Health-style 3-column layout (matches Image 19 reference):
    //   ┌────────┬──────────────────────┬──────────┐
    //   │ 16:58  │ Afternoon walk       │  ⊙ icon  │
    //   │ Zepp   │ 0.49 mi · 24 min     │  (right) │
    //   │        │ [PR chips]           │          │
    //   └────────┴──────────────────────┴──────────┘
    //
    // The icon used to sit on the LEFT (in front of the title) which read
    // as a Material list-tile rather than a journal feed. Moving it to the
    // right rail mirrors the Samsung Health UX the user pointed at, and
    // freeing the left rail makes time + source the primary anchor for
    // scanning a long chronological feed.
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Left rail: HH:MM + source label ──────────────────────────
            SizedBox(
              width: 56,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _hhmm(entry.occurredAt),
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.source.label,
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // ── Middle: title + subtitle + achievement chips ────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (entry.subtitle != null && entry.subtitle!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        entry.subtitle!,
                        style:
                            TextStyle(color: textSecondary, fontSize: 12.5),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if ((entry.metadata['during'] is String) &&
                      (entry.metadata['during'] as String).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'During ${entry.metadata['during']}',
                        style: TextStyle(
                            color: textSecondary,
                            fontSize: 11,
                            fontStyle: FontStyle.italic),
                      ),
                    ),
                  if (entry.coachNote != null && entry.coachNote!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        AppLocalizations.of(context)!.timelineEntryTileValue(entry.coachNote ?? ''),
                        style: TextStyle(
                            color: textSecondary,
                            fontSize: 11,
                            fontStyle: FontStyle.italic),
                      ),
                    ),
                  if (entry.achievementChips.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: entry.achievementChips
                            .take(3)
                            .map((a) => _AchievementChip(achievement: a))
                            .toList(growable: false),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // ── Right: type-coloured circular icon badge ─────────────────
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(_iconFor(entry.icon), color: iconBg, size: 20),
            ),
            // Attachment thumbnail (food photo, progress pic) — only shown
            // when present, sits flush to the icon so the right rail stays
            // visually balanced.
            if (entry.attachments.isNotEmpty &&
                entry.attachments.first['url'] != null)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    entry.attachments.first['url'] as String,
                    width: 44,
                    height: 44,
                    // Decode to ~2x the 44px render box instead of full source
                    // resolution — a full-res food/progress JPEG decoded to a
                    // 44px thumb wastes decode time + image cache memory.
                    cacheWidth: 88,
                    cacheHeight: 88,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const SizedBox(width: 44, height: 44),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static Color _domainColor(String type) {
    switch (type) {
      case 'workout':
        return Colors.deepPurple;
      case 'sleep':
        return Colors.indigo;
      case 'food':
        return Colors.orange;
      case 'water':
        return Colors.blue;
      case 'weight':
        return Colors.green;
      case 'mood':
        return Colors.amber;
      case 'habit':
        return Colors.teal;
      case 'achievement':
        return Colors.pinkAccent;
      default:
        return Colors.grey;
    }
  }

  /// Map backend Material icon names to Flutter IconData.
  static IconData _iconFor(String name) {
    switch (name) {
      case 'fitness_center':
        return Icons.fitness_center;
      case 'self_improvement':
        return Icons.self_improvement;
      case 'directions_walk':
        return Icons.directions_walk;
      case 'directions_run':
        return Icons.directions_run;
      case 'directions_bike':
        return Icons.directions_bike;
      case 'pool':
        return Icons.pool;
      case 'rowing':
        return Icons.rowing;
      case 'sports_basketball':
        return Icons.sports_basketball;
      case 'sports_soccer':
        return Icons.sports_soccer;
      case 'sports_tennis':
        return Icons.sports_tennis;
      case 'sports_mma':
        return Icons.sports_mma;
      case 'sports_golf':
        return Icons.sports_golf;
      case 'terrain':
        return Icons.terrain;
      case 'bolt':
        return Icons.bolt;
      case 'restaurant':
        return Icons.restaurant;
      case 'water_drop':
        return Icons.water_drop;
      case 'bedtime':
        return Icons.bedtime;
      case 'monitor_weight':
        return Icons.monitor_weight;
      case 'mood':
        return Icons.mood;
      case 'check_circle':
        return Icons.check_circle;
      case 'spa':
        return Icons.spa;
      case 'accessibility':
        return Icons.accessibility;
      case 'accessibility_new':
        return Icons.accessibility_new;
      case 'stairs':
        return Icons.stairs;
      case 'snowboarding':
        return Icons.snowboarding;
      case 'downhill_skiing':
        return Icons.downhill_skiing;
      case 'surfing':
        return Icons.surfing;
      case 'music_note':
        return Icons.music_note;
      case 'sports_volleyball':
        return Icons.sports_volleyball;
      case 'sports_football':
        return Icons.sports_football;
      case 'sports_handball':
        return Icons.sports_handball;
      case 'emoji_events':
        return Icons.emoji_events;
      case 'trending_up':
        return Icons.trending_up;
      default:
        return Icons.timeline;
    }
  }

  static String _hhmm(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return '';
    }
  }
}

class _AchievementChip extends StatelessWidget {
  final TimelineAchievement achievement;
  const _AchievementChip({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final isPR = achievement.kind.contains('pr');
    final color = isPR ? Colors.amber.shade700 : Colors.deepOrange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        achievement.label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
