import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/services/haptic_service.dart';

/// Staged crate-opening ceremony, pure Flutter (no Lottie/Rive asset needed —
/// crates are emoji-identified throughout the app).
///
/// Stages:
///  1. Drop-in: crate scales in with a bounce.
///  2. Shake loop: rocks side-to-side with ramping amplitude + a light haptic
///     tick per cycle while the claim network call is in flight — the shake
///     IS the loading state, so variable latency just means more anticipation.
///  3. Burst (when [opened] flips true): elastic pop + expanding glow ring +
///     radial sparks while the crate gives way to [revealIcon] rising out.
///     [onOpened] fires when the burst completes.
///
/// The parent drives it with a single bool — mount with `opened: false`
/// during the claim, flip to `true` on success. Everything else is internal.
class CrateOpeningPlay extends StatefulWidget {
  final Color color;

  /// Crate emoji shown while closed/shaking (📦 / 🔥 / ⭐...).
  final String icon;

  /// Emoji that rises out of the burst. Defaults to 🎁.
  final String revealIcon;

  /// Flip to true when the claim finished — triggers the burst.
  final bool opened;

  /// Fired once, after the burst animation completes.
  final VoidCallback? onOpened;

  /// Crate emoji size.
  final double size;

  /// Optional caption under the crate (e.g. "3 crates").
  final String? caption;

  const CrateOpeningPlay({
    super.key,
    required this.color,
    this.icon = '\u{1F4E6}',
    this.revealIcon = '\u{1F381}',
    required this.opened,
    this.onOpened,
    this.size = 64,
    this.caption,
  });

  @override
  State<CrateOpeningPlay> createState() => _CrateOpeningPlayState();
}

class _CrateOpeningPlayState extends State<CrateOpeningPlay>
    with TickerProviderStateMixin {
  late final AnimationController _dropCtrl;
  late final AnimationController _shakeCtrl;
  late final AnimationController _rampCtrl;
  late final AnimationController _burstCtrl;
  double _lastShakeValue = 0;
  bool _notifiedOpened = false;

  @override
  void initState() {
    super.initState();
    _dropCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    )..forward();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    // Amplitude ramp: starts gentle, works up to a full rattle.
    _rampCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _burstCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );

    _shakeCtrl.addListener(_onShakeTick);
    _burstCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_notifiedOpened) {
        _notifiedOpened = true;
        widget.onOpened?.call();
      }
    });

    if (widget.opened) {
      // Mounted already-opened (edge case): skip straight to the burst.
      _burstCtrl.forward();
    } else {
      _shakeCtrl.repeat();
      _rampCtrl.forward();
    }
  }

  void _onShakeTick() {
    // Cycle wrap detection → one light haptic tick per rock.
    if (_shakeCtrl.value < _lastShakeValue && !widget.opened) {
      HapticService.light();
    }
    _lastShakeValue = _shakeCtrl.value;
  }

  @override
  void didUpdateWidget(CrateOpeningPlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.opened && !oldWidget.opened) {
      _shakeCtrl.stop();
      HapticService.medium();
      _burstCtrl.forward();
    }
  }

  @override
  void dispose() {
    _dropCtrl.dispose();
    _shakeCtrl.dispose();
    _rampCtrl.dispose();
    _burstCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stageSize = widget.size * 2.6;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: stageSize,
          height: stageSize,
          child: AnimatedBuilder(
            animation: Listenable.merge(
                [_dropCtrl, _shakeCtrl, _rampCtrl, _burstCtrl]),
            builder: (context, _) {
              final drop = Curves.easeOutBack.transform(_dropCtrl.value);
              final burstT = _burstCtrl.value;
              final burstCurve = Curves.easeOutCubic.transform(burstT);

              // Rocking rotation, amplitude ramping 0.035 → 0.1 rad,
              // squashed to zero as the burst takes over.
              final amplitude = 0.035 + 0.065 * _rampCtrl.value;
              final rotation = math.sin(_shakeCtrl.value * 2 * math.pi) *
                  amplitude *
                  (1 - burstT);

              // Crate: elastic pop up then fade as the reward takes over.
              final cratePop = burstT == 0
                  ? 1.0
                  : 1.0 + 0.35 * Curves.elasticOut.transform(burstT);
              final crateOpacity =
                  burstT < 0.35 ? 1.0 : (1 - (burstT - 0.35) / 0.35).clamp(0.0, 1.0);

              // Reward: rises out of the burst point.
              final rewardT = burstT < 0.3
                  ? 0.0
                  : Curves.easeOutBack.transform((burstT - 0.3) / 0.7);

              // Glow behind the crate breathes with the shake, flashes on burst.
              final breathe =
                  0.5 + 0.5 * math.sin(_shakeCtrl.value * 2 * math.pi);
              final glowOpacity = burstT > 0
                  ? (0.55 * (1 - burstCurve))
                  : (0.18 + 0.14 * breathe * _rampCtrl.value);
              final glowScale =
                  burstT > 0 ? 1.0 + 1.4 * burstCurve : 1.0 + 0.06 * breathe;

              return Stack(
                alignment: Alignment.center,
                children: [
                  // Glow.
                  Transform.scale(
                    scale: glowScale,
                    child: Container(
                      width: widget.size * 1.6,
                      height: widget.size * 1.6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            widget.color.withOpacity(glowOpacity),
                            widget.color.withOpacity(0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Ring + sparks on burst.
                  if (burstT > 0)
                    CustomPaint(
                      size: Size.square(stageSize),
                      painter: _BurstPainter(t: burstCurve, color: widget.color),
                    ),
                  // Crate.
                  if (crateOpacity > 0)
                    Opacity(
                      opacity: crateOpacity,
                      child: Transform.rotate(
                        angle: rotation,
                        child: Transform.scale(
                          scale: drop * cratePop,
                          child: Text(
                            widget.icon,
                            style: TextStyle(fontSize: widget.size),
                          ),
                        ),
                      ),
                    ),
                  // Reward rising out.
                  if (rewardT > 0)
                    Transform.translate(
                      offset: Offset(0, -widget.size * 0.45 * rewardT),
                      child: Transform.scale(
                        scale: rewardT,
                        child: Text(
                          widget.revealIcon,
                          style: TextStyle(fontSize: widget.size * 0.82),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        if (widget.caption != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.caption!,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white60
                  : Colors.black54,
            ),
          ),
        ],
      ],
    );
  }
}

/// Expanding ring + radial sparks for the burst instant. Deterministic
/// pseudo-random spread from the spark index (no dart:math Random so the
/// paint is stable across frames).
class _BurstPainter extends CustomPainter {
  final double t; // 0..1, already eased
  final Color color;

  _BurstPainter({required this.t, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxR = size.shortestSide / 2;
    final fade = (1 - t).clamp(0.0, 1.0);

    // Ring.
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5 * fade + 0.5
      ..color = color.withOpacity(0.8 * fade);
    canvas.drawCircle(center, maxR * (0.25 + 0.65 * t), ringPaint);

    // Sparks.
    const sparkCount = 10;
    for (var i = 0; i < sparkCount; i++) {
      final angle = (i / sparkCount) * 2 * math.pi + (i.isEven ? 0.18 : -0.12);
      final jitter = 0.75 + 0.25 * ((i * 7) % 5) / 4; // 0.75..1.0 spread
      final dist = maxR * (0.3 + 0.62 * t) * jitter;
      final pos = center + Offset(math.cos(angle), math.sin(angle)) * dist;
      final sparkPaint = Paint()
        ..color = (i % 3 == 0 ? Colors.white : color).withOpacity(0.9 * fade);
      canvas.drawCircle(pos, (3.2 - 2.4 * t) * jitter, sparkPaint);
    }
  }

  @override
  bool shouldRepaint(_BurstPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.color != color;
}
