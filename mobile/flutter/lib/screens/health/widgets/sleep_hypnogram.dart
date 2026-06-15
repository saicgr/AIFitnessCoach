import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/services/health_service.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Stage-proportion hypnogram for one night's main sleep.
///
/// A true minute-by-minute hypnogram is only possible for nights still
/// inside Health Connect's retention with raw per-stage points. The
/// [SleepSummary] the data layer hands us carries the per-stage MINUTES
/// (deep / light / REM / awake) but not their ordering, so this renders an
/// honest stage-proportion bar — the same approach the plan's Risks section
/// calls for older nights. Deep is drawn lowest, then light, REM, awake on
/// top, mirroring how a clinical hypnogram stacks depth.
///
/// Renders nothing when the night has no staged data at all (a flat
/// un-staged session) — the caller shows the duration headline instead, so
/// no fabricated stages ever appear.
class SleepHypnogram extends StatelessWidget {
  final SleepSummary summary;
  final bool isDark;

  const SleepHypnogram({
    super.key,
    required this.summary,
    required this.isDark,
  });

  bool get _hasStages =>
      summary.deepMinutes > 0 ||
      summary.lightMinutes > 0 ||
      summary.remMinutes > 0 ||
      summary.awakeMinutes > 0;

  @override
  Widget build(BuildContext context) {
    if (!_hasStages) return const SizedBox.shrink();

    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final deep = summary.deepMinutes;
    final rem = summary.remMinutes;
    final awake = summary.awakeMinutes;
    // Light is the residual asleep time so the bar spans the full total even
    // when one session was logged without a deep/light/REM breakdown.
    final reportedLight = summary.lightMinutes;
    final residual = summary.totalMinutes - deep - rem;
    var light = residual > reportedLight ? residual : reportedLight;
    if (light < 0) light = 0;

    final fmt = DateFormat('HH:mm');
    final bed = summary.bedTime;
    final wake = summary.wakeTime;

    // Signature stage legend colours: Awake amber, REM cyan, Light a
    // violet-translucent rung, Deep the full violet (the sleep family hue).
    const awakeColor = Color(0xFFFFD54A);
    final remColor = AppColors.macroCarbs; // cyan #06B6D4
    final lightColor = AppColors.macroProtein.withValues(alpha: 0.55);
    const deepColor = AppColors.macroProtein; // violet #A855F7
    final span = _spanTotal(deep, light, rem, awake);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STAGES',
          style: ZType.lbl(10, color: textMuted, letterSpacing: 2.0),
        ),
        const SizedBox(height: 10),
        // The four stacked stage rows, depth-ordered top → bottom: Awake,
        // REM, Light, Deep. Each row's filled span is proportional to its
        // share of time-in-bed.
        _StageRow(
          label: AppLocalizations.of(context).sleepHypnogramAwake,
          color: awakeColor,
          minutes: awake,
          totalMinutes: span,
          isDark: isDark,
        ),
        const SizedBox(height: 6),
        _StageRow(
          label: 'REM',
          color: remColor,
          minutes: rem,
          totalMinutes: span,
          isDark: isDark,
        ),
        const SizedBox(height: 6),
        _StageRow(
          label: AppLocalizations.of(context).settingsThemeLight,
          color: lightColor,
          minutes: light,
          totalMinutes: span,
          isDark: isDark,
        ),
        const SizedBox(height: 6),
        _StageRow(
          label: AppLocalizations.of(context).sleepHypnogramDeep,
          color: deepColor,
          minutes: deep,
          totalMinutes: span,
          isDark: isDark,
        ),
        if (bed != null && wake != null) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(fmt.format(bed),
                  style: ZType.data(11, color: textMuted)),
              Text(fmt.format(wake),
                  style: ZType.data(11, color: textMuted)),
            ],
          ),
        ],
      ],
    );
  }

  int _spanTotal(int deep, int light, int rem, int awake) {
    final t = deep + light + rem + awake;
    return t > 0 ? t : 1;
  }
}

class _StageRow extends StatelessWidget {
  final String label;
  final Color color;
  final int minutes;
  final int totalMinutes;
  final bool isDark;

  const _StageRow({
    required this.label,
    required this.color,
    required this.minutes,
    required this.totalMinutes,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final track = isDark
        ? AppColors.hairlineStrong
        : Colors.black.withValues(alpha: 0.06);
    final frac = (minutes / totalMinutes).clamp(0.0, 1.0);

    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(
            label.toUpperCase(),
            style: ZType.lbl(10, color: textMuted, letterSpacing: 1.2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              height: 8,
              child: Stack(
                children: [
                  Container(color: track),
                  FractionallySizedBox(
                    widthFactor: frac == 0 ? 0.001 : frac,
                    child: Container(color: color),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 48,
          child: Text(
            _fmtDur(minutes),
            textAlign: TextAlign.end,
            style: ZType.data(11, color: textPrimary),
          ),
        ),
      ],
    );
  }

  String _fmtDur(int minutes) {
    if (minutes <= 0) return '0m';
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h${m}m';
  }
}
