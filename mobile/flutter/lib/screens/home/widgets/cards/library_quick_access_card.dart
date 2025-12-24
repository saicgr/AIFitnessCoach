import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/services/haptic_service.dart';

/// A prominent card for quick access to the exercise library
class LibraryQuickAccessCard extends StatelessWidget {
  /// Whether the current theme is dark
  final bool isDark;

  const LibraryQuickAccessCard({
    super.key,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Material(
      color: elevatedColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          HapticService.medium();
          context.push('/library');
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.purple.withOpacity(0.3),
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                elevatedColor,
                AppColors.purple.withOpacity(0.05),
              ],
            ),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.purple, AppColors.cyan],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.fitness_center,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Exercise Library',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Browse exercises, programs & workout history',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),

              // Arrow
              const Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: AppColors.purple,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
