import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/language_provider.dart';

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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isDropdownOpen = false;


  // Stats data (hardcoded)
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
    {
      'headline': '<3s',
      'subheadline': 'workout generation',
      'description': 'AI-powered instant planning',
      'longDescription': 'Get custom workout plans tailored to your goals, equipment, and schedule',
      'icon': Icons.bolt,
      'color': Color(0xFFFF9800), // orange
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
    _searchController.dispose();
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

  List<Language> get _filteredLanguages {
    if (_searchQuery.isEmpty) {
      return SupportedLanguages.all;
    }
    return SupportedLanguages.all.where((lang) {
      final query = _searchQuery.toLowerCase();
      return lang.name.toLowerCase().contains(query) ||
          lang.nativeName.toLowerCase().contains(query) ||
          lang.code.toLowerCase().contains(query);
    }).toList();
  }

  void _selectLanguage(Language language) {
    HapticFeedback.lightImpact();

    if (language.isComingSoon) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${language.name} support coming soon!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.teal,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _selectedLanguage = language;
      _isDropdownOpen = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                          const SizedBox(height: 20),

                          // Progress dots (individual fillable)
                          _buildProgressDots(isDark),

                          const SizedBox(height: 24),

                          // App branding (smaller)
                          _buildBranding(isDark),

                          const SizedBox(height: 24),

                          // Stats carousel - takes remaining space
                          Expanded(
                            child: Column(
                              children: [
                                Expanded(child: _buildStatsCarousel(isDark)),
                                const SizedBox(height: 12),
                                // Long description below carousel
                                _buildStatDescription(isDark),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Bottom section: Language + buttons (fixed at bottom)
                          _buildBottomSection(isDark),

                          const SizedBox(height: 16),
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
    );
  }

  Widget _buildProgressDots(bool isDark) {
    return AnimatedBuilder(
      animation: _progressController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_stats.length, (index) {
            final isPast = index < _currentStatIndex;
            final isCurrent = index == _currentStatIndex;

            // Gradient colors based on position
            final activeColor = Color.lerp(
              AppColors.cyan,
              AppColors.teal,
              index / (_stats.length - 1),
            )!;
            final inactiveColor = isDark ? Colors.white12 : Colors.black12;

            // For past dots: fully filled
            // For current dot: filling based on animation progress
            // For future dots: empty
            double fillProgress = 0.0;
            if (isPast) {
              fillProgress = 1.0;
            } else if (isCurrent) {
              fillProgress = _progressController.value;
            }

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              child: _FillingDot(
                size: isCurrent ? 14 : 10,
                fillProgress: fillProgress,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                isCurrent: isCurrent,
              ),
            );
          }),
        );
      },
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildBranding(bool isDark) {
    return Column(
      children: [
        // App icon - using actual app icon image
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.teal,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.teal.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/images/app_icon.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.fitness_center,
                color: AppColors.pureBlack,
                size: 40,
              ),
            ),
          ),
        ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.8, 0.8)),

        const SizedBox(height: 16),

        // App name - single teal color instead of gradient
        Text(
          'AI Fitness Coach',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.teal,
              ),
        ).animate().fadeIn(delay: 200.ms),
      ],
    );
  }

  Widget _buildStatsCarousel(bool isDark) {
    final cardColor = isDark ? AppColors.elevated : Colors.white;
    final borderColor = isDark
        ? AppColors.cardBorder.withOpacity(0.3)
        : AppColors.cyan.withOpacity(0.2);

    return Center(
      child: SizedBox(
        height: 200,
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
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: (stat['color'] as Color).withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 0,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: (stat['color'] as Color).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          stat['icon'] as IconData,
                          color: stat['color'] as Color,
                          size: 28,
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
                              fontWeight: FontWeight.bold,
                              color: stat['color'] as Color,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            stat['subheadline'] as String,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textPrimary
                                  : AppColorsLight.textPrimary,
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
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.1),
            );
          },
        ),
        ),
      ),
    );
  }

  Widget _buildStatDescription(bool isDark) {
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final longDesc = _stats[_currentStatIndex]['longDescription'] as String;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(
        longDesc,
        key: ValueKey(_currentStatIndex),
        style: TextStyle(
          fontSize: 14,
          color: textSecondary,
          height: 1.4,
        ),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildBottomSection(bool isDark) {
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final elevated = isDark ? AppColors.elevated : Colors.white;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Language selector (compact dropdown button that opens upward)
        _buildCompactLanguageSelector(isDark, cardBorder, elevated, textSecondary),

        const SizedBox(height: 20),

        // Get Started button (goes to pre-auth quiz)
        _buildGetStartedButton(isDark),

        const SizedBox(height: 12),

        // Already have account - sign in link
        TextButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            context.go('/sign-in');
          },
          child: Text(
            'Already have an account? Sign in',
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
            ),
          ),
        ).animate().fadeIn(delay: 700.ms),
      ],
    );
  }

  Widget _buildGetStartedButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          // Save selected language
          ref.read(languageProvider.notifier).setLanguage(_selectedLanguage);
          // Navigate to pre-auth quiz
          context.go('/pre-auth-quiz');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.cyan,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: AppColors.cyan.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Get Started',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, size: 20),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1);
  }

  Widget _buildCompactLanguageSelector(
    bool isDark,
    Color cardBorder,
    Color elevated,
    Color textSecondary,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Language dropdown button
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _isDropdownOpen = !_isDropdownOpen);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: elevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isDropdownOpen ? AppColors.cyan : cardBorder,
                width: _isDropdownOpen ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      _selectedLanguage.code.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        color: AppColors.cyan,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _selectedLanguage.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 200),
                  turns: _isDropdownOpen ? 0.5 : 0,
                  child: Icon(
                    Icons.keyboard_arrow_up,
                    color: textSecondary,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 500.ms),

        // Dropdown options (opens upward with overlay)
        if (_isDropdownOpen)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            constraints: const BoxConstraints(maxHeight: 180),
            decoration: BoxDecoration(
              color: elevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search field
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(() => _searchQuery = value),
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          prefixIcon: const Icon(Icons.search, size: 18),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? AppColors.glassSurface
                              : AppColorsLight.glassSurface,
                        ),
                      ),
                    ),
                    // Language list
                    ..._filteredLanguages.map((language) {
                      final isSelected = language == _selectedLanguage;
                      return InkWell(
                        onTap: () => _selectLanguage(language),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.cyan.withOpacity(0.1)
                                : Colors.transparent,
                            border: Border(
                              top: BorderSide(
                                color: cardBorder.withOpacity(0.5),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.cyan.withOpacity(0.2)
                                      : (isDark
                                          ? AppColors.glassSurface
                                          : AppColorsLight.glassSurface),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Center(
                                  child: Text(
                                    language.code.toUpperCase(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                      color: isSelected
                                          ? AppColors.cyan
                                          : textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Row(
                                  children: [
                                    Text(
                                      language.name,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? AppColors.cyan
                                            : (isDark
                                                ? AppColors.textPrimary
                                                : AppColorsLight.textPrimary),
                                      ),
                                    ),
                                    if (language.isComingSoon) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.teal.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'Soon',
                                          style: TextStyle(
                                            fontSize: 8,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.teal,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: AppColors.cyan,
                                  size: 16,
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
      ],
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
