import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/animations/bouncy_counter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/hydration.dart';
import '../../../data/repositories/hydration_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/haptic_service.dart';

/// Water quick-log control for the Fasting screen (Section E).
///
/// CRITICAL — single source of truth: this widget logs through the SAME
/// [hydrationProvider] that the Home nutrition card and the Nutrition tab
/// use, in the same unit (ml, the canonical storage unit). Water logged here
/// shows up everywhere immediately. There is NO fasting-local water store.
class FastingHydrationRow extends ConsumerStatefulWidget {
  const FastingHydrationRow({super.key});

  @override
  ConsumerState<FastingHydrationRow> createState() =>
      _FastingHydrationRowState();
}

class _FastingHydrationRowState extends ConsumerState<FastingHydrationRow> {
  bool _loggedOnce = false;
  bool _loggingAmount = false; // true while a quick-log is in flight
  int? _inFlightAmount;

  @override
  void initState() {
    super.initState();
    // Ensure today's summary is loaded so the displayed total is correct even
    // if the fasting screen is the first surface the user opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = ref.read(authStateProvider).user?.id;
      final summary = ref.read(hydrationProvider).todaySummary;
      if (userId != null && summary == null) {
        ref
            .read(hydrationProvider.notifier)
            .loadTodaySummary(userId, showLoading: false);
      }
    });
  }

  Future<void> _quickLog(int amountMl) async {
    if (_loggingAmount) return;
    final userId = ref.read(authStateProvider).user?.id;
    if (userId == null) return;
    HapticService.light();
    setState(() {
      _loggingAmount = true;
      _inFlightAmount = amountMl;
    });
    try {
      // Same provider the rest of the app uses — one count everywhere.
      // `nutrition` source: water + fasting both live in the nutrition domain.
      await ref.read(hydrationProvider.notifier).quickLog(
            userId: userId,
            amountMl: amountMl,
            source: HydrationSource.nutrition,
          );
      if (mounted) setState(() => _loggedOnce = true);
    } finally {
      if (mounted) {
        setState(() {
          _loggingAmount = false;
          _inFlightAmount = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.colors(context);
    final hydration = ref.watch(hydrationProvider);
    final summary = hydration.todaySummary;
    final waterBlue =
        colors.isDark ? AppColors.waterBlue : AppColorsLight.waterBlue;

    final totalMl = summary?.totalMl ?? 0;
    final goalMl = (summary?.goalMl ?? hydration.dailyGoalMl);
    final progress = goalMl > 0 ? (totalMl / goalMl).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: waterBlue.withValues(alpha: 0.16),
                ),
                child: Icon(Icons.water_drop_rounded,
                    size: 18, color: waterBlue),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hydration',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      'Water keeps you energized while fasting',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              // Animated count-up of the running ml total.
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  BouncyCounter(
                    value: totalMl,
                    hapticFeedback: false,
                    textStyle: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: waterBlue,
                    ),
                  ),
                  Text(
                    ' / $goalMl ml',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Progress bar animates up as water is logged.
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: waterBlue.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(waterBlue),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _AddButton(
                  label: '+250 ml',
                  caption: 'Glass',
                  color: waterBlue,
                  busy: _loggingAmount && _inFlightAmount == 250,
                  enabled: !_loggingAmount,
                  onTap: () => _quickLog(250),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _AddButton(
                  label: '+500 ml',
                  caption: 'Bottle',
                  color: waterBlue,
                  busy: _loggingAmount && _inFlightAmount == 500,
                  enabled: !_loggingAmount,
                  onTap: () => _quickLog(500),
                ),
              ),
            ],
          ),
          if (_loggedOnce) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.check_circle,
                    size: 13, color: colors.success),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'Synced — visible on Home and Nutrition too.',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: colors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final String label;
  final String caption;
  final Color color;
  final bool busy;
  final bool enabled;
  final VoidCallback onTap;

  const _AddButton({
    required this.label,
    required this.caption,
    required this.color,
    required this.busy,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.6,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: busy
              ? SizedBox(
                  height: 30,
                  child: Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ),
                )
              : Column(
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    Text(
                      caption,
                      style: TextStyle(
                        fontSize: 10,
                        color: color.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
