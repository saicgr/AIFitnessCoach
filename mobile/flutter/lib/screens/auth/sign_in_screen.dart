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
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_links.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/api_client.dart';
import '../onboarding/pre_auth_quiz_screen.dart';
import '../onboarding/widgets/onboarding_theme.dart';
import 'widgets/pre_auth_referral_chip.dart';
import 'package:fitwiz/core/constants/branding.dart';

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
    final messageTimer = Stream.periodic(
      const Duration(seconds: 3),
      (_) => _loadingMessages[++messageIndex % _loadingMessages.length],
    ).listen((message) {
      if (mounted && _isLoading) {
        setState(() => _loadingMessage = message);
      }
    });

    try {
      await ref.read(authStateProvider.notifier).signInWithApple();

      final user = ref.read(authStateProvider).user;
      if (user != null && user.isFirstLogin && user.hasSupportFriend && mounted) {
        _showSupportFriendWelcome();
      }

      // Founder sheet is shown on MainShell (the actual destination) — showing
      // it here would race with the GoRouter redirect and tear down under us.

      _triggerEarlyGeneration();
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
    final messageTimer = Stream.periodic(
      const Duration(seconds: 3),
      (_) => _loadingMessages[++messageIndex % _loadingMessages.length],
    ).listen((message) {
      if (mounted && _isLoading) {
        setState(() => _loadingMessage = message);
      }
    });

    try {
      await ref.read(authStateProvider.notifier).signInWithGoogle();

      final user = ref.read(authStateProvider).user;
      if (user != null && user.isFirstLogin && user.hasSupportFriend && mounted) {
        _showSupportFriendWelcome();
      }

      // Founder sheet is shown on MainShell (the actual destination) — showing
      // it here would race with the GoRouter redirect and tear down under us.

      _triggerEarlyGeneration();
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
                  Text('Welcome to ${Branding.appName}!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text('${Branding.appName} Support is now your friend. Reach out anytime for help!', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12)),
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
    if (authState.status == AuthStatus.error && authState.errorMessage != null) {
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
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          _buildHeader(t),
                          const Spacer(),
                          _buildMainContent(t),
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

  Widget _buildHeader(OnboardingTheme t) {
    // Progress reflects pre-auth quiz completion. Users who come directly to
    // sign-in from /intro (without doing the quiz) shouldn't see "90% done".
    final quizData = ref.watch(preAuthQuizProvider);
    final quizStarted = !widget.forceReturning && (quizData.goals != null ||
        quizData.fitnessLevel != null ||
        quizData.daysPerWeek != null ||
        (quizData.equipment?.isNotEmpty ?? false));
    final showProgressPill = quizStarted;
    final progressFraction = quizData.isComplete ? 0.9 : 0.5;
    final progressPercent = (progressFraction * 100).round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // Glassmorphic "← Back" pill — matches the back affordance on
          // the /intro welcome panel (arrow + text label) so the two
          // entry screens feel like one flow instead of two unrelated
          // pages with mismatched chrome.
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: t.isDark
                        ? Colors.white.withValues(alpha: 0.10)
                        : Colors.black.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: t.isDark
                          ? Colors.white.withValues(alpha: 0.18)
                          : Colors.black.withValues(alpha: 0.15),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back_rounded, color: t.textPrimary, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Back',
                        style: TextStyle(
                          color: t.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          // Glassmorphic progress pill — only shown if the user has started the quiz
          if (showProgressPill)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          const Spacer(),
          const SizedBox(width: 44),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildMainContent(OnboardingTheme t) {
    final quizData = ref.watch(preAuthQuizProvider);
    final quizStarted = !widget.forceReturning && (quizData.goals != null ||
        quizData.fitnessLevel != null ||
        quizData.daysPerWeek != null ||
        (quizData.equipment?.isNotEmpty ?? false));
    // Intro carousel now routes *everyone* here via a single "Continue"
    // button, so the copy must work for both new sign-ups and returning
    // sign-ins. "Let's get started" + "Sign in or create an account"
    // stays neutral; "Continue with Google/Email" below handles both
    // paths transparently (the backend upserts on first Google auth;
    // the email screen has its own Sign In / Sign Up toggle).
    final title = quizStarted ? 'Almost There!' : "Let's get started";
    final subtitle = quizStarted
        ? _buildPersonalizedSubtitle(quizData)
        : 'Sign in or create an account to continue';
    return Column(
      children: [
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
                      color: t.textPrimary.withOpacity(0.15 + _pulseController.value * 0.1),
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

        const SizedBox(height: 32),

        // Title
        Text(
          title,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: t.textPrimary,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 300.ms),

        const SizedBox(height: 12),

        // Subtitle
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 16,
            color: t.textSecondary,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 400.ms),

        if (quizStarted) ...[
          const SizedBox(height: 32),
          // Value reminder card — only meaningful if user actually did the quiz
          _buildValueReminderCard(quizData, t)
              .animate()
              .fadeIn(delay: 500.ms)
              .slideY(begin: 0.1),
        ],
      ],
    );
  }

  Widget _buildValueReminderCard(PreAuthQuizData quizData, OnboardingTheme t) {
    String goalDisplay = _formatGoal(quizData.goal ?? 'build_muscle');

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: t.buttonGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: t.borderDefault),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: t.cardFill,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  color: t.textPrimary.withValues(alpha: 0.9),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Your $goalDisplay Plan · ${quizData.daysPerWeek ?? 3} days/week',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: t.textPrimary,
                  ),
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.success.withOpacity(0.4)),
                    ),
                    child: const Text(
                      'Ready',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignInButtons(OnboardingTheme t) {
    return Column(
      children: [
        // Google Sign In button — glassmorphic
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
                  gradient: LinearGradient(
                    colors: t.buttonGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(27),
                  border: Border.all(color: t.buttonBorder),
                ),
                child: _isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(t.textPrimary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _loadingMessage ?? 'Signing in...',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: t.textSecondary,
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
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.g_mobiledata,
                              size: 24,
                              color: t.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Continue with Google',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: t.textPrimary,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),

        // Apple Sign In button — iOS / iPadOS only (App Store guideline 4.8)
        if (_showAppleSignIn) ...[
          const SizedBox(height: 12),
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
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(27),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.apple, color: Colors.white, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'Continue with Apple',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.1),
        ],

        const SizedBox(height: 16),

        // Email Sign In link
        GestureDetector(
          onTap: _isLoading ? null : () => context.push('/email-sign-in'),
          child: Text(
            'Continue with Email',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: t.textMuted,
              decoration: TextDecoration.underline,
              decorationColor: t.textMuted.withValues(alpha: 0.5),
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
    final base = TextStyle(
      fontSize: 11,
      color: t.textSecondary,
      height: 1.45,
    );
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
