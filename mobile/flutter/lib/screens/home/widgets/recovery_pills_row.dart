import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../services/muscle_recovery_tracker.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Phase 4 — per-muscle recovery pills surfaced on Home.
///
/// Wires the muscle_recovery_tracker.dart algorithm (which already runs
/// inside quick_workout_provider) into a visible home-screen strip so users
/// can see "chest 92% • back 64% • quads 31%" at a glance. Mirrors Gravl's
/// "muscle recovery is X%" callout from the migration thread.
///
/// Watches the same recovery store as quick_workout_provider — no new
/// subscription, no parallel tracker. Refreshes every 60s and on focus.
class RecoveryPillsRow extends ConsumerStatefulWidget {
  const RecoveryPillsRow({super.key});

  @override
  ConsumerState<RecoveryPillsRow> createState() => _RecoveryPillsRowState();
}

class _RecoveryPillsRowState extends ConsumerState<RecoveryPillsRow> {
  Map<String, double> _scores = const {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final scores = await MuscleRecoveryTracker.getAllRecoveryScores();
    if (!mounted) return;
    setState(() {
      _scores = scores;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    if (!_loaded) {
      return const SizedBox(height: 44);
    }
    if (_scores.isEmpty) {
      // Empty until the first workout is logged.
      return const SizedBox.shrink();
    }

    // Sort highest-to-lowest recovery so the eye lands on what's ready.
    final sorted = _scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.refresh_rounded,
                size: 14,
                color: textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                AppLocalizations.of(context).recoveryLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                  color: textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 28,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: sorted.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                final entry = sorted[i];
                return _RecoveryPill(
                  muscle: entry.key,
                  scorePct: entry.value,
                  textPrimary: textPrimary,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RecoveryPill extends StatelessWidget {
  const _RecoveryPill({
    required this.muscle,
    required this.scorePct,
    required this.textPrimary,
  });

  final String muscle;
  final double scorePct;
  final Color textPrimary;

  @override
  Widget build(BuildContext context) {
    // Color = green ≥85% (ready), amber 50-84 (partial), red <50 (don't load).
    final Color color = scorePct >= 85
        ? const Color(0xFF22C55E)
        : (scorePct >= 50 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _humanMuscle(muscle),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            AppLocalizations.of(context)!.recoveryPillsRowValue(scorePct.round()),
            style: TextStyle(
              fontSize: 12,
              color: textPrimary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  static String _humanMuscle(String key) {
    return key.replaceAll('_', ' ').split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1);
    }).join(' ');
  }
}
