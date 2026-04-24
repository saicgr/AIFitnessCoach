import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/synced_workout_kinds.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../data/models/workout.dart';
import '../../data/providers/health_import_provider.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/charts/workout_metric_chart.dart';
import '../../widgets/pill_app_bar.dart';
import '../../widgets/synced/kind_avatar.dart';
import '../../widgets/synced/metric_chip.dart';

/// Rich detail view for a Health Connect / Apple Health synced workout.
///
/// Reads exhaustive metadata persisted by `PendingWorkoutImport.toMetadata`
/// — HR series + zones, pace/cadence series, vitals, splits, training load —
/// and renders each section only when its data is present. No silent
/// fallbacks: missing data simply hides the associated section.
class SyncedWorkoutDetailScreen extends ConsumerStatefulWidget {
  final Workout workout;

  const SyncedWorkoutDetailScreen({super.key, required this.workout});

  @override
  ConsumerState<SyncedWorkoutDetailScreen> createState() =>
      _SyncedWorkoutDetailScreenState();
}

class _SyncedWorkoutDetailScreenState
    extends ConsumerState<SyncedWorkoutDetailScreen> {
  late Workout _workout;
  bool _enriching = false;

  @override
  void initState() {
    super.initState();
    _workout = widget.workout;
    _maybeOpportunisticallyEnrich();
  }

  Future<void> _maybeOpportunisticallyEnrich() async {
    final meta = _workout.generationMetadata ?? {};
    // If we already have HR samples, nothing to do.
    if ((meta['hr_samples'] as List?)?.isNotEmpty ?? false) return;
    // Don't hit HC beyond its ~30d retention.
    final endIso = meta['end_time_iso'] as String? ?? _workout.scheduledDate;
    final end = endIso != null ? DateTime.tryParse(endIso) : null;
    if (end == null) return;
    if (end.isBefore(DateTime.now().subtract(const Duration(days: 28)))) return;

    setState(() => _enriching = true);
    try {
      final startIso = (meta['start_time_iso'] as String?) ?? endIso;
      final start = (startIso != null ? DateTime.tryParse(startIso) : null) ?? end;
      final kind = meta['hc_activity_kind'] as String? ?? 'other';
      final sourceApp = meta['source_app'] as String?;
      final ok = await ref
          .read(healthImportProvider.notifier)
          .reEnrichImportedWorkout(
            _workout.id ?? '',
            start,
            end,
            sourceName: sourceApp,
            activityKind: kind,
          );
      if (!mounted) return;
      // Either way, drop the spinner. On success the profile-strip refresh
      // will pick up the richer metadata on next visit.
      if (!ok) {
        debugPrint(
            '⚠️ [SyncedDetail] Re-enrichment returned false for ${_workout.id}');
      }
      setState(() => _enriching = false);
    } catch (e) {
      debugPrint('⚠️ [SyncedDetail] Opportunistic enrich failed: $e');
      if (!mounted) return;
      setState(() => _enriching = false);
    }
  }

  Future<void> _delete() async {
    HapticService.selection();
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DeleteSheet(),
    );
    if (confirmed != true || !mounted) return;

    try {
      final id = _workout.id;
      if (id == null) return;
      // Delete via repository
      final repo = ref.read(workoutRepositoryProvider);
      await repo.deleteWorkout(id);

      // Unmark the Health Connect UUID so it re-surfaces on next sync.
      final meta = _workout.generationMetadata ?? {};
      final uuid = meta['hc_uuid'] as String? ?? meta['uuid'] as String?;
      if (uuid != null) {
        await ref
            .read(healthImportProvider.notifier)
            .unmarkImported(uuid);
      }
      if (!mounted) return;
      if (context.canPop()) context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e')),
      );
    }
  }

  Future<void> _setRpe(int value) async {
    try {
      final id = _workout.id;
      if (id == null) return;
      await ref
          .read(workoutRepositoryProvider)
          .updateGenerationMetadata(id, {'user_rpe': value});
      if (!mounted) return;
      setState(() {
        final meta = Map<String, dynamic>.from(_workout.generationMetadata ?? {});
        meta['user_rpe'] = value;
        _workout = _rebuildWithMetadata(meta);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save RPE: $e')),
      );
    }
  }

  Future<void> _saveNotes(String notes) async {
    try {
      final id = _workout.id;
      if (id == null) return;
      await ref
          .read(workoutRepositoryProvider)
          .updateGenerationMetadata(id, {'user_notes': notes});
      if (!mounted) return;
      setState(() {
        final meta = Map<String, dynamic>.from(_workout.generationMetadata ?? {});
        meta['user_notes'] = notes;
        _workout = _rebuildWithMetadata(meta);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save notes: $e')),
      );
    }
  }

  /// Reconstruct the workout with updated metadata, preserving all other
  /// fields. The Workout model is immutable; we build a new JSON dict and
  /// hydrate. Using the generated fromJson keeps all parsing quirks intact.
  Workout _rebuildWithMetadata(Map<String, dynamic> metadata) {
    final json = _workout.toJson();
    json['generation_metadata'] = jsonEncode(metadata);
    return Workout.fromJson(json);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final metadata = _workout.generationMetadata ?? {};
    final kind = SyncedKind.fromString(
      metadata['hc_activity_kind'] as String? ?? _workout.type,
    );
    final palette = kind.palette(isDark);
    final background = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;

    return Scaffold(
      backgroundColor: background,
      appBar: PillAppBar(
        title: kind == SyncedKind.other
            ? (_workout.name ?? 'Workout')
            : kind.label,
        actions: [
          PillAppBarAction(
            icon: Icons.delete_outline_rounded,
            onTap: _delete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          _HeroBanner(
            kind: kind,
            workout: _workout,
            metadata: metadata,
          ),
          const SizedBox(height: 8),
          _SourceRow(metadata: metadata),
          const SizedBox(height: 16),
          if (_enriching) const _EnrichingBanner(),
          _HeartRateSection(metadata: metadata, palette: palette),
          _HeartRateZonesStrip(metadata: metadata),
          _PaceSpeedSection(metadata: metadata, palette: palette),
          _CadenceSection(metadata: metadata, palette: palette),
          _SplitsSection(metadata: metadata, palette: palette),
          _MetricsGrid(workout: _workout, metadata: metadata),
          _VitalsGrid(metadata: metadata),
          _TrainingLoadCard(metadata: metadata, palette: palette),
          _RpeNotesCard(
            metadata: metadata,
            palette: palette,
            onRpe: _setRpe,
            onNotes: _saveNotes,
          ),
          _ActivityInfoCard(workout: _workout, metadata: metadata),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero banner
// ---------------------------------------------------------------------------

class _HeroBanner extends StatelessWidget {
  final SyncedKind kind;
  final Workout workout;
  final Map<String, dynamic> metadata;

  const _HeroBanner({
    required this.kind,
    required this.workout,
    required this.metadata,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = kind.palette(isDark);
    final accent = AccentColorScope.of(context).getColor(isDark);
    final textPrimary = isDark ? Colors.white : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final order = kind.heroMetricOrder;
    final primary = _formatMetricByKey(order.first, metadata, workout);
    final secondaries = order
        .skip(1)
        .map((k) => _formatMetricByKey(k, metadata, workout))
        .whereType<_MetricDisplay>()
        .take(3)
        .toList();

    final startIso = metadata['start_time_iso'] as String?
        ?? workout.scheduledDate;
    final start = startIso != null ? DateTime.tryParse(startIso)?.toLocal() : null;
    final timeLabel = start != null ? _formatClock(start) : '';
    final weekday = start != null ? _weekday(start) : '';

    return Container(
      height: 220,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            palette.fg.withValues(alpha: isDark ? 0.45 : 0.35),
            palette.fg.withValues(alpha: 0.02),
          ],
        ),
        border: Border.all(
          color: palette.fg.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Watermark
          Positioned(
            right: -30,
            bottom: -28,
            child: IgnorePointer(
              child: Transform.rotate(
                angle: -0.26,
                child: Icon(
                  kind.icon,
                  size: 220,
                  color: palette.fg.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    KindAvatar(kind: kind, size: 60),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          timeLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          weekday,
                          style: TextStyle(fontSize: 11, color: textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  primary?.value ?? '—',
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    color: accent,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  primary?.label ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textMuted,
                  ),
                ),
                const SizedBox(height: 10),
                if (secondaries.isNotEmpty)
                  Row(
                    children: [
                      for (int i = 0; i < secondaries.length; i++) ...[
                        if (i > 0) const SizedBox(width: 18),
                        _HeroSecondaryStat(
                            m: secondaries[i], textPrimary: textPrimary, textMuted: textMuted),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatClock(DateTime dt) {
    final hh = dt.hour > 12
        ? dt.hour - 12
        : (dt.hour == 0 ? 12 : dt.hour);
    final mm = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hh:$mm $ampm';
  }

  static String _weekday(DateTime dt) {
    const names = [
      'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'
    ];
    return names[dt.weekday - 1];
  }
}

class _HeroSecondaryStat extends StatelessWidget {
  final _MetricDisplay m;
  final Color textPrimary;
  final Color textMuted;

  const _HeroSecondaryStat({
    required this.m,
    required this.textPrimary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          m.value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          m.label,
          style: TextStyle(fontSize: 11, color: textMuted),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Source chip row
// ---------------------------------------------------------------------------

class _SourceRow extends StatelessWidget {
  final Map<String, dynamic> metadata;

  const _SourceRow({required this.metadata});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final border = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06);

    final sourceApp = metadata['source_app'] as String?
        ?? metadata['source_app_name'] as String?
        ?? (Theme.of(context).platform == TargetPlatform.iOS
            ? 'Apple Health'
            : 'Health Connect');
    final sourceDevice = metadata['source_device'] as String?;
    final parts = <String>[
      'Synced from $sourceApp',
      if (sourceDevice != null) sourceDevice,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: elevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sync_rounded, size: 12, color: textMuted),
                const SizedBox(width: 6),
                Text(
                  parts.join(' · '),
                  style: TextStyle(
                    fontSize: 11,
                    color: textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EnrichingBanner extends StatelessWidget {
  const _EnrichingBanner();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2, color: textMuted),
          ),
          const SizedBox(width: 8),
          Text(
            'Pulling richer data from Health Connect…',
            style: TextStyle(fontSize: 11, color: textMuted),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Heart rate section
// ---------------------------------------------------------------------------

class _HeartRateSection extends StatelessWidget {
  final Map<String, dynamic> metadata;
  final KindPalette palette;

  const _HeartRateSection({required this.metadata, required this.palette});

  @override
  Widget build(BuildContext context) {
    final rawSamples = metadata['hr_samples'] as List?;
    final avg = (metadata['avg_heart_rate'] as num?)?.toInt();
    final max = (metadata['max_heart_rate'] as num?)?.toInt();
    final min = (metadata['min_heart_rate'] as num?)?.toInt();
    final recoveryDrop = (metadata['recovery_drop_bpm'] as num?)?.toInt();

    // Only render the chart if we have a proper series.
    if (rawSamples == null || rawSamples.length < 2) {
      // Stat-only card when we have aggregates but no series.
      if (avg == null && max == null && min == null) {
        return const SizedBox.shrink();
      }
      return _SectionCard(
        title: 'Heart Rate',
        child: Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            if (avg != null)
              _HrStatTile(label: 'Avg', value: avg, color: const Color(0xFFEF4444)),
            if (max != null)
              _HrStatTile(label: 'Peak', value: max, color: const Color(0xFFDC2626)),
            if (min != null)
              _HrStatTile(label: 'Min', value: min, color: const Color(0xFF22C55E)),
          ],
        ),
      );
    }

    final samples = rawSamples
        .map((e) => MetricSample(
              (e['t'] as num).toDouble(),
              (e['bpm'] as num).toDouble(),
            ))
        .toList();
    final stats = <String>[
      if (avg != null) 'Avg $avg bpm',
      if (max != null) 'Peak $max bpm',
      if (min != null) 'Min $min bpm',
      if (recoveryDrop != null && recoveryDrop > 0)
        'Recovery −$recoveryDrop',
    ];

    return _SectionCard(
      title: 'Heart Rate',
      child: WorkoutMetricChart(
        samples: samples,
        label: 'bpm',
        color: const Color(0xFFEF4444),
        stats: stats,
        formatValue: (v) => v.round().toString(),
        height: 200,
      ),
    );
  }
}

class _HrStatTile extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _HrStatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.14 : 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label $value bpm',
        style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Heart-rate zones stacked strip
// ---------------------------------------------------------------------------

class _HeartRateZonesStrip extends StatelessWidget {
  final Map<String, dynamic> metadata;

  const _HeartRateZonesStrip({required this.metadata});

  static const _zoneColors = [
    Color(0xFF22C55E),
    Color(0xFF84CC16),
    Color(0xFFEAB308),
    Color(0xFFF97316),
    Color(0xFFEF4444),
  ];
  static const _zoneLabels = [
    '<60% max',
    '60–70% max',
    '70–80% max',
    '80–90% max',
    '>90% max',
  ];

  @override
  Widget build(BuildContext context) {
    final raw = metadata['hr_zones_pct'] as Map?;
    if (raw == null || raw.isEmpty) return const SizedBox.shrink();

    final pcts = <double>[];
    for (int i = 1; i <= 5; i++) {
      final v = raw['$i'];
      pcts.add(v is num ? v.toDouble() : 0);
    }
    final total = pcts.fold<double>(0, (a, b) => a + b);
    if (total <= 0) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textPrimary = isDark ? Colors.white : AppColorsLight.textPrimary;

    return _SectionCard(
      title: 'Zones',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 14,
              child: Row(
                children: [
                  for (int i = 0; i < 5; i++)
                    Expanded(
                      flex: (pcts[i] * 100).round().clamp(0, 10000),
                      child: Container(color: _zoneColors[i]),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < 5; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _zoneColors[i],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Z${i + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _zoneLabels[i],
                      style: TextStyle(fontSize: 11, color: textMuted),
                    ),
                  ),
                  Text(
                    '${pcts[i].round()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _zoneColors[i],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pace / speed section
// ---------------------------------------------------------------------------

class _PaceSpeedSection extends StatelessWidget {
  final Map<String, dynamic> metadata;
  final KindPalette palette;

  const _PaceSpeedSection({required this.metadata, required this.palette});

  @override
  Widget build(BuildContext context) {
    final rawSamples = metadata['pace_samples'] as List?;
    if (rawSamples == null || rawSamples.length < 2) return const SizedBox.shrink();

    final samples = rawSamples
        .map((e) => MetricSample(
              (e['t'] as num).toDouble(),
              (e['mps'] as num).toDouble(),
            ))
        .toList();
    final avg = metadata['avg_speed_mps'] as num?;
    final max = metadata['max_speed_mps'] as num?;
    final stats = <String>[
      if (avg != null) 'Avg ${(avg * 2.23694).toStringAsFixed(1)} mph',
      if (max != null) 'Max ${(max * 2.23694).toStringAsFixed(1)} mph',
    ];

    return _SectionCard(
      title: 'Speed',
      child: WorkoutMetricChart(
        samples: samples,
        label: 'mph',
        color: palette.fg,
        stats: stats,
        formatValue: (mps) => (mps * 2.23694).toStringAsFixed(1),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cadence section
// ---------------------------------------------------------------------------

class _CadenceSection extends StatelessWidget {
  final Map<String, dynamic> metadata;
  final KindPalette palette;

  const _CadenceSection({required this.metadata, required this.palette});

  @override
  Widget build(BuildContext context) {
    final rawSamples = metadata['cadence_samples'] as List?;
    if (rawSamples == null || rawSamples.length < 2) return const SizedBox.shrink();

    final samples = rawSamples
        .map((e) => MetricSample(
              (e['t'] as num).toDouble(),
              (e['spm'] as num).toDouble(),
            ))
        .toList();
    final avg = metadata['avg_cadence_spm'] as num?;
    final max = metadata['max_cadence_spm'] as num?;
    final stats = <String>[
      if (avg != null) 'Avg ${avg.round()} spm',
      if (max != null) 'Max ${max.round()} spm',
    ];

    return _SectionCard(
      title: 'Cadence',
      child: WorkoutMetricChart(
        samples: samples,
        label: 'spm',
        color: MetricColors.cadence,
        stats: stats,
        formatValue: (v) => v.round().toString(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Splits table
// ---------------------------------------------------------------------------

class _SplitsSection extends StatelessWidget {
  final Map<String, dynamic> metadata;
  final KindPalette palette;

  const _SplitsSection({required this.metadata, required this.palette});

  @override
  Widget build(BuildContext context) {
    final raw = metadata['splits'] as List?;
    if (raw == null || raw.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    // Find worst (slowest) split for bar-scaling
    double worstDur = 0;
    for (final s in raw) {
      final d = (s as Map)['duration_sec'] as num?;
      if (d != null && d.toDouble() > worstDur) worstDur = d.toDouble();
    }

    return _SectionCard(
      title: 'Splits',
      child: Column(
        children: [
          Row(
            children: [
              _headerCell('#', 36, textMuted),
              _headerCell('Time', 60, textMuted),
              Expanded(child: _headerCell('Pace', null, textMuted)),
              _headerCell('Avg HR', 60, textMuted),
            ],
          ),
          const SizedBox(height: 6),
          for (final sRaw in raw) ...[
            _splitRow(
              sRaw as Map,
              worstDur,
              textPrimary,
              palette.fg,
            ),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }

  Widget _headerCell(String label, double? width, Color color) {
    final child = Text(
      label,
      style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
    );
    return width != null ? SizedBox(width: width, child: child) : child;
  }

  Widget _splitRow(Map s, double worstDur, Color textPrimary, Color fg) {
    final i = (s['i'] as num?)?.toInt() ?? 0;
    final dur = (s['duration_sec'] as num?)?.toDouble() ?? 0;
    final hr = (s['avg_hr'] as num?)?.toInt();
    final unit = s['unit'] as String? ?? 'mi';
    final paceMinSec = _formatPace(dur);
    final barWidthPct = worstDur > 0 ? (dur / worstDur).clamp(0.0, 1.0) : 1.0;

    return Row(
      children: [
        SizedBox(
          width: 36,
          child: Text(
            '${i + 1}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
        ),
        SizedBox(
          width: 60,
          child: Text(
            _formatDurationShort(dur.toInt()),
            style: TextStyle(fontSize: 12, color: textPrimary),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 16,
                decoration: BoxDecoration(
                  color: fg.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              FractionallySizedBox(
                widthFactor: barWidthPct,
                child: Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: fg.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              Positioned.fill(
                child: Center(
                  child: Text(
                    '$paceMinSec /$unit',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 60,
          child: Text(
            hr != null ? '$hr' : '—',
            style: TextStyle(fontSize: 12, color: textPrimary),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  String _formatDurationShort(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String _formatPace(double durSec) {
    // durSec per unit (mi). Display mm:ss.
    final total = durSec.round();
    final m = total ~/ 60;
    final s = total % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

// ---------------------------------------------------------------------------
// Metrics grid (catch-all for everything not featured above)
// ---------------------------------------------------------------------------

class _MetricsGrid extends StatelessWidget {
  final Workout workout;
  final Map<String, dynamic> metadata;

  const _MetricsGrid({required this.workout, required this.metadata});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tiles = <_MetricTileData>[];

    if (workout.durationMinutes != null) {
      tiles.add(_MetricTileData(
        icon: Icons.timer_outlined,
        label: 'Duration',
        value: _formatDuration(workout.durationMinutes!),
        color: MetricColors.duration,
      ));
    }
    final dist = (metadata['distance_m'] ?? metadata['distance_meters']) as num?;
    if (dist != null && dist > 0) {
      tiles.add(_MetricTileData(
        icon: Icons.straighten_outlined,
        label: 'Distance',
        value: _formatDistance(dist.toDouble()),
        color: MetricColors.distance,
      ));
    }
    final paceSecPerKm = metadata['pace_sec_per_km'] as num?;
    if (paceSecPerKm != null && paceSecPerKm > 0) {
      tiles.add(_MetricTileData(
        icon: Icons.speed_rounded,
        label: 'Pace',
        value: '${_formatPacePerMile(paceSecPerKm.toDouble())} /mi',
        color: MetricColors.pace,
      ));
    }
    final steps = (metadata['steps'] ?? metadata['total_steps']) as num?;
    if (steps != null && steps > 0) {
      tiles.add(_MetricTileData(
        icon: Icons.directions_walk_rounded,
        label: 'Steps',
        value: _formatInt(steps),
        color: MetricColors.steps,
      ));
    }
    final cadence = metadata['avg_cadence_spm'] as num?;
    if (cadence != null && cadence > 0) {
      tiles.add(_MetricTileData(
        icon: Icons.graphic_eq_rounded,
        label: 'Cadence',
        value: '${cadence.round()} spm',
        color: MetricColors.cadence,
      ));
    }
    final stride = metadata['avg_stride_in'] as num?;
    if (stride != null && stride > 0) {
      tiles.add(_MetricTileData(
        icon: Icons.swap_horiz_rounded,
        label: 'Stride',
        value: '${stride.round()} in',
        color: MetricColors.cadence,
      ));
    }
    final active = (metadata['calories_active'] ?? metadata['calories_burned']) as num?;
    if (active != null && active > 0) {
      tiles.add(_MetricTileData(
        icon: Icons.local_fire_department_outlined,
        label: 'Active cal',
        value: '${_formatInt(active)} kcal',
        color: MetricColors.calories,
      ));
    }
    final totalKcal = metadata['calories_total'] as num?;
    if (totalKcal != null && totalKcal > 0) {
      tiles.add(_MetricTileData(
        icon: Icons.whatshot_outlined,
        label: 'Total cal',
        value: '${_formatInt(totalKcal)} kcal',
        color: MetricColors.calories,
      ));
    }
    final elev = metadata['elevation_gain_m'] as num?;
    if (elev != null && elev > 0) {
      tiles.add(_MetricTileData(
        icon: Icons.terrain_rounded,
        label: 'Elev. gain',
        value: '${elev.round()} m',
        color: MetricColors.elevation,
      ));
    }
    final flights = metadata['flights_climbed'] as num?;
    if (flights != null && flights > 0) {
      tiles.add(_MetricTileData(
        icon: Icons.stairs_rounded,
        label: 'Flights',
        value: '${flights.round()}',
        color: MetricColors.elevation,
      ));
    }

    if (tiles.isEmpty) return const SizedBox.shrink();

    return _SectionCard(
      title: 'Metrics',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: tiles
            .map((t) => SizedBox(
                  width: (MediaQuery.of(context).size.width - 32 - 12 - 40) / 2,
                  child: _MetricTile(data: t, isDark: isDark),
                ))
            .toList(),
      ),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes >= 60) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      return m == 0 ? '${h}h' : '${h}h ${m}m';
    }
    return '$minutes min';
  }

  String _formatDistance(double meters) {
    if (meters < 50) return '${meters.round()} m';
    final miles = meters * 0.000621371;
    return '${miles.toStringAsFixed(miles >= 10 ? 1 : 2)} mi';
  }

  String _formatInt(num v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(v >= 10000 ? 0 : 1)}k';
    return v.round().toString();
  }

  String _formatPacePerMile(double secPerKm) {
    final secPerMi = secPerKm * 1.609344;
    final m = (secPerMi ~/ 60).toInt();
    final s = (secPerMi % 60).round();
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

class _MetricTileData {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricTileData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

class _MetricTile extends StatelessWidget {
  final _MetricTileData data;
  final bool isDark;

  const _MetricTile({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? Colors.white : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: data.color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(data.icon, color: data.color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data.label, style: TextStyle(fontSize: 10, color: textMuted)),
              Text(
                data.value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Vitals grid — SpO2, respiratory rate, body temp, HRV, resting HR
// ---------------------------------------------------------------------------

class _VitalsGrid extends StatelessWidget {
  final Map<String, dynamic> metadata;

  const _VitalsGrid({required this.metadata});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tiles = <_MetricTileData>[];

    final spo2 = metadata['avg_spo2'] as num?;
    if (spo2 != null && spo2 > 0) {
      tiles.add(_MetricTileData(
        icon: Icons.bloodtype_outlined,
        label: 'SpO₂ avg',
        value: '${spo2.toStringAsFixed(1)}%',
        color: MetricColors.spo2,
      ));
    }
    final resp = metadata['avg_respiratory_rate'] as num?;
    if (resp != null && resp > 0) {
      tiles.add(_MetricTileData(
        icon: Icons.air_rounded,
        label: 'Breathing',
        value: '${resp.round()} br/min',
        color: MetricColors.respRate,
      ));
    }
    final temp = metadata['peak_body_temperature_c'] as num?;
    if (temp != null && temp > 0) {
      tiles.add(_MetricTileData(
        icon: Icons.device_thermostat_rounded,
        label: 'Body temp',
        value: '${temp.toStringAsFixed(1)}°C',
        color: MetricColors.temperature,
      ));
    }
    final hrvPre = metadata['avg_hrv_rmssd_pre'] as num?;
    if (hrvPre != null && hrvPre > 0) {
      tiles.add(_MetricTileData(
        icon: Icons.monitor_heart_outlined,
        label: 'HRV (pre)',
        value: '${hrvPre.round()} ms',
        color: MetricColors.hrv,
      ));
    }
    final hrvPost = metadata['avg_hrv_rmssd_post'] as num?;
    if (hrvPost != null && hrvPost > 0) {
      tiles.add(_MetricTileData(
        icon: Icons.monitor_heart_rounded,
        label: 'HRV (post)',
        value: '${hrvPost.round()} ms',
        color: MetricColors.hrv,
      ));
    }
    final rhr = metadata['resting_hr_same_day'] as num?;
    if (rhr != null && rhr > 0) {
      tiles.add(_MetricTileData(
        icon: Icons.favorite_border_rounded,
        label: 'Resting HR',
        value: '${rhr.round()} bpm',
        color: MetricColors.heartRate,
      ));
    }
    final bodyKg = metadata['body_weight_kg_nearest'] as num?;
    if (bodyKg != null && bodyKg > 0) {
      tiles.add(_MetricTileData(
        icon: Icons.monitor_weight_outlined,
        label: 'Body wt',
        value: '${bodyKg.toStringAsFixed(1)} kg',
        color: MetricColors.hrv,
      ));
    }

    if (tiles.isEmpty) return const SizedBox.shrink();

    return _SectionCard(
      title: 'Body Signals',
      subtitle: 'Captured around your session',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: tiles
            .map((t) => SizedBox(
                  width: (MediaQuery.of(context).size.width - 32 - 12 - 40) / 2,
                  child: _MetricTile(data: t, isDark: isDark),
                ))
            .toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Training load gauge
// ---------------------------------------------------------------------------

class _TrainingLoadCard extends StatelessWidget {
  final Map<String, dynamic> metadata;
  final KindPalette palette;

  const _TrainingLoadCard({required this.metadata, required this.palette});

  @override
  Widget build(BuildContext context) {
    final trimp = metadata['training_load_trimp'] as num?;
    final effort = metadata['effort_score'] as num?;
    if (trimp == null || effort == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final pct = (effort / 100).clamp(0.0, 1.0);
    final band = _band(effort.toDouble());

    return _SectionCard(
      title: 'Training Effect',
      child: Row(
        children: [
          SizedBox(
            width: 88,
            height: 88,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 88,
                  height: 88,
                  child: CircularProgressIndicator(
                    value: pct,
                    strokeWidth: 8,
                    backgroundColor: palette.fg.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation(palette.fg),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${effort.round()}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      '/ 100',
                      style: TextStyle(fontSize: 9, color: textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  band,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  'TRIMP ${trimp.toStringAsFixed(1)} · from HR reserve, duration, and recovery',
                  style: TextStyle(fontSize: 11, color: textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _band(double score) {
    if (score < 20) return 'Easy recovery';
    if (score < 50) return 'Moderate effort';
    if (score < 80) return 'Hard session';
    return 'Max effort';
  }
}

// ---------------------------------------------------------------------------
// RPE + notes inline edit
// ---------------------------------------------------------------------------

class _RpeNotesCard extends StatefulWidget {
  final Map<String, dynamic> metadata;
  final KindPalette palette;
  final Future<void> Function(int) onRpe;
  final Future<void> Function(String) onNotes;

  const _RpeNotesCard({
    required this.metadata,
    required this.palette,
    required this.onRpe,
    required this.onNotes,
  });

  @override
  State<_RpeNotesCard> createState() => _RpeNotesCardState();
}

class _RpeNotesCardState extends State<_RpeNotesCard> {
  bool _editingNotes = false;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(
      text: widget.metadata['user_notes'] as String? ?? '',
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder =
        (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06);
    final rpe = (widget.metadata['user_rpe'] as num?)?.toInt();
    final notes = widget.metadata['user_notes'] as String? ?? '';

    return _SectionCard(
      title: 'How did it feel?',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RPE · Rate of Perceived Exertion',
            style: TextStyle(fontSize: 11, color: textMuted),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (int i = 1; i <= 10; i++)
                _RpePill(
                  value: i,
                  selected: i == rpe,
                  color: widget.palette.fg,
                  onTap: () {
                    HapticService.selection();
                    widget.onRpe(i);
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Notes',
            style: TextStyle(fontSize: 11, color: textMuted),
          ),
          const SizedBox(height: 6),
          if (!_editingNotes)
            GestureDetector(
              onTap: () {
                setState(() => _editingNotes = true);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cardBorder),
                ),
                child: Text(
                  notes.isEmpty ? 'Tap to add notes' : notes,
                  style: TextStyle(
                    fontSize: 13,
                    color: notes.isEmpty ? textMuted : textPrimary,
                  ),
                ),
              ),
            )
          else
            Column(
              children: [
                TextField(
                  controller: _notesController,
                  maxLines: 4,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'How did this session go?',
                    hintStyle: TextStyle(color: textMuted, fontSize: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: widget.palette.fg, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  style: TextStyle(fontSize: 13, color: textPrimary),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _notesController.text = notes;
                          _editingNotes = false;
                        });
                      },
                      child: Text('Cancel', style: TextStyle(color: textMuted)),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: widget.palette.fg,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        await widget.onNotes(_notesController.text);
                        if (!mounted) return;
                        setState(() => _editingNotes = false);
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _RpePill extends StatelessWidget {
  final int value;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _RpePill({
    required this.value,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          '$value',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : textMuted,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Activity info
// ---------------------------------------------------------------------------

class _ActivityInfoCard extends StatelessWidget {
  final Workout workout;
  final Map<String, dynamic> metadata;

  const _ActivityInfoCard({required this.workout, required this.metadata});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final border =
        (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06);

    final startIso = metadata['start_time_iso'] as String?
        ?? workout.scheduledDate;
    final endIso = metadata['end_time_iso'] as String?;
    final start = startIso != null ? DateTime.tryParse(startIso)?.toLocal() : null;
    final end = endIso != null ? DateTime.tryParse(endIso)?.toLocal() : null;
    final dateStr = start != null ? _formatDate(start) : '—';
    final startStr = start != null ? _formatClock(start) : '—';
    final endStr = end != null ? _formatClock(end) : '—';

    return _SectionCard(
      title: 'Session info',
      child: Column(
        children: [
          _row('Date', dateStr, textPrimary, textMuted),
          Divider(height: 18, color: border),
          _row('Start', startStr, textPrimary, textMuted),
          Divider(height: 18, color: border),
          _row('End', endStr, textPrimary, textMuted),
          Divider(height: 18, color: border),
          _row(
            'Status',
            workout.isCompleted == true ? 'Completed' : 'Recorded',
            textPrimary,
            textMuted,
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, Color primary, Color muted) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: muted)),
        Text(
          value,
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: primary),
        ),
      ],
    );
  }

  static String _formatDate(DateTime dt) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  static String _formatClock(DateTime dt) {
    final hh = dt.hour > 12
        ? dt.hour - 12
        : (dt.hour == 0 ? 12 : dt.hour);
    final mm = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hh:$mm $ampm';
  }
}

// ---------------------------------------------------------------------------
// Section card shell
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? Colors.white : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final border = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06);

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
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: TextStyle(fontSize: 11, color: textMuted),
              ),
            ],
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Delete confirmation sheet
// ---------------------------------------------------------------------------

class _DeleteSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? Colors.white : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: textMuted.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Icon(Icons.delete_outline_rounded, size: 40,
              color: const Color(0xFFEF4444)),
          const SizedBox(height: 12),
          Text(
            'Delete this synced workout?',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'It will re-appear the next time you sync with Health Connect.',
            style: TextStyle(fontSize: 12, color: textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel', style: TextStyle(color: textMuted)),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Metric formatting helpers (shared with hero banner)
// ---------------------------------------------------------------------------

class _MetricDisplay {
  final String value;
  final String label;
  const _MetricDisplay(this.value, this.label);
}

_MetricDisplay? _formatMetricByKey(
  String key,
  Map<String, dynamic> metadata,
  Workout workout,
) {
  num? numAt(String a, [String? b]) {
    final v = metadata[a];
    if (v is num) return v;
    if (b != null) {
      final v2 = metadata[b];
      if (v2 is num) return v2;
    }
    return null;
  }

  switch (key) {
    case 'duration':
      if (workout.durationMinutes == null) return null;
      final m = workout.durationMinutes!;
      if (m >= 60) {
        final h = m ~/ 60;
        final rem = m % 60;
        return _MetricDisplay(
            rem == 0 ? '${h}h' : '${h}h ${rem}m', 'Duration');
      }
      return _MetricDisplay('${m}m', 'Duration');
    case 'distance_m':
      final d = numAt('distance_m', 'distance_meters');
      if (d == null || d <= 0) return null;
      if (d < 50) return _MetricDisplay('${d.round()} m', 'Distance');
      final miles = d.toDouble() * 0.000621371;
      return _MetricDisplay(
          '${miles.toStringAsFixed(miles >= 10 ? 1 : 2)} mi', 'Distance');
    case 'calories_active':
      final c = numAt('calories_active', 'calories_burned');
      if (c == null || c <= 0) return null;
      return _MetricDisplay('${c.round()} kcal', 'Active');
    case 'steps':
      final s = numAt('steps', 'total_steps');
      if (s == null || s <= 0) return null;
      return _MetricDisplay(s.round().toString(), 'Steps');
    case 'avg_heart_rate':
      final h = numAt('avg_heart_rate');
      if (h == null || h <= 0) return null;
      return _MetricDisplay('${h.round()} bpm', 'Avg HR');
    case 'max_heart_rate':
      final h = numAt('max_heart_rate');
      if (h == null || h <= 0) return null;
      return _MetricDisplay('${h.round()} bpm', 'Peak HR');
    case 'pace_sec_per_km':
      final p = numAt('pace_sec_per_km');
      if (p == null || p <= 0) return null;
      final secPerMi = p.toDouble() * 1.609344;
      final m = secPerMi ~/ 60;
      final s = (secPerMi % 60).round();
      return _MetricDisplay(
          '$m:${s.toString().padLeft(2, '0')} /mi', 'Pace');
    case 'avg_speed_mps':
      final v = numAt('avg_speed_mps');
      if (v == null || v <= 0) return null;
      return _MetricDisplay(
          '${(v * 2.23694).toStringAsFixed(1)} mph', 'Avg Speed');
    case 'elevation_gain_m':
      final e = numAt('elevation_gain_m');
      if (e == null || e <= 0) return null;
      return _MetricDisplay('${e.round()} m', 'Elev. gain');
    case 'avg_respiratory_rate':
      final r = numAt('avg_respiratory_rate');
      if (r == null || r <= 0) return null;
      return _MetricDisplay('${r.round()}', 'Breaths/min');
    case 'hr_zones_pct':
      final raw = metadata['hr_zones_pct'] as Map?;
      if (raw == null) return null;
      final z4 = (raw['4'] as num?)?.toDouble() ?? 0;
      final z5 = (raw['5'] as num?)?.toDouble() ?? 0;
      return _MetricDisplay('${(z4 + z5).round()}%', 'in Z4+');
  }
  return null;
}

