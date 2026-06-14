import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/services/api_client.dart';
import '../../../widgets/design_system/zealova.dart';

import '../../../l10n/generated/app_localizations.dart';
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
    final tc = ThemeColors.of(context);
    final bg = tc.surface;
    final textPrimary = tc.textPrimary;
    final textSecondary = tc.textSecondary;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: const Border(
          top: BorderSide(color: AppColors.hairlineStrong, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.hairlineStrong,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ZealovaSectionKicker('Strength Breakdown'),
                      const SizedBox(height: 4),
                      Text(
                        _humanMuscle(widget.muscleGroup).toUpperCase(),
                        style: ZType.disp(24, color: textPrimary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: tc.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          if (_loading)
            Padding(
              padding: const EdgeInsets.all(40),
              child: CircularProgressIndicator(color: tc.accent),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: tc.textMuted,
                    size: 36,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: ZType.lbl(13, color: textSecondary, letterSpacing: 0.5),
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
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        _headerCard(context, header, textPrimary, textSecondary),
        const SizedBox(height: 20),
        if (exercises.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              _data?['note']?.toString() ??
                  AppLocalizations.of(context).muscleScoreBreakdownNoExerciseDataIn,
              style: ZType.lbl(13, color: textSecondary, letterSpacing: 0.5),
            ),
          )
        else ...[
          ZealovaSectionKicker(
            AppLocalizations.of(context).strengthContributionToScore,
            accent: true,
          ),
          const SizedBox(height: 10),
          const ZealovaRule(),
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
    BuildContext context,
    Map header,
    Color textPrimary,
    Color textSecondary,
  ) {
    final tc = ThemeColors.of(context);
    final score = header['strength_score'];
    final level = header['strength_level'];
    final best = header['best_exercise_name'];
    final best1rm = header['best_estimated_1rm_kg'];
    final trend = header['trend'];

    return ZealovaCard(
      variant: ZealovaCardVariant.hero,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ZealovaStatTile(
                value: '$score',
                label: level?.toString() ?? 'Score',
                valueSize: 40,
                accentValue: true,
              ),
              const Spacer(),
              if (trend != null)
                _trendBadge(context, trend.toString(), textSecondary),
            ],
          ),
          if (best != null) ...[
            const SizedBox(height: 12),
            const ZealovaRule(),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ZealovaSectionKicker('Best Lift', fontSize: 10),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$best',
                    style: ZType.lbl(13,
                        color: textPrimary, letterSpacing: 0.5),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            if (best1rm != null) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '1RM ${best1rm}kg',
                    style: ZType.data(11, color: tc.textMuted),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _trendBadge(BuildContext context, String trend, Color textSecondary) {
    final tc = ThemeColors.of(context);
    final isUp = trend.toLowerCase().contains('up') ||
        trend.toLowerCase().contains('improving');
    final isDown = trend.toLowerCase().contains('down') ||
        trend.toLowerCase().contains('declin');
    final color = isUp
        ? tc.success
        : (isDown ? tc.error : textSecondary);
    final icon = isUp
        ? Icons.trending_up_rounded
        : (isDown ? Icons.trending_down_rounded : Icons.trending_flat_rounded);
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(trend.toUpperCase(),
            style: ZType.lbl(11, color: color, letterSpacing: 0.8)),
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
    final tc = ThemeColors.of(context);
    final name = data['exercise_name']?.toString() ?? '—';
    final pct = (data['contribution_pct'] as num?)?.toDouble() ?? 0;
    final e1rm = (data['e1rm'] as num?)?.toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: ZType.lbl(14,
                          color: textPrimary, letterSpacing: 0.4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.muscleScoreBreakdownSheetValue(pct.toStringAsFixed(1)),
                    style: ZType.data(13, color: tc.accent),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Thin hairline-style bar with a single accent fill element.
              LayoutBuilder(
                builder: (context, constraints) {
                  final frac = (pct / 100).clamp(0.0, 1.0);
                  return Stack(
                    children: [
                      Container(
                        height: 2,
                        decoration: BoxDecoration(
                          color: AppColors.hairlineStrong,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      Container(
                        height: 2,
                        width: constraints.maxWidth * frac,
                        decoration: BoxDecoration(
                          color: tc.accent,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ],
                  );
                },
              ),
              if (e1rm != null) ...[
                const SizedBox(height: 6),
                Text(
                  AppLocalizations.of(context)!.muscleScoreBreakdownSheetEstimatedRmKg(e1rm.toStringAsFixed(1)),
                  style: ZType.data(11, color: tc.textMuted),
                ),
              ],
            ],
          ),
        ),
        const ZealovaRule(),
      ],
    );
  }
}
