import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/repositories/auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;
  String? _loadingMessage;
  final List<String> _loadingMessages = [
    'Connecting to server...',
    'Waking up backend (cold start)...',
    'Almost there...',
    'Verifying credentials...',
  ];

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = _loadingMessages[0];
    });

    // Cycle through loading messages for long waits (Render cold start)
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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Logo and branding
              _buildBranding(),

              const Spacer(flex: 1),

              // Features list
              _buildFeatures(),

              const Spacer(flex: 2),

              // Google Sign In button
              _buildSignInButton(),

              const SizedBox(height: 16),

              // Error message
              if (authState.status == AuthStatus.error)
                _buildErrorMessage(authState.errorMessage),

              const SizedBox(height: 24),

              // New user? Get started link
              _buildNewUserLink(),

              const SizedBox(height: 24),

              // Terms
              _buildTerms(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewUserLink() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'New here? ',
          style: TextStyle(
            color: textMuted,
            fontSize: 14,
          ),
        ),
        GestureDetector(
          onTap: () => context.go('/welcome'),
          child: Text(
            'See what we offer',
            style: TextStyle(
              color: isDark ? AppColors.cyan : AppColorsLight.cyan,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 900.ms);
  }

  Widget _buildBranding() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Column(
      children: [
        // App icon
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: AppColors.cyanGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: cyan.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(
            Icons.fitness_center,
            color: AppColors.pureBlack,
            size: 48,
          ),
        )
            .animate()
            .fadeIn(duration: 600.ms)
            .scale(begin: const Offset(0.8, 0.8), delay: 200.ms),
        const SizedBox(height: 24),

        // App name
        Text(
          'AI Fitness Coach',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ).animate().fadeIn(delay: 300.ms),

        const SizedBox(height: 8),

        // Tagline
        Text(
          'Your personalized workout companion',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: textSecondary,
              ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }

  Widget _buildFeatures() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    final features = [
      ('🎯', 'AI-Generated Workouts', 'Personalized to your goals'),
      ('💬', 'Smart Coaching', 'Chat with your AI coach anytime'),
      ('📊', 'Track Progress', 'See your fitness journey unfold'),
    ];

    return Column(
      children: features.asMap().entries.map((entry) {
        final index = entry.key;
        final (emoji, title, subtitle) = entry.value;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: glassSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: Duration(milliseconds: 500 + (index * 100)))
            .slideX(begin: -0.1, delay: Duration(milliseconds: 500 + (index * 100)));
      }).toList(),
    );
  }

  Widget _buildSignInButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // In dark mode use white button, in light mode use a slightly gray/elevated button
    final buttonColor = isDark ? Colors.white : AppColorsLight.elevated;
    final buttonTextColor = isDark ? Colors.black87 : AppColorsLight.textPrimary;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _signInWithGoogle,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: buttonTextColor,
          disabledBackgroundColor: buttonColor.withOpacity(0.5),
          elevation: isDark ? 0 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: isDark
                ? BorderSide.none
                : BorderSide(color: AppColorsLight.cardBorder, width: 1),
          ),
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
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark ? Colors.black54 : AppColorsLight.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _loadingMessage ?? 'Signing in...',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.black54 : AppColorsLight.textMuted,
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
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Continue with Google',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: buttonTextColor,
                    ),
                  ),
                ],
              ),
      ),
    ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2, delay: 800.ms);
  }

  Widget _buildErrorMessage(String? message) {
    if (message == null) return const SizedBox.shrink();

    return Container(
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
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                  ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().shake();
  }

  Widget _buildTerms() {
    return Text(
      'By continuing, you agree to our Terms of Service and Privacy Policy',
      style: Theme.of(context).textTheme.bodySmall,
      textAlign: TextAlign.center,
    ).animate().fadeIn(delay: 1000.ms);
  }
}
