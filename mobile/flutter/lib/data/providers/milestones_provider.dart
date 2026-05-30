import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;
import '../models/milestone.dart';
import '../repositories/milestones_repository.dart';
import '../services/data_cache_service.dart';

/// In-memory caches (mirrors scoresProvider/consistencyProvider) so a notifier
/// recreation paints prior milestone data instantly without a network flash.
/// Flushed on a real account switch.
ROIMetrics? _roiMetricsInMemoryCache;
MilestonesResponse? _milestonesInMemoryCache;
String? _milestonesCacheOwnerUserId;

/// Disk cache keys (12h TTL via `statsKeyPrefix`). Cache the RAW model JSON so
/// a cold start paints last-known numbers instantly.
const String _roiMetricsCacheKey = '${DataCacheService.statsKeyPrefix}roi';
const String _milestoneProgressCacheKey =
    '${DataCacheService.statsKeyPrefix}milestone_progress';

// ============================================
// Milestones State
// ============================================

/// Complete milestones state including progress, ROI, and celebrations
class MilestonesState {
  final MilestonesResponse? milestones;
  final ROISummary? roiSummary;
  final ROIMetrics? roiMetrics;
  final List<UserMilestone> uncelebrated;
  final List<MilestoneDefinition> allDefinitions;
  final bool isLoading;
  final bool isCheckingMilestones;
  final String? error;
  final MilestoneCheckResult? lastCheckResult;

  const MilestonesState({
    this.milestones,
    this.roiSummary,
    this.roiMetrics,
    this.uncelebrated = const [],
    this.allDefinitions = const [],
    this.isLoading = false,
    this.isCheckingMilestones = false,
    this.error,
    this.lastCheckResult,
  });

  MilestonesState copyWith({
    MilestonesResponse? milestones,
    ROISummary? roiSummary,
    ROIMetrics? roiMetrics,
    List<UserMilestone>? uncelebrated,
    List<MilestoneDefinition>? allDefinitions,
    bool? isLoading,
    bool? isCheckingMilestones,
    String? error,
    MilestoneCheckResult? lastCheckResult,
    bool clearError = false,
    bool clearUncelebrated = false,
    bool clearCheckResult = false,
  }) {
    return MilestonesState(
      milestones: milestones ?? this.milestones,
      roiSummary: roiSummary ?? this.roiSummary,
      roiMetrics: roiMetrics ?? this.roiMetrics,
      uncelebrated:
          clearUncelebrated ? const [] : (uncelebrated ?? this.uncelebrated),
      allDefinitions: allDefinitions ?? this.allDefinitions,
      isLoading: isLoading ?? this.isLoading,
      isCheckingMilestones: isCheckingMilestones ?? this.isCheckingMilestones,
      error: clearError ? null : (error ?? this.error),
      lastCheckResult: clearCheckResult
          ? null
          : (lastCheckResult ?? this.lastCheckResult),
    );
  }

  /// Total points earned from milestones
  int get totalPoints => milestones?.totalPoints ?? 0;

  /// Total milestones achieved
  int get totalAchieved => milestones?.totalAchieved ?? 0;

  /// List of achieved milestones
  List<MilestoneProgress> get achieved => milestones?.achieved ?? [];

  /// List of upcoming milestones
  List<MilestoneProgress> get upcoming => milestones?.upcoming ?? [];

  /// Next milestone to achieve (closest to completion)
  MilestoneProgress? get nextMilestone => milestones?.nextMilestone;

  /// Check if there are uncelebrated milestones
  bool get hasUncelebrated => uncelebrated.isNotEmpty;

  /// Check if there are new milestones from the last check
  bool get hasNewMilestones => lastCheckResult?.hasNewMilestones ?? false;
}

// ============================================
// Milestones Notifier
// ============================================

class MilestonesNotifier extends StateNotifier<MilestonesState> {
  final MilestonesRepository _repository;
  String? _currentUserId;

  MilestonesNotifier(this._repository)
      : super(MilestonesState(
          milestones: _milestonesInMemoryCache,
          roiMetrics: _roiMetricsInMemoryCache,
          uncelebrated: _milestonesInMemoryCache?.uncelebrated ?? const [],
        ));

  /// Clear in-memory caches (called on logout / account switch).
  static void clearCache() {
    _roiMetricsInMemoryCache = null;
    _milestonesInMemoryCache = null;
    debugPrint('🧹 [MilestonesProvider] In-memory cache cleared');
  }

  /// Set user ID for this session
  void setUserId(String userId) {
    _currentUserId = userId;
  }

  /// Cold-start disk seed. Paints last-known ROI metrics + milestone progress
  /// instantly (even if expired) before any network call, so the scalar strip
  /// and milestones list show real prior numbers rather than skeletons. No-op
  /// for slices already held in memory this session.
  Future<void> seedFromDisk({String? userId}) async {
    final uid = userId ??
        Supabase.instance.client.auth.currentUser?.id ??
        _currentUserId;
    if (uid == null) return;
    _currentUserId = uid;

    try {
      if (state.roiMetrics == null) {
        final cached = await DataCacheService.instance.getCached(
          _roiMetricsCacheKey,
          userId: uid,
          returnExpiredOnMiss: true,
        );
        if (cached != null && state.roiMetrics == null) {
          final metrics = ROIMetrics.fromJson(cached);
          _roiMetricsInMemoryCache = metrics;
          state = state.copyWith(roiMetrics: metrics);
          debugPrint('⚡ [MilestonesProvider] Seeded ROI metrics from disk');
        }
      }
      if (state.milestones == null) {
        final cached = await DataCacheService.instance.getCached(
          _milestoneProgressCacheKey,
          userId: uid,
          returnExpiredOnMiss: true,
        );
        if (cached != null && state.milestones == null) {
          final milestones = MilestonesResponse.fromJson(cached);
          _milestonesInMemoryCache = milestones;
          state = state.copyWith(
            milestones: milestones,
            uncelebrated: milestones.uncelebrated,
          );
          debugPrint(
              '⚡ [MilestonesProvider] Seeded milestone progress from disk');
        }
      }
    } catch (e) {
      debugPrint('⚠️ [MilestonesProvider] Disk seed failed: $e');
    }
  }

  /// Load milestone progress for a user
  Future<void> loadMilestoneProgress({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) {
      debugPrint('[MilestonesProvider] No user ID, skipping load');
      return;
    }
    _currentUserId = uid;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final milestones = await _repository.getMilestoneProgress(uid);
      _milestonesInMemoryCache = milestones;
      state = state.copyWith(
        milestones: milestones,
        uncelebrated: milestones.uncelebrated,
        isLoading: false,
      );
      // Write-through to disk so the next cold start paints instantly.
      await DataCacheService.instance
          .cache(_milestoneProgressCacheKey, milestones.toJson(), userId: uid);
      debugPrint(
          '[MilestonesProvider] Loaded ${milestones.totalAchieved} achieved milestones');
    } catch (e) {
      debugPrint('[MilestonesProvider] Error loading milestones: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load milestones: $e',
      );
    }
  }

  /// Load ROI summary for home screen
  Future<void> loadROISummary({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;
    _currentUserId = uid;

    try {
      final summary = await _repository.getROISummary(uid);
      state = state.copyWith(roiSummary: summary);
      debugPrint(
          '[MilestonesProvider] Loaded ROI: ${summary.totalWorkouts} workouts');
    } catch (e) {
      debugPrint('[MilestonesProvider] Error loading ROI summary: $e');
    }
  }

  /// Load detailed ROI metrics
  Future<void> loadROIMetrics({String? userId, bool recalculate = false}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;
    _currentUserId = uid;

    try {
      final metrics = await _repository.getROIMetrics(uid, recalculate: recalculate);
      _roiMetricsInMemoryCache = metrics;
      state = state.copyWith(roiMetrics: metrics);
      // Write-through to disk so the next cold start paints instantly.
      await DataCacheService.instance
          .cache(_roiMetricsCacheKey, metrics.toJson(), userId: uid);
      debugPrint(
          '[MilestonesProvider] Loaded detailed ROI metrics');
    } catch (e) {
      debugPrint('[MilestonesProvider] Error loading ROI metrics: $e');
    }
  }

  /// Load uncelebrated milestones
  Future<void> loadUncelebrated({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;
    _currentUserId = uid;

    try {
      final uncelebrated = await _repository.getUncelebratedMilestones(uid);
      state = state.copyWith(uncelebrated: uncelebrated);
      debugPrint(
          '[MilestonesProvider] Found ${uncelebrated.length} uncelebrated milestones');
    } catch (e) {
      debugPrint('[MilestonesProvider] Error loading uncelebrated: $e');
    }
  }

  /// Load all milestone definitions
  Future<void> loadDefinitions({MilestoneCategory? category}) async {
    try {
      final definitions =
          await _repository.getMilestoneDefinitions(category: category);
      state = state.copyWith(allDefinitions: definitions);
      debugPrint(
          '[MilestonesProvider] Loaded ${definitions.length} milestone definitions');
    } catch (e) {
      debugPrint('[MilestonesProvider] Error loading definitions: $e');
    }
  }

  /// Check for new milestones (called after workout completion)
  Future<MilestoneCheckResult?> checkForNewMilestones({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return null;
    _currentUserId = uid;

    state = state.copyWith(isCheckingMilestones: true);

    try {
      final result = await _repository.checkMilestones(uid);
      state = state.copyWith(
        lastCheckResult: result,
        isCheckingMilestones: false,
      );

      if (result.hasNewMilestones) {
        debugPrint(
            '[MilestonesProvider] New milestones achieved: ${result.newMilestones.length}');
        // Reload milestones to get updated data
        await loadMilestoneProgress(userId: uid);
      }

      return result;
    } catch (e) {
      debugPrint('[MilestonesProvider] Error checking milestones: $e');
      state = state.copyWith(isCheckingMilestones: false);
      return null;
    }
  }

  /// Mark milestones as celebrated (after showing celebration dialog)
  Future<bool> markAsCelebrated(List<String> milestoneIds) async {
    final uid = _currentUserId;
    if (uid == null) return false;

    try {
      final success = await _repository.markMilestonesCelebrated(
        uid,
        milestoneIds,
      );

      if (success) {
        // Remove from uncelebrated list
        final remaining = state.uncelebrated
            .where((m) => !milestoneIds.contains(m.id))
            .toList();
        state = state.copyWith(uncelebrated: remaining);
        debugPrint(
            '[MilestonesProvider] Marked ${milestoneIds.length} milestones as celebrated');
      }

      return success;
    } catch (e) {
      debugPrint('[MilestonesProvider] Error marking celebrated: $e');
      return false;
    }
  }

  /// Record a milestone share
  Future<bool> recordShare(String milestoneId, String platform) async {
    final uid = _currentUserId;
    if (uid == null) return false;

    try {
      final success = await _repository.recordMilestoneShare(
        uid,
        milestoneId,
        platform,
      );
      debugPrint('[MilestonesProvider] Recorded share on $platform');
      return success;
    } catch (e) {
      debugPrint('[MilestonesProvider] Error recording share: $e');
      return false;
    }
  }

  /// Award a first_steps milestone by trigger name.
  ///
  /// Called when the user performs a key action for the first time.
  /// If a new milestone is awarded, reloads milestone data.
  Future<bool> awardFirstStep(String trigger, {String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return false;
    _currentUserId = uid;

    try {
      final result = await _repository.awardFirstStep(uid, trigger);
      if (result != null) {
        debugPrint(
            '[MilestonesProvider] Awarded first_steps milestone: ${result['milestone_name']}');
        // Reload milestones to pick up the new achievement
        await loadMilestoneProgress(userId: uid);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[MilestonesProvider] Error awarding first step: $e');
      return false;
    }
  }

  /// Load all data (milestones + ROI)
  Future<void> loadAll({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;
    _currentUserId = uid;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Load in parallel
      await Future.wait([
        loadMilestoneProgress(userId: uid),
        loadROISummary(userId: uid),
      ]);

      state = state.copyWith(isLoading: false);
      debugPrint('[MilestonesProvider] Loaded all milestone data');
    } catch (e) {
      debugPrint('[MilestonesProvider] Error loading all data: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load progress data: $e',
      );
    }
  }

  /// Refresh all data
  Future<void> refresh({String? userId}) async {
    await loadAll(userId: userId);
  }

  /// Clear last check result
  void clearCheckResult() {
    state = state.copyWith(clearCheckResult: true);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// ============================================
// Providers
// ============================================

/// Main milestones provider
final milestonesProvider =
    StateNotifierProvider<MilestonesNotifier, MilestonesState>((ref) {
  final repository = ref.watch(milestonesRepositoryProvider);
  // Flush the static in-memory caches on a real account switch so the new user
  // never inherits the prior user's milestone numbers.
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId != null && userId != _milestonesCacheOwnerUserId) {
    _milestonesCacheOwnerUserId = userId;
    MilestonesNotifier.clearCache();
  }
  return MilestonesNotifier(repository);
});

/// ROI summary for home screen (convenience provider)
final roiSummaryProvider = Provider<ROISummary?>((ref) {
  return ref.watch(milestonesProvider).roiSummary;
});

/// Total points earned (convenience provider)
final milestonePointsProvider = Provider<int>((ref) {
  return ref.watch(milestonesProvider).totalPoints;
});

/// Total milestones achieved (convenience provider)
final milestonesAchievedCountProvider = Provider<int>((ref) {
  return ref.watch(milestonesProvider).totalAchieved;
});

/// Achieved milestones list (convenience provider)
final achievedMilestonesProvider = Provider<List<MilestoneProgress>>((ref) {
  return ref.watch(milestonesProvider).achieved;
});

/// Upcoming milestones list (convenience provider)
final upcomingMilestonesProvider = Provider<List<MilestoneProgress>>((ref) {
  return ref.watch(milestonesProvider).upcoming;
});

/// Next milestone to achieve (convenience provider)
final nextMilestoneProvider = Provider<MilestoneProgress?>((ref) {
  return ref.watch(milestonesProvider).nextMilestone;
});

/// Uncelebrated milestones (convenience provider)
final uncelebratedMilestonesProvider = Provider<List<UserMilestone>>((ref) {
  return ref.watch(milestonesProvider).uncelebrated;
});

/// Whether there are uncelebrated milestones (convenience provider)
final hasUncelebratedMilestonesProvider = Provider<bool>((ref) {
  return ref.watch(milestonesProvider).hasUncelebrated;
});

/// Milestones loading state (convenience provider)
final milestonesLoadingProvider = Provider<bool>((ref) {
  return ref.watch(milestonesProvider).isLoading;
});

/// Last milestone check result (convenience provider)
final lastMilestoneCheckProvider = Provider<MilestoneCheckResult?>((ref) {
  return ref.watch(milestonesProvider).lastCheckResult;
});
