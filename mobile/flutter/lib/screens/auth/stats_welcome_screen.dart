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

  /// Hero claim - the main selling point, BIG and bold
  Widget _buildHeroClaim(ThemeColors colors) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Column(
      children: [
        // Main claim - one line, BIG type
        Text(
          'Your AI Fitness Coach',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w900,
            color: colors.accent,
            height: 1.1,
            letterSpacing: -1,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 12),

        // Supporting tagline
        Text(
          'AI-powered workouts tailored to you',
          style: TextStyle(
            fontSize: 16,
            color: colors.textSecondary,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 20),

        // Micro-benefits (Fitbod-style)
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: [
            _buildMicroBenefit('Adapts to your equipment', Icons.fitness_center, textSecondary),
            _buildMicroBenefit('Progressive overload built-in', Icons.trending_up, textSecondary),
            _buildMicroBenefit('Rest timer + tracking', Icons.timer, textSecondary),
          ],
        ),
      ],
    );
  }

  Widget _buildMicroBenefit(String text, IconData icon, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: textColor.withOpacity(0.7)),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: textColor.withOpacity(0.8),
            height: 1.2,
          ),
        ),
      ],
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

  Widget _buildStatDescription(bool isDark) {
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final longDesc = _stats[_currentStatIndex]['longDescription'] as String;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          longDesc,
          key: ValueKey(_currentStatIndex),
          style: TextStyle(
            fontSize: 13,
            color: textSecondary,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }


  /// Show a bottom sheet with tier-by-tier feature comparison
  void _showFeaturesBottomSheet(BuildContext context, bool isDark) {
    final cardColor = isDark ? AppColors.elevated : Colors.white;
    final borderColor = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => GlassSheet(
        showHandle: false,
        child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.compare_arrows, color: AppColors.cyan, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Compare Plans',
                      style: TextStyle(
                        fontSize: 20,
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
              // Tier header row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.glassSurface.withOpacity(0.3)
                      : AppColorsLight.glassSurface,
                ),
                child: Row(
                  children: [
                    const Expanded(flex: 3, child: SizedBox()),
                    _TierHeaderCell(name: 'Free', color: AppColors.teal, isDark: isDark),
                    _TierHeaderCell(name: 'Premium', color: AppColors.cyan, isDark: isDark),
                    _TierHeaderCell(name: 'Plus', color: AppColors.purple, isDark: isDark),
                    _TierHeaderCell(name: 'Lifetime', color: const Color(0xFFFFB800), isDark: isDark),
                  ],
                ),
              ),
              // Features list
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _FeatureRow(
                      feature: 'Workout Generation',
                      values: ['4/mo', 'Daily', '∞', '∞'],
                      isDark: isDark,
                    ),
                    _FeatureRow(
                      feature: 'Food Photo Scans',
                      values: ['—', '5/day', '10/day', '10/day'],
                      isDark: isDark,
                    ),
                    _FeatureRow(
                      feature: 'Nutrition Tracking',
                      values: ['—', 'Full', 'Full', 'Full'],
                      isDark: isDark,
                    ),
                    _FeatureRow(
                      feature: 'Exercise Library',
                      values: ['50', '1,700+', '1,700+', '1,700+'],
                      isDark: isDark,
                    ),
                    _FeatureRow(
                      feature: 'Macro Tracking',
                      values: ['Calories', 'Full', 'Full', 'Full'],
                      isDark: isDark,
                    ),
                    _FeatureRow(
                      feature: 'PR Tracking',
                      values: ['—', '✓', '✓', '✓'],
                      isDark: isDark,
                    ),
                    _FeatureRow(
                      feature: 'Favorite Workouts',
                      values: ['3', '5', '∞', '∞'],
                      isDark: isDark,
                    ),
                    _FeatureRow(
                      feature: 'Edit Workouts',
                      values: ['—', '✓', '✓', '✓'],
                      isDark: isDark,
                    ),
                    _FeatureRow(
                      feature: 'Shareable Links',
                      values: ['—', '—', '✓', '✓'],
                      isDark: isDark,
                    ),
                    _FeatureRow(
                      feature: 'Leaderboards',
                      values: ['—', '—', '✓', '✓'],
                      isDark: isDark,
                    ),
                    _FeatureRow(
                      feature: 'Priority Support',
                      values: ['—', '—', '✓', '✓'],
                      isDark: isDark,
                    ),
                    _FeatureRow(
                      feature: 'Advanced Analytics',
                      values: ['—', '✓', '✓', '✓'],
                      isDark: isDark,
                    ),
                    _FeatureRow(
                      feature: 'Ads',
                      values: ['Yes', 'No', 'No', 'No'],
                      isDark: isDark,
                      isNegative: true,
                    ),
                    const SizedBox(height: 16),
                    // Pricing summary
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.cyan.withOpacity(0.1),
                            AppColors.purple.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Monthly Pricing',
                            style: TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _PriceSummaryChip(price: '\$0', label: 'Free', color: AppColors.teal),
                              _PriceSummaryChip(price: '\$4', label: 'Premium', color: AppColors.cyan),
                              _PriceSummaryChip(price: '\$6.67', label: 'Plus', color: AppColors.purple),
                              _PriceSummaryChip(price: '\$99.99', label: 'Once', color: const Color(0xFFFFB800)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show a bottom sheet with features for a specific tier
  void _showTierFeaturesSheet(BuildContext context, bool isDark, String tierName, Color accentColor) {
    final cardColor = isDark ? AppColors.elevated : Colors.white;
    final borderColor = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    // Define features for each tier
    final Map<String, List<Map<String, dynamic>>> tierFeatures = {
      'Free': [
        {'feature': 'Workout Generation', 'value': '4/month', 'included': true},
        {'feature': 'Exercise Library', 'value': '50 exercises', 'included': true},
        {'feature': 'Streak Tracking', 'value': '✓', 'included': true},
        {'feature': 'Fasting Tracker', 'value': '✓', 'included': true},
        {'feature': 'Saved Workouts', 'value': '3 max', 'included': true},
        {'feature': 'Basic Progress', 'value': '7 days', 'included': true},
        {'feature': 'Food Photo Scans', 'value': '—', 'included': false},
        {'feature': 'Nutrition Tracking', 'value': '—', 'included': false},
        {'feature': 'PR Tracking', 'value': '—', 'included': false},
        {'feature': 'Ads', 'value': 'Yes', 'included': false, 'isNegative': true},
      ],
      'Premium': [
        {'feature': 'Workout Generation', 'value': 'Daily', 'included': true},
        {'feature': 'Exercise Library', 'value': '1,700+', 'included': true},
        {'feature': 'Food Photo Scans', 'value': '5/day', 'included': true},
        {'feature': 'Full Nutrition Tracking', 'value': '✓', 'included': true},
        {'feature': 'Full Macro Tracking', 'value': '✓', 'included': true},
        {'feature': 'PR Tracking', 'value': '✓', 'included': true},
        {'feature': 'Edit Workouts', 'value': '✓', 'included': true},
        {'feature': 'Saved Workouts', 'value': '5', 'included': true},
        {'feature': 'Advanced Analytics', 'value': '✓', 'included': true},
        {'feature': 'Ad-Free', 'value': '✓', 'included': true},
        {'feature': '7-day Free Trial', 'value': '✓', 'included': true},
      ],
      'Premium Plus': [
        {'feature': 'Workout Generation', 'value': 'Unlimited', 'included': true},
        {'feature': 'Exercise Library', 'value': '1,700+', 'included': true},
        {'feature': 'Food Photo Scans', 'value': '10/day', 'included': true},
        {'feature': 'Full Nutrition Tracking', 'value': '✓', 'included': true},
        {'feature': 'Full Macro Tracking', 'value': '✓', 'included': true},
        {'feature': 'PR Tracking', 'value': '✓', 'included': true},
        {'feature': 'Edit Workouts', 'value': '✓', 'included': true},
        {'feature': 'Saved Workouts', 'value': 'Unlimited', 'included': true},
        {'feature': 'Advanced Analytics', 'value': '✓', 'included': true},
        {'feature': 'Shareable Links', 'value': '✓', 'included': true},
        {'feature': 'Leaderboards', 'value': '✓', 'included': true},
        {'feature': 'Priority Support', 'value': '✓', 'included': true},
        {'feature': 'Ad-Free', 'value': '✓', 'included': true},
      ],
      'Lifetime': [
        {'feature': 'Everything in Premium Plus', 'value': '✓', 'included': true},
        {'feature': 'One-Time Payment', 'value': '\$99.99', 'included': true},
        {'feature': 'Lifetime Updates', 'value': '✓', 'included': true},
        {'feature': 'Early Access Features', 'value': '✓', 'included': true},
        {'feature': 'No Recurring Charges', 'value': 'Ever', 'included': true},
        {'feature': 'Best Value', 'value': '~14 months', 'included': true},
      ],
    };

    final features = tierFeatures[tierName] ?? [];

    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => GlassSheet(
        maxHeightFraction: 0.7,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      tierName == 'Free' ? Icons.person_outline :
                      tierName == 'Premium' ? Icons.workspace_premium :
                      tierName == 'Premium Plus' ? Icons.diamond_outlined :
                      Icons.all_inclusive,
                      color: accentColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$tierName Features',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          tierName == 'Free' ? '\$0/forever' :
                          tierName == 'Premium' ? '\$4/mo (yearly)' :
                          tierName == 'Premium Plus' ? '\$6.67/mo (yearly)' :
                          '\$99.99 one-time',
                          style: TextStyle(
                            fontSize: 13,
                            color: accentColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: textSecondary),
                  ),
                ],
              ),
            ),
            Divider(color: borderColor, height: 1),
            // Features list
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: features.length,
                itemBuilder: (context, index) {
                  final feature = features[index];
                  final isIncluded = feature['included'] as bool;
                  final isNegative = feature['isNegative'] ?? false;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isNegative
                                ? Colors.red.withValues(alpha: 0.15)
                                : isIncluded
                                    ? accentColor.withValues(alpha: 0.15)
                                    : Colors.grey.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isNegative
                                ? Icons.remove
                                : isIncluded
                                    ? Icons.check
                                    : Icons.close,
                            size: 14,
                            color: isNegative
                                ? Colors.red
                                : isIncluded
                                    ? accentColor
                                    : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            feature['feature'] as String,
                            style: TextStyle(
                              color: isIncluded ? textPrimary : textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          feature['value'] as String,
                          style: TextStyle(
                            color: isNegative
                                ? Colors.red
                                : isIncluded
                                    ? accentColor
                                    : textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Compare all button
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showFeaturesBottomSheet(context, isDark);
                },
                child: Text(
                  'Compare All Plans',
                  style: TextStyle(
                    color: AppColors.cyan,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
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
            'Sign in with Email',
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

  Widget _buildGetStartedButton(bool isDark, ThemeColors colors) {
    final accentColor = colors.accent;
    final accentContrast = colors.accentContrast;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          // Save selected language
          ref.read(languageProvider.notifier).setLanguage(_selectedLanguage);
          // Navigate to how it works screen (sets expectations before quiz)
          context.go('/how-it-works');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: accentContrast,
          elevation: 6,
          shadowColor: accentColor.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(27),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Get Started — Free',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: accentContrast,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, size: 20, color: accentContrast),
          ],
        ),
      ),
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

/// Custom widget for a filling progress dot
class _FillingDot extends StatelessWidget {
  final double size;
  final double fillProgress;
  final Color activeColor;
  final Color inactiveColor;
  final bool isCurrent;

  const _FillingDot({
    required this.size,
    required this.fillProgress,
    required this.activeColor,
    required this.inactiveColor,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _FillingDotPainter(
        fillProgress: fillProgress,
        activeColor: activeColor,
        inactiveColor: inactiveColor,
        isCurrent: isCurrent,
      ),
    );
  }
}

/// Custom painter for the filling dot animation
class _FillingDotPainter extends CustomPainter {
  final double fillProgress;
  final Color activeColor;
  final Color inactiveColor;
  final bool isCurrent;

  _FillingDotPainter({
    required this.fillProgress,
    required this.activeColor,
    required this.inactiveColor,
    required this.isCurrent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw inactive background circle
    final bgPaint = Paint()
      ..color = inactiveColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    if (fillProgress > 0) {
      // Draw filled portion using clip
      final fillPaint = Paint()
        ..color = activeColor
        ..style = PaintingStyle.fill;

      // Save canvas state
      canvas.save();

      // Clip to circle
      final circlePath = Path()..addOval(Rect.fromCircle(center: center, radius: radius));
      canvas.clipPath(circlePath);

      // Draw fill from left to right based on progress
      final fillWidth = size.width * fillProgress;
      final fillRect = Rect.fromLTWH(0, 0, fillWidth, size.height);
      canvas.drawRect(fillRect, fillPaint);

      // Restore canvas
      canvas.restore();

      // Add glow effect for active dots
      if (fillProgress > 0.1) {
        final glowPaint = Paint()
          ..color = activeColor.withOpacity(0.3 * fillProgress)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(center, radius, glowPaint);
      }
    }

    // Add subtle pulse effect for current dot
    if (isCurrent && fillProgress > 0) {
      final pulsePaint = Paint()
        ..color = activeColor.withOpacity(0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(center, radius + 2, pulsePaint);
    }
  }

  @override
  bool shouldRepaint(_FillingDotPainter oldDelegate) {
    return oldDelegate.fillProgress != fillProgress ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor ||
        oldDelegate.isCurrent != isCurrent;
  }
}

/// Compact tier card for the welcome screen 2x2 grid
class _CompactTierCard extends StatelessWidget {
  final String tierName;
  final String price;
  final String period;
  final String highlight;
  final Color accentColor;
  final bool isDark;
  final IconData icon;
  final bool isPopular;
  final VoidCallback? onInfoTap;

  const _CompactTierCard({
    required this.tierName,
    required this.price,
    required this.period,
    required this.highlight,
    required this.accentColor,
    required this.isDark,
    required this.icon,
    this.isPopular = false,
    this.onInfoTap,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: accentColor.withOpacity(isPopular ? 0.4 : 0.2),
          width: isPopular ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tier name with icon and optional badge
          Row(
            children: [
              Icon(icon, size: 12, color: accentColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  tierName,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isPopular)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '★',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                    ),
                  ),
                ),
              if (onInfoTap != null) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onInfoTap,
                  child: Icon(
                    Icons.info_outline,
                    size: 14,
                    color: accentColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          // Price row
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                price,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                period,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 9,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          // Highlight text
          Text(
            highlight,
            style: TextStyle(
              color: textSecondary,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }
}

/// Feature comparison item for the summary row
class _FeatureComparisonItem extends StatelessWidget {
  final String label;
  final String free;
  final String paid;
  final bool isDark;

  const _FeatureComparisonItem({
    required this.label,
    required this.free,
    required this.paid,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final accentColor = isDark ? AppColors.accent : AppColorsLight.accent;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textSecondary,
            fontSize: 8,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              free,
              style: TextStyle(
                color: textSecondary,
                fontSize: 9,
              ),
            ),
            const SizedBox(width: 3),
            Icon(Icons.arrow_forward, size: 8, color: textSecondary),
            const SizedBox(width: 3),
            Text(
              paid,
              style: TextStyle(
                color: accentColor,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Tier header cell for the features comparison bottom sheet
class _TierHeaderCell extends StatelessWidget {
  final String name;
  final Color color;
  final bool isDark;

  const _TierHeaderCell({
    required this.name,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          name,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Feature row for the comparison table
class _FeatureRow extends StatelessWidget {
  final String feature;
  final List<String> values; // [Free, Premium, Plus, Lifetime]
  final bool isDark;
  final bool isNegative;

  const _FeatureRow({
    required this.feature,
    required this.values,
    required this.isDark,
    this.isNegative = false,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final borderColor = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final tierColors = [
      AppColors.teal,
      AppColors.cyan,
      AppColors.purple,
      const Color(0xFFFFB800),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: borderColor.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              feature,
              style: TextStyle(
                color: textPrimary,
                fontSize: 12,
              ),
            ),
          ),
          ...List.generate(values.length, (index) {
            final value = values[index];
            final isCheck = value == '✓';
            final isDash = value == '—';
            final isNo = value == 'No';
            final isYes = value == 'Yes' && isNegative;

            Color valueColor;
            if (isCheck) {
              valueColor = tierColors[index];
            } else if (isDash || (isYes && isNegative)) {
              valueColor = textSecondary.withOpacity(0.5);
            } else if (isNo && isNegative) {
              valueColor = tierColors[index];
            } else {
              valueColor = textSecondary;
            }

            return Expanded(
              flex: 2,
              child: Text(
                isCheck ? '✓' : value,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 10,
                  fontWeight: isCheck || (isNo && isNegative) ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Price summary chip for bottom sheet footer
class _PriceSummaryChip extends StatelessWidget {
  final String price;
  final String label;
  final Color color;

  const _PriceSummaryChip({
    required this.price,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          price,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.7),
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}
