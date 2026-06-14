import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/design_system/zealova.dart';
import '../../widgets/glass_back_button.dart';
import 'widgets/collapsible_intro_card.dart';
import 'widgets/fasting_timeline_pager.dart';
import 'widgets/fasting_types_section.dart';

/// Plain-language Fasting Guide.
///
/// Sections: what fasting is / how it works / is it safe, a protocol
/// explainer, beginner tips, an FAQ, and safety guidance. The centerpiece is
/// an animated educational timeline scrolling 0h → 30-day fast — generic
/// (relative hours, NO user clock times; that's the Body Status screen).
///
/// Route: `/fasting/guide`.
class FastingGuideScreen extends StatelessWidget {
  const FastingGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Compact inline header: ← Fasting Guide ─────────────────
            _CompactHeader(colors: colors),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
                children: [
                  Text(
                    l10n.fastingGuideSubtitle,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── (1) Collapsible intro education cards ────────────
                const CollapsibleIntroCard(
                  index: 0,
                  icon: Icons.lightbulb_outline_rounded,
                  accent: Color(0xFF8B5CF6),
                  eyebrow: 'The basics',
                  title: 'What is fasting?',
                  body:
                      'Intermittent fasting is simply cycling between periods '
                      'of eating and not eating. You are not changing what '
                      'you eat — only when. A common pattern, 16:8, means a '
                      '16-hour fasting window and an 8-hour eating window.',
                  stat: '16:8',
                  statLabel: 'most popular window',
                ),
                const CollapsibleIntroCard(
                  index: 1,
                  icon: Icons.bolt_rounded,
                  accent: Color(0xFFF59E0B),
                  eyebrow: 'The science',
                  title: 'How it works',
                  body:
                      'After a meal your body burns the carbohydrates you '
                      'just ate. Once those run out — usually 8–12 hours in — '
                      'it switches to burning stored fat and producing '
                      'ketones. Longer fasts deepen this fat-burning and '
                      'trigger autophagy, your cells’ self-cleaning '
                      'process. The timeline below shows the full journey.',
                  stat: '8–12h',
                  statLabel: 'until fat-burning kicks in',
                ),
                const CollapsibleIntroCard(
                  index: 2,
                  icon: Icons.health_and_safety_outlined,
                  accent: Color(0xFFEF4444),
                  eyebrow: 'Before you start',
                  title: 'Is it safe for me?',
                  body:
                      'For most healthy adults, fasts up to 16–24 hours are '
                      'considered safe. Fasting is NOT recommended if you are '
                      'pregnant or breastfeeding, under 18, underweight, have '
                      'a history of disordered eating, or manage diabetes or '
                      'another chronic condition without medical guidance. '
                      'When in doubt, talk to your clinician first.',
                  stat: '16–24h',
                  statLabel: 'safe range for healthy adults',
                  isCaution: true,
                ),

                  // ── (2) Swipeable educational timeline pager ─────────
                  const SizedBox(height: 16),
                  _timelineHeader(context, colors),
                  const SizedBox(height: 12),
                  const FastingTimelinePager(),

                  // ── (3) Common protocols (TRE hour-ratios) ───────────
                  const SizedBox(height: 24),
                  _ProtocolExplainer(colors: colors),

                  // ── (4) Types of fasting (distinct styles) ───────────
                  const SizedBox(height: 24),
                  const FastingTypesSection(),

                  // ── (5) Beginner tips ────────────────────────────────
                  const SizedBox(height: 24),
                  _BeginnerTips(colors: colors),

                  // ── (6) FAQ ──────────────────────────────────────────
                  const SizedBox(height: 24),
                  _Faq(colors: colors),

                  const SizedBox(height: 24),
                  _SafetyCard(colors: colors),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timelineHeader(BuildContext context, ThemeColors colors) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.fastingGuideTheFastingTimeline.toUpperCase(),
          style: ZType.disp(22, color: colors.textPrimary),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.fastingGuideSwipeTimeline,
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }

}

/// Compact inline header — `← Fasting Guide` — matching the pattern used by
/// other detail screens (back button + title on a single row).
class _CompactHeader extends StatelessWidget {
  final ThemeColors colors;
  const _CompactHeader({required this.colors});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 16, 8),
      child: Row(
        children: [
          const GlassBackButton(),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.fastingGuideFastingGuide.toUpperCase(),
              style: ZType.disp(22, color: colors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Protocol explainer — the common fasting windows.
class _ProtocolExplainer extends StatelessWidget {
  final ThemeColors colors;
  const _ProtocolExplainer({required this.colors});

  // TODO(i18n): static const field initializer — cannot access BuildContext.
  static const _protocols = [
    ('14:10', 'For beginners', 'A 14-hour fast — an easy on-ramp.'),
    ('16:8', 'Most popular', 'A 16-hour fast; balances results and ease.'),
    ('18:6', 'Stay lean', 'A 18-hour fast for steady fat loss.'),
    ('20:4', 'The warrior', 'A 20-hour fast with a tight 4-hour window.'),
    ('OMAD', 'One meal a day', 'A 23-hour fast — advanced.'),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ZealovaCard(
      variant: ZealovaCardVariant.outlined,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.fastingGuideCommonProtocols.toUpperCase(),
            style: ZType.disp(18, color: colors.textPrimary),
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < _protocols.length; i++) ...[
            if (i > 0)
              const ZealovaRule(margin: EdgeInsets.symmetric(vertical: 10)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Text(
                    _protocols[i].$1,
                    textAlign: TextAlign.center,
                    style: ZType.data(12, color: colors.textPrimary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _protocols[i].$2.toUpperCase(),
                        style: ZType.lbl(13, color: colors.textPrimary,
                            letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        _protocols[i].$3,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.06, end: 0);
  }
}

/// Beginner tips list.
class _BeginnerTips extends StatelessWidget {
  final ThemeColors colors;
  const _BeginnerTips({required this.colors});

  // TODO(i18n): static const field initializer — cannot access BuildContext.
  // Migrate to build-time list or separate ARB keys when refactoring.
  static const _tips = [
    ('Start gentle', 'Begin with 12:12 or 14:10 and extend as it feels easy.'),
    ('Drink water', 'Water, black coffee and plain tea keep you hydrated and '
        'do not break your fast.'),
    ('Mind electrolytes',
        'On longer fasts add a pinch of salt to help with energy and '
        'headaches.'),
    ('Break it well', 'End with something light and protein-rich rather than '
        'a heavy, sugary meal.'),
    ('Be consistent', 'Keeping similar windows day to day makes fasting feel '
        'effortless faster.'),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ZealovaCard(
      variant: ZealovaCardVariant.outlined,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.fastingGuideBeginnerTips.toUpperCase(),
            style: ZType.disp(18, color: colors.textPrimary),
          ),
          const SizedBox(height: 14),
          for (final t in _tips)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_rounded,
                      size: 17, color: colors.success),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${t.$1}. ',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                          TextSpan(
                            text: t.$2,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.06, end: 0);
  }
}

/// FAQ accordion.
class _Faq extends StatelessWidget {
  final ThemeColors colors;
  const _Faq({required this.colors});

  // TODO(i18n): static const field initializer — cannot access BuildContext.
  static const _faqs = [
    ('Does black coffee break my fast?',
        'No. Black coffee, plain tea and water have effectively no calories '
        'and will not break a fast. Skip the milk, sugar and sweeteners.'),
    ('Will I lose muscle?',
        'Short fasts (under ~24h) preserve muscle well — growth hormone rises '
        'to protect lean tissue. Strength training and adequate protein in '
        'your eating window matter most.'),
    ('What if I get hungry?',
        'Hunger comes in waves and usually passes within 20 minutes. Water, '
        'a walk, or a hot drink helps. If you feel unwell, end the fast.'),
    ('Can I exercise while fasting?',
        'Yes — light to moderate exercise is fine for most people. For '
        'intense sessions you may prefer to train near your eating window.'),
    ('How long until I see results?',
        'Many people notice changes in energy and appetite within 1–2 weeks; '
        'visible body changes typically take several weeks of consistency.'),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Text(
              l10n.fastingGuideFaq.toUpperCase(),
              style: ZType.disp(22, color: colors.textPrimary),
            ),
          ),
          for (final f in _faqs)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  shape: const Border(),
                  collapsedShape: const Border(),
                  tilePadding:
                      const EdgeInsets.symmetric(horizontal: 14),
                  childrenPadding:
                      const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  iconColor: colors.accent,
                  collapsedIconColor: colors.textMuted,
                  title: Text(
                    f.$1.toUpperCase(),
                    style: ZType.lbl(13.5, color: colors.textPrimary,
                        letterSpacing: 0.5),
                  ),
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        f.$2,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Safety guidance card.
class _SafetyCard extends StatelessWidget {
  final ThemeColors colors;
  const _SafetyCard({required this.colors});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(color: colors.warning, width: 3),
          top: BorderSide(color: AppColors.cardBorder),
          right: BorderSide(color: AppColors.cardBorder),
          bottom: BorderSide(color: AppColors.cardBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, size: 20, color: colors.warning),
              const SizedBox(width: 8),
              Text(
                l10n.fastingGuideStaySafe.toUpperCase(),
                style: ZType.disp(18, color: colors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l10n.fastingGuideSafetyBody,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
