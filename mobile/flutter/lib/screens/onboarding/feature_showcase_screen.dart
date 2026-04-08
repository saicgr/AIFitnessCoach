import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/posthog_service.dart';
import '../../widgets/glass_back_button.dart';

/// Feature Showcase onboarding screen.
///
/// Presents 3 feature cards with rich visuals: stacked photos, coded mock UIs.
/// Navigates to `/paywall-features` on completion.
class FeatureShowcaseScreen extends ConsumerWidget {
  const FeatureShowcaseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  child: GlassBackButton(
                    onTap: () => context.go('/health-connect-setup'),
                  ),
                ).animate().fadeIn(duration: 300.ms),

                // Header
                Text(
                  'What you can do',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                ).animate().fadeIn(delay: 100.ms).slideY(begin: -0.1),
                const SizedBox(height: 4),
                Text(
                  'Powerful tools to reach your goals faster',
                  style: TextStyle(fontSize: 15, color: textSecondary),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 20),

                // Feature cards
                Expanded(
                  child: Column(
                    children: [
                      // 1. Snap & Log — stacked squircle photos
                      Expanded(
                        child: _SnapAndLogCard(isDark: isDark),
                      ),
                      const SizedBox(height: 12),
                      // 2. Barcode Scan — coded mock UI
                      Expanded(
                        child: _BarcodeScanCard(isDark: isDark),
                      ),
                      const SizedBox(height: 12),
                      // 3. AI Workouts — coded mock UI
                      Expanded(
                        child: _AIWorkoutsCard(isDark: isDark),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // CTA button
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    ref.read(posthogServiceProvider).capture(
                      eventName: 'onboarding_feature_showcase_completed',
                    );
                    context.go('/paywall-features');
                  },
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.orange, Color(0xFFEA580C)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.orange.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Get Started',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(width: 10),
                          Icon(Icons.arrow_forward_rounded,
                              color: Colors.white, size: 22),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CARD 1: SNAP & LOG — Stacked squircle photos
// ═══════════════════════════════════════════════════════════════════════════════

class _SnapAndLogCard extends StatelessWidget {
  final bool isDark;
  const _SnapAndLogCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00BCD4).withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00BCD4).withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Stacked squircle photos
          SizedBox(
            width: 100,
            height: double.infinity,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Back photo (food) — rotated slightly, offset up-left
                Positioned(
                  left: 0,
                  top: 0,
                  child: Transform.rotate(
                    angle: -0.08,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.9),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Image.asset(
                          'assets/images/showcase_food.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 400.ms)
                    .slideX(begin: -0.2),

                // Front photo (result) — rotated slightly opposite, offset down-right
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Transform.rotate(
                    angle: 0.06,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.9),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Image.asset(
                          'assets/images/showcase_result.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 450.ms, duration: 400.ms)
                    .slideX(begin: 0.2),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Text(
                      'Snap & Log',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00BCD4).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Most Popular',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF00BCD4),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Photo your meal, get instant nutrition breakdown.',
                  style: TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.05);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CARD 2: BARCODE SCAN — Coded mock viewfinder UI
// ═══════════════════════════════════════════════════════════════════════════════

class _BarcodeScanCard extends StatelessWidget {
  final bool isDark;
  const _BarcodeScanCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    const featureColor = Color(0xFF9B59B6);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: featureColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: featureColor.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Mini barcode scanner mockup
          SizedBox(
            width: 100,
            child: Center(
              child: _BarcodeMockup(isDark: isDark),
            ),
          ),
          const SizedBox(width: 14),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Text(
                      'Barcode Scan',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: featureColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Zero Typing',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: featureColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Scan any product for precise nutrition data.',
                  style: TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.05);
  }
}

class _BarcodeMockup extends StatelessWidget {
  final bool isDark;
  const _BarcodeMockup({required this.isDark});

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF9B59B6);

    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.4)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        children: [
          // Corner brackets (viewfinder)
          ..._buildCornerBrackets(purple),

          // Barcode lines in center
          Center(
            child: SizedBox(
              width: 48,
              height: 36,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(12, (i) {
                  final widths = [2.0, 1.0, 3.0, 1.0, 2.0, 1.5, 2.5, 1.0, 2.0, 1.5, 1.0, 2.0];
                  return Container(
                    width: widths[i],
                    height: 36,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.7)
                        : Colors.black.withValues(alpha: 0.7),
                  );
                }),
              ),
            ),
          ),

          // Scan line (animated)
          Center(
            child: Container(
              width: 56,
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    purple.withValues(alpha: 0.0),
                    purple,
                    purple.withValues(alpha: 0.0),
                  ],
                ),
                borderRadius: BorderRadius.circular(1),
                boxShadow: [
                  BoxShadow(
                    color: purple.withValues(alpha: 0.5),
                    blurRadius: 6,
                  ),
                ],
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .slideY(
                  begin: -0.8,
                  end: 0.8,
                  duration: 1500.ms,
                  curve: Curves.easeInOut,
                ),
          ),

          // Small nutrition result pill at bottom
          Positioned(
            bottom: 4,
            left: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: purple.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 8, color: purple),
                  const SizedBox(width: 3),
                  Text(
                    '120 kcal',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: purple,
                    ),
                  ),
                ],
              ),
            ),
          )
              .animate()
              .fadeIn(delay: 800.ms, duration: 400.ms),
        ],
      ),
    );
  }

  List<Widget> _buildCornerBrackets(Color color) {
    const size = 14.0;
    const thickness = 2.5;
    const offset = 6.0;

    Widget bracket(Alignment alignment) {
      final isTop = alignment == Alignment.topLeft || alignment == Alignment.topRight;
      final isLeft = alignment == Alignment.topLeft || alignment == Alignment.bottomLeft;

      return Positioned(
        top: isTop ? offset : null,
        bottom: !isTop ? offset : null,
        left: isLeft ? offset : null,
        right: !isLeft ? offset : null,
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _CornerPainter(
              color: color,
              thickness: thickness,
              isTop: isTop,
              isLeft: isLeft,
            ),
          ),
        ),
      );
    }

    return [
      bracket(Alignment.topLeft),
      bracket(Alignment.topRight),
      bracket(Alignment.bottomLeft),
      bracket(Alignment.bottomRight),
    ];
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double thickness;
  final bool isTop;
  final bool isLeft;

  _CornerPainter({
    required this.color,
    required this.thickness,
    required this.isTop,
    required this.isLeft,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (isTop && isLeft) {
      path.moveTo(0, size.height);
      path.lineTo(0, 0);
      path.lineTo(size.width, 0);
    } else if (isTop && !isLeft) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else if (!isTop && isLeft) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, 0);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════════════════
// CARD 3: AI WORKOUTS — Coded mock workout plan
// ═══════════════════════════════════════════════════════════════════════════════

class _AIWorkoutsCard extends StatelessWidget {
  final bool isDark;
  const _AIWorkoutsCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    const featureColor = Color(0xFF2ECC71);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: featureColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: featureColor.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Mini workout plan mockup
          SizedBox(
            width: 100,
            child: Center(
              child: _WorkoutMockup(isDark: isDark),
            ),
          ),
          const SizedBox(width: 14),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Text(
                      'AI Workouts',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: featureColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Personalized',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: featureColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Plans built for your goals, equipment & schedule.',
                  style: TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.05);
  }
}

class _WorkoutMockup extends StatelessWidget {
  final bool isDark;
  const _WorkoutMockup({required this.isDark});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF2ECC71);

    final exercises = [
      ('Bench Press', '4 x 10', Icons.fitness_center),
      ('Pull Ups', '3 x 8', Icons.height_rounded),
      ('Squats', '4 x 12', Icons.accessibility_new),
    ];

    return Container(
      width: 88,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.4)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // AI sparkle header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome,
                  size: 10, color: green),
              const SizedBox(width: 3),
              Text(
                'Push Day',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),

          // Mini exercise rows
          ...exercises.asMap().entries.map((entry) {
            final i = entry.key;
            final ex = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(ex.$3, size: 9, color: green),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ex.$1,
                            style: TextStyle(
                              fontSize: 7,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            ex.$2,
                            style: TextStyle(
                              fontSize: 6,
                              color: isDark
                                  ? AppColors.textMuted
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(
                    delay: Duration(milliseconds: 600 + i * 150),
                    duration: 300.ms,
                  )
                  .slideX(begin: 0.15),
            );
          }),
        ],
      ),
    );
  }
}
