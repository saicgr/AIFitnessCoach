import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/cardio_log.dart';
import '../../data/providers/cardio_providers.dart';
import '../../data/providers/habit_provider.dart' show currentUserIdProvider;

/// Cardio history screen — lists Strava/Peloton/Garmin/Apple Health/Fitbit
/// sessions imported into cardio_logs. Tapping a row opens a detail sheet
/// with splits + optional GPS map (renders a compact summary when
/// flutter_map isn't installed, per the plan note).
///
/// Mirrors the shape of the strength-history screen but keyed off
/// activity_type instead of exercise_name.
class CardioHistoryScreen extends ConsumerStatefulWidget {
  const CardioHistoryScreen({super.key});

  @override
  ConsumerState<CardioHistoryScreen> createState() => _CardioHistoryScreenState();
}

class _CardioHistoryScreenState extends ConsumerState<CardioHistoryScreen> {
  String? _activityFilter;
  DateTimeRange? _dateRange;

  // Quick-filter chip order: most common first (running dominates cardio
  // exports globally), machines last. Keeps the common cases one tap away.
  static const List<_ChipOption> _quickFilters = [
    _ChipOption(label: 'All', value: null, emoji: '🏃'),
    _ChipOption(label: 'Run', value: 'run', emoji: '🏃'),
    _ChipOption(label: 'Walk', value: 'walk', emoji: '🚶'),
    _ChipOption(label: 'Hike', value: 'hike', emoji: '🥾'),
    _ChipOption(label: 'Cycle', value: 'cycle', emoji: '🚴'),
    _ChipOption(label: 'Indoor Cycle', value: 'indoor_cycle', emoji: '🚴'),
    _ChipOption(label: 'Row', value: 'row', emoji: '🚣'),
    _ChipOption(label: 'Swim', value: 'swim', emoji: '🏊'),
    _ChipOption(label: 'HIIT', value: 'hiit', emoji: '🥊'),
    _ChipOption(label: 'Yoga', value: 'yoga', emoji: '🧘'),
  ];

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) {
      // Fail-fast rather than rendering an empty history for a logged-out
      // state. The router should gate this screen upstream; this is defense.
      return const Scaffold(
        body: Center(child: Text('Please sign in to see your cardio history.')),
      );
    }

    final filter = CardioLogsFilter(
      userId: userId,
      activityType: _activityFilter,
      from: _dateRange?.start,
      to: _dateRange?.end,
    );

    final logsAsync = ref.watch(cardioLogsProvider(filter));
    final summaryAsync = ref.watch(cardioSummaryProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cardio History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: 'Date range',
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
                lastDate: DateTime.now(),
                initialDateRange: _dateRange,
              );
              if (picked != null) {
                setState(() => _dateRange = picked);
              }
            },
          ),
          if (_dateRange != null)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Clear date filter',
              onPressed: () => setState(() => _dateRange = null),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SummaryHeader(summary: summaryAsync),
          const SizedBox(height: 8),
          SizedBox(
            height: 42,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              itemCount: _quickFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final opt = _quickFilters[idx];
                final selected = _activityFilter == opt.value;
                return FilterChip(
                  label: Text('${opt.emoji} ${opt.label}'),
                  selected: selected,
                  onSelected: (_) => setState(() => _activityFilter = opt.value),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: logsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => _ErrorState(
                message: 'Could not load cardio history',
                detail: err.toString(),
                onRetry: () => ref.invalidate(cardioLogsProvider(filter)),
              ),
              data: (logs) {
                if (logs.isEmpty) {
                  return _EmptyState(hasFilter: _activityFilter != null || _dateRange != null);
                }
                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: logs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) => _CardioRowTile(
                    log: logs[i],
                    onTap: () => _openDetailSheet(context, logs[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openDetailSheet(BuildContext context, CardioLog log) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CardioDetailSheet(log: log),
    );
  }
}


class _SummaryHeader extends StatelessWidget {
  final AsyncValue<CardioSummary> summary;
  const _SummaryHeader({required this.summary});

  @override
  Widget build(BuildContext context) {
    return summary.when(
      loading: () => const SizedBox(
        height: 96,
        child: Center(child: LinearProgressIndicator()),
      ),
      error: (_, __) => const SizedBox(height: 0),  // hide quietly; list below still works
      data: (s) {
        final weeklyKm = (s.weeklyDistanceM / 1000).toStringAsFixed(1);
        final totalKm = (s.totalDistanceM / 1000).toStringAsFixed(0);
        final totalHours = (s.totalDurationSeconds / 3600).toStringAsFixed(0);
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primaryContainer,
                Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.7),
              ],
            ),
          ),
          child: Row(
            children: [
              Expanded(child: _StatBox(label: 'This week', value: '$weeklyKm km', sub: '${s.weeklySessions} sessions')),
              Expanded(child: _StatBox(label: 'All-time', value: '$totalKm km', sub: '$totalHours h')),
              Expanded(child: _StatBox(label: 'Sessions', value: s.totalSessions.toString(), sub: '${s.perActivity.length} activities')),
            ],
          ),
        );
      },
    );
  }
}


class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  const _StatBox({required this.label, required this.value, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 2),
        Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        Text(sub, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.black54)),
      ],
    );
  }
}


class _CardioRowTile extends StatelessWidget {
  final CardioLog log;
  final VoidCallback onTap;
  const _CardioRowTile({required this.log, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final d = log.performedAtLocal;
    final dateStr = '${d.month}/${d.day}/${d.year}';
    final parts = <String>[
      log.formatDuration(),
      if (log.formatDistanceKm() != null) log.formatDistanceKm()!,
      if (log.avgHeartRate != null) '${log.avgHeartRate} bpm',
      if (log.calories != null) '${log.calories} cal',
    ];

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        child: Text(log.iconEmoji, style: const TextStyle(fontSize: 20)),
      ),
      title: Text(
        _activityLabel(log.activityType),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text('$dateStr  ·  ${parts.join('  ·  ')}'),
      trailing: Text(
        log.sourceApp,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.black54),
      ),
      onTap: onTap,
    );
  }
}


String _activityLabel(String activityType) {
  // Underscore-to-title-case; 'indoor_cycle' → 'Indoor Cycle'.
  return activityType.split('_').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
}


class _CardioDetailSheet extends StatelessWidget {
  final CardioLog log;
  const _CardioDetailSheet({required this.log});

  @override
  Widget build(BuildContext context) {
    final splits = log.splitsJson ?? const <Map<String, dynamic>>[];
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(log.iconEmoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_activityLabel(log.activityType),
                          style: Theme.of(context).textTheme.titleLarge),
                      Text(
                        log.performedAtLocal.toString().substring(0, 16),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Chip(label: Text(log.sourceApp)),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                _DetailStat(label: 'Duration', value: log.formatDuration()),
                if (log.formatDistanceKm() != null)
                  _DetailStat(label: 'Distance', value: log.formatDistanceKm()!),
                if (log.formatPacePerKm() != null)
                  _DetailStat(label: 'Avg pace', value: log.formatPacePerKm()!),
                if (log.formatSpeedKmh() != null)
                  _DetailStat(label: 'Avg speed', value: log.formatSpeedKmh()!),
                if (log.avgHeartRate != null)
                  _DetailStat(label: 'Avg HR', value: '${log.avgHeartRate} bpm'),
                if (log.maxHeartRate != null)
                  _DetailStat(label: 'Max HR', value: '${log.maxHeartRate} bpm'),
                if (log.avgWatts != null)
                  _DetailStat(label: 'Avg watts', value: '${log.avgWatts} W'),
                if (log.calories != null)
                  _DetailStat(label: 'Calories', value: log.calories.toString()),
                if (log.elevationGainM != null)
                  _DetailStat(
                    label: 'Elevation',
                    value: '${log.elevationGainM!.toStringAsFixed(0)} m',
                  ),
                if (log.rpe != null)
                  _DetailStat(label: 'RPE', value: log.rpe!.toStringAsFixed(1)),
              ],
            ),
            if (log.notes != null && log.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Notes', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(log.notes!),
            ],
            if (splits.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Splits', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              for (final split in splits) _SplitRow(split: split),
            ],
            if (log.gpsPolyline != null && log.gpsPolyline!.isNotEmpty) ...[
              const SizedBox(height: 16),
              // NOTE: `flutter_map` + `polyline_decoder` aren't in pubspec.
              // Per the plan, render a summary + polyline length chip rather
              // than blocking the whole sheet on a map dep. The raw polyline
              // stays in the model for when those deps get added.
              Row(
                children: [
                  const Icon(Icons.map_outlined, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Route recorded (${log.gpsPolyline!.length} pts)',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}


class _SplitRow extends StatelessWidget {
  final Map<String, dynamic> split;
  const _SplitRow({required this.split});

  @override
  Widget build(BuildContext context) {
    // Handle both the per-km splits shape (generic_gpx: {km, seconds, pace_seconds_per_km})
    // and the lap shape (garmin_tcx / garmin_fit: {lap, lap_seconds, lap_distance_m, pace_seconds_per_km}).
    final labelParts = <String>[];
    if (split['km'] != null) labelParts.add('km ${split['km']}');
    if (split['lap'] != null) labelParts.add('lap ${split['lap']}');
    final duration = (split['seconds'] ?? split['lap_seconds']) as num?;
    final pace = (split['pace_seconds_per_km']) as num?;

    String fmtSecs(num sec) {
      final total = sec.round();
      final m = total ~/ 60;
      final s = total % 60;
      return '$m:${s.toString().padLeft(2, '0')}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(labelParts.join('  ·  '))),
          if (duration != null) Text(fmtSecs(duration)),
          if (pace != null) ...[
            const SizedBox(width: 12),
            Text('${fmtSecs(pace)} /km',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}


class _DetailStat extends StatelessWidget {
  final String label;
  final String value;
  const _DetailStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 2),
        Text(value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                )),
      ],
    );
  }
}


class _EmptyState extends StatelessWidget {
  final bool hasFilter;
  const _EmptyState({required this.hasFilter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏃', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              hasFilter
                  ? 'No sessions match this filter.'
                  : 'No cardio sessions yet.',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              hasFilter
                  ? 'Try clearing filters or widening the date range.'
                  : 'Import from Strava, Peloton, Garmin, Apple Health, or Fitbit to see your history here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}


class _ErrorState extends StatelessWidget {
  final String message;
  final String detail;
  final VoidCallback onRetry;
  const _ErrorState({
    required this.message,
    required this.detail,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(message, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}


class _ChipOption {
  final String label;
  final String? value;
  final String emoji;
  const _ChipOption({required this.label, required this.value, required this.emoji});
}
