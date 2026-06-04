/// B9 — Streak timeframe sheet. A bottom sheet that lets the user switch
/// between WEEK / MONTH / ALL views of their streak/progress, with a calendar
/// of active + freeze-protected days, headline streak stats, and freeze
/// balance + "days until next free freeze" progress.
///
/// Matches Gravl's timeframe sheet but adds the freeze-earn cadence rail.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/theme_colors.dart';
import '../data/providers/streak_freeze_provider.dart';
import '../data/services/haptic_service.dart';

/// Show the streak timeframe sheet.
Future<void> showStreakTimeframeSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const StreakTimeframeSheet(),
  );
}

class StreakTimeframeSheet extends ConsumerStatefulWidget {
  const StreakTimeframeSheet({super.key});

  @override
  ConsumerState<StreakTimeframeSheet> createState() =>
      _StreakTimeframeSheetState();
}

class _StreakTimeframeSheetState extends ConsumerState<StreakTimeframeSheet> {
  static const _timeframes = ['week', 'month', 'all'];
  static const _labels = {'week': 'Week', 'month': 'Month', 'all': 'All time'};
  String _selected = 'week';

  static const Color _ice = Color(0xFF4FC3F7);

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    final tf = ref.watch(streakTimeframeProvider(_selected));
    final freeze = ref.watch(streakFreezeStatusProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            // Grabber
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: c.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Text(
                  'Your streak',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: c.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Timeframe segmented control.
            _TimeframeSegments(
              selected: _selected,
              timeframes: _timeframes,
              labels: _labels,
              onSelect: (t) {
                HapticService.light();
                setState(() => _selected = t);
              },
            ),
            const SizedBox(height: 20),

            tf.when(
              data: (data) => _buildBody(c, data),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Text(
                    'Couldn\'t load your streak.',
                    style: TextStyle(color: c.textSecondary),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Freeze cadence rail.
            freeze.maybeWhen(
              data: (f) => _buildFreezeRail(c, f),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ThemeColors c, StreakTimeframe data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                value: '${data.currentStreak}',
                label: 'Current',
                accent: const Color(0xFFFF7043),
                c: c,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                value: '${data.longestStreak}',
                label: 'Longest',
                accent: const Color(0xFFFFD700),
                c: c,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                value: '${data.activeDays}/${data.totalDays}',
                label: 'Active',
                accent: const Color(0xFF66BB6A),
                c: c,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          _labels[data.timeframe] ?? 'Week',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: c.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        _DayGrid(days: data.days, c: c),
        if (data.freezesUsed > 0) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('🧊', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                '${data.freezesUsed} freeze${data.freezesUsed == 1 ? '' : 's'} '
                'protected your streak this ${data.timeframe == 'all' ? 'year' : data.timeframe}',
                style: TextStyle(fontSize: 12, color: c.textSecondary),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildFreezeRail(ThemeColors c, StreakFreezeStatus f) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _ice.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _ice.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🧊', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                '${f.freezesAvailable} streak freeze'
                '${f.freezesAvailable == 1 ? '' : 's'} banked',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: f.progressToNextFreeze,
              minHeight: 8,
              backgroundColor: c.textSecondary.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(_ice),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            f.streakUntilNextFreeze <= 0
                ? 'Your next free freeze is ready.'
                : '${f.streakUntilNextFreeze} more day'
                    '${f.streakUntilNextFreeze == 1 ? '' : 's'} until your next free freeze.',
            style: TextStyle(fontSize: 12, color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _TimeframeSegments extends StatelessWidget {
  final String selected;
  final List<String> timeframes;
  final Map<String, String> labels;
  final ValueChanged<String> onSelect;

  const _TimeframeSegments({
    required this.selected,
    required this.timeframes,
    required this.labels,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.cardBorder),
      ),
      child: Row(
        children: timeframes.map((t) {
          final isSel = t == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSel ? c.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: Text(
                    labels[t] ?? t,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSel ? c.accentContrast : c.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final Color accent;
  final ThemeColors c;

  const _StatTile({
    required this.value,
    required this.label,
    required this.accent,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: c.elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.cardBorder),
      ),
      child: Column(
        children: [
          FittedBox(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: accent,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayGrid extends StatelessWidget {
  final List<StreakTimeframeDay> days;
  final ThemeColors c;

  const _DayGrid({required this.days, required this.c});

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return Text(
        'No activity yet.',
        style: TextStyle(fontSize: 13, color: c.textSecondary),
      );
    }
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: days.map((d) {
        Color fill;
        Color border = Colors.transparent;
        if (d.frozen) {
          fill = const Color(0xFF4FC3F7).withValues(alpha: 0.35);
        } else if (d.active) {
          fill = const Color(0xFFFF7043);
        } else {
          fill = c.textSecondary.withValues(alpha: 0.12);
        }
        if (d.isToday) {
          border = c.accent;
        }
        return Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: border,
              width: d.isToday ? 2 : 0,
            ),
          ),
          child: d.frozen
              ? const Center(
                  child: Text('🧊', style: TextStyle(fontSize: 10)),
                )
              : null,
        );
      }).toList(),
    );
  }
}
