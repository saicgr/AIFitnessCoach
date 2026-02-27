import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../core/providers/window_mode_provider.dart';
import '../../data/models/ai_profile_payload.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/api_client.dart';
import '../onboarding/pre_auth_quiz_screen.dart';
import '../onboarding/widgets/foldable_quiz_scaffold.dart';

/// Dedicated sign-in screen shown after quiz and preview
/// Shows progress indicator and value reinforcement
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

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
    // Quiz data is already preserved in SharedPreferences via PreAuthQuizNotifier
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

      // After successful sign-in, check if we should show welcome message
      final user = ref.read(authStateProvider).user;
      if (user != null && user.isFirstLogin && user.hasSupportFriend && mounted) {
        _showSupportFriendWelcome();
      }

      // Fire-and-forget: submit quiz preferences and trigger workout generation
      // so workouts start generating while the user completes remaining onboarding screens
      _triggerEarlyGeneration();

      // After successful sign-in, navigation happens automatically via router redirect
      // The pre-auth data is still in SharedPreferences and will be loaded in onboarding
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

  /// Fire-and-forget: submit quiz preferences early and trigger workout generation
  /// so workouts are ready by the time the user reaches the loading screen.
  void _triggerEarlyGeneration() {
    Future<void>(() async {
      try {
        final apiClient = ref.read(apiClientProvider);
        final userId = await apiClient.getUserId();
        if (userId == null) return;

        final quizData = ref.read(preAuthQuizProvider);

        // Build workout-relevant preferences from quiz data
        final payload = AIProfilePayloadBuilder.buildPayload(quizData);

        // Add personal info needed for generation
        if (quizData.gender != null) payload['gender'] = quizData.gender;
        if (quizData.age != null) payload['age'] = quizData.age;
        if (quizData.heightCm != null) payload['height_cm'] = quizData.heightCm;
        if (quizData.weightKg != null) payload['weight_kg'] = quizData.weightKg;
        if (quizData.workoutDays != null) payload['workout_days'] = quizData.workoutDays;

        // Submit preferences so backend has workout config for generation
        await apiClient.post(
          '${ApiConstants.users}/$userId/preferences',
          data: payload,
        );
        debugPrint('✅ [EarlyGen] Preferences submitted');

        // Trigger /today which auto-generates workouts for upcoming dates
        await apiClient.get('${ApiConstants.workouts}/today?user_id=$userId');
        debugPrint('✅ [EarlyGen] Generation triggered');
      } catch (e) {
        // Non-critical — generation will happen normally via loading screen
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
                    'Welcome to FitWiz!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'FitWiz Support is now your friend. Reach out anytime for help!',
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authStateProvider);
    final windowState = ref.watch(windowModeProvider);
    final useFoldable = FoldableQuizScaffold.shouldUseFoldableLayout(windowState);
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    Widget errorWidget = const SizedBox.shrink();
    if (authState.status == AuthStatus.error && authState.errorMessage != null) {
      errorWidget = Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                authState.errorMessage!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.error,
                    ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn().shake();
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0A1628), AppColors.pureBlack],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFE3F2FD), Color(0xFFF5F5F5), Colors.white],
                ),
        ),
        child: SafeArea(
          child: useFoldable
              ? _buildFoldableLayout(
                  context, windowState, isDark, textPrimary, textSecondary, errorWidget)
              : _buildPhoneLayout(isDark, textPrimary, textSecondary, errorWidget),
        ),
      ),
    );
  }

  Widget _buildPhoneLayout(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Widget errorWidget,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    _buildHeader(isDark, textSecondary),
                    const Spacer(),
                    _buildMainContent(isDark, textPrimary, textSecondary),
                    const Spacer(),
                    _buildSignInButtons(isDark),
                    errorWidget,
                    const SizedBox(height: 24),
                    _buildTermsText(textSecondary),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFoldableLayout(
    BuildContext context,
    WindowModeState windowState,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Widget errorWidget,
  ) {
    final hingeBounds = windowState.hingeBounds;
    final safeLeft = MediaQuery.of(context).padding.left;
    final rawHingeLeft = hingeBounds?.left ?? MediaQuery.of(context).size.width / 2;
    final hingeLeft = (rawHingeLeft - safeLeft).clamp(100.0, double.infinity);
    final hingeWidth = hingeBounds?.width ?? 0;

    return Column(
      children: [
        // Header spans full width
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _buildHeader(isDark, textSecondary),
        ),
        Expanded(
          child: Row(
            children: [
              // Left pane: branding + value proposition
              SizedBox(
                width: hingeLeft,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: _buildMainContent(isDark, textPrimary, textSecondary),
                  ),
                ),
              ),
              // Hinge gap
              SizedBox(width: hingeWidth),
              // Right pane: sign-in buttons
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSignInButtons(isDark),
                        errorWidget,
                        const SizedBox(height: 24),
                        _buildTermsText(textSecondary),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(bool isDark, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.go('/pre-auth-quiz'),
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              color: textSecondary,
              size: 20,
            ),
          ),
          const Spacer(),
          // Progress indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.orange : AppColorsLight.orange).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: (isDark ? AppColors.orange : AppColorsLight.orange).withOpacity(0.3)),
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
                          color: isDark ? AppColors.glassSurface : AppColorsLight.glassSurface,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: 0.9, // 90% complete
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [AppColors.orange, AppColors.orangeLight]
                                  : [AppColorsLight.orange, AppColorsLight.orangeLight],
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
                  '90%',
                  style: TextStyle(
                    color: isDark ? AppColors.orange : AppColorsLight.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildMainContent(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    final quizData = ref.watch(preAuthQuizProvider);
    return Column(
      children: [
        // Animated AI icon
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (_pulseController.value * 0.05),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.teal,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.teal.withOpacity(0.3 + _pulseController.value * 0.1),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.asset(
                    'assets/images/app_icon.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.fitness_center,
                      color: Colors.white,
                      size: 48,
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
          'Almost There!',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 300.ms),

        const SizedBox(height: 12),

        // Subtitle
        Text(
          'Sign in to save your personalized plan and start your fitness journey',
          style: TextStyle(
            fontSize: 16,
            color: textSecondary,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 400.ms),

        const SizedBox(height: 32),

        // Value reminder card
        _buildValueReminderCard(isDark, quizData, textPrimary, textSecondary)
            .animate()
            .fadeIn(delay: 500.ms)
            .slideY(begin: 0.1),
      ],
    );
  }

  Widget _buildValueReminderCard(
    bool isDark,
    PreAuthQuizData quizData,
    Color textPrimary,
    Color textSecondary,
  ) {
    final cardColor = isDark ? AppColors.elevated : Colors.white;
    final borderColor = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    String goalDisplay = _formatGoal(quizData.goal ?? 'build_muscle');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.orange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: AppColors.orange,
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
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${quizData.daysPerWeek ?? 3} days/week • Personalized for you',
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
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
        ],
      ),
    );
  }

  Widget _buildSignInButtons(bool isDark) {
    return Column(
      children: [
        // Google Sign In button (primary)
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _signInWithGoogle,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              elevation: isDark ? 0 : 2,
              disabledBackgroundColor: Colors.white.withOpacity(0.6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(27),
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
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black54),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _loadingMessage ?? 'Signing in...',
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
                      const Text(
                        'Continue with Google',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
          ),
        ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),

        const SizedBox(height: 16),

        // Email Sign In link
        TextButton(
          onPressed: _isLoading ? null : () => context.push('/email-sign-in'),
          child: Text(
            'Sign in with Email',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
            ),
          ),
        ).animate().fadeIn(delay: 800.ms),
      ],
    );
  }

  Widget _buildTermsText(Color textSecondary) {
    return Text(
      'By continuing, you agree to our Terms of Service and Privacy Policy',
      style: TextStyle(
        fontSize: 12,
        color: textSecondary,
        height: 1.4,
      ),
      textAlign: TextAlign.center,
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
