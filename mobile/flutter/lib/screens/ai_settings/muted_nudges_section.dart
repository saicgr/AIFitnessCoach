/// Lists the nudge types the user permanently muted via "Always hide this"
/// (the swipe-to-delete snackbar action or the explainer sheet). Each row has
/// an X to restore a single type; a "Restore all" button clears the lot.
///
/// Renders nothing when no nudge is muted, so the AI Settings screen has no
/// empty placeholder section. Mounted right after [NudgePrioritySection] in
/// [AISettingsScreen]; reads + writes through [coachUiSettingsProvider].
///
/// This is distinct from the category-priority reorder above it: that
/// re-weights whole *categories*, this hides individual *types*.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/models/contextual_nudge.dart' show NudgeId;
import '../../data/providers/ai_settings_provider.dart';

/// Humanise a [NudgeId] enum name into a readable label. There is no central
/// id→title map (titles live on each constructed nudge), so we split the
/// camelCase enum name into Title Case words. e.g. `postWorkoutProtein` →
/// "Post Workout Protein".
String nudgeDisplayLabel(NudgeId id) {
  final name = id.name;
  final buf = StringBuffer();
  for (var i = 0; i < name.length; i++) {
    final ch = name[i];
    final isUpper = ch.toUpperCase() == ch && ch.toLowerCase() != ch;
    if (i > 0 && isUpper) buf.write(' ');
    buf.write(ch);
  }
  return buf
      .toString()
      .split(' ')
      .map((w) => w.isEmpty
          ? w
          : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

class MutedNudgesSection extends ConsumerWidget {
  const MutedNudgesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ThemeColors.of(context);
    final muted = ref.watch(
      coachUiSettingsProvider.select((s) => s.mutedNudgeIds),
    );
    if (muted.isEmpty) return const SizedBox.shrink();

    // Resolve names back to live NudgeIds, sorted for a stable order.
    final byName = {for (final id in NudgeId.values) id.name: id};
    final ids = muted
        .map((n) => byName[n])
        .whereType<NudgeId>()
        .toList()
      ..sort((a, b) => nudgeDisplayLabel(a).compareTo(nudgeDisplayLabel(b)));
    if (ids.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'HIDDEN NUDGES',
                  style: ZType.lbl(11.5, color: c.textMuted, letterSpacing: 2.0),
                ),
              ),
              TextButton(
                onPressed: () => ref
                    .read(coachUiSettingsProvider.notifier)
                    .clearMutedNudges(),
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 28),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(
                  'Restore all',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: c.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Types you chose to always hide. Tap the X to bring one back. '
            '(This hides individual nudges; the list above re-orders whole '
            'categories.)',
            style: TextStyle(
              fontSize: 11.5,
              color: c.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          DecoratedBox(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.cardBorder),
            ),
            child: Column(
              children: [
                for (var i = 0; i < ids.length; i++)
                  _MutedRow(
                    id: ids[i],
                    isLast: i == ids.length - 1,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MutedRow extends ConsumerWidget {
  final NudgeId id;
  final bool isLast;
  const _MutedRow({required this.id, required this.isLast});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ThemeColors.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isLast ? Colors.transparent : c.cardBorder,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.notifications_off_outlined, size: 18, color: c.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              nudgeDisplayLabel(id),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 18, color: c.textMuted),
            onPressed: () =>
                ref.read(coachUiSettingsProvider.notifier).unmuteNudge(id),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            tooltip: 'Restore',
          ),
        ],
      ),
    );
  }
}
