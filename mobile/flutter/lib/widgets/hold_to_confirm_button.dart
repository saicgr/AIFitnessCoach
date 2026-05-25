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
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  /// Guards [onConfirmed] so it fires exactly once.
  bool _fired = false;

  /// Index of the last haptic tick fired (ticks at 25/50/75%).
  int _lastTick = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.holdDuration,
    )
      ..addListener(_onProgress)
      ..addStatusListener(_onStatus);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onProgress)
      ..removeStatusListener(_onStatus)
      ..dispose();
    super.dispose();
  }

  void _onProgress() {
    // Staged anticipation ticks as the fill crosses quarter marks.
    final tick = (_controller.value * 4).floor();
    if (tick > _lastTick && tick < 4) {
      _lastTick = tick;
      HapticFeedback.selectionClick();
    }
    setState(() {});
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_fired) {
      _fired = true;
      HapticFeedback.heavyImpact();
      widget.onConfirmed();
    }
  }

  void _holdStart(_) {
    if (!widget.enabled || _fired) return;
    HapticFeedback.selectionClick();
    _controller.forward();
  }

  void _holdEnd([_]) {
    if (_fired) return;
    _lastTick = 0;
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
            child: _centerLabel(widget.accessibleLabel),
          ),
        ),
      );
    }

    final progress = _controller.value;
    final holding = progress > 0 && progress < 1;

    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: AppLocalizations.of(context)!.holdToConfirmButtonPressAndHoldTo(widget.label),
      child: GestureDetector(
        onTapDown: _holdStart,
        onTapUp: _holdEnd,
        onTapCancel: _holdEnd,
        child: AnimatedScale(
          scale: holding ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: _shell(
            progress: progress,
            child: _centerLabel(
              holding ? 'Keep holding…' : widget.label,
              icon: holding ? null : Icons.lock_outline_rounded,
            ),
          ),
        ),
      ),
    );
  }

  /// The button body: a dim track with a bright gradient fill clipped to
  /// [progress], the child centred on top.
  Widget _shell({required double progress, required Widget child}) {
    return Opacity(
      opacity: widget.enabled ? 1.0 : 0.5,
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
                        AppColors.onboardingAccent.withValues(alpha: 0.32),
                        const Color(0xFFFF6B00).withValues(alpha: 0.32),
                      ],
                    ),
                  ),
                ),
              ),
              // Bright fill, clipped to progress width.
              Positioned.fill(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FractionallySizedBox(
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.onboardingAccent,
                            Color(0xFFFF6B00),
                          ],
                        ),
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
    );
  }

  Widget _centerLabel(String text, {IconData? icon}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
        ],
        Text(
          text,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}
