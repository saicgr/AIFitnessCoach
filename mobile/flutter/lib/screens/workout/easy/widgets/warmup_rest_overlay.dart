// Easy tier — rest countdown BETWEEN warm-up moves.
//
// E2E #125 ask #2 — the warm-up used to jump straight from one move to the
// next with no pacing at all. The countdown state itself
// (`_warmupResting`/`_warmupRestRemaining`/`_warmupRestTimer`) lives in
// `easy_active_workout_state.dart` as a plain polled `Timer.periodic` (not
// the stream-based broadcaster the working-set rest overlay uses — a
// warm-up rest has no weight×reps target to preview, so that heavier
// machinery isn't needed). This widget is the render surface for it: a
// full-screen replacement for `EasyActiveWorkoutView` while resting,
// wired from `_buildWarmupView`.

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class WarmupRestOverlay extends StatelessWidget {
  /// Seconds left in the current rest, from `_warmupRestRemaining`.
  final int secondsRemaining;

  /// The rest duration this countdown STARTED at, from `_warmupRestTotal` —
  /// drives the draining progress bar. Falls back to `secondsRemaining`
  /// itself (a full bar) if unset, so a 0/0 division never renders broken.
  final int totalSeconds;

  /// Name of the move coming up next, or null on the last move (the next
  /// thing is the working sets, not another hold).
  final String? nextMoveName;

  final VoidCallback onSkip;
  final bool isDark;
  final Color accent;

  const WarmupRestOverlay({
    super.key,
    required this.secondsRemaining,
    required this.totalSeconds,
    required this.onSkip,
    required this.isDark,
    required this.accent,
    this.nextMoveName,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.background : Colors.white;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final total = totalSeconds > 0 ? totalSeconds : secondsRemaining;
    final frac = total <= 0 ? 0.0 : (secondsRemaining / total).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.self_improvement_rounded,
                      size: 56, color: accent),
                ),
                const SizedBox(height: 24),
                Text(
                  'REST',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: accent,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '$secondsRemaining',
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w300,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: frac,
                    minHeight: 4,
                    backgroundColor:
                        (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                  ),
                ),
                if (nextMoveName != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Next: $nextMoveName',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                TextButton(
                  onPressed: onSkip,
                  child: Text(
                    'Skip rest',
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
