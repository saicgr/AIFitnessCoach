import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/theme_provider.dart';
import '../../navigation/app_router.dart';
import '../models/chat_message.dart';
import '../models/workout.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import 'workout_repository.dart';
import 'auth_repository.dart';

/// Chat repository provider
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ChatRepository(apiClient);
});

/// Chat messages provider - now includes workout context, settings control, and navigation
final chatMessagesProvider =
    StateNotifierProvider<ChatMessagesNotifier, AsyncValue<List<ChatMessage>>>(
        (ref) {
  final repository = ref.watch(chatRepositoryProvider);
  final apiClient = ref.watch(apiClientProvider);
  final workoutsNotifier = ref.watch(workoutsProvider.notifier);
  final authState = ref.watch(authStateProvider);
  final themeNotifier = ref.watch(themeModeProvider.notifier);
  final router = ref.watch(routerProvider);
  return ChatMessagesNotifier(repository, apiClient, workoutsNotifier, authState.user, themeNotifier, router);
});

/// Chat repository for API calls
class ChatRepository {
  final ApiClient _apiClient;

  ChatRepository(this._apiClient);

  /// Get chat history
  Future<List<ChatMessage>> getChatHistory(String userId, {int limit = 100}) async {
    try {
      debugPrint('🔍 [Chat] Fetching chat history for user: $userId');
      final response = await _apiClient.get(
        '${ApiConstants.chat}/history/$userId',
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List;
        final messages = data.map((json) {
          final item = ChatHistoryItem.fromJson(json as Map<String, dynamic>);
          return item.toChatMessage();
        }).toList();
        debugPrint('✅ [Chat] Fetched ${messages.length} messages');
        return messages;
      }
      return [];
    } catch (e) {
      debugPrint('❌ [Chat] Error fetching chat history: $e');
      rethrow;
    }
  }

  /// Send a message to the AI coach
  Future<ChatResponse> sendMessage({
    required String message,
    required String userId,
    Map<String, dynamic>? userProfile,
    Map<String, dynamic>? currentWorkout,
    Map<String, dynamic>? workoutSchedule,
    List<Map<String, dynamic>>? conversationHistory,
  }) async {
    try {
      debugPrint('🔍 [Chat] Sending message: ${message.substring(0, message.length.clamp(0, 50))}...');

      final response = await _apiClient.post(
        '${ApiConstants.chat}/send',
        data: ChatRequest(
          message: message,
          userId: userId,
          userProfile: userProfile,
          currentWorkout: currentWorkout,
          workoutSchedule: workoutSchedule,
          conversationHistory: conversationHistory,
        ).toJson(),
      );

      if (response.statusCode == 200) {
        final chatResponse = ChatResponse.fromJson(response.data as Map<String, dynamic>);
        debugPrint('✅ [Chat] Got response with intent: ${chatResponse.intent}');
        return chatResponse;
      }
      throw Exception('Failed to send message');
    } catch (e) {
      debugPrint('❌ [Chat] Error sending message: $e');
      rethrow;
    }
  }
}

/// Chat messages state notifier
class ChatMessagesNotifier extends StateNotifier<AsyncValue<List<ChatMessage>>> {
  final ChatRepository _repository;
  final ApiClient _apiClient;
  final WorkoutsNotifier _workoutsNotifier;
  final User? _user;
  final ThemeModeNotifier _themeNotifier;
  final GoRouter _router;
  bool _isLoading = false;

  ChatMessagesNotifier(this._repository, this._apiClient, this._workoutsNotifier, this._user, this._themeNotifier, this._router)
      : super(const AsyncValue.data([]));

  bool get isLoading => _isLoading;

  /// Load chat history
  /// If force is false, only loads if there are no messages yet
  Future<void> loadHistory({bool force = false}) async {
    // Skip loading if we already have messages and not forcing
    final currentMessages = state.valueOrNull;
    if (!force && currentMessages != null && currentMessages.isNotEmpty) {
      debugPrint('🔍 [Chat] Skipping history load - already have ${currentMessages.length} messages');
      return;
    }

    final userId = await _apiClient.getUserId();
    if (userId == null) return;

    state = const AsyncValue.loading();
    try {
      final messages = await _repository.getChatHistory(userId);
      state = AsyncValue.data(messages);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Send a message
  Future<void> sendMessage(String message) async {
    if (_isLoading) return;

    final userId = await _apiClient.getUserId();
    if (userId == null) return;

    final currentMessages = state.valueOrNull ?? [];

    // Add user message immediately
    final userMessage = ChatMessage(
      role: 'user',
      content: message,
      createdAt: DateTime.now().toIso8601String(),
    );
    state = AsyncValue.data([...currentMessages, userMessage]);

    _isLoading = true;

    try {
      // Build conversation history for context
      final history = currentMessages.map((m) => {
        'role': m.role,
        'content': m.content,
      }).toList();

      // Build user profile context (matches backend UserProfile model)
      Map<String, dynamic>? userProfile;
      if (_user != null) {
        final user = _user!;
        userProfile = {
          'id': user.id,  // Required by backend
          'fitness_level': user.fitnessLevel ?? 'beginner',
          'goals': user.goalsList,
          'equipment': user.equipmentList,
          'active_injuries': user.injuriesList,
        };
        debugPrint('🤖 [Chat] Sending user profile context: $userProfile');
      }

      // Build current workout context (matches backend WorkoutContext model)
      Map<String, dynamic>? currentWorkout;
      final nextWorkout = _workoutsNotifier.nextWorkout;
      if (nextWorkout != null) {
        final exercisesList = nextWorkout.exercises?.map((e) {
          return <String, dynamic>{
            'name': e.name,
            'sets': e.sets,
            'reps': e.reps,
            'duration_seconds': e.durationSeconds,
            'muscle_group': e.muscleGroup,
            'equipment': e.equipment,
          };
        }).toList() ?? <Map<String, dynamic>>[];

        currentWorkout = {
          'id': nextWorkout.id is int ? nextWorkout.id : int.tryParse(nextWorkout.id.toString()) ?? 0,
          'name': nextWorkout.name ?? 'Workout',
          'type': nextWorkout.type ?? 'strength',
          'difficulty': nextWorkout.difficulty ?? 'intermediate',
          'scheduled_date': nextWorkout.scheduledDate,
          'is_completed': nextWorkout.isCompleted ?? false,
          'exercises': exercisesList,
        };
        debugPrint('🤖 [Chat] Sending current workout context: ${nextWorkout.name} with ${exercisesList.length} exercises');
      }

      // Build workout schedule context (matches backend WorkoutScheduleContext)
      Map<String, dynamic>? workoutSchedule;
      final upcoming = _workoutsNotifier.upcomingWorkouts;
      // Only send schedule if we have today's workout
      if (nextWorkout != null) {
        final thisWeekWorkouts = upcoming.take(5).map((w) {
          return <String, dynamic>{
            'id': w.id is int ? w.id : int.tryParse(w.id.toString()) ?? 0,
            'name': w.name ?? 'Workout',
            'type': w.type ?? 'strength',
            'difficulty': w.difficulty ?? 'intermediate',
            'scheduled_date': w.scheduledDate,
            'is_completed': w.isCompleted ?? false,
            'exercises': <Map<String, dynamic>>[],
          };
        }).toList();

        workoutSchedule = {
          'today': currentWorkout,
          'thisWeek': thisWeekWorkouts,
          'recentCompleted': <Map<String, dynamic>>[],
        };
      }

      final response = await _repository.sendMessage(
        message: message,
        userId: userId,
        userProfile: userProfile,
        currentWorkout: currentWorkout,
        workoutSchedule: workoutSchedule,
        conversationHistory: history,
      );

      // Process action_data if present
      _processActionData(response.actionData);

      // Add assistant response
      final assistantMessage = ChatMessage(
        role: 'assistant',
        content: response.message,
        intent: response.intent,
        createdAt: DateTime.now().toIso8601String(),
      );

      final updatedMessages = state.valueOrNull ?? [];
      state = AsyncValue.data([...updatedMessages, assistantMessage]);
    } catch (e) {
      // Add error message
      final errorMessage = ChatMessage(
        role: 'assistant',
        content: 'Sorry, I encountered an error. Please try again.',
        createdAt: DateTime.now().toIso8601String(),
      );
      final updatedMessages = state.valueOrNull ?? [];
      state = AsyncValue.data([...updatedMessages, errorMessage]);
    } finally {
      _isLoading = false;
    }
  }

  /// Clear messages
  void clear() {
    state = const AsyncValue.data([]);
  }

  /// Clear history (alias for clear)
  void clearHistory() {
    clear();
  }

  /// Process action_data from AI response
  void _processActionData(Map<String, dynamic>? actionData) {
    if (actionData == null) return;

    final action = actionData['action'] as String?;
    debugPrint('🤖 [Chat] Processing action_data: $action');

    switch (action) {
      case 'change_setting':
        _handleSettingChange(actionData);
        break;
      case 'navigate':
        _handleNavigation(actionData);
        break;
      default:
        debugPrint('🤖 [Chat] Unknown action: $action');
    }
  }

  /// Handle app setting changes from AI
  void _handleSettingChange(Map<String, dynamic> actionData) {
    final settingName = actionData['setting_name'] as String?;
    final settingValue = actionData['setting_value'] as bool?;

    debugPrint('🤖 [Chat] Changing setting: $settingName = $settingValue');

    switch (settingName) {
      case 'dark_mode':
        if (settingValue == true) {
          _themeNotifier.setTheme(ThemeMode.dark);
          debugPrint('🌙 [Chat] Dark mode enabled via AI');
        } else if (settingValue == false) {
          _themeNotifier.setTheme(ThemeMode.light);
          debugPrint('☀️ [Chat] Light mode enabled via AI');
        }
        break;
      case 'notifications':
        // TODO: Implement notification toggle when needed
        debugPrint('🔔 [Chat] Notifications setting change requested: $settingValue');
        break;
      default:
        debugPrint('🤖 [Chat] Unknown setting: $settingName');
    }
  }

  /// Handle navigation from AI
  void _handleNavigation(Map<String, dynamic> actionData) {
    final destination = actionData['destination'] as String?;
    debugPrint('🧭 [Chat] Navigating to: $destination');

    // Map destination names to routes
    final routes = {
      'home': '/home',
      'library': '/library',
      'profile': '/profile',
      'achievements': '/achievements',
      'hydration': '/hydration',
      'nutrition': '/nutrition',
      'summaries': '/summaries',
    };

    final route = routes[destination];
    if (route != null) {
      // Use go for main tabs, push for nested screens
      if (['home', 'library', 'profile'].contains(destination)) {
        _router.go(route);
      } else {
        _router.push(route);
      }
      debugPrint('🧭 [Chat] Navigated to $route');
    } else {
      debugPrint('🧭 [Chat] Unknown destination: $destination');
    }
  }
}
