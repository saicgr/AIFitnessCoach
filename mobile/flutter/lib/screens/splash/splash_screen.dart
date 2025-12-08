import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Splash screen shown while app initializes and checks auth state.
/// This prevents the login screen flash when user is already authenticated.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureBlack,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App icon/logo
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.cyan,
                    AppColors.purple,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cyan.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.fitness_center,
                size: 40,
                color: Colors.white,
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
                  AppColors.cyan.withOpacity(0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
