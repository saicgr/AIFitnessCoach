import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/personal_goals_service.dart';
import '../services/goal_social_service.dart';
import '../services/api_client.dart';

// ============================================================
// SERVICE PROVIDERS
// ============================================================

/// Personal goals service provider
final personalGoalsServiceProvider = Provider<PersonalGoalsService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PersonalGoalsService(apiClient);
});

/// Goal social service provider
final goalSocialServiceProvider = Provider<GoalSocialService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return GoalSocialService(apiClient);
});

// ============================================================
// GOAL SUGGESTIONS PROVIDERS
// ============================================================

/// Goal suggestions provider (cached for 24h)
final goalSuggestionsProvider = FutureProvider.autoDispose.family<GoalSuggestionsResponse, GoalSuggestionsParams>(
  (ref, params) async {
    final service = ref.watch(personalGoalsServiceProvider);
    return await service.getGoalSuggestions(
      userId: params.userId,
      forceRefresh: params.forceRefresh,
    );
  },
);

/// Suggestions summary provider (lightweight)
final suggestionsSummaryProvider = FutureProvider.autoDispose.family<GoalSuggestionsSummary, String>(
  (ref, userId) async {
    final service = ref.watch(personalGoalsServiceProvider);
    return await service.getSuggestionsSummary(userId: userId);
  },
);

/// Current goals provider
final currentGoalsProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>(
  (ref, userId) async {
    final service = ref.watch(personalGoalsServiceProvider);
    return await service.getCurrentGoals(userId: userId);
  },
);

/// Goals summary provider
final goalsSummaryProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>(
  (ref, userId) async {
    final service = ref.watch(personalGoalsServiceProvider);
    return await service.getSummary(userId: userId);
  },
);

/// Personal records provider
final personalRecordsProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>(
  (ref, userId) async {
    final service = ref.watch(personalGoalsServiceProvider);
    return await service.getPersonalRecords(userId: userId);
  },
);

// ============================================================
// GOAL SOCIAL PROVIDERS
// ============================================================

/// Goal friends (leaderboard) provider
final goalFriendsProvider = FutureProvider.autoDispose.family<GoalFriendsResponse, GoalFriendsParams>(
  (ref, params) async {
    final service = ref.watch(goalSocialServiceProvider);
    return await service.getGoalFriends(
      userId: params.userId,
      goalId: params.goalId,
    );
  },
);

/// Pending goal invites provider
final goalInvitesProvider = FutureProvider.autoDispose.family<List<GoalInviteWithDetails>, String>(
  (ref, userId) async {
    final service = ref.watch(goalSocialServiceProvider);
    return await service.getGoalInvites(userId: userId);
  },
);

/// Pending invites count provider (for badge)
final pendingInvitesCountProvider = FutureProvider.autoDispose.family<int, String>(
  (ref, userId) async {
    final service = ref.watch(goalSocialServiceProvider);
    return await service.getPendingInvitesCount(userId: userId);
  },
);

// ============================================================
// STATE NOTIFIER FOR SELECTED SUGGESTION
// ============================================================

/// Currently selected suggestion state
class SelectedSuggestionNotifier extends StateNotifier<GoalSuggestionItem?> {
  SelectedSuggestionNotifier() : super(null);

  void select(GoalSuggestionItem suggestion) {
    state = suggestion;
  }

  void clear() {
    state = null;
  }
}

final selectedSuggestionProvider = StateNotifierProvider<SelectedSuggestionNotifier, GoalSuggestionItem?>(
  (ref) => SelectedSuggestionNotifier(),
);

// ============================================================
// PARAMETER CLASSES
// ============================================================

/// Parameters for goal suggestions
class GoalSuggestionsParams {
  final String userId;
  final bool forceRefresh;

  GoalSuggestionsParams({
    required this.userId,
    this.forceRefresh = false,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GoalSuggestionsParams &&
        other.userId == userId &&
        other.forceRefresh == forceRefresh;
  }

  @override
  int get hashCode => userId.hashCode ^ forceRefresh.hashCode;
}

/// Parameters for goal friends
class GoalFriendsParams {
  final String userId;
  final String goalId;

  GoalFriendsParams({
    required this.userId,
    required this.goalId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GoalFriendsParams &&
        other.userId == userId &&
        other.goalId == goalId;
  }

  @override
  int get hashCode => userId.hashCode ^ goalId.hashCode;
}

/// Parameters for goal history
class GoalHistoryParams {
  final String userId;
  final String exerciseName;
  final PersonalGoalType goalType;

  GoalHistoryParams({
    required this.userId,
    required this.exerciseName,
    required this.goalType,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GoalHistoryParams &&
        other.userId == userId &&
        other.exerciseName == exerciseName &&
        other.goalType == goalType;
  }

  @override
  int get hashCode => userId.hashCode ^ exerciseName.hashCode ^ goalType.hashCode;
}

/// Goal history provider
final goalHistoryProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, GoalHistoryParams>(
  (ref, params) async {
    final service = ref.watch(personalGoalsServiceProvider);
    return await service.getGoalHistory(
      userId: params.userId,
      exerciseName: params.exerciseName,
      goalType: params.goalType,
    );
  },
);
