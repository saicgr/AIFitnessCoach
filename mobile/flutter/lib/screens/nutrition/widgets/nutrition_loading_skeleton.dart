import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class NutritionLoadingSkeleton extends StatelessWidget {
  final bool isDark;

  const NutritionLoadingSkeleton({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final shimmerBase = isDark
        ? AppColors.elevated.withValues(alpha: 0.6)
        : AppColorsLight.elevated;
    final shimmerHighlight = isDark
        ? AppColors.glassSurface.withValues(alpha: 0.3)
        : Colors.white.withValues(alpha: 0.5);

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Energy card skeleton with shimmer
          ShimmerContainer(
            height: 140,
            borderRadius: 20,
            baseColor: shimmerBase,
            highlightColor: shimmerHighlight,
          ),
          const SizedBox(height: 16),
          // Macros row skeleton with staggered shimmer
          Row(
            children: List.generate(
              4,
              (index) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ShimmerContainer(
                    height: 100,
                    borderRadius: 12,
                    baseColor: shimmerBase,
                    highlightColor: shimmerHighlight,
                    delay: Duration(milliseconds: index * 100),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Meal sections skeleton with staggered shimmer
          ...List.generate(
            4,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ShimmerContainer(
                height: 60,
                borderRadius: 16,
                baseColor: shimmerBase,
                highlightColor: shimmerHighlight,
                delay: Duration(milliseconds: 400 + index * 100),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer container with smooth animation
class ShimmerContainer extends StatefulWidget {
  final double height;
  final double? width;
  final double borderRadius;
  final Color baseColor;
  final Color highlightColor;
  final Duration delay;

  const ShimmerContainer({
    super.key,
    required this.height,
    this.width,
    required this.borderRadius,
    required this.baseColor,
    required this.highlightColor,
    this.delay = Duration.zero,
  });

  @override
  State<ShimmerContainer> createState() => _ShimmerContainerState();
}

class _ShimmerContainerState extends State<ShimmerContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Start with delay for staggered effect
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.repeat();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}
