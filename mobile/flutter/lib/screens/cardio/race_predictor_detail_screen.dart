import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/accent_color_provider.dart';
import '../../data/repositories/race_predictor_repository.dart';
import '../../widgets/cardio/race_predictor_card.dart' show formatRaceTime;
import '../../widgets/glass_back_button.dart';
import '../pillar/widgets/ask_coach_button.dart';

/// Race-time predictor detail screen.
///
/// Self-contained for now — when the later MetricDetailScreen wave lands,
/// this screen will be refactored onto the shared base. Today it mirrors
/// the pillar detail layout informally: hero block, body tiles, methodology,
/// Ask Coach footer.
class RacePredictorDetailScreen extends ConsumerWidget {
  const RacePredictorDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(racePredictionsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 16, 4),
              child: Row(
                children: [
                  const GlassBackButton(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Race predictor',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: async.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Could not load predictions.\n$e',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                data: (predictions) =>
                    _Body(predictions: predictions),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

class _Body extends StatelessWidget {
  final Map<String, RacePrediction?> predictions;
  const _Body({required this.predictions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final firstPred = predictions.values.firstWhere(
      (v) => v != null,
      orElse: () => null,
    );

    if (firstPred == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.directions_run_rounded,
                size: 48,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 16),
              Text(
                'No predictions yet',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Log at least three runs, including one measured kilometre, and a prediction will appear.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _BaseRunHero(baseRun: firstPred.baseRun),
        const SizedBox(height: 20),
        for (final key in const ['five_k', 'ten_k', 'half_marathon', 'marathon'])
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _PredictionTile(
              label: _labelFor(key),
              prediction: predictions[key],
            ),
          ),
        const SizedBox(height: 12),
        const _MethodologySection(),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AskCoachButton(
              contextLabel: 'Race time predictions',
              statSnapshot: {
                'source': 'race_predictor',
                'predictions': {
                  for (final e in predictions.entries)
                    e.key: e.value == null
                        ? null
                        : {
                            'predicted_seconds': e.value!.predictedSeconds,
                            'distance_m': e.value!.distanceM,
                            'confidence': e.value!.confidence,
                            'formula': e.value!.formula,
                          },
                },
                'base_run': firstPred.baseRun.toJson(),
              },
            ),
            const SizedBox(width: 10),
            Text(
              'Ask coach',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static String _labelFor(String key) {
    switch (key) {
      case 'five_k':
        return '5K';
      case 'ten_k':
        return '10K';
      case 'half_marathon':
        return 'Half marathon';
      case 'marathon':
        return 'Marathon';
    }
    return key;
  }
}

// ---------------------------------------------------------------------------
// Hero — base run
// ---------------------------------------------------------------------------

class _BaseRunHero extends StatelessWidget {
  final BaseRunRef baseRun;
  const _BaseRunHero({required this.baseRun});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final onSurface = theme.colorScheme.onSurface;

    final km = baseRun.distanceM / 1000.0;
    final paceSecPerKm =
        baseRun.distanceM > 0 ? baseRun.timeSeconds / km : 0.0;
    final paceStr = _formatPace(paceSecPerKm);
    final whenStr = DateFormat.yMMMd().format(baseRun.performedAt);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.18),
            accent.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your best run',
            style: theme.textTheme.labelMedium?.copyWith(
              color: onSurface.withValues(alpha: 0.6),
              letterSpacing: 0.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${km.toStringAsFixed(2)} km in ${formatRaceTime(baseRun.timeSeconds)}',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: accent,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _heroStat(theme, 'Pace', '$paceStr /km'),
              _heroStat(theme, 'When', whenStr),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _heroStat(ThemeData theme, String label, String value) {
    final onSurface = theme.colorScheme.onSurface;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label  ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: onSurface.withValues(alpha: 0.55),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: onSurface,
          ),
        ),
      ],
    );
  }

  static String _formatPace(double secondsPerKm) {
    if (secondsPerKm <= 0) return '--:--';
    final m = secondsPerKm ~/ 60;
    final s = (secondsPerKm % 60).round();
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

// ---------------------------------------------------------------------------
// Per-distance tile
// ---------------------------------------------------------------------------

class _PredictionTile extends StatelessWidget {
  final String label;
  final RacePrediction? prediction;
  const _PredictionTile({required this.label, required this.prediction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final onSurface = theme.colorScheme.onSurface;
    final disabled = prediction == null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: onSurface.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (disabled)
            Text(
              'Need more data',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: onSurface.withValues(alpha: 0.5),
              ),
            )
          else
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${formatRaceTime(prediction!.predictedSeconds)}  ± ${formatRaceTime(prediction!.confidenceBandSeconds)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${prediction!.formula == 'cameron' ? 'Cameron formula' : 'Riegel formula'} · ${(prediction!.confidence * 100).round()}% confidence',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: onSurface.withValues(alpha: 0.55),
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
// Methodology section
// ---------------------------------------------------------------------------

class _MethodologySection extends StatelessWidget {
  const _MethodologySection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How predictions are calculated',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Riegel formula (T2 = T1 × (D2/D1)^1.06) is used at short '
            'and middle distances where it stays within ~2× the base run. '
            'For half-marathon and marathon predictions from a shorter base, '
            'we switch to the Cameron formula, which is empirically more '
            'accurate at the longer extrapolation range. Confidence drops '
            'when the base run is shorter than the target distance and '
            'decays slowly as the run ages.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: onSurface.withValues(alpha: 0.75),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sources: Riegel PS, "Athletic records and human endurance" '
            '(American Scientist, 1981); Cameron coefficients per Pete '
            'Riegel\'s published derivation.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: onSurface.withValues(alpha: 0.45),
              fontStyle: FontStyle.italic,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
