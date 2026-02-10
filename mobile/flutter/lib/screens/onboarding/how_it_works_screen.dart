import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/window_mode_provider.dart';

/// How It Works Screen - Explains the onboarding journey before the quiz
///
/// Displayed after Stats Welcome and before Pre-Auth Quiz.
/// Shows a 3-step visual journey to set expectations.
///
/// Adapts layout for foldable devices:
///   - Closed / normal phone: single-column vertical scroll
///   - Half-opened (tabletop): header on top pane, steps + button on bottom pane
///   - Fully opened (flat): side-by-side — header left, steps right
class HowItWorksScreen extends ConsumerStatefulWidget {
  const HowItWorksScreen({super.key});

  @override
  ConsumerState<HowItWorksScreen> createState() => _HowItWorksScreenState();
}

class _HowItWorksScreenState extends ConsumerState<HowItWorksScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;

  /// Steps data with icons, titles, and descriptions
  static const List<_StepData> _steps = [
    _StepData(
      number: 1,
      icon: Icons.person_outline,
      emoji: '🎯',
      title: 'Tell us about you',
      subtitle: '2-minute personalization quiz',
      color: Color(0xFF00BCD4), // Cyan
    ),
    _StepData(
      number: 2,
      icon: Icons.auto_awesome,
      emoji: '🤖',
      title: 'AI builds your plan',
      subtitle: 'Personalized to your goals',
      color: Color(0xFF9B59B6), // Purple
    ),
    _StepData(
      number: 3,
      icon: Icons.fitness_center,
      emoji: '💪',
      title: 'Start your first workout',
      subtitle: 'Guided videos, smart progression',
      color: Color(0xFF2ECC71), // Green
    ),
  ];

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

  void _continue() {
    HapticFeedback.mediumImpact();
    context.go('/pre-auth-quiz');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    final windowState = ref.watch(windowModeProvider);
    final posture = windowState.foldablePosture;
    final hingeBounds = windowState.hingeBounds;

    return Scaffold(
      backgroundColor: isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [AppColors.pureBlack, const Color(0xFF0A0A1A)]
                : [AppColorsLight.pureWhite, const Color(0xFFF5F5FA)],
          ),
        ),
        child: SafeArea(
          child: _buildLayoutForPosture(
            posture: posture,
            hingeBounds: hingeBounds,
            isDark: isDark,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
        ),
      ),
    );
  }

  // ─── Layout router ──────────────────────────────────────────────

  /// Determine hinge orientation: true = vertical hinge (book-fold like
  /// Pixel Fold, Galaxy Fold), false = horizontal hinge (flip phone).
  bool _isVerticalHinge(Rect? hingeBounds) {
    if (hingeBounds == null) return true; // default to book-fold
    return hingeBounds.height > hingeBounds.width;
  }

  Widget _buildLayoutForPosture({
    required FoldablePosture posture,
    required Rect? hingeBounds,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    if (posture == FoldablePosture.none) {
      return _buildPhoneLayout(
        isDark: isDark,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
      );
    }

    // Foldable is at least partially open — pick layout by hinge orientation.
    final isVertical = _isVerticalHinge(hingeBounds);

    if (isVertical) {
      // Book-fold (Pixel Fold, Galaxy Fold): split left / right
      return _buildSideBySideLayout(
        hingeBounds: hingeBounds,
        isDark: isDark,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
      );
    } else {
      // Flip phone (Galaxy Flip): split top / bottom
      return _buildTopBottomLayout(
        hingeBounds: hingeBounds,
        isDark: isDark,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
      );
    }
  }

  // ─── Phone / closed layout (original) ───────────────────────────

  Widget _buildPhoneLayout({
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                _buildHeader(textPrimary, textSecondary, isDark),
                const SizedBox(height: 48),
                ..._buildStepCards(isDark),
                const SizedBox(height: 32),
                _buildSocialProof(textSecondary, isDark),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        _buildContinueButton(isDark),
      ],
    );
  }

  // ─── Side-by-side layout (vertical hinge — book-fold) ───────────
  //  Left pane: header + social proof
  //  Right pane: step cards + CTA button
  //  Used for both half-opened and flat on Pixel Fold / Galaxy Fold.

  Widget _buildSideBySideLayout({
    required Rect? hingeBounds,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final safeLeft = MediaQuery.of(context).padding.left;
    final rawHingeLeft =
        hingeBounds?.left ?? MediaQuery.of(context).size.width / 2;
    final hingeLeft = (rawHingeLeft - safeLeft).clamp(100.0, double.infinity);
    final hingeWidth = hingeBounds?.width ?? 0;

    return Row(
      children: [
        // ── Left pane (header side) ──
        SizedBox(
          width: hingeLeft,
          child: Center(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 32),
                  _buildHeader(textPrimary, textSecondary, isDark),
                  const SizedBox(height: 40),
                  _buildSocialProof(textSecondary, isDark),
                ],
              ),
            ),
          ),
        ),

        // ── Hinge gap ──
        SizedBox(width: hingeWidth),

        // ── Right pane (steps side) ──
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      ..._buildStepCards(isDark),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              _buildContinueButton(isDark),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Top-bottom layout (horizontal hinge — flip phone) ──────────
  //  Top pane: header + social proof (above hinge)
  //  Bottom pane: step cards + CTA button (below hinge)

  Widget _buildTopBottomLayout({
    required Rect? hingeBounds,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final safeTop = MediaQuery.of(context).padding.top;
    final rawHingeTop =
        hingeBounds?.top ?? MediaQuery.of(context).size.height / 2;
    final hingeTop = (rawHingeTop - safeTop).clamp(100.0, double.infinity);
    final hingeHeight = hingeBounds?.height ?? 0;

    return Column(
      children: [
        // ── Top pane (above hinge) ──
        SizedBox(
          height: hingeTop,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                _buildHeader(textPrimary, textSecondary, isDark),
                const SizedBox(height: 24),
                _buildSocialProof(textSecondary, isDark),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        // ── Hinge gap ──
        SizedBox(height: hingeHeight),

        // ── Bottom pane (below hinge) ──
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      ..._buildStepCards(isDark),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              _buildContinueButton(isDark),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Shared building blocks ─────────────────────────────────────

  List<Widget> _buildStepCards(bool isDark) {
    final cards = <Widget>[];
    for (int index = 0; index < _steps.length; index++) {
      final step = _steps[index];
      final isLast = index == _steps.length - 1;

      cards.add(
        _StepCard(
          step: step,
          isDark: isDark,
          pulseController: _pulseController,
        )
            .animate(delay: (300 + index * 200).ms)
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.1, curve: Curves.easeOutCubic),
      );

      if (!isLast) {
        cards.add(
          _buildConnector(isDark, step.color)
              .animate(delay: (500 + index * 200).ms)
              .fadeIn(duration: 300.ms)
              .scaleY(begin: 0, alignment: Alignment.topCenter),
        );
      }
    }
    return cards;
  }

  Widget _buildHeader(Color textPrimary, Color textSecondary, bool isDark) {
    return Column(
      children: [
        // App icon
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.orange, const Color(0xFFFF6B00)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.orange.withValues(
                        alpha: 0.3 + (_pulseController.value * 0.15)),
                    blurRadius: 20 + (_pulseController.value * 8),
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.rocket_launch_rounded,
                color: Colors.white,
                size: 36,
              ),
            );
          },
        ),

        const SizedBox(height: 24),

        // Title
        Text(
          "Here's how it works",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: textPrimary,
            letterSpacing: -0.5,
          ),
        ).animate().fadeIn(delay: 100.ms).slideY(begin: -0.1),

        const SizedBox(height: 8),

        // Subtitle
        Text(
          'Get your personalized workout plan in 3 simple steps',
          style: TextStyle(
            fontSize: 15,
            color: textSecondary,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 200.ms),
      ],
    );
  }

  Widget _buildConnector(bool isDark, Color color) {
    return Container(
      width: 2,
      height: 32,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.5),
            color.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  Widget _buildSocialProof(Color textSecondary, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.glassSurface.withValues(alpha: 0.5)
            : AppColorsLight.glassSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified,
            size: 18,
            color: const Color(0xFF2ECC71),
          ),
          const SizedBox(width: 10),
          Text(
            '85% of users stick to their workout plan',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
          ),
        ],
      ),
    ).animate(delay: 900.ms).fadeIn().scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildContinueButton(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: GestureDetector(
        onTap: _continue,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              width: double.infinity,
              height: 58,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.orange, const Color(0xFFFF6B00)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.orange.withValues(
                        alpha: 0.3 + (_pulseController.value * 0.15)),
                    blurRadius: 16 + (_pulseController.value * 8),
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Let's Go",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 22,
                    )
                        .animate(
                          onPlay: (controller) =>
                              controller.repeat(reverse: true),
                        )
                        .moveX(begin: 0, end: 4, duration: 600.ms),
                  ],
                ),
              ),
            );
          },
        ),
      ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.1),
    );
  }
}

/// Data class for step information
class _StepData {
  final int number;
  final IconData icon;
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;

  const _StepData({
    required this.number,
    required this.icon,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}

/// Individual step card widget
class _StepCard extends StatelessWidget {
  final _StepData step;
  final bool isDark;
  final AnimationController pulseController;

  const _StepCard({
    required this.step,
    required this.isDark,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevated : AppColorsLight.elevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: step.color.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: step.color.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Step number with icon
          AnimatedBuilder(
            animation: pulseController,
            builder: (context, child) {
              return Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      step.color.withValues(alpha: 0.2),
                      step.color.withValues(alpha: 0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: step.color.withValues(
                          alpha: 0.2 + (pulseController.value * 0.1)),
                      blurRadius: 12 + (pulseController.value * 4),
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Icon
                    Icon(
                      step.icon,
                      size: 28,
                      color: step.color,
                    ),
                    // Step number badge
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: step.color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? AppColors.elevated
                                : AppColorsLight.elevated,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${step.number}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(width: 16),

          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      step.emoji,
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        step.title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  step.subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
