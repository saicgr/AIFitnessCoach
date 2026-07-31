// Easy tier — FULL-SCREEN rest countdown.
//
// Unlike Simple's inline rest bar, Easy hides the whole workout surface
// behind a calm full-screen overlay during rest. The only affordance
// is a big countdown number + a single "Skip rest" text button. On
// countdown zero the screen auto-dismisses (caller pops and advances).
//
// Pushed via `Navigator.of(context).push(PageRouteBuilder(...))` with
// a transparent opaque=false route so the underlying Easy screen stays
// alive in the tree (controllers, timers, provider subscriptions).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/haptic_service.dart';
import '../../../../core/theme/accent_color_provider.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/models/exercise.dart';

import '../../../../l10n/generated/app_localizations.dart';
/// Full-screen rest countdown overlay.
///
/// Wire-up (call-site):
///   Navigator.of(context).push(
///     PageRouteBuilder(
///       opaque: false,
///       barrierColor: Colors.black.withValues(alpha: 0.92),
///       pageBuilder: (_, __, ___) => EasyRestOverlay(...),
///     ),
///   );
class EasyRestOverlay extends ConsumerStatefulWidget {
  final int initialSeconds;

  /// Stream of remaining seconds from the parent's WorkoutTimerController.
  /// The overlay listens and pops automatically when this hits 0.
  final Stream<int> remainingStream;

  final WorkoutExercise nextExercise;
  final int nextSetNumber;
  final int totalSets;
  final double nextTargetWeightKg; // already in kg; display converts if needed
  final int nextTargetReps;
  final bool useKg;

  final VoidCallback onSkip;
  final VoidCallback onDone;

  /// ±15s rest adjustments — wired to WorkoutTimerController.adjustRestTime
  /// (the tick re-broadcasts through `remainingStream`, so the countdown
  /// updates in place). Optional so older call-sites still compile.
  final VoidCallback? onAddTime;
  final VoidCallback? onSubtractTime;

  /// Pause / resume the rest countdown — wired to
  /// WorkoutTimerController.toggleRestPause. Optional so older call-sites
  /// still compile.
  final VoidCallback? onPause;

  /// Quick-log a cup of water mid-rest (the 💧 control in the strip — mockup).
  final VoidCallback? onLogWater;

  const EasyRestOverlay({
    super.key,
    required this.initialSeconds,
    required this.remainingStream,
    required this.nextExercise,
    required this.nextSetNumber,
    required this.totalSets,
    required this.nextTargetWeightKg,
    required this.nextTargetReps,
    required this.useKg,
    required this.onSkip,
    required this.onDone,
    this.onAddTime,
    this.onSubtractTime,
    this.onPause,
    this.onLogWater,
  });

  @override
  ConsumerState<EasyRestOverlay> createState() => _EasyRestOverlayState();
}

class _EasyRestOverlayState extends ConsumerState<EasyRestOverlay> {
  late int _remaining;
  late final Stream<int> _stream;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.initialSeconds;
    _stream = widget.remainingStream;
    _stream.listen((s) {
      if (!mounted) return;
      setState(() => _remaining = s);
      if (s <= 0) {
        widget.onDone();
      }
    });
  }

  String _fmtWeight(double kg) {
    final v = widget.useKg ? kg : kg * 2.20462;
    if (v <= 0) return '—';
    return v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
  }

  // `nextSetNumber` is derived from `completed.length + 1` by the resolver
  // (easy_rest_controller.dart) and can point one PAST the plan for the
  // same reason the header hit "SET 3 OF 2" — clamp the displayed number so
  // this surface, which is visible for the whole rest window, never shows
  // an impossible set index.
  int get _displaySetNumber =>
      widget.nextSetNumber > widget.totalSets
          ? widget.totalSets
          : widget.nextSetNumber;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final unit = widget.useKg ? 'kg' : 'lb';

    // Draining-bar fraction (`.ir-strip`'s bar). 1.0 at start → 0.0 at zero.
    final double frac = widget.initialSeconds <= 0
        ? 0.0
        : (_remaining / widget.initialSeconds).clamp(0.0, 1.0);

    // Signature v2: rest is an INLINE, in-flow strip docked at the bottom —
    // NOT a full-screen takeover. The route is pushed with a transparent
    // barrier so the set ledger / targets / next-set stay fully visible above.
    // The strip carries the Barlow "REST" kicker, the Anton countdown, a
    // draining accent bar, −15 / Skip / +15 controls, and the next-set ledger.
    final restLabel =
        AppLocalizations.of(context).workoutSummaryAdvancedRest.toUpperCase();
    return Scaffold(
      backgroundColor: Colors.transparent,
      // The strip itself is the only hit target; the rest of the screen shows
      // through so the workout never disappears behind a scrim.
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161318) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accent.withValues(alpha: 0.55)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(restLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ZType.lbl(11,
                              color: isDark
                                  ? Colors.white70
                                  : Colors.black54,
                              letterSpacing: 2.5)),
                      const SizedBox(width: 12),
                      Text(_remaining.toString(),
                          style: ZType.disp(30,
                                  color: isDark ? Colors.white : Colors.black,
                                  letterSpacing: 0)
                              .copyWith(height: 1.0)),
                      // The trailing controls are intrinsically sized and the
                      // SKIP label is LOCALIZED, so their combined width is not
                      // knowable at build time. A bare Spacer collapsed to 0 and
                      // the row overflowed ("RIGHT OVERFLOWED BY 5.3 PIXELS" on
                      // an iPhone 17 Pro, worse in longer locales), clipping the
                      // last control. Expanded+FittedBox gives the cluster all
                      // the slack there is and scales it down only when there
                      // genuinely isn't enough — never overflows, any width,
                      // any language.
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                      if (widget.onPause != null) ...[
                        _RestCtl(
                            label: _paused ? '▶' : '⏸',
                            isDark: isDark,
                            onTap: () async {
                              await HapticService.instance.tap();
                              widget.onPause!();
                              setState(() => _paused = !_paused);
                            }),
                        const SizedBox(width: 8),
                      ],
                      if (widget.onSubtractTime != null)
                        _RestCtl(
                            label: '−15',
                            isDark: isDark,
                            onTap: () async {
                              await HapticService.instance.tap();
                              widget.onSubtractTime!();
                            }),
                      const SizedBox(width: 8),
                      _RestCtl(
                          label: AppLocalizations.of(context)
                              .easyRestOverlaySkipRest
                              .toUpperCase(),
                          isDark: isDark,
                          emphasized: true,
                          accent: accent,
                          onTap: () async {
                            await HapticService.instance.tap();
                            widget.onSkip();
                          }),
                      if (widget.onAddTime != null) ...[
                        const SizedBox(width: 8),
                        _RestCtl(
                            label: '+15',
                            isDark: isDark,
                            onTap: () async {
                              await HapticService.instance.tap();
                              widget.onAddTime!();
                            }),
                      ],
                      // 💧 Water — quick-log a cup mid-rest (mockup).
                      if (widget.onLogWater != null) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () async {
                            await HapticService.instance.tap();
                            widget.onLogWater!();
                          },
                          child: Container(
                            width: 38,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                  color: (isDark ? Colors.white : Colors.black)
                                      .withValues(alpha: 0.16)),
                            ),
                            child: Icon(Icons.water_drop_outlined,
                                size: 16, color: accent),
                          ),
                        ),
                      ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Draining accent bar — full width (the `.ir-strip` bar).
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: frac,
                      minHeight: 3,
                      backgroundColor: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.10),
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Next-set ledger — what's coming, stays visible during rest.
                  Row(
                    children: [
                      Icon(Icons.arrow_forward_rounded, size: 15, color: accent),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          widget.nextExercise.name.toUpperCase(),
                          style: ZType.lbl(11.5,
                              color: isDark ? Colors.white : Colors.black87,
                              letterSpacing: 1.0),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // The ledger tail is intrinsically sized and grows with
                      // the weight/reps digits, the unit label AND the user's
                      // font scale — at the app's own "Max" preset (1.5) it
                      // overflowed the strip by 23px on a 320dp device even
                      // though the control cluster above was already fixed.
                      // FittedBox inside a Flexible: it keeps its natural size
                      // whenever it fits and only shrinks when it genuinely
                      // cannot, so the numbers stay readable and the row can
                      // never throw a RenderFlex overflow.
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            'SET $_displaySetNumber/${widget.totalSets}'
                            ' · ${_fmtWeight(widget.nextTargetWeightKg)} $unit'
                            ' × ${widget.nextTargetReps}',
                            maxLines: 1,
                            style: TextStyle(
                              fontFamily: 'Space Mono',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: (isDark ? Colors.white : Colors.black)
                                  .withValues(alpha: 0.66),
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A compact rest-strip control pill (−15 / SKIP / +15). The Skip variant is
/// accent-emphasized; the ±15 variants are hairline ghosts.
class _RestCtl extends StatelessWidget {
  final String label;
  final bool isDark;
  final bool emphasized;
  final Color? accent;
  final VoidCallback onTap;
  const _RestCtl({
    required this.label,
    required this.isDark,
    required this.onTap,
    this.emphasized = false,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final fg = emphasized
        ? (accent ?? Colors.white)
        : (isDark ? Colors.white70 : Colors.black54);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: emphasized
                ? (accent ?? Colors.white).withValues(alpha: 0.6)
                : (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.22),
          ),
        ),
        child: Text(label,
            style: ZType.lbl(10.5, color: fg, letterSpacing: 1.5)),
      ),
    );
  }
}
