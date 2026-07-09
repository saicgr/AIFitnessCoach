import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'demo_clock.dart';

/// The auto-playing scenes of the intro demo — faithful, lightweight
/// recreations of real app surfaces (ported from the zealova.com hero):
///   1. ProgramBuilderScene    — coach chat assembling a program
///   2. LiveLoggingScene       — active-workout set logging + PR
///   3. FoodScanScene          — photo logging with macro extraction
///   4. MenuAnalysisScene      — DARK menu-analysis sheet with live re-sort
///   5. IntegrationsGridScene  — wearable/health data tiles lighting up
///   6. ShareablesScene        — a real share card rendered in-frame
///
/// Scenes 5 + 6 are flag-gated (default ON) — see [IntroScreen]'s effective
/// scene list. Each scene receives its LOCAL time in ms (0..2500) and renders
/// pure widgets from it — no per-scene controllers, the master clock drives all.

// ── shared bits ─────────────────────────────────────────────────────────

const _userBubbleColor = Color(0xFF06B6D4);
const _demoDarkBg = Color(0xFF0B0B0C);
const _demoDarkCard = Color(0xFF141416);
const _demoDarkBorder = Color(0xFF232326);
const _proteinColor = Color(0xFF9C27B0);
const _carbsColor = Color(0xFFFF9800);
const _badgeGreen = Color(0xFF4CAF50);
const _badgeYellow = Color(0xFFFFC107);
const _badgeRed = Color(0xFFF44336);

class _CoachAvatar extends StatelessWidget {
  static const double size = 34;
  const _CoachAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFB366), AppColors.orange],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        'A',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.42,
        ),
      ),
    );
  }
}

class _TypingDots extends StatelessWidget {
  final int localMs;
  final Color background;
  const _TypingDots({required this.localMs, required this.background});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: const BorderRadiusDirectional.only(
          topStart: Radius.circular(18),
          topEnd: Radius.circular(18),
          bottomStart: Radius.circular(6),
          bottomEnd: Radius.circular(18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final phase = ((localMs / 1100) + i * 0.15) % 1.0;
          final bounce = phase < 0.3 ? Curves.easeOut.transform(phase / 0.3) : 0.0;
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 4),
            child: Transform.translate(
              offset: Offset(0, -3 * bounce),
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF7A7A82)
                      .withValues(alpha: 0.4 + 0.6 * bounce),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Scene 1: program builder chat (light) ──────────────────────────────

class ProgramBuilderScene extends StatelessWidget {
  final int localMs;
  const ProgramBuilderScene({super.key, required this.localMs});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      color: Colors.white,
      padding: EdgeInsetsDirectional.only(
        top: MediaQuery.of(context).padding.top + 10,
        start: 22,
        end: 22,
      ),
      // Absorbs overflow when every beat (header + both bubbles + program
      // card + goal chip) is visible at once near the end of the loop —
      // this is a passive looping background scene, not user-navigable
      // content, so scrolling is disabled; it exists purely to prevent the
      // RenderFlex overflow banner on short devices.
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // chat header
          Container(
            padding: const EdgeInsets.only(bottom: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFECECEF))),
            ),
            child: Row(
              children: [
                const _CoachAvatar(),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.introDemoCoachName,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF18181B))),
                    Text(l10n.introDemoProgramBuilder,
                        style: const TextStyle(
                            fontSize: 10,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFA1A1AA))),
                  ],
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: const Color(0xFFFED7AA)),
                  ),
                  child: Text(l10n.introDemoLiveBadge,
                      style: const TextStyle(
                          fontSize: 10,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w800,
                          color: AppColors.orange)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // user ask
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              decoration: const BoxDecoration(
                color: _userBubbleColor,
                borderRadius: BorderRadiusDirectional.only(
                  topStart: Radius.circular(16),
                  topEnd: Radius.circular(16),
                  bottomStart: Radius.circular(16),
                  bottomEnd: Radius.circular(5),
                ),
              ),
              child: Text(l10n.introDemoUserAsk,
                  style: const TextStyle(fontSize: 14, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 9),
          if (!beat(localMs, 700))
            _TypingDots(localMs: localMs, background: const Color(0xFFF4F4F5)),
          // program card builds row by row
          BeatIn(
            localMs: localMs,
            at: 700,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsetsDirectional.only(end: 40),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFECECEF)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.introDemoPushDayMon,
                      style: const TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.orange)),
                  const SizedBox(height: 4),
                  _progRow('Bench Press', '4 × 8 · 185 lb', 900),
                  _progRow('Incline DB Press', '3 × 10', 1150),
                  _progRow('Cable Fly', '3 × 12', 1400),
                ],
              ),
            ),
          ),
          const SizedBox(height: 9),
          BeatIn(
            localMs: localMs,
            at: 1750,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: Text(l10n.introDemoGoalChip,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFC2410C))),
            ),
          ),
          const SizedBox(height: 9),
          BeatIn(
            localMs: localMs,
            at: 2050,
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                decoration: const BoxDecoration(
                  color: _userBubbleColor,
                  borderRadius: BorderRadiusDirectional.only(
                    topStart: Radius.circular(16),
                    topEnd: Radius.circular(16),
                    bottomStart: Radius.circular(16),
                    bottomEnd: Radius.circular(5),
                  ),
                ),
                child: Text(l10n.introDemoUserReply,
                    style:
                        const TextStyle(fontSize: 13, color: Colors.white)),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _progRow(String name, String detail, int at) {
    return BeatIn(
      localMs: localMs,
      at: at,
      child: Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F6F8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name,
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF18181B))),
            Text(detail,
                style: const TextStyle(
                    fontSize: 12.5, color: Color(0xFF71717A))),
          ],
        ),
      ),
    );
  }
}

// ── Scene 2: live workout logging (dark) ───────────────────────────────

class LiveLoggingScene extends StatelessWidget {
  final int localMs;
  const LiveLoggingScene({super.key, required this.localMs});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Rest timer ticks down as the scene plays.
    final secondsLeft = 92 - (localMs ~/ 1000);
    final timer =
        '${secondsLeft ~/ 60}:${(secondsLeft % 60).toString().padLeft(2, '0')}';

    return Container(
      color: _demoDarkBg,
      padding: EdgeInsetsDirectional.only(
        top: MediaQuery.of(context).padding.top + 10,
        start: 22,
        end: 22,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 11),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF1C1C1F))),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.introDemoExerciseKicker,
                        style: const TextStyle(
                            fontFamily: 'Barlow Condensed',
                            fontSize: 12,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w700,
                            color: AppColors.orange)),
                    const SizedBox(height: 3),
                    const Text('Bench Press',
                        style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFFAFAFA))),
                  ],
                ),
                const Spacer(),
                Text(timer,
                    style: const TextStyle(
                        fontFamily: 'Space Mono',
                        fontSize: 17,
                        color: AppColors.orange)),
              ],
            ),
          ),
          const SizedBox(height: 13),
          _setRow(l10n, 1, '185 lb × 8', done: true, at: 0),
          _setRow(l10n, 2, '215 lb × 5', done: true, at: 200),
          _setRow(l10n, 3, '225 lb × 3',
              done: false, active: true, at: 500, restingLabel: l10n.introDemoResting),
          const SizedBox(height: 8),
          BeatIn(
            localMs: localMs,
            at: 1100,
            child: _PrChip(localMs: localMs, label: l10n.introDemoPrChip),
          ),
          const SizedBox(height: 8),
          BeatIn(
            localMs: localMs,
            at: 1550,
            child: Text(
              l10n.introDemoCoachPrLine,
              style:
                  const TextStyle(fontSize: 12, color: Color(0xFF8A8A92)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _setRow(AppLocalizations l10n, int n, String detail,
      {required bool done,
      bool active = false,
      required int at,
      String? restingLabel}) {
    return BeatIn(
      localMs: localMs,
      at: at,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: active
              ? AppColors.orange.withValues(alpha: 0.08)
              : _demoDarkCard,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: active
                ? AppColors.orange.withValues(alpha: 0.55)
                : _demoDarkBorder,
          ),
        ),
        child: Row(
          children: [
            Text(done ? '✓' : '▸',
                style: TextStyle(
                    fontSize: 13,
                    color: done ? const Color(0xFF2ECC71) : AppColors.orange)),
            const SizedBox(width: 10),
            Text(l10n.introDemoSetRow(n),
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFAFAFA))),
            const SizedBox(width: 10),
            Text(detail,
                style: TextStyle(
                    fontSize: 13,
                    color: active
                        ? const Color(0xFFFAFAFA)
                        : const Color(0xFF8A8A92))),
            const Spacer(),
            if (active && restingLabel != null)
              Text(restingLabel,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF8A8A92))),
          ],
        ),
      ),
    );
  }
}

class _PrChip extends StatelessWidget {
  final int localMs;
  final String label;
  const _PrChip({required this.localMs, required this.label});

  @override
  Widget build(BuildContext context) {
    // Gentle 1.6s pulse like the mockup.
    final phase = (localMs % 1600) / 1600;
    final scale = 1.0 + 0.05 * (0.5 - (phase - 0.5).abs()) * 2;
    return Transform.scale(
      scale: scale,
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2A2106), Color(0xFF1C1505)],
          ),
          borderRadius: BorderRadius.circular(9),
          border:
              Border.all(color: const Color(0xFFFFD54A).withValues(alpha: 0.5)),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFFFFD54A))),
      ),
    );
  }
}

// ── Scene 3: food photo scan (light) ───────────────────────────────────

class FoodScanScene extends StatelessWidget {
  final int localMs;
  const FoodScanScene({super.key, required this.localMs});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Sweep oscillates down/up across the photo.
    final sweepPhase = (localMs % 2200) / 2200;
    final sweepT = sweepPhase < 0.5 ? sweepPhase * 2 : (1 - sweepPhase) * 2;

    return Container(
      color: Colors.white,
      padding: EdgeInsetsDirectional.only(
        top: MediaQuery.of(context).padding.top + 10,
        start: 22,
        end: 22,
      ),
      // This scene renders full-bleed on the intro screen (near full device
      // height) but is also reused framed inside the paywall's value reel,
      // where it only gets whatever's left after that beat's headline block
      // — sometimes shorter than this scene's natural content height.
      // SingleChildScrollView + NeverScrollableScrollPhysics absorbs that
      // overflow instead of throwing the RenderFlex banner (same pattern as
      // ProgramBuilderScene above) — it's a passive looping background
      // scene, not user-navigable content, so scrolling is disabled.
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.introDemoPhotoLogging,
                style: const TextStyle(
                    fontFamily: 'Barlow Condensed',
                    fontSize: 12,
                    letterSpacing: 2.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.orange)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 200,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset('assets/images/demo_food.webp',
                        fit: BoxFit.cover),
                    PositionedDirectional(
                      top: 8 + sweepT * 180,
                      start: 12,
                      end: 12,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient: LinearGradient(colors: [
                            AppColors.orange.withValues(alpha: 0),
                            AppColors.orange,
                            AppColors.orange.withValues(alpha: 0),
                          ]),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.orange.withValues(alpha: 0.8),
                              blurRadius: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                _macroChip(l10n.introDemoKcalChip, const Color(0xFF18181B),
                    Colors.white, 700),
                _macroChip(l10n.introDemoProteinChip, const Color(0xFFF3E8FF),
                    const Color(0xFF7C3AED), 850),
                _macroChip(l10n.introDemoCarbsChip, const Color(0xFFFFF7ED),
                    const Color(0xFFC2410C), 1000),
                _macroChip(l10n.introDemoFatChip, const Color(0xFFFDF2F8),
                    const Color(0xFFDB2777), 1150),
              ],
            ),
            const SizedBox(height: 12),
            BeatIn(
              localMs: localMs,
              at: 1500,
              child: Text(l10n.introDemoLoggedLine,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF16A34A))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _macroChip(String label, Color bg, Color fg, int at) {
    return BeatIn(
      localMs: localMs,
      at: at,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11.5, fontWeight: FontWeight.w700, color: fg)),
      ),
    );
  }
}

// ── Scene 4: menu analysis sheet (DARK, live re-sort) ──────────────────

class _Dish {
  final String name;
  final int p;
  final int c;
  final String badge; // 'rec' | 'ok' | 'avoid'
  final bool pick;
  const _Dish(this.name, this.p, this.c, this.badge, {this.pick = false});
}

const List<_Dish> _dishes = [
  _Dish('Grilled chicken bowl', 52, 38, 'rec', pick: true),
  _Dish('Bistecca alla griglia', 46, 2, 'rec'),
  _Dish('Carbonara', 28, 96, 'avoid'),
  _Dish('Margherita', 24, 80, 'ok'),
  _Dish('Caesar salad', 18, 22, 'ok'),
  _Dish('Caprese', 14, 8, 'ok'),
  _Dish('Risotto ai funghi', 12, 74, 'ok'),
  _Dish('Panna cotta', 6, 32, 'avoid'),
];

class MenuAnalysisScene extends StatelessWidget {
  final int localMs;
  const MenuAnalysisScene({super.key, required this.localMs});

  static const double _rowStep = 56;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // The money shot: sort flips Protein↓ → Carbs↓ mid-scene.
    final byCarbs = beat(localMs, 1400);
    final ordered = [..._dishes]
      ..sort((a, b) => byCarbs ? b.c.compareTo(a.c) : b.p.compareTo(a.p));
    final indexOf = {
      for (var i = 0; i < ordered.length; i++) ordered[i].name: i
    };

    return Container(
      color: _demoDarkBg,
      padding: EdgeInsetsDirectional.only(
        top: MediaQuery.of(context).padding.top + 10,
        start: 16,
        end: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.introDemoMenuTitle,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFFAFAFA))),
              const Text('🔖  ⏱  ✕',
                  style: TextStyle(fontSize: 12, color: Color(0xFF8A8A92))),
            ],
          ),
          const SizedBox(height: 4),
          Text(l10n.introDemoMenuMeta,
              style:
                  const TextStyle(fontSize: 11, color: Color(0xFF8A8A92))),
          const SizedBox(height: 9),
          Row(
            children: [
              Text(l10n.introDemoSortLabel,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF8A8A92))),
              const SizedBox(width: 7),
              _sortPill('${l10n.introDemoSortProtein}${byCarbs ? '' : ' ↓'}',
                  active: !byCarbs),
              const SizedBox(width: 7),
              _sortPill('${l10n.introDemoSortCarbs}${byCarbs ? ' ↓' : ''}',
                  active: byCarbs),
              const SizedBox(width: 7),
              _sortPill(l10n.introDemoSortInflammation, active: false),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (final d in _dishes)
                  AnimatedPositionedDirectional(
                    key: ValueKey(d.name),
                    duration: const Duration(milliseconds: 480),
                    curve: Curves.easeInOutCubic,
                    top: indexOf[d.name]! * _rowStep,
                    start: 0,
                    end: 0,
                    height: _rowStep - 7,
                    child: _dishRow(l10n, d),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sortPill(String label, {required bool active}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active
            ? AppColors.orange.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: active
              ? AppColors.orange.withValues(alpha: 0.55)
              : Colors.transparent,
        ),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color:
                  active ? AppColors.orange : const Color(0xFF8A8A92))),
    );
  }

  Widget _dishRow(AppLocalizations l10n, _Dish d) {
    final badgeColor = switch (d.badge) {
      'rec' => _badgeGreen,
      'avoid' => _badgeRed,
      _ => _badgeYellow,
    };
    final badgeLabel = switch (d.badge) {
      'rec' => l10n.introDemoBadgeRecommended,
      'avoid' => l10n.introDemoBadgeAvoid,
      _ => l10n.introDemoBadgeOk,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: d.pick
            ? const Color(0xFF221703)
            : _demoDarkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: d.pick
              ? const Color(0xFFFCD34D).withValues(alpha: 0.45)
              : _demoDarkBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: d.pick ? AppColors.orange : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: d.pick ? AppColors.orange : const Color(0xFF3A3A40),
              ),
            ),
            alignment: Alignment.center,
            child: d.pick
                ? const Text('✓',
                    style: TextStyle(fontSize: 10, color: Colors.white))
                : null,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(d.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFFAFAFA))),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(badgeLabel,
                          style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    _macroTag('${d.p}g P', _proteinColor),
                    const SizedBox(width: 6),
                    _macroTag('${d.c}g C', _carbsColor),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _macroTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 9.5, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

// ── Scene 5: integrations grid (dark) ──────────────────────────────────
//
// "Adapts to your data." A grid of the data sources we ACTUALLY read —
// Health Connect, Apple Health, and the wearable signals they carry
// (steps, heart rate, sleep, calories, workouts). Tiles light up one by
// one, then a footer line lands selling the payoff: every workout evolves
// with your effort, recovery & progress. No copyrighted logos — Material
// icons + simple branded tiles only, no fabricated integrations.

class _IntegrationTile {
  final IconData icon;
  final String label;
  final Color color;
  const _IntegrationTile(this.icon, this.label, this.color);
}

const List<_IntegrationTile> _integrationTiles = [
  _IntegrationTile(
      Icons.health_and_safety_rounded, 'Health Connect', Color(0xFF34A853)),
  _IntegrationTile(Icons.favorite_rounded, 'Apple Health', Color(0xFFFF375F)),
  _IntegrationTile(
      Icons.directions_walk_rounded, 'Steps', Color(0xFF06B6D4)),
  _IntegrationTile(
      Icons.monitor_heart_rounded, 'Heart rate', Color(0xFFEF4444)),
  _IntegrationTile(Icons.bedtime_rounded, 'Sleep', Color(0xFF8B5CF6)),
  _IntegrationTile(
      Icons.local_fire_department_rounded, 'Calories', AppColors.orange),
];

class IntegrationsGridScene extends StatelessWidget {
  final int localMs;
  const IntegrationsGridScene({super.key, required this.localMs});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _demoDarkBg,
      padding: EdgeInsetsDirectional.only(
        top: MediaQuery.of(context).padding.top + 14,
        start: 22,
        end: 22,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CONNECTED DATA',
              style: TextStyle(
                  fontFamily: 'Barlow Condensed',
                  fontSize: 12,
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.orange)),
          const SizedBox(height: 8),
          const Text('Adapts to your data.',
              style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFFAFAFA))),
          const SizedBox(height: 16),
          // 2-column tile grid; each tile pops in on its own beat.
          for (var row = 0; row < _integrationTiles.length; row += 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: _tile(_integrationTiles[row], 250 + row * 130),
                  ),
                  const SizedBox(width: 10),
                  if (row + 1 < _integrationTiles.length)
                    Expanded(
                      child:
                          _tile(_integrationTiles[row + 1], 320 + row * 130),
                    )
                  else
                    const Expanded(child: SizedBox()),
                ],
              ),
            ),
          const SizedBox(height: 6),
          BeatIn(
            localMs: localMs,
            at: 1700,
            child: Row(
              children: [
                Icon(Icons.auto_awesome_rounded,
                    size: 15, color: AppColors.orange.withValues(alpha: 0.9)),
                const SizedBox(width: 7),
                const Expanded(
                  child: Text(
                    'Every workout evolves with your effort, recovery & progress.',
                    style:
                        TextStyle(fontSize: 12.5, color: Color(0xFF9A9AA2)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(_IntegrationTile t, int at) {
    // A subtle "live" pulse on the connected dot once the tile is in.
    final inT = beatT(localMs, at, at + 300);
    final pulsePhase = (localMs % 1500) / 1500;
    final dotAlpha = 0.5 + 0.5 * (0.5 - (pulsePhase - 0.5).abs()) * 2;
    return BeatIn(
      localMs: localMs,
      at: at,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: _demoDarkCard,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: Color.lerp(_demoDarkBorder, t.color, 0.35 * inT) ??
                _demoDarkBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: t.color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: Icon(t.icon, size: 18, color: t.color),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(t.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFAFAFA))),
            ),
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2ECC71)
                    .withValues(alpha: dotAlpha * inT),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Scene 6: shareables showcase (dark) ────────────────────────────────
//
// "Flex your progress." Cycles through a few REAL share cards via the
// production shareables renderer (Achievement Hero → Workout Score → Streak
// Fire) fed static sample data, scaled to fit the demo frame. Each template
// lays out in its native 1080×1920 (story) design space, so we wrap it in a
// SizedBox at that size and FittedBox it down — exactly what the share
// preview pane does. The scene divides its [DemoClock.sceneMs] window into N
// slots and cross-fades between consecutive templates so the intro showcases
// the BREADTH of shareables instead of one static trophy card.
//
// Only photo-FREE templates are used here — each degrades to its own
// signature gradient with no real user asset, so nothing renders broken in
// the unauthenticated intro carousel.

class ShareablesScene extends StatelessWidget {
  final int localMs;
  const ShareablesScene({super.key, required this.localMs});

  /// The founder's REAL before/after progress photos — the same shot the
  /// marketing site uses — cropped to a clean left/right grid. One card, no
  /// rotation, no gradient fallback.
  static const String _beforeAfterAsset =
      'assets/images/demo_progress_before_after.webp';
  static const double _cardAspect = 1017 / 972;

  @override
  Widget build(BuildContext context) {
    // Single card: deals in with a rise + scale, then floats gently so it
    // never sits dead-static.
    final enter = beatT(localMs, 0, 540, Curves.easeOutBack);
    final fadeIn = beatT(localMs, 0, 280, Curves.easeOut);
    final floatT = math.sin(
        (localMs.clamp(0, DemoClock.sceneMs) / DemoClock.sceneMs) * math.pi);
    final dy = 30 * (1 - enter) - 4 * floatT;
    final scale = 0.90 + 0.10 * enter;

    return Container(
      color: _demoDarkBg,
      padding: EdgeInsetsDirectional.only(
        top: MediaQuery.of(context).padding.top + 14,
        start: 22,
        end: 22,
        bottom: 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SHARE YOUR WINS',
              style: TextStyle(
                  fontFamily: 'Barlow Condensed',
                  fontSize: 12,
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.orange)),
          const SizedBox(height: 8),
          const Text('Flex your progress.',
              style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFFAFAFA))),
          const SizedBox(height: 14),
          Expanded(
            child: Center(
              child: LayoutBuilder(
                builder: (context, c) {
                  // Fit the ~square card inside the available frame.
                  var w = c.maxWidth;
                  var h = w / _cardAspect;
                  if (h > c.maxHeight) {
                    h = c.maxHeight;
                    w = h * _cardAspect;
                  }
                  return Opacity(
                    opacity: fadeIn.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, dy),
                      child: Transform.scale(
                        scale: scale,
                        child: RepaintBoundary(
                          child: SizedBox(
                            width: w,
                            height: h,
                            child: _beforeAfterCard(),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _beforeAfterCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(_beforeAfterAsset, fit: BoxFit.cover),
          // Top + bottom scrims so the tags / delta pill / watermark stay legible.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x99000000),
                  Color(0x00000000),
                  Color(0x00000000),
                  Color(0xB3000000),
                ],
                stops: [0.0, 0.22, 0.74, 1.0],
              ),
            ),
          ),
          // BEFORE / AFTER tags, one per half.
          const Positioned(top: 12, left: 12, child: _BaTag('BEFORE')),
          const Positioned(top: 12, right: 12, child: _BaTag('AFTER')),
          // Centre delta pill straddling the seam.
          Center(child: _deltaPill()),
          // Brand watermark.
          const Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            child: Center(child: _BaWatermark()),
          ),
        ],
      ),
    );
  }

  Widget _deltaPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.orange,
        borderRadius: BorderRadius.circular(40),
        boxShadow: const [
          BoxShadow(
              color: Color(0x66000000), blurRadius: 16, offset: Offset(0, 5)),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.trending_down_rounded, color: Colors.black, size: 18),
          SizedBox(width: 7),
          Text('−18 lb',
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2)),
          SizedBox(width: 6),
          Text('· 12 weeks',
              style: TextStyle(
                  color: Color(0xCC000000),
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _BaTag extends StatelessWidget {
  final String label;
  const _BaTag(this.label);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x8C000000),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2)),
    );
  }
}

class _BaWatermark extends StatelessWidget {
  const _BaWatermark();
  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.bolt, color: AppColors.orange, size: 15),
        SizedBox(width: 3),
        Text('Zealova',
            style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3)),
      ],
    );
  }
}
