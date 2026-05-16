import 'package:flutter/foundation.dart';
import 'api_client.dart';

/// Leaderboard type enum
enum LeaderboardType {
  challengeMasters('challenge_masters'),
  volumeKings('volume_kings'),
  streaks('streaks'),
  weeklyChallenges('weekly_challenges'),
  nutrientRush('nutrient_rush');

  final String value;
  const LeaderboardType(this.value);
}

/// Leaderboard filter enum
enum LeaderboardFilter {
  global('global'),
  country('country'),
  friends('friends');

  final String value;
  const LeaderboardFilter(this.value);
}

/// Service for leaderboard features
class LeaderboardService {
  final ApiClient _apiClient;

  LeaderboardService(this._apiClient);

  // ============================================================
  // GET LEADERBOARD
  // ============================================================

  /// Get leaderboard data with filtering and pagination
  Future<Map<String, dynamic>> getLeaderboard({
    required String userId,
    LeaderboardType leaderboardType = LeaderboardType.challengeMasters,
    LeaderboardFilter filterType = LeaderboardFilter.global,
    String? countryCode,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final queryParams = {
        'user_id': userId,
        'leaderboard_type': leaderboardType.value,
        'filter_type': filterType.value,
        'limit': limit.toString(),
        'offset': offset.toString(),
      };

      if (countryCode != null) {
        queryParams['country_code'] = countryCode;
      }

      final response = await _apiClient.get(
        '/leaderboard/',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Leaderboard] Fetched ${leaderboardType.value} leaderboard');
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get leaderboard: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Leaderboard] Error getting leaderboard: $e');
      rethrow;
    }
  }

  // ============================================================
  // GET USER RANK
  // ============================================================

  /// Get user's rank in specified leaderboard
  Future<Map<String, dynamic>> getUserRank({
    required String userId,
    LeaderboardType leaderboardType = LeaderboardType.challengeMasters,
    String? countryFilter,
  }) async {
    try {
      final queryParams = {
        'user_id': userId,
        'leaderboard_type': leaderboardType.value,
      };

      if (countryFilter != null) {
        queryParams['country_filter'] = countryFilter;
      }

      final response = await _apiClient.get(
        '/leaderboard/rank',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get user rank: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Leaderboard] Error getting user rank: $e');
      rethrow;
    }
  }

  // ============================================================
  // GET UNLOCK STATUS
  // ============================================================

  /// Check if user has unlocked global leaderboard
  Future<Map<String, dynamic>> getUnlockStatus({
    required String userId,
  }) async {
    try {
      final response = await _apiClient.get(
        '/leaderboard/unlock-status',
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get unlock status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Leaderboard] Error getting unlock status: $e');
      rethrow;
    }
  }

  // ============================================================
  // GET LEADERBOARD STATS
  // ============================================================

  /// Get overall leaderboard statistics
  Future<Map<String, dynamic>> getLeaderboardStats() async {
    try {
      final response = await _apiClient.get(
        '/leaderboard/stats',
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get leaderboard stats: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Leaderboard] Error getting leaderboard stats: $e');
      rethrow;
    }
  }

  // ============================================================
  // CREATE ASYNC CHALLENGE
  // ============================================================

  /// Create async 'Beat Their Best' challenge from leaderboard
  Future<Map<String, dynamic>> createAsyncChallenge({
    required String userId,
    required String targetUserId,
    String? workoutLogId,
    String challengeMessage = "I'm coming for your record! 💪",
  }) async {
    try {
      final response = await _apiClient.post(
        '/leaderboard/async-challenge',
        queryParameters: {'user_id': userId},
        data: {
          'target_user_id': targetUserId,
          if (workoutLogId != null) 'workout_log_id': workoutLogId,
          'challenge_message': challengeMessage,
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Leaderboard] Created async challenge to $targetUserId');
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to create async challenge: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Leaderboard] Error creating async challenge: $e');
      rethrow;
    }
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  /// Get country flag emoji from country code
  String getCountryFlag(String countryCode) {
    if (countryCode.length != 2) return '🌍';

    final int firstLetter = countryCode.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final int secondLetter = countryCode.codeUnitAt(1) - 0x41 + 0x1F1E6;

    return String.fromCharCode(firstLetter) + String.fromCharCode(secondLetter);
  }

  /// Get medal emoji for rank
  String getMedalEmoji(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '#$rank';
    }
  }

  /// Get leaderboard type display name
  String getLeaderboardDisplayName(LeaderboardType type) {
    switch (type) {
      case LeaderboardType.challengeMasters:
        return 'Challenge Masters';
      case LeaderboardType.volumeKings:
        return 'Volume Kings';
      case LeaderboardType.streaks:
        return 'Workout Streaks';
      case LeaderboardType.weeklyChallenges:
        return 'This Week';
      case LeaderboardType.nutrientRush:
        return 'Nutrient Rush';
    }
  }

  /// Get leaderboard type icon
  String getLeaderboardIcon(LeaderboardType type) {
    switch (type) {
      case LeaderboardType.challengeMasters:
        return '🏆';
      case LeaderboardType.volumeKings:
        return '🏋️';
      case LeaderboardType.streaks:
        return '🔥';
      case LeaderboardType.weeklyChallenges:
        return '⚡';
      case LeaderboardType.nutrientRush:
        return '🚀';
    }
  }

  // ============================================================
  // MINI-GAME SCORE (Nutrient Rush)
  // ============================================================

  /// Submit a mini-game run's final score.
  ///
  /// Called on EVERY game-over. The backend raises the stored personal best
  /// only when [score] is higher; every call still counts as a play.
  /// Returns the post-submission state: `{high_score, plays, is_new_best,
  /// submitted_score}`. Throws on network/server error.
  Future<Map<String, dynamic>> submitMinigameScore({
    required int score,
    String gameKey = 'nutrient_rush',
  }) async {
    try {
      final response = await _apiClient.post(
        '/leaderboard/minigame/score',
        data: {'score': score, 'game_key': gameKey},
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Leaderboard] Submitted minigame score: $score');
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to submit minigame score: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Leaderboard] Error submitting minigame score: $e');
      rethrow;
    }
  }

  /// Get the current user's persisted mini-game personal best.
  ///
  /// A user who has never played returns `high_score: 0, plays: 0`.
  Future<Map<String, dynamic>> getMinigameHighScore({
    String gameKey = 'nutrient_rush',
  }) async {
    try {
      final response = await _apiClient.get(
        '/leaderboard/minigame/high-score',
        queryParameters: {'game_key': gameKey},
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get minigame high score: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Leaderboard] Error getting minigame high score: $e');
      rethrow;
    }
  }
}
