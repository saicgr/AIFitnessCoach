import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_widget/home_widget.dart';
import '../../navigation/app_router.dart';

/// Service for handling deep links from home screen widgets.
///
/// Supports the following deep link schemes:
/// - fitwiz://workout/{id} - Open workout detail
/// - fitwiz://workout/start/{id} - Start workout immediately
/// - fitwiz://hydration/add?amount={ml} - Quick add water
/// - fitwiz://nutrition/log?meal={type}&mode={input} - Log food
/// - fitwiz://chat?prompt={text}&agent={type} - Open chat
/// - fitwiz://challenges - Open challenges
/// - fitwiz://achievements - Open achievements
/// - fitwiz://goals - Open personal goals
/// - fitwiz://schedule - Open calendar
/// - fitwiz://stats - Open stats dashboard
/// - fitwiz://social/share?type={workout|achievement} - Share
class DeepLinkService {
  static const String scheme = 'fitwiz';

  /// Validate UUID format for IDs
  static bool _isValidUuid(String value) {
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    return uuidRegex.hasMatch(value);
  }

  /// Validate numeric range
  static bool _isValidNumericRange(String value, {int min = 0, int max = 10000}) {
    final num = int.tryParse(value);
    return num != null && num >= min && num <= max;
  }

  /// Sanitize text input
  static String _sanitizeText(String text, {int maxLength = 500}) {
    final cleaned = text.replaceAll(RegExp(r'[<>\"\\]'), '');
    return cleaned.substring(0, cleaned.length.clamp(0, maxLength));
  }

  static const List<String> _validMealTypes = ['breakfast', 'lunch', 'dinner', 'snack'];
  static const List<String> _validInputModes = ['text', 'photo', 'barcode', 'saved'];
  static const List<String> _validAgentTypes = ['coach', 'nutrition', 'workout', 'injury', 'hydration'];

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
        if (!_isValidUuid(workoutId)) {
          debugPrint('DeepLinkService: Invalid workout UUID: $workoutId');
          return;
        }
        _navigateToStartWorkout(router, workoutId, ref);
        break;

      case String p when p.startsWith('workout/'):
        final workoutId = p.replaceFirst('workout/', '');
        if (!_isValidUuid(workoutId)) {
          debugPrint('DeepLinkService: Invalid workout UUID: $workoutId');
          return;
        }
        router.go('/workout/$workoutId');
        break;

      case 'workout':
      case 'workout/start':
        // Widget clicked "Start" button without specific workout ID
        // Go to home screen where user can see today's workout
        router.go('/home');
        break;

      // Hydration routes
      case 'hydration/add':
        final rawAmount = queryParams['amount'] ?? '250';
        if (!_isValidNumericRange(rawAmount, min: 1, max: 5000)) {
          debugPrint('DeepLinkService: Invalid hydration amount: $rawAmount');
          return;
        }
        final amount = int.parse(rawAmount);
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
        if (!_validMealTypes.contains(meal) || !_validInputModes.contains(mode)) {
          debugPrint('DeepLinkService: Invalid nutrition params: meal=$meal, mode=$mode');
          return;
        }
        _openFoodLogger(router, meal, mode);
        break;

      case 'nutrition':
        router.go('/nutrition');
        break;

      // Chat routes
      case 'chat':
        final rawPrompt = queryParams['prompt'];
        final agent = queryParams['agent'];
        if (agent != null && !_validAgentTypes.contains(agent)) {
          debugPrint('DeepLinkService: Invalid agent type: $agent');
          return;
        }
        final prompt = rawPrompt != null ? _sanitizeText(rawPrompt) : null;
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
        if (!const ['workout', 'achievement'].contains(shareType)) {
          debugPrint('DeepLinkService: Invalid share type: $shareType');
          return;
        }
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
    // Navigate to nutrition screen with meal param to auto-open log sheet
    router.go('/nutrition?meal=$meal');
  }

  /// Open chat screen with optional prompt or agent
  static void _openChat(GoRouter router, {String? prompt, String? agent}) {
    debugPrint('DeepLinkService: Opening chat with prompt=$prompt, agent=$agent');
    // Pass prompt via query parameter so the route extracts it
    final params = <String, String>{};
    if (prompt != null) params['prompt'] = Uri.encodeComponent(prompt);
    if (agent != null) params['agent'] = agent;
    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    router.go('/chat${query.isNotEmpty ? '?$query' : ''}');
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

/// Enum for pending widget actions that need UI interaction
enum PendingWidgetAction {
  none,
  showLogMealSheet,
  showAddWaterSheet,
  showShareSheet,
}

/// Provider to track pending widget actions that require showing a sheet/dialog
final pendingWidgetActionProvider = StateProvider<PendingWidgetAction>((ref) => PendingWidgetAction.none);
