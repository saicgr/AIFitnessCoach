import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/services/api_client.dart';

/// Phase 4 — per-exercise contribution to a muscle's strength score.
///
/// Tap-through from the strength tab: tap a muscle row → this sheet opens →
/// shows the ranked list of contributing exercises with contribution %.
/// Mirrors Gravl's "see the logic / exercises contributing to a muscle's
/// strength score" feature (from the Fitbod-vs-Gravl blog).
///
/// Source: GET /api/v1/scores/breakdown/{muscle_group}
class MuscleScoreBreakdownSheet extends ConsumerStatefulWidget {
  const MuscleScoreBreakdownSheet({
    super.key,
    required this.muscleGroup,
  });

  final String muscleGroup;

  static Future<void> show(BuildContext context, String muscleGroup) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MuscleScoreBreakdownSheet(muscleGroup: muscleGroup),
    );
  }

  @override
  ConsumerState<MuscleScoreBreakdownSheet> createState() =>
      _MuscleScoreBreakdownSheetState();
}

class _MuscleScoreBreakdownSheetState
    extends ConsumerState<MuscleScoreBreakdownSheet> {
  Map<String, dynamic>? _data;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = ref.read(apiClientProvider);
      final resp = await api.get('/scores/breakdown/${widget.muscleGroup}');
      if (resp.statusCode == 200 && resp.data is Map) {
        setState(() {
          _data = Map<String, dynamic>.from(resp.data);
          _loading = false;
          _error = null;
        });
      } else {
        setState(() {
          _error = 'No breakdown available (HTTP ${resp.statusCode}).';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Theme.of(context).colorScheme.surface;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  _humanMuscle(widget.muscleGroup),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: textSecondary,
                    size: 36,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(color: textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            Flexible(child: _body(context, textPrimary, textSecondary)),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, Color textPrimary, Color textSecondary) {
    final header = (_data?['header'] as Map?) ?? {};
    final exercises = (_data?['exercises'] as List?) ?? const [];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        _headerCard(header, textPrimary, textSecondary),
        const SizedBox(height: 16),
        if (exercises.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              _data?['note']?.toString() ??
                  'No exercise data in the last 90 days.',
              style: TextStyle(color: textSecondary),
            ),
          )
        else ...[
          Text(
            'Contribution to score',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          for (final raw in exercises)
            _ExerciseRow(
              data: Map<String, dynamic>.from(raw as Map),
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
        ],
      ],
    );
  }

  Widget _headerCard(
    Map header,
    Color textPrimary,
    Color textSecondary,
  ) {
    final score = header['strength_score'];
    final level = header['strength_level'];
    final best = header['best_exercise_name'];
    final best1rm = header['best_estimated_1rm_kg'];
    final trend = header['trend'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$score',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  level?.toString() ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                  ),
                ),
              ),
              const Spacer(),
              if (trend != null)
                _trendBadge(trend.toString(), textPrimary, textSecondary),
            ],
          ),
          if (best != null) ...[
            const SizedBox(height: 8),
            Text(
              'Best lift: $best${best1rm != null ? "  ·  1RM ${best1rm}kg" : ''}',
              style: TextStyle(fontSize: 12, color: textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _trendBadge(String trend, Color textPrimary, Color textSecondary) {
    final isUp = trend.toLowerCase().contains('up') ||
        trend.toLowerCase().contains('improving');
    final isDown = trend.toLowerCase().contains('down') ||
        trend.toLowerCase().contains('declin');
    final color = isUp
        ? const Color(0xFF22C55E)
        : (isDown ? const Color(0xFFEF4444) : textSecondary);
    final icon = isUp
        ? Icons.trending_up_rounded
        : (isDown ? Icons.trending_down_rounded : Icons.trending_flat_rounded);
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(trend, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }

  static String _humanMuscle(String key) =>
      key.replaceAll('_', ' ').split(' ').map((w) {
        if (w.isEmpty) return w;
        return w[0].toUpperCase() + w.substring(1);
      }).join(' ');
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({
    required this.data,
    required this.textPrimary,
    required this.textSecondary,
  });

  final Map<String, dynamic> data;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    final name = data['exercise_name']?.toString() ?? '—';
    final pct = (data['contribution_pct'] as num?)?.toDouble() ?? 0;
    final e1rm = (data['e1rm'] as num?)?.toDouble();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ),
              Text(
                '${pct.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (pct / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: Colors.white.withOpacity(0.06),
            ),
          ),
          if (e1rm != null) ...[
            const SizedBox(height: 2),
            Text(
              'Estimated 1RM ${e1rm.toStringAsFixed(1)} kg',
              style: TextStyle(
                fontSize: 11,
                color: textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
