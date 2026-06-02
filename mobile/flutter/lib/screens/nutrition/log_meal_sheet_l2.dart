part of 'log_meal_sheet.dart';

// ════════════════════════════════════════════════════════════════════
// Leapfrog L2 — "Near-zero friction" logging
//
// Three sub-features, all front-end only (no new backend endpoints —
// the data already exists in /nutrition/food-logs):
//
//   1. Voice-first log mode — a first-class hands-free dictation path
//      with a confirm-the-transcript step (C6: mis-transcription,
//      homophones — the user fixes the transcript before it analyses).
//   2. One-tap re-log — a "frequent meals" strip derived client-side
//      from recent food_logs; tapping pre-fills the analysis path so
//      the result sheet opens with the portion editable (C8 — never a
//      blind copy).
//   3. Meal-slot prediction — the slot is pre-selected from the user's
//      device-local time of day (C8 timezone), with a dismissible
//      "predicted" hint and a fully overridable selector.
// ════════════════════════════════════════════════════════════════════

/// A meal the user logs often, derived by grouping recent `food_log`
/// rows by a normalised signature (meal-type + the set of food names).
/// This is the unit behind the L2 one-tap re-log strip.
class _FrequentMeal {
  /// Human label for the chip — the log's `userQuery` if present,
  /// otherwise the joined food-item names.
  final String label;
  /// The meal type the user most often logs this under.
  final MealType mealType;
  /// How many times this signature appeared in the recent window.
  final int timesLogged;
  /// Representative calories (from the most recent matching log) — shown
  /// as a soft hint on the chip, NOT logged blindly (C8: re-log opens
  /// editable, the AI re-estimates the portion).
  final int calories;
  /// The text description routed into the analysis path on tap. Built
  /// from the food names so the AI re-estimates a fresh, editable
  /// portion rather than copying stale macros.
  final String analysisText;

  const _FrequentMeal({
    required this.label,
    required this.mealType,
    required this.timesLogged,
    required this.calories,
    required this.analysisText,
  });
}

/// L2 logic + UI for the log-meal sheet.
extension __LogMealSheetStateL2 on _LogMealSheetState {

  // ─── Frequent meals (one-tap re-log) ──────────────────────────

  /// Fetch a recent window of food logs and reduce them, client-side,
  /// into the user's most-logged meals. Mirrors the existing
  /// `getLoggedDateKeys` pattern (no dedicated backend endpoint — the
  /// food-logs endpoint already returns everything needed).
  ///
  /// C8 — a brand-new user with no logs resolves to an empty list and
  /// the strip renders a friendly empty state, never a spinner forever.
  Future<void> _loadFrequentMeals() async {
    if (_frequentMealsLoading) return;
    setState(() => _frequentMealsLoading = true);
    try {
      final repo = ref.read(nutritionRepositoryProvider);
      // ~3 weeks of history is enough to surface genuine repeats without
      // dragging in one-off meals. 200 rows comfortably covers a heavy
      // logger over that window in a single round trip.
      final logs = await repo.getFoodLogs(widget.userId, limit: 200);
      final frequent = _deriveFrequentMeals(logs);
      if (!mounted) return;
      setState(() {
        _frequentMeals = frequent;
        _frequentMealsLoading = false;
        _frequentMealsLoaded = true;
      });
      debugPrint('🍽️ [L2] Frequent meals loaded | count=${frequent.length}');
    } catch (e) {
      debugPrint('🍽️ [L2] Frequent meals load failed: $e');
      if (!mounted) return;
      // No mock/fallback data — on failure the strip simply shows the
      // empty state. We mark it loaded so the user isn't stuck on a
      // skeleton; a re-open re-attempts the fetch.
      setState(() {
        _frequentMeals = const [];
        _frequentMealsLoading = false;
        _frequentMealsLoaded = true;
      });
    }
  }

  /// Group [logs] by a normalised signature and rank by frequency.
  /// Returns at most 8 meals, each logged ≥2× (a single log isn't a
  /// "frequent" meal).
  List<_FrequentMeal> _deriveFrequentMeals(List<FoodLog> logs) {
    // signature → accumulator
    final groups = <String, _FreqAccumulator>{};
    for (final log in logs) {
      // Skip empty/garbage logs — no items and no query means nothing
      // to re-log.
      final names = log.foodItems
          .map((i) => i.name.trim())
          .where((n) => n.isNotEmpty)
          .toList();
      final query = (log.userQuery ?? '').trim();
      if (names.isEmpty && query.isEmpty) continue;

      // Signature = meal type + the sorted, lower-cased set of food
      // names (so "eggs, toast" and "toast, eggs" collapse together).
      // When there are no item names, fall back to the query text.
      final namesKey = names.isNotEmpty
          ? (names.map((n) => n.toLowerCase()).toList()..sort()).join('|')
          : query.toLowerCase();
      final signature = '${log.mealType}::$namesKey';

      final acc = groups.putIfAbsent(
        signature,
        () => _FreqAccumulator(firstSeen: log),
      );
      acc.count += 1;
      // Keep the most recent log as the representative (logs arrive
      // newest-first from the API, so the first seen is already newest).
    }

    final result = <_FrequentMeal>[];
    for (final acc in groups.values) {
      if (acc.count < 2) continue; // not yet "frequent"
      final rep = acc.firstSeen;
      final names = rep.foodItems
          .map((i) => i.name.trim())
          .where((n) => n.isNotEmpty)
          .toList();
      final query = (rep.userQuery ?? '').trim();

      // Label: prefer a concise food-name join; the query is often a
      // long sentence so it's the fallback.
      final label = names.isNotEmpty
          ? names.join(', ')
          : query;
      // Analysis text routed on tap — the food names give the AI a
      // clean re-estimate. Fall back to the original query otherwise.
      final analysisText = names.isNotEmpty ? names.join(', ') : query;

      result.add(_FrequentMeal(
        label: label,
        mealType: MealType.fromValue(rep.mealType),
        timesLogged: acc.count,
        calories: rep.totalCalories,
        analysisText: analysisText,
      ));
    }
    // Most-logged first; ties broken by calories desc for stable order.
    result.sort((a, b) {
      final byCount = b.timesLogged.compareTo(a.timesLogged);
      if (byCount != 0) return byCount;
      return b.calories.compareTo(a.calories);
    });
    return result.take(8).toList();
  }

  /// One-tap re-log. C8 — opens the result sheet with the portion
  /// EDITABLE (routes through the normal text-analysis path so the AI
  /// re-estimates) rather than blindly copying the old macros. The
  /// meal's typical slot is pre-selected but stays overridable.
  void _relogFrequentMeal(_FrequentMeal meal) {
    if (_isAnalyzing || _describeAnalyzing || _isLoading) return;
    setState(() {
      _selectedMealType = meal.mealType;
      _predictedMealSlot = null; // an explicit re-log clears the hint
      _aiMode = _AiLogMode.search;
      _descriptionController.text = meal.analysisText;
      _descriptionController.selection = TextSelection.collapsed(
        offset: meal.analysisText.length,
      );
      _inputType = 'copy';
      _sourceType = 'text';
    });
    ref.read(posthogServiceProvider).capture(
      eventName: 'food_frequent_meal_relog',
      properties: <String, Object>{
        'times_logged': meal.timesLogged,
        'meal_type': meal.mealType.name,
      },
    );
    // Route through the same analysis path as a typed description — the
    // result sheet is fully editable (portion, items, refine).
    _handleAnalyze();
  }

  /// The L2 "frequent meals" strip. Renders above the input body in the
  /// Voice / Search panels. Handles three states (C8):
  ///   • loading  → a lightweight skeleton row
  ///   • empty    → a friendly "log a few meals" message (new user)
  ///   • has data → a horizontally-scrolling row of one-tap chips
  Widget _buildFrequentMealsStrip(bool isDark) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accent = AccentColorScope.of(context).getColor(isDark);

    Widget header(String trailing) => Row(
          children: [
            Icon(Icons.replay_rounded, size: 15, color: accent),
            const SizedBox(width: 6),
            Text(
              AppLocalizations.of(context).logMealSheetFrequentMeals,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textPrimary),
            ),
            const Spacer(),
            if (trailing.isNotEmpty)
              Text(trailing,
                  style: TextStyle(fontSize: 11, color: textMuted)),
          ],
        );

    // Loading skeleton.
    if (_frequentMealsLoading && !_frequentMealsLoaded) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header(''),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (int i = 0; i < 3; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Container(
                        width: 120,
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white : Colors.black)
                              .withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Empty — brand-new user, or one who only logs one-offs. Hide the
    // whole section rather than showing an empty promise card; the Recent
    // list below already covers re-logging until frequent meals build up.
    if (_frequentMeals.isEmpty) {
      return const SizedBox.shrink();
    }

    // Populated — the one-tap chip row.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header('tap to re-log'),
          const SizedBox(height: 8),
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _frequentMeals.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) =>
                  _buildFrequentMealChip(isDark, _frequentMeals[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequentMealChip(bool isDark, _FrequentMeal meal) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final disabled = _isAnalyzing || _describeAnalyzing || _isLoading;

    return Opacity(
      opacity: disabled ? 0.5 : 1.0,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: disabled ? null : () => _relogFrequentMeal(meal),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 220),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: glassSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withValues(alpha: 0.30)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(meal.mealType.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: textPrimary),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      meal.calories > 0
                          ? '~${meal.calories} kcal · ${meal.timesLogged}×'
                          : 'logged ${meal.timesLogged}×',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10.5, color: textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.replay_rounded, size: 15, color: accent),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Meal-slot prediction hint ────────────────────────────────

  /// A dismissible "we picked Breakfast" hint shown when the slot came
  /// purely from the time-of-day prediction (C8). It also surfaces the
  /// user's typical foods for that slot as one-tap chips. The user can
  /// dismiss it; the meal-type pill in the header stays fully
  /// overridable regardless (C8 — wrong prediction → easy to override).
  Widget _buildMealSlotPredictionHint(bool isDark) {
    final predicted = _predictedMealSlot;
    if (predicted == null) return const SizedBox.shrink();
    // Only relevant while the prediction still matches the selection —
    // once the user overrides the slot, the hint is meaningless.
    if (predicted != _selectedMealType) return const SizedBox.shrink();

    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final typical = _typicalFoodsForSlot();
    final busy = _isAnalyzing || _describeAnalyzing || _isLoading;
    // The "Set to X for the time of day" message was removed per user request.
    // What's left is the useful "your usual <slot>" quick-relog strip — so hide
    // the whole hint when the user has no usual foods for this slot.
    if (typical.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: glassSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withValues(alpha: 0.20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              Text(
                'Your usual ${predicted.label.toLowerCase()}',
                style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: textMuted),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final meal in typical)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: busy ? null : () => _relogFrequentMeal(meal),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: accent.withValues(alpha: 0.30)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bolt_rounded, size: 12, color: accent),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                meal.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// The user's typical meals for the currently-selected slot — the
  /// most-logged meals the user eats at this meal type. Empty when the
  /// user has no history for the slot (C8 new user → nothing renders).
  List<_FrequentMeal> _typicalFoodsForSlot() {
    return _frequentMeals
        .where((m) => m.mealType == _selectedMealType)
        .take(4)
        .toList();
  }

  // ─── Voice-first log mode ─────────────────────────────────────

  /// Start hands-free dictation for Voice mode. Streams partial results
  /// into the editable [_voiceTranscriptController] so the user always
  /// sees what was heard before anything is logged (C6).
  Future<void> _startVoiceLog() async {
    if (_voiceCapturing) {
      await _stopVoiceLog();
      return;
    }
    // Lazy-init speech on first use (avoids a permission prompt on open).
    if (!_speechAvailable) {
      await _initSpeech();
    }
    if (!_speechAvailable) {
      // C6 — mic permission denied or speech unavailable. Graceful
      // fallback: flag it so the panel offers the typed path instead.
      if (mounted) setState(() => _voiceUnavailable = true);
      return;
    }
    setState(() {
      _voiceCapturing = true;
      _voiceUnavailable = false;
      _inputType = 'voice';
    });
    ref.read(posthogServiceProvider).capture(
      eventName: 'food_voice_log_started',
      properties: <String, Object>{},
    );
    try {
      await _speech.listen(
        onResult: (result) {
          if (!mounted) return;
          // Live partial + final transcript → the editable field.
          _voiceTranscriptController.text = result.recognizedWords;
          _voiceTranscriptController.selection = TextSelection.collapsed(
            offset: result.recognizedWords.length,
          );
          setState(() {});
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        localeId: 'en_US',
      );
    } catch (e) {
      debugPrint('🎤 [L2] Voice listen error: $e');
      if (mounted) {
        setState(() {
          _voiceCapturing = false;
          _voiceUnavailable = true;
        });
      }
    }
  }

  Future<void> _stopVoiceLog() async {
    try {
      await _speech.stop();
    } catch (_) {/* stop is best-effort */}
    if (mounted) setState(() => _voiceCapturing = false);
  }

  /// Confirm the (possibly user-corrected) transcript and route it
  /// through the normal text-analysis path. C6 — the user has already
  /// had the chance to fix homophones / mis-hearings in the field.
  Future<void> _confirmVoiceTranscript() async {
    final transcript = _voiceTranscriptController.text.trim();
    if (transcript.isEmpty) return;
    if (_voiceCapturing) await _stopVoiceLog();

    // C6 — "not a food log": a transcript with no letters (just noise
    // punctuation) or that's plainly not food shouldn't be analysed.
    // We do a light check; the analysis backend itself rejects clear
    // non-food, but this avoids a wasted round trip on empty noise.
    final hasWord = RegExp(r'[A-Za-z]{2,}').hasMatch(transcript);
    if (!hasWord) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).logMealSheetDidnTCatchAny),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    ref.read(posthogServiceProvider).capture(
      eventName: 'food_voice_log_confirmed',
      properties: <String, Object>{'transcript_length': transcript.length},
    );
    // Hand off to the shared analysis path — the result sheet is fully
    // editable, so an ambiguous "a bowl of cereal" (C6) lands as an
    // editable estimate the user can refine.
    setState(() {
      _descriptionController.text = transcript;
      _descriptionController.selection =
          TextSelection.collapsed(offset: transcript.length);
      _inputType = 'voice';
      _sourceType = 'text';
    });
    await _handleAnalyze();
  }

  /// Voice mode panel — a prominent mic affordance for hands-free
  /// logging while cooking/driving, plus the editable transcript
  /// confirm step and the frequent-meals strip for repeat meals.
  Widget _buildVoicePanel(bool isDark) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final coral = isDark ? AppColors.coral : AppColorsLight.coral;
    final hasTranscript = _voiceTranscriptController.text.trim().isNotEmpty;
    final busy = _isAnalyzing || _isLoading;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // L2 meal-slot prediction hint + frequent-meals strip.
          _buildMealSlotPredictionHint(isDark),
          _buildFrequentMealsStrip(isDark),
          const SizedBox(height: 4),

          // ── Big mic affordance ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: busy ? null : _startVoiceLog,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 26),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _voiceCapturing
                        ? [coral, coral.withValues(alpha: 0.78)]
                        : [accent, accent.withValues(alpha: 0.78)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (_voiceCapturing ? coral : accent)
                          .withValues(alpha: 0.32),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      _voiceCapturing
                          ? Icons.stop_circle_outlined
                          : Icons.mic_rounded,
                      size: 44,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _voiceCapturing ? AppLocalizations.of(context).logMealSheetListening : AppLocalizations.of(context).logMealSheetTapToSpeak,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _voiceCapturing
                          ? AppLocalizations.of(context).logMealSheetTapAgainWhenYou
                          : 'e.g. "log 3 eggs and oatmeal"',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Voice unavailable → graceful fallback (C6) ──────────
          if (_voiceUnavailable) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: coral.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: coral.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.mic_off_rounded, size: 16, color: coral),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context).logMealSheetMicrophoneUnavailable,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: textPrimary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context).logMealSheetEnableMicrophoneAccessIn,
                      style: TextStyle(
                          fontSize: 12, height: 1.35, color: textMuted),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () =>
                          setState(() => _aiMode = _AiLogMode.search),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.keyboard_alt_outlined,
                              size: 15, color: accent),
                          const SizedBox(width: 6),
                          Text(
                            AppLocalizations.of(context).logMealSheetTypeItInstead,
                            style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: accent),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // ── Editable transcript (confirm before analyse — C6) ───
          if (hasTranscript || _voiceCapturing) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.hearing_rounded, size: 14, color: textMuted),
                      const SizedBox(width: 6),
                      Text(
                        AppLocalizations.of(context).logMealSheetHeardEditIfNeeded,
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: glassSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.10)
                            : Colors.black.withValues(alpha: 0.07),
                      ),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: TextField(
                      controller: _voiceTranscriptController,
                      minLines: 2,
                      maxLines: 4,
                      enabled: !busy,
                      onChanged: (_) => setState(() {}),
                      textInputAction: TextInputAction.newline,
                      style: TextStyle(
                          color: textPrimary, fontSize: 15, height: 1.4),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        hintText: _voiceCapturing
                            ? AppLocalizations.of(context).logMealSheetListening
                            : 'Your words appear here — fix any mis-hearings.',
                        hintStyle: TextStyle(
                            color: textMuted.withValues(alpha: 0.7),
                            fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    // C6 — homophones note nudges the user to double-check.
                    'Tip: voice can mishear similar words ("ate"/"eight") — a quick glance saves a wrong log.',
                    style: TextStyle(
                        fontSize: 10.5,
                        height: 1.3,
                        fontStyle: FontStyle.italic,
                        color: textMuted.withValues(alpha: 0.85)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Re-record — clears and restarts capture.
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: busy
                            ? null
                            : () {
                                _voiceTranscriptController.clear();
                                _startVoiceLog();
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: glassSurface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: textMuted.withValues(alpha: 0.3)),
                          ),
                          child: Icon(Icons.refresh_rounded,
                              size: 18, color: textMuted),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: (!hasTranscript || busy)
                              ? null
                              : _confirmVoiceTranscript,
                          icon: busy
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                          Colors.white)))
                              : const Icon(Icons.check_rounded, size: 18),
                          label: Text(
                            busy ? AppLocalizations.of(context).logMealSheetAnalyzing : AppLocalizations.of(context).logMealSheetConfirmAnalyze,
                            style: const TextStyle(
                                fontSize: 14.5, fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                accent.withValues(alpha: 0.3),
                            disabledForegroundColor: Colors.white54,
                            padding:
                                const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              AppLocalizations.of(context).logMealSheetHandsFreeLoggingSpeak,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11, height: 1.4, color: textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mutable accumulator used while grouping logs into [_FrequentMeal]s.
class _FreqAccumulator {
  final FoodLog firstSeen;
  int count = 0;
  _FreqAccumulator({required this.firstSeen});
}
