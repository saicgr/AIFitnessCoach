import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// "Let's Go" button shown after onboarding is complete.
class LetsGoButton extends StatelessWidget {
  final VoidCallback onTap;

  const LetsGoButton({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Responsive margin: smaller on narrow screens
    final screenWidth = MediaQuery.of(context).size.width;
    final leftMargin = screenWidth < 380 ? 16.0 : 52.0;

    return Padding(
      padding: EdgeInsets.only(left: leftMargin, top: 12, right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            gradient: AppColors.cyanGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.cyan.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 0,
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Let's Go!",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 8),
              Text('rocket', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}
