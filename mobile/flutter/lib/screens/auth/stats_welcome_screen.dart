import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/language_provider.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/providers/guest_mode_provider.dart';
import '../../widgets/glass_sheet.dart';

part 'stats_welcome_screen_part_filling_dot.dart';

part 'stats_welcome_screen_ui.dart';

part 'stats_welcome_screen_ext.dart';


/// Stats welcome screen with Rootd-style social proof, language selection, and sign-in
class StatsWelcomeScreen extends ConsumerStatefulWidget {
  const StatsWelcomeScreen({super.key});

  @override
  ConsumerState<StatsWelcomeScreen> createState() => _StatsWelcomeScreenState();
}

class _StatsWelcomeScreenState extends ConsumerState<StatsWelcomeScreen>
    with SingleTickerProviderStateMixin {
  // Stats carousel
  final PageController _statsController = PageController();
  int _currentStatIndex = 0;
  Timer? _autoScrollTimer;

  // Progress animation
  late AnimationController _progressController;
  static const Duration _autoScrollDuration = Duration(seconds: 3);

  // Language selection
  Language _selectedLanguage = SupportedLanguages.english;

  // Sign-in state
  bool _showSignInButtons = false;
  bool _isSigningIn = false;
  String? _loadingMessage;
  final List<String> _loadingMessages = [
    'Connecting to server...',
    'Setting things up...',
    'Almost there...',
    'Verifying credentials...',
  ];


  // Stats data (hardcoded) - focused on proof points, no redundancy
  static const List<Map<String, dynamic>> _stats = [
    {
      'headline': '1,722',
      'subheadline': 'exercises',
      'description': 'with HD video demonstrations',
      'longDescription': 'Learn proper form with professional video tutorials for every exercise',
      'icon': Icons.play_circle_outline,
      'color': Color(0xFF00BCD4), // cyan
    },
    {
      'headline': '85%',
      'subheadline': 'of users',
      'description': 'stick to their workout plan',
      'longDescription': 'Our adaptive AI keeps you motivated and on track with personalized guidance',
      'icon': Icons.trending_up,
      'color': Color(0xFF4CAF50), // green
    },
    {
      'headline': '5',
      'subheadline': 'AI Agents',
      'description': 'personalize your fitness journey',
      'longDescription': 'From nutrition to recovery, our AI team covers every aspect of your health',
      'icon': Icons.auto_awesome,
      'color': Color(0xFF14B8A6), // teal
    },
  ];

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: _autoScrollDuration,
    );
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _goToNextStat();
      }
    });
    _startAutoScroll();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _progressController.dispose();
    _statsController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _progressController.forward(from: 0.0);
  }

  void _goToNextStat() {
    final nextIndex = (_currentStatIndex + 1) % _stats.length;
    _statsController.animateToPage(
      nextIndex,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
    // Note: Animation restart is handled by onPageChanged callback
  }

  void _pauseAutoScroll() {
    _progressController.stop();
    // Resume after 5 seconds of no interaction
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _progressController.forward();
      }
    });
  }

  void _selectLanguage(Language language) {
    HapticFeedback.lightImpact();

    if (language.isComingSoon) return;

    setState(() {
      _selectedLanguage = language;
    });
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isSigningIn = true;
      _loadingMessage = _loadingMessages[0];
    });

    int messageIndex = 0;
    final messageTimer = Stream.periodic(
      const Duration(seconds: 3),
      (_) => _loadingMessages[++messageIndex % _loadingMessages.length],
    ).listen((message) {
      if (mounted && _isSigningIn) {
        setState(() => _loadingMessage = message);
      }
    });

    try {
      await ref.read(authStateProvider.notifier).signInWithGoogle();
      // Navigation happens automatically via router redirect
    } finally {
      messageTimer.cancel();
      if (mounted) {
        setState(() {
          _isSigningIn = false;
          _loadingMessage = null;
        });
      }
    }
  }


  Future<void> _continueAsGuest() async {
    HapticFeedback.lightImpact();

    // Enter guest mode
    await ref.read(guestModeProvider.notifier).enterGuestMode();

    // Navigate to main app home (guests now get full UI access with restrictions)
    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Use ref.colors(context) to get dynamic accent color from provider
    final colors = ref.colors(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0A1628),
                    AppColors.pureBlack,
                  ],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFE3F2FD), // Light blue
                    Color(0xFFF5F5F5), // Light grey
                    Colors.white,
                  ],
                ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Scrollable content area
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),

                      // Hero claim - BIG
                      _buildHeroClaim(colors),

                      const SizedBox(height: 32),

                      // Stats carousel
                      _buildStatsCarousel(isDark, colors),
                      const SizedBox(height: 16),
                      // Long description below carousel
                      _buildStatDescription(isDark),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Bottom section: buttons (pinned to bottom)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: _buildBottomSection(isDark, colors),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCarousel(bool isDark, ThemeColors colors) {
    return SizedBox(
      height: 160,
      child: GestureDetector(
        onPanDown: (_) => _pauseAutoScroll(),
        child: PageView.builder(
          controller: _statsController,
          onPageChanged: (index) {
            setState(() => _currentStatIndex = index);
            // Reset progress animation when page changes (manual swipe or auto)
            _progressController.forward(from: 0.0);
          },
          itemCount: _stats.length,
          itemBuilder: (context, index) {
            final stat = _stats[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon with subtle background - NO borders
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: (stat['color'] as Color).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      stat['icon'] as IconData,
                      color: stat['color'] as Color,
                      size: 24,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Headline number
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        stat['headline'] as String,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: stat['color'] as Color,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        stat['subheadline'] as String,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textPrimary
                              : AppColorsLight.textPrimary,
                          height: 1,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Description
                  Text(
                    stat['description'] as String,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.textSecondary
                          : AppColorsLight.textSecondary,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomSection(bool isDark, ThemeColors colors) {
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final accentColor = colors.accent;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Get Started button (goes to pre-auth quiz) - hide when sign-in buttons shown
        if (!_showSignInButtons) ...[
          _buildGetStartedButton(isDark, colors),

          const SizedBox(height: 6),

          // "No credit card needed" directly under CTA
          Text(
            'No credit card needed',
            style: TextStyle(
              fontSize: 13,
              color: textSecondary.withOpacity(0.7),
            ),
          ),

          const SizedBox(height: 16),
        ],

        // Secondary CTAs in a horizontal row
        if (!_showSignInButtons)
          Wrap(
                alignment: WrapAlignment.center,
                spacing: 4,
                runSpacing: 0,
                children: [
                  // See Pricing link
                  TextButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      context.push('/pricing-preview');
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Full Pricing',
                      style: TextStyle(
                        fontSize: 13,
                        color: accentColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text('•', style: TextStyle(color: textSecondary, fontSize: 13)),
                  // All Features link
                  TextButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _showFeaturesBottomSheet(context, isDark);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'All Features',
                      style: TextStyle(
                        fontSize: 13,
                        color: accentColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text('•', style: TextStyle(color: textSecondary, fontSize: 13)),
                  // Language selector (small, inline)
                  TextButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _showLanguageBottomSheet(context, isDark, colors);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: Icon(Icons.language, size: 14, color: textSecondary),
                    label: Text(
                      _selectedLanguage.code.toUpperCase(),
                      style: TextStyle(
                        fontSize: 13,
                        color: textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

        // Already have account - sign in section
        if (!_showSignInButtons)
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() => _showSignInButtons = true);
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Already have an account? Sign in',
              style: TextStyle(
                fontSize: 12,
                color: textSecondary,
              ),
            ),
          ),

        // Sign-in buttons (shown when user clicks "Sign in")
        if (_showSignInButtons) ...[
          _buildSignInButtons(isDark, textSecondary, colors),
        ],
      ],
    );
  }

  Widget _buildSignInButtons(bool isDark, Color textSecondary, ThemeColors colors) {
    final authState = ref.watch(authStateProvider);
    final accentColor = colors.accent;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Google Sign In button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isSigningIn ? null : _signInWithGoogle,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              elevation: isDark ? 0 : 2,
              disabledBackgroundColor: Colors.white.withOpacity(0.6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: _isSigningIn
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black54),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _loadingMessage ?? 'Signing in...',
                        style: const TextStyle(
                          fontSize: 14,
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
                        width: 18,
                        height: 18,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.g_mobiledata,
                          size: 22,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Continue with Google',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
          ),
        ),

        // Error message
        if (authState.status == AuthStatus.error && authState.errorMessage != null)
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.error.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    authState.errorMessage!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 8),

        // Email Sign In link
        TextButton(
          onPressed: _isSigningIn ? null : () => context.push('/email-sign-in'),
          child: Text(
            'Continue with Email',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: accentColor,
            ),
          ),
        ),

        // Cancel/back to get started
        TextButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            setState(() => _showSignInButtons = false);
          },
          child: Text(
            'Back to Get Started',
            style: TextStyle(
              fontSize: 13,
              color: textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  /// Show language picker as a bottom sheet
  void _showLanguageBottomSheet(BuildContext context, bool isDark, ThemeColors colors) {
    final cardColor = isDark ? AppColors.elevated : Colors.white;
    final borderColor = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final accentColor = colors.accent;

    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => GlassSheet(
        maxHeightFraction: 0.6,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.language, color: accentColor, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Select Language',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: textSecondary),
                  ),
                ],
              ),
            ),
            Divider(color: borderColor, height: 1),
            // Language list
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: SupportedLanguages.all.length,
                itemBuilder: (context, index) {
                  final language = SupportedLanguages.all[index];
                  final isSelected = language == _selectedLanguage;

                  return InkWell(
                    onTap: () {
                      _selectLanguage(language);
                      Navigator.pop(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? accentColor.withOpacity(0.15)
                                  : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                language.code.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: isSelected ? accentColor : textSecondary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      language.name,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                        color: isSelected ? accentColor : textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                if (language.nativeName != language.name)
                                  Text(
                                    language.nativeName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle, color: accentColor, size: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

}
