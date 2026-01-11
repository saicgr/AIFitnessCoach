import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../data/providers/admin_provider.dart';
import '../data/providers/guest_mode_provider.dart';
import '../data/providers/guest_usage_limits_provider.dart';
import '../data/services/deep_link_service.dart';
import '../data/services/widget_action_service.dart';
import '../screens/admin_support/admin_support_provider.dart';
import '../screens/ai_settings/ai_settings_screen.dart';
import '../screens/nutrition/quick_log_overlay.dart';
import 'floating_chat/floating_chat_overlay.dart';

/// Provider to control floating nav bar visibility
final floatingNavBarVisibleProvider = StateProvider<bool>((ref) => true);

/// Provider to control whether nav bar labels are expanded
/// Set to false when on secondary pages (Workouts, Nutrition, Fasting)
final navBarLabelsExpandedProvider = StateProvider<bool>((ref) => true);

/// Main shell with floating bottom navigation bar
class MainShell extends ConsumerWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/social')) return 1;
    if (location.startsWith('/profile')) return 2;
    if (location.startsWith('/stats')) return 3;
    return 0;
  }

  bool _isSecondaryPage(BuildContext context) {
    // Use the full URI path to detect secondary pages, not just the shell's matched location
    final fullPath = GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
    return fullPath.startsWith('/workouts') ||
           fullPath.startsWith('/nutrition') ||
           fullPath.startsWith('/fasting');
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/social');
        break;
      case 2:
        context.go('/profile');
        break;
      case 3:
        context.go('/stats');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _calculateSelectedIndex(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final isNavBarVisible = ref.watch(floatingNavBarVisibleProvider);
    final isGuestMode = ref.watch(isGuestModeProvider);

    // Initialize widget action service (MethodChannel listener)
    // This allows Android widgets to trigger UI actions without navigation
    final widgetActionService = ref.read(widgetActionServiceProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        widgetActionService.initialize(context, ref);
      }
    });

    // Listen for pending widget actions (from home screen widget deep links)
    ref.listen<PendingWidgetAction>(pendingWidgetActionProvider, (previous, next) {
      debugPrint('MainShell: Pending action changed from $previous to $next');
      if (next == PendingWidgetAction.showLogMealSheet) {
        // Clear the action immediately
        ref.read(pendingWidgetActionProvider.notifier).state = PendingWidgetAction.none;
        // Show the quick log overlay after screen is fully built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (context.mounted) {
              debugPrint('MainShell: Showing quick log overlay');
              showQuickLogOverlay(context, ref);
            }
          });
        });
      }
    });

    // Use ValueKey to avoid GlobalKey conflicts when theme changes
    return Material(
      key: const ValueKey('main_shell_material'),
      color: backgroundColor,
      child: Stack(
        children: [
          // Main content with guest banner if needed
          Positioned.fill(
            child: Column(
              children: [
                // Guest mode banner at top
                if (isGuestMode)
                  _GuestModeBanner(isDark: isDark),
                // Main content fills remaining space
                Expanded(child: child),
              ],
            ),
          ),
          // Floating nav bar at bottom with AI button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              offset: isNavBarVisible ? Offset.zero : const Offset(0, 1.5),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isNavBarVisible ? 1.0 : 0.0,
                child: _FloatingNavBarWithAI(
                  selectedIndex: selectedIndex,
                  isSecondaryPage: _isSecondaryPage(context),
                  onItemTapped: (index) => _onItemTapped(context, index),
                ),
              ),
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
  final bool isSecondaryPage;
  final Function(int) onItemTapped;

  const _FloatingNavBarWithAI({
    required this.selectedIndex,
    required this.isSecondaryPage,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBarColor = isDark ? const Color(0xFF1C1C1E) : AppColorsLight.elevated;
    final shadowColor = isDark ? Colors.black.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.1);

    // Watch the labels expanded provider - secondary pages set this to false
    final labelsExpanded = ref.watch(navBarLabelsExpandedProvider);

    // Dynamic sizing based on nav bar dimensions - compact design
    const navBarHeight = 42.0;
    const navBarRadius = navBarHeight / 2; // Fully rounded ends
    const itemPadding = 3.0; // Reduced padding for compact look
    final itemHeight = navBarHeight - (itemPadding * 2); // 36

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: bottomPadding + 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Back button - only shown on secondary pages (when labels are collapsed), OUTSIDE the nav bar
          if (!labelsExpanded) ...[
            _FloatingBackButton(
              onTap: () {
                // Reset labels to expanded before navigating home
                ref.read(navBarLabelsExpandedProvider.notifier).state = true;
                onItemTapped(0); // Go to Home
              },
            ),
            const SizedBox(width: 8),
          ],

          // Nav bar - uses intrinsic width, animates when items expand/collapse
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            height: navBarHeight,
            decoration: BoxDecoration(
              color: navBarColor,
              borderRadius: BorderRadius.circular(navBarRadius),
              border: isDark ? null : Border.all(color: AppColorsLight.cardBorder, width: 1),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(itemPadding),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Home - Cyan
                  _NavItem(
                    icon: Icons.home_outlined,
                    selectedIcon: Icons.home_rounded,
                    label: 'Home',
                    isSelected: selectedIndex == 0,
                    labelsExpanded: labelsExpanded,
                    onTap: () {
                      // Reset labels to expanded when navigating to Home
                      if (!labelsExpanded) {
                        ref.read(navBarLabelsExpandedProvider.notifier).state = true;
                      }
                      onItemTapped(0);
                    },
                    itemHeight: itemHeight,
                    selectedColor: isDark ? AppColors.cyan : AppColorsLight.cyan,
                  ),
                  const SizedBox(width: 4),
                  // Social - Orange (globe icon)
                  _NavItem(
                    icon: Icons.public_outlined,
                    selectedIcon: Icons.public,
                    label: 'Social',
                    isSelected: selectedIndex == 1,
                    labelsExpanded: labelsExpanded,
                    onTap: () => onItemTapped(1),
                    itemHeight: itemHeight,
                    selectedColor: const Color(0xFFFF9500),
                  ),
                  const SizedBox(width: 4),
                  // Profile - Purple
                  _NavItem(
                    icon: Icons.person_outline,
                    selectedIcon: Icons.person,
                    label: 'Profile',
                    isSelected: selectedIndex == 2,
                    labelsExpanded: labelsExpanded,
                    onTap: () => onItemTapped(2),
                    itemHeight: itemHeight,
                    selectedColor: isDark ? AppColors.purple : AppColorsLight.purple,
                  ),
                  const SizedBox(width: 4),
                  // Stats - Teal (bar chart icon)
                  _NavItem(
                    icon: Icons.bar_chart_outlined,
                    selectedIcon: Icons.bar_chart,
                    label: 'Stats',
                    isSelected: selectedIndex == 3,
                    labelsExpanded: labelsExpanded,
                    onTap: () => onItemTapped(3),
                    itemHeight: itemHeight,
                    selectedColor: AppColors.teal,
                  ),
                ],
              ),
            ),
          ),

          // Spacing between nav bar and buttons
          const SizedBox(width: 8),

          // Admin Support Button - only shown for admins
          _AdminSupportButton(),

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

/// Admin support button - only visible for admin users
class _AdminSupportButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);
    final unreadCount = ref.watch(adminUnreadCountProvider);

    // Don't show for non-admin users
    if (!isAdmin) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          context.push('/admin-support');
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.warning,
                borderRadius: BorderRadius.circular(21),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.warning.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.support_agent,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
            // Unread badge
            if (unreadCount > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.pureBlack, width: 2),
                  ),
                  constraints: const BoxConstraints(minWidth: 18),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// AI Coach button with gradient and glow - reactive to coach persona
class _AICoachButton extends ConsumerWidget {
  final VoidCallback onTap;

  const _AICoachButton({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch AI settings to reactively update when coach changes
    final aiSettings = ref.watch(aiSettingsProvider);
    final coach = ref.read(aiSettingsProvider.notifier).getCurrentCoach();

    // Always use chat bubble for AI coach button (cleaner look)
    const coachIcon = Icons.chat_bubble_rounded;
    final primaryColor = coach?.primaryColor ?? AppColors.purple;
    final accentColor = coach?.accentColor ?? AppColors.cyan;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primaryColor, accentColor],
          ),
          borderRadius: BorderRadius.circular(21),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 2),
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Icon(
            coachIcon,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}

/// Individual navigation item with fluid expand animation
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final bool labelsExpanded;
  final VoidCallback onTap;
  final double itemHeight;
  final Color selectedColor;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.labelsExpanded,
    required this.onTap,
    required this.itemHeight,
    required this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    // Show label only when selected AND labels are expanded (not on secondary pages)
    final showLabel = isSelected && labelsExpanded;

    return Semantics(
      label: label,
      selected: isSelected,
      button: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          height: itemHeight,
          padding: EdgeInsets.symmetric(
            horizontal: showLabel ? 10 : 8,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? selectedColor.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(itemHeight / 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isSelected ? selectedIcon : icon,
                  key: ValueKey(isSelected),
                  color: isSelected ? selectedColor : textMuted,
                  size: 22,
                ),
              ),
              // Animated label - only shows when selected AND labels expanded
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                alignment: Alignment.centerLeft,
                child: showLabel
                    ? Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: selectedColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Floating back button for secondary pages - appears to the left of nav bar (like AI button)
class _FloatingBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _FloatingBackButton({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cyanColor = isDark ? AppColors.cyan : AppColorsLight.cyan;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: cyanColor,
          borderRadius: BorderRadius.circular(21),
          boxShadow: [
            BoxShadow(
              color: cyanColor.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 2),
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}

/// Guest mode banner shown at the top of the main shell
class _GuestModeBanner extends ConsumerWidget {
  final bool isDark;

  const _GuestModeBanner({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usage = ref.watch(guestUsageLimitsProvider);
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return SafeArea(
      bottom: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.orange.withOpacity(0.15),
              AppColors.purple.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.orange.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            // Guest icon
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.person_outline,
                color: AppColors.orange,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        'Guest Mode',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.cyan.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${usage.remainingChatMessages} chats left today',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: AppColors.cyan,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Sign up free for unlimited access',
                    style: TextStyle(
                      fontSize: 11,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Sign up button
            GestureDetector(
              onTap: () async {
                HapticFeedback.lightImpact();
                await ref.read(guestModeProvider.notifier).exitGuestMode(convertedToSignup: true);
                if (context.mounted) {
                  context.go('/pre-auth-quiz');
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.cyan,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Sign Up',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
