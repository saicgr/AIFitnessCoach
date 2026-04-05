import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/services/haptic_service.dart';

/// Focus pills for navigating between For You (Home), Workouts, Nutrition, and Fasting
class WorkoutCategoryPills extends ConsumerStatefulWidget {
  final bool isDark;

  const WorkoutCategoryPills({super.key, required this.isDark});

  @override
  ConsumerState<WorkoutCategoryPills> createState() => _WorkoutCategoryPillsState();
}

class _WorkoutCategoryPillsState extends ConsumerState<WorkoutCategoryPills> {
  late ScrollController _scrollController;
  bool _hasAnimated = false;

  static final List<Map<String, dynamic>> _focusOptions = [
    {'label': 'For You', 'icon': Icons.star_rounded, 'route': null, 'color': AppColors.textPrimary},
    {'label': 'Workout', 'icon': Icons.fitness_center, 'route': '/workouts', 'color': AppColors.textPrimary},
    {'label': 'Nutrition', 'icon': Icons.restaurant, 'route': '/nutrition', 'color': AppColors.textPrimary},
    // COMING SOON: Fasting pill — uncomment when fasting feature launches
    // {'label': 'Fasting', 'icon': Icons.timer, 'route': '/fasting', 'color': AppColors.textPrimary},
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animateScrollHint();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _animateScrollHint() async {
    if (_hasAnimated || !mounted) return;
    _hasAnimated = true;

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted || !_scrollController.hasClients) return;

    await _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );

    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted || !_scrollController.hasClients) return;

    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    final location = GoRouterState.of(context).matchedLocation;
    int activeIndex = 0;
    if (location.startsWith('/workouts')) {
      activeIndex = 1;
    } else if (location.startsWith('/nutrition')) {
      activeIndex = 2;
    }

    final colors = ref.colors(context);
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return AnimationLimiter(
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Edit/Pencil icon button before pills
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  HapticService.selection();
                  context.push('/settings/homescreen');
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.glassSurface
                        : AppColorsLight.glassSurface,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: textSecondary,
                  ),
                ),
              ),
            ),
            // Category pills
            ...AnimationConfiguration.toStaggeredList(
              duration: const Duration(milliseconds: 400),
              childAnimationBuilder: (widget) => SlideAnimation(
                horizontalOffset: 50.0,
                child: FadeInAnimation(child: widget),
              ),
              children: _focusOptions.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              final isActive = index == activeIndex;
              final activeColor = colors.accent;
              final route = option['route'] as String?;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _CategoryPill(
                  label: option['label'] as String,
                  icon: option['icon'] as IconData,
                  isActive: isActive,
                  isDark: isDark,
                  activeColor: activeColor,
                  onTap: () {
                    HapticService.selection();
                    if (route != null) {
                      context.push(route);
                    }
                  },
                ),
              );
            }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final bool isDark;
  final Color activeColor;
  final VoidCallback onTap;

  const _CategoryPill({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.isDark,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeBg = activeColor;
    final inactiveBg = isDark
        ? AppColors.glassSurface
        : AppColorsLight.glassSurface;
    final activeText = isDark ? Colors.black : Colors.white;
    final inactiveText = isDark
        ? AppColors.textSecondary
        : AppColorsLight.textSecondary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: Material(
        color: isActive ? activeBg : inactiveBg,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: isActive ? 16 : 14,
              vertical: isActive ? 10 : 8,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive
                    ? activeBg
                    : (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
                width: isActive ? 0 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isActive ? activeText : inactiveText,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive ? activeText : inactiveText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
