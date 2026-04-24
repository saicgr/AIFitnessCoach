import 'dart:async';
import 'dart:ui';
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
import '../../core/providers/window_mode_provider.dart';
import '../../data/models/ai_profile_payload.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/api_client.dart';
import '../onboarding/pre_auth_quiz_screen.dart';
import '../onboarding/widgets/foldable_quiz_scaffold.dart';
import '../onboarding/widgets/onboarding_theme.dart';
import 'widgets/pre_auth_referral_chip.dart';

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
    Future<void>(() async {
      try {
        final apiClient = ref.read(apiClientProvider);
        final userId = await apiClient.getUserId();
        if (userId == null) return;

        final quizData = ref.read(preAuthQuizProvider);
        final payload = AIProfilePayloadBuilder.buildPayload(quizData);

        if (quizData.gender != null) payload['gender'] = quizData.gender;
        if (quizData.age != null) payload['age'] = quizData.age;
        if (quizData.heightCm != null) payload['height_cm'] = quizData.heightCm;
        if (quizData.weightKg != null) payload['weight_kg'] = quizData.weightKg;
        if (quizData.workoutDays != null) payload['workout_days'] = quizData.workoutDays;

        await apiClient.post(
          '${ApiConstants.users}/$userId/preferences',
          data: payload,
        );
        debugPrint('✅ [EarlyGen] Preferences submitted');

        await apiClient.get('${ApiConstants.workouts}/today?user_id=$userId');
        debugPrint('✅ [EarlyGen] Generation triggered');
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
                  Text('Welcome to FitWiz!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text('FitWiz Support is now your friend. Reach out anytime for help!', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12)),
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
                          const SizedBox(height: 24),
                          _buildTermsText(t),
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
            onTap: () => context.go(
              (!widget.forceReturning && quizStarted) ? '/pre-auth-quiz' : '/intro',
            ),
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
        ? 'Sign in to save your personalized plan and start your fitness journey'
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your $goalDisplay Plan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: t.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${quizData.daysPerWeek ?? 3} days/week • Personalized for you',
                      style: TextStyle(
                        fontSize: 12,
                        color: t.textMuted,
                      ),
                    ),
                  ],
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
      ],
    );
  }

  Widget _buildTermsText(OnboardingTheme t) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(fontSize: 12, color: t.textMuted, height: 1.4),
        children: [
          const TextSpan(text: 'By continuing, you agree to our '),
          TextSpan(
            text: 'Terms of Service',
            style: TextStyle(
              color: t.textSecondary,
              decoration: TextDecoration.underline,
              decorationColor: t.textMuted,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => launchUrl(Uri.parse('${AppLinks.termsOfService}'), mode: LaunchMode.externalApplication),
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy Policy',
            style: TextStyle(
              color: t.textSecondary,
              decoration: TextDecoration.underline,
              decorationColor: t.textMuted,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => launchUrl(Uri.parse('${AppLinks.privacyPolicy}'), mode: LaunchMode.externalApplication),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 800.ms);
  }

  String _formatGoal(String goal) {
    switch (goal) {
      case 'build_muscle':
        return 'Build Muscle';
      case 'lose_weight':
        return 'Lose Weight';
      case 'increase_strength':
        return 'Strength';
      case 'improve_endurance':
        return 'Endurance';
      case 'stay_active':
        return 'Stay Active';
      case 'athletic_performance':
        return 'Athletic';
      default:
        return 'Fitness';
    }
  }
}
