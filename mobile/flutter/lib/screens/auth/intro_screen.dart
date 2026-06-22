import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/posthog_service.dart';
import '../../l10n/generated/app_localizations.dart';
import '../onboarding/onboarding_experiments.dart';
import 'intro_demo/demo_clock.dart';
import 'intro_demo/demo_scenes.dart';
import 'package:fitwiz/core/constants/branding.dart';

/// Intro Screen — first-run redesign v7 ("V1b full-bleed demo").
///
/// The screen IS the product: a 10-second auto-playing loop of four real
/// app surfaces (program builder → live logging → food scan → menu
/// analysis with live re-sort). The pitch rising out of the scrim is a static
/// all-in-one HERO — "ONE APP. NOT FIVE." — that lands the consolidation moat
/// in <1s (clarity + a contrast word convert best), with a SMALL rotating sub
/// ("› builds your plan" → "counts your macros"…) narrating each demo scene.
/// (Replaced "your coach is already typing" → "ALREADY {…}", whose "ALREADY"
/// made no sense cold; the paywall price anchor later proves "not five".)
///
/// Navigation is byte-identical to v5/v6:
///   - Primary CTA → /onboarding-why (the emotional-anchor funnel entry)
///   - "I have an account" → /sign-in?returning=true
/// Any tap on the demo itself acts as the primary CTA.
///
/// Kill switch: `onboarding_v7_intro_demo` (PostHog, default ON, fail-open)
/// drops back to the v5 outcome-hero layout without a redeploy.
class IntroScreen extends ConsumerStatefulWidget {
  const IntroScreen({super.key});

  @override
  ConsumerState<IntroScreen> createState() => _IntroScreenState();
}

/// The base four demo scenes, always present, in loop order. Indexes here are
/// the scene's stable identity (used by [_IntroScreenState._buildScene] /
/// [_IntroScreenState._wordForKind]); the WINDOW a scene occupies is its
/// position in the resolved [_IntroScreenState._scenes] list, which the two
/// optional scenes append to when their flags are on.
enum _DemoScene {
  programBuilder,
  liveLogging,
  foodScan,
  menuAnalysis,
  integrations,
  shareables,
}

class _IntroScreenState extends ConsumerState<IntroScreen>
    with TickerProviderStateMixin {
  late final AnimationController _clock;
  late final AnimationController _pulseController; // legacy fallback only
  bool _demoEnabled = true;
  String _appVersion = '';

  /// The resolved, ordered scene list this session plays. Starts with the
  /// four base scenes (correct before flags resolve / in legacy fallback);
  /// the two Gravl-gap scenes are appended once their flags resolve ON.
  List<_DemoScene> _scenes = const [
    _DemoScene.programBuilder,
    _DemoScene.liveLogging,
    _DemoScene.foodScan,
    _DemoScene.menuAnalysis,
  ];

  @override
  void initState() {
    super.initState();
    // Configure the clock for the base count BEFORE creating the controller
    // so its duration matches the loop length; flags may extend it below.
    DemoClock.configure(_scenes.length);
    _clock = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: DemoClock.sceneMs * 4),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _maybeFallBack();
    _resolveOptionalScenes();
    ref
        .read(posthogServiceProvider)
        .capture(
          eventName: 'onboarding_intro_viewed',
          properties: {'variant': 'v7_demo'},
        );
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _appVersion = info.version);
    });
  }

  /// Resolve the two flag-gated Gravl-gap scenes (both default-ON kill
  /// switches). When a flag is ON its scene is appended to the loop; the
  /// clock + controller duration are re-derived so every scene keeps its full
  /// [DemoClock.sceneMs] window. Fail-open: an unreadable flag keeps the
  /// scene IN (matches the default-ON contract).
  Future<void> _resolveOptionalScenes() async {
    final posthog = ref.read(posthogServiceProvider);
    final showIntegrations = await OnboardingExperiments.isEnabled(
      posthog,
      OnboardingExperiments.flagIntroIntegrations,
    );
    final showShareables = await OnboardingExperiments.isEnabled(
      posthog,
      OnboardingExperiments.flagIntroShareables,
    );
    if (!mounted) return;
    final next = <_DemoScene>[
      _DemoScene.programBuilder,
      _DemoScene.liveLogging,
      _DemoScene.foodScan,
      _DemoScene.menuAnalysis,
      if (showIntegrations) _DemoScene.integrations,
      if (showShareables) _DemoScene.shareables,
    ];
    if (next.length == _scenes.length) return; // nothing changed
    setState(() => _scenes = next);
    DemoClock.configure(next.length);
    // Re-stretch the loop to the new scene count and restart from the top so
    // the dot countdown / fades stay aligned with the longer window.
    _clock.duration = Duration(milliseconds: DemoClock.loopMs);
    _clock
      ..reset()
      ..repeat();
  }

  /// Remote kill switch: explicit off → legacy v5 hero layout.
  Future<void> _maybeFallBack() async {
    final enabled = await OnboardingExperiments.isEnabled(
      ref.read(posthogServiceProvider),
      OnboardingExperiments.flagIntroDemoV7,
    );
    if (!enabled && mounted) {
      setState(() => _demoEnabled = false);
      _clock.stop();
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onGetStarted() {
    HapticFeedback.mediumImpact();
    // Onboarding conversion v6: the "What's your why" emotional anchor now
    // leads the funnel. If its remote kill-switch is off, that screen
    // forwards itself straight into /pre-auth-quiz.
    context.push('/onboarding-why');
  }

  void _onSignIn() {
    HapticFeedback.lightImpact();
    context.push('/sign-in?returning=true');
  }

  @override
  Widget build(BuildContext context) {
    if (!_demoEnabled) return _buildLegacy(context);

    final l10n = AppLocalizations.of(context);

    return AnimatedBuilder(
      animation: _clock,
      builder: (context, _) {
        final tMs = DemoClock.timeMs(_clock.value);
        final scene = DemoClock.sceneOf(tMs);
        final activeKind = _scenes[scene.clamp(0, _scenes.length - 1)];
        // Program-builder & food-scan have light backgrounds at the top of
        // the screen; every other scene (incl. the two new ones) is dark.
        final lightScene =
            activeKind == _DemoScene.programBuilder ||
            activeKind == _DemoScene.foodScan;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: lightScene
              ? SystemUiOverlayStyle.dark
              : SystemUiOverlayStyle.light,
          child: Scaffold(
            backgroundColor: const Color(0xFF0B0B0C),
            body: Stack(
              fit: StackFit.expand,
              children: [
                // ── The demo (any tap = primary CTA) ─────────────────
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _onGetStarted,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      for (var i = 0; i < DemoClock.sceneCount; i++)
                        _scene(i, tMs),
                    ],
                  ),
                ),

                // ── Scrim ────────────────────────────────────────────
                IgnorePointer(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.42, 0.62, 0.78],
                        colors: [
                          Colors.transparent,
                          Color(0xE0080502),
                          Color(0xFF080502),
                        ],
                      ),
                    ),
                  ),
                ),

                // (No brand top bar in the demo variant — the approved V1b
                // mockup lets each scene's own header own the top edge;
                // returning users use the "I have an account" ghost link.)

                // ── Bottom overlay: dots + headline + CTAs ───────────
                SafeArea(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(26, 0, 26, 14),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _dots(tMs, scene),
                          const SizedBox(height: 12),
                          // ── Hero — static, instant: the all-in-one punch.
                          // Clarity + a contrast word ("NOT") land the moat in
                          // <1s (the demo supplies the motion). The price anchor
                          // on the paywall later proves the "not five" claim.
                          const Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'ONE APP. ',
                                  style: TextStyle(color: Color(0xFFFAFAFA)),
                                ),
                                TextSpan(
                                  text: 'NOT FIVE.',
                                  style: TextStyle(color: AppColors.orange),
                                ),
                              ],
                            ),
                            maxLines: 2,
                            style: TextStyle(
                              fontFamily: 'Anton',
                              fontSize: 38,
                              height: 1.02,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // ── Sub — small, rotating: narrates the live demo
                          // scene ("› builds your plan" → "counts your macros"…)
                          // so the four jobs in one app read while you watch.
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 320),
                            layoutBuilder: (current, previous) => Stack(
                              alignment: AlignmentDirectional.centerStart,
                              children: [
                                ...previous,
                                if (current != null) current,
                              ],
                            ),
                            transitionBuilder: (child, anim) => FadeTransition(
                              opacity: anim,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.4),
                                  end: Offset.zero,
                                ).animate(anim),
                                child: child,
                              ),
                            ),
                            child: Text(
                              '›  ${_wordFor(scene, l10n).toLowerCase()}',
                              key: ValueKey(scene),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Barlow Condensed',
                                fontSize: 16,
                                letterSpacing: 0.4,
                                color: Color(0xFFCFCFCF),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: _onGetStarted,
                            child: Container(
                              width: double.infinity,
                              height: 58,
                              decoration: BoxDecoration(
                                color: AppColors.orange,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.orange.withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 26,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${l10n.introV7BuildMyPlan.toUpperCase()}  →',
                                style: const TextStyle(
                                  fontFamily: 'Barlow Condensed',
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2.5,
                                  color: Color(0xFF160B03),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: GestureDetector(
                              onTap: _onSignIn,
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 5,
                                ),
                                child: Text(
                                  l10n.introIAlreadyHaveAnAccount.toUpperCase(),
                                  style: const TextStyle(
                                    fontFamily: 'Barlow Condensed',
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 2.5,
                                    color: Color(0xFF7C7C84),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Headline accent word for the scene occupying window [window]. The base
  /// four keep their localized words; the two new scenes use inline English
  /// copy (no new l10n keys per the redesign contract).
  String _wordFor(int window, AppLocalizations l10n) {
    final kind = _scenes[window.clamp(0, _scenes.length - 1)];
    return switch (kind) {
      _DemoScene.programBuilder => l10n.introV7WordTyping,
      _DemoScene.liveLogging => l10n.introV7WordSpotting,
      _DemoScene.foodScan => l10n.introV7WordCounting,
      _DemoScene.menuAnalysis => l10n.introV7WordChoosing,
      _DemoScene.integrations => 'SYNCS YOUR DATA',
      _DemoScene.shareables => 'SHARES YOUR WINS',
    };
  }

  /// Render the scene occupying window [window] at global time [tMs]. The
  /// window index drives the fade/opacity math; the [_DemoScene] at that slot
  /// drives WHICH scene widget renders.
  Widget _scene(int window, int tMs) {
    final opacity = DemoClock.opacityFor(window, tMs);
    if (opacity <= 0) return const SizedBox.shrink();
    final local = DemoClock.localMs(tMs);
    final kind = _scenes[window.clamp(0, _scenes.length - 1)];
    final child = switch (kind) {
      _DemoScene.programBuilder => ProgramBuilderScene(localMs: local),
      _DemoScene.liveLogging => LiveLoggingScene(localMs: local),
      _DemoScene.foodScan => FoodScanScene(localMs: local),
      _DemoScene.menuAnalysis => MenuAnalysisScene(localMs: local),
      _DemoScene.integrations => IntegrationsGridScene(localMs: local),
      _DemoScene.shareables => ShareablesScene(localMs: local),
    };
    return Opacity(opacity: opacity, child: child);
  }

  Widget _dots(int tMs, int scene) {
    return Row(
      children: List.generate(DemoClock.sceneCount, (i) {
        final active = i == scene;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            _clock.value = DemoClock.valueForScene(i);
          },
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(end: 7),
            child: active
                ? Container(
                    width: 22,
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B3200),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: FractionallySizedBox(
                        widthFactor: DemoClock.sceneFraction(tMs),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.orange,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  )
                : Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                  ),
          ),
        );
      }),
    );
  }

  // ── Legacy v5 layout (kill-switch fallback) ─────────────────────────

  Widget _buildLegacy(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.textPrimary
        : AppColorsLight.textPrimary;
    final textSecondary = isDark
        ? AppColors.textSecondary
        : AppColorsLight.textSecondary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.4),
            radius: 1.2,
            colors: isDark
                ? [
                    AppColors.orange.withValues(alpha: 0.15),
                    AppColors.pureBlack,
                  ]
                : [
                    AppColors.orange.withValues(alpha: 0.08),
                    AppColorsLight.pureWhite,
                  ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: Image.asset(
                            'assets/icon/app_icon.png',
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              Branding.appName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                                letterSpacing: -0.3,
                                height: 1.0,
                              ),
                            ),
                            if (_appVersion.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                l10n.introScreenV(_appVersion),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: textSecondary.withValues(alpha: 0.7),
                                  height: 1.0,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: _onSignIn,
                      child: Text(
                        l10n.authSignIn,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(flex: 2),
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, __) {
                    return Container(
                      width: 132,
                      height: 132,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(34),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.orange.withValues(
                              alpha: 0.35 + (_pulseController.value * 0.25),
                            ),
                            blurRadius: 50 + (_pulseController.value * 20),
                            spreadRadius: 6,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(34),
                        child: Image.asset(
                          'assets/icon/app_icon.png',
                          width: 132,
                          height: 132,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ).animate().scale(duration: 700.ms, curve: Curves.elasticOut),
                const SizedBox(height: 36),
                Text(
                  l10n.introYourBody,
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: textPrimary,
                    letterSpacing: -1.5,
                    height: 1.0,
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.15),
                const SizedBox(height: 4),
                Text(
                  l10n.introYourTimeline,
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: AppColors.orange,
                    letterSpacing: -1.5,
                    height: 1.0,
                  ),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.15),
                const SizedBox(height: 18),
                Text(
                  l10n.introTagline,
                  style: TextStyle(
                    fontSize: 16,
                    color: textSecondary,
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 600.ms),
                const Spacer(flex: 3),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.glassSurface.withValues(alpha: 0.5)
                        : AppColorsLight.glassSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? AppColors.cardBorder
                          : AppColorsLight.cardBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatPill(
                        value: '1,700+',
                        label: l10n.authIntroExercises,
                        color: const Color(0xFF00BCD4),
                      ),
                      _Divider(),
                      _StatPill(
                        value: '1M+',
                        label: l10n.authIntroFoods,
                        color: const Color(0xFF2ECC71),
                      ),
                      _Divider(),
                      _StatPill(
                        value: '24/7',
                        label: l10n.authIntroAiCoach,
                        color: AppColors.orange,
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.1),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: _onGetStarted,
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: AlignmentDirectional.topStart,
                        end: AlignmentDirectional.bottomEnd,
                        colors: [
                          Color(0xFFFFB366), // orangeLight
                          AppColors.orange,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.orange.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l10n.introBuildMyPlan,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.1),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: _onSignIn,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      l10n.introIAlreadyHaveAnAccount,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 1200.ms),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatPill({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark
        ? AppColors.textSecondary
        : AppColorsLight.textSecondary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: textSecondary,
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 1,
      height: 28,
      color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
    );
  }
}
