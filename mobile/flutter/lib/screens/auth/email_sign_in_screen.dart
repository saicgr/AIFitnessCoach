import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
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

class _EmailSignInScreenState extends ConsumerState<EmailSignInScreen>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLoading = false;
  bool _isSignUp = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  // Set when Supabase reports "email not confirmed" so we can:
  //   1) render an explicit "I've verified — continue" CTA, and
  //   2) silently retry sign-in when the app returns to the
  //      foreground (user likely just tapped the verification link
  //      in their email client and is back in our app).
  bool _awaitingEmailConfirm = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Defensive: if a stale snackbar from a previous mount of this
    // screen is still queued in ScaffoldMessenger (hot-reload doesn't
    // drain that queue), kill it as soon as the screen mounts so it
    // can never reappear.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }
    });
    // Smart-default the auth mode: if the user just finished the
    // pre-auth quiz (substantive data present), they almost certainly
    // mean to *create* an account, not sign in to an existing one.
    // Returning users hitting this screen from settings/login won't
    // have quiz data and stay in sign-in mode.
    final quiz = ref.read(preAuthQuizProvider);
    final cameFromOnboarding = quiz.weightKg != null ||
        quiz.goalWeightKg != null ||
        quiz.daysPerWeek != null ||
        (quiz.goals != null && quiz.goals!.isNotEmpty) ||
        quiz.fitnessLevel != null;
    if (cameFromOnboarding) {
      _isSignUp = true;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When the user comes back from their email client (after tapping
    // the verification link), Supabase has now flipped
    // email_confirmed_at on the server. Quietly retry sign-in with the
    // email + password they typed so they auto-proceed without needing
    // to re-tap Create Account.
    if (state == AppLifecycleState.resumed && _awaitingEmailConfirm) {
      // Belt-and-braces: also guard here in case dispose runs between
      // the resume event and the microtask scheduling.
      if (!mounted) return;
      _retryAfterVerification();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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

    debugPrint('🔵 [Auth] Auth attempt: email=$email startingMode=${_isSignUp ? "signup" : "signin"}');

    try {
      // ── Smart auth ──────────────────────────────────────────────────
      // Cal AI / Fastic / BetterMe pattern: one button handles both
      // signup and sign-in by trying the most likely path first and
      // falling back when Supabase reports a mismatch.
      //
      //   signup mode  (default for users coming from onboarding):
      //     1) try signUp → if "already registered", flip to sign-in
      //        and try the password they just typed
      //     2) if that fails creds → message about wrong password
      //
      //   sign-in mode (returning users from settings/login):
      //     1) try signIn → if creds invalid, fall back to signUp
      //        on the assumption they're new
      //     2) if signUp says "already registered", it's a real
      //        wrong-password and we surface that
      //
      // This way returning testers (existing account, correct password)
      // get signed in cleanly, AND new users finishing onboarding get
      // an account created + verification email automatically.
      if (_isSignUp) {
        final didSignUp = await _tryEmailSignUp(email, password);
        if (!didSignUp) {
          // Supabase says the email is already registered. Try the
          // password they typed against the existing account.
          debugPrint('🟡 [Auth] Email exists — trying sign-in with same password');
          await ref.read(authStateProvider.notifier).signInWithEmail(
                email,
                password,
              );
        }
      } else {
        await ref.read(authStateProvider.notifier).signInWithEmail(
              email,
              password,
            );
        final auth1 = ref.read(authStateProvider);
        final isCredsErr = auth1.status == AuthStatus.error &&
            _looksLikeCredentialsError(auth1.errorMessage ?? '');
        if (isCredsErr) {
          // Could be wrong password OR no account. Try signup —
          // if the email is unregistered, a new account is created
          // (and Supabase sends the verify email). If it IS
          // registered, signUp will throw "already registered" and
          // we surface a wrong-password message.
          debugPrint('🟡 [Auth] Sign-in creds invalid — trying signup');
          final didSignUp = await _tryEmailSignUp(email, password);
          if (!didSignUp) {
            if (mounted) {
              setState(() {
                _errorMessage =
                    "An account exists for that email but the password "
                    "doesn't match. Tap Forgot Password to reset.";
              });
            }
            return;
          }
        }
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
        debugPrint('🔴 [Auth] Auth returned error state: $raw');
        if (mounted) {
          setState(() {
            _errorMessage = friendly;
            _awaitingEmailConfirm = _looksLikeNeedsConfirm(raw);
          });
        }
        return;
      }

      // Cleared on success — leaving the verification UI showing
      // after a successful sign-in would be confusing.
      _awaitingEmailConfirm = false;

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
          setState(() {
            _awaitingEmailConfirm = true;
          });
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

  /// Calls signUpWithEmail, forwarding pre-auth quiz answers as Supabase
  /// user_metadata so the welcome email + Supabase confirm template can
  /// personalize from day zero. Returns `true` if a new account was
  /// created (Supabase will have sent a verification email), `false` if
  /// Supabase reports the email is already registered (caller should
  /// fall back to sign-in). Other failures bubble up as exceptions.
  Future<bool> _tryEmailSignUp(String email, String password) async {
    final quiz = ref.read(preAuthQuizProvider);
    final formName = _nameController.text.trim();
    final resolvedName = formName.isNotEmpty ? formName : (quiz.name ?? '');
    final firstName = resolvedName.split(RegExp(r'\s+')).first;
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

    try {
      await ref.read(authStateProvider.notifier).signUpWithEmail(
            email,
            password,
            name: resolvedName.isNotEmpty ? resolvedName : null,
            quizMetadata: quizMetadata,
          );
    } catch (e) {
      // Supabase / repository may surface "User already registered" as
      // a thrown exception. Treat that as a fallback signal and let the
      // caller try sign-in instead.
      if (_looksLikeAlreadyRegistered(e.toString())) {
        return false;
      }
      rethrow;
    }

    // The notifier swallows errors into state. If signUp reported
    // "already registered" via state, that's our fallback signal too.
    final auth = ref.read(authStateProvider);
    if (auth.status == AuthStatus.error &&
        _looksLikeAlreadyRegistered(auth.errorMessage ?? '')) {
      return false;
    }

    return true;
  }

  bool _looksLikeCredentialsError(String raw) {
    final l = raw.toLowerCase();
    return l.contains('invalid login credentials') ||
        l.contains('invalid email or password') ||
        l.contains('wrong password') ||
        l.contains('email or password');
  }

  bool _looksLikeAlreadyRegistered(String raw) {
    final l = raw.toLowerCase();
    return l.contains('already registered') ||
        l.contains('already exists') ||
        l.contains('user already') ||
        l.contains('duplicate key');
  }

  /// Re-sends the Supabase signup verification email. Called from the
  /// "Resend" action on the still-not-confirmed snackbar (and from the
  /// Resend link rendered next to the green continue button). Uses the
  /// Supabase client directly because the existing AuthRepository
  /// doesn't expose a resend method and adding one would be a bigger
  /// refactor than this surface needs.
  Future<void> _resendVerificationEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    try {
      await sb.Supabase.instance.client.auth.resend(
        type: sb.OtpType.signup,
        email: email,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification email resent to $email.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      debugPrint('🔴 [Auth] Resend failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Couldn't resend right now. ${_humanizeAuthError(e.toString())}",
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  bool _looksLikeNeedsConfirm(String raw) {
    final l = raw.toLowerCase();
    return l.contains('email not confirmed') ||
        l.contains('verify your account') ||
        l.contains('check your email') ||
        l.contains('confirm your email');
  }

  /// Called when the app comes back to the foreground while we're
  /// waiting on an email verification. Quietly retries sign-in with the
  /// email + password the user already typed; on success the auth
  /// state flips and GoRouter advances them to the next onboarding
  /// step automatically — no manual re-entry required.
  Future<void> _retryAfterVerification() async {
    // mounted guard BEFORE touching controllers — dispose() runs
    // _emailController.dispose() in our State; if a delayed
    // didChangeAppLifecycleState callback fires after dispose
    // (race during navigation), reading .text throws
    // "TextEditingController used after being disposed"
    // (FITWIZ-FLUTTER-5H).
    if (!mounted) return;
    if (_isLoading) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) return;

    // Drop any stale snackbars from earlier attempts so the user
    // doesn't see stacked or lingering verification toasts.
    ScaffoldMessenger.of(context).clearSnackBars();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authStateProvider.notifier).signInWithEmail(
            email,
            password,
          );
      final auth = ref.read(authStateProvider);
      if (auth.status == AuthStatus.error || auth.user == null) {
        final raw = auth.errorMessage ?? '';
        // Still not confirmed — keep the awaiting state so the next
        // resume can try again. The red pill + green button + inline
        // "Resend email" link already explain everything, so a stacked
        // snackbar on top of all that is redundant noise. Tap is still
        // acknowledged via the brief loading spinner on the button and
        // a single light haptic.
        if (_looksLikeNeedsConfirm(raw)) {
          if (mounted) {
            HapticFeedback.lightImpact();
            setState(() {
              _awaitingEmailConfirm = true;
              _errorMessage = _humanizeAuthError(raw);
            });
          }
          return;
        }
        if (mounted) {
          setState(() {
            _awaitingEmailConfirm = false;
            _errorMessage = _humanizeAuthError(raw);
          });
        }
        return;
      }
      // Success — clear the verification UI; GoRouter redirect will
      // handle navigation based on the now-authenticated state.
      if (mounted) {
        setState(() {
          _awaitingEmailConfirm = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _humanizeAuthError(e.toString());
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                              style: TextStyle(
                                color: t.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Email',
                                labelStyle: TextStyle(
                                  color: t.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                floatingLabelStyle: TextStyle(
                                  color: t.borderSelected,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                                hintText: 'you@example.com',
                                hintStyle: TextStyle(
                                  color: t.textMuted.withValues(alpha: 0.7),
                                  fontSize: 15,
                                ),
                                prefixIcon: Icon(Icons.email_outlined,
                                    color: t.textPrimary, size: 22),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 18),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: t.borderDefault, width: 1.5),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: t.borderSelected, width: 2.5),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: AppColors.error, width: 1.5),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: AppColors.error, width: 2.5),
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
                              style: TextStyle(
                                color: t.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: TextStyle(
                                  color: t.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                floatingLabelStyle: TextStyle(
                                  color: t.borderSelected,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                                hintText: _isSignUp
                                    ? 'At least 8 characters'
                                    : 'Enter your password',
                                hintStyle: TextStyle(
                                  color: t.textMuted.withValues(alpha: 0.7),
                                  fontSize: 15,
                                ),
                                prefixIcon: Icon(Icons.lock_outline,
                                    color: t.textPrimary, size: 22),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: t.textPrimary,
                                    size: 22,
                                  ),
                                  onPressed: () => setState(
                                      () => _obscurePassword = !_obscurePassword),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 18),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: t.borderDefault, width: 1.5),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: t.borderSelected, width: 2.5),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: AppColors.error, width: 1.5),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: AppColors.error, width: 2.5),
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
                              // Explicit recover-from-verify CTA. If the
                              // user just tapped the email link, the
                              // app-resume listener will auto-retry —
                              // but a tappable button is the belt-and-
                              // suspenders fallback so they're never
                              // stuck on this screen wondering what to
                              // do next.
                              if (_awaitingEmailConfirm) ...[
                                const SizedBox(height: 10),
                                GestureDetector(
                                  onTap: _isLoading
                                      ? null
                                      : _retryAfterVerification,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12, horizontal: 14),
                                    decoration: BoxDecoration(
                                      color: AppColors.success
                                          .withValues(alpha: 0.12),
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.success
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.mark_email_read_rounded,
                                          size: 18,
                                          color: AppColors.success,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "I've verified — continue",
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.success,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // Inline resend so users who never got
                                // the email (typo, spam folder, expired
                                // link) have a one-tap recovery without
                                // backing out and starting over.
                                Center(
                                  child: TextButton(
                                    onPressed: _isLoading
                                        ? null
                                        : _resendVerificationEmail,
                                    child: Text(
                                      "Didn't get it? Resend email",
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textSecondary,
                                        decoration:
                                            TextDecoration.underline,
                                        decorationColor:
                                            AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
