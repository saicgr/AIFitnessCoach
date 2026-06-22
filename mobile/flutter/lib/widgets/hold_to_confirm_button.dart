import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_colors.dart';
import '../l10n/generated/app_localizations.dart';

/// A press-and-hold confirmation button.
///
/// The user holds the button for [holdDuration]; a fill sweeps across and
/// staged haptic ticks build anticipation, then a completion haptic fires
/// and [onConfirmed] is called. Releasing early rewinds the fill.
///
/// The hold is a deliberate commitment gesture — it makes the action feel
/// chosen, not tapped past. Used for the commitment-pact CTA.
///
/// ACCESSIBILITY: a hold gesture is unusable with VoiceOver / TalkBack, so
/// when a screen reader is active ([MediaQuery.accessibleNavigation]) the
/// widget renders a standard single-tap button instead, labelled with
/// [accessibleLabel].
class HoldToConfirmButton extends StatefulWidget {
  /// Hold-mode label, e.g. "Hold to commit".
  final String label;

  /// Tap-mode label used when a screen reader is active, e.g. "I'm in".
  final String accessibleLabel;

  /// Fired once when a hold completes (or on tap in accessible mode).
  final VoidCallback onConfirmed;

  /// When false the button is inert and dimmed (e.g. while submitting).
  final bool enabled;

  /// How long the user must hold.
  final Duration holdDuration;

  const HoldToConfirmButton({
    super.key,
    required this.label,
    required this.accessibleLabel,
    required this.onConfirmed,
    this.enabled = true,
    this.holdDuration = const Duration(milliseconds: 1300),
  });

  @override
  State<HoldToConfirmButton> createState() => _HoldToConfirmButtonState();
}

class _HoldToConfirmButtonState extends State<HoldToConfirmButton>
    with TickerProviderStateMixin {
  late final AnimationController _controller;

  /// A perpetual breathing pulse driven only while the user is holding —
  /// scales the lock glyph + ring subtly so the button feels alive, not
  /// just "filling".
  late final AnimationController _pulse;

  /// Guards [onConfirmed] so it fires exactly once.
  bool _fired = false;

  /// Once true the button shows a brief "COMMITTED ✓" state for
  /// [_committedDwell] before [onConfirmed] actually fires, so the user
  /// gets visible confirmation that the hold landed.
  bool _committed = false;

  /// Index of the last haptic tick fired (ticks at 25/50/75%).
  int _lastTick = 0;

  static const Duration _committedDwell = Duration(milliseconds: 360);

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: widget.holdDuration)
          ..addListener(_onProgress)
          ..addStatusListener(_onStatus);
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onProgress)
      ..removeStatusListener(_onStatus)
      ..dispose();
    _pulse.dispose();
    super.dispose();
  }

  void _onProgress() {
    // Staged anticipation ticks as the fill crosses quarter marks. Ticks
    // get firmer (medium) past the halfway point so the build of intensity
    // is felt, not just seen.
    final tick = (_controller.value * 4).floor();
    if (tick > _lastTick && tick < 4) {
      _lastTick = tick;
      if (tick >= 2) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.selectionClick();
      }
    }
    setState(() {});
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_fired) {
      _fired = true;
      _pulse.stop();
      HapticFeedback.heavyImpact();
      // Show "COMMITTED ✓" for a beat, then hand off. The dwell makes the
      // commitment feel landed instead of instantly yanking the screen away.
      setState(() => _committed = true);
      Future.delayed(_committedDwell, () {
        if (mounted) widget.onConfirmed();
      });
    }
  }

  void _holdStart(_) {
    if (!widget.enabled || _fired) return;
    HapticFeedback.selectionClick();
    _pulse.repeat(reverse: true);
    _controller.forward();
  }

  void _holdEnd([_]) {
    if (_fired) return;
    _lastTick = 0;
    _pulse.stop();
    _pulse.value = 0;
    // Rewind faster than the fill so an accidental brush feels responsive.
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final accessible = MediaQuery.of(context).accessibleNavigation;

    if (accessible) {
      // Screen-reader mode: a plain, fully-accessible tap button.
      return Semantics(
        button: true,
        enabled: widget.enabled,
        label: widget.accessibleLabel,
        child: GestureDetector(
          onTap: widget.enabled && !_fired
              ? () {
                  _fired = true;
                  HapticFeedback.heavyImpact();
                  widget.onConfirmed();
                }
              : null,
          child: _shell(
            progress: 1.0,
            child: _centerLabel(
              widget.accessibleLabel.toUpperCase(),
              progress: 1.0,
              committed: false,
            ),
          ),
        ),
      );
    }

    final progress = _controller.value;
    final holding = progress > 0 && progress < 1 && !_committed;

    final String stateText;
    if (_committed) {
      stateText = 'COMMITTED';
    } else if (holding) {
      stateText = 'KEEP HOLDING…';
    } else {
      stateText = widget.label.toUpperCase();
    }

    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: AppLocalizations.of(
        context,
      )!.holdToConfirmButtonPressAndHoldTo(widget.label),
      child: GestureDetector(
        onTapDown: _holdStart,
        onTapUp: _holdEnd,
        onTapCancel: _holdEnd,
        // Rebuild on every pulse tick so the breathing scale animates while
        // holding (the fill/ring already rebuild via _controller's listener).
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            // Press-down to 0.985, then breathe by up to ~1.2% while holding;
            // on commit it pops back to 1.0.
            final double scale;
            if (_committed) {
              scale = 1.0;
            } else if (holding) {
              scale = 0.985 - 0.012 * _pulse.value;
            } else {
              scale = progress > 0 ? 0.985 : 1.0;
            }
            return Transform.scale(scale: scale, child: child);
          },
          child: _shell(
            progress: _committed ? 1.0 : progress,
            committed: _committed,
            child: _centerLabel(
              stateText,
              progress: _committed ? 1.0 : progress,
              committed: _committed,
            ),
          ),
        ),
      ),
    );
  }

  /// The button body: a dim track with a bright animated gradient fill
  /// clipped to [progress], a glow that intensifies with progress, the
  /// child centred on top.
  Widget _shell({
    required double progress,
    required Widget child,
    bool committed = false,
  }) {
    final clamped = progress.clamp(0.0, 1.0);
    // Animate the gradient stops with progress so the fill looks like it's
    // sweeping/charging, not just statically wider. The accent shifts to a
    // brighter hot-orange as it nears completion.
    final hot = committed ? const Color(0xFF22C55E) : const Color(0xFFFF7A1A);
    final base = committed
        ? const Color(0xFF16A34A)
        : AppColors.onboardingAccent;

    return Opacity(
      opacity: widget.enabled ? 1.0 : 0.5,
      child: DecoratedBox(
        // Glow grows with progress — a flat button suddenly radiating as the
        // user commits reads as "this matters".
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (committed ? hot : AppColors.onboardingAccent).withValues(
                alpha: 0.10 + 0.45 * clamped,
              ),
              blurRadius: 14 + 22 * clamped,
              spreadRadius: -2,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: double.infinity,
            height: 60,
            child: Stack(
              children: [
                // Dim track.
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.onboardingAccent.withValues(alpha: 0.30),
                          const Color(0xFFFF6B00).withValues(alpha: 0.30),
                        ],
                      ),
                    ),
                  ),
                ),
                // Bright fill, clipped to progress width, with an animated
                // gradient that brightens toward the leading edge.
                Positioned.fill(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FractionallySizedBox(
                      widthFactor: clamped,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [base, hot]),
                        ),
                      ),
                    ),
                  ),
                ),
                Center(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Centre content: a circular progress ring wrapping a lock glyph (the
  /// glyph flips to a check on commit), plus the Barlow-Condensed state
  /// label. The ring advances with the hold so the user sees two
  /// reinforcing progress signals (linear fill + radial ring).
  Widget _centerLabel(
    String text, {
    required double progress,
    required bool committed,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 26,
          height: 26,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Faint full ring as the track for the progress arc.
              SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withValues(alpha: 0.22),
                  ),
                ),
              ),
              // Progress arc that advances with the hold.
              SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  strokeWidth: 2.5,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              Icon(
                committed ? Icons.check_rounded : Icons.lock_outline_rounded,
                color: Colors.white,
                size: 14,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            // Signature v2: Barlow Condensed, uppercase, wide tracking.
            fontFamily: 'Barlow Condensed',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 2.0,
          ),
        ),
      ],
    );
  }
}
