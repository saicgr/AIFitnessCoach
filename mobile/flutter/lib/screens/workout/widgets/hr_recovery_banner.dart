/// Heart-rate-aware rest banner.
///
/// Shown when a between-set rest countdown has elapsed but the lifter's live
/// heart rate is still elevated. Self-contained: it watches the live HR stream,
/// computes the recovery target via [HrRecoveryPolicy], and either nudges the
/// lifter to rest longer ('suggest' mode) or holds and auto-advances once HR
/// settles ('gate' mode, Polar-style). Always offers a manual override, so it
/// never truly blocks.
///
/// Drives the flow back to the host through [onReady] (start the next set now)
/// and [onExtend] (rest N more seconds, then re-check). The host owns rest
/// state; this widget owns only the recovery presentation + detection.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/heart_rate_provider.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/services/haptic_service.dart';
import 'hr_recovery_policy.dart';

class HrRecoveryBanner extends ConsumerStatefulWidget {
  /// 'suggest' (nudge) or 'gate' (hold + auto-advance).
  final String mode;

  /// Peak BPM captured during the just-finished set (for the relative target
  /// and the recovery progress bar).
  final int? peakHr;

  /// User age (→ max HR) and resting HR, when known, for a personalized target.
  final int? age;
  final int? restingHr;

  /// Hard ceiling on how long 'gate' will hold before auto-advancing, so a
  /// noisy/never-settling HR can't trap the lifter.
  final int maxHoldSeconds;

  /// Start the next set now.
  final VoidCallback onReady;

  /// Rest [seconds] more, then re-evaluate ('suggest' +30s path).
  final void Function(int seconds) onExtend;

  const HrRecoveryBanner({
    super.key,
    required this.mode,
    required this.onReady,
    required this.onExtend,
    this.peakHr,
    this.age,
    this.restingHr,
    this.maxHoldSeconds = 120,
  });

  @override
  ConsumerState<HrRecoveryBanner> createState() => _HrRecoveryBannerState();
}

class _HrRecoveryBannerState extends ConsumerState<HrRecoveryBanner> {
  Timer? _ticker;
  int _elapsed = 0;
  int? _minHr; // lowest BPM seen since the banner mounted
  bool _resolved = false; // guard against double onReady

  bool get _isGate => widget.mode == 'gate';

  @override
  void initState() {
    super.initState();
    // 1s ticker enforces the gate hold-cap even if HR stops updating.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed++);
      if (_isGate && _elapsed >= widget.maxHoldSeconds) {
        _finish(); // cap reached — let them lift
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _finish() {
    if (_resolved) return;
    _resolved = true;
    HapticService.restTimerComplete();
    widget.onReady();
  }

  HrRecoveryTarget? get _target => HrRecoveryPolicy.recoveryTarget(
        age: widget.age,
        restingHr: widget.restingHr,
        peakHr: widget.peakHr,
        minHrThisRest: _minHr,
      );

  /// Deterministic nudge headline (stable for a given rest, varied across rests).
  String _suggestHeadline() {
    const pool = [
      "Heart rate's still up — rest a few more seconds?",
      "Catch your breath — your heart rate hasn't settled yet.",
      "Still coming down — give it a moment before the next set?",
      "HR's a touch high — a bit more rest will help the next set.",
    ];
    final seed = (widget.peakHr ?? 0) + (_target?.targetBpm ?? 0);
    return pool[seed.abs() % pool.length];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = ThemeColors.of(context).accent;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final reading = ref.watch(liveHeartRateProvider).value;
    final bpm = reading?.bpm;

    // Track the lull as HR descends.
    if (bpm != null && (_minHr == null || bpm < _minHr!)) {
      _minHr = bpm;
    }

    final target = _target;
    final recovered =
        bpm != null && target != null && HrRecoveryPolicy.isRecovered(bpm, target.targetBpm);

    // Gate mode: auto-advance the moment HR settles. Scheduled post-frame so we
    // never call back synchronously during build.
    if (_isGate && recovered && !_resolved) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
    }

    final maxHr =
        (widget.age != null && widget.age! > 0) ? HrRecoveryPolicy.maxHrForAge(widget.age!) : 190;
    final zone = bpm != null ? getHeartRateZone(bpm, maxHr: maxHr) : null;
    final hrColor = zone != null ? Color(zone.colorValue) : Colors.grey;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF15161A) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: hrColor.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Live HR + target row.
          Row(
            children: [
              Icon(Icons.favorite, size: 18, color: hrColor),
              const SizedBox(width: 7),
              Text(
                bpm != null ? '$bpm' : '--',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: hrColor,
                  height: 1,
                ),
              ),
              const SizedBox(width: 4),
              Text('bpm', style: TextStyle(fontSize: 12, color: textMuted)),
              const Spacer(),
              if (target != null)
                _TargetChip(
                  target: target.targetBpm,
                  recovered: recovered,
                  accent: accent,
                  textMuted: textMuted,
                ),
            ],
          ),
          const SizedBox(height: 10),

          if (recovered) ...[
            Text(
              "Recovered — you're good to go.",
              style: TextStyle(
                  fontSize: 13.5, fontWeight: FontWeight.w600, color: textPrimary),
            ),
          ] else if (_isGate) ...[
            Text('RECOVERING',
                style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: textMuted)),
            const SizedBox(height: 6),
            _RecoveryProgressBar(
              bpm: bpm,
              peakHr: widget.peakHr,
              targetBpm: target?.targetBpm,
              color: hrColor,
            ),
            const SizedBox(height: 6),
            Text('Auto-starts the moment your heart rate settles.',
                style: TextStyle(fontSize: 11, color: textMuted)),
          ] else ...[
            Text(_suggestHeadline(),
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                    height: 1.3)),
          ],

          const SizedBox(height: 12),
          _buildActions(accent, recovered),
        ],
      ),
    );
  }

  Widget _buildActions(Color accent, bool recovered) {
    // Recovered, or gate mode (hands-free): one clear "start" affordance.
    if (recovered || _isGate) {
      return SizedBox(
        width: double.infinity,
        child: _PrimaryButton(
          label: recovered ? 'Start set' : "I'm ready",
          accent: accent,
          onTap: _finish,
        ),
      );
    }
    // Suggest mode, still elevated: +30s nudge + start-anytime.
    return Row(
      children: [
        Expanded(
          child: _SecondaryButton(
            label: '+30s',
            accent: accent,
            onTap: () {
              if (_resolved) return;
              _resolved = true;
              HapticService.selection();
              widget.onExtend(30);
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PrimaryButton(
            label: 'Start set',
            accent: accent,
            onTap: _finish,
          ),
        ),
      ],
    );
  }
}

class _TargetChip extends StatelessWidget {
  final int target;
  final bool recovered;
  final Color accent;
  final Color textMuted;

  const _TargetChip({
    required this.target,
    required this.recovered,
    required this.accent,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    final c = recovered ? AppColors.success : textMuted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(recovered ? Icons.check_circle : Icons.arrow_forward,
            size: 13, color: c),
        const SizedBox(width: 4),
        Text('$target',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
                color: c)),
        const SizedBox(width: 2),
        Text('target', style: TextStyle(fontSize: 11, color: textMuted)),
      ],
    );
  }
}

class _RecoveryProgressBar extends StatelessWidget {
  final int? bpm;
  final int? peakHr;
  final int? targetBpm;
  final Color color;

  const _RecoveryProgressBar({
    required this.bpm,
    required this.peakHr,
    required this.targetBpm,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    double progress = 0;
    if (bpm != null && peakHr != null && targetBpm != null && peakHr! > targetBpm!) {
      progress = (peakHr! - bpm!) / (peakHr! - targetBpm!);
      progress = progress.clamp(0.0, 1.0);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 6,
        backgroundColor: color.withValues(alpha: 0.16),
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final Color accent;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.label,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: ThemeColors.of(context).accentContrast,
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final Color accent;
  final VoidCallback onTap;

  const _SecondaryButton({
    required this.label,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accent.withValues(alpha: 0.4)),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: accent,
          ),
        ),
      ),
    );
  }
}
