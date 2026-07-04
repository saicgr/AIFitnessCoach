import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../auth/intro_demo/demo_scenes.dart';

/// Signature v2 single orange accent.
const Color _kSigAccent = Color(0xFFF97316);
const Color _kSigInk = Color(0xFF0A0A0B);
const Color _kSigSurface = Color(0xFF141416);
const Color _kSigBorder = Color(0xFF26262B);
const Color _kSigText = Color(0xFFFAFAFA);
const Color _kSigMut = Color(0xFF9D9DA6);

/// A short auto-advancing animated value reel.
///
/// Shown as page 0 of the paywall intro PageView so the flow reads:
///   reel → founder → reminder → offer.
///
/// Each beat frames one of the intro screen's LIVE demo scenes
/// (`intro_demo/demo_scenes.dart`) — the same clock-driven recreations of
/// real app surfaces the user glimpsed behind the intro scrim, now shown
/// full-frame at the decision moment. This is the "video paywall" pattern
/// (UI feature demo, silent, looping) with zero video assets: no bandwidth,
/// no quality risk, and recall continuity from first open.
///
/// Beats auto-advance every ~3.4s (one full 2.5s scene pass + dwell; the
/// scene loops if the user lingers). Tap advances; Skip or finishing the
/// last beat hands off to the offer page via [onSkip].
class PaywallValueReel extends StatefulWidget {
  /// Jump straight past the reel to the offer page.
  final VoidCallback onSkip;

  const PaywallValueReel({super.key, required this.onSkip});

  @override
  State<PaywallValueReel> createState() => _PaywallValueReelState();
}

/// One reel beat: copy + which live demo scene it frames.
class _BeatSpec {
  final String kicker;
  final String headline;
  final String sub;
  final Widget Function(int localMs) scene;
  const _BeatSpec({
    required this.kicker,
    required this.headline,
    required this.sub,
    required this.scene,
  });
}

class _PaywallValueReelState extends State<PaywallValueReel>
    with SingleTickerProviderStateMixin {
  static const _beatDuration = Duration(milliseconds: 3400);

  /// One full pass of a demo scene (mirrors DemoClock.sceneMs).
  static const int _sceneMs = 2500;

  static final List<_BeatSpec> _beats = [
    _BeatSpec(
      kicker: 'IN SECONDS',
      headline: 'BUILDS YOUR PLAN',
      sub: 'A full week of training, matched to your goal and gear.',
      scene: (ms) => ProgramBuilderScene(localMs: ms),
    ),
    _BeatSpec(
      kicker: 'EVERY SET COUNTED',
      headline: 'LOGS YOUR TRAINING',
      sub: 'Two-tap set logging — PRs celebrated, next loads auto-raised.',
      scene: (ms) => LiveLoggingScene(localMs: ms),
    ),
    _BeatSpec(
      kicker: 'ONE PHOTO',
      headline: 'SNAPS YOUR FOOD',
      sub: 'Point the camera — calories and macros land instantly.',
      scene: (ms) => FoodScanScene(localMs: ms),
    ),
    _BeatSpec(
      kicker: 'EATING OUT?',
      headline: 'READS ANY MENU',
      sub: 'Scan a menu and sort it by what fits your goal.',
      scene: (ms) => MenuAnalysisScene(localMs: ms),
    ),
  ];

  static int get _beatCount => _beats.length;

  int _beat = 0;
  Timer? _timer;

  /// Drives the framed demo scene. Restarted at each beat so every scene
  /// plays from its opening moment; repeats so it loops during the dwell.
  late final AnimationController _sceneCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: _sceneMs),
  )..repeat();

  @override
  void initState() {
    super.initState();
    _scheduleNext();
  }

  void _scheduleNext() {
    _timer?.cancel();
    _timer = Timer(_beatDuration, () {
      if (!mounted) return;
      if (_beat < _beatCount - 1) {
        _advanceTo(_beat + 1);
        _scheduleNext();
      } else {
        // Reel finished its last beat — hand off to the host flow.
        widget.onSkip();
      }
    });
  }

  void _advanceTo(int beat) {
    setState(() => _beat = beat);
    // Fresh scene pass from its opening frame.
    _sceneCtrl
      ..stop()
      ..forward(from: 0)
      ..repeat();
  }

  void _onBeatTap() {
    // Tap anywhere advances; on the last beat it hands off.
    if (_beat < _beatCount - 1) {
      _advanceTo(_beat + 1);
      _scheduleNext();
    } else {
      _timer?.cancel();
      widget.onSkip();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sceneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _kSigInk,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Beat counter + Skip — the counter tells the user where they
            // are; Skip is always visible so they can bail to the offer.
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 12, 0),
              child: Row(
                children: [
                  Text(
                    '${'${_beat + 1}'.padLeft(2, '0')} / ${'$_beatCount'.padLeft(2, '0')}',
                    style: const TextStyle(
                      fontFamily: 'Barlow Condensed',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: Color(0xFF6B6B74),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      _timer?.cancel();
                      widget.onSkip();
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: Text(
                        'SKIP',
                        style: TextStyle(
                          fontFamily: 'Barlow Condensed',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                          color: _kSigMut,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Progress segments — one per beat, the active one fills.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Row(
                children: List.generate(_beatCount, (i) {
                  final done = i < _beat;
                  final active = i == _beat;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: i < _beatCount - 1 ? 8 : 0,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: Stack(
                          children: [
                            Container(
                              height: 4,
                              color: _kSigMut.withValues(alpha: 0.25),
                            ),
                            if (done)
                              Container(height: 4, color: _kSigAccent)
                            else if (active)
                              // Fill across the beat duration.
                              Container(height: 4, color: _kSigAccent)
                                  .animate(key: ValueKey('seg$_beat'))
                                  .custom(
                                    duration: _beatDuration,
                                    builder: (context, value, child) =>
                                        FractionallySizedBox(
                                          alignment: Alignment.centerLeft,
                                          widthFactor: value,
                                          child: child,
                                        ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: _onBeatTap,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 26),
                  child: _ReelBeat(
                    key: ValueKey('beat$_beat'),
                    beatIndex: _beat,
                    spec: _beats[_beat],
                    sceneCtrl: _sceneCtrl,
                    sceneMs: _sceneMs,
                  ),
                ),
              ),
            ),
            // Teach the affordance that already exists.
            const Padding(
              padding: EdgeInsets.only(top: 10, bottom: 12),
              child: Text(
                'TAP TO CONTINUE',
                style: TextStyle(
                  fontFamily: 'Barlow Condensed',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: Color(0xFF6B6B74),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared beat layout: kicker + Anton headline + sub + the framed live scene
/// filling the rest of the frame. A giant ghost numeral behind the header is
/// the signature editorial texture.
class _ReelBeat extends StatelessWidget {
  final int beatIndex;
  final _BeatSpec spec;
  final AnimationController sceneCtrl;
  final int sceneMs;

  const _ReelBeat({
    super.key,
    required this.beatIndex,
    required this.spec,
    required this.sceneCtrl,
    required this.sceneMs,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        // Header block with the ghost beat numeral bleeding behind it.
        Stack(
          clipBehavior: Clip.none,
          children: [
            PositionedDirectional(
              end: -6,
              top: -18,
              child: Text(
                '${beatIndex + 1}'.padLeft(2, '0'),
                style: TextStyle(
                  fontFamily: 'Anton',
                  fontSize: 96,
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.045),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spec.kicker,
                  style: const TextStyle(
                    fontFamily: 'Barlow Condensed',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.5,
                    color: _kSigAccent,
                  ),
                ).animate().fadeIn(duration: 260.ms),
                const SizedBox(height: 6),
                Text(
                  spec.headline,
                  style: const TextStyle(
                    fontFamily: 'Anton',
                    fontSize: 38,
                    height: 1.0,
                    color: _kSigText,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 70.ms, duration: 300.ms)
                    .slideY(begin: 0.08),
                const SizedBox(height: 10),
                Text(
                  spec.sub,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: _kSigMut,
                  ),
                ).animate().fadeIn(delay: 150.ms, duration: 320.ms),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        // The live demo, filling the remaining height — no dead zone.
        Expanded(
          child: _SceneFrame(
            child: AnimatedBuilder(
              animation: sceneCtrl,
              builder: (context, _) => spec.scene(
                (sceneCtrl.value * sceneMs).floor().clamp(0, sceneMs - 1),
              ),
            ),
          )
              .animate()
              .fadeIn(delay: 200.ms, duration: 360.ms)
              .slideY(begin: 0.06, curve: Curves.easeOutCubic),
        ),
      ],
    );
  }
}

/// Signature-v2 frame around a live demo scene: hairline border, rounded
/// clip, soft accent glow. Strips the ambient MediaQuery top padding — the
/// scenes offset themselves below the notch when full-bleed on the intro,
/// which would waste a notch-height band inside this card.
class _SceneFrame extends StatelessWidget {
  final Widget child;
  const _SceneFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _kSigSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kSigBorder),
        boxShadow: [
          BoxShadow(
            color: _kSigAccent.withValues(alpha: 0.10),
            blurRadius: 40,
            spreadRadius: -8,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: MediaQuery.removePadding(
          context: context,
          removeTop: true,
          child: child,
        ),
      ),
    );
  }
}
