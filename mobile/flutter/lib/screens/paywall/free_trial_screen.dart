import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme_colors.dart';

/// "24 hours, on me" free trial screen shown after user declines
/// both the paywall and the discount popup.
class FreeTrialScreen extends ConsumerWidget {
  const FreeTrialScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.colors(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? colors.background : const Color(0xFFFBF5EF);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: CustomPaint(
          painter: _DecoSymbolsPainter(isDark: isDark),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // App icon
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/images/app_icon.png',
                    width: 80,
                    height: 80,
                  ),
                ),
                const SizedBox(height: 28),

                // Title
                Text(
                  '24 hours, on me \u{1F44B}',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Body text 1
                Text(
                  "I'd love for you to try the app. Here's a 24-hour "
                  "trial on me. Nothing you need to do, it's already activated.",
                  style: TextStyle(
                    fontSize: 16,
                    color: colors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Body text 2
                Text(
                  "I wish I could offer a free plan or make this longer, "
                  "but for transparency I'm using extremely expensive AI "
                  "providers to power FitWiz and simply can't afford to do it.",
                  style: TextStyle(
                    fontSize: 15,
                    color: colors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Bold callout
                Text(
                  'No credit card required. Just enjoy!',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const Spacer(flex: 3),

                // CTA button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.accent,
                      foregroundColor: colors.accentContrast,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Sounds good!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Subtle decorative symbols painted behind the content.
class _DecoSymbolsPainter extends CustomPainter {
  final bool isDark;
  _DecoSymbolsPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03)
      ..style = PaintingStyle.fill;

    // Draw a few subtle circles as decoration
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.15), 40, paint);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.25), 30, paint);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.75), 50, paint);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.7), 35, paint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.05), 25, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
