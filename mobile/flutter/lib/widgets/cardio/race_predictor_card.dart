import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/accent_color_provider.dart';
import '../../data/repositories/race_predictor_repository.dart';
import '../../screens/cardio/race_predictor_detail_screen.dart';
import '../../screens/pillar/widgets/ask_coach_button.dart';

/// Race-time predictor card for the cardio profile.
///
/// Renders 4 chips (5K / 10K / Half / Marathon) showing predicted finish
/// times from the user's all-time best run. Empty state prompts the user
/// to log a measured run. Tapping any chip → detail screen with confidence
/// bands + Ask Coach.
///
/// Placement on the cardio profile is owned by a later wiring wave — this
/// widget is self-contained so it can be dropped into a Column/SliverList
/// anywhere.
class RacePredictorCard extends ConsumerWidget {
  const RacePredictorCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(racePredictionsProvider);
    return async.when(
      loading: () => const _RacePredictorShell(child: _LoadingBody()),
      error: (e, _) => _RacePredictorShell(child: _ErrorBody(message: '$e')),
      data: (map) {
        final hasAny = map.values.any((v) => v != null);
        if (!hasAny) {
          return const _RacePredictorShell(child: _EmptyBody());
        }
        return _RacePredictorShell(
          child: _LoadedBody(predictions: map),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Shell — Theme surface, 20px BR, header
// ---------------------------------------------------------------------------

class _RacePredictorShell extends StatelessWidget {
  final Widget child;
  const _RacePredictorShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: onSurface.withValues(alpha: 0.06)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.directions_run_rounded,
                size: 18,
                color: onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Race predictor',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 64,
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final String message;
  const _ErrorBody({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        'Could not load predictions.\n$message',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
    );
  }
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Run a measured km or two for your first prediction',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: onSurface.withValues(alpha: 0.75),
            height: 1.35,
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonalIcon(
            onPressed: () {
              // Cardio logging entry point — log_cardio_screen.dart route.
              GoRouter.of(context).push('/cardio/log');
            },
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Log run'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadedBody extends StatelessWidget {
  final Map<String, RacePrediction?> predictions;
  const _LoadedBody({required this.predictions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final onSurface = theme.colorScheme.onSurface;

    // The first non-null prediction has the base_run — they all share it.
    final firstPred = predictions.values.firstWhere(
      (v) => v != null,
      orElse: () => null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 76,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final entry in predictions.entries)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _PredictionChip(
                    label: _labelFor(entry.key),
                    prediction: entry.value,
                    accent: accent,
                    onTap: () => _openDetail(context),
                  ),
                ),
            ],
          ),
        ),
        if (firstPred != null) ...[
          const SizedBox(height: 10),
          Text(
            _footnote(firstPred.baseRun),
            style: theme.textTheme.bodySmall?.copyWith(
              color: onSurface.withValues(alpha: 0.55),
              fontSize: 11.5,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            const Spacer(),
            AskCoachButton(
              // SLICE_COACH owns adding a `source` param to AskCoachButton.
              // Until then, `race_predictor` is carried in statSnapshot.source
              // and the chat screen / coach_agent will branch on that.
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
                if (firstPred != null) 'base_run': firstPred.baseRun.toJson(),
              },
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
        return 'Half';
      case 'marathon':
        return 'Marathon';
    }
    return key;
  }

  static String _footnote(BaseRunRef baseRun) {
    final km = (baseRun.distanceM / 1000).toStringAsFixed(1);
    final whenStr = DateFormat.MMMd().format(baseRun.performedAt);
    return 'Based on your $km km run from $whenStr';
  }

  static void _openDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const RacePredictorDetailScreen(),
      ),
    );
  }
}

class _PredictionChip extends StatelessWidget {
  final String label;
  final RacePrediction? prediction;
  final Color accent;
  final VoidCallback onTap;

  const _PredictionChip({
    required this.label,
    required this.prediction,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final disabled = prediction == null;
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 92,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: disabled
              ? onSurface.withValues(alpha: 0.04)
              : accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: disabled
                ? onSurface.withValues(alpha: 0.06)
                : accent.withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              disabled ? '--' : formatRaceTime(prediction!.predictedSeconds),
              style: theme.textTheme.titleMedium?.copyWith(
                color: disabled ? onSurface.withValues(alpha: 0.45) : accent,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Format seconds as M:SS or H:MM:SS depending on duration.
String formatRaceTime(int seconds) {
  if (seconds < 0) return '--';
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  if (h > 0) {
    return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
  return '$m:${s.toString().padLeft(2, '0')}';
}
