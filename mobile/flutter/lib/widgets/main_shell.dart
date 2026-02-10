import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import 'offline_banner.dart';

/// Provider to control floating nav bar visibility
final floatingNavBarVisibleProvider = StateProvider<bool>((ref) => true);

/// Provider to control whether nav bar labels are expanded
/// Set to false when on secondary pages (Workouts, Nutrition, Fasting)
final navBarLabelsExpandedProvider = StateProvider<bool>((ref) => true);

/// Provider to control edge handle visibility (can be toggled in settings)
/// Persisted to SharedPreferences
final edgeHandleEnabledProvider =
    StateNotifierProvider<EdgeHandleEnabledNotifier, bool>((ref) {
  return EdgeHandleEnabledNotifier();
});

/// Provider to store edge handle vertical position (0.0 = top, 1.0 = bottom)
/// Persisted to SharedPreferences
final edgeHandlePositionProvider =
    StateNotifierProvider<EdgeHandlePositionNotifier, double>((ref) {
  return EdgeHandlePositionNotifier();
});

/// Notifier for edge handle enabled state with persistence
class EdgeHandleEnabledNotifier extends StateNotifier<bool> {
  static const _key = 'edge_handle_enabled';

  EdgeHandleEnabledNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getBool(_key);
      if (value != null) {
        state = value;
      }
    } catch (e) {
      debugPrint('Error loading edge handle enabled: $e');
    }
  }

  Future<void> setEnabled(bool value) async {
    state = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, value);
    } catch (e) {
      debugPrint('Error saving edge handle enabled: $e');
    }
  }
}

/// Notifier for edge handle vertical position with persistence
class EdgeHandlePositionNotifier extends StateNotifier<double> {
  static const _key = 'edge_handle_position';

  EdgeHandlePositionNotifier() : super(0.3) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getDouble(_key);
      if (value != null) {
        state = value.clamp(0.0, 1.0);
      }
    } catch (e) {
      debugPrint('Error loading edge handle position: $e');
    }
  }

  Future<void> setPosition(double value) async {
    state = value.clamp(0.0, 1.0);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_key, state);
    } catch (e) {
      debugPrint('Error saving edge handle position: $e');
    }
  }
}

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
          // Main content with guest/offline banners
          Positioned.fill(
            child: Column(
              children: [
                // Guest mode banner at top
                if (isGuestMode)
                  _GuestModeBanner(isDark: isDark),
                // Offline banner (auto-shows/hides based on connectivity)
                const OfflineBanner(),
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
          // Samsung-style edge handle for AI Coach access
          _EdgePanelHandle(
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

/// Samsung Edge Panel style handle for AI Coach access
/// A subtle, semi-transparent vertical bar on the right edge.
/// Tap or swipe left to open AI Coach. Draggable vertically.
class _EdgePanelHandle extends ConsumerStatefulWidget {
  final VoidCallback onTap;

  const _EdgePanelHandle({required this.onTap});

  @override
  ConsumerState<_EdgePanelHandle> createState() => _EdgePanelHandleState();
}

class _EdgePanelHandleState extends ConsumerState<_EdgePanelHandle> {
  double _verticalPosition = 0.3; // 0.0 = top, 1.0 = bottom
  bool _isDragging = false;
  double _horizontalDragDistance = 0;

  @override
  void initState() {
    super.initState();
    // Load saved position after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _verticalPosition = ref.read(edgeHandlePositionProvider);
      });
    });
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _horizontalDragDistance = 0;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    // Track horizontal drag for swipe detection
    _horizontalDragDistance += details.delta.dx;

    // Update vertical position
    final screenHeight = MediaQuery.of(context).size.height;
    final safeTop = MediaQuery.of(context).padding.top + 100;
    const safeBottom = 180; // Above nav bar
    final usableHeight = screenHeight - safeTop - safeBottom;

    setState(() {
      _verticalPosition += details.delta.dy / usableHeight;
      _verticalPosition = _verticalPosition.clamp(0.0, 1.0);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() => _isDragging = false);

    // Check for swipe left gesture (negative horizontal distance or velocity)
    final horizontalVelocity = details.velocity.pixelsPerSecond.dx;
    if (_horizontalDragDistance < -30 || horizontalVelocity < -200) {
      // Swiped left - open AI Coach
      widget.onTap();
    }

    // Save position (persisted to SharedPreferences)
    ref.read(edgeHandlePositionProvider.notifier).setPosition(_verticalPosition);
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = ref.watch(edgeHandleEnabledProvider);
    final isNavBarVisible = ref.watch(floatingNavBarVisibleProvider);

    // Don't show if disabled or nav bar is hidden (e.g., bottom sheet open)
    if (!isEnabled || !isNavBarVisible) {
      return const SizedBox.shrink();
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final safeTop = MediaQuery.of(context).padding.top + 100;
    const safeBottom = 180;
    final usableHeight = screenHeight - safeTop - safeBottom;
    final topOffset = safeTop + (usableHeight * _verticalPosition);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      right: 0,
      top: topOffset,
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          // Larger touch area (24px) for easier interaction
          width: 24,
          height: 80,
          alignment: Alignment.centerRight,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: _isDragging ? 16 : 10,
            height: 44,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: _isDragging ? 0.4 : 0.2)
                  : Colors.black.withValues(alpha: _isDragging ? 0.3 : 0.15),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                bottomLeft: Radius.circular(6),
              ),
            ),
            child: Center(
              child: Icon(
                Icons.chevron_left,
                size: _isDragging ? 14 : 10,
                color: isDark
                    ? Colors.white.withValues(alpha: _isDragging ? 0.7 : 0.5)
                    : Colors.black.withValues(alpha: _isDragging ? 0.5 : 0.3),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Minimal floating nav bar - expandable items show label when selected
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
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Get dynamic accent color from provider
    final accentColor = ref.colors(context).accent;

    // Compact nav bar dimensions
    const navBarHeight = 52.0;
    const fadeHeight = 36.0;

    // Clean pill bar colors
    final pillBarColor = isDark
        ? Colors.grey.shade900.withValues(alpha: 0.92)
        : Colors.grey.shade100.withValues(alpha: 0.95);

    final iconMuted = isDark
        ? Colors.grey.shade500
        : Colors.grey.shade400;

    return SizedBox(
      height: navBarHeight + bottomPadding + fadeHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Subtle fade gradient
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
                      backgroundColor.withValues(alpha: 0.0),
                      backgroundColor.withValues(alpha: 0.9),
                      backgroundColor,
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // Centered compact pill nav bar
          Positioned(
            left: 20,
            right: 20,
            bottom: bottomPadding + 10,
            child: Container(
              height: navBarHeight,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: pillBarColor,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _ExpandableNavItem(
                    icon: Icons.home_outlined,
                    selectedIcon: Icons.home_rounded,
                    label: 'Home',
                    isSelected: selectedIndex == 0,
                    onTap: () => onItemTapped(0),
                    accentColor: accentColor,
                    mutedColor: iconMuted,
                    isDark: isDark,
                  ),
                  _ExpandableNavItem(
                    icon: Icons.fitness_center_outlined,
                    selectedIcon: Icons.fitness_center,
                    label: 'Workout',
                    isSelected: selectedIndex == 1,
                    onTap: () => onItemTapped(1),
                    accentColor: accentColor,
                    mutedColor: iconMuted,
                    isDark: isDark,
                  ),
                  _ExpandableNavItem(
                    icon: Icons.restaurant_outlined,
                    selectedIcon: Icons.restaurant,
                    label: 'Nutrition',
                    isSelected: selectedIndex == 2,
                    onTap: () => onItemTapped(2),
                    accentColor: accentColor,
                    mutedColor: iconMuted,
                    isDark: isDark,
                  ),
                  _ExpandableNavItem(
                    icon: Icons.public_outlined,
                    selectedIcon: Icons.public,
                    label: 'Social',
                    isSelected: selectedIndex == 3,
                    onTap: () => onItemTapped(3),
                    accentColor: accentColor,
                    mutedColor: iconMuted,
                    isDark: isDark,
                  ),
                  _ExpandableNavItem(
                    icon: Icons.person_outline,
                    selectedIcon: Icons.person,
                    label: 'Profile',
                    isSelected: selectedIndex == 4,
                    onTap: () => onItemTapped(4),
                    accentColor: accentColor,
                    mutedColor: iconMuted,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Expandable nav item - shows icon only when unselected, icon + label when selected
class _ExpandableNavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color accentColor;
  final Color mutedColor;
  final bool isDark;

  const _ExpandableNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.accentColor,
    required this.mutedColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Background pill color when selected
    final selectedBgColor = accentColor.withValues(alpha: isDark ? 0.15 : 0.12);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 14 : 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? selectedBgColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              color: isSelected ? accentColor : mutedColor,
              size: 22,
            ),
            // Animated label that expands when selected
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: isSelected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: accentColor,
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
        child: Container(
          height: itemHeight,
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                isSelected ? selectedIcon : icon,
                color: activeColor,
                size: 22,
              ),
              // Only show label when selected
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child: isSelected
                    ? Padding(
                        padding: const EdgeInsets.only(left: 5),
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
