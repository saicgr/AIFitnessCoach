import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../data/repositories/training_load_repository.dart';
import '../../widgets/cardio/training_load_chart.dart';
import '../../widgets/glass_back_button.dart';
import '../pillar/widgets/ask_coach_button.dart';

/// =========================================================================
/// TrainingLoadScreen — `/cardio/training-load`
/// =========================================================================
///
/// Pro-coach view of the Banister TRIMP system: ACWR hero, classification
/// band, combined acute / chronic / ACWR chart, and a methodology footer.
///
/// Self-contained on purpose — wave 2 owns the Home tile + Custom Trends
/// entry that route in. Once those exist, the screen below renders without
/// changes (just hit `/cardio/training-load`).
class TrainingLoadScreen extends ConsumerWidget {
  const TrainingLoadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppColorsLight.background;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    final asyncState = ref.watch(trainingLoadCurrentProvider);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Invalidate both so the chart + hero refetch together.
            ref.invalidate(trainingLoadCurrentProvider);
            ref.invalidate(trainingLoadHistoryProvider);
            await ref.read(trainingLoadCurrentProvider.future);
          },
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 16, 4),
                child: Row(
                  children: [
                    const GlassBackButton(),
                    const SizedBox(width: 12),
                    Text(
                      'Training load',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              // Hero
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: asyncState.when(
                  loading: () => const SizedBox(
                    height: 140,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => _ErrorBox(message: '$e'),
                  data: (state) => _HeroBlock(state: state),
                ),
              ),

              // Chart
              const Padding(
                padding: EdgeInsets.fromLTRB(8, 16, 8, 8),
                child: TrainingLoadChart(days: 120, height: 260),
              ),

              // Legend
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: _Legend(textColor: textSecondary),
              ),

              // Stat cards
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: asyncState.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (state) => _StatCards(state: state),
                ),
              ),

              // Methodology footer
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Text(
                  'Method: Banister HR-weighted TRIMP (Banister 1991), '
                  '7-day acute / 28-day chronic rolling sums, ACWR '
                  'classification per Gabbett 2016 (BJSM 50(5)). When heart '
                  'rate is missing we fall back to RPE × duration (Foster '
                  'sRPE) or a calorie proxy.',
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                    height: 1.5,
                  ),
                ),
              ),

              // Ask Coach
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AskCoachButton(
                      contextLabel: 'Training load · ACWR',
                      semanticLabel: 'Ask coach about your training load',
                      statSnapshot: {
                        'source': 'training_load',
                        'state': asyncState.valueOrNull?.state,
                        'acwr': asyncState.valueOrNull?.acwr,
                        'acute_load': asyncState.valueOrNull?.acuteLoad,
                        'chronic_load': asyncState.valueOrNull?.chronicLoad,
                        'daily_trimp': asyncState.valueOrNull?.dailyTrimp,
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroBlock extends StatelessWidget {
  final TrainingLoadState state;
  const _HeroBlock({required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    final stateColor = _colorForState(state.state);
    final acwrLabel = state.acwr == null
        ? '—'
        : state.acwr!.toStringAsFixed(2);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accent.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                acwrLabel,
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                  color: textPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'ACWR',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textSecondary,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: stateColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: stateColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  _labelForState(state.state),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: stateColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            state.interpretation,
            style: TextStyle(
              fontSize: 14,
              color: textPrimary.withValues(alpha: 0.85),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCards extends StatelessWidget {
  final TrainingLoadState state;
  const _StatCards({required this.state});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Acute (7d)',
            value: state.acuteLoad.toStringAsFixed(0),
            unit: 'TRIMP',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'Chronic (28d)',
            value: state.chronicLoad.toStringAsFixed(0),
            unit: 'TRIMP',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'ACWR',
            value:
                state.acwr == null ? '—' : state.acwr!.toStringAsFixed(2),
            unit: 'ratio',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.surface : AppColorsLight.surface;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: 11,
                    color: textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color textColor;
  const _Legend({required this.textColor});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        _legendChip('Acute (7d)', accent.withValues(alpha: 0.55), textColor),
        _legendChip('Chronic (28d)', accent.withValues(alpha: 0.20), textColor),
        _legendChip('ACWR', isDark ? Colors.white : Colors.black87, textColor,
            dashed: true),
        _legendChip('Sweet spot 0.8–1.3',
            Colors.green.withValues(alpha: 0.35), textColor),
        _legendChip('Loading 1.3–1.5',
            Colors.amber.withValues(alpha: 0.45), textColor),
        _legendChip('Overreaching >1.5',
            Colors.redAccent.withValues(alpha: 0.45), textColor),
      ],
    );
  }

  Widget _legendChip(String label, Color swatch, Color textColor,
      {bool dashed = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 4,
          decoration: BoxDecoration(
            color: swatch,
            borderRadius: BorderRadius.circular(2),
            border: dashed ? Border.all(color: swatch) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: textColor),
        ),
      ],
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
      ),
      child: Text(
        'Could not load training load: $message',
        style: const TextStyle(color: Colors.redAccent),
      ),
    );
  }
}

Color _colorForState(String state) {
  switch (state) {
    case 'balanced':
      return Colors.green;
    case 'loading':
      return Colors.amber;
    case 'overreaching':
      return Colors.redAccent;
    case 'detraining':
      return Colors.blueGrey;
    case 'calibration':
    default:
      return Colors.grey;
  }
}

String _labelForState(String state) {
  switch (state) {
    case 'balanced':
      return 'Balanced';
    case 'loading':
      return 'Loading';
    case 'overreaching':
      return 'Overreaching';
    case 'detraining':
      return 'Detraining';
    case 'calibration':
      return 'Calibration';
    default:
      return state;
  }
}
