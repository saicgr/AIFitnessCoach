import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/theme_provider.dart';
import 'lottie_animations.dart';

/// Reusable empty state widget with illustration and message
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;
  final bool useLottie;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.iconColor,
    this.useLottie = true,
  });

  // Pre-defined empty states for common scenarios
  factory EmptyState.noWorkouts({VoidCallback? onAction}) {
    return EmptyState(
      icon: Icons.fitness_center,
      title: 'No workouts yet',
      subtitle: 'Your workout schedule is empty.\nStart by creating a program!',
      actionLabel: 'Create Program',
      onAction: onAction,
      iconColor: AppColors.cyan,
    );
  }

  factory EmptyState.noExercises({VoidCallback? onAction}) {
    return EmptyState(
      icon: Icons.search_off,
      title: 'No exercises found',
      subtitle: 'Try adjusting your filters\nor search for something else.',
      actionLabel: 'Clear Filters',
      onAction: onAction,
      iconColor: AppColors.purple,
    );
  }

  factory EmptyState.noHistory() {
    return const EmptyState(
      icon: Icons.history,
      title: 'No workout history',
      subtitle: 'Complete your first workout\nto start tracking progress!',
      iconColor: AppColors.orange,
    );
  }

  factory EmptyState.noResults() {
    return const EmptyState(
      icon: Icons.search,
      title: 'No results',
      subtitle: 'We couldn\'t find what you\'re looking for.\nTry different keywords.',
      iconColor: AppColors.textMuted,
    );
  }

  factory EmptyState.offline({VoidCallback? onRetry}) {
    return EmptyState(
      icon: Icons.wifi_off,
      title: 'No connection',
      subtitle: 'Please check your internet connection\nand try again.',
      actionLabel: 'Retry',
      onAction: onRetry,
      iconColor: AppColors.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final effectiveIconColor = iconColor ?? (isDark ? AppColors.cyan : AppColorsLight.cyan);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustrated icon with background or Lottie animation
            if (useLottie)
              LottieEmpty(
                size: 120,
                color: effectiveIconColor,
              )
            else
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: effectiveIconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background ring
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: effectiveIconColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                    // Icon
                    Icon(
                      icon,
                      size: 48,
                      color: effectiveIconColor.withOpacity(0.7),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            // Action button
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: effectiveIconColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Skeleton loading widget for lists
class SkeletonLoader extends StatefulWidget {
  final int itemCount;
  final double itemHeight;
  final EdgeInsets padding;

  const SkeletonLoader({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 80,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);
    final highlightColor = isDark ? const Color(0xFF3C3C3E) : const Color(0xFFF5F5F5);

    return ListView.builder(
      padding: widget.padding,
      itemCount: widget.itemCount,
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Container(
              height: widget.itemHeight,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment(_animation.value - 1, 0),
                  end: Alignment(_animation.value, 0),
                  colors: [
                    baseColor,
                    highlightColor,
                    baseColor,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Avatar skeleton
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: highlightColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Title skeleton
                          Container(
                            height: 16,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: highlightColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Subtitle skeleton
                          Container(
                            height: 12,
                            width: 120,
                            decoration: BoxDecoration(
                              color: highlightColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Card skeleton for stats/info cards
class SkeletonCard extends StatefulWidget {
  final double height;
  final double width;
  final BorderRadius? borderRadius;

  const SkeletonCard({
    super.key,
    this.height = 100,
    this.width = double.infinity,
    this.borderRadius,
  });

  @override
  State<SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);
    final highlightColor = isDark ? const Color(0xFF3C3C3E) : const Color(0xFFF5F5F5);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}
