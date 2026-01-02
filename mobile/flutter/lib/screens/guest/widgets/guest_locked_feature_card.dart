import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/haptic_service.dart';

/// A card showing a locked feature in guest mode
/// Displays with a lock icon and prompts user to sign up
class GuestLockedFeatureCard extends StatelessWidget {
  /// Unique identifier for the feature
  final String featureId;

  /// Icon to display
  final IconData icon;

  /// Feature title
  final String title;

  /// Callback when tapped
  final VoidCallback onTap;

  const GuestLockedFeatureCard({
    super.key,
    required this.featureId,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final borderColor = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Material(
      color: elevatedColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          HapticService.light();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with lock overlay
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.purple.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      icon,
                      color: AppColors.purple.withOpacity(0.6),
                      size: 24,
                    ),
                  ),
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: elevatedColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: borderColor),
                      ),
                      child: Icon(
                        Icons.lock,
                        color: textSecondary,
                        size: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Title
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Unlock hint
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    color: AppColors.cyan,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Unlock free',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.cyan,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
