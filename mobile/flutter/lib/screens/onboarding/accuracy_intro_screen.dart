import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/posthog_service.dart';
import '../../widgets/glass_back_button.dart';
import 'widgets/did_you_know_chip.dart';
import 'package:fitwiz/core/constants/branding.dart';

/// Accuracy Trust Screen - Shows users why specific food logging matters.
///
/// Compares vague vs specific food inputs side-by-side to demonstrate
/// how precision leads to better calorie tracking accuracy.
///
/// Inserted in onboarding flow: Fitness Assessment → **this** → Health Connect Setup
class AccuracyIntroScreen extends ConsumerStatefulWidget {
  const AccuracyIntroScreen({super.key});

  @override
  ConsumerState<AccuracyIntroScreen> createState() =>
      _AccuracyIntroScreenState();
}

class _AccuracyIntroScreenState extends ConsumerState<AccuracyIntroScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;

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

    // Track accuracy intro completion
    ref.read(posthogServiceProvider).capture(
      eventName: 'onboarding_accuracy_intro_completed',
    );

    context.go('/health-connect-setup');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

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
          child: Column(
            children: [
              // Back button row
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, top: 8),
                  child: GlassBackButton(
                    onTap: () => context.go('/fitness-assessment'),
                  ),
                ),
              ),

              // Static content — fits within the viewport
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildHeader(textPrimary, textSecondary, isDark),
                      const SizedBox(height: 24),
                      _buildComparisonSection(isDark, textPrimary, textSecondary),
                      const SizedBox(height: 20),
                      _buildInsightText(textSecondary, isDark),
                      const SizedBox(height: 12),
                      DidYouKnowChip(
                        text:
                            '${Branding.appName} uses AI + 200,000+ verified foods from 100+ country cuisines, plus barcode databases',
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom CTA
              _buildContinueButton(isDark),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────

  Widget _buildHeader(Color textPrimary, Color textSecondary, bool isDark) {
    return Column(
      children: [
        // Target/bullseye icon
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
                Icons.gps_fixed_rounded,
                color: Colors.white,
                size: 36,
              ),
            );
          },
        ),

        const SizedBox(height: 24),

        Text(
          'Precise Nutrition Logging',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: textPrimary,
            letterSpacing: -0.5,
          ),
        ).animate().fadeIn(delay: 100.ms).slideY(begin: -0.1),

        const SizedBox(height: 8),

        Text(
          'The more specific you are, the more accurate your tracking',
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

  // ─── Comparison Section ────────────────────────────────────────

  Widget _buildComparisonSection(
      bool isDark, Color textPrimary, Color textSecondary) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEFT: Vague card (red-tinted)
        Expanded(
          child: _ComparisonCard(
            isDark: isDark,
            label: 'Vague',
            labelColor: const Color(0xFFEF4444),
            tintColor: const Color(0xFFEF4444),
            icon: Icons.close_rounded,
            items: const [
              _FoodItem(name: 'Pizza', calories: '285 cal'),
              _FoodItem(name: 'Salad', calories: '150 cal'),
            ],
          )
              .animate(delay: 400.ms)
              .fadeIn(duration: 500.ms)
              .slideX(begin: -0.15, curve: Curves.easeOutCubic),
        ),

        const SizedBox(width: 12),

        // RIGHT: Specific card (green-tinted)
        Expanded(
          child: _ComparisonCard(
            isDark: isDark,
            label: 'Specific',
            labelColor: const Color(0xFF22C55E),
            tintColor: const Color(0xFF22C55E),
            icon: Icons.check_rounded,
            items: const [
              _FoodItem(
                  name: "Domino's Pepperoni\n2 slices", calories: '534 cal'),
              _FoodItem(
                  name: 'Sweetgreen\nHarvest Bowl', calories: '705 cal'),
            ],
          )
              .animate(delay: 600.ms)
              .fadeIn(duration: 500.ms)
              .slideX(begin: 0.15, curve: Curves.easeOutCubic),
        ),
      ],
    );
  }

  // ─── Insight Text ──────────────────────────────────────────────

  Widget _buildInsightText(Color textSecondary, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
        children: [
          Icon(
            Icons.auto_awesome,
            size: 22,
            color: AppColors.orange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'The more specific you are, the more accurate ${Branding.appName} gets. Include brand names, portions, and restaurant names.',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    )
        .animate(delay: 800.ms)
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, curve: Curves.easeOutCubic);
  }

  // ─── Continue Button ───────────────────────────────────────────

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
                    const Text(
                      'Continue',
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
      ),
    ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.1);
  }
}

// ─── Data Model ──────────────────────────────────────────────────

class _FoodItem {
  final String name;
  final String calories;

  const _FoodItem({required this.name, required this.calories});
}

// ─── Comparison Card Widget ──────────────────────────────────────

class _ComparisonCard extends StatelessWidget {
  final bool isDark;
  final String label;
  final Color labelColor;
  final Color tintColor;
  final IconData icon;
  final List<_FoodItem> items;

  const _ComparisonCard({
    required this.isDark,
    required this.label,
    required this.labelColor,
    required this.tintColor,
    required this.icon,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevated : AppColorsLight.elevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: tintColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: tintColor.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Label badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: tintColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: labelColor),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: labelColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Food items
          ...items.map((item) => _buildFoodRow(item, textPrimary, textSecondary)),
        ],
      ),
    );
  }

  Widget _buildFoodRow(
      _FoodItem item, Color textPrimary, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          // Food name
          Text(
            item.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          // Calorie badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: tintColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              item.calories,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: tintColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
