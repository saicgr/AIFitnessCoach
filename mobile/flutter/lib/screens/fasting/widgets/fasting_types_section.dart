import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/theme_colors.dart';
import '../../../data/models/fasting.dart';

import '../../../l10n/generated/app_localizations.dart';
/// "Types of Fasting" section for the Fasting Guide.
///
/// Unlike the TRE hour-ratio explainer ("Common protocols"), this covers the
/// distinct fasting *styles / methods*: how often you fast and what the
/// fasting day looks like. Each type is a collapsible, accent-tinted card with
/// an icon, an intensity cue, a plain-language "what it is", "who it suits",
/// and a caution where relevant.
///
/// Content reviewed against Medical News Today, Cleveland Clinic and the
/// Wikipedia intermittent-fasting overview (May 2026).
class FastingTypesSection extends StatelessWidget {
  const FastingTypesSection({super.key});

  /// Intensity cue — 1 (gentle) … 4 (expert), drives the dot meter.
  static const _types = <_FastingType>[
    _FastingType(
      icon: Icons.schedule_rounded,
      accent: Color(0xFF10B981),
      title: 'Time-Restricted Eating (TRE)',
      tagline: 'The everyday approach',
      intensity: 1,
      what:
          'Eat every day, but only inside a set daily window — the rest of '
          'the day you fast. Common windows are 14:10, 16:8, 18:6, 20:4 and '
          'OMAD (one meal a day). You never skip a full day of eating.',
      suits:
          'Best for almost everyone, especially beginners. Easy to keep up '
          'long-term because it becomes a simple daily routine.',
      caution:
          'Tighter windows (20:4, OMAD) make it harder to hit your protein '
          'and nutrient needs — widen the window if energy drops.',
      // Maps to the everyday TRE protocols.
      protocols: [FastingProtocol.sixteen8],
    ),
    _FastingType(
      icon: Icons.wb_sunny_rounded,
      accent: Color(0xFFF59E0B),
      title: 'Circadian / Early TRE',
      tagline: 'Eat with your body clock',
      intensity: 2,
      what:
          'A TRE window deliberately shifted earlier in the day — for '
          'example finishing your last meal by mid-afternoon. It lines '
          'eating up with your circadian rhythm, when your body handles '
          'food best.',
      suits:
          'Great if you want the strongest metabolic benefit from TRE and '
          'can eat earlier — research links early windows to better blood '
          'sugar and sleep.',
      caution:
          'An early cut-off clashes with social dinners and late training '
          '— pick a window you can realistically keep.',
    ),
    _FastingType(
      icon: Icons.calendar_view_week_rounded,
      accent: Color(0xFF8B5CF6),
      title: '5:2 — The Fast Diet',
      tagline: '5 normal days, 2 light days',
      intensity: 2,
      what:
          'Eat normally five days a week, then on two non-consecutive days '
          'eat just ~500–600 calories (about a quarter of your usual '
          'intake). The fasting days are low-calorie, not zero-calorie.',
      suits:
          'A good fit if a daily eating window feels restrictive — most '
          'days are unrestricted, with the effort focused on just two.',
      caution:
          'The very-low-calorie days can feel tough at first; keep them '
          'protein-forward and never put them back to back.',
      protocols: [FastingProtocol.fiveTwo],
    ),
    _FastingType(
      icon: Icons.swap_horiz_rounded,
      accent: Color(0xFF3B82F6),
      title: 'Alternate-Day Fasting (ADF)',
      tagline: 'Fast every other day',
      intensity: 3,
      what:
          'Alternate a "fast day" — eating nothing or under ~25% of your '
          'usual calories — with a normal "feast day". You repeat that '
          'pattern across the whole week.',
      suits:
          'Suits experienced fasters chasing faster fat loss who prefer '
          'fully free eating on the off days.',
      caution:
          'Demanding and hard to sustain socially. Watch energy, mood and '
          'electrolytes; not for beginners.',
      protocols: [FastingProtocol.adf],
    ),
    _FastingType(
      icon: Icons.restaurant_rounded,
      accent: Color(0xFFEC4899),
      title: 'Eat-Stop-Eat',
      tagline: 'A full 24h fast, 1–2× a week',
      intensity: 3,
      what:
          'Once or twice a week you do a complete 24-hour fast — for '
          'example dinner to dinner — then eat normally the rest of the '
          'time. Only water, black coffee and plain tea during the fast.',
      suits:
          'Works for people comfortable with longer fasts who want a clear '
          'weekly reset without changing every day.',
      caution:
          'A full day without food can hit energy and focus hard — plan it '
          'on a lighter day and break the fast gently.',
      protocols: [FastingProtocol.waterFast24],
    ),
    _FastingType(
      icon: Icons.water_drop_rounded,
      accent: Color(0xFFEF4444),
      title: 'Extended / Multi-Day Fasting',
      tagline: '24h+ water fasts',
      intensity: 4,
      what:
          'Water-only fasts that run beyond a single day — 48h, 72h or '
          'longer. They deepen fat-burning and autophagy far past what '
          'daily fasting reaches.',
      suits:
          'Only for experienced fasters with a specific goal, and only '
          'when properly prepared and monitored.',
      caution:
          'Fasts beyond 24h need careful electrolyte management, and '
          'anything past 72h should be done ONLY under medical '
          'supervision. Not for beginners.',
      protocols: [FastingProtocol.waterFast48, FastingProtocol.waterFast72],
      isCaution: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).fastingTypesTypesOfFasting,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Beyond the daily hour-ratios above, fasting comes in distinct '
          'styles — they differ in how often you fast and what a fasting '
          'day looks like. Tap any to learn more.',
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < _types.length; i++)
          _FastingTypeCard(index: i, type: _types[i]),
      ],
    );
  }
}

/// Immutable description of one fasting style.
class _FastingType {
  final IconData icon;
  final Color accent;
  final String title;
  final String tagline;

  /// 1 (gentle) … 4 (expert).
  final int intensity;
  final String what;
  final String suits;
  final String caution;

  /// Optional [FastingProtocol] enum values this style maps to — used to show
  /// difficulty / description chips sourced from the shared model.
  final List<FastingProtocol> protocols;
  final bool isCaution;

  const _FastingType({
    required this.icon,
    required this.accent,
    required this.title,
    required this.tagline,
    required this.intensity,
    required this.what,
    required this.suits,
    required this.caution,
    this.protocols = const [],
    this.isCaution = false,
  });
}

/// A single collapsible fasting-type card. Collapsed by default — mirrors the
/// elevated, accent-tinted style of [CollapsibleIntroCard].
class _FastingTypeCard extends StatefulWidget {
  final int index;
  final _FastingType type;

  const _FastingTypeCard({required this.index, required this.type});

  @override
  State<_FastingTypeCard> createState() => _FastingTypeCardState();
}

class _FastingTypeCardState extends State<_FastingTypeCard> {
  bool _expanded = false;

  void _toggle() => setState(() => _expanded = !_expanded);

  static const _intensityLabels = ['', 'Gentle', 'Moderate', 'Hard', 'Expert'];

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final dark = colors.isDark;
    final t = widget.type;
    final accent = t.accent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: dark ? 0.14 : 0.09),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Tinted header band (tap to toggle) ─────────────────────
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _toggle,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: AlignmentDirectional.topStart,
                      end: AlignmentDirectional.bottomEnd,
                      colors: [
                        accent.withValues(alpha: dark ? 0.30 : 0.18),
                        accent.withValues(alpha: dark ? 0.09 : 0.05),
                      ],
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: accent.withValues(
                            alpha: _expanded ? 0.20 : 0.0),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              accent.withValues(alpha: 0.32),
                              accent.withValues(alpha: 0.11),
                            ],
                          ),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.50),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(t.icon, size: 23, color: accent),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.title,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    t.tagline,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: accent,
                                    ),
                                  ),
                                ),
                                _IntensityMeter(
                                    level: t.intensity, accent: accent),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (t.isCaution)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 4),
                          child: Icon(Icons.priority_high_rounded,
                              size: 18, color: accent),
                        ),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 22,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // ── Body (animated expand/collapse) ────────────────────────
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity, height: 0),
              secondChild: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _row(colors, accent, Icons.info_outline_rounded,
                        'What it is', t.what),
                    const SizedBox(height: 12),
                    _row(colors, accent, Icons.favorite_outline_rounded,
                        'Who it suits', t.suits),
                    const SizedBox(height: 12),
                    _cautionRow(colors, accent, t.caution, t.isCaution),
                    if (t.protocols.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _protocolChips(colors, accent, t.protocols),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.speed_rounded,
                            size: 14, color: colors.textMuted),
                        const SizedBox(width: 6),
                        Text(
                          'Intensity: ${_intensityLabels[t.intensity]}',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 240),
              sizeCurve: Curves.easeOutCubic,
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 420.ms, delay: (widget.index * 80).ms)
        .slideY(begin: 0.10, end: 0, curve: Curves.easeOutCubic);
  }

  /// A labelled detail row (icon + bold label + body copy).
  Widget _row(ThemeColors colors, Color accent, IconData icon, String label,
      String body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: accent),
            const SizedBox(width: 6),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          body,
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// Caution row — uses a warning tone for medical-supervision types.
  Widget _cautionRow(
      ThemeColors colors, Color accent, String body, bool strong) {
    final tone = strong ? colors.warning : accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: colors.isDark ? 0.14 : 0.09),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: tone.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            strong
                ? Icons.warning_amber_rounded
                : Icons.lightbulb_outline_rounded,
            size: 15,
            color: tone,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              body,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Difficulty / description chips sourced from the shared [FastingProtocol]
  /// model so the section stays in sync with the rest of the app.
  Widget _protocolChips(
      ThemeColors colors, Color accent, List<FastingProtocol> protocols) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).fastingTypesInAppProtocols,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: accent,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in protocols)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: colors.isDark ? 0.16 : 0.10),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: accent.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      p.displayName,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 1,
                      height: 11,
                      color: accent.withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      p.difficulty,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// A 4-dot intensity meter — filled dots in [accent], empty dots muted.
class _IntensityMeter extends StatelessWidget {
  final int level;
  final Color accent;

  const _IntensityMeter({required this.level, required this.accent});

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 4; i++)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 3),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i <= level
                    ? accent
                    : colors.textMuted.withValues(alpha: 0.30),
              ),
            ),
          ),
      ],
    );
  }
}
