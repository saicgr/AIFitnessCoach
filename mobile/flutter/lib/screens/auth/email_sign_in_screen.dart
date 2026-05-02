import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../onboarding/pre_auth_quiz_data.dart';
import '../onboarding/widgets/onboarding_theme.dart';
import 'widgets/pre_auth_referral_chip.dart';
import 'package:fitwiz/core/constants/branding.dart';

/// Glassmorphic email sign-in screen
class EmailSignInScreen extends ConsumerStatefulWidget {
  const EmailSignInScreen({super.key});

  @override
  ConsumerState<EmailSignInScreen> createState() => _EmailSignInScreenState();
}

class _EmailSignInScreenState extends ConsumerState<EmailSignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLoading = false;
  bool _isSignUp = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) {
      debugPrint('🔴 [Auth] Form validation failed — sign-in not attempted');
      return;
    }

    final email = _emailController.text.trim();
    // Trim only trailing whitespace from password — leading/trailing
    // accidental spaces (autocomplete on iOS adds them) shouldn't lock
    // out a returning user with valid credentials.
    final password = _passwordController.text.trim();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    debugPrint('🔵 [Auth] Sign-in attempt: email=$email isSignUp=$_isSignUp');

    try {
      if (_isSignUp) {
        // Pull pre-auth quiz answers (already collected before this screen)
        // and forward them as Supabase user_metadata. Without this the
        // welcome email + Supabase confirm template can't personalize and
        // fall back to "Welcome, there." See feedback_name_personalization_required.
        final quiz = ref.read(preAuthQuizProvider);
        final formName = _nameController.text.trim();
        final resolvedName = formName.isNotEmpty ? formName : (quiz.name ?? '');
        final firstName =
            resolvedName.split(RegExp(r'\s+')).first;
        final goalKey = (quiz.goals != null && quiz.goals!.isNotEmpty)
            ? quiz.goals!.first
            : null;
        final quizMetadata = <String, dynamic>{
          if (firstName.isNotEmpty) 'first_name': firstName,
          if (goalKey != null) 'goal': goalKey,
          if (quiz.daysPerWeek != null) 'days_per_week': quiz.daysPerWeek,
          if (quiz.weightKg != null) 'weight_kg': quiz.weightKg,
          if (quiz.goalWeightKg != null) 'goal_weight_kg': quiz.goalWeightKg,
          if (quiz.weightDirection != null)
            'weight_direction': quiz.weightDirection,
          if (quiz.fitnessLevel != null) 'fitness_level': quiz.fitnessLevel,
        };
        await ref.read(authStateProvider.notifier).signUpWithEmail(
              email,
              password,
              name: resolvedName.isNotEmpty ? resolvedName : null,
              quizMetadata: quizMetadata,
            );
      } else {
        await ref.read(authStateProvider.notifier).signInWithEmail(
              email,
              password,
            );
      }

      // CRITICAL: AuthNotifier.signInWithEmail swallows exceptions and stores
      // them in state.errorMessage instead of re-throwing. If we don't read
      // the state here, a failed sign-in silently succeeds at this layer:
      // the button stops loading, no error shows, the user sees nothing
      // happen. We have to inspect state explicitly.
      final auth = ref.read(authStateProvider);
      if (auth.status == AuthStatus.error || auth.user == null) {
        final raw = auth.errorMessage ?? 'Sign-in failed. Please try again.';
        final friendly = _humanizeAuthError(raw);
        debugPrint('🔴 [Auth] Sign-in returned error state: $raw');
        if (mounted) {
          setState(() {
            _errorMessage = friendly;
          });
        }
        return;
      }

      debugPrint('🟢 [Auth] Sign-in success: userId=${auth.user?.id}');

      final user = auth.user;
      if (user != null && user.isFirstLogin && user.hasSupportFriend && mounted) {
        _showSupportFriendWelcome();
      }
      // Founder sheet is shown on MainShell (the actual destination) — showing
      // it here would race with the GoRouter redirect and tear down under us.
    } catch (e) {
      debugPrint('🔴 [Auth] Sign-in threw exception: $e');
      final errorMsg = e.toString().replaceAll('Exception: ', '');

      if (errorMsg.contains('check your email') || errorMsg.contains('verify your account')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.mark_email_read, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Account created! Please check your email and confirm to sign in.',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.success,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 6),
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = errorMsg;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Translate raw Supabase / repository auth errors into actionable copy.
  /// Without this, users see strings like "Exception: AuthApiException(...)"
  /// or "Invalid login credentials" without context — hard to act on.
  String _humanizeAuthError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid email or password') ||
        lower.contains('wrong password')) {
      return _isSignUp
          ? 'Could not create the account. Try a different email or password.'
          : "Email or password doesn't match our records. Tap Forgot Password if you need to reset.";
    }
    if (lower.contains('email not confirmed') ||
        lower.contains('verify your account') ||
        lower.contains('check your email')) {
      return 'Please confirm your email first — check your inbox for a verification link.';
    }
    if (lower.contains('user already registered') ||
        lower.contains('already exists') ||
        lower.contains('duplicate key')) {
      return 'An account with that email already exists. Try signing in instead.';
    }
    if (lower.contains('rate limit') || lower.contains('too many requests')) {
      return 'Too many attempts. Wait a minute and try again.';
    }
    if (lower.contains('network') ||
        lower.contains('socket') ||
        lower.contains('timed out') ||
        lower.contains('connection')) {
      return "Can't reach the server. Check your connection and try again.";
    }
    if (lower.contains('weak password') ||
        lower.contains('password is too short')) {
      return 'Use a stronger password — at least 8 characters with a letter and a number.';
    }
    // Strip the most verbose decoration before showing raw text as a fallback.
    return raw
        .replaceAll('Exception: ', '')
        .replaceAll(RegExp(r'^AuthApiException\([^)]*\)\s*:?\s*'), '')
        .trim();
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

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email address first';
      });
      return;
    }

    HapticFeedback.lightImpact();
    await ref.read(authStateProvider.notifier).sendPasswordReset(email);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'If an account exists with this email, a password reset link has been sent.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = OnboardingTheme.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: t.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: OnboardingBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      // Glassmorphic back button — force readable contrast in light mode
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: t.isDark
                                    ? Colors.white.withValues(alpha: 0.10)
                                    : Colors.black.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: t.isDark
                                      ? Colors.white.withValues(alpha: 0.18)
                                      : Colors.black.withValues(alpha: 0.15),
                                ),
                              ),
                              child: Icon(Icons.arrow_back_ios_rounded, color: t.textPrimary, size: 18),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _isSignUp ? 'Create Account' : 'Sign In',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: t.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 44),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms),

                const SizedBox(height: 32),

                // Logo — glassmorphic container
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: t.cardFill,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: t.borderDefault),
                        boxShadow: [
                          BoxShadow(
                            color: t.textPrimary.withOpacity(0.1),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/images/app_icon.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.fitness_center,
                            color: t.textPrimary,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.8, 0.8)),

                const SizedBox(height: 32),

                // Form card — glassmorphic
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: t.buttonGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: t.borderDefault),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Email field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              style: TextStyle(color: t.textPrimary),
                              decoration: InputDecoration(
                                labelText: 'Email',
                                labelStyle: TextStyle(color: t.textMuted),
                                hintText: 'Enter your email',
                                hintStyle: TextStyle(color: t.textDisabled),
                                prefixIcon: Icon(Icons.email_outlined, color: t.textMuted),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: t.borderDefault),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: t.borderSelected),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.error),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.error),
                                ),
                                filled: true,
                                fillColor: t.cardFill,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Please enter your email';
                                if (!value.contains('@') || !value.contains('.')) return 'Please enter a valid email';
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Password field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: TextStyle(color: t.textPrimary),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: TextStyle(color: t.textMuted),
                                hintText: 'Enter your password',
                                hintStyle: TextStyle(color: t.textDisabled),
                                prefixIcon: Icon(Icons.lock_outline, color: t.textMuted),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    color: t.textMuted,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: t.borderDefault),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: t.borderSelected),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.error),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.error),
                                ),
                                filled: true,
                                fillColor: t.cardFill,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Please enter your password';
                                if (_isSignUp) {
                                  if (value.length < 8) return 'Password must be at least 8 characters';
                                  if (!RegExp(r'[a-zA-Z]').hasMatch(value)) return 'Password must contain at least one letter';
                                  if (!RegExp(r'[0-9]').hasMatch(value)) return 'Password must contain at least one number';
                                }
                                return null;
                              },
                            ),

                            // Forgot password
                            if (!_isSignUp) ...[
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: GestureDetector(
                                  onTap: _forgotPassword,
                                  child: Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      color: t.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],

                            // Error message
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 16),
                              Container(
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
                                        _errorMessage!,
                                        style: const TextStyle(color: AppColors.error, fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),

                            // Submit button — warm brand orange so it
                            // doesn't read as a disabled glassmorphic card
                            // on light backgrounds. Spinner stays white so
                            // it remains visible against the gradient.
                            GestureDetector(
                              onTap: _isLoading ? null : _signIn,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                height: 54,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: _isLoading
                                        ? [
                                            AppColors.orange.withValues(alpha: 0.55),
                                            const Color(0xFFFFB366).withValues(alpha: 0.55),
                                          ]
                                        : const [
                                            Color(0xFFFFB366),
                                            AppColors.orange,
                                          ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: _isLoading
                                      ? null
                                      : [
                                          BoxShadow(
                                            color: AppColors.orange
                                                .withValues(alpha: 0.35),
                                            blurRadius: 14,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                ),
                                child: Center(
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : Text(
                                          _isSignUp ? 'Create Account' : 'Sign In',
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            letterSpacing: 0.2,
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
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

                const SizedBox(height: 24),

                // Toggle sign in / sign up
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isSignUp ? 'Already have an account?' : "Don't have an account?",
                      style: TextStyle(color: t.textMuted, fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isSignUp = !_isSignUp;
                          _errorMessage = null;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        child: Text(
                          _isSignUp ? 'Sign In' : 'Sign Up',
                          style: TextStyle(
                            color: t.textPrimary.withValues(alpha: 0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 500.ms),

                // Optional: user can enter a referral code; stored pre-auth
                // and applied automatically after sign-up completes.
                if (_isSignUp) ...[
                  const SizedBox(height: 8),
                  const PreAuthReferralChip(),
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }
}
