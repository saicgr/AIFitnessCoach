import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

/// A bouncing arrow that indicates scrollable content below.
/// Shows when user hasn't scrolled to the bottom yet.
class ScrollHintArrow extends StatefulWidget {
  final ScrollController scrollController;
  final double threshold; // How far from bottom to hide (default 50px)

  const ScrollHintArrow({
    super.key,
    required this.scrollController,
    this.threshold = 50,
  });

  @override
  State<ScrollHintArrow> createState() => _ScrollHintArrowState();
}

class _ScrollHintArrowState extends State<ScrollHintArrow> {
  bool _showArrow = false;
  bool _hasCheckedInitial = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
    // Check initial state after layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfScrollable();
    });
  }

  @override
  void didUpdateWidget(ScrollHintArrow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController.removeListener(_onScroll);
      widget.scrollController.addListener(_onScroll);
    }
    // Re-check scrollability when widget updates (content may have changed)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfScrollable();
    });
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _checkIfScrollable() {
    if (!mounted) return;
    if (!widget.scrollController.hasClients) {
      // Try again next frame
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkIfScrollable());
      return;
    }

    final maxScroll = widget.scrollController.position.maxScrollExtent;
    final currentScroll = widget.scrollController.offset;
    final isScrollable = maxScroll > widget.threshold;
    final isNearBottom = currentScroll >= maxScroll - widget.threshold;

    // Only show arrow if content is scrollable AND we're not already at/near the bottom
    final shouldShow = isScrollable && !isNearBottom;

    if (!_hasCheckedInitial || _showArrow != shouldShow) {
      setState(() {
        _showArrow = shouldShow;
        _hasCheckedInitial = true;
      });
    }
  }

  void _onScroll() {
    if (!mounted || !widget.scrollController.hasClients) return;

    final maxScroll = widget.scrollController.position.maxScrollExtent;
    final currentScroll = widget.scrollController.offset;
    final isNearBottom = currentScroll >= maxScroll - widget.threshold;

    if (_showArrow && isNearBottom) {
      setState(() => _showArrow = false);
    } else if (!_showArrow && !isNearBottom && maxScroll > widget.threshold) {
      setState(() => _showArrow = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_showArrow) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      bottom: 16,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.elevated : Colors.white).withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.keyboard_arrow_down,
              color: isDark ? AppColors.cyan : AppColors.teal,
              size: 24,
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .moveY(begin: 0, end: 6, duration: 600.ms, curve: Curves.easeInOut)
              .then()
              .moveY(begin: 6, end: 0, duration: 600.ms, curve: Curves.easeInOut),
        ),
      ),
    );
  }
}
