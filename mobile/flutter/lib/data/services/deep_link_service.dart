import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_widget/home_widget.dart';
import '../../navigation/app_router.dart';

/// Service for handling deep links from home screen widgets.
///
/// Supports the following deep link schemes:
/// - aifitnesscoach://workout/{id} - Open workout detail
/// - aifitnesscoach://workout/start/{id} - Start workout immediately
/// - aifitnesscoach://hydration/add?amount={ml} - Quick add water
/// - aifitnesscoach://nutrition/log?meal={type}&mode={input} - Log food
/// - aifitnesscoach://chat?prompt={text}&agent={type} - Open chat
/// - aifitnesscoach://challenges - Open challenges
/// - aifitnesscoach://achievements - Open achievements
/// - aifitnesscoach://goals - Open personal goals
/// - aifitnesscoach://schedule - Open calendar
/// - aifitnesscoach://stats - Open stats dashboard
/// - aifitnesscoach://social/share?type={workout|achievement} - Share
class DeepLinkService {
  static const String scheme = 'aifitnesscoach';

  /// Initialize deep link listening from home widgets
  static void initialize(WidgetRef ref) {
    // Listen for widget clicks when app is already running
    HomeWidget.widgetClicked.listen((uri) {
      if (uri != null) {
        handleDeepLink(uri, ref);
      }
    });

    // Check if app was launched from widget click
    HomeWidget.initiallyLaunchedFromHomeWidget().then((uri) {
      if (uri != null) {
        // Small delay to ensure router is ready
        Future.delayed(const Duration(milliseconds: 500), () {
          handleDeepLink(uri, ref);
        });
      }
    });
  }

  /// Handle a deep link URI and navigate appropriately
  static void handleDeepLink(Uri uri, WidgetRef ref) {
    if (uri.scheme != scheme) {
      debugPrint('DeepLinkService: Invalid scheme ${uri.scheme}');
      return;
    }

    final router = ref.read(routerProvider);
    final path = uri.host + uri.path;
    final queryParams = uri.queryParameters;

    debugPrint('DeepLinkService: Handling deep link - path: $path, params: $queryParams');

    switch (path) {
      // Workout routes
      case String p when p.startsWith('workout/start/'):
        final workoutId = p.replaceFirst('workout/start/', '');
        _navigateToStartWorkout(router, workoutId, ref);
        break;

      case String p when p.startsWith('workout/'):
        final workoutId = p.replaceFirst('workout/', '');
        router.go('/workout/$workoutId');
        break;

      case 'workout':
        router.go('/home');
        break;

      // Hydration routes
      case 'hydration/add':
        final amount = int.tryParse(queryParams['amount'] ?? '') ?? 250;
        _quickAddWater(amount, ref);
        router.go('/hydration');
        break;

      case 'hydration':
        router.go('/hydration');
        break;

      // Nutrition routes
      case 'nutrition/log':
        final meal = queryParams['meal'] ?? 'snack';
        final mode = queryParams['mode'] ?? 'text';
        _openFoodLogger(router, meal, mode);
        break;

      case 'nutrition':
        router.go('/nutrition');
        break;

      // Chat routes
      case 'chat':
        final prompt = queryParams['prompt'];
        final agent = queryParams['agent'];
        _openChat(router, prompt: prompt, agent: agent);
        break;

      // Other screens
      case 'challenges':
        router.go('/social'); // Challenges are in social tab
        break;

      case 'achievements':
        router.go('/achievements');
        break;

      case 'goals':
        router.go('/personal-goals');
        break;

      case 'schedule':
        router.go('/schedule');
        break;

      case 'stats':
        router.go('/stats');
        break;

      case 'social':
        router.go('/social');
        break;

      case 'social/share':
        final shareType = queryParams['type'] ?? 'workout';
        _openShareSheet(router, shareType);
        break;

      default:
        debugPrint('DeepLinkService: Unknown path $path, going home');
        router.go('/home');
    }
  }

  /// Navigate to workout detail and optionally start it
  static void _navigateToStartWorkout(GoRouter router, String workoutId, WidgetRef ref) {
    // First navigate to workout detail
    router.go('/workout/$workoutId');
    // The workout detail screen will have a "Start" button
    // For auto-start, we could emit an event or use a provider
    debugPrint('DeepLinkService: Navigating to start workout $workoutId');
  }

  /// Quick add water amount
  static void _quickAddWater(int amountMl, WidgetRef ref) {
    // This would trigger the hydration provider to add water
    debugPrint('DeepLinkService: Quick adding ${amountMl}ml water');
    // TODO: Call hydration repository to add water
    // ref.read(hydrationRepositoryProvider).addWater(amountMl);
  }

  /// Open food logger with specific meal and input mode
  static void _openFoodLogger(GoRouter router, String meal, String mode) {
    debugPrint('DeepLinkService: Opening food logger for $meal via $mode');
    // Navigate to nutrition screen
    // The mode could be: text, photo, barcode, saved
    router.go('/nutrition');
    // TODO: Trigger specific input mode via a provider
  }

  /// Open chat screen with optional prompt or agent
  static void _openChat(GoRouter router, {String? prompt, String? agent}) {
    debugPrint('DeepLinkService: Opening chat with prompt=$prompt, agent=$agent');
    // Navigate to chat - could pass prompt/agent via extra
    router.go('/chat');
    // TODO: Pass prompt to chat screen to pre-fill or auto-send
  }

  /// Open share sheet for specific content type
  static void _openShareSheet(GoRouter router, String shareType) {
    debugPrint('DeepLinkService: Opening share sheet for $shareType');
    router.go('/social');
    // TODO: Trigger share sheet via provider
  }

  /// Build a deep link URI for a specific action
  static Uri buildUri(String path, {Map<String, String>? queryParams}) {
    return Uri(
      scheme: scheme,
      host: path.split('/').first,
      path: path.contains('/') ? '/${path.split('/').skip(1).join('/')}' : null,
      queryParameters: queryParams?.isNotEmpty == true ? queryParams : null,
    );
  }
}

/// Provider for deep link service initialization
final deepLinkServiceProvider = Provider<void>((ref) {
  // This is intentionally empty - initialization happens in main.dart
  return;
});
