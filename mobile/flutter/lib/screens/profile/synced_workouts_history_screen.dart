import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/synced_workout_kinds.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../data/models/workout.dart';
import '../../data/providers/synced_workouts_provider.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/pill_app_bar.dart';
import '../../widgets/synced/kind_avatar.dart';
import '../../widgets/synced/metric_chip.dart';
import 'synced_workout_detail_screen.dart';

/// Full-screen list of every synced workout, with aggregate stats header,
/// per-kind donut, 90-day activity heatmap, PR tiles, filter chips, and
/// date-grouped list tiles.
class SyncedWorkoutsHistoryScreen extends ConsumerStatefulWidget {
  const SyncedWorkoutsHistoryScreen({super.key});

  @override
  ConsumerState<SyncedWorkoutsHistoryScreen> createState() =>
      _SyncedWorkoutsHistoryScreenState();
}

class _SyncedWorkoutsHistoryScreenState
    extends ConsumerState<SyncedWorkoutsHistoryScreen> {
  SyncedKind? _selectedKind;

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(syncedWorkoutsProvider);
    final filtered = _selectedKind == null
        ? all
        : all.where((w) {
            final meta = w.generationMetadata ?? {};
            final kind = SyncedKind.fromString(
              meta['hc_activity_kind'] as String? ?? w.type,
            );
            return kind == _selectedKind;
          }).toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary = isDark ? Colors.white : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final breakdown = _breakdownByKind(all);
    final personalRecords = _computePersonalRecords(all);

    return Scaffold(
      backgroundColor: background,
      appBar: const PillAppBar(title: 'Synced Workouts'),
      body: all.isEmpty
          ? _emptyState(textPrimary, textMuted)
          : ListView(
              padding: const EdgeInsets.only(bottom: 40),
              children: [
                _AggregateStatsHeader(workouts: filtered),
                if (breakdown.length >= 2)
                  _PerKindDonut(breakdown: breakdown),
                _HeatmapCalendarCard(workouts: all),
                if (personalRecords.isNotEmpty)
                  _PersonalRecordsRow(records: personalRecords),
                _FilterChipsRow(
                  allWorkouts: all,
                  selected: _selectedKind,
                  onSelect: (k) {
                    HapticService.selection();
                    setState(() => _selectedKind = k);
                  },
                ),
                ..._buildGroupedList(filtered),
              ],
            ),
    );
  }

  Widget _emptyState(Color primary, Color muted) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sync_rounded, size: 44, color: muted),
            const SizedBox(height: 12),
            Text(
              'No synced workouts yet',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Connect Health Connect or Apple Health from Settings to import '
              'activity from your watch or fitness tracker.',
              style: TextStyle(fontSize: 13, color: muted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGroupedList(List<Workout> workouts) {
    // Group by date (YYYY-MM-DD), already sorted descending in provider.
    final groups = <String, List<Workout>>{};
    for (final w in workouts) {
      final key = (w.scheduledDate ?? '').split('T').first;
      groups.putIfAbsent(key, () => []).add(w);
    }
    final keys = groups.keys.toList()..sort((a, b) => b.compareTo(a));
    final out = <Widget>[];
    for (final k in keys) {
      out.add(_DateHeader(dateIso: k));
      for (final w in groups[k]!) {
        out.add(_HistoryListTile(workout: w));
      }
    }
    return out;
  }

  Map<SyncedKind, int> _breakdownByKind(List<Workout> workouts) {
    final out = <SyncedKind, int>{};
    for (final w in workouts) {
      final meta = w.generationMetadata ?? {};
      final kind = SyncedKind.fromString(
          meta['hc_activity_kind'] as String? ?? w.type);
      final minutes = w.durationMinutes ?? 0;
      out[kind] = (out[kind] ?? 0) + minutes;
    }
    return out;
  }

  List<_PersonalRecord> _computePersonalRecords(List<Workout> workouts) {
    final byKind = <SyncedKind, List<Workout>>{};
    for (final w in workouts) {
      final meta = w.generationMetadata ?? {};
      final kind = SyncedKind.fromString(
          meta['hc_activity_kind'] as String? ?? w.type);
      byKind.putIfAbsent(kind, () => []).add(w);
    }

    final prs = <_PersonalRecord>[];
    byKind.forEach((kind, list) {
      final pr = _prForKind(kind, list);
      if (pr != null) prs.add(pr);
    });
    return prs.take(6).toList();
  }

  _PersonalRecord? _prForKind(SyncedKind kind, List<Workout> list) {
    if (list.isEmpty) return null;
    switch (kind) {
      case SyncedKind.walking:
      case SyncedKind.hiking:
        // Longest distance
        Workout best = list.first;
        double bestM = 0;
        for (final w in list) {
          final d = (w.generationMetadata?['distance_m']
                  ?? w.generationMetadata?['distance_meters']) as num?;
          if (d != null && d > bestM) {
            bestM = d.toDouble();
            best = w;
          }
        }
        if (bestM <= 0) return null;
        final miles = bestM * 0.000621371;
        return _PersonalRecord(
          kind: kind,
          label: kind == SyncedKind.walking ? 'Longest walk' : 'Longest hike',
          value: '${miles.toStringAsFixed(miles >= 10 ? 1 : 2)} mi',
          workout: best,
        );
      case SyncedKind.running:
        // Fastest pace
        Workout best = list.first;
        double bestPace = double.infinity;
        for (final w in list) {
          final p = w.generationMetadata?['pace_sec_per_km'] as num?;
          if (p != null && p > 0 && p < bestPace) {
            bestPace = p.toDouble();
            best = w;
          }
        }
        if (bestPace.isInfinite) return null;
        final secPerMi = bestPace * 1.609344;
        final m = secPerMi ~/ 60;
        final s = (secPerMi % 60).round();
        return _PersonalRecord(
          kind: kind,
          label: 'Fastest mile',
          value: '$m:${s.toString().padLeft(2, '0')}',
          workout: best,
        );
      case SyncedKind.cycling:
        Workout best = list.first;
        double bestElev = 0;
        for (final w in list) {
          final e = w.generationMetadata?['elevation_gain_m'] as num?;
          if (e != null && e > bestElev) {
            bestElev = e.toDouble();
            best = w;
          }
        }
        if (bestElev <= 0) {
          // Fall back to longest ride
          double bestM = 0;
          for (final w in list) {
            final d = (w.generationMetadata?['distance_m']
                    ?? w.generationMetadata?['distance_meters']) as num?;
            if (d != null && d > bestM) {
              bestM = d.toDouble();
              best = w;
            }
          }
          if (bestM <= 0) return null;
          final miles = bestM * 0.000621371;
          return _PersonalRecord(
            kind: kind,
            label: 'Longest ride',
            value: '${miles.toStringAsFixed(miles >= 10 ? 1 : 2)} mi',
            workout: best,
          );
        }
        return _PersonalRecord(
          kind: kind,
          label: 'Biggest climb',
          value: '${bestElev.round()} m',
          workout: best,
        );
      case SyncedKind.hiit:
        Workout best = list.first;
        double bestZ4plus = 0;
        for (final w in list) {
          final zones = w.generationMetadata?['hr_zones_pct'] as Map?;
          if (zones != null) {
            final z4 = (zones['4'] as num?)?.toDouble() ?? 0;
            final z5 = (zones['5'] as num?)?.toDouble() ?? 0;
            final z = z4 + z5;
            if (z > bestZ4plus) {
              bestZ4plus = z;
              best = w;
            }
          }
        }
        if (bestZ4plus <= 0) return null;
        return _PersonalRecord(
          kind: kind,
          label: 'Hardest session',
          value: '${bestZ4plus.round()}% Z4+',
          workout: best,
        );
      default:
        // Longest session for strength / other
        Workout best = list.first;
        int bestMin = 0;
        for (final w in list) {
          final m = w.durationMinutes ?? 0;
          if (m > bestMin) {
            bestMin = m;
            best = w;
          }
        }
        if (bestMin <= 0) return null;
        final m = bestMin;
        final label = m >= 60
            ? '${m ~/ 60}h ${m % 60}m'
            : '${m}m';
        return _PersonalRecord(
          kind: kind,
          label: 'Longest session',
          value: label,
          workout: best,
        );
    }
  }
}

// ---------------------------------------------------------------------------
// Aggregate stats header (4 numbers with count-up)
// ---------------------------------------------------------------------------

class _AggregateStatsHeader extends StatelessWidget {
  final List<Workout> workouts;

  const _AggregateStatsHeader({required this.workouts});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final border = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06);
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accent = AccentColorScope.of(context).getColor(isDark);

    int totalSessions = workouts.length;
    int totalMinutes = 0;
    double totalMeters = 0;
    double totalCals = 0;
    for (final w in workouts) {
      totalMinutes += w.durationMinutes ?? 0;
      final meta = w.generationMetadata ?? {};
      final d = (meta['distance_m'] ?? meta['distance_meters']) as num?;
      if (d != null) totalMeters += d.toDouble();
      final c = (meta['calories_active'] ?? meta['calories_burned']) as num?;
      if (c != null) totalCals += c.toDouble();
    }
    final miles = totalMeters * 0.000621371;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _CountUpStat(
                    target: totalSessions.toDouble(),
                    formatter: (v) => v.toInt().toString(),
                    label: 'Sessions',
                    accent: accent,
                    textMuted: textMuted,
                  ),
                ),
                Expanded(
                  child: _CountUpStat(
                    target: miles,
                    formatter: (v) => v >= 100
                        ? v.round().toString()
                        : v.toStringAsFixed(v >= 10 ? 1 : 2),
                    label: 'Miles',
                    accent: accent,
                    textMuted: textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _CountUpStat(
                    target: totalMinutes.toDouble(),
                    formatter: (v) => _formatMinutes(v.toInt()),
                    label: 'Active',
                    accent: accent,
                    textMuted: textMuted,
                  ),
                ),
                Expanded(
                  child: _CountUpStat(
                    target: totalCals,
                    formatter: (v) => v >= 1000
                        ? '${(v / 1000).toStringAsFixed(1)}k'
                        : v.round().toString(),
                    label: 'Calories',
                    accent: accent,
                    textMuted: textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatMinutes(int min) {
    if (min >= 60) {
      final h = min ~/ 60;
      final m = min % 60;
      return m == 0 ? '${h}h' : '${h}h ${m}m';
    }
    return '${min}m';
  }
}

class _CountUpStat extends StatefulWidget {
  final double target;
  final String Function(double) formatter;
  final String label;
  final Color accent;
  final Color textMuted;

  const _CountUpStat({
    required this.target,
    required this.formatter,
    required this.label,
    required this.accent,
    required this.textMuted,
  });

  @override
  State<_CountUpStat> createState() => _CountUpStatState();
}

class _CountUpStatState extends State<_CountUpStat>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    duration: const Duration(milliseconds: 1200),
    vsync: this,
  );

  @override
  void initState() {
    super.initState();
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = Curves.easeOutExpo.transform(_c.value);
        final value = widget.target * t;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.formatter(value),
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: widget.accent,
                height: 1.05,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.label,
              style: TextStyle(fontSize: 11, color: widget.textMuted),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Per-kind donut + legend
// ---------------------------------------------------------------------------

class _PerKindDonut extends StatelessWidget {
  final Map<SyncedKind, int> breakdown; // kind → minutes

  const _PerKindDonut({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final border = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06);
    final textPrimary = isDark ? Colors.white : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final sorted = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = sorted.fold<int>(0, (a, e) => a + e.value);
    if (total == 0) return const SizedBox.shrink();

    final sections = <PieChartSectionData>[];
    for (final e in sorted) {
      final palette = e.key.palette(isDark);
      sections.add(PieChartSectionData(
        value: e.value.toDouble(),
        color: palette.fg,
        radius: 18,
        showTitle: false,
      ));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 84,
              height: 84,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 26,
                  sectionsSpace: 2,
                  startDegreeOffset: -90,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Breakdown',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textPrimary),
                  ),
                  const SizedBox(height: 6),
                  for (final e in sorted.take(5))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: e.key.palette(isDark).fg,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              e.key.label,
                              style: TextStyle(
                                  fontSize: 12, color: textPrimary),
                            ),
                          ),
                          Text(
                            '${(e.value / total * 100).round()}% · ${e.value}m',
                            style: TextStyle(fontSize: 11, color: textMuted),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 90-day heatmap calendar
// ---------------------------------------------------------------------------

class _HeatmapCalendarCard extends StatelessWidget {
  final List<Workout> workouts;

  const _HeatmapCalendarCard({required this.workouts});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final border = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06);
    final textPrimary = isDark ? Colors.white : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final emptyCell = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04);

    // Build day buckets
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(const Duration(days: 89));
    final dayMinutes = <String, double>{};
    final dayDominantKind = <String, SyncedKind>{};
    final dayKindMinutes = <String, Map<SyncedKind, double>>{};
    for (final w in workouts) {
      final iso = (w.scheduledDate ?? '').split('T').first;
      if (iso.isEmpty) continue;
      final d = DateTime.tryParse(iso);
      if (d == null) continue;
      if (d.isBefore(start) || d.isAfter(today)) continue;
      final key =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final mins = (w.durationMinutes ?? 0).toDouble();
      dayMinutes[key] = (dayMinutes[key] ?? 0) + mins;
      final meta = w.generationMetadata ?? {};
      final kind = SyncedKind.fromString(
          meta['hc_activity_kind'] as String? ?? w.type);
      final km = dayKindMinutes.putIfAbsent(key, () => {});
      km[kind] = (km[kind] ?? 0) + mins;
    }
    dayKindMinutes.forEach((k, m) {
      var best = m.entries.first;
      for (final e in m.entries) {
        if (e.value > best.value) best = e;
      }
      dayDominantKind[k] = best.key;
    });

    // Max minutes used for intensity scaling
    double maxDayMinutes = 30;
    for (final v in dayMinutes.values) {
      if (v > maxDayMinutes) maxDayMinutes = v;
    }

    // Grid: 13 weeks × 7 days, newest on the right
    // Column = week (0..12), Row = day-of-week (0..6, Mon..Sun)
    const weeks = 13;
    final cells = <Widget>[];
    for (int row = 0; row < 7; row++) {
      for (int col = 0; col < weeks; col++) {
        final daysFromToday = (weeks - 1 - col) * 7 + (6 - row);
        final date = today.subtract(Duration(days: daysFromToday));
        final key =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final mins = dayMinutes[key];
        final kind = dayDominantKind[key];
        final color = mins == null || kind == null
            ? emptyCell
            : kind.palette(isDark).fg.withValues(
                  alpha: (0.25 + (mins / maxDayMinutes) * 0.65).clamp(0.25, 0.9),
                );
        cells.add(Container(
          width: 14,
          height: 14,
          margin: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ));
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Last 90 days',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textPrimary),
                ),
                Row(
                  children: [
                    Text(
                      'Less',
                      style: TextStyle(fontSize: 10, color: textMuted),
                    ),
                    const SizedBox(width: 6),
                    for (final a in [0.25, 0.45, 0.65, 0.9])
                      Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: (AccentColorScope.of(context).getColor(isDark))
                              .withValues(alpha: a),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    const SizedBox(width: 6),
                    Text(
                      'More',
                      style: TextStyle(fontSize: 10, color: textMuted),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 7 * 17,
              child: GridView.count(
                crossAxisCount: weeks,
                physics: const NeverScrollableScrollPhysics(),
                children: cells,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Personal records row
// ---------------------------------------------------------------------------

class _PersonalRecord {
  final SyncedKind kind;
  final String label;
  final String value;
  final Workout workout;

  const _PersonalRecord({
    required this.kind,
    required this.label,
    required this.value,
    required this.workout,
  });
}

class _PersonalRecordsRow extends StatelessWidget {
  final List<_PersonalRecord> records;

  const _PersonalRecordsRow({required this.records});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 0, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16, bottom: 8),
            child: Row(
              children: [
                Icon(Icons.emoji_events_rounded,
                    color: const Color(0xFFEAB308), size: 18),
                const SizedBox(width: 8),
                Text(
                  'Your records',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textPrimary),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 16),
              itemCount: records.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final r = records[index];
                final palette = r.kind.palette(isDark);
                return GestureDetector(
                  onTap: () {
                    HapticService.selection();
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => SyncedWorkoutDetailScreen(workout: r.workout),
                    ));
                  },
                  child: Container(
                    width: 180,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: palette.bg(isDark),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: palette.fg.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        KindAvatar(kind: r.kind, size: 42),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                r.label,
                                style: TextStyle(
                                    fontSize: 11, color: textMuted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                r.value,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter chips row
// ---------------------------------------------------------------------------

class _FilterChipsRow extends StatelessWidget {
  final List<Workout> allWorkouts;
  final SyncedKind? selected;
  final ValueChanged<SyncedKind?> onSelect;

  const _FilterChipsRow({
    required this.allWorkouts,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    // Build kind → count
    final counts = <SyncedKind, int>{};
    for (final w in allWorkouts) {
      final meta = w.generationMetadata ?? {};
      final kind = SyncedKind.fromString(
          meta['hc_activity_kind'] as String? ?? w.type);
      counts[kind] = (counts[kind] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
      child: SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            _chip(
              context,
              label: 'All',
              count: allWorkouts.length,
              active: selected == null,
              color: accent,
              textMuted: textMuted,
              icon: null,
              onTap: () => onSelect(null),
              isDark: isDark,
            ),
            for (final e in sorted) ...[
              const SizedBox(width: 8),
              _chip(
                context,
                label: e.key.label,
                count: e.value,
                active: selected == e.key,
                color: e.key.palette(isDark).fg,
                textMuted: textMuted,
                icon: e.key.icon,
                onTap: () => onSelect(e.key),
                isDark: isDark,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(
    BuildContext context, {
    required String label,
    required int count,
    required bool active,
    required Color color,
    required Color textMuted,
    required IconData? icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? color : color.withValues(alpha: isDark ? 0.14 : 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withValues(alpha: active ? 0 : 0.3),
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 14,
                  color: active ? Colors.white : color),
              const SizedBox(width: 6),
            ],
            Text(
              '$label · $count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Date-grouped list tile
// ---------------------------------------------------------------------------

class _DateHeader extends StatelessWidget {
  final String dateIso;
  const _DateHeader({required this.dateIso});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final dt = DateTime.tryParse(dateIso);
    final label = dt != null ? _format(dt) : dateIso;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: textMuted,
        ),
      ),
    );
  }

  String _format(DateTime dt) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    const weekdays = [
      'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'
    ];
    return '${months[dt.month - 1]} ${dt.day} · ${weekdays[dt.weekday - 1]}'
        .toUpperCase();
  }
}

class _HistoryListTile extends StatelessWidget {
  final Workout workout;

  const _HistoryListTile({required this.workout});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final meta = workout.generationMetadata ?? {};
    final kind = SyncedKind.fromString(
        meta['hc_activity_kind'] as String? ?? workout.type);
    final palette = kind.palette(isDark);
    final textPrimary = isDark ? Colors.white : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final dist = (meta['distance_m'] ?? meta['distance_meters']) as num?;
    final cals = (meta['calories_active'] ?? meta['calories_burned']) as num?;
    final steps = (meta['steps'] ?? meta['total_steps']) as num?;
    final avgHr = meta['avg_heart_rate'] as num?;
    final sourceApp = meta['source_app'] as String?
        ?? meta['source_app_name'] as String?
        ?? (Theme.of(context).platform == TargetPlatform.iOS
            ? 'Apple Health'
            : 'Health Connect');

    final chips = <Widget>[];
    if (dist != null && dist > 0) {
      chips.add(MetricChip(
          dotColor: MetricColors.distance,
          value: (dist.toDouble() * 0.000621371).toStringAsFixed(2),
          unit: 'mi'));
    }
    if (cals != null && cals > 0) {
      chips.add(MetricChip(
          dotColor: MetricColors.calories,
          value: cals.round().toString(),
          unit: 'kcal'));
    } else if (steps != null && steps > 0) {
      chips.add(MetricChip(
          dotColor: MetricColors.steps,
          value: steps.round().toString(),
          unit: 'steps'));
    }
    if (avgHr != null && avgHr > 0) {
      chips.add(MetricChip(
          dotColor: MetricColors.heartRate,
          value: avgHr.round().toString(),
          unit: 'bpm'));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: GestureDetector(
        onTap: () {
          HapticService.selection();
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => SyncedWorkoutDetailScreen(workout: workout),
          ));
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: palette.bg(isDark),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: palette.fg.withValues(alpha: 0.2), width: 1),
          ),
          child: Row(
            children: [
              KindAvatar(kind: kind, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            kind == SyncedKind.other
                                ? (workout.name ?? 'Workout')
                                : kind.label,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (workout.durationMinutes != null)
                          Text(
                            _formatDuration(workout.durationMinutes!),
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: textPrimary),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (chips.isNotEmpty)
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: chips,
                      ),
                    const SizedBox(height: 4),
                    Text(
                      sourceApp,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: palette.fg.withValues(alpha: isDark ? 0.9 : 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: textMuted),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes >= 60) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      return m == 0 ? '${h}h' : '${h}h ${m}m';
    }
    return '${minutes}m';
  }
}
