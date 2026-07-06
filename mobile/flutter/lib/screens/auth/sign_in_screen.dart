import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_links.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/api_client.dart';
import '../onboarding/pre_auth_quiz_screen.dart';
import '../onboarding/onboarding_experiments.dart';
import '../onboarding/widgets/onboarding_theme.dart';
import '../../core/services/posthog_service.dart';
import 'widgets/pre_auth_referral_chip.dart';
import 'package:fitwiz/core/constants/branding.dart';

import '../../l10n/generated/app_localizations.dart';

/// Glassmorphic sign-in screen shown after quiz and preview
class SignInScreen extends ConsumerStatefulWidget {
  /// When true, renders in returning-user mode regardless of any lingering
  /// pre-auth quiz data in SharedPreferences. Set from the "Already have an
  /// account? Sign In" entry on the intro screen.
  final bool forceReturning;

  const SignInScreen({super.key, this.forceReturning = false});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  String? _loadingMessage;
  final List<String> _loadingMessages = [
    'Connecting to server...',
    'Setting things up...',
    'Almost there...',
    'Verifying credentials...',
  ];

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// True only on real iOS / iPadOS devices. Apple Sign In is not supported
  /// on web (where Platform throws) or other platforms.
  bool get _showAppleSignIn => !kIsWeb && Platform.isIOS;

  Future<void> _signInWithApple() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = _loadingMessages[0];
    });

    int messageIndex = 0;
    final messageTimer =
        Stream.periodic(
          const Duration(seconds: 3),
          (_) => _loadingMessages[++messageIndex % _loadingMessages.length],
        ).listen((message) {
          if (mounted && _isLoading) {
            setState(() => _loadingMessage = message);
          }
        });

    try {
      await ref.read(authStateProvider.notifier).signInWithApple();

      // Auth flip can synchronously dispose this ConsumerState via the
      // GoRouter redirect listener — touching `ref` after that throws
      // StateError("Cannot use ref after the widget was disposed"), which
      // leaves the loading overlay stuck and the user seeing a frozen
      // sign-in screen even though the redirect already happened.
      if (!mounted) return;

      final authState = ref.read(authStateProvider);
      final user = authState.user;
      if (user != null &&
          user.isFirstLogin &&
          user.hasSupportFriend &&
          mounted) {
        _showSupportFriendWelcome();
      }

      // Founder sheet is shown on MainShell (the actual destination) — showing
      // it here would race with the GoRouter redirect and tear down under us.

      // Funnel: closes the demo-showcase → sign-in → paywall_pricing_viewed
      // gap so paywall-reach rate is measurable per auth method.
      ref
          .read(posthogServiceProvider)
          .capture(
            eventName: 'onboarding_signin_completed',
            properties: {
              'method': 'apple',
              'is_first_login': user?.isFirstLogin ?? false,
            },
          );

      _triggerEarlyGeneration();

      // See _signInWithGoogle for rationale.
      if (authState.status == AuthStatus.authenticated && user != null) {
        // 250ms grace before checking — by then the SignIn screen MAY have been
        // popped by GoRouter's refreshListenable. If so, the BuildContext is no
        // longer under a route subtree and `GoRouterState.of(context)` throws
        // "There is no GoRouterState above the current context" (Sentry
        // FITWIZ-FLUTTER-7A). Use the router-level routerDelegate path which
        // is available on any Element under the GoRouter widget tree —
        // including a stale SignIn context that's been popped off the route
        // stack but not yet disposed.
        Future<void>.delayed(const Duration(milliseconds: 250), () {
          if (!mounted) return;
          String? loc;
          try {
            loc = GoRouter.of(
              context,
            ).routerDelegate.currentConfiguration.uri.path;
          } catch (e) {
            // Truly disconnected from the router — nothing we can safely do.
            debugPrint('🧭 [SignIn] Router unreachable post-auth: $e');
            return;
          }
          if (loc == '/sign-in') {
            debugPrint(
              '🧭 [SignIn] Auth flipped but redirect did not fire — '
              'force-navigating to next onboarding step (router will rewrite if needed)',
            );
            // Post-paywall treatment routes a fresh user to coach-selection
            // first (personal-info now comes after the paywall); default order
            // still goes to personal-info. Either way the router redirect
            // rewrites to the user's true next step.
            context.go(
              OnboardingExperiments.personalInfoAfterPaywall
                  ? '/coach-selection'
                  : '/personal-info',
            );
          }
        });
      }
    } finally {
      messageTimer.cancel();
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingMessage = null;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = _loadingMessages[0];
    });

    int messageIndex = 0;
    final messageTimer =
        Stream.periodic(
          const Duration(seconds: 3),
          (_) => _loadingMessages[++messageIndex % _loadingMessages.length],
        ).listen((message) {
          if (mounted && _isLoading) {
            setState(() => _loadingMessage = message);
          }
        });

    try {
      await ref.read(authStateProvider.notifier).signInWithGoogle();

      // See _signInWithApple — same dispose-during-await race.
      if (!mounted) return;

      final authState = ref.read(authStateProvider);
      final user = authState.user;
      if (user != null &&
          user.isFirstLogin &&
          user.hasSupportFriend &&
          mounted) {
        _showSupportFriendWelcome();
      }

      // Founder sheet is shown on MainShell (the actual destination) — showing
      // it here would race with the GoRouter redirect and tear down under us.

      // Funnel: closes the demo-showcase → sign-in → paywall_pricing_viewed
      // gap so paywall-reach rate is measurable per auth method.
      ref
          .read(posthogServiceProvider)
          .capture(
            eventName: 'onboarding_signin_completed',
            properties: {
              'method': 'google',
              'is_first_login': user?.isFirstLogin ?? false,
            },
          );

      _triggerEarlyGeneration();

      // Belt-and-suspenders: GoRouter's refreshListenable should redirect us
      // off /sign-in the instant authState flips to authenticated. If — for
      // any reason (notifier race, stale sub) — we're still mounted on
      // /sign-in 250 ms after the auth flip, force-navigate to the next
      // onboarding step ourselves. The router's redirect handler will pick
      // the right destination based on the user record.
      if (authState.status == AuthStatus.authenticated && user != null) {
        // 250ms grace before checking — by then the SignIn screen MAY have been
        // popped by GoRouter's refreshListenable. If so, the BuildContext is no
        // longer under a route subtree and `GoRouterState.of(context)` throws
        // "There is no GoRouterState above the current context" (Sentry
        // FITWIZ-FLUTTER-7A). Use the router-level routerDelegate path which
        // is available on any Element under the GoRouter widget tree —
        // including a stale SignIn context that's been popped off the route
        // stack but not yet disposed.
        Future<void>.delayed(const Duration(milliseconds: 250), () {
          if (!mounted) return;
          String? loc;
          try {
            loc = GoRouter.of(
              context,
            ).routerDelegate.currentConfiguration.uri.path;
          } catch (e) {
            // Truly disconnected from the router — nothing we can safely do.
            debugPrint('🧭 [SignIn] Router unreachable post-auth: $e');
            return;
          }
          if (loc == '/sign-in') {
            debugPrint(
              '🧭 [SignIn] Auth flipped but redirect did not fire — '
              'force-navigating to next onboarding step (router will rewrite if needed)',
            );
            // Post-paywall treatment routes a fresh user to coach-selection
            // first (personal-info now comes after the paywall); default order
            // still goes to personal-info. Either way the router redirect
            // rewrites to the user's true next step.
            context.go(
              OnboardingExperiments.personalInfoAfterPaywall
                  ? '/coach-selection'
                  : '/personal-info',
            );
          }
        });
      }
    } finally {
      messageTimer.cancel();
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingMessage = null;
        });
      }
    }
  }

  void _triggerEarlyGeneration() {
    // Quiz preferences are now POSTed by AuthNotifier._syncQuizAfterSignIn
    // synchronously inside signInWithGoogle, so by the time we reach here the
    // backend already has the user's preferences. Just kick the generation
    // endpoint to warm up workout-of-the-day so the home screen loads instantly.
    Future<void>(() async {
      try {
        final apiClient = ref.read(apiClientProvider);
        final userId = await apiClient.getUserId();
        if (userId == null) return;

        await apiClient.get('${ApiConstants.workouts}/today?user_id=$userId');
        debugPrint('✅ [EarlyGen] Workout generation warmed up');
      } catch (e) {
        debugPrint('⚠️ [EarlyGen] Early generation failed (non-critical): $e');
      }
    });
  }

  void _showSupportFriendWelcome() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.support_agent, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Welcome to ${Branding.appName}!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${Branding.appName} Support is now your friend. Reach out anytime for help!',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.teal,
        duration: const Duration(seconds: 5),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = OnboardingTheme.of(context);
    final authState = ref.watch(authStateProvider);

    Widget errorWidget = const SizedBox.shrink();
    if (authState.status == AuthStatus.error &&
        authState.errorMessage != null) {
      errorWidget = Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                authState.errorMessage!,
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ),
          ],
        ),
      ).animate().fadeIn().shake();
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: t.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        body: OnboardingBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            _buildHeroZone(t),
                            const Spacer(),
                            _buildSignInButtons(t),
                            errorWidget,
                            // Single consent disclosure lives above the
                            // sign-in buttons in `_ConsentDisclosure` —
                            // covers Terms, Privacy Policy, AND the
                            // Health Disclaimer (the legally required
                            // one for an AI fitness app). The duplicate
                            // "By continuing…" line that used to render
                            // here was redundant.
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Merges the old `_buildHeader` (back + progress row) and the top of the
  /// old `_buildMainContent` (icon/kicker/title/subtitle) into one zone so a
  /// single full-bleed animated background can sit behind all of it — the
  /// plan card stays outside, in the solid area below.
  Widget _buildHeroZone(OnboardingTheme t) {
    // Progress reflects pre-auth quiz completion. Users who come directly to
    // sign-in from /intro (without doing the quiz) shouldn't see "90% done".
    final quizData = ref.watch(preAuthQuizProvider);
    final quizStarted =
        !widget.forceReturning &&
        (quizData.goals != null ||
            quizData.fitnessLevel != null ||
            quizData.daysPerWeek != null ||
            (quizData.equipment?.isNotEmpty ?? false));
    final showProgressPill = quizStarted;
    final progressFraction = quizData.isComplete ? 0.9 : 0.5;
    final progressPercent = (progressFraction * 100).round();
    // "One quick step left" only holds up once we're actually at 90% —
    // coach-selection/personal-info still follow sign-in either way, so
    // don't imply near-completion earlier than that.
    final showStepMicrocopy = quizData.isComplete;

    // Intro carousel now routes *everyone* here via a single "Continue"
    // button, so the copy must work for both new sign-ups and returning
    // sign-ins. "Let's get started" + "Sign in or create an account"
    // stays neutral; "Continue with Google/Email" below handles both
    // paths transparently (the backend upserts on first Google auth;
    // the email screen has its own Sign In / Sign Up toggle).
    // v7: loss aversion replaces "Almost There!" — the user just watched
    // their plan get built; signing in is now about not losing it.
    final title = quizStarted
        ? AppLocalizations.of(context).signInV7DontLoseIt
        : AppLocalizations.of(context).signInV7LetsGetStarted;
    final subtitle = quizStarted
        ? _buildPersonalizedSubtitle(quizData)
        : 'Sign in or create an account to continue';

    final headerRow = Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // De-emphasized back affordance — plain text, not a glass pill.
          // This is an escape hatch, not a choice with equal weight to
          // continuing, so it shouldn't compete visually with moving forward.
          GestureDetector(
            // Pop one screen back if anything pushed us here (demo-tasks,
            // capability-and-community, etc.). Only fall back to /intro
            // when sign-in is the root (deep-link / cold returning user).
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(
                  (!widget.forceReturning && quizStarted)
                      ? '/pre-auth-quiz'
                      : '/intro',
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_rounded, color: t.textMuted, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    AppLocalizations.of(context).commonBack,
                    style: TextStyle(
                      color: t.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          // Glassmorphic progress pill — only shown if the user has started the quiz
          if (showProgressPill)
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: t.cardFill,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: t.borderDefault),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 60,
                            height: 6,
                            child: Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: t.borderDefault,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor: progressFraction,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          t.textPrimary.withValues(alpha: 0.9),
                                          t.textPrimary.withValues(alpha: 0.6),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$progressPercent%',
                            style: TextStyle(
                              color: t.textPrimary.withValues(alpha: 0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (showStepMicrocopy) ...[
                  const SizedBox(height: 4),
                  Text(
                    'One quick step left',
                    style: TextStyle(
                      color: t.accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          const Spacer(),
          const SizedBox(width: 44),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);

    final heroContent = Column(
      children: [
        headerRow,
        // Pulsing app icon
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (_pulseController.value * 0.05),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: t.textPrimary.withOpacity(
                        0.15 + _pulseController.value * 0.1,
                      ),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: t.cardFill,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: t.borderDefault),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Image.asset(
                          'assets/images/app_icon.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.fitness_center,
                            color: t.textPrimary,
                            size: 48,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.8, 0.8)),

        const SizedBox(height: 28),

        // Kicker — only meaningful when a plan exists to protect.
        if (quizStarted)
          Text(
            AppLocalizations.of(context).signInV7KickerPlanBuilt,
            style: TextStyle(
              fontFamily: 'Barlow Condensed',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.5,
              color: t.accent,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 250.ms),
        if (quizStarted) const SizedBox(height: 6),

        // Title
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Anton',
            fontSize: 36,
            height: 1.02,
            color: t.textPrimary,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 300.ms),

        const SizedBox(height: 12),

        // Subtitle
        Text(
          subtitle,
          style: TextStyle(fontSize: 16, color: t.textSecondary, height: 1.4),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 400.ms),
      ],
    );

    return Column(
      children: [
        // Full-bleed faded scene-loop background — same technique as the
        // real intro screen's looping app-demo (AnimationController + bottom
        // gradient scrim), dialed down to low-opacity background texture.
        // Only shown once there's an actual plan to preview.
        Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(child: _HeroSceneBackground(t: t)),
            heroContent,
          ],
        ),
        if (quizStarted) ...[
          const SizedBox(height: 32),
          // Value reminder card — only meaningful if user actually did the quiz
          _buildValueReminderCard(
            quizData,
            t,
          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
        ],
      ],
    );
  }

  Widget _buildValueReminderCard(PreAuthQuizData quizData, OnboardingTheme t) {
    String goalDisplay = _formatGoal(quizData.goal ?? 'build_muscle');

    // v7: the card now carries the plan's own goal date (computed during
    // /plan-analyzing) so the account ask reads as protecting something
    // concrete. READY badge is brand orange, not green.
    String? goalDateLabel;
    final iso = quizData.goalTargetDate;
    if (iso != null) {
      final parsed = DateTime.tryParse(iso);
      if (parsed != null) {
        goalDateLabel = DateFormat('MMM d').format(parsed);
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.cardFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  // Non-breaking "2 days/week" (NBSP + word-joiners around "/")
                  // so it never splits mid-token as "2 days/" / "week"; it
                  // wraps cleanly before the phrase instead.
                  'Your $goalDisplay Plan · '
                  '${quizData.daysPerWeek ?? 3} days⁠/⁠week',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: t.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: t.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  AppLocalizations.of(context).signInReady,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: t.accent,
                  ),
                ),
              ),
            ],
          ),
          if (goalDateLabel != null) ...[
            const SizedBox(height: 10),
            Text(
              AppLocalizations.of(context).signInV7GoalDateChip(goalDateLabel),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: t.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSignInButtons(OnboardingTheme t) {
    // On iOS, Apple Sign-In renders ABOVE Google to satisfy Apple Human
    // Interface Guidelines for "Sign in with Apple" — reviewers occasionally
    // flag apps that hide the SIWA option below other social sign-ins.
    return Column(
      children: [
        if (_showAppleSignIn) ...[
          GestureDetector(
            onTap: _isLoading ? null : _signInWithApple,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(27),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    // White pill: was black-on-black against the screen's
                    // dark background, barely distinguishable from the
                    // page or from the Google button below it.
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(27),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.apple, color: Colors.black, size: 22),
                      SizedBox(width: 10),
                      Text(
                        AppLocalizations.of(context).authContinueWithApple,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
          const SizedBox(height: 12),
        ],
        // Google Sign In button — neutral card (NOT the orange CTA: auth
        // providers stay visually unbranded so Apple-first ordering reads).
        GestureDetector(
          onTap: _isLoading ? null : _signInWithGoogle,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(27),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  // Matches the Apple button — white pill, same reasoning.
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(27),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                child: _isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.black54,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _loadingMessage ??
                                AppLocalizations.of(context).signInSigningIn,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.network(
                            'https://www.google.com/favicon.ico',
                            width: 20,
                            height: 20,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.g_mobiledata,
                              size: 24,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            AppLocalizations.of(context).authContinueWithGoogle,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.1),

        const SizedBox(height: 16),

        // Email Sign In — bordered button. Was a plain underlined text
        // link, easy to miss entirely below the two white Apple/Google
        // pills; still visually tertiary to those two, but no longer
        // invisible. (Was also a hardcoded English string — now routed
        // through the existing `authContinueWithEmail` l10n key.)
        GestureDetector(
          onTap: _isLoading
              ? null
              : () => context.push(
                  widget.forceReturning
                      ? '/email-sign-in?returning=true'
                      : '/email-sign-in',
                ),
          child: Container(
            width: double.infinity,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: t.textPrimary.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: t.textPrimary.withValues(alpha: 0.28),
                width: 1.5,
              ),
            ),
            child: Text(
              AppLocalizations.of(context).authContinueWithEmail,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: t.textPrimary,
              ),
            ),
          ),
        ).animate().fadeIn(delay: 800.ms),

        const SizedBox(height: 14),

        // Referral code capture — stored pre-auth, auto-applied after
        // sign-in completes (see AuthStateNotifier._flushPendingReferral).
        const PreAuthReferralChip(),

        const SizedBox(height: 18),

        // Legal disclosure — moved BELOW the sign-in buttons to match
        // the iOS HIG / Apple App Store convention (terms shown after
        // the action, not before). Single comprehensive disclosure
        // that covers Terms · Privacy · Health Disclaimer.
        _ConsentDisclosure(t: t),
      ],
    );
  }

  /// Builds a founder-note style subtitle — first-person, warm,
  /// handwritten voice instead of marketing copy. Pulls the user's
  /// first name + goal + weight delta from the quiz to make it feel
  /// like a real letter from Chetan, not a template. The aim is to
  /// nudge the user to continue, not to sell.
  String _buildPersonalizedSubtitle(PreAuthQuizData quiz) {
    final firstName = (quiz.name ?? '').trim().split(RegExp(r'\s+')).first;
    final hasName = firstName.isNotEmpty;
    final greeting = hasName ? 'Hey $firstName' : 'Hey';
    final direction = (quiz.weightDirection ?? '').toLowerCase();
    final goalKg = quiz.goalWeightKg;
    final currentKg = quiz.weightKg;

    // If we have a real weight delta, lead with the human-sized number.
    if (goalKg != null && currentKg != null && direction.isNotEmpty) {
      final deltaKg = (currentKg - goalKg).abs();
      final deltaLb = (deltaKg * 2.20462).round();
      if (deltaLb >= 1) {
        if (direction == 'gain') {
          return "$greeting — I built your plan to put on $deltaLb lb. Save it and let's start tomorrow.";
        }
        return "$greeting — I built your plan to drop $deltaLb lb. Save it and let's start tomorrow.";
      }
    }

    // Strength / endurance / maintain users get a goal-shaped variant.
    final goalKey = (quiz.goal ?? '').toLowerCase();
    String voice;
    if (goalKey.contains('muscle')) {
      voice = "I built you a plan to put on real muscle.";
    } else if (goalKey.contains('strength')) {
      voice = "I built you a plan to get stronger every week.";
    } else if (goalKey.contains('endurance')) {
      voice = "I built you a plan to outlast everyone.";
    } else if (goalKey.contains('active')) {
      voice = "I built you a plan to actually keep moving.";
    } else if (goalKey.contains('athletic')) {
      voice = "I built you a plan to perform like an athlete.";
    } else {
      voice = "Your plan is ready and shaped around what you told me.";
    }
    return "$greeting — $voice Save it and let's start tomorrow.";
  }

  /// Renders the goal as a noun phrase so "Your $goalDisplay Plan"
  /// reads naturally — "Your Weight Loss Plan" / "Your Strength Plan"
  /// instead of the verb-led "Your Lose Weight Plan".
  String _formatGoal(String goal) {
    switch (goal) {
      case 'build_muscle':
        return 'Muscle Building';
      case 'lose_weight':
        return 'Weight Loss';
      case 'increase_strength':
        return 'Strength';
      case 'improve_endurance':
        return 'Endurance';
      case 'stay_active':
        return 'Active Lifestyle';
      case 'athletic_performance':
        return 'Performance';
      default:
        return 'Fitness';
    }
  }
}

/// Full-bleed, faded, looping background for the hero zone — reuses the
/// same technique as the real `/intro` screen's live 4-scene app demo
/// (an `AnimationController` looping fake UI content + a bottom gradient
/// scrim), just dialed down from full-opacity foreground content to
/// low-opacity background texture. Cycles through three abstract scenes
/// (workout rows, a progress chart, a calendar grid) on a 12s loop.
///
/// Every scene is anchored from the TOP of the zone. Anything anchored
/// from the bottom lands inside the scrim's fade-to-background area and
/// renders but is invisible — hit this once building the HTML mockup this
/// was ported from (see project_paywall_screen_bg_animation_mockup memory).
class _HeroSceneBackground extends StatefulWidget {
  final OnboardingTheme t;
  const _HeroSceneBackground({required this.t});

  @override
  State<_HeroSceneBackground> createState() => _HeroSceneBackgroundState();
}

class _HeroSceneBackgroundState extends State<_HeroSceneBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _calendarOn = {1, 3, 6, 7, 10, 12, 15, 18};

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Each scene fades in, holds, and fades out within its own third of the
  /// 12s loop, staggered so only one scene is ever fully visible at a time.
  double _opacityFor(int sceneIndex) {
    double phase = _controller.value - (sceneIndex / 3.0);
    phase = phase % 1.0;
    if (phase < 0) phase += 1.0;
    if (phase < 0.06) return 0;
    if (phase < 0.16) return (phase - 0.06) / 0.10;
    if (phase < 0.26) return 1;
    if (phase < 0.36) return 1 - (phase - 0.26) / 0.10;
    return 0;
  }

  /// Anchors [child] to the top of the zone (not stretched to fill it) and
  /// fades it in/out per [sceneIndex] — mirrors `position:absolute; top:`
  /// in the source mockup rather than a Stack that stretches non-positioned
  /// children to the full zone height.
  Widget _scene(int sceneIndex, Widget child) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, cached) =>
            Opacity(opacity: _opacityFor(sceneIndex), child: cached),
        child: child,
      ),
    );
  }

  Widget _row({required Color color, required double opacity}) {
    return Container(
      height: 14,
      decoration: BoxDecoration(
        color: color.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(7),
      ),
    );
  }

  Widget _dot() {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.55),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _chartBar(double height, Color color) {
    return Container(
      width: 16,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.55),
            color.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.t.isDark;
    final neutral = isDark ? Colors.white : Colors.black;
    final scrimColor = isDark
        ? const Color(0xFF050505)
        : const Color(0xFFFAFAFA);

    return Stack(
      children: [
        // Scene 1 — workout list rows, anchored top.
        _scene(
          0,
          SizedBox(
            width: double.infinity,
            height: 60,
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 40,
                  child: _row(color: AppColors.orange, opacity: 0.32),
                ),
                Positioned(
                  top: 22,
                  left: 0,
                  right: 90,
                  child: _row(color: neutral, opacity: 0.16),
                ),
                Positioned(
                  top: 44,
                  left: 0,
                  right: 40,
                  child: _row(color: AppColors.orange, opacity: 0.32),
                ),
                Positioned(top: 0, right: 0, child: _dot()),
                Positioned(top: 44, right: 0, child: _dot()),
              ],
            ),
          ),
        ),
        // Scene 2 — progress chart, anchored top (bars grow up from a
        // baseline near the top of the zone, not the bottom — see the
        // class doc comment on why bottom-anchoring here is a trap).
        _scene(
          1,
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _chartBar(26, AppColors.purple),
                  const SizedBox(width: 8),
                  _chartBar(42, AppColors.purple),
                  const SizedBox(width: 8),
                  _chartBar(34, AppColors.purple),
                  const SizedBox(width: 8),
                  _chartBar(58, AppColors.cyan),
                  const SizedBox(width: 8),
                  _chartBar(46, AppColors.purple),
                ],
              ),
            ),
          ),
        ),
        // Scene 3 — calendar / week grid, anchored top.
        _scene(
          2,
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SizedBox(
                width: 180,
                child: Column(
                  children: List.generate(3, (row) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: List.generate(7, (col) {
                          final on = _calendarOn.contains(row * 7 + col);
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: on
                                        ? AppColors.orange.withValues(
                                            alpha: 0.50,
                                          )
                                        : neutral.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
        // Bottom scrim — fades the loop into the surrounding page
        // background (OnboardingBackground's gradient is solid by this
        // point) so it blends instead of hard-cutting at an edge.
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.62, 0.85, 1.0],
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  scrimColor.withValues(alpha: 0.85),
                  scrimColor,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Inline consent disclosure shown above the sign-in buttons.
///
/// Onboarding v5.1: replaces the standalone /ai-consent and /health-disclaimer
/// screens. The pattern is "by tapping sign-in you agree to..." with the
/// three legal documents linked inline — same legal coverage as a blocking
/// screen but without the friction. Standard for AI fitness apps in 2026.
class _ConsentDisclosure extends StatelessWidget {
  final OnboardingTheme t;
  const _ConsentDisclosure({required this.t});

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(fontSize: 11, color: t.textSecondary, height: 1.45);
    final link = base.copyWith(
      color: AppColors.orange,
      fontWeight: FontWeight.w700,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.orange,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: base,
          children: [
            const TextSpan(text: 'By signing in you agree to our '),
            TextSpan(
              text: 'Terms',
              style: link,
              recognizer: TapGestureRecognizer()
                ..onTap = () => _open(AppLinks.termsOfService),
            ),
            const TextSpan(text: ', '),
            TextSpan(
              text: 'Privacy Policy',
              style: link,
              recognizer: TapGestureRecognizer()
                ..onTap = () => _open(AppLinks.privacyPolicy),
            ),
            const TextSpan(text: ', and '),
            TextSpan(
              text: 'Health Disclaimer',
              style: link,
              recognizer: TapGestureRecognizer()
                ..onTap = () => _open('${AppLinks.website}/health-disclaimer'),
            ),
            const TextSpan(text: '.'),
          ],
        ),
      ),
    );
  }
}
