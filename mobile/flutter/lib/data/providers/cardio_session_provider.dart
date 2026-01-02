import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cardio_session.dart';
import '../repositories/cardio_repository.dart';

// ============================================
// Cardio State
// ============================================

/// Cardio session state
class CardioState {
  final List<CardioSession> sessions;
  final List<CardioSession> recentSessions;
  final DailyCardioSummary? todaySummary;
  final CardioStats? stats;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const CardioState({
    this.sessions = const [],
    this.recentSessions = const [],
    this.todaySummary,
    this.stats,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  CardioState copyWith({
    List<CardioSession>? sessions,
    List<CardioSession>? recentSessions,
    DailyCardioSummary? todaySummary,
    CardioStats? stats,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) {
    return CardioState(
      sessions: sessions ?? this.sessions,
      recentSessions: recentSessions ?? this.recentSessions,
      todaySummary: todaySummary ?? this.todaySummary,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }

  /// Total sessions count
  int get totalSessions => sessions.length;

  /// Today's total duration
  int get todayDurationMinutes => todaySummary?.totalDurationMinutes ?? 0;

  /// Today's total distance
  double get todayDistanceKm => todaySummary?.totalDistanceKm ?? 0;

  /// Today's total calories
  int get todayCalories => todaySummary?.totalCalories ?? 0;
}

// ============================================
// Cardio Notifier
// ============================================

/// Cardio state notifier
class CardioNotifier extends StateNotifier<CardioState> {
  final CardioRepository _repository;

  CardioNotifier(this._repository) : super(const CardioState());

  /// Initialize cardio state for a user
  Future<void> initialize(String userId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      debugPrint('🏃 [CardioProvider] Initializing for $userId');

      // Load data in parallel
      final results = await Future.wait([
        _repository.getRecentSessions(userId, limit: 10).catchError((_) => <CardioSession>[]),
        _repository.getDailySummary(userId).catchError((_) => const DailyCardioSummary(date: '')),
        _repository.getStats(userId: userId).catchError((_) => CardioStats(userId: userId)),
      ]);

      state = state.copyWith(
        recentSessions: results[0] as List<CardioSession>,
        todaySummary: results[1] as DailyCardioSummary,
        stats: results[2] as CardioStats,
        isLoading: false,
      );

      debugPrint('✅ [CardioProvider] Initialized with ${state.recentSessions.length} recent sessions');
    } catch (e) {
      debugPrint('❌ [CardioProvider] Init error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Log a new cardio session
  Future<CardioSession?> logSession({
    required String userId,
    required CardioType cardioType,
    required CardioLocation location,
    required int durationMinutes,
    double? distanceKm,
    int? avgHeartRate,
    int? maxHeartRate,
    int? caloriesBurned,
    String? notes,
    WeatherCondition? weatherCondition,
    String? workoutId,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      debugPrint('🏃 [CardioProvider] Logging session: ${cardioType.label} at ${location.label}');

      // Calculate pace and speed if distance is provided
      final avgPacePerKm = CardioSession.calculatePace(distanceKm, durationMinutes);
      final avgSpeedKmh = CardioSession.calculateSpeed(distanceKm, durationMinutes);

      final session = await _repository.logSession(
        userId: userId,
        cardioType: cardioType.value,
        location: location.value,
        durationMinutes: durationMinutes,
        distanceKm: distanceKm,
        avgPacePerKm: avgPacePerKm,
        avgSpeedKmh: avgSpeedKmh,
        avgHeartRate: avgHeartRate,
        maxHeartRate: maxHeartRate,
        caloriesBurned: caloriesBurned,
        notes: notes,
        weatherConditions: weatherCondition?.value,
        workoutId: workoutId,
      );

      // Update state with new session
      final updatedRecent = [session, ...state.recentSessions];
      if (updatedRecent.length > 10) {
        updatedRecent.removeLast();
      }

      state = state.copyWith(
        recentSessions: updatedRecent,
        isSaving: false,
      );

      // Refresh summary and stats
      await _refreshSummary(userId);

      debugPrint('✅ [CardioProvider] Session logged');
      return session;
    } catch (e) {
      debugPrint('❌ [CardioProvider] Log session error: $e');
      state = state.copyWith(isSaving: false, error: e.toString());
      return null;
    }
  }

  /// Load sessions with optional filters
  Future<void> loadSessions({
    required String userId,
    int limit = 20,
    int offset = 0,
    CardioType? cardioType,
    CardioLocation? location,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final sessions = await _repository.getSessions(
        userId: userId,
        limit: limit,
        offset: offset,
        cardioType: cardioType?.value,
        location: location?.value,
        startDate: startDate,
        endDate: endDate,
      );
      state = state.copyWith(sessions: sessions, isLoading: false);
    } catch (e) {
      debugPrint('❌ [CardioProvider] Load sessions error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Update a cardio session
  Future<bool> updateSession({
    required String sessionId,
    CardioType? cardioType,
    CardioLocation? location,
    int? durationMinutes,
    double? distanceKm,
    int? avgHeartRate,
    int? maxHeartRate,
    int? caloriesBurned,
    String? notes,
    WeatherCondition? weatherCondition,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      // Calculate pace and speed if distance and duration provided
      double? avgPacePerKm;
      double? avgSpeedKmh;
      if (distanceKm != null && durationMinutes != null) {
        avgPacePerKm = CardioSession.calculatePace(distanceKm, durationMinutes);
        avgSpeedKmh = CardioSession.calculateSpeed(distanceKm, durationMinutes);
      }

      final updated = await _repository.updateSession(
        sessionId: sessionId,
        cardioType: cardioType?.value,
        location: location?.value,
        durationMinutes: durationMinutes,
        distanceKm: distanceKm,
        avgPacePerKm: avgPacePerKm,
        avgSpeedKmh: avgSpeedKmh,
        avgHeartRate: avgHeartRate,
        maxHeartRate: maxHeartRate,
        caloriesBurned: caloriesBurned,
        notes: notes,
        weatherConditions: weatherCondition?.value,
      );

      // Update in recent sessions
      final updatedRecent = state.recentSessions.map((s) {
        return s.id == sessionId ? updated : s;
      }).toList();

      // Update in all sessions
      final updatedSessions = state.sessions.map((s) {
        return s.id == sessionId ? updated : s;
      }).toList();

      state = state.copyWith(
        recentSessions: updatedRecent,
        sessions: updatedSessions,
        isSaving: false,
      );

      return true;
    } catch (e) {
      debugPrint('❌ [CardioProvider] Update session error: $e');
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  /// Delete a cardio session
  Future<bool> deleteSession(String userId, String sessionId) async {
    try {
      await _repository.deleteSession(sessionId);

      // Remove from state
      final updatedRecent = state.recentSessions
          .where((s) => s.id != sessionId)
          .toList();
      final updatedSessions = state.sessions
          .where((s) => s.id != sessionId)
          .toList();

      state = state.copyWith(
        recentSessions: updatedRecent,
        sessions: updatedSessions,
      );

      // Refresh summary
      await _refreshSummary(userId);

      return true;
    } catch (e) {
      debugPrint('❌ [CardioProvider] Delete session error: $e');
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Refresh today's summary
  Future<void> refreshTodaySummary(String userId) async {
    await _refreshSummary(userId);
  }

  /// Internal refresh summary
  Future<void> _refreshSummary(String userId) async {
    try {
      final summary = await _repository.getDailySummary(userId);
      state = state.copyWith(todaySummary: summary);
    } catch (e) {
      debugPrint('❌ [CardioProvider] Refresh summary error: $e');
    }
  }

  /// Refresh stats
  Future<void> refreshStats(String userId, {int days = 30}) async {
    try {
      final stats = await _repository.getStats(userId: userId, days: days);
      state = state.copyWith(stats: stats);
    } catch (e) {
      debugPrint('❌ [CardioProvider] Refresh stats error: $e');
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// ============================================
// Providers
// ============================================

/// Cardio state provider
final cardioProvider = StateNotifierProvider<CardioNotifier, CardioState>((ref) {
  return CardioNotifier(ref.watch(cardioRepositoryProvider));
});

/// Recent cardio sessions provider (convenience)
final recentCardioSessionsProvider = Provider<List<CardioSession>>((ref) {
  return ref.watch(cardioProvider).recentSessions;
});

/// Today's cardio summary provider (convenience)
final todayCardioSummaryProvider = Provider<DailyCardioSummary?>((ref) {
  return ref.watch(cardioProvider).todaySummary;
});

/// Cardio stats provider (convenience)
final cardioStatsProvider = Provider<CardioStats?>((ref) {
  return ref.watch(cardioProvider).stats;
});

/// Is cardio loading provider (convenience)
final isCardioLoadingProvider = Provider<bool>((ref) {
  return ref.watch(cardioProvider).isLoading;
});

/// Is cardio saving provider (convenience)
final isCardioSavingProvider = Provider<bool>((ref) {
  return ref.watch(cardioProvider).isSaving;
});
