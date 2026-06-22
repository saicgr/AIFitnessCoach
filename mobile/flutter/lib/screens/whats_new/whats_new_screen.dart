/// What's New — feature-spotlight carousel.
///
/// A full-screen PageView that announces this release's redesigns, one card
/// per surface. Mirrors the "announce the redesign" frame competitors use, but
/// rendered entirely with OUR design system: [GlassCard] panels, accent tokens
/// from [ThemeColors] / [AccentColorScope], [GlowButton] CTA, [HapticService]
/// feedback, and subtle flutter_animate entrances.
///
/// Each slide can carry an optional [_Spotlight.imageAsset] — a real in-app
/// screenshot rendered as the hero. When the asset is null (or fails to load),
/// the slide FALLS BACK to a composed icon + stat-flourish visual so the screen
/// is always safe to ship even before the PNGs land in `assets/whats_new/`.
///
/// Consolidation: this is the SINGLE What's-New surface per release. Showing it
/// also marks the standalone score-change announcement sheet seen (via its
/// shared SharedPreferences flag) so a returning user never sees both — the
/// "Sleep now counts toward your score" change is folded in as one slide here.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/constants/stat_typography.dart';
import '../../core/services/haptic_service.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../core/theme/theme_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glow_button.dart';

/// SharedPreferences flag owned by `score_change_announcement_sheet.dart`
/// (`_kSeenKey` there). We set it true when this carousel is shown so the
/// standalone score-change bottom sheet — which is folded in here as a slide —
/// won't ALSO fire for the same user. Keep this string in sync with that file.
const String _kScoreChangeSeenKey = 'score_change_v2_seen';

/// Immutable description of a single spotlight slide.
class _Spotlight {
  /// Large bold headline.
  final String headline;

  /// One-line supporting caption.
  final String caption;

  /// Primary iconographic visual for the slide — used in the composed hero
  /// when [imageAsset] is null or its asset fails to load.
  final IconData icon;

  /// A short stat-style flourish rendered in [StatNumber] type (e.g. "+6",
  /// "92"). Purely decorative — sells the "numbers come alive" tone without
  /// inventing real data. Only shown in the composed (icon) hero.
  final String statValue;

  /// Tiny label beneath [statValue].
  final String statLabel;

  /// Secondary supporting icons arranged around the hero glyph (composed hero
  /// only).
  final List<IconData> supportingIcons;

  /// Optional path to a real in-app screenshot (e.g.
  /// 'assets/whats_new/workout_details.png'). When set AND the asset loads,
  /// it becomes the hero (BoxFit.cover, rounded, subtle border). When null OR
  /// the asset is missing, the slide falls back to the composed icon hero, so
  /// it is always safe to ship the path before the PNG exists.
  final String? imageAsset;

  const _Spotlight({
    required this.headline,
    required this.caption,
    required this.icon,
    required this.statValue,
    required this.statLabel,
    required this.supportingIcons,
    this.imageAsset,
  });
}

/// NOTE on assets: `imageAsset` paths point at `assets/whats_new/*.png`. Those
/// PNGs do NOT exist yet and `assets/whats_new/` is NOT yet declared in
/// pubspec.yaml — the errorBuilder fallback keeps every slide rendering safely
/// until real screenshots are captured and the asset dir is wired (follow-up).
const List<_Spotlight> _spotlights = [
  _Spotlight(
    headline: 'Workout details got richer',
    caption:
        'Completed sessions now surface more of the stats and summaries that matter.',
    icon: Icons.fitness_center_rounded,
    statValue: '12',
    statLabel: 'stats per session',
    supportingIcons: [
      Icons.timer_outlined,
      Icons.local_fire_department_rounded,
      Icons.bar_chart_rounded,
    ],
    imageAsset: 'assets/whats_new/workout_details.png',
  ),
  _Spotlight(
    headline: 'Strength score, inline',
    caption: 'See your best lift and a strength score right on each exercise.',
    icon: Icons.bolt_rounded,
    statValue: '92',
    statLabel: 'strength score',
    supportingIcons: [
      Icons.trending_up_rounded,
      Icons.emoji_events_outlined,
      Icons.straighten_rounded,
    ],
    imageAsset: 'assets/whats_new/strength_score.png',
  ),
  // Folded-in score-change announcement — replaces the standalone bottom sheet
  // so a returning user sees this change here and nowhere else.
  _Spotlight(
    headline: 'Sleep now counts toward your score',
    caption:
        'Sleep joins Train, Nourish, and Move as a fourth pillar, so a poor '
        'night shows up and a solid one helps your day score climb.',
    icon: Icons.bedtime_rounded,
    statValue: '4',
    statLabel: 'score pillars',
    supportingIcons: [
      Icons.fitness_center_rounded,
      Icons.restaurant_rounded,
      Icons.directions_walk_rounded,
    ],
    imageAsset: 'assets/whats_new/sleep_score.png',
  ),
  _Spotlight(
    headline: 'Streaks have a new home',
    caption:
        'Track weekly momentum, freezes, and the leaderboard from one screen.',
    icon: Icons.local_fire_department_rounded,
    statValue: '18',
    statLabel: 'week streak',
    supportingIcons: [
      Icons.ac_unit_rounded,
      Icons.leaderboard_rounded,
      Icons.calendar_view_week_rounded,
    ],
    imageAsset: 'assets/whats_new/streaks.png',
  ),
  _Spotlight(
    headline: 'Freezes protect your streak',
    caption:
        'Banked freezes automatically cover a missed week and keep your momentum alive.',
    icon: Icons.ac_unit_rounded,
    statValue: '3',
    statLabel: 'freezes banked',
    supportingIcons: [
      Icons.shield_outlined,
      Icons.auto_awesome_rounded,
      Icons.local_fire_department_rounded,
    ],
    imageAsset: 'assets/whats_new/freezes.png',
  ),
  _Spotlight(
    headline: 'Progress is easier to scan',
    caption: 'Scores, streaks, trends, and a volume heatmap, all in one place.',
    icon: Icons.insights_rounded,
    statValue: '+24',
    statLabel: 'this month',
    supportingIcons: [
      Icons.grid_on_rounded,
      Icons.show_chart_rounded,
      Icons.stacked_line_chart_rounded,
    ],
    imageAsset: 'assets/whats_new/progress.png',
  ),
];

class WhatsNewScreen extends StatefulWidget {
  const WhatsNewScreen({super.key});

  @override
  State<WhatsNewScreen> createState() => _WhatsNewScreenState();
}

class _WhatsNewScreenState extends State<WhatsNewScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  bool get _isLast => _page >= _spotlights.length - 1;

  @override
  void initState() {
    super.initState();
    // Consolidate the two What's-New surfaces: now that the score-change
    // content is a slide here, mark the standalone score-change sheet seen so
    // it never also fires for this user. Fire-and-forget; non-fatal on error.
    _markScoreChangeSeen();
  }

  Future<void> _markScoreChangeSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kScoreChangeSeenKey, true);
    } catch (_) {
      // Non-fatal — the worst case is the user briefly seeing the score sheet
      // on a later home visit; never block the carousel on a prefs write.
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onAdvance() {
    HapticService.instance.tap();
    if (_isLast) {
      _dismiss();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  void _dismiss() {
    if (!mounted) return;
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      // Reached directly (e.g. deep link / post-onboarding) — nowhere to pop to.
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar: progress hint + Skip ──────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.sm,
                0,
              ),
              child: Row(
                children: [
                  Text(
                    "What's new",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                      color: colors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      HapticService.instance.tick();
                      _dismiss();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: colors.textMuted,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Carousel ───────────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _spotlights.length,
                onPageChanged: (i) {
                  HapticService.instance.tick();
                  if (mounted) setState(() => _page = i);
                },
                itemBuilder: (context, index) => _SpotlightCard(
                  // Re-key per page so the entrance animation replays on each
                  // slide as it becomes active.
                  key: ValueKey('whats-new-$index-$_page'),
                  spotlight: _spotlights[index],
                  accent: accent,
                  colors: colors,
                  isActive: index == _page,
                ),
              ),
            ),

            // ── Page dots ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_spotlights.length, (i) {
                  final selected = i == _page;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: selected ? 22 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: selected
                          ? accent
                          : colors.textMuted.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  );
                }),
              ),
            ),

            // ── CTA ────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: GlowButton(
                width: double.infinity,
                color: accent,
                onTap: _onAdvance,
                child: Text(
                  _isLast ? 'Done' : 'Continue',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single spotlight slide: a glass hero visual on top, headline + caption
/// below. The hero is either a real screenshot (when [_Spotlight.imageAsset]
/// loads) or a composed icon + stat flourish (fallback).
class _SpotlightCard extends StatelessWidget {
  final _Spotlight spotlight;
  final Color accent;
  final ThemeColors colors;
  final bool isActive;

  const _SpotlightCard({
    super.key,
    required this.spotlight,
    required this.accent,
    required this.colors,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final content = SingleChildScrollView(
      // Scroll guard so the slide never overflows on an iPhone SE / large
      // text scale; on roomy phones the column simply centers.
      physics: const NeverScrollableScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _HeroVisual(spotlight: spotlight, accent: accent, colors: colors),
              const SizedBox(height: AppSpacing.xl),
              Text(
                spotlight.headline,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm + 4),
              Text(
                spotlight.caption,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!isActive) return content;

    // Subtle premium entrance for the active slide only.
    return content
        .animate()
        .fadeIn(duration: 360.ms, curve: Curves.easeOut)
        .slideY(
          begin: 0.04,
          end: 0,
          duration: 420.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

/// The glass hero block. Renders a real screenshot when
/// [_Spotlight.imageAsset] is set and loads; otherwise composes a large accent
/// glyph with a stat flourish and a row of supporting icons.
class _HeroVisual extends StatelessWidget {
  final _Spotlight spotlight;
  final Color accent;
  final ThemeColors colors;

  const _HeroVisual({
    required this.spotlight,
    required this.accent,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final asset = spotlight.imageAsset;
    return GlassCard(
      glowColor: accent,
      isActive: true,
      glowIntensity: 0.22,
      borderRadius: AppRadius.xl,
      padding: EdgeInsets.all(asset != null ? AppSpacing.sm : AppSpacing.lg),
      child: asset != null
          ? _ScreenshotHero(
              asset: asset,
              accent: accent,
              colors: colors,
              fallback: _ComposedHero(
                spotlight: spotlight,
                accent: accent,
                colors: colors,
              ),
            )
          : _ComposedHero(spotlight: spotlight, accent: accent, colors: colors),
    );
  }
}

/// Real-screenshot hero: the PNG rendered BoxFit.cover with a rounded clip and
/// a subtle accent border. Falls back to [fallback] (the composed icon hero) if
/// the asset is missing or fails to decode — so a not-yet-captured screenshot
/// path never breaks the slide.
class _ScreenshotHero extends StatelessWidget {
  final String asset;
  final Color accent;
  final ThemeColors colors;
  final Widget fallback;

  const _ScreenshotHero({
    required this.asset,
    required this.accent,
    required this.colors,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: accent.withValues(alpha: 0.30), width: 1),
        ),
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: Image.asset(
            asset,
            fit: BoxFit.cover,
            // Safe fallback while the PNGs don't exist yet (or fail to decode):
            // render the composed icon hero instead of a broken-image box.
            errorBuilder: (context, error, stackTrace) => fallback,
          ),
        ),
      ),
    );
  }
}

/// The composed (asset-free) hero: a large accent glyph with a stat flourish
/// and a row of supporting icons. Used directly when no screenshot is set, and
/// as the errorBuilder fallback for [_ScreenshotHero].
class _ComposedHero extends StatelessWidget {
  final _Spotlight spotlight;
  final Color accent;
  final ThemeColors colors;

  const _ComposedHero({
    required this.spotlight,
    required this.accent,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hero glyph in an accent-tinted disc.
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: 0.28),
                  accent.withValues(alpha: 0.10),
                ],
              ),
              border: Border.all(
                color: accent.withValues(alpha: 0.45),
                width: 1.5,
              ),
            ),
            child: Icon(spotlight.icon, size: 46, color: accent),
          ),
          const SizedBox(height: AppSpacing.md),

          // Stat flourish — big glanceable number + muted label.
          StatNumber(
            value: spotlight.statValue,
            size: StatType.primary,
            color: colors.textPrimary,
            alignment: Alignment.center,
          ),
          const SizedBox(height: 2),
          Text(
            spotlight.statLabel,
            style: TextStyle(
              fontSize: StatType.label,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              color: colors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Supporting icon strip — small accent-tinted glyph chips.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < spotlight.supportingIcons.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.sm),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: colors.cardBorder, width: 1),
                  ),
                  child: Icon(
                    spotlight.supportingIcons[i],
                    size: 20,
                    color: accent.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
