import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../models/assign_preview.dart';
import '../models/equipment_coverage.dart';
import '../models/program_template.dart';
import '../models/user_program_assignment.dart';
import '../services/api_client.dart';
import '../services/data_cache_service.dart';

/// Response for `POST /program-templates/assign` (the unified Start-program
/// flow). Kept here (not in the read-only model file) so this stream owns it.
class AssignResult {
  final bool success;
  final String? assignmentId;
  final String? templateId;
  final int workoutsCreated;

  /// What the AI-tailoring actually did on commit (`CustomizeSummary.none` when
  /// the user didn't enable tailoring). Drives the honest post-Start toast.
  final CustomizeSummary customizeSummary;

  const AssignResult({
    required this.success,
    this.assignmentId,
    this.templateId,
    this.workoutsCreated = 0,
    this.customizeSummary = CustomizeSummary.none,
  });

  factory AssignResult.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v.trim()) ?? 0;
      return 0;
    }

    final s = json['success'];
    return AssignResult(
      success: s is bool ? s : true,
      assignmentId: json['assignment_id']?.toString(),
      templateId: json['template_id']?.toString(),
      workoutsCreated: toInt(json['workouts_created']),
      customizeSummary: json['customize_summary'] is Map
          ? CustomizeSummary.fromJson(
              Map<String, dynamic>.from(json['customize_summary'] as Map))
          : CustomizeSummary.none,
    );
  }
}

/// DI provider for the program-template repository.
final programTemplateRepositoryProvider =
    Provider<ProgramTemplateRepository>((ref) {
  return ProgramTemplateRepository(ref.watch(apiClientProvider));
});

/// Filter key for [programLibraryBrowseProvider]. A Dart record gives value
/// equality, so the same filter combo reuses one cached provider instance.
typedef ProgramLibraryFilter = ({
  String? category,
  String? difficulty,
  int? sessionsPerWeek,
  String? search,
  List<String>? goals,
  int? durationMin,
  int? durationMax,
  List<String>? equipment,
});

/// Cache-first `AsyncValue` notifier shared by every Program Library lane.
///
/// It paints the disk-cached value INSTANTLY (even if stale) on construction,
/// then revalidates over the network in the background and emits the fresh
/// result. This is the "instant tabs" pattern (mirrors `TodayWorkoutNotifier`):
/// a plain `FutureProvider` can't emit twice, so it always blocked on the
/// network and showed a skeleton on the first open per launch.
///
/// Error posture: a revalidation failure with a painted cache is swallowed
/// (the user keeps seeing real data); a cold miss + failure surfaces as
/// `AsyncError` so the screen's existing error + Retry card shows. Never any
/// mock/fallback data.
class LibraryAsyncNotifier<T> extends StateNotifier<AsyncValue<T>> {
  LibraryAsyncNotifier({required this.seed, required this.fetch})
      : super(const AsyncValue.loading()) {
    _boot();
  }

  /// Reads the disk cache (returns null on a cold miss).
  final Future<T?> Function() seed;

  /// Fetches fresh from the network (and write-throughs the disk cache).
  final Future<T> Function() fetch;

  Future<void> _boot() async {
    try {
      final cached = await seed();
      if (cached != null && mounted && !state.hasValue) {
        state = AsyncValue.data(cached);
      }
    } catch (_) {
      // Cache read failure is non-fatal — fall through to the network.
    }
    await refresh();
  }

  /// Revalidate over the network. Called on construction and on manual refresh.
  Future<void> refresh() async {
    try {
      final fresh = await fetch();
      if (mounted) state = AsyncValue.data(fresh);
    } catch (e, st) {
      // Keep the cached value if we already painted one; only surface the error
      // on a true cold miss so the Retry card shows (no mock data).
      if (mounted && !state.hasValue) state = AsyncValue.error(e, st);
    }
  }
}

/// Cache-first browse of the curated program library, keyed by the active
/// filter tuple. Paints the last disk-cached result for these filters
/// instantly, then revalidates. `keepAlive` holds the value across screen
/// rebuilds / quick back-and-forth navigation.
///
/// The screen invalidates this provider for the current filter to force a
/// refresh (recreates the notifier → reseeds from cache, then refetches — so a
/// pull-to-refresh still paints instantly, no skeleton flash).
final programLibraryBrowseProvider = StateNotifierProvider.autoDispose.family<
    LibraryAsyncNotifier<ProgramLibraryResult>,
    AsyncValue<ProgramLibraryResult>,
    ProgramLibraryFilter>((ref, filter) {
  ref.keepAlive();
  final repo = ref.watch(programTemplateRepositoryProvider);
  return LibraryAsyncNotifier<ProgramLibraryResult>(
    seed: () => repo.cachedBrowse(filter),
    // Scoped resilience: the library is static reference data behind a single
    // GET. A transient backend blip shouldn't dump the user to the error card
    // on the first failure — retry TRANSIENT failures only; real errors
    // (auth / 4xx) propagate so we never mask a genuine problem.
    fetch: () => _browseLibraryWithRetry(repo, filter),
  );
});

/// Browse the library, retrying up to 3 times on transient network/server
/// failures with a short backoff. Non-transient errors rethrow on attempt 1.
Future<ProgramLibraryResult> _browseLibraryWithRetry(
  ProgramTemplateRepository repo,
  ProgramLibraryFilter filter,
) async {
  const maxAttempts = 3;
  for (var attempt = 1;; attempt++) {
    try {
      return await repo.browseLibrary(
        category: filter.category,
        difficulty: filter.difficulty,
        sessionsPerWeek: filter.sessionsPerWeek,
        search: filter.search,
        goals: filter.goals,
        durationMin: filter.durationMin,
        durationMax: filter.durationMax,
        equipment: filter.equipment,
      );
    } on DioException catch (e) {
      if (attempt >= maxAttempts || !_isTransientLibraryFailure(e)) rethrow;
      // 400ms then 800ms — enough to ride out a restart / cold-cache window.
      await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
    }
  }
}

/// True for failures worth retrying: connection/receive/send timeouts, dropped
/// connections, and 502/503/504 (gateway / restart). NOT 4xx (auth, bad input).
bool _isTransientLibraryFailure(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.connectionError:
      return true;
    default:
      final code = e.response?.statusCode ?? 0;
      return code == 502 || code == 503 || code == 504;
  }
}

/// Cache-first curated-featured programs (`GET /library/featured`). Paints the
/// disk-cached hero carousel instantly, then revalidates. `keepAlive` holds it
/// across navigation. Errors on a cold miss surface the Retry card; never mock.
final programFeaturedProvider = StateNotifierProvider.autoDispose<
    LibraryAsyncNotifier<ProgramLibraryResult>,
    AsyncValue<ProgramLibraryResult>>((ref) {
  ref.keepAlive();
  final repo = ref.watch(programTemplateRepositoryProvider);
  return LibraryAsyncNotifier<ProgramLibraryResult>(
    seed: () => repo.cachedFeatured(),
    fetch: () => repo.getFeatured(),
  );
});

/// Cache-first personalized recommendations (`GET /library/recommended`).
/// Same posture as [programFeaturedProvider]; the disk cache is user-scoped.
final programRecommendedProvider = StateNotifierProvider.autoDispose<
    LibraryAsyncNotifier<ProgramLibraryResult>,
    AsyncValue<ProgramLibraryResult>>((ref) {
  ref.keepAlive();
  final repo = ref.watch(programTemplateRepositoryProvider);
  return LibraryAsyncNotifier<ProgramLibraryResult>(
    seed: () => repo.cachedRecommended(),
    fetch: () => repo.getRecommended(),
  );
});

/// Cache-first category facet counts (`GET /library/categories`) — drives the
/// category chips / filter rail. Same posture as [programFeaturedProvider].
final programCategoryCountsProvider = StateNotifierProvider.autoDispose<
    LibraryAsyncNotifier<List<({String category, int count})>>,
    AsyncValue<List<({String category, int count})>>>((ref) {
  ref.keepAlive();
  final repo = ref.watch(programTemplateRepositoryProvider);
  return LibraryAsyncNotifier<List<({String category, int count})>>(
    seed: () => repo.cachedCategories(),
    fetch: () => repo.getCategoryCounts(),
  );
});

/// Per-variant schedule provider keyed by (programId, variantId).
/// `variantId` is null for single-plan programs (the backend resolves
/// `default_variant_id` automatically). `keepAlive` so the schedule doesn't
/// re-fetch on every tab switch while the user reviews it.
///
/// Errors propagate so the schedule tab can show a Retry card — no mock data.
final programScheduleProvider = FutureProvider.autoDispose.family<
    ProgramScheduleResponse,
    ({String programId, String? variantId})>((ref, key) async {
  ref.keepAlive();
  final repo = ref.watch(programTemplateRepositoryProvider);
  return repo.getLibrarySchedule(key.programId, variantId: key.variantId);
});

/// Thin HTTP wrapper for `/api/v1/program-templates/*`.
///
/// Every method returns a typed model and lets Dio exceptions bubble — the
/// screen layer converts them into human copy. We never swallow errors or
/// substitute mock data (see `feedback_no_silent_fallbacks`). Modeled on
/// `body_analyzer_repository.dart`.
class ProgramTemplateRepository {
  final ApiClient _client;
  ProgramTemplateRepository(this._client);

  static const _base = '/program-templates';

  // -------------------------------------------------------------------------
  // Library — the first-ever API over the 259-row `programs` table.
  // -------------------------------------------------------------------------

  /// GET /library — browse the curated program library.
  ///
  /// All filters are optional. `category` matches `program_category`,
  /// `difficulty` matches `difficulty_level`, `sessionsPerWeek` matches
  /// `sessions_per_week`, `search` is a free-text name match.
  Future<ProgramLibraryResult> browseLibrary({
    String? category,
    String? difficulty,
    int? sessionsPerWeek,
    String? search,
    List<String>? goals,
    int? durationMin,
    int? durationMax,
    List<String>? equipment,
  }) async {
    final query = <String, dynamic>{};
    if (category != null && category.isNotEmpty) {
      query['category'] = category;
    }
    if (difficulty != null && difficulty.isNotEmpty) {
      query['difficulty_level'] = difficulty;
    }
    if (sessionsPerWeek != null) {
      query['sessions_per_week'] = sessionsPerWeek;
    }
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    if (goals != null) {
      final clean = goals
          .map((g) => g.trim())
          .where((g) => g.isNotEmpty)
          .toList(growable: false);
      if (clean.isNotEmpty) {
        query['goals'] = clean.join(',');
      }
    }
    if (durationMin != null) {
      query['duration_min'] = durationMin;
    }
    if (durationMax != null) {
      query['duration_max'] = durationMax;
    }
    if (equipment != null) {
      final clean = equipment
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
      if (clean.isNotEmpty) {
        query['equipment'] = clean.join(',');
      }
    }
    debugPrint('🏋️ [ProgramTemplate] browseLibrary | filters=$query');
    final resp = await _client.get(
      '$_base/library',
      queryParameters: query.isEmpty ? null : query,
    );
    final data = Map<String, dynamic>.from(resp.data as Map);
    // Write-through the RAW response so the next cold open paints instantly
    // (see cache-first providers). Skip free-text searches — a stale search
    // result is confusing, and they're one-off queries not worth persisting.
    if ((search ?? '').trim().isEmpty) {
      _cacheRaw(_browseCacheKey(_filterFromQuery(query)), data);
    }
    return ProgramLibraryResult.fromJson(data);
  }

  /// GET /library/featured — curated/editorial featured programs.
  ///
  /// Same `{total, programs}` shape as [browseLibrary]. Wrapped in the shared
  /// transient-retry so a deploy blip doesn't dump the user to the error card.
  Future<ProgramLibraryResult> getFeatured() async {
    debugPrint('🏋️ [ProgramTemplate] getFeatured');
    final data = await _getMapWithRetry('$_base/library/featured');
    _cacheRaw(_kFeaturedCacheKey, data);
    return ProgramLibraryResult.fromJson(data);
  }

  /// GET /library/recommended — personalized program recommendations.
  ///
  /// Same `{total, programs}` shape as [browseLibrary]. Wrapped in the shared
  /// transient-retry. Cache is user-scoped (recommendations are personalized).
  Future<ProgramLibraryResult> getRecommended() async {
    debugPrint('🏋️ [ProgramTemplate] getRecommended');
    final data = await _getMapWithRetry('$_base/library/recommended');
    _cacheRaw(_kRecommendedCacheKey, data, userScoped: true);
    return ProgramLibraryResult.fromJson(data);
  }

  /// GET /library/categories — category facet counts for the filter rail.
  ///
  /// Returns `{categories:[{category, count}]}`; we surface a list of typed
  /// `(category, count)` records. Wrapped in the shared transient-retry.
  Future<List<({String category, int count})>> getCategoryCounts() async {
    debugPrint('🏋️ [ProgramTemplate] getCategoryCounts');
    final data = await _getMapWithRetry('$_base/library/categories');
    _cacheRaw(_kCategoriesCacheKey, data);
    return _parseCategories(data);
  }

  /// Shared parse for the `{categories:[{category, count}]}` payload — used by
  /// both the network path and the disk-cache read.
  List<({String category, int count})> _parseCategories(
      Map<String, dynamic> data) {
    final raw = data['categories'];
    final out = <({String category, int count})>[];
    if (raw is List) {
      for (final c in raw) {
        if (c is Map) {
          final category = c['category']?.toString() ?? '';
          if (category.isEmpty) continue;
          final count = _toInt(c['count']);
          out.add((category: category, count: count));
        }
      }
    }
    return out;
  }

  // -------------------------------------------------------------------------
  // Cache-first disk cache (instant Program Library paint). We persist the RAW
  // response map (not a serialized model) so reads round-trip through the same
  // `fromJson` the network path uses — no model `toJson` needed, no drift risk.
  // -------------------------------------------------------------------------

  static const String _kFeaturedCacheKey = 'cache_program_featured';
  static const String _kRecommendedCacheKey = 'cache_program_recommended';
  static const String _kCategoriesCacheKey = 'cache_program_categories';
  static const String _kBrowseCachePrefix = 'cache_program_browse_';
  static const String _kDetailCachePrefix = 'cache_program_detail_';

  /// Disk key for one program's full detail payload (the `GET /library/{id}`
  /// response). Keyed by program id so re-opening a program paints the real
  /// phases / variants / joined-count instantly instead of the lightweight
  /// browse card's fabricated placeholder.
  String _detailCacheKey(String programId) =>
      '$_kDetailCachePrefix$programId';

  /// Live user id (never a cached field — JWT-expiry rule). Scopes the
  /// personalized recommendations cache so user B never inherits user A's.
  String? _uid() {
    try {
      return Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  /// Deterministic disk key for a browse filter tuple. Library content is the
  /// same for everyone, so browse/featured/categories caches are global
  /// (userId null); only recommendations are user-scoped.
  String _browseCacheKey(ProgramLibraryFilter f) {
    final parts = [
      f.category ?? '',
      f.difficulty ?? '',
      f.sessionsPerWeek?.toString() ?? '',
      (f.goals ?? const <String>[]).join('|'),
      f.durationMin?.toString() ?? '',
      f.durationMax?.toString() ?? '',
      (f.equipment ?? const <String>[]).join('|'),
    ];
    final hash = parts.join('~');
    return '$_kBrowseCachePrefix${hash.replaceAll('~', '') == '' ? 'default' : hash}';
  }

  /// Reconstruct the filter tuple from a built query map (so [browseLibrary]
  /// can derive its own cache key without the caller threading the filter in).
  ProgramLibraryFilter _filterFromQuery(Map<String, dynamic> q) {
    final rawGoals = q['goals'];
    final rawEquipment = q['equipment'];
    return (
      category: q['category'] as String?,
      difficulty: q['difficulty_level'] as String?,
      sessionsPerWeek: q['sessions_per_week'] as int?,
      search: q['search'] as String?,
      goals: rawGoals is String ? rawGoals.split(',') : null,
      durationMin: q['duration_min'] as int?,
      durationMax: q['duration_max'] as int?,
      equipment: rawEquipment is String ? rawEquipment.split(',') : null,
    );
  }

  /// Fire-and-forget disk write of a raw response map. Never throws into the
  /// caller — a cache failure must not break a successful fetch.
  void _cacheRaw(String key, Map<String, dynamic> data, {bool userScoped = false}) {
    DataCacheService.instance
        .cache(key, data, userId: userScoped ? _uid() : null)
        .catchError((Object e) =>
            debugPrint('⚠️ [ProgramTemplate] cache write ($key) failed: $e'));
  }

  /// Read a cached raw map (expired entries allowed — the provider revalidates
  /// in the background, so a stale-but-instant first paint is the whole point).
  Future<Map<String, dynamic>?> _readRaw(String key, {bool userScoped = false}) async {
    try {
      return await DataCacheService.instance.getCached(
        key,
        userId: userScoped ? _uid() : null,
        returnExpiredOnMiss: true,
      );
    } catch (e) {
      debugPrint('⚠️ [ProgramTemplate] cache read ($key) failed: $e');
      return null;
    }
  }

  /// Disk-cached featured programs, or null on a cold miss.
  Future<ProgramLibraryResult?> cachedFeatured() async {
    final data = await _readRaw(_kFeaturedCacheKey);
    return data == null ? null : ProgramLibraryResult.fromJson(data);
  }

  /// Disk-cached recommendations (user-scoped), or null on a cold miss.
  Future<ProgramLibraryResult?> cachedRecommended() async {
    final data = await _readRaw(_kRecommendedCacheKey, userScoped: true);
    return data == null ? null : ProgramLibraryResult.fromJson(data);
  }

  /// Disk-cached category counts, or null on a cold miss.
  Future<List<({String category, int count})>?> cachedCategories() async {
    final data = await _readRaw(_kCategoriesCacheKey);
    return data == null ? null : _parseCategories(data);
  }

  /// Disk-cached browse result for a filter, or null on a cold miss. Searches
  /// are never cached, so they always miss (and fetch fresh).
  Future<ProgramLibraryResult?> cachedBrowse(ProgramLibraryFilter f) async {
    if ((f.search ?? '').trim().isNotEmpty) return null;
    final data = await _readRaw(_browseCacheKey(f));
    return data == null ? null : ProgramLibraryResult.fromJson(data);
  }

  /// Disk-cached program detail (editorial card + sample week) for [programId],
  /// or null on a cold miss. Parses the cached RAW payload through the SAME
  /// `fromJson` paths the network response uses, so a repeat open paints the
  /// real phases / variant selectors / joined badge instantly while
  /// [getLibraryDetail] revalidates in the background.
  Future<({ProgramLibraryCard card, ProgramTemplate sampleWeek})?>
      cachedLibraryDetail(String programId) async {
    final data = await _readRaw(_detailCacheKey(programId));
    if (data == null) return null;
    final cardData = Map<String, dynamic>.from(data);
    cardData.putIfAbsent('id', () => data['program_id'] ?? programId);
    if ((cardData['id']?.toString() ?? '').isEmpty) {
      cardData['id'] = programId;
    }
    return (
      card: ProgramLibraryCard.fromJson(cardData),
      sampleWeek: ProgramTemplate.fromJson(data),
    );
  }

  /// Coerce a loose JSON number/string into an int, defaulting to 0.
  int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim()) ?? 0;
    return 0;
  }

  /// GET a JSON object with up to 3 attempts, retrying only TRANSIENT failures
  /// (timeouts / dropped connections / 502-503-504). Non-transient errors
  /// (auth / 4xx) rethrow immediately. Mirrors [_browseLibraryWithRetry] for
  /// the static library reference routes.
  Future<Map<String, dynamic>> _getMapWithRetry(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    const maxAttempts = 3;
    for (var attempt = 1;; attempt++) {
      try {
        final resp = await _client.get(
          path,
          queryParameters: query == null || query.isEmpty ? null : query,
        );
        return Map<String, dynamic>.from(resp.data as Map);
      } on DioException catch (e) {
        if (attempt >= maxAttempts || !_isTransientLibraryFailure(e)) rethrow;
        await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
      }
    }
  }

  /// GET /library/{program_id} — full structured preview of one program.
  Future<ProgramTemplate> previewLibraryProgram(String programId) async {
    debugPrint('🏋️ [ProgramTemplate] previewLibraryProgram | id=$programId');
    final resp = await _client.get('$_base/library/$programId');
    return ProgramTemplate.fromJson(
      Map<String, dynamic>.from(resp.data as Map),
    );
  }

  /// GET /library/{program_id} — the SAME endpoint as [previewLibraryProgram],
  /// but parsed into BOTH the editorial card (name/tagline/who-for/phases/
  /// joined_count) and the normalized sample-week template (name/days). The
  /// detail page needs both: the card-level editorial + phase content for the
  /// Overview tab, and the day-by-day for the Schedule tab. One request, two
  /// views over the same payload (the backend merges card fields + `**normalized`).
  Future<({ProgramLibraryCard card, ProgramTemplate sampleWeek})>
      getLibraryDetail(String programId) async {
    debugPrint('🏋️ [ProgramTemplate] getLibraryDetail | id=$programId');
    // Retry transient failures (e.g. a backend deploy restart) so the detail
    // header + variant picker don't blank out on a single blip, matching the
    // browse/featured/recommended routes.
    final data = await _getMapWithRetry('$_base/library/$programId');
    // Write-through to disk so the next open of this program paints the real
    // detail (phases / variants / joined) instantly instead of the browse
    // card's fabricated placeholder. Raw payload — round-trips through the same
    // fromJson on read (see [cachedLibraryDetail]).
    _cacheRaw(_detailCacheKey(programId), data);
    // The detail payload carries the id as `program_id` (not `id`), so seed the
    // id the card model reads — preserving the caller's prefixed/branded form
    // — before parsing. Don't clobber an `id` if the backend ever sends one.
    final cardData = Map<String, dynamic>.from(data);
    cardData.putIfAbsent('id', () => data['program_id'] ?? programId);
    if ((cardData['id']?.toString() ?? '').isEmpty) {
      cardData['id'] = programId;
    }
    return (
      card: ProgramLibraryCard.fromJson(cardData),
      sampleWeek: ProgramTemplate.fromJson(data),
    );
  }

  // -------------------------------------------------------------------------
  // Favorites — the user's hearted library programs (Your Programs hub).
  // -------------------------------------------------------------------------

  /// GET /favorites — the user's favorited library programs as full cards.
  Future<List<ProgramLibraryCard>> listFavorites() async {
    debugPrint('🏋️ [ProgramTemplate] listFavorites');
    final resp = await _client.get('$_base/favorites');
    final data = Map<String, dynamic>.from(resp.data as Map);
    final raw = data['programs'];
    final out = <ProgramLibraryCard>[];
    if (raw is List) {
      for (final p in raw) {
        if (p is Map) {
          out.add(ProgramLibraryCard.fromJson(Map<String, dynamic>.from(p)));
        }
      }
    }
    return out;
  }

  /// GET /favorites/ids — just the favorited program ids (drives heart state).
  Future<Set<String>> favoriteIds() async {
    debugPrint('🏋️ [ProgramTemplate] favoriteIds');
    final resp = await _client.get('$_base/favorites/ids');
    final data = Map<String, dynamic>.from(resp.data as Map);
    final raw = data['program_ids'];
    final out = <String>{};
    if (raw is List) {
      for (final id in raw) {
        final s = id?.toString();
        if (s != null && s.isNotEmpty) out.add(s);
      }
    }
    return out;
  }

  /// POST /favorites {program_id} — favorite a program.
  Future<void> addFavorite(String programId) async {
    debugPrint('🏋️ [ProgramTemplate] addFavorite | id=$programId');
    await _client.post('$_base/favorites', data: {'program_id': programId});
  }

  /// DELETE /favorites/{program_id} — un-favorite a program.
  Future<void> removeFavorite(String programId) async {
    debugPrint('🏋️ [ProgramTemplate] removeFavorite | id=$programId');
    await _client.delete('$_base/favorites/$programId');
  }

  /// POST /from-program/{program_id} — clone a library program into a NEW
  /// editable saved template. Returns the saved row.
  ///
  /// Throws [ProgramParseException] with `parse_error` if the source program
  /// has no structured workouts (the backend 422s).
  Future<ProgramTemplate> importFromProgram(String programId) async {
    debugPrint('🏋️ [ProgramTemplate] importFromProgram | id=$programId');
    try {
      final resp = await _client.post('$_base/from-program/$programId');
      return ProgramTemplate.fromJson(
        Map<String, dynamic>.from(resp.data as Map),
      );
    } on DioException catch (e) {
      throw _mapParseError(e) ?? e;
    }
  }

  // -------------------------------------------------------------------------
  // Assign — enroll the user in a library program (slot/days/start-date) and
  // expand it forward into scheduled workouts. The unified "Start program"
  // flow (Primary vs Add-on, Replace vs Run-alongside) calls this.
  // -------------------------------------------------------------------------

  /// POST /assign — enroll the user in a library program.
  ///
  /// [programId] is the library card id (curated plain id or branded uuid —
  /// pass the bare uuid for branded). [assignedDays] are weekday ints
  /// 0=Mon..6=Sun the program occupies. [slot] is `primary` | `addon`.
  /// [startDate] is `YYYY-MM-DD`. [replace] (primary only) replaces the current
  /// primary instead of running alongside. [durationWeeks] optionally overrides
  /// the program's length. [customize] carries the AI-tailoring toggles.
  /// [variantId] — when the program has multiple variants, pass the chosen
  /// `ProgramVariantOption.variantId`; null falls back to the single plan.
  Future<AssignResult> assignProgram({
    required String programId,
    required List<int> assignedDays,
    required ProgramSlot slot,
    required String startDate,
    bool replace = false,
    int? durationWeeks,
    bool adaptToLevel = false,
    bool swapForInjuries = false,
    bool fitEquipment = false,
    String? variantId,
    Map<String, String>? dayResolutions,
  }) async {
    final body = <String, dynamic>{
      'program_id': programId,
      'assigned_days': assignedDays,
      'slot': slot == ProgramSlot.addon ? 'addon' : 'primary',
      'start_date': startDate,
      'replace': replace,
      if (durationWeeks != null) 'duration_weeks': durationWeeks,
      if (variantId != null && variantId.isNotEmpty) 'variant_id': variantId,
      // Per-day overlap resolution — same shape preview sent (parity).
      if (dayResolutions != null && dayResolutions.isNotEmpty)
        'day_resolutions': dayResolutions,
      if (adaptToLevel || swapForInjuries || fitEquipment)
        'customize': {
          'adapt_to_level': adaptToLevel,
          'swap_for_injuries': swapForInjuries,
          'fit_equipment': fitEquipment,
        },
    };
    debugPrint('🏋️ [ProgramTemplate] assignProgram | id=$programId '
        'slot=${body['slot']} days=$assignedDays replace=$replace '
        'variant=$variantId');
    try {
      final resp = await _client.post('$_base/assign', data: body);
      return AssignResult.fromJson(
        Map<String, dynamic>.from(resp.data as Map),
      );
    } on DioException catch (e) {
      throw _mapParseError(e) ?? e;
    }
  }

  /// Shared request body for the assign / assign-preview / assign-review trio.
  /// Kept in one place so the live preview is GUARANTEED to send the exact same
  /// args the real [assignProgram] call will — otherwise the preview could lie.
  Map<String, dynamic> _assignBody({
    required String programId,
    required List<int> assignedDays,
    required ProgramSlot slot,
    required String startDate,
    required bool replace,
    int? durationWeeks,
    String? variantId,
    Map<String, String>? dayResolutions,
    bool adaptToLevel = false,
    bool swapForInjuries = false,
    bool fitEquipment = false,
  }) {
    return <String, dynamic>{
      'program_id': programId,
      'assigned_days': assignedDays,
      'slot': slot == ProgramSlot.addon ? 'addon' : 'primary',
      'start_date': startDate,
      'replace': replace,
      if (durationWeeks != null) 'duration_weeks': durationWeeks,
      // The EXACT variant the user picked (weeks × sessions). Sent on BOTH
      // preview and commit so the backend schedules that variant's
      // program_variant_weeks — not a duration-only default — keeping the
      // picker, totals, and what's scheduled in lockstep.
      if (variantId != null && variantId.isNotEmpty) 'variant_id': variantId,
      // Per-day overlap resolution: { "YYYY-MM-DD": "replace" | "add" } for the
      // first-week conflict days. Sent on BOTH preview and commit so they agree.
      if (dayResolutions != null && dayResolutions.isNotEmpty)
        'day_resolutions': dayResolutions,
      // AI-tailoring toggles — sent on the PREVIEW so the live estimate matches
      // what commit will do (mirrors [assignProgram]'s customize block).
      if (adaptToLevel || swapForInjuries || fitEquipment)
        'customize': {
          'adapt_to_level': adaptToLevel,
          'swap_for_injuries': swapForInjuries,
          'fit_equipment': fitEquipment,
        },
    };
  }

  /// POST /assign-preview — a deterministic, LLM-free projection of what
  /// assigning this program will SCHEDULE and OVERLAP (week-by-week days +
  /// collisions + impact counts + a one-line summary). Drives the live schedule
  /// preview in the Start flow. Same args as [assignProgram]; lets Dio
  /// exceptions bubble so the sheet can show a "couldn't preview" + Retry.
  Future<AssignPreview> previewAssignment({
    required String programId,
    required List<int> assignedDays,
    required ProgramSlot slot,
    required String startDate,
    bool replace = false,
    int? durationWeeks,
    String? variantId,
    Map<String, String>? dayResolutions,
    bool adaptToLevel = false,
    bool swapForInjuries = false,
    bool fitEquipment = false,
  }) async {
    final body = _assignBody(
      programId: programId,
      assignedDays: assignedDays,
      slot: slot,
      startDate: startDate,
      replace: replace,
      durationWeeks: durationWeeks,
      variantId: variantId,
      dayResolutions: dayResolutions,
      adaptToLevel: adaptToLevel,
      swapForInjuries: swapForInjuries,
      fitEquipment: fitEquipment,
    );
    debugPrint('🏋️ [ProgramTemplate] previewAssignment | id=$programId '
        'slot=${body['slot']} days=$assignedDays replace=$replace '
        'variant=$variantId');
    final resp = await _client.post('$_base/assign-preview', data: body);
    return AssignPreview.fromJson(
      Map<String, dynamic>.from(resp.data as Map),
    );
  }

  /// POST /assign-review — a 1-2 sentence AI coach take on this assignment.
  /// Fail-SOFT: returns the `review` string, falling back to the deterministic
  /// `summary` then '' on ANY error. NEVER throws to the UI — the preview /
  /// confirm flow must keep working even when the LLM is down.
  Future<String> assignmentReview({
    required String programId,
    required List<int> assignedDays,
    required ProgramSlot slot,
    required String startDate,
    bool replace = false,
    int? durationWeeks,
    String? variantId,
    Map<String, String>? dayResolutions,
  }) async {
    final body = _assignBody(
      programId: programId,
      assignedDays: assignedDays,
      slot: slot,
      startDate: startDate,
      replace: replace,
      durationWeeks: durationWeeks,
      variantId: variantId,
      dayResolutions: dayResolutions,
    );
    debugPrint('🤖 [ProgramTemplate] assignmentReview | id=$programId '
        'slot=${body['slot']} days=$assignedDays replace=$replace '
        'variant=$variantId');
    try {
      final resp = await _client.post('$_base/assign-review', data: body);
      final data = Map<String, dynamic>.from(resp.data as Map);
      final review = data['review']?.toString().trim() ?? '';
      if (review.isNotEmpty) return review;
      return data['summary']?.toString().trim() ?? '';
    } catch (e) {
      debugPrint('⚠️ [ProgramTemplate] assignmentReview failed (soft): $e');
      return '';
    }
  }

  // -------------------------------------------------------------------------
  // Parse — free-text → reviewable (NOT saved) template draft.
  // -------------------------------------------------------------------------

  /// POST /parse — parse a free-text program description.
  ///
  /// The response is a DRAFT (`source='parsed'`, no `id`). The user reviews /
  /// edits it, then calls [createTemplate] to persist.
  ///
  /// Throws [ProgramParseException] on a 422 — `not_a_program` when the text
  /// was not a workout program, `parse_error` when parsing failed outright.
  Future<ProgramTemplate> parseDescription(String description) async {
    debugPrint(
        '🤖 [ProgramTemplate] parseDescription | len=${description.length}');
    try {
      final resp = await _client.post(
        '$_base/parse',
        data: {'description': description},
      );
      return ProgramTemplate.fromJson(
        Map<String, dynamic>.from(resp.data as Map),
      );
    } on DioException catch (e) {
      throw _mapParseError(e) ?? e;
    }
  }

  /// POST /import-photo — OCR a photo/PDF of a written program into a DRAFT
  /// template (`source='imported'`, no `id`). The user reviews / edits it in
  /// the builder, then calls [createTemplate] to persist.
  ///
  /// Pass EITHER [imageBase64] + [mimeType] (in-memory bytes) OR [s3Key] (an
  /// already-uploaded object). Throws [ProgramParseException] on a 422 —
  /// `not_a_program` when the image wasn't a program, `parse_error` otherwise.
  Future<ProgramTemplate> importFromPhoto({
    String? imageBase64,
    String? mimeType,
    String? s3Key,
  }) async {
    final body = <String, dynamic>{};
    if (s3Key != null && s3Key.isNotEmpty) {
      body['s3_key'] = s3Key;
    } else if (imageBase64 != null && imageBase64.isNotEmpty) {
      body['image_base64'] = imageBase64;
      body['mime_type'] = mimeType ?? 'image/jpeg';
    } else {
      throw const ProgramParseException(
        'parse_error',
        'No image provided. Pick a photo or PDF of your program first.',
      );
    }
    debugPrint('🤖 [ProgramTemplate] importFromPhoto | '
        '${s3Key != null ? 's3=$s3Key' : 'bytes=${imageBase64?.length}'}');
    try {
      final resp = await _client.post('$_base/import-photo', data: body);
      return ProgramTemplate.fromJson(
        Map<String, dynamic>.from(resp.data as Map),
      );
    } on DioException catch (e) {
      throw _mapParseError(e) ?? e;
    }
  }

  // -------------------------------------------------------------------------
  // CRUD.
  // -------------------------------------------------------------------------

  /// POST / — create a template from authored / parsed JSON.
  ///
  /// Throws [ProgramParseException] (`parse_error`) if every day is rest —
  /// the backend rejects an all-rest program.
  Future<ProgramTemplate> createTemplate(ProgramTemplate template) async {
    debugPrint('🏋️ [ProgramTemplate] createTemplate | name=${template.name}');
    try {
      final resp = await _client.post(
        _base,
        data: template.toCreateJson(),
      );
      return ProgramTemplate.fromJson(
        Map<String, dynamic>.from(resp.data as Map),
      );
    } on DioException catch (e) {
      throw _mapParseError(e) ?? e;
    }
  }

  /// GET /user/{user_id} — list templates owned by a user.
  Future<List<ProgramTemplate>> listForUser(String userId) async {
    debugPrint('🏋️ [ProgramTemplate] listForUser | user=$userId');
    final resp = await _client.get('$_base/user/$userId');
    final data = resp.data;
    final list = data is List
        ? data
        : (data is Map ? (data['templates'] as List? ?? const []) : const []);
    return list
        .whereType<Object>()
        .map((e) =>
            ProgramTemplate.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// GET /{template_id} — fetch one saved template.
  Future<ProgramTemplate> getTemplate(String templateId) async {
    debugPrint('🏋️ [ProgramTemplate] getTemplate | id=$templateId');
    final resp = await _client.get('$_base/$templateId');
    return ProgramTemplate.fromJson(
      Map<String, dynamic>.from(resp.data as Map),
    );
  }

  /// PATCH /{template_id} — edit a saved template.
  Future<ProgramTemplate> updateTemplate(
    String templateId,
    ProgramTemplate template,
  ) async {
    debugPrint('🏋️ [ProgramTemplate] updateTemplate | id=$templateId');
    final resp = await _client.patch(
      '$_base/$templateId',
      data: template.toCreateJson(),
    );
    return ProgramTemplate.fromJson(
      Map<String, dynamic>.from(resp.data as Map),
    );
  }

  /// DELETE /{template_id} — delete a saved template.
  Future<void> deleteTemplate(String templateId) async {
    debugPrint('🏋️ [ProgramTemplate] deleteTemplate | id=$templateId');
    await _client.delete('$_base/$templateId');
  }

  // -------------------------------------------------------------------------
  // Scheduling.
  // -------------------------------------------------------------------------

  /// POST /{template_id}/schedule — expand a template forward into workouts.
  ///
  /// [startDate] must be `YYYY-MM-DD`. [weeks] is clamped 1..12 by the caller.
  /// [dayAlignment] is `start_today` or `calendar_weekday`. [dayTimes] maps a
  /// stringified day index to a `HH:MM` user-local time; absent days default
  /// to noon server-side.
  Future<ScheduleResult> scheduleTemplate(
    String templateId, {
    required String startDate,
    required int weeks,
    required String dayAlignment,
    required Map<String, String> dayTimes,
  }) async {
    debugPrint(
        '🏋️ [ProgramTemplate] scheduleTemplate | id=$templateId weeks=$weeks '
        'align=$dayAlignment times=${dayTimes.length}');
    final resp = await _client.post(
      '$_base/$templateId/schedule',
      data: {
        'start_date': startDate,
        'weeks': weeks,
        'day_alignment': dayAlignment,
        'day_times': dayTimes,
      },
    );
    return ScheduleResult.fromJson(
      Map<String, dynamic>.from(resp.data as Map),
    );
  }

  /// POST /{template_id}/regenerate-future — rebuild not-yet-completed
  /// workouts after a template edit.
  Future<ScheduleResult> regenerateFuture(String templateId) async {
    debugPrint('🏋️ [ProgramTemplate] regenerateFuture | id=$templateId');
    final resp = await _client.post('$_base/$templateId/regenerate-future');
    return ScheduleResult.fromJson(
      Map<String, dynamic>.from(resp.data as Map),
    );
  }

  // -------------------------------------------------------------------------
  // Library schedule — multi-week, variant-aware day-by-day breakdown.
  // -------------------------------------------------------------------------

  /// GET /library/{program_id}/schedule?variant_id={uuid} — fetch the
  /// multi-week day-by-day schedule for a library program, optionally scoped
  /// to a specific variant.
  ///
  /// When [variantId] is null, the backend uses `default_variant_id` for
  /// multi-variant programs, or the single plan's workouts for single-plan
  /// programs. Exercises carry presigned media URLs where the library has them.
  Future<ProgramScheduleResponse> getLibrarySchedule(
    String programId, {
    String? variantId,
  }) async {
    debugPrint('🏋️ [ProgramTemplate] getLibrarySchedule | '
        'id=$programId variant=$variantId');
    final query = <String, dynamic>{};
    if (variantId != null && variantId.isNotEmpty) {
      query['variant_id'] = variantId;
    }
    // Retry transient failures (e.g. a backend deploy restart) so the Schedule
    // tab doesn't show "We could not load this program" on a single blip,
    // matching the browse/featured/recommended routes.
    final data = await _getMapWithRetry(
      '$_base/library/$programId/schedule',
      query: query,
    );
    return ProgramScheduleResponse.fromJson(data);
  }

  /// GET /library/{program_id}/equipment-coverage — pre-flight equipment
  /// fit-check of a curated program against a gym profile (defaults to the
  /// user's active profile). Read-only; the backend never blocks on it.
  ///
  /// [variantId] scopes the check to a specific variant (the selected
  /// duration/sessions option); [gymProfileId] overrides the active profile.
  Future<EquipmentCoverage> getEquipmentCoverage(
    String programId, {
    String? variantId,
    String? gymProfileId,
  }) async {
    final query = <String, dynamic>{};
    if (variantId != null && variantId.isNotEmpty) {
      query['variant_id'] = variantId;
    }
    if (gymProfileId != null && gymProfileId.isNotEmpty) {
      query['gym_profile_id'] = gymProfileId;
    }
    final data = await _getMapWithRetry(
      '$_base/library/$programId/equipment-coverage',
      query: query,
    );
    return EquipmentCoverage.fromJson(data);
  }

  // -------------------------------------------------------------------------
  // Error mapping.
  // -------------------------------------------------------------------------

  /// Maps a 422 Dio response carrying `{error, message}` into a typed
  /// [ProgramParseException]. Returns null when the error is something else
  /// so the caller can rethrow the original [DioException].
  ProgramParseException? _mapParseError(DioException e) {
    final resp = e.response;
    if (resp == null || resp.statusCode != 422) return null;
    final body = resp.data;
    if (body is Map) {
      final code = body['error']?.toString();
      if (code != null && code.isNotEmpty) {
        final msg = body['message']?.toString() ??
            'We could not read that program. Please check the format and try again.';
        return ProgramParseException(code, msg);
      }
      // FastAPI's default 422 shape — surface as a generic parse error.
      final detail = body['detail'];
      if (detail != null) {
        return ProgramParseException('parse_error', detail.toString());
      }
    }
    return ProgramParseException(
      'parse_error',
      'We could not read that program. Please check the format and try again.',
    );
  }
}
