import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/theme_colors.dart';
import '../data/models/coach_persona.dart';
import '../data/providers/admin_provider.dart';
import '../data/providers/guest_mode_provider.dart';
import '../data/providers/guest_usage_limits_provider.dart';
import '../data/services/deep_link_service.dart';
import '../data/services/widget_action_service.dart';
import '../screens/admin_support/admin_support_provider.dart';
import '../screens/ai_settings/ai_settings_screen.dart';
import '../screens/nutrition/quick_log_overlay.dart';
import 'coach_avatar.dart';
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
    if (location.startsWith('/workouts')) return 1;
    if (location.startsWith('/nutrition')) return 2;
    if (location.startsWith('/social')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  bool _isSecondaryPage(BuildContext context) {
    // Use the full URI path to detect secondary pages, not just the shell's matched location
    final fullPath = GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
    return fullPath.startsWith('/fasting');
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/workouts');
        break;
      case 2:
        context.go('/nutrition');
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
    final isNavBarVisible = ref.watch(floatingNavBarVisibleProvider);
    final isGuestMode = ref.watch(isGuestModeProvider);
    // Get dynamic accent color from provider
    final accentColor = ref.colors(context).accent;

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
          // Nav bar at bottom
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
          // Note: Workout mini player is now handled globally in app.dart
          // Floating draggable AI Coach button
          _DraggableAICoachButton(
            onTap: () {
              HapticFeedback.mediumImpact();
              showChatBottomSheet(context, ref);
            },
          ),
        ],
      ),
    );
  }
}

/// Draggable floating AI Coach button that can be positioned anywhere on screen
class _DraggableAICoachButton extends StatefulWidget {
  final VoidCallback onTap;

  const _DraggableAICoachButton({required this.onTap});

  @override
  State<_DraggableAICoachButton> createState() => _DraggableAICoachButtonState();
}

class _DraggableAICoachButtonState extends State<_DraggableAICoachButton> {
  // Position - initialized in initState
  late double _xPosition;
  late double _yPosition;

  static const double buttonSize = 64.0; // Bigger avatar

  @override
  void initState() {
    super.initState();
    // Will be properly initialized in first build
    _xPosition = -1;
    _yPosition = -1;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final topPadding = MediaQuery.of(context).padding.top;

    // Position just above the nav bar (64px height + small gap)
    const navBarOffset = 72.0; // 64px nav bar + 8px gap

    // Initialize position on first build - position just above nav bar
    if (_xPosition < 0 || _yPosition < 0) {
      _xPosition = size.width - buttonSize - 16;
      _yPosition = size.height - buttonSize - bottomPadding - navBarOffset;
    }

    // Boundaries for dragging - allow going lower (just above nav bar)
    const minX = 8.0;
    final maxX = size.width - buttonSize - 8;
    final minY = topPadding + 60;
    final maxY = size.height - buttonSize - bottomPadding - navBarOffset;

    return Positioned(
      left: _xPosition.clamp(minX, maxX),
      top: _yPosition.clamp(minY, maxY),
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _xPosition = (_xPosition + details.delta.dx).clamp(minX, maxX);
            _yPosition = (_yPosition + details.delta.dy).clamp(minY, maxY);
          });
        },
        onPanEnd: (details) {
          // Snap to nearest edge (left or right)
          setState(() {
            final centerX = _xPosition + buttonSize / 2;
            if (centerX < size.width / 2) {
              _xPosition = minX;
            } else {
              _xPosition = maxX;
            }
          });
        },
        onTap: widget.onTap,
        child: _AICoachButton(onTap: widget.onTap),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBarColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Watch the labels expanded provider - secondary pages set this to false
    final labelsExpanded = ref.watch(navBarLabelsExpandedProvider);

    // Get dynamic accent color from provider
    final accentColor = ref.colors(context).accent;

    // Nav bar dimensions (no more + button protrusion)
    const navBarHeight = 64.0;
    const itemHeight = 50.0;
    const fadeHeight = 50.0;

    return SizedBox(
      height: navBarHeight + bottomPadding + fadeHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Full gradient from transparent to solid - covers entire nav area
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      navBarColor.withValues(alpha: 0.0),
                      navBarColor.withValues(alpha: 0.15),
                      navBarColor.withValues(alpha: 0.4),
                      navBarColor.withValues(alpha: 0.7),
                      navBarColor.withValues(alpha: 0.9),
                      navBarColor,
                      navBarColor,
                    ],
                    stops: const [0.0, 0.1, 0.25, 0.4, 0.5, 0.6, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // Nav bar content - positioned at bottom, only this area receives touches
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: navBarHeight + bottomPadding,
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: navBarHeight,
                child: Stack(
                  children: [
                    // Main nav items - 5 items evenly spaced
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _AnchoredNavItem(
                          icon: Icons.home_outlined,
                          selectedIcon: Icons.home_rounded,
                          label: 'Home',
                          isSelected: selectedIndex == 0,
                          onTap: () => onItemTapped(0),
                          itemHeight: itemHeight,
                          selectedColor: accentColor,
                          isDark: isDark,
                        ),
                        _AnchoredNavItem(
                          icon: Icons.fitness_center_outlined,
                          selectedIcon: Icons.fitness_center,
                          label: 'Workout',
                          isSelected: selectedIndex == 1,
                          onTap: () => onItemTapped(1),
                          itemHeight: itemHeight,
                          selectedColor: accentColor,
                          isDark: isDark,
                        ),
                        _AnchoredNavItem(
                          icon: Icons.restaurant_outlined,
                          selectedIcon: Icons.restaurant,
                          label: 'Nutrition',
                          isSelected: selectedIndex == 2,
                          onTap: () => onItemTapped(2),
                          itemHeight: itemHeight,
                          selectedColor: accentColor,
                          isDark: isDark,
                        ),
                        _AnchoredNavItem(
                          icon: Icons.public_outlined,
                          selectedIcon: Icons.public,
                          label: 'Social',
                          isSelected: selectedIndex == 3,
                          onTap: () => onItemTapped(3),
                          itemHeight: itemHeight,
                          selectedColor: accentColor,
                          isDark: isDark,
                        ),
                        _AnchoredNavItem(
                          icon: Icons.person_outline,
                          selectedIcon: Icons.person,
                          label: 'Profile',
                          isSelected: selectedIndex == 4,
                          onTap: () => onItemTapped(4),
                          itemHeight: itemHeight,
                          selectedColor: accentColor,
                          isDark: isDark,
                        ),
                      ],
                    ),

                    // Admin Support Button - only shown for admins
                    Positioned(
                      right: 8,
                      top: 0,
                      bottom: 0,
                      child: Center(child: _AdminSupportButton()),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper to get contrast color for a given background
Color _getContrastColor(Color background) {
  // Calculate luminance - if > 0.5, use black text, otherwise white
  final luminance = background.computeLuminance();
  return luminance > 0.5 ? Colors.black : Colors.white;
}

/// Plus button with slight protrusion above the nav bar
class _ProtrudingPlusButton extends StatelessWidget {
  final double size;
  final VoidCallback onTap;
  final bool isDark;
  final Color accentColor;

  const _ProtrudingPlusButton({
    required this.size,
    required this.onTap,
    required this.isDark,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    // Use dynamic accent color
    final buttonColor = accentColor;
    // Contrast icon: for colored accents use white, for monochrome use opposite
    final iconColor = _getContrastColor(buttonColor);

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: buttonColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: buttonColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            Icons.add_rounded,
            color: iconColor,
            size: 28,
          ),
        ),
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

/// AI Coach button with coach avatar - reactive to coach persona
class _AICoachButton extends ConsumerWidget {
  final VoidCallback onTap;

  const _AICoachButton({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch AI settings to reactively update when coach changes
    final aiSettings = ref.watch(aiSettingsProvider);
    final coach = CoachPersona.findById(aiSettings.coachPersonaId) ?? CoachPersona.defaultCoach;

    return CoachAvatar(
      coach: coach,
      size: 56,
      showBorder: true,
      borderWidth: 3,
      showShadow: true,
      enableTapToView: false, // Tap opens chat
      onTap: onTap,
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

/// Plus button for quick actions in the center of nav bar
class _PlusButton extends StatelessWidget {
  final double itemHeight;
  final VoidCallback onTap;

  const _PlusButton({
    required this.itemHeight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final purpleColor = isDark ? AppColors.purple : AppColorsLight.purple;

    return Semantics(
      label: 'Quick Actions',
      button: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: itemHeight,
          width: itemHeight,
          decoration: BoxDecoration(
            color: purpleColor,
            borderRadius: BorderRadius.circular(itemHeight / 2),
            boxShadow: [
              BoxShadow(
                color: purpleColor.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

/// Anchored nav item for standard bottom navigation bar (like Fitbod)
class _AnchoredNavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final double itemHeight;
  final Color selectedColor;
  final bool isDark;

  const _AnchoredNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.itemHeight,
    required this.selectedColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final activeColor = isSelected ? selectedColor : textMuted;

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
        child: SizedBox(
          height: itemHeight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? selectedIcon : icon,
                color: activeColor,
                size: 24,
              ),
              // Only show label when selected
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child: isSelected
                    ? Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: selectedColor,
                            fontSize: 13,
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

/// Anchored plus button for standard bottom navigation bar
class _AnchoredPlusButton extends StatelessWidget {
  final double itemHeight;
  final VoidCallback onTap;

  const _AnchoredPlusButton({
    required this.itemHeight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: 'Quick Actions',
      button: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: isDark ? Colors.white : Colors.black,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              Icons.add_rounded,
              color: isDark ? Colors.black : Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}

/// Elevated FAB that sits above the nav bar (like Fitbod/reference designs)
class _ElevatedFAB extends StatelessWidget {
  final double size;
  final VoidCallback onTap;
  final bool isDark;

  const _ElevatedFAB({
    required this.size,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Use app's purple color for the FAB
    final fabColor = isDark ? AppColors.purple : AppColorsLight.purple;

    return Semantics(
      label: 'Quick Actions',
      button: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: fabColor,
            shape: BoxShape.circle,
            // No shadow - clean look
          ),
          child: const Center(
            child: Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }
}

/// Anchored back button for secondary pages
class _AnchoredBackButton extends StatelessWidget {
  final VoidCallback onTap;
  final double itemHeight;
  final bool isDark;

  const _AnchoredBackButton({
    required this.onTap,
    required this.itemHeight,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cyanColor = isDark ? AppColors.cyan : AppColorsLight.cyan;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        height: itemHeight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.arrow_back_ios_new_rounded,
              color: cyanColor,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              'Back',
              style: TextStyle(
                color: cyanColor,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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
