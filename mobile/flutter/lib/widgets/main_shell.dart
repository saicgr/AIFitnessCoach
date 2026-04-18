import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_colors.dart';
import '../core/providers/subscription_provider.dart';
import '../data/services/recipe_notification_router.dart';
import '../core/theme/theme_colors.dart';
import '../data/models/coach_persona.dart';
import '../data/providers/admin_provider.dart';
import '../data/providers/guest_mode_provider.dart';
import '../data/providers/guest_usage_limits_provider.dart';
import '../data/services/deep_link_service.dart';
import '../data/services/widget_action_service.dart';
import '../screens/ai_settings/ai_settings_screen.dart';
import '../screens/nutrition/quick_log_overlay.dart';
import '../screens/workout/widgets/quick_workout_sheet.dart';
import 'coach_avatar.dart';
import 'app_tour/app_tour_controller.dart';
import 'app_tour/app_tour_overlay.dart';
import 'floating_chat/floating_chat_bubble.dart';
import 'floating_chat/floating_chat_overlay.dart';
import 'level_up_dialog.dart';
import 'streak_saved_dialog.dart';
import 'morphing_tab_indicator.dart';
import 'offline_banner.dart';
import '../data/providers/xp_provider.dart' show xpProvider, levelUpEventProvider, dailyLoginResultProvider;
import '../data/models/xp_event.dart' show DailyLoginResult;
import '../data/models/user_xp.dart';
import '../core/accessibility/accessibility_provider.dart';

part 'main_shell_part_edge_panel_handle.dart';
part 'main_shell_part_guest_mode_banner.dart';


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

  EdgeHandleEnabledNotifier() : super(false) {
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
  /// StatefulNavigationShell for the main tab navigation (keeps tabs alive).
  final StatefulNavigationShell? navigationShell;

  /// Fallback child widget for non-tab usages (e.g. progress_screen wrapping).
  final Widget? child;

  const MainShell({super.key, this.navigationShell, this.child})
      : assert(navigationShell != null || child != null,
            'Either navigationShell or child must be provided');

  /// The widget to display as the main content area.
  Widget get _child => navigationShell ?? child!;

  int _calculateSelectedIndex(BuildContext context) {
    if (navigationShell != null) return navigationShell!.currentIndex;
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/workouts')) return 1;
    if (location.startsWith('/nutrition')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  bool _isSecondaryPage(BuildContext context) {
    final fullPath = GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
    return fullPath.startsWith('/fasting');
  }

  void _onItemTapped(BuildContext context, int index) {
    if (navigationShell != null) {
      navigationShell!.goBranch(index, initialLocation: index == navigationShell!.currentIndex);
      return;
    }
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

    // Consume any pending meal-reminder notification action (set by the FCM
    // handler in notification_service_ext._handleMessageOpenedApp). No-op if
    // nothing pending; clears itself after first consumption.
    if (RecipeNotificationRouter.pending != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          RecipeNotificationRouter.consume(context, ref);
        }
      });
    }

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

    // Hard-lock paywall: redirect to /hard-paywall when subscription lapses
    ref.listen(
      subscriptionProvider.select((s) => s.tier),
      (previous, currentTier) {
        if (currentTier == SubscriptionTier.free && context.mounted) {
          // Check if user previously completed paywall (had a trial/sub that lapsed)
          ref.read(subscriptionProvider.notifier).checkIsHardLocked().then((isLocked) {
            if (isLocked && context.mounted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  context.go('/hard-paywall');
                }
              });
            }
          });
        }
      },
    );

    // Listen for level-up events from ANY screen (moved from home_screen.dart)
    ref.listen<LevelUpEvent?>(levelUpEventProvider, (previous, next) {
      if (next != null && previous == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            final showProg = ref.read(accessibilityProvider).showLevelUpProgression;
            showLevelUpDialog(
              context,
              next,
              () {
                ref.read(xpProvider.notifier).clearLevelUp();
              },
              showProgression: showProg,
            );
          }
        });
      }
    });

    // Listen for streak-saved events (migration 1938 / W3).
    // Fires once when daily-login response flags that a Streak Shield was
    // auto-consumed to protect the streak. Celebrates the save instead of
    // silently swallowing it.
    ref.listen<DailyLoginResult?>(dailyLoginResultProvider, (previous, next) {
      if (next == null) return;
      final wasAlreadyShown = previous?.streakSavedByShield == true;
      if (next.streakSavedByShield && !wasAlreadyShown) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            showStreakSavedDialog(
              context,
              savedStreakCount: next.savedStreakCount > 0
                  ? next.savedStreakCount
                  : next.currentStreak,
              shieldsRemaining: next.shieldsRemaining,
            );
          }
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
                Expanded(child: _child),
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
          // Floating AI Chat bubble (toggled in Settings > AI Coach)
          if (ref.watch(edgeHandleEnabledProvider))
            const FloatingChatBubble(),
          // App tour overlay (topmost)
          const AppTourOverlay(),
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
