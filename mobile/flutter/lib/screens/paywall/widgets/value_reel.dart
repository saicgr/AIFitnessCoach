import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

/// Signature v2 palette — pinned to the near-black dark tokens. The reel is a
/// self-contained dark conversion surface (it must look identical in light or
/// dark app themes), so it references the dark `AppColors` literals directly
/// rather than the theme-resolved `ThemeColors`.
const Color _kSigAccent = AppColors.orange;
const Color _kSigInk = AppColors.pureBlack;
const Color _kSigSurface = AppColors.surface;
const Color _kSigBorder = AppColors.cardBorder;
const Color _kSigText = AppColors.textPrimary;
const Color _kSigMut = AppColors.textSecondary;

/// A short (~3-beat) auto-advancing animated value reel.
///
/// Shown as page 0 of the paywall intro PageView so the flow reads:
///   reel → timeline → pricing.
///
/// Each beat is a self-contained animated mock card (no real screens, no
/// imports from intro_screen) in the signature-v2 dark style. Beats
/// auto-advance every ~2.5s; the user can also tap the dots' [Skip] control to
/// jump straight to the pricing page via [onSkip], or let the reel finish and
/// the host PageView carry them onward.
///
/// Self-contained dark palette: the reel paints its own signature-v2 surface
/// so it looks identical in light or dark app themes (it sits on a paywall,
/// which is a dark conversion surface).
class PaywallValueReel extends StatefulWidget {
  /// Jump straight past the reel to the pricing page.
  final VoidCallback onSkip;

  const PaywallValueReel({super.key, required this.onSkip});

  @override
  State<PaywallValueReel> createState() => _PaywallValueReelState();
}

class _PaywallValueReelState extends State<PaywallValueReel> {
  static const _beatCount = 3;
  static const _beatDuration = Duration(milliseconds: 2500);

  int _beat = 0;
  Timer? _timer;

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
        setState(() => _beat++);
        _scheduleNext();
      } else {
        // Reel finished its last beat — hand off to the host flow.
        widget.onSkip();
      }
    });
  }

  void _onBeatTap() {
    // Tap anywhere advances; on the last beat it hands off.
    if (_beat < _beatCount - 1) {
      setState(() => _beat++);
      _scheduleNext();
    } else {
      _timer?.cancel();
      widget.onSkip();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
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
            // Skip control — always visible top-right so the user can bail to
            // the offer at any beat.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
              child: Row(
                children: [
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
                        right: i < _beatCount - 1 ? 6 : 0,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: Stack(
                          children: [
                            Container(
                              height: 3,
                              color: _kSigMut.withValues(alpha: 0.25),
                            ),
                            if (done)
                              Container(height: 3, color: _kSigAccent)
                            else if (active)
                              // Fill across the beat duration.
                              Container(height: 3, color: _kSigAccent)
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
                  child: _buildBeat(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBeat() {
    // keyed so each beat re-runs its entrance animation on swap.
    switch (_beat) {
      case 0:
        return _ReelBeat(
          key: const ValueKey('beat0'),
          kicker: 'IN SECONDS',
          headline: 'BUILDS YOUR PLAN',
          sub: 'A full week of training, matched to your goal and gear.',
          card: const _PlanMockCard(),
        );
      case 1:
        return _ReelBeat(
          key: const ValueKey('beat1'),
          kicker: 'ONE PHOTO',
          headline: 'SNAPS YOUR FOOD',
          sub: 'Point the camera — calories and macros land instantly.',
          card: const _FoodMockCard(),
        );
      default:
        return _ReelBeat(
          key: const ValueKey('beat2'),
          kicker: 'EATING OUT?',
          headline: 'READS ANY MENU',
          sub: 'Scan a menu and sort it by what fits your goal.',
          card: const _MenuMockCard(),
        );
    }
  }
}

/// Shared beat layout: kicker + Anton headline + sub + an animated mock card.
class _ReelBeat extends StatelessWidget {
  final String kicker;
  final String headline;
  final String sub;
  final Widget card;

  const _ReelBeat({
    super.key,
    required this.kicker,
    required this.headline,
    required this.sub,
    required this.card,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Text(
          kicker,
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
          headline,
          style: const TextStyle(
            fontFamily: 'Anton',
            fontSize: 38,
            height: 1.0,
            color: _kSigText,
          ),
        ).animate().fadeIn(delay: 70.ms, duration: 300.ms).slideY(begin: 0.08),
        const SizedBox(height: 10),
        Text(
          sub,
          style: const TextStyle(fontSize: 14, height: 1.5, color: _kSigMut),
        ).animate().fadeIn(delay: 150.ms, duration: 320.ms),
        Expanded(
          child: Center(
            child: card
                .animate()
                .fadeIn(delay: 200.ms, duration: 360.ms)
                .slideY(begin: 0.06, curve: Curves.easeOutCubic),
          ),
        ),
      ],
    );
  }
}

/// Shared signature-v2 mock card chrome.
class _MockShell extends StatelessWidget {
  final Widget child;
  const _MockShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.all(16),
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
      child: child,
    );
  }
}

/// Beat 1 — a weekly plan being assembled (rows fill in).
class _PlanMockCard extends StatelessWidget {
  const _PlanMockCard();

  static const _days = [
    ('MON', 'Push · 6 lifts'),
    ('TUE', 'Pull · 6 lifts'),
    ('WED', 'Rest'),
    ('THU', 'Legs · 5 lifts'),
  ];

  @override
  Widget build(BuildContext context) {
    return _MockShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YOUR WEEK',
            style: TextStyle(
              fontFamily: 'Barlow Condensed',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: _kSigMut,
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < _days.length; i++) ...[
            if (i > 0) const SizedBox(height: 9),
            _planRow(_days[i].$1, _days[i].$2)
                .animate()
                .fadeIn(delay: (300 + i * 220).ms, duration: 260.ms)
                .slideX(begin: 0.1),
          ],
        ],
      ),
    );
  }

  Widget _planRow(String day, String label) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _kSigAccent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            day,
            style: const TextStyle(
              fontFamily: 'Barlow Condensed',
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: _kSigAccent,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _kSigText,
          ),
        ),
      ],
    );
  }
}

/// Beat 2 — a food photo with macros popping in.
class _FoodMockCard extends StatelessWidget {
  const _FoodMockCard();

  static const _macros = [
    ('PROTEIN', '38g', Color(0xFF06B6D4)),
    ('CARBS', '52g', Color(0xFFFFD54A)),
    ('FAT', '14g', Color(0xFFA855F7)),
  ];

  @override
  Widget build(BuildContext context) {
    return _MockShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Faux photo tile.
          Container(
            height: 96,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3A2410), Color(0xFF1C140C)],
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.restaurant_rounded,
                size: 36,
                color: _kSigAccent,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
                children: [
                  const Text(
                    '512',
                    style: TextStyle(
                      fontFamily: 'Anton',
                      fontSize: 30,
                      color: _kSigText,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'kcal',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kSigMut,
                      ),
                    ),
                  ),
                ],
              )
              .animate()
              .fadeIn(delay: 360.ms, duration: 260.ms)
              .scaleXY(begin: 0.9, curve: Curves.easeOutBack),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < _macros.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _macroChip(_macros[i].$1, _macros[i].$2, _macros[i].$3)
                      .animate()
                      .fadeIn(delay: (460 + i * 130).ms, duration: 240.ms)
                      .slideY(begin: 0.2),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _macroChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Barlow Condensed',
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: _kSigMut,
            ),
          ),
        ],
      ),
    );
  }
}

/// Beat 3 — a scanned menu, sorted by goal-fit.
class _MenuMockCard extends StatelessWidget {
  const _MenuMockCard();

  static const _items = [
    ('Grilled salmon bowl', 'BEST FIT', true),
    ('Chicken fajitas', 'GOOD', false),
    ('Loaded nachos', 'HEAVY', false),
  ];

  @override
  Widget build(BuildContext context) {
    return _MockShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book_rounded, size: 15, color: _kSigAccent),
              const SizedBox(width: 6),
              const Text(
                'SORTED FOR YOUR GOAL',
                style: TextStyle(
                  fontFamily: 'Barlow Condensed',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: _kSigMut,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < _items.length; i++) ...[
            if (i > 0) const SizedBox(height: 9),
            _menuRow(_items[i].$1, _items[i].$2, _items[i].$3)
                .animate()
                .fadeIn(delay: (320 + i * 200).ms, duration: 260.ms)
                .slideX(begin: 0.12),
          ],
        ],
      ),
    );
  }

  Widget _menuRow(String name, String tag, bool best) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: best
            ? _kSigAccent.withValues(alpha: 0.10)
            : _kSigInk.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: best ? _kSigAccent.withValues(alpha: 0.35) : _kSigBorder,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _kSigText,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: best ? _kSigAccent : _kSigMut.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              tag,
              style: TextStyle(
                fontFamily: 'Barlow Condensed',
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                // Dark ink on the orange "best fit" fill (signature-v2 on-accent).
                color: best ? const Color(0xFF160B03) : _kSigMut,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
