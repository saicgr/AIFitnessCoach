import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';

/// Main shell with floating bottom navigation bar
class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/library')) return 1;
    if (location.startsWith('/social')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/library');
        break;
      case 2:
        context.go('/social');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);

    return Material(
      color: AppColors.pureBlack,
      child: Stack(
        children: [
          // Main content fills the entire screen
          Positioned.fill(
            child: child,
          ),
          // Floating nav bar at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _FloatingNavBar(
              selectedIndex: selectedIndex,
              onItemTapped: (index) => _onItemTapped(context, index),
              onChatPressed: () => context.push('/chat'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom floating navigation bar widget
class _FloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final VoidCallback onChatPressed;

  const _FloatingNavBar({
    required this.selectedIndex,
    required this.onItemTapped,
    required this.onChatPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: bottomPadding + 16,
      ),
      child: Row(
        children: [
          // Main nav bar pill
          Expanded(
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Home
                  _NavItem(
                    icon: Icons.home_outlined,
                    selectedIcon: Icons.home_rounded,
                    label: 'Home',
                    isSelected: selectedIndex == 0,
                    onTap: () => onItemTapped(0),
                  ),
                  // Library
                  _NavItem(
                    icon: Icons.fitness_center_outlined,
                    selectedIcon: Icons.fitness_center,
                    label: 'Library',
                    isSelected: selectedIndex == 1,
                    onTap: () => onItemTapped(1),
                  ),
                  // Social
                  _NavItem(
                    icon: Icons.people_outline_rounded,
                    selectedIcon: Icons.people_rounded,
                    label: 'Social',
                    isSelected: selectedIndex == 2,
                    onTap: () => onItemTapped(2),
                  ),
                  // Profile
                  _NavItem(
                    icon: Icons.person_outline_rounded,
                    selectedIcon: Icons.person_rounded,
                    label: 'Profile',
                    isSelected: selectedIndex == 3,
                    onTap: () => onItemTapped(3),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Separate AI Chat pill
          _ChatButton(onTap: onChatPressed),
        ],
      ),
    );
  }
}

/// Separate AI Chat button - floating gradient circle
class _ChatButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ChatButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.purple, AppColors.cyan],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.cyan.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: const Icon(
          Icons.auto_awesome,
          color: Colors.white,
          size: 24,
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

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 52,
        height: 56,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.cyan.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isSelected ? selectedIcon : icon,
              color: isSelected ? AppColors.cyan : AppColors.textMuted,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
