/// Snapped Equipment tab body (Issue #1, Task #6).
///
/// Lists the user's previously snapped equipment (from
/// `GET /api/v1/users/{user_id}/snapped-equipment`) and lets them re-rank
/// any prior snap against the *current* workout context without re-uploading.
///
/// Tapping a card POSTs `/api/v1/equipment/snap` with `reuse_s3_key=<s3_key>`
/// — the backend skips the S3 upload and re-runs Vision/extractor + match
/// reranking against the current workout, then returns matches that the
/// user can swap/add into the active workout.
///
/// Cache-first per `feedback_instant_data`: the Riverpod provider hands
/// back any in-memory cache instantly while a background refresh runs.
library;

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/workout.dart';
import '../../../data/services/api_client.dart';
import 'equipment_snap_flow.dart' show SnapMode;

import '../../../l10n/generated/app_localizations.dart';
// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

/// One row from `GET /api/v1/users/{user_id}/snapped-equipment`.
@immutable
class SnappedEquipmentItem {
  final String id;
  final String s3Key;
  final String? imageUrl;
  final String canonicalName;
  final double? confidence;
  final String? visionLabel;
  final String? lastExerciseId;
  final String? createdVia;
  final DateTime classifiedAt;

  const SnappedEquipmentItem({
    required this.id,
    required this.s3Key,
    required this.imageUrl,
    required this.canonicalName,
    required this.confidence,
    required this.visionLabel,
    required this.lastExerciseId,
    required this.createdVia,
    required this.classifiedAt,
  });

  factory SnappedEquipmentItem.fromJson(Map<String, dynamic> j) {
    return SnappedEquipmentItem(
      id: (j['id'] ?? '').toString(),
      s3Key: (j['s3_key'] ?? '').toString(),
      imageUrl: j['image_url'] as String?,
      canonicalName: (j['canonical_name'] ?? '').toString(),
      confidence: (j['confidence'] as num?)?.toDouble(),
      visionLabel: j['vision_label'] as String?,
      lastExerciseId: j['last_exercise_id'] as String?,
      createdVia: j['created_via'] as String?,
      classifiedAt:
          DateTime.tryParse(j['classified_at']?.toString() ?? '') ??
              DateTime.now().toUtc(),
    );
  }
}

@immutable
class SnappedEquipmentPage {
  final List<SnappedEquipmentItem> items;
  final String? nextCursor;
  const SnappedEquipmentPage({required this.items, this.nextCursor});
}

// ---------------------------------------------------------------------------
// Provider (cache-first, instant load + silent refresh)
// ---------------------------------------------------------------------------

/// In-memory cache of the first page so re-opening the sheet shows results
/// instantly (per memory `feedback_instant_data`).
List<SnappedEquipmentItem>? _firstPageCache;

/// Notifier-style state for the Snapped tab. Exposes:
///   - `items`              already-loaded items (cache-warmed instantly)
///   - `isInitialLoading`   true ONLY when we have no cache yet
///   - `isRefreshing`       silent background refresh in progress
///   - `error`              user-facing error string (if any)
///   - `nextCursor`         for pagination
@immutable
class SnappedEquipmentState {
  final List<SnappedEquipmentItem> items;
  final bool isInitialLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final String? error;
  final String? nextCursor;

  const SnappedEquipmentState({
    this.items = const [],
    this.isInitialLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.error,
    this.nextCursor,
  });

  SnappedEquipmentState copyWith({
    List<SnappedEquipmentItem>? items,
    bool? isInitialLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    String? error,
    String? nextCursor,
    bool clearError = false,
    bool clearNextCursor = false,
  }) {
    return SnappedEquipmentState(
      items: items ?? this.items,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      nextCursor:
          clearNextCursor ? null : (nextCursor ?? this.nextCursor),
    );
  }
}

class SnappedEquipmentNotifier extends StateNotifier<SnappedEquipmentState> {
  final Ref _ref;
  static const int _pageSize = 50;

  /// When true, skip the auto-load in the ctor (used by widget tests so the
  /// notifier doesn't hit the network on construction).
  SnappedEquipmentNotifier(this._ref, {bool autoLoad = true})
      : super(SnappedEquipmentState(
          items: _firstPageCache ?? const [],
          isInitialLoading: autoLoad && _firstPageCache == null,
        )) {
    if (autoLoad) {
      _loadFirstPage(useCacheFirst: true);
    }
  }

  /// Test-only seam: lets a test inject a fixture state directly.
  @visibleForTesting
  void debugSetState(SnappedEquipmentState next) {
    state = next;
  }

  Future<void> _loadFirstPage({bool useCacheFirst = false}) async {
    final hasCache = _firstPageCache != null && _firstPageCache!.isNotEmpty;
    if (useCacheFirst && hasCache) {
      // Show cache instantly + refresh silently in background.
      state = state.copyWith(
        items: _firstPageCache!,
        isInitialLoading: false,
        isRefreshing: true,
        clearError: true,
      );
    } else {
      state = state.copyWith(
        isInitialLoading: state.items.isEmpty,
        isRefreshing: state.items.isNotEmpty,
        clearError: true,
      );
    }

    try {
      final api = _ref.read(apiClientProvider);
      final userId = await api.getUserId();
      if (userId == null || userId.isEmpty) {
        throw 'Not signed in';
      }
      final resp = await api.get(
        '${ApiConstants.apiBaseUrl}/users/$userId/snapped-equipment',
        queryParameters: {'limit': _pageSize},
      );
      final data = resp.data;
      if (data is! Map) throw 'Unexpected response shape';
      final rawItems = (data['items'] as List? ?? const [])
          .whereType<Map>()
          .map((m) => SnappedEquipmentItem.fromJson(
              Map<String, dynamic>.from(m)))
          .toList();
      final cursor = data['next_cursor'] as String?;

      _firstPageCache = rawItems;

      if (!mounted) return;
      state = state.copyWith(
        items: rawItems,
        isInitialLoading: false,
        isRefreshing: false,
        nextCursor: cursor,
        clearNextCursor: cursor == null,
        clearError: true,
      );
    } catch (e, st) {
      debugPrint('❌ [SnappedTab] load failed: $e\n$st');
      if (!mounted) return;
      // If we already had cached items, keep them on screen and only surface
      // the error subtly; never silently fall back to mock data.
      state = state.copyWith(
        isInitialLoading: false,
        isRefreshing: false,
        error: state.items.isEmpty
            ? "Couldn't load your snapped equipment. Pull to retry."
            : null,
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || state.nextCursor == null) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final api = _ref.read(apiClientProvider);
      final userId = await api.getUserId();
      if (userId == null) throw 'Not signed in';
      final resp = await api.get(
        '${ApiConstants.apiBaseUrl}/users/$userId/snapped-equipment',
        queryParameters: {
          'limit': _pageSize,
          'cursor': state.nextCursor,
        },
      );
      final data = resp.data as Map;
      final more = (data['items'] as List? ?? const [])
          .whereType<Map>()
          .map((m) => SnappedEquipmentItem.fromJson(
              Map<String, dynamic>.from(m)))
          .toList();
      if (!mounted) return;
      state = state.copyWith(
        items: [...state.items, ...more],
        nextCursor: data['next_cursor'] as String?,
        clearNextCursor: data['next_cursor'] == null,
        isLoadingMore: false,
      );
    } catch (e) {
      debugPrint('❌ [SnappedTab] loadMore failed: $e');
      if (!mounted) return;
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Pull-to-refresh: bypass cache.
  Future<void> refresh() async {
    await _loadFirstPage(useCacheFirst: false);
  }

  /// Re-classify an existing snap against current workout context (no upload).
  /// Returns the snap response or null on failure.
  Future<Map<String, dynamic>?> reuseSnap({
    required SnappedEquipmentItem item,
    required SnapMode mode,
    String? workoutId,
    String? replacingExerciseId,
  }) async {
    try {
      final api = _ref.read(apiClientProvider);
      final form = FormData.fromMap({
        'reuse_s3_key': item.s3Key,
        'mode': mode.name,
        if (workoutId != null) 'workout_id': workoutId,
        if (replacingExerciseId != null)
          'replacing_exercise_id': replacingExerciseId,
      });
      final resp = await api.post(
        '${ApiConstants.apiBaseUrl}/equipment/snap',
        data: form,
        options: Options(
          contentType: 'multipart/form-data',
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
        ),
      );
      if (resp.data is! Map) return null;
      return Map<String, dynamic>.from(resp.data as Map);
    } catch (e) {
      debugPrint('❌ [SnappedTab] reuseSnap failed: $e');
      return null;
    }
  }
}

final snappedEquipmentProvider = StateNotifierProvider.autoDispose<
    SnappedEquipmentNotifier, SnappedEquipmentState>((ref) {
  return SnappedEquipmentNotifier(ref);
});

/// Public API: wipe cache (call after a fresh snap completes so the tab
/// reflects the new row instantly).
void invalidateSnappedEquipmentCache() {
  _firstPageCache = null;
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

/// Vertical list of the user's snapped-equipment history with a tap-to-reuse
/// action. Used as a tab in [exercise_swap_sheet] and [exercise_add_sheet].
class SnappedEquipmentSection extends ConsumerStatefulWidget {
  final SnapMode mode;
  final String? workoutId;
  final String? replacingExerciseId;
  final String? replacingExerciseName;
  final String? previewId;

  /// Called when a snap re-rank yields matches. Caller decides what to do
  /// with them (swap/add). Receives the full snap response payload.
  final void Function(Map<String, dynamic> snapResponse)? onMatchesReady;

  /// Optional override callback — caller can short-circuit the default
  /// swap/add behavior. When null, this widget calls the workout repo
  /// directly using the top match.
  final Future<Workout?> Function(Map<String, dynamic> match)? onSwapOrAdd;

  const SnappedEquipmentSection({
    super.key,
    required this.mode,
    this.workoutId,
    this.replacingExerciseId,
    this.replacingExerciseName,
    this.previewId,
    this.onMatchesReady,
    this.onSwapOrAdd,
  });

  @override
  ConsumerState<SnappedEquipmentSection> createState() =>
      _SnappedEquipmentSectionState();
}

class _SnappedEquipmentSectionState
    extends ConsumerState<SnappedEquipmentSection> {
  final ScrollController _scrollController = ScrollController();
  String? _busyItemId; // shows spinner on the tapped card

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_maybeLoadMore);
    _scrollController.dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 240) {
      ref.read(snappedEquipmentProvider.notifier).loadMore();
    }
  }

  Future<void> _onTapItem(SnappedEquipmentItem item) async {
    if (_busyItemId != null) return;
    setState(() => _busyItemId = item.id);
    try {
      final notifier = ref.read(snappedEquipmentProvider.notifier);
      final resp = await notifier.reuseSnap(
        item: item,
        mode: widget.mode,
        workoutId: widget.workoutId,
        replacingExerciseId: widget.replacingExerciseId,
      );
      if (!mounted) return;

      if (resp == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).snappedEquipmentCouldnTReuseThat)),
        );
        return;
      }

      // Prefer caller-supplied callback (swap/add sheets handle workout
      // mutation themselves).
      if (widget.onMatchesReady != null) {
        widget.onMatchesReady!(resp);
        return;
      }

      // Default: pop the sheet with the top match applied.
      final matches = (resp['matches'] as List? ?? const [])
          .whereType<Map>()
          .toList();
      if (matches.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).snappedEquipmentNoMatchingExercisesFor),
          ),
        );
        return;
      }
      final top = Map<String, dynamic>.from(matches.first);
      if (widget.onSwapOrAdd != null) {
        await widget.onSwapOrAdd!(top);
      }
    } finally {
      if (mounted) setState(() => _busyItemId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(snappedEquipmentProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    if (state.isInitialLoading) {
      return _buildSkeleton(isDark);
    }

    if (state.items.isEmpty) {
      return _buildEmpty(textMuted, textPrimary);
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(snappedEquipmentProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i >= state.items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final item = state.items[i];
          return _SnapCard(
            item: item,
            isBusy: _busyItemId == item.id,
            isDark: isDark,
            actionLabel: switch (widget.mode) {
              SnapMode.swap => 'Swap',
              SnapMode.add => 'Add',
              SnapMode.identify => 'View',
            },
            onTap: () => _onTapItem(item),
          );
        },
      ),
    );
  }

  Widget _buildSkeleton(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      itemCount: 4,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 76,
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _buildEmpty(Color textMuted, Color textPrimary) {
    // Pull-to-refresh-able empty state so silent recovery still works.
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(snappedEquipmentProvider.notifier).refresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 64),
          Icon(Icons.camera_alt_outlined,
              size: 56, color: textMuted.withValues(alpha: 0.6)),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              AppLocalizations.of(context).snappedEquipmentNoSnappedEquipmentYet,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              AppLocalizations.of(context).snappedEquipmentTapTheCameraButton,
              textAlign: TextAlign.center,
              style: TextStyle(color: textMuted, fontSize: 13, height: 1.4),
            ),
          ),
          const SizedBox(height: 96),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card
// ---------------------------------------------------------------------------

class _SnapCard extends StatelessWidget {
  final SnappedEquipmentItem item;
  final bool isBusy;
  final bool isDark;
  final String actionLabel;
  final VoidCallback onTap;

  const _SnapCard({
    required this.item,
    required this.isBusy,
    required this.isDark,
    required this.actionLabel,
    required this.onTap,
  });

  String _humanCanonical(String c) {
    if (c.isEmpty) return 'Unknown equipment';
    final s = c.replaceAll('_', ' ');
    return s[0].toUpperCase() + s.substring(1);
  }

  String _badgeText() {
    // last_exercise_id is opaque to the client; show a generic affordance.
    // Backend doesn't currently denormalize last exercise *name*, so we
    // fall back to a typed badge.
    if (item.lastExerciseId != null && item.lastExerciseId!.isNotEmpty) {
      return 'Last used recently';
    }
    return 'Equipment only';
  }

  @override
  Widget build(BuildContext context) {
    final accent = AccentColorScope.of(context).getColor(isDark);
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: isBusy ? null : onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surface.withValues(alpha: 0.6)
                  : AppColorsLight.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: (item.imageUrl != null &&
                            item.imageUrl!.isNotEmpty)
                        ? Image.network(
                            item.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder(),
                            loadingBuilder: (c, child, p) =>
                                p == null ? child : _placeholder(),
                          )
                        : _placeholder(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _humanCanonical(item.canonicalName),
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _badgeText(),
                          style: TextStyle(
                            color: accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isBusy)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                else
                  // Compact icon button — keeps the card narrow enough for
                  // iPhone SE (320pt) without overflow per
                  // `feedback_no_overflow_adaptive_screens`.
                  IconButton(
                    tooltip: actionLabel,
                    onPressed: onTap,
                    icon: Icon(Icons.bolt, color: accent),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey.shade300,
      child: const Icon(Icons.fitness_center, size: 22, color: Colors.white),
    );
  }
}
