import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/theme_provider.dart';
import 'floating_chat/floating_chat_provider.dart';
import 'floating_chat/floating_chat_overlay.dart';

/// Main shell with floating bottom navigation bar
class MainShell extends ConsumerWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/nutrition')) return 1;
    if (location.startsWith('/stats') || location.startsWith('/library') || location.startsWith('/schedule')) return 2;
    if (location.startsWith('/social')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/nutrition');
        break;
      case 2:
        context.go('/library'); // Stats/Workouts screen
        break;
      case 3:
        context.go('/social');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _calculateSelectedIndex(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;

    // Use ValueKey to avoid GlobalKey conflicts when theme changes
    return Material(
      key: const ValueKey('main_shell_material'),
      color: backgroundColor,
      child: Stack(
        children: [
          // Main content fills the entire screen
          Positioned.fill(
            child: child,
          ),
          // Floating nav bar at bottom with AI button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _FloatingNavBarWithAI(
              selectedIndex: selectedIndex,
              onItemTapped: (index) => _onItemTapped(context, index),
            ),
          ),
        ],
      ),
    );
  }
}

/// Container widget with nav bar and AI button side by side
class _FloatingNavBarWithAI extends ConsumerWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const _FloatingNavBarWithAI({
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBarColor = isDark ? const Color(0xFF1C1C1E) : AppColorsLight.elevated;
    final shadowColor = isDark ? Colors.black.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.1);

    // Dynamic sizing based on nav bar dimensions
    const navBarHeight = 46.0;
    const navBarRadius = navBarHeight / 2; // Fully rounded ends = 23
    const itemPadding = 3.0; // Even padding on all sides
    final itemHeight = navBarHeight - (itemPadding * 2); // 40

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: bottomPadding + 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Nav bar
          Container(
            height: navBarHeight,
            constraints: const BoxConstraints(maxWidth: 300), // Increased from 240 for 5 items
            decoration: BoxDecoration(
              color: navBarColor,
              borderRadius: BorderRadius.circular(navBarRadius),
              border: isDark ? null : Border.all(color: AppColorsLight.cardBorder, width: 1),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(itemPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Home - Cyan
                  _NavItem(
                    icon: Icons.home_outlined,
                    selectedIcon: Icons.home_rounded,
                    label: 'Home',
                    isSelected: selectedIndex == 0,
                    onTap: () => onItemTapped(0),
                    itemHeight: itemHeight,
                    selectedColor: isDark ? AppColors.cyan : AppColorsLight.cyan,
                  ),
                  // Nutrition - Green
                  _NavItem(
                    icon: Icons.restaurant_outlined,
                    selectedIcon: Icons.restaurant,
                    label: 'Nutrition',
                    isSelected: selectedIndex == 1,
                    onTap: () => onItemTapped(1),
                    itemHeight: itemHeight,
                    selectedColor: const Color(0xFF34C759),
                  ),
                  // Stats/Workouts - Purple
                  _NavItem(
                    icon: Icons.insights_outlined,
                    selectedIcon: Icons.insights,
                    label: 'Stats',
                    isSelected: selectedIndex == 2,
                    onTap: () => onItemTapped(2),
                    itemHeight: itemHeight,
                    selectedColor: isDark ? AppColors.purple : AppColorsLight.purple,
                  ),
                  // Social - Orange
                  _NavItem(
                    icon: Icons.people_outline_rounded,
                    selectedIcon: Icons.people_rounded,
                    label: 'Social',
                    isSelected: selectedIndex == 3,
                    onTap: () => onItemTapped(3),
                    itemHeight: itemHeight,
                    selectedColor: const Color(0xFFFF9500),
                  ),
                  // Profile - Pink
                  _NavItem(
                    icon: Icons.person_outline_rounded,
                    selectedIcon: Icons.person_rounded,
                    label: 'Profile',
                    isSelected: selectedIndex == 4,
                    onTap: () => onItemTapped(4),
                    itemHeight: itemHeight,
                    selectedColor: const Color(0xFFFF2D55),
                  ),
                ],
              ),
            ),
          ),

          // Spacing between nav bar and AI button
          const SizedBox(width: 10),

          // AI Coach Button - fixed position
          _AICoachButton(
            onTap: () {
              HapticFeedback.mediumImpact();
              // Show the chat bottom sheet directly (we have Navigator access here)
              showChatBottomSheet(context, ref);
            },
          ),
        ],
      ),
    );
  }
}

/// AI Coach button with gradient and glow
class _AICoachButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AICoachButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.purple, AppColors.cyan],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.cyan.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 3),
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.auto_awesome,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

/// Individual navigation item
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final double itemHeight;
  final Color selectedColor;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.itemHeight,
    required this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    // Squircle radius - about 1/3 of height for smooth rounded rectangle
    final squircleRadius = itemHeight / 3;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: itemHeight, // Square for even borders
        height: itemHeight,
        decoration: BoxDecoration(
          color: isSelected
              ? selectedColor.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(squircleRadius),
        ),
        child: Center(
          child: Icon(
            isSelected ? selectedIcon : icon,
            color: isSelected ? selectedColor : textMuted,
            size: 22,
          ),
        ),
      ),
    );
  }
}
