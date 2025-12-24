import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../floating_chat/floating_chat_overlay.dart';

/// Simplified bottom navigation for Senior Mode
/// 4 items: Home, Workouts, Food, Settings + AI Coach floating button
class SeniorBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback? onAICoachTap;

  const SeniorBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.onAICoachTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      height: 100 + bottomPadding, // Taller for easier tapping
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? const Color(0xFF333333)
                : const Color(0xFFEEEEEE),
            width: 2,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _SeniorNavItem(
              icon: Icons.home_rounded,
              label: 'Home',
              isSelected: currentIndex == 0,
              onTap: () => onTap(0),
            ),
            _SeniorNavItem(
              icon: Icons.insights_rounded,
              label: 'Workouts',
              isSelected: currentIndex == 1,
              onTap: () => onTap(1),
            ),
            _SeniorNavItem(
              icon: Icons.restaurant_rounded,
              label: 'Food',
              isSelected: currentIndex == 2,
              onTap: () => onTap(2),
            ),
            _SeniorNavItem(
              icon: Icons.settings_rounded,
              label: 'Settings',
              isSelected: currentIndex == 3,
              onTap: () => onTap(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeniorNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SeniorNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final color = isSelected
        ? AppColors.cyan
        : (isDark ? const Color(0xFF666666) : const Color(0xFF999999));

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.cyan.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    size: 36, // Large icons
                    color: color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16, // Large labels
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: color,
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

/// Full-screen Senior Mode scaffold with simplified navigation
class SeniorScaffold extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onNavTap;
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showBackButton;
  final VoidCallback? onBack;
  final bool showAICoachButton;

  const SeniorScaffold({
    super.key,
    required this.currentIndex,
    required this.onNavTap,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.showBackButton = false,
    this.onBack,
    this.showAICoachButton = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.pureBlack : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.pureBlack : Colors.white,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 72,
        leading: showBackButton
            ? IconButton(
                onPressed: onBack ?? () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.arrow_back_rounded,
                  size: 32,
                  color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                ),
              )
            : null,
        title: Text(
          title,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1A1A1A),
          ),
        ),
        actions: actions,
      ),
      body: Stack(
        children: [
          body,
          // Floating AI Coach button
          if (showAICoachButton)
            Positioned(
              right: 20,
              bottom: 16,
              child: _SeniorAICoachButton(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  showChatBottomSheet(context, ref);
                },
              ),
            ),
        ],
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: SeniorBottomNav(
        currentIndex: currentIndex,
        onTap: onNavTap,
      ),
    );
  }
}

/// Large AI Coach button for Senior Mode
class _SeniorAICoachButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SeniorAICoachButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.purple, AppColors.cyan],
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: AppColors.cyan.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.auto_awesome,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }
}

/// Simple Senior Mode page without bottom nav (for sub-screens)
class SeniorPage extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final VoidCallback? onBack;

  const SeniorPage({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.pureBlack : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.pureBlack : Colors.white,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 72,
        leading: IconButton(
          onPressed: onBack ?? () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back_rounded,
            size: 32,
            color: isDark ? Colors.white : const Color(0xFF1A1A1A),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1A1A1A),
          ),
        ),
        actions: actions,
      ),
      body: body,
    );
  }
}
