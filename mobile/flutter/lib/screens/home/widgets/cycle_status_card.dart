/// Home dashboard cycle card.
///
/// Shown only when `menstrual_tracking_enabled` (gated via the hormonal
/// profile). Surfaces the current phase, cycle day, next-period / fertile
/// countdown and quick-log buttons; the whole card opens `/cycle`.
///
/// Registered as `HomeSection.cycle` in `home_sections_provider.dart` and
/// rendered by the home screen's section switch.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/hormonal_health.dart';
import '../../../data/providers/hormonal_health_provider.dart';
import '../../../data/services/haptic_service.dart';
import '../../cycle/cycle_screen.dart' show kCycleAccent;
import '../../cycle/cycle_visuals.dart';
import '../../cycle/widgets/log_period_sheet.dart';

class CycleStatusCard extends ConsumerWidget {
  const CycleStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Gate: only render when menstrual tracking is enabled.
    final profileAsync = ref.watch(hormonalProfileProvider);
    final enabled = profileAsync.value?.menstrualTrackingEnabled ?? false;
    if (!enabled) return const SizedBox.shrink();

    final predictionAsync = ref.watch(cyclePredictionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : const Color(0xFF0A0A0A);
    const accent = kCycleAccent;

    return predictionAsync.when(
      loading: () => _CardShell(
        accent: accent,
        fg: fg,
        isDark: isDark,
        child: const SizedBox(
          height: 72,
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: kCycleAccent),
            ),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (prediction) {
        if (prediction == null) return const SizedBox.shrink();
        return _CycleCardBody(
          prediction: prediction,
          accent: accent,
          fg: fg,
          isDark: isDark,
        ).animate().fadeIn(duration: 320.ms);
      },
    );
  }
}

class _CycleCardBody extends ConsumerWidget {
  final CyclePrediction prediction;
  final Color accent;
  final Color fg;
  final bool isDark;

  const _CycleCardBody({
    required this.prediction,
    required this.accent,
    required this.fg,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = prediction.currentPhase;
    final phaseColor = CyclePhaseColors.of(phase);
    final day = prediction.currentCycleDay;
    final headline = _headline();

    return _CardShell(
      accent: accent,
      fg: fg,
      isDark: isDark,
      onTap: () {
        HapticService.light();
        context.push('/cycle');
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: phaseColor.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    CyclePhaseColors.emoji(phase),
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Cycle',
                          style: TextStyle(
                            color: fg.withValues(alpha: 0.5),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                        if (day != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            '· Day $day',
                            style: TextStyle(
                              color: fg.withValues(alpha: 0.5),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      phase?.displayName ?? 'Cycle tracking',
                      style: TextStyle(
                        color: phaseColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: fg.withValues(alpha: 0.35)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            headline,
            style: TextStyle(
              color: fg.withValues(alpha: 0.78),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniLogButton(
                  icon: Icons.water_drop_rounded,
                  label: 'Log period',
                  color: CyclePhaseColors.menstrual,
                  onTap: () => showLogPeriodSheet(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniLogButton(
                  icon: Icons.auto_awesome_rounded,
                  label: 'View cycle',
                  color: accent,
                  onTap: () {
                    HapticService.light();
                    context.push('/cycle');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _headline() {
    final seed = prediction.currentCycleDay ?? 1;
    if (prediction.trackingMode == CycleTrackingMode.pregnancy) {
      return 'Pregnancy mode — predictions paused';
    }
    if (prediction.isLate) {
      return CycleCopy.lateBy(prediction.periodLateBy ?? 0, seed);
    }
    if (prediction.inFertileWindow) {
      return CycleCopy.fertileNow(seed);
    }
    if (prediction.inPeriod) {
      return 'Period in progress — rest well';
    }
    final until = prediction.daysUntilNextPeriod;
    if (until != null) {
      return CycleCopy.periodIn(until, seed);
    }
    return CyclePhaseColors.tagline(prediction.currentPhase);
  }
}

class _CardShell extends StatelessWidget {
  final Color accent;
  final Color fg;
  final bool isDark;
  final Widget child;
  final VoidCallback? onTap;

  const _CardShell({
    required this.accent,
    required this.fg,
    required this.isDark,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withValues(alpha: 0.2)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _MiniLogButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MiniLogButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : const Color(0xFF0A0A0A);
    return GestureDetector(
      onTap: () {
        HapticService.light();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.14 : 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: fg.withValues(alpha: 0.85),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
