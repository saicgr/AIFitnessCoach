/// One row in the Timeline. Renders type icon, title + subtitle, source
/// chip ("Chat" / "Apple Health" / "AI Plan" / etc.), HH:MM timestamp,
/// optional achievement chips, optional coach_note + photo thumbnail.
library;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/timeline_entry.dart';

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

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(_iconFor(entry.icon), color: iconBg, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          entry.title,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _hhmm(entry.occurredAt),
                        style:
                            TextStyle(color: textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                  if (entry.subtitle != null && entry.subtitle!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        entry.subtitle!,
                        style:
                            TextStyle(color: textSecondary, fontSize: 12),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: _SourceChip(
                      source: entry.source,
                      isDark: isDark,
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
                        '💬 ${entry.coachNote}',
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
            if (entry.attachments.isNotEmpty &&
                entry.attachments.first['url'] != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    entry.attachments.first['url'] as String,
                    width: 44,
                    height: 44,
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

class _SourceChip extends StatelessWidget {
  final TimelineSource source;
  final bool isDark;
  const _SourceChip({required this.source, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : Colors.black.withValues(alpha: 0.55);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        source.label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
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
