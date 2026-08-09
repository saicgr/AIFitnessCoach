part of '../log_meal_sheet.dart';

// ════════════════════════════════════════════════════════════════════
// WS6 — Smart quick-log pills
//
// A single ranked, time/slot-aware row at the top of the log-meal sheet so
// a repeat meal is one tap away. This is a UI + ranking layer over data the
// app ALREADY exposes — it adds NO new backend endpoints:
//
//   🍲 Leftovers          — activeCookEventsProvider (GET /nutrition/
//                           cook-events/active). Floats to FRONT when a
//                           portion is expiring soon (food-waste nudge).
//   ↻ Same [slot] as       — yesterday's logs (captured from the same
//     yesterday             recent-logs fetch that builds _frequentMeals),
//                           filtered to the current slot. EXACT macros.
//   ⭐ Your usual [slot]    — usualMealProvider (GET /nutrition/usual-meal),
//                           server-computed from 30-day frequency.
//   🔁 Frequent            — reuses _deriveFrequentMeals() (logged ≥2×).
//   ↺ Log it again        — ANY recent log, incl. one filed minutes ago.
//                           This is the source that keeps the tab's own
//                           empty-state promise on day one (E2E row 101);
//                           every other source needs history the user
//                           doesn't have yet.
//
// Ranking is a deterministic local algo (<100ms, no LLM/RAG per
// feedback_prefer_local_algo_over_rag): expiring leftovers first; breakfast
// ranks yesterday/usual up; lunch/dinner rank leftovers up; de-duped across
// sources; capped at 5; horizontal scroll.
//
// On tap:
//   • EXACT-macro pills (leftover w/ a recipe, yesterday's logged meal) →
//     one-tap OPTIMISTIC POST /nutrition/log-direct (idempotent + spliceLog)
//     with a "Logged · Edit / Undo" snackbar; leftovers also decrement
//     portions_remaining via logRecipe's DB trigger.
//   • FUZZY pills (frequent / usual needing a fresh portion estimate) → the
//     existing editable analysis confirm flow (_relogFrequentMeal) — never a
//     blind copy (feedback_logged_data_durability / C8).
// ════════════════════════════════════════════════════════════════════

/// The kind of source a smart pill came from — drives icon, copy, and the
/// tap behaviour (exact-macro one-tap log vs. fuzzy re-analyse).
enum _SmartPillKind { leftover, yesterday, usual, frequent, recent }

/// One ranked pill in the smart quick-log row.
class _SmartPill {
  final _SmartPillKind kind;

  /// The bold title line (e.g. "Roast chicken", "Same breakfast").
  final String title;

  /// The muted subtitle line (e.g. "2 left · use by Thu", "280 cal").
  final String subtitle;

  /// Leading glyph (emoji) — 🍲 / ↻ / ⭐ / 🔁.
  final String glyph;

  /// Computed rank score — higher sorts first. Set by the ranker.
  final double score;

  /// A stable de-dupe signature (lower-cased item-name set) so the same
  /// meal arriving from two sources only shows once.
  final String dedupeKey;

  /// EXACT-macro one-tap path: present for leftover + yesterday pills.
  /// When non-null, tapping logs this immediately (optimistic) instead of
  /// routing through the editable analysis flow.
  final ActiveCookEvent? leftover;
  final FoodLog? exactLog;

  /// FUZZY path: present for frequent / usual pills — routes through the
  /// editable re-analyse confirm flow so the portion is re-estimated.
  final _FrequentMeal? fuzzyMeal;

  const _SmartPill({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.glyph,
    required this.score,
    required this.dedupeKey,
    this.leftover,
    this.exactLog,
    this.fuzzyMeal,
  });

  bool get isExact => leftover != null || exactLog != null;
}

extension __LogMealSheetStateQuickPills on _LogMealSheetState {
  // ─── Source loading ───────────────────────────────────────────

  /// Filter [logs] down to the ones logged "yesterday" in device-local
  /// time. The recent-logs fetch is newest-first across dates, so a simple
  /// per-row date compare is enough. Empty when nothing was logged
  /// yesterday (no mock/fallback — the pill simply won't appear).
  List<FoodLog> _yesterdayLogsFrom(List<FoodLog> logs) {
    final now = DateTime.now();
    final y = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 1));
    return logs.where((l) {
      final d = l.loggedAt.toLocal();
      return d.year == y.year && d.month == y.month && d.day == y.day;
    }).toList();
  }

  /// Fetch the leftover (cook-events) source for the smart-pill row. Marks
  /// the row loaded even on failure so it resolves to its other sources or
  /// hides — never a forever-skeleton (mirrors _loadFrequentMeals' C8).
  Future<void> _loadSmartPillSources() async {
    if (widget.userId.isEmpty) {
      if (mounted) setState(() => _smartPillsLoaded = true);
      return;
    }
    try {
      final events =
          await ref.read(activeCookEventsProvider(widget.userId).future);
      if (!mounted) return;
      setState(() {
        _leftoverEvents = events;
        _smartPillsLoaded = true;
      });
      debugPrint('🍲 [WS6] Leftover pills loaded | count=${events.length}');
    } catch (e) {
      debugPrint('🍲 [WS6] Leftover pill load failed: $e');
      if (!mounted) return;
      // No fallback data — on failure the leftover source is simply empty.
      setState(() {
        _leftoverEvents = const [];
        _smartPillsLoaded = true;
      });
    }
  }

  // ─── Ranking ──────────────────────────────────────────────────

  /// Build the ranked, de-duped, capped pill list for the current slot.
  /// Deterministic, synchronous, <100ms — reads only already-loaded state.
  List<_SmartPill> _rankedSmartPills() {
    final slot = _selectedMealType;
    final isBreakfast = slot == MealType.breakfast;
    final isMainMeal = slot == MealType.lunch || slot == MealType.dinner;

    final pills = <_SmartPill>[];
    final seen = <String>{};

    // Helper — add a pill only if its de-dupe key is new.
    bool add(_SmartPill p) {
      if (p.dedupeKey.isNotEmpty && !seen.add(p.dedupeKey)) return false;
      pills.add(p);
      return true;
    }

    // 1) Leftovers. Expiring-soon always floats to the very front; a normal
    //    leftover ranks a bit higher for lunch/dinner (the slots people
    //    actually eat leftovers) than for breakfast.
    for (final ev in _leftoverEvents) {
      if (ev.isExpired) continue; // don't push an expired portion
      final remaining = ev.portionsRemaining;
      if (remaining <= 0) continue;
      // The one-tap leftover log reuses `logRecipe`, which needs a recipe id.
      // A leftover with no linked recipe can't be one-tapped here — skip it
      // (the Daily-tab carousel still surfaces it via its own path).
      if (ev.recipeId == null || ev.recipeId!.isEmpty) continue;
      double base = isMainMeal ? 90 : 78;
      if (ev.isExpiringSoon) base = 130; // food-waste nudge wins outright
      add(_SmartPill(
        kind: _SmartPillKind.leftover,
        title: ev.recipeName ?? _leftoverFallbackTitle(),
        subtitle: _leftoverSubtitle(ev),
        glyph: '🍲',
        score: base,
        dedupeKey: 'leftover::${ev.id}',
        leftover: ev,
      ));
    }

    // 2) Same [slot] as yesterday — exact macros, so a one-tap log. Pick the
    //    single most substantial yesterday log for this slot (most calories)
    //    so we surface the "real" meal, not a stray snack mis-slotted.
    final yMatches = _yesterdayLogs
        .where((l) => MealType.fromValue(l.mealType) == slot)
        .where((l) => l.foodItems.isNotEmpty || l.totalCalories > 0)
        .toList()
      ..sort((a, b) => b.totalCalories.compareTo(a.totalCalories));
    if (yMatches.isNotEmpty) {
      final log = yMatches.first;
      // Breakfast is the most habitual slot → rank yesterday up there.
      final base = isBreakfast ? 100.0 : 84.0;
      add(_SmartPill(
        kind: _SmartPillKind.yesterday,
        title: _yesterdayTitle(slot, log),
        subtitle: _exactMacroSubtitle(log.totalCalories),
        glyph: '↻',
        score: base,
        dedupeKey: _logDedupeKey(slot, _logNames(log)),
        exactLog: log,
      ));
    }

    // 3) Your usual [slot] — server-computed (usualMealProvider). Fuzzy:
    //    routes through the editable re-analyse flow so the portion is fresh.
    final usual = ref.watch(usualMealProvider(slot.value)).valueOrNull;
    if (usual != null && usual.itemNames.isNotEmpty) {
      final base = isBreakfast ? 92.0 : 70.0;
      final analysisText = usual.summary?.trim().isNotEmpty == true
          ? usual.summary!.trim()
          : usual.itemNames.join(', ');
      add(_SmartPill(
        kind: _SmartPillKind.usual,
        title: _usualTitle(slot),
        subtitle: usual.totalCalories > 0
            ? _approxMacroSubtitle(usual.totalCalories)
            : usual.itemNames.take(2).join(', '),
        glyph: '⭐',
        score: base,
        dedupeKey: _logDedupeKey(slot, usual.itemNames),
        fuzzyMeal: _FrequentMeal(
          label: usual.itemNames.join(', '),
          mealType: slot,
          timesLogged: 0,
          calories: usual.totalCalories,
          analysisText: analysisText,
          itemNames: usual.itemNames,
        ),
      ));
    }

    // 4) Recent / frequent — reuse the existing derivation. Prefer this
    //    slot's repeats; fall back to the user's overall top repeats so the
    //    row is still useful on a slot they've never logged before.
    final freqForSlot = _frequentMeals.where((m) => m.mealType == slot).toList();
    final freqPool =
        freqForSlot.isNotEmpty ? freqForSlot : _frequentMeals;
    for (final m in freqPool) {
      // Frequency bumps the score within the frequent tier; this keeps the
      // user's heaviest repeats ahead of one-off-ish twice-logged meals.
      final base = 40 + (m.timesLogged.clamp(0, 12) * 2).toDouble() +
          (m.mealType == slot ? 6 : 0);
      add(_SmartPill(
        kind: _SmartPillKind.frequent,
        title: m.label,
        subtitle: m.calories > 0
            ? '${_approxMacroSubtitle(m.calories)} · ${m.timesLogged}×'
            : 'Logged ${m.timesLogged}×',
        glyph: '🔁',
        score: base,
        // Key on the NAME SET, never the joined display label: every other
        // source keys on the set, so `[m.label]` ("whole egg, toast, banana")
        // could never collapse against a "banana|toast|whole egg" key and the
        // same meal rendered twice — once here and once as a ↺ recent pill.
        dedupeKey: _logDedupeKey(m.mealType, m.itemNames),
        fuzzyMeal: m,
      ));
    }

    // 5) Recent — ANY log the user has filed recently, including one logged
    //    minutes ago. Exact macros (they are the user's own numbers), so this
    //    is a one-tap re-log. This is the source that makes the tab's own
    //    empty-state copy true from the FIRST meal (E2E row 101): leftovers
    //    need a cook event, "yesterday" needs a log from yesterday, "usual"
    //    needs 30 days of history and "frequent" needs the same meal ≥2×, so
    //    a day-one user with three logs used to match none of them.
    //    Ranked below every intentional source, ahead of nothing at all;
    //    this slot's logs outrank other slots'.
    final recentForSlot = <FoodLog>[];
    final recentOther = <FoodLog>[];
    for (final l in _recentLogs) {
      if (l.foodItems.isEmpty && l.totalCalories <= 0) continue;
      if (MealType.fromValue(l.mealType) == slot) {
        recentForSlot.add(l);
      } else {
        recentOther.add(l);
      }
    }
    for (final log in [...recentForSlot, ...recentOther]) {
      final logSlot = MealType.fromValue(log.mealType);
      final sameSlot = logSlot == slot;
      add(_SmartPill(
        kind: _SmartPillKind.recent,
        title: _recentTitle(log),
        // Row #189: two "log it again" pills for the SAME food logged under
        // different meal slots are de-duped per-slot, so both render — but
        // shared an identical title AND (by chance, from the shared
        // minute-seeded copy pool) often an identical subtitle too, making
        // them indistinguishable. Prefix the cross-slot copy with its slot
        // so it's the deterministic differentiator, not luck-of-the-minute.
        subtitle: sameSlot
            ? _exactMacroSubtitle(log.totalCalories)
            : '${logSlot.label} · ${_exactMacroSubtitle(log.totalCalories)}',
        glyph: '↺',
        score: sameSlot ? 34 : 26,
        // Key on the log's OWN slot (not the selected one) so it shares a key
        // space with the frequent/yesterday pills, which key on the meal's own
        // slot — otherwise a frequent breakfast surfaced while the dinner slot
        // is selected would duplicate as a recent pill.
        dedupeKey: _logDedupeKey(logSlot, _logNames(log)),
        exactLog: log,
      ));
    }

    // Deterministic order. `List.sort` is explicitly NOT stable in Dart, and
    // the recent source can contribute dozens of pills that all carry the same
    // score — so a plain score sort reordered them arbitrarily and the meal the
    // user logged sixty seconds ago could fall out of the top 5 entirely
    // (measured: with 60 equal-score pills the newest landed 20th). Insertion
    // order is meaningful — sources are appended best-first and `_recentLogs`
    // arrives newest-first — so ties break on it.
    final ordered = <MapEntry<int, _SmartPill>>[
      for (int i = 0; i < pills.length; i++) MapEntry(i, pills[i]),
    ]..sort((a, b) {
        final byScore = b.value.score.compareTo(a.value.score);
        return byScore != 0 ? byScore : a.key.compareTo(b.key);
      });
    return [for (final e in ordered.take(5)) e.value];
  }

  /// De-dupe signature shared across sources: slot + sorted lower-cased
  /// item-name set (so yesterday's "eggs, toast" and a frequent "toast,
  /// eggs" collapse to one pill).
  String _logDedupeKey(MealType slot, Iterable<String> names) {
    final norm = names
        .map((n) => n.trim().toLowerCase())
        .where((n) => n.isNotEmpty)
        .toList()
      ..sort();
    if (norm.isEmpty) return '';
    return '${slot.value}::${norm.join('|')}';
  }

  // ─── Dynamic copy (variant pools + exact substitution) ────────
  //
  // Per feedback_dynamic_copy_not_robotic: vary the human-facing label from
  // a small pool and substitute exact data, so the row doesn't read like the
  // same robotic string every open. The variant is chosen deterministically
  // from a per-open seed so a single sheet session is stable (no flicker on
  // rebuild) but successive opens rotate.

  int get _copySeed {
    // Stable for the life of the sheet (seeded once on first build of the
    // pills), rotates across opens via the meal-slot + minute.
    return (_selectedMealType.index * 7 + DateTime.now().minute) & 0x7fffffff;
  }

  String _pick(List<String> pool) => pool[_copySeed % pool.length];

  String _yesterdayTitle(MealType slot, FoodLog log) {
    final names = log.foodItems
        .map((i) => i.name.trim())
        .where((n) => n.isNotEmpty)
        .toList();
    // Prefer the actual food when it's a tidy one/two-item meal; otherwise a
    // "Same <slot> as yesterday" framing reads cleaner than a long list.
    if (names.length == 1) {
      return _pick(['${names.first} again', 'Repeat ${names.first.toLowerCase()}']);
    }
    if (names.length == 2) {
      return '${names[0]} + ${names[1]}';
    }
    return _pick([
      'Same ${slot.label.toLowerCase()} as yesterday',
      "Yesterday's ${slot.label.toLowerCase()}",
      'Repeat ${slot.label.toLowerCase()}',
    ]);
  }

  /// The food names that identify a log — its itemised foods, or the user's
  /// own query when the log carries no items (a bare calorie entry still has
  /// an identity, and without one every such log would share an empty dedupe
  /// key and stack up as duplicate pills).
  List<String> _logNames(FoodLog log) {
    final names = log.foodItems
        .map((i) => i.name.trim())
        .where((n) => n.isNotEmpty)
        .toList();
    if (names.isNotEmpty) return names;
    final q = (log.userQuery ?? '').trim();
    return q.isEmpty ? const [] : [q];
  }

  /// Title for a "log it again" pill. Names the actual food when it is a tidy
  /// one/two-item meal; otherwise the slot it was logged under + how long ago,
  /// which is what makes two same-day logs distinguishable in the list.
  String _recentTitle(FoodLog log) {
    final names = _logNames(log);
    if (names.length == 1) return names.first;
    if (names.length == 2) return '${names[0]} + ${names[1]}';
    if (names.length > 2) return '${names[0]} + ${names.length - 1} more';
    return MealType.fromValue(log.mealType).label;
  }

  String _usualTitle(MealType slot) => _pick([
        'Your usual ${slot.label.toLowerCase()}',
        'Usual ${slot.label.toLowerCase()}',
        'The regular',
      ]);

  String _leftoverFallbackTitle() =>
      _pick(['Leftovers', 'From the fridge', "Last night's batch"]);

  String _leftoverSubtitle(ActiveCookEvent ev) {
    final left = ev.portionsRemaining;
    final leftStr = left == left.roundToDouble()
        ? left.toInt().toString()
        : left.toStringAsFixed(1);
    final parts = <String>['$leftStr left'];
    if (ev.isExpiringSoon) {
      parts.add('use by ${_weekday(ev.expiresAt.toLocal())}');
    }
    return parts.join(' · ').toUpperCase();
  }

  String _exactMacroSubtitle(int calories) =>
      calories > 0 ? '$calories CAL · ${_pick(['EXACT', '1 TAP', 'TAP TO LOG'])}' : 'TAP TO LOG';

  String _approxMacroSubtitle(int calories) => '~$calories CAL';

  String _weekday(DateTime d) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[(d.weekday - 1).clamp(0, 6)];
  }

  // ─── Tap handlers ─────────────────────────────────────────────

  void _onSmartPillTap(_SmartPill pill) {
    final busy =
        _isAnalyzing || _describeAnalyzing || _isLoading || _smartPillLogging;
    if (busy) return;
    if (pill.leftover != null) {
      unawaited(_logLeftoverPill(pill.leftover!));
    } else if (pill.exactLog != null) {
      unawaited(_logExactPill(pill, pill.exactLog!));
    } else if (pill.fuzzyMeal != null) {
      // Fuzzy → existing editable re-analyse confirm flow (never a blind copy).
      _relogFrequentMeal(pill.fuzzyMeal!);
    }
  }

  /// One-tap log of a leftover portion. Reuses the same `logRecipe` path the
  /// Daily-tab leftovers carousel uses — the DB trigger (migration 509)
  /// decrements `portions_remaining`, and we invalidate the provider so the
  /// pill's "N left" reflects it. Optimistic + non-blocking; the sheet stays
  /// open so the user can keep logging.
  Future<void> _logLeftoverPill(ActiveCookEvent ev) async {
    setState(() => _smartPillLogging = true);
    final slot = _selectedMealType.value;
    final userId = widget.userId;
    HapticService.light();
    ref.read(posthogServiceProvider).capture(
      eventName: 'food_smart_pill_log',
      properties: <String, Object>{'kind': 'leftover'},
    );
    try {
      await ref.read(nutritionRepositoryProvider).logRecipe(
            userId: userId,
            recipeId: ev.recipeId ?? '',
            mealType: slot,
            servings: 1.0,
          );
      ref.read(mealLoggedGhostProvider.notifier).show(slot);
      ref.read(xpProvider.notifier).markMealLogged();
      // Decrement reflected: refetch leftovers so the "N left" updates, and
      // refresh the active day so the rings/list pick up the new meal.
      ref.invalidate(activeCookEventsProvider(userId));
      final notifier = ref.read(
          dailyNutritionProvider(_logSheetDateKey(widget.selectedDate))
              .notifier);
      notifier.load(userId, forceRefresh: true);
      notifier.refreshTimeline();
      notifier.refreshNutritionStats(userId);
      if (mounted) {
        // Reflect the decrement locally too so the row updates before the
        // provider refetch lands.
        setState(() {
          _leftoverEvents = _leftoverEvents
              .map((e) => e.id == ev.id
                  ? _withDecrementedPortion(e)
                  : e)
              .where((e) => e.portionsRemaining > 0)
              .toList();
        });
        _showSmartPillLoggedSnack(
          ev.recipeName ?? _leftoverFallbackTitle(),
          undo: null, // leftovers consume a portion; undo handled via re-log
        );
      }
    } catch (e) {
      debugPrint('🍲 [WS6] Leftover log failed: $e');
      if (mounted) _showSmartPillFailedSnack();
    } finally {
      if (mounted) setState(() => _smartPillLogging = false);
    }
  }

  ActiveCookEvent _withDecrementedPortion(ActiveCookEvent e) => ActiveCookEvent(
        id: e.id,
        recipeId: e.recipeId,
        recipeName: e.recipeName,
        recipeImageUrl: e.recipeImageUrl,
        cookedAt: e.cookedAt,
        portionsRemaining: (e.portionsRemaining - 1).clamp(0, double.infinity),
        portionsMade: e.portionsMade,
        storage: e.storage,
        expiresAt: e.expiresAt,
        isExpired: e.isExpired,
        isExpiringSoon: e.isExpiringSoon,
      );

  /// One-tap optimistic log of an exact-macro pill (yesterday's logged
  /// meal). Builds a [LogFoodResponse] from the stored log, splices it into
  /// the day immediately, then persists via POST /nutrition/log-direct with
  /// a fresh idempotency key — the same instant path "Log This Meal" uses,
  /// minus the sheet close. Shows a "Logged · Edit / Undo" snackbar.
  Future<void> _logExactPill(_SmartPill pill, FoodLog log) async {
    setState(() => _smartPillLogging = true);
    final userId = widget.userId;
    final mealType = _selectedMealType.value;
    HapticService.light();
    ref.read(posthogServiceProvider).capture(
      eventName: 'food_smart_pill_log',
      properties: <String, Object>{'kind': pill.kind.name},
    );

    final response = _responseFromLog(log);
    final idempotencyKey = NutritionRepository.newMealIdempotencyKey();
    final notifier = ref.read(
        dailyNutritionProvider(_logSheetDateKey(widget.selectedDate)).notifier);

    // Optimistic splice — meal appears in the day within one frame.
    final optimistic =
        notifier.spliceLog(response, mealType, userId, idempotencyKey: idempotencyKey);
    final optimisticId = optimistic.id;
    ref.read(mealLoggedGhostProvider.notifier).show(mealType);
    ref.read(xpProvider.notifier).markMealLogged();
    notifier.refreshTimeline();

    final loggedAtIso = _buildLoggedAtForSelectedDate();
    try {
      final saved = await ref.read(nutritionRepositoryProvider).logFoodDirect(
            userId: userId,
            mealType: mealType,
            analyzedFood: response,
            sourceType: 'text',
            inputType: 'copy',
            loggedAt: loggedAtIso,
            idempotencyKey: idempotencyKey,
          );
      if (saved.foodLogId != null && saved.foodLogId!.isNotEmpty) {
        notifier.reconcileLoggedMeal(optimisticId, saved.foodLogId!,
            idempotencyKey: idempotencyKey);
      }
      notifier.load(userId, forceRefresh: true);
      notifier.refreshNutritionStats(userId);
      // E2E row 101 — the sheet stays open after a one-tap log, so re-read the
      // recent-logs window; without this the meal just logged is missing from
      // the Quick-log list until the sheet is closed and reopened.
      unawaited(_loadFrequentMeals());
      if (mounted) {
        _showSmartPillLoggedSnack(
          pill.title,
          undo: () => _undoSmartPillLog(saved.foodLogId ?? optimisticId, optimisticId),
        );
      }
    } catch (e) {
      debugPrint('↻ [WS6] Exact pill log failed: $e');
      // Genuine online failure → roll the optimistic row back so we never
      // show a meal the server didn't store (no silent degradation).
      final stillOnline = await NutritionRepository.isOnline();
      if (stillOnline) {
        notifier.optimisticRemoveLog(optimisticId);
        if (mounted) _showSmartPillFailedSnack();
      }
      // Offline: the write queue keeps the optimistic row + replays it.
    } finally {
      if (mounted) setState(() => _smartPillLogging = false);
    }
  }

  /// Undo a one-tap exact log — deletes the just-created row and refreshes.
  Future<void> _undoSmartPillLog(String logId, String optimisticId) async {
    final userId = widget.userId;
    final notifier = ref.read(
        dailyNutritionProvider(_logSheetDateKey(widget.selectedDate)).notifier);
    // Remove optimistically first, then delete server-side.
    notifier.optimisticRemoveLog(optimisticId);
    if (logId != optimisticId) notifier.optimisticRemoveLog(logId);
    try {
      if (logId != optimisticId && !logId.startsWith('optimistic_')) {
        await ref.read(nutritionRepositoryProvider).deleteFoodLog(logId);
      }
      notifier.load(userId, forceRefresh: true);
      notifier.refreshNutritionStats(userId);
      notifier.refreshTimeline();
    } catch (e) {
      debugPrint('↻ [WS6] Undo failed: $e');
    }
  }

  /// Build a [LogFoodResponse] from a stored [FoodLog] so its exact macros
  /// can be re-logged via the normal optimistic log-direct path.
  LogFoodResponse _responseFromLog(FoodLog log) {
    final items = log.foodItems
        .map((i) => FoodItemRanking(
              name: i.name,
              amount: i.amount,
              calories: i.calories,
              proteinG: i.proteinG,
              carbsG: i.carbsG,
              fatG: i.fatG,
              fiberG: i.fiberG,
              weightG: i.weightG,
              unit: i.unit,
              count: i.count,
              weightPerUnitG: i.weightPerUnitG,
            ))
        .toList();
    return LogFoodResponse(
      success: true,
      foodItems: items,
      totalCalories: log.totalCalories,
      proteinG: log.proteinG,
      carbsG: log.carbsG,
      fatG: log.fatG,
      fiberG: log.fiberG,
      healthScore: log.healthScore,
      sourceType: 'text',
      sodiumMg: log.sodiumMg,
      sugarG: log.sugarG,
      saturatedFatG: log.saturatedFatG,
      cholesterolMg: log.cholesterolMg,
      potassiumMg: log.potassiumMg,
      calciumMg: log.calciumMg,
      ironMg: log.ironMg,
      vitaminCMg: log.vitaminCMg,
      vitaminDIu: log.vitaminDIu,
      inflammationScore: log.inflammationScore,
      isUltraProcessed: log.isUltraProcessed,
    );
  }

  /// Row #126: an external `ScaffoldMessenger` SnackBar renders wherever its
  /// resolved messenger's Scaffold lives, which is BELOW this modal sheet's
  /// route in z-order — `rootNavigator: true` only changes which messenger
  /// instance is FOUND, not where it paints. The sheet stays open after a
  /// one-tap log by design, so the confirmation has to be part of the sheet
  /// itself to be guaranteed visible. See [_buildSmartPillConfirmBanner].
  void _showSmartPillLoggedSnack(String title, {VoidCallback? undo}) {
    _smartPillConfirmTimer?.cancel();
    setState(() {
      _smartPillConfirmMessage = 'Logged $title';
      _smartPillConfirmUndo = undo;
      _smartPillConfirmIsError = false;
    });
    _smartPillConfirmTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() {
        _smartPillConfirmMessage = null;
        _smartPillConfirmUndo = null;
      });
    });
  }

  void _showSmartPillFailedSnack() {
    _smartPillConfirmTimer?.cancel();
    setState(() {
      _smartPillConfirmMessage =
          AppLocalizations.of(context).logMealSheetCouldnTSaveYour;
      _smartPillConfirmUndo = null;
      _smartPillConfirmIsError = true;
    });
    _smartPillConfirmTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() => _smartPillConfirmMessage = null);
    });
  }

  /// In-sheet confirmation banner — see [_showSmartPillLoggedSnack]. Empty
  /// (zero-height) when there's nothing to show, so it never reserves space
  /// it isn't using.
  Widget _buildSmartPillConfirmBanner(bool isDark) {
    final message = _smartPillConfirmMessage;
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      alignment: Alignment.topCenter,
      child: message == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              key: ValueKey(message),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: (_smartPillConfirmIsError
                          ? ThemeColors.of(context).error
                          : ThemeColors.of(context).success)
                      .withValues(alpha: isDark ? 0.16 : 0.10),  // accent-allowlist: success/error state
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (_smartPillConfirmIsError
                            ? ThemeColors.of(context).error
                            : ThemeColors.of(context).success)
                        .withValues(alpha: 0.4),  // accent-allowlist: success/error state
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _smartPillConfirmIsError
                          ? Icons.error_outline_rounded
                          : Icons.check_circle_outline_rounded,
                      size: 16,
                      color: _smartPillConfirmIsError
                          ? AppColors.error  // accent-allowlist: error state
                          : AppColors.success,  // accent-allowlist: success state
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textPrimary
                              : AppColorsLight.textPrimary,
                        ),
                      ),
                    ),
                    if (_smartPillConfirmUndo != null)
                      TextButton(
                        onPressed: () {
                          final undo = _smartPillConfirmUndo;
                          _smartPillConfirmTimer?.cancel();
                          setState(() {
                            _smartPillConfirmMessage = null;
                            _smartPillConfirmUndo = null;
                          });
                          undo?.call();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          AppLocalizations.of(context).foodHistoryUndo,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _smartPillConfirmIsError
                                ? AppColors.error  // accent-allowlist: error state
                                : AppColors.success,  // accent-allowlist: success state
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  // ─── UI ───────────────────────────────────────────────────────

  /// The ranked smart quick-log pill row. Renders at the top of the input
  /// body (above the existing frequent-meals strip). Three states:
  ///   • loading  → a slim skeleton row (never blocks the sheet)
  ///   • empty    → hidden entirely (no mock promise card)
  ///   • has data → a horizontally-scrolling row of ranked pills
  Widget _buildQuickLogPills(bool isDark) {
    final accent = AccentColorScope.of(context).getColor(isDark);
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    // Skeleton while the first source resolves. Hidden once loaded if empty.
    if (!_smartPillsLoaded && !_frequentMealsLoaded) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (int i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    width: 150,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surface : AppColorsLight.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: isDark
                              ? AppColors.cardBorder
                              : AppColorsLight.cardBorder),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    final pills = _rankedSmartPills();
    if (pills.isEmpty) return const SizedBox.shrink();

    final busy =
        _isAnalyzing || _describeAnalyzing || _isLoading || _smartPillLogging;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded, size: 14, color: accent),
              const SizedBox(width: 6),
              Text(
                AppLocalizations.of(context).quickLogOverlayQuickLog.toUpperCase(),
                style: ZType.lbl(11, color: textMuted, letterSpacing: 1.8),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            // Grow with the user's font scale so a taller pill row doesn't
            // clip its inner text at 1.2x+; clamped so it stays compact.
            height: (54 * MediaQuery.textScalerOf(context).scale(1.0))
                .clamp(54.0, 72.0),
            // E2E register #148: this is the "Quick lo…" row that sliced its
            // rightmost pill mid-word with no fade/gutter — FadingChipRow
            // fixes it.
            child: FadingChipRow(
              children: [
                for (final p in pills) _buildSmartPill(isDark, p, busy),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Vertical "Quick log" list for the food-browser `quickLog` filter tab.
  /// Renders the SAME ranked pills as the old horizontal rail, but as
  /// full-width rows, reusing the identical tap handlers (`_onSmartPillTap`
  /// → exact one-tap log vs. fuzzy re-analyse) so behaviour is unchanged.
  ///
  /// States mirror the rail: skeleton while the first source resolves, a
  /// small empty-state once loaded with no ranked pills, else the list.
  Widget _buildQuickLogList(bool isDark) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    // Row #126 — in-sheet confirmation banner (see [_showSmartPillLoggedSnack])
    // pinned above the list so a tap's result is visible without scrolling,
    // on every state of the list below (skeleton / empty / populated).
    final banner = _buildSmartPillConfirmBanner(isDark);

    // Skeleton while the first source resolves (same gate as the rail).
    if (!_smartPillsLoaded && !_frequentMealsLoaded) {
      return Column(
        children: [
          banner,
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 120),
              children: [
                for (int i = 0; i < 5; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color:
                            isDark ? AppColors.surface : AppColorsLight.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: isDark
                                ? AppColors.cardBorder
                                : AppColorsLight.cardBorder),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    }

    final pills = _rankedSmartPills();
    if (pills.isEmpty) {
      return Column(
        children: [
          banner,
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt_rounded, color: textMuted, size: 40),
                    const SizedBox(height: 12),
                    Text(
                      "No quick meals yet — log a meal and it'll show up here",
                      style:
                          TextStyle(color: textMuted, fontSize: 14, height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    final busy =
        _isAnalyzing || _describeAnalyzing || _isLoading || _smartPillLogging;

    return Column(
      children: [
        banner,
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 120),
            itemCount: pills.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _buildSmartPill(isDark, pills[i], busy,
                fullWidth: true),
          ),
        ),
      ],
    );
  }

  Widget _buildSmartPill(bool isDark, _SmartPill pill, bool busy,
      {bool fullWidth = false}) {
    final accent = AccentColorScope.of(context).getColor(isDark);
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final surface = isDark ? AppColors.surface : AppColorsLight.surface;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    // Expiring leftovers get a warm warning edge (food-waste nudge); exact
    // one-tap pills get a subtle accent edge to telegraph "instant".
    final expiring = pill.kind == _SmartPillKind.leftover &&
        (pill.leftover?.isExpiringSoon ?? false);
    final edge = expiring
        ? (isDark ? AppColors.warning : AppColorsLight.warning)  // accent-allowlist: warning severity
        : pill.isExact
            ? accent.withValues(alpha: 0.45)
            : cardBorder;

    return Opacity(
      opacity: busy ? 0.5 : 1.0,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: busy ? null : () => _onSmartPillTap(pill),
        child: Container(
          width: fullWidth ? double.infinity : null,
          constraints:
              fullWidth ? null : const BoxConstraints(maxWidth: 230),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: edge, width: (expiring || pill.isExact) ? 1.2 : 1),
          ),
          child: Row(
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Text(pill.glyph, style: const TextStyle(fontSize: 17)),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pill.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pill.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ZType.lbl(9.5,
                          color: expiring
                              ? (isDark ? AppColors.warning : AppColorsLight.warning)  // accent-allowlist: warning severity
                              : textMuted,
                          letterSpacing: 0.8),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                pill.isExact ? Icons.bolt_rounded : Icons.replay_rounded,
                size: 15,
                color: pill.isExact ? accent : textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
