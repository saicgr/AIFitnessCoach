import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Splash screen shown while app initializes and checks auth state.
/// This prevents the login screen flash when user is already authenticated.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App icon/logo - using actual app icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: teal,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: teal.withOpacity(0.3),
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
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Loading indicator
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  teal.withOpacity(0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
