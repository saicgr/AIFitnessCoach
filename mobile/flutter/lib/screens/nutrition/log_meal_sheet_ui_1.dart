part of 'log_meal_sheet.dart';

/// Date-key (yyyy-MM-dd) a log from this sheet should target. Null = today.
/// Splices + refreshes route to `dailyNutritionProvider(this key)`.
String _logSheetDateKey(DateTime? selectedDate) =>
    selectedDate != null ? nutritionKeyFor(selectedDate) : todayNutritionKey();

/// Methods extracted from _LogMealSheetState
extension __LogMealSheetStateExt1 on _LogMealSheetState {

  MealType _getDefaultMealType() {
    final hour = DateTime.now().hour;
    if (hour < 10) return MealType.breakfast;
    if (hour < 14) return MealType.lunch;
    if (hour < 17) return MealType.snack;
    return MealType.dinner;
  }

  /// Resolve a stored meal-type key string back to its enum value. Returns
  /// null when the key is missing OR no longer maps (silent migration —
  /// caller falls back to time-of-day default).
  MealType? _resolveMealTypeFromKey(String? key) {
    if (key == null || key.isEmpty) return null;
    for (final t in MealType.values) {
      if (t.name == key || t.value == key) return t;
    }
    return null;
  }


  // ─── Voice Input ──────────────────────────────────────────────

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onStatus: (status) {
          debugPrint('🎤 Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
        onError: (error) {
          debugPrint('🎤 Speech error: $error');
          if (mounted) setState(() => _isListening = false);
        },
      );
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('🎤 Speech init error: $e');
    }
  }


  Future<void> _toggleVoiceInput() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      // Lazy-initialize speech on first mic tap to avoid
      // triggering Bluetooth/nearby-devices permission on sheet open
      if (!_speechAvailable) {
        await _initSpeech();
      }
      if (!_speechAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).logMealSheetSpeechRecognitionNotAvailab)),
        );
        return;
      }
      setState(() {
        _isListening = true;
        // Voice input is still text-shaped downstream, but analytics should
        // distinguish dictation from typed text.
        _inputType = 'voice';
      });
      ref.read(posthogServiceProvider).capture(
        eventName: 'food_voice_input_used',
        properties: <String, Object>{},
      );
      await _speech.listen(
        onResult: (result) {
          if (mounted) {
            _descriptionController.text = result.recognizedWords;
            setState(() {});
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        localeId: 'en_US',
      );
    }
  }


  void _onFocusChange() {
    if (_textFieldFocusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }


  void _onDescriptionChanged() {
    final query = _descriptionController.text.trim();
    if (query != _searchQuery) {
      setState(() => _searchQuery = query);
      if (query.isNotEmpty) {
        // NL input is only triggered on explicit submit (search button / enter),
        // not on every keystroke — regular search continues as-is during typing.
        final service = ref.read(search.foodSearchServiceProvider);
        final cachedLogs = ref.read(dailyNutritionProvider(todayNutritionKey())).logs;
        service.search(query, widget.userId, cachedLogs: cachedLogs);
      }
    }
  }


  void _triggerImmediateSearch() {
    final query = _descriptionController.text.trim();
    if (query.length >= 3) {
      final service = ref.read(search.foodSearchServiceProvider);
      final cachedLogs = ref.read(dailyNutritionProvider(todayNutritionKey())).logs;
      service.searchImmediate(query, widget.userId, cachedLogs: cachedLogs);
    }
  }


  // ─── Analysis ─────────────────────────────────────────────────

  Future<void> _handleAnalyze() async {
    if (_descriptionController.text.trim().isEmpty) return;

    // Check guest limits for text describe
    final isGuest = ref.read(isGuestModeProvider);
    if (isGuest) {
      final canDescribe = await ref.read(guestUsageLimitsProvider.notifier).useTextDescribe();
      if (!canDescribe) {
        if (mounted) {
          Navigator.pop(context);
          GuestUpgradeSheet.show(context, feature: GuestFeatureLimit.textDescribe);
        }
        return;
      }
    }

    debugPrint('🍎 [LogMeal] Starting analysis with streaming...');
    setState(() {
      _isAnalyzing = true;
      _showLoadingIndicator = false;
      _error = null;
      _currentStep = 0;
      _progressMessage = AppLocalizations.of(context).logMealSheetStartingAnalysis;
      _progressDetail = null;
      _analysisElapsedMs = null;
      _previousResponse = null;
      _awaitingCoachTip = false;
    });
    // Only show loading indicator if analysis takes > 500ms (avoids flash for cache hits)
    _loadingDelayTimer?.cancel();
    _loadingDelayTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted && _isAnalyzing) {
        setState(() => _showLoadingIndicator = true);
      }
    });

    try {
      final repository = ref.read(nutritionRepositoryProvider);
      LogFoodResponse? response;

      await for (final progress in repository.analyzeFoodFromTextStreaming(
        userId: widget.userId,
        description: _descriptionController.text.trim(),
        mealType: _selectedMealType.value,
        moodBefore: _moodBefore?.value,
      )) {
        if (!mounted) return;

        if (progress.hasError) {
          _loadingDelayTimer?.cancel();
          setState(() {
            _isAnalyzing = false;
            _showLoadingIndicator = false;
            _error = progress.message;
          });
          return;
        }

        // Gap 1 — pure-water entry ("a glass of water"): the analyze stream
        // returns no food items but a hydration split. Log the water, confirm,
        // and close — never show an empty food confirm.
        if (progress.isHydrationOnly && progress.hydrationDetected != null) {
          _loadingDelayTimer?.cancel();
          await _logHydrationOnly(progress.hydrationDetected!);
          return;
        }

        if (progress.isCompleted && progress.foodLog != null) {
          // The `done` event renders the macro card immediately (~2-3s). A
          // late `coach_tips` event (progress.hasCoachTips) may follow a few
          // seconds later carrying a foodLog with the coach commentary merged
          // in. We do NOT break on `done` — keep listening so the tip swaps
          // in when it arrives. The shimmer placeholder shows meanwhile.
          final finalResponse = progress.foodLog!;
          // Stash any detected beverage so _handleLog can log it to hydration
          // alongside the food on confirm. A late coach_tips re-render carries
          // null here — keep the first non-null value.
          if (progress.hydrationDetected != null) {
            _pendingHydration = progress.hydrationDetected;
          }
          // Gap 7 — keep tracker inputs for the confirm → /log-direct write.
          if (progress.trackerMicros != null) {
            _pendingTrackerMicros = progress.trackerMicros;
          }
          response = finalResponse;
          final isTips = progress.hasCoachTips;
          setState(() {
            _analysisElapsedMs = progress.elapsedMs;
            _isAnalyzing = false;
            _showLoadingIndicator = false;
            _analyzedResponse = finalResponse;
            if (!isTips) {
              // Only reset edits on the first (done) render — a late tips
              // re-render must not wipe portion edits the user made.
              _originalFoodItems =
                  List<FoodItemRanking>.from(finalResponse.foodItems);
              _pendingItemEdits.clear();
              // The coach-tip card shows a shimmer until coach_tips lands.
              _awaitingCoachTip = (finalResponse.aiSuggestion == null ||
                      finalResponse.aiSuggestion!.trim().isEmpty) &&
                  (finalResponse.encouragements == null ||
                      !finalResponse.encouragements!
                          .any((e) => e.trim().isEmpty == false)) &&
                  (finalResponse.warnings == null ||
                      !finalResponse.warnings!
                          .any((w) => w.trim().isEmpty == false)) &&
                  (finalResponse.recommendedSwap == null ||
                      finalResponse.recommendedSwap!.trim().isEmpty);
            } else {
              _awaitingCoachTip = false;
            }
          });
          if (!isTips) {
            final description = _descriptionController.text.trim();
            ref.read(posthogServiceProvider).capture(
              eventName: 'food_text_analyzed',
              properties: <String, Object>{
                'description_length': description.length,
                'meal_type': _selectedMealType.name,
              },
            );
            // Show "Log This Meal" tooltip tour on first analysis
            _triggerLogMealTour();
          }
          _loadingDelayTimer?.cancel();
          if (isTips) break; // tips arrived — stream is done
          continue; // keep listening for the late coach_tips event
        }

        setState(() {
          _currentStep = progress.step;
          _totalSteps = progress.totalSteps;
          _progressMessage = progress.message;
          _progressDetail = progress.detail;
        });
      }

      debugPrint('🍎 [LogMeal] Streaming complete, response: $response');
      _loadingDelayTimer?.cancel();
      if (mounted && response != null) {
        // _analyzedResponse already set inside the loop on the `done` event.
        // If the stream ended before coach_tips arrived, clear the shimmer.
        if (_awaitingCoachTip) {
          setState(() => _awaitingCoachTip = false);
        }
      } else if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _showLoadingIndicator = false;
          _error = AppLocalizations.of(context).logMealSheetAnalysisFailed;
        });
      }
    } catch (e) {
      debugPrint('🍎 [LogMeal] Streaming error: $e');
      _loadingDelayTimer?.cancel();
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _showLoadingIndicator = false;
          _error = 'Error: $e';
        });
      }
    }
  }


  /// Gap 1 — parse {amount_ml, drink_type} into a logHydration call on the
  /// hydration provider (optimistic + offline-safe). Source = nutrition so the
  /// entry's badge reflects it came from the food logger.
  Future<bool> _logHydrationFromMap(Map<String, dynamic> hyd) async {
    final amountMl = (hyd['amount_ml'] as num?)?.toInt() ?? 0;
    if (amountMl <= 0) return false;
    final drinkType = (hyd['drink_type'] as String?) ?? 'water';
    try {
      return await ref.read(hydrationProvider.notifier).logHydration(
            userId: widget.userId,
            drinkType: drinkType,
            amountMl: amountMl,
            source: HydrationSource.nutrition,
          );
    } catch (e) {
      debugPrint('💧 [LogMeal] water-in-text log failed: $e');
      return false;
    }
  }

  /// Gap 1 — pure-water entry: log the water, toast it, and close the sheet.
  Future<void> _logHydrationOnly(Map<String, dynamic> hyd) async {
    final amountMl = (hyd['amount_ml'] as num?)?.toInt() ?? 0;
    await _logHydrationFromMap(hyd);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Logged ${amountMl}ml of water 💧'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pop();
  }

  void _handleBackToResults() {
    if (_previousResponse != null) {
      setState(() {
        _analyzedResponse = _previousResponse;
        _previousResponse = null;
      });
    }
  }


  void _handleFoodItemWeightChange(int index, FoodItemRanking updatedItem) {
    if (_analyzedResponse == null) return;

    final currentItems = List<FoodItemRanking>.from(_analyzedResponse!.foodItems);
    if (index < 0 || index >= currentItems.length) return;

    currentItems[index] = updatedItem;
    setState(() => _analyzedResponse = _rebuildResponseWithItems(currentItems));
  }

  /// L4 — "accuracy you can trust". User tapped the 1-tap "Looks right"
  /// confirm on a low-confidence item. Clears the low-confidence flag
  /// without changing any nutrition values (the user vouched for it as-is).
  void _confirmFoodItem(int index) {
    if (_analyzedResponse == null) return;
    final currentItems = List<FoodItemRanking>.from(_analyzedResponse!.foodItems);
    if (index < 0 || index >= currentItems.length) return;
    if (!currentItems[index].isLowConfidence) return;
    currentItems[index] = currentItems[index].confirmedByUser();
    setState(() => _analyzedResponse = _rebuildResponseWithItems(currentItems));
  }

  /// User tapped the inline kcal/macro pill on a food item and saved a new
  /// value. Commit the edit locally and diff against the AI's original
  /// analysis to produce audit rows flushed at save time.
  void _handleFoodItemFieldEdited(int index, String field, num newValue) {
    if (_analyzedResponse == null) return;

    final currentItems = List<FoodItemRanking>.from(_analyzedResponse!.foodItems);
    if (index < 0 || index >= currentItems.length) return;

    final item = currentItems[index];
    final previousValue = _readField(item, field);

    FoodItemRanking updated;
    switch (field) {
      case 'calories':
        updated = item.copyWithFields(calories: newValue.round());
        break;
      case 'protein_g':
        updated = item.copyWithFields(proteinG: newValue.toDouble());
        break;
      case 'carbs_g':
        updated = item.copyWithFields(carbsG: newValue.toDouble());
        break;
      case 'fat_g':
        updated = item.copyWithFields(fatG: newValue.toDouble());
        break;
      default:
        return;
    }
    currentItems[index] = updated;

    setState(() => _analyzedResponse = _rebuildResponseWithItems(currentItems));

    // Diff against AI's ORIGINAL values (not the last-edited value) so the
    // audit row represents the total correction the user made this session.
    _recomputePendingEditsForIndex(index, updated);

    // Analytics (see CLAUDE.md feedback — event-level edit tracking)
    final deltaPct = previousValue != 0
        ? ((newValue - previousValue) / previousValue * 100).toStringAsFixed(1)
        : 'inf';
    ref.read(posthogServiceProvider).capture(
      eventName: 'food_item_edited',
      properties: <String, Object>{
        'field': field,
        'previous': previousValue,
        'updated': newValue,
        'delta': newValue - previousValue,
        'delta_pct': deltaPct,
        'source': 'pre_save_log_meal',
        'food_item_name': item.name,
        'data_source': _sourceType,
        'meal_type': _selectedMealType.value,
      },
    );
  }

  /// Rebuild pending audit rows for the item at [index] by diffing every
  /// field against the ORIGINAL AI values. Replaces whatever was there —
  /// edit-back-to-original cleanly removes the audit row.
  void _recomputePendingEditsForIndex(int index, FoodItemRanking current) {
    final originals = _originalFoodItems;
    if (originals == null) return;
    if (index < 0 || index >= originals.length) return;

    final original = originals[index];
    final rows = <FoodItemEdit>[];

    void addIfChanged(String field, num prev, num next) {
      if (prev != next) {
        rows.add(FoodItemEdit(
          foodItemIndex: index,
          foodItemName: current.name,
          editedField: field,
          previousValue: prev,
          updatedValue: next,
        ));
      }
    }

    addIfChanged('calories', original.calories ?? 0, current.calories ?? 0);
    addIfChanged('protein_g', original.proteinG ?? 0, current.proteinG ?? 0);
    addIfChanged('carbs_g', original.carbsG ?? 0, current.carbsG ?? 0);
    addIfChanged('fat_g', original.fatG ?? 0, current.fatG ?? 0);

    if (rows.isEmpty) {
      _pendingItemEdits.remove(index);
    } else {
      _pendingItemEdits[index] = rows;
    }
  }

  num _readField(FoodItemRanking item, String field) {
    switch (field) {
      case 'calories':
        return item.calories ?? 0;
      case 'protein_g':
        return item.proteinG ?? 0;
      case 'carbs_g':
        return item.carbsG ?? 0;
      case 'fat_g':
        return item.fatG ?? 0;
    }
    return 0;
  }

  /// Rebuild the LogFoodResponse with new items + recomputed totals.
  /// Extracted so both weight-scaling and field-edit paths share the same
  /// totals-aggregation logic.
  LogFoodResponse _rebuildResponseWithItems(List<FoodItemRanking> items) {
    int totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    double totalFiber = 0;
    for (final item in items) {
      totalCalories += item.calories ?? 0;
      totalProtein += item.proteinG ?? 0;
      totalCarbs += item.carbsG ?? 0;
      totalFat += item.fatG ?? 0;
      totalFiber += item.fiberG ?? 0;
    }
    final base = _analyzedResponse!;
    return LogFoodResponse(
      success: base.success,
      foodLogId: base.foodLogId,
      foodItems: items,
      totalCalories: totalCalories,
      proteinG: totalProtein,
      carbsG: totalCarbs,
      fatG: totalFat,
      fiberG: totalFiber,
      overallMealScore: base.overallMealScore,
      healthScore: base.healthScore,
      // Preserve `health_score_reasons` across portion edits so the
      // ScoreExplainSheet keeps its chips when the user nudges a portion.
      healthScoreReasons: base.healthScoreReasons,
      goalAlignmentPercentage: base.goalAlignmentPercentage,
      aiSuggestion: base.aiSuggestion,
      encouragements: base.encouragements,
      warnings: base.warnings,
      recommendedSwap: base.recommendedSwap,
      confidenceScore: base.confidenceScore,
      confidenceLevel: base.confidenceLevel,
      sourceType: base.sourceType,
      correctedQuery: base.correctedQuery,
      sodiumMg: base.sodiumMg,
      sugarG: base.sugarG,
      saturatedFatG: base.saturatedFatG,
      cholesterolMg: base.cholesterolMg,
      potassiumMg: base.potassiumMg,
      vitaminAIu: base.vitaminAIu,
      vitaminCMg: base.vitaminCMg,
      vitaminDIu: base.vitaminDIu,
      calciumMg: base.calciumMg,
      ironMg: base.ironMg,
      personalHistoryNote: base.personalHistoryNote,
      sourceLabel: base.sourceLabel,
      imageUrl: base.imageUrl,
      imageStorageKey: base.imageStorageKey,
      plateDescription: base.plateDescription,
      // Preserve the meal-level inflammation summary across portion edits.
      // Without these the bottom inflammation bar disappears the moment the
      // user nudges any food's portion size.
      inflammationScore: base.inflammationScore,
      isUltraProcessed: base.isUltraProcessed,
      // Preserve the A3 "Applied:" note and the L1 coaching extras across
      // portion edits / item confirms — they describe the analysis, not the
      // portion, so a local edit must not wipe them.
      appliedInstructionNote: base.appliedInstructionNote,
      // L3 — preserve the "Zealova remembered…" affirmation across edits.
      rememberedMessage: base.rememberedMessage,
      nextMealSuggestion: base.nextMealSuggestion,
      overBudgetFork: base.overBudgetFork,
      // Preserve sauce/side suggestions across portion edits.
      suggestedAddons: base.suggestedAddons,
    );
  }

  /// Append a suggested sauce/side instantly from its carried macros — NO
  /// server round-trip (instant feel). The tapped suggestion is removed from
  /// the chip row so it isn't offered twice.
  void _addSuggestedAddon(SuggestedAddon addon) {
    if (_analyzedResponse == null) return;
    final base = _analyzedResponse!;
    final newItem = FoodItemRanking(
      name: addon.name,
      amount: addon.weightG != null ? '${addon.weightG!.round()}g' : '1 serving',
      calories: addon.calories,
      proteinG: addon.proteinG,
      carbsG: addon.carbsG,
      fatG: addon.fatG,
      fiberG: 0,
      weightG: addon.weightG,
      weightSource: 'estimated',
      unit: 'g',
      confidence: 'medium',
    );
    final updatedItems = List<FoodItemRanking>.from(base.foodItems)..add(newItem);
    _originalFoodItems ??= List<FoodItemRanking>.from(base.foodItems);
    _originalFoodItems!.add(newItem);
    final remaining = (base.suggestedAddons ?? const <SuggestedAddon>[])
        .where((a) => a.name != addon.name)
        .toList();
    setState(() {
      _analyzedResponse = _rebuildResponseWithItems(updatedItems)
          .copyWithCoachTips(suggestedAddons: remaining);
    });
    ref.read(posthogServiceProvider).capture(
      eventName: 'food_addon_added',
      properties: <String, Object>{
        'addon': addon.name,
        'calories': addon.calories,
      },
    );
  }


  void _handleFoodItemRemoved(int index) {
    if (_analyzedResponse == null) return;

    final currentItems = List<FoodItemRanking>.from(_analyzedResponse!.foodItems);
    if (index < 0 || index >= currentItems.length) return;
    currentItems.removeAt(index);
    // Keep the originals list aligned so diffs always line up 1:1.
    if (_originalFoodItems != null && index < _originalFoodItems!.length) {
      _originalFoodItems!.removeAt(index);
    }

    if (currentItems.isEmpty) {
      setState(() {
        _analyzedResponse = null;
        _pendingItemEdits.clear();
        _originalFoodItems = null;
      });
      return;
    }

    // Drop edits for the removed item AND re-key higher indices down by 1
    // (so audit payload indices match the post-removal food_items array).
    final rekeyed = <int, List<FoodItemEdit>>{};
    _pendingItemEdits.forEach((idx, edits) {
      if (idx < index) {
        rekeyed[idx] = edits;
      } else if (idx > index) {
        rekeyed[idx - 1] = edits
            .map((e) => FoodItemEdit(
                  foodItemIndex: idx - 1,
                  foodItemName: e.foodItemName,
                  foodItemId: e.foodItemId,
                  editedField: e.editedField,
                  previousValue: e.previousValue,
                  updatedValue: e.updatedValue,
                ))
            .toList();
      }
    });
    _pendingItemEdits
      ..clear()
      ..addAll(rekeyed);

    setState(() => _analyzedResponse = _rebuildResponseWithItems(currentItems));
  }


  /// Show a one-time tooltip on the "Log This Meal" button after first analysis
  void _triggerLogMealTour() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(appTourControllerProvider.notifier).checkAndShow(
        'nutrition_log_tour',
        [
          AppTourStep(
            id: 'log_meal_button',
            targetKey: AppTourKeys.logMealButtonKey,
            title: AppLocalizations.of(context).logMealSheetLogThisMeal,
            description: AppLocalizations.of(context).logMealSheetTapHereToSave,
            position: TooltipPosition.above,
          ),
        ],
      );
    });
  }


  /// ISO-8601 `logged_at` for this log. Null when the sheet is logging TODAY
  /// (the backend stamps server-now, preserving the exact time). When the user
  /// is viewing a PAST date in the Nutrition tab, returns that date stamped with
  /// the current wall-clock time so the meal lands on THAT day. The backend
  /// validates the window (today..−30 days); the carousel hides Log Meal beyond
  /// it, so anything reaching here is in range.
  String? _buildLoggedAtForSelectedDate() {
    final d = widget.selectedDate;
    if (d == null) return null;
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return null; // selected date IS today → server-now (keep exact time)
    }
    return DateTime(d.year, d.month, d.day, now.hour, now.minute, now.second)
        .toIso8601String();
  }

  Future<void> _handleLog() async {
    if (_analyzedResponse == null || _hasLoggedThisSession) return;

    setState(() => _hasLoggedThisSession = true);

    final response = _analyzedResponse!;
    final repository = ref.read(nutritionRepositoryProvider);
    final mealType = _selectedMealType.value;
    final sourceType = _sourceType;
    final userId = widget.userId;

    // Optimistic: mark XP and close sheet immediately
    ref.read(xpProvider.notifier).markMealLogged();

    // Flatten pending pre-save edits into a single list — backend writes them
    // to food_log_edits table with the new food_log_id as part of the same
    // request. Any item edits for already-removed items have already been
    // pruned by _handleFoodItemRemoved.
    final pendingEdits = _pendingItemEdits.values.expand((e) => e).toList();

    // Logs always stamp at the current moment via backend default. The
    // Nutrition tab auto-snaps to today after a successful log so the user
    // sees the meal where it actually lives.
    final loggedAtIso = _buildLoggedAtForSelectedDate();

    // (WR9) Stable client-generated idempotency key — rides on the
    // `/nutrition/log-direct` body so a rapid double-tap of "Log This Meal"
    // (or an offline-queued write replayed on reconnect) can never create two
    // food_log rows. The same key is reused for the lifetime of this save.
    final idempotencyKey = NutritionRepository.newMealIdempotencyKey();

    // (WR1) Splice the meal into nutritionProvider state IMMEDIATELY — before
    // the network POST — so it appears in the Nutrition Daily meal list and
    // the rings/pinned nutrients update within one frame. `spliceLog` returns
    // the optimistic FoodLog so we can roll it back by id on failure (WR4).
    final nutritionNotifier = ref
        .read(dailyNutritionProvider(_logSheetDateKey(widget.selectedDate)).notifier);
    final optimisticLog = nutritionNotifier.spliceLog(response, mealType, userId,
        idempotencyKey: idempotencyKey);
    final optimisticLogId = optimisticLog.id;

    // (WR5) If the analyzed response carries no remote photo URL yet (the S3
    // upload hasn't returned) but we captured a local photo, show the LOCAL
    // image on the meal-list row immediately. The background save's success
    // branch swaps it to the remote URL via `updateLogImageUrl`.
    if ((response.imageUrl == null || response.imageUrl!.isEmpty) &&
        _capturedImagePath != null &&
        _capturedImagePath!.isNotEmpty) {
      nutritionNotifier.updateLogImageUrl(optimisticLogId, _capturedImagePath);
    }

    // (WR6) Refresh Home's timeline so the new meal shows on Home without a
    // manual pull-to-refresh — mirrors the hydration log path.
    nutritionNotifier.refreshTimeline();

    // Start the save — capture the food_log_id for post-meal review.
    // Wrapped in an unawaited async IIFE (instead of `.then().catchError(...)`)
    // because catchError that returns void breaks the chained Future's type
    // contract — Dart 3 surfaces this as `'Null' is not a subtype of
    // 'LogFoodResponse'` when the chain rethrows. The IIFE pattern makes the
    // result type unambiguous (`Future<void>`) and keeps the same fire-and-
    // forget behaviour: errors are debugPrinted and surfaced via a calm
    // retry snackbar (WR4) — never a silent failure.
    String? savedLogId;
    final Future<void> saveFuture = () async {
      try {
        final savedResponse = await repository.logFoodDirect(
          userId: userId,
          mealType: mealType,
          analyzedFood: response,
          sourceType: sourceType,
          inputType: _inputType,
          loggedAt: loggedAtIso,
          itemEdits: pendingEdits,
          idempotencyKey: idempotencyKey, // (WR9) double-tap / replay guard
          trackerMicros: _pendingTrackerMicros, // Gap 7 sugar/caffeine/alcohol
        );
        savedLogId = savedResponse.foodLogId;
        // (WR9b) Reconcile the optimistic row to the authoritative server row:
        // swap its synthetic `optimistic_<ts>` id for the real food_log_id so a
        // later summary refresh dedupes by id (not just idempotency_key) and any
        // delete/edit targets the PERSISTED row, never the phantom. Without this
        // the merge re-adds the optimistic row next to the server row → the
        // duplicate the user sees, then deleting one orphans the survivor.
        if (savedLogId != null && savedLogId!.isNotEmpty) {
          nutritionNotifier.reconcileLoggedMeal(optimisticLogId, savedLogId!,
              idempotencyKey: idempotencyKey);
        }
        // (WR5) The photo's S3 upload finished as part of the POST — swap the
        // optimistic row's (possibly local file://) image for the remote URL.
        if (savedResponse.imageUrl != null &&
            savedResponse.imageUrl!.isNotEmpty) {
          nutritionNotifier.updateLogImageUrl(
              savedLogId ?? optimisticLogId, savedResponse.imageUrl);
        }
      } catch (e) {
        debugPrint('❌ [LogMeal] Background save failed: $e');
        // (WR4) The write may have been offline-queued by logAdjustedFood
        // (the _MealWriteQueue keeps the optimistic row + flushes on
        // reconnect). Only a genuine ONLINE failure should roll back. Probe
        // connectivity: offline → keep the optimistic row; online → roll back.
        //
        // EXCEPTION: a MealLogPersistException means the offline queue write
        // itself failed, so the meal is NOT saved anywhere — roll back and
        // surface a retry even though we're offline, or it vanishes silently.
        final couldNotPersistOffline = e is MealLogPersistException;
        final stillOnline =
            couldNotPersistOffline || await NutritionRepository.isOnline();
        if (stillOnline) {
          // Genuine failure — remove the optimistic row so the UI doesn't
          // show a meal the server never stored, and surface a calm retry.
          nutritionNotifier.optimisticRemoveLog(optimisticLogId);
          _showLogFailedRetry(response);
        }
        // Offline branch: optimistic row stays; _MealWriteQueue replays it.
        // Rethrow so `_logAnalyzedFood`'s reconcile-on-success path is skipped.
        rethrow;
      }
    }();
    // Swallow the rethrow at the top level — already handled above.
    unawaited(saveFuture.catchError((_) {}));

    // Gap 1 — water-in-text. If the entry also mentioned a beverage, log it to
    // hydration alongside the food (fire-and-forget; optimistic + offline-safe).
    // Consume once so a retry of the same response doesn't double-log water.
    final pendingHydration = _pendingHydration;
    if (pendingHydration != null) {
      _pendingHydration = null;
      unawaited(_logHydrationFromMap(pendingHydration));
    }

    _logAnalyzedFood(response, saveFuture, () => savedLogId, optimisticLogId);
  }

  /// (WR4) Surface a calm, non-blocking retry affordance when a food-log
  /// network write genuinely fails while online. The optimistic row has
  /// already been rolled back by the caller — tapping Retry re-runs the log.
  void _showLogFailedRetry(LogFoodResponse response) {
    final messenger = ScaffoldMessenger.maybeOf(
      Navigator.of(context, rootNavigator: true).overlay?.context ?? context,
    );
    if (messenger == null) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).logMealSheetCouldnTSaveYour),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: AppLocalizations.of(context).buttonRetry,
          onPressed: () {
            // Re-arm and re-run the log with the same analyzed response.
            _hasLoggedThisSession = false;
            _analyzedResponse = response;
            _handleLog();
          },
        ),
      ),
    );
  }


  Future<void> _handleSaveAsFavorite() async {
    if (_isSaving || _analyzedResponse == null) return;

    // Star fills instantly; persistence runs in background.
    setState(() {
      _isSaving = true;
      _isSaved = true;
    });

    final repository = ref.read(nutritionRepositoryProvider);
    final description = _descriptionController.text.trim();
    final request = SaveFoodRequest.fromLogResponse(
      _analyzedResponse!,
      description.length > 50
          ? '${description.substring(0, 50)}...'
          : description,
      description: description,
      sourceType: _sourceType,
    );

    final bottomPadding = MediaQuery.of(context).padding.bottom;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.star, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(AppLocalizations.of(context).logMealSheetSavedToFavorites)
        ]),
        backgroundColor: AppColors.textMuted,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: EdgeInsets.only(left: 16, right: 16, bottom: bottomPadding + 100),
      ),
    );
    if (mounted) setState(() => _isSaving = false);

    unawaited(() async {
      try {
        await repository.saveFood(userId: widget.userId, request: request);
      } catch (e) {
        debugPrint('❌ [SaveFood] Error: $e');
        if (mounted) {
          // Roll back the star so the user sees it didn't persist.
          setState(() => _isSaved = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)
                  .logMealSheetFailedToSaveError(e.toString())),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }());
  }


  bool _hasMicronutrients(LogFoodResponse response) {
    return response.sodiumMg != null ||
        response.sugarG != null ||
        response.saturatedFatG != null ||
        response.cholesterolMg != null ||
        response.potassiumMg != null ||
        response.vitaminAIu != null ||
        response.vitaminCMg != null ||
        response.vitaminDIu != null ||
        response.calciumMg != null ||
        response.ironMg != null;
  }


  /// Check if the user specified explicit quantities that the AI significantly changed.
  /// Returns true if any user-specified quantity differs from AI result by >30%.
  bool _hasQuantityMismatch(String description, List<FoodItemRanking> items) {
    // Parse explicit quantities from user input: "500g rice", "300ml milk", "2kg chicken"
    final quantityPattern = RegExp(r'(\d+(?:\.\d+)?)\s*(g|kg|ml|oz|lb)\b', caseSensitive: false);
    final matches = quantityPattern.allMatches(description.toLowerCase());
    if (matches.isEmpty) return false;

    for (final match in matches) {
      final userAmount = double.tryParse(match.group(1)!) ?? 0;
      final unit = match.group(2)!.toLowerCase();
      // Convert to grams for comparison
      double userGrams;
      switch (unit) {
        case 'kg': userGrams = userAmount * 1000; break;
        case 'lb': userGrams = userAmount * 453.6; break;
        case 'oz': userGrams = userAmount * 28.35; break;
        default: userGrams = userAmount; // g and ml
      }
      if (userGrams <= 0) continue;

      // Find the closest matching food item by checking if any word after the number
      // appears in the item name
      final afterQuantity = description.substring(match.end).trim().toLowerCase();
      final firstWord = afterQuantity.split(RegExp(r'\s+')).firstOrNull ?? '';
      if (firstWord.isEmpty) continue;

      for (final item in items) {
        final itemName = item.name.toLowerCase();
        if (itemName.contains(firstWord)) {
          final aiWeight = item.weightG ?? 0;
          if (aiWeight <= 0) continue;
          final ratio = (aiWeight - userGrams).abs() / userGrams;
          if (ratio > 0.3) return true;
          break;
        }
      }
    }
    return false;
  }


  // ─── Time Picker ──────────────────────────────────────────────

  Future<void> _showTimePicker() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && mounted) {
      setState(() => _selectedTime = picked);
    }
  }


  // ─── Meal Type Picker ─────────────────────────────────────────

  void _showMealTypePicker() {
    final isDark = widget.isDark;
    final lastUsed = ref.read(lastUsedServiceProvider);
    final lastUsedKey = lastUsed.get(_kMealTypeLastUsedKey);
    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        maxHeightFraction: 0.35,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: MealType.values.map((type) {
              final isSelected = _selectedMealType == type;
              // Badge a row when it matches last-used AND is not the currently
              // selected row (the check icon already marks the current pick).
              final showLastUsedBadge = !isSelected &&
                  (type.name == lastUsedKey || type.value == lastUsedKey);
              return ListTile(
                leading: Text(type.emoji, style: const TextStyle(fontSize: 24)),
                title: Text(
                  type.label,
                  style: TextStyle(
                    color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check, color: isDark ? AppColors.teal : AppColorsLight.teal)
                    : (showLastUsedBadge ? const LastUsedBadge.static() : null),
                onTap: () {
                  setState(() => _selectedMealType = type);
                  // Fire-and-forget — don't block UI on prefs flush.
                  // ignore: unawaited_futures
                  lastUsed.set(_kMealTypeLastUsedKey, type.name);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }


  // ─── AI Coach popup ───────────────────────────────────────────

  void _openAiCoachSheet() {
    // Resolve context needed for the coach. Graceful fallbacks so the
    // popup always opens even if a provider isn't ready.
    String tz;
    try {
      tz = DateTime.now().timeZoneName; // e.g. "CDT"
      // Prefer IANA if available from the app's locale/tz helpers.
      final offsetMinutes = DateTime.now().timeZoneOffset.inMinutes;
      // Keep it simple — backend accepts IANA names and falls back to UTC.
      if (tz.length > 6 || RegExp(r'^[A-Z]+$').hasMatch(tz)) {
        // Common cases ("CDT", "PST") aren't IANA — let backend resolve via
        // user_profile.timezone instead; pass UTC here to avoid confusion.
        tz = 'UTC';
      }
      debugPrint('[AiCoach] tz=$tz offsetMin=$offsetMinutes');
    } catch (_) {
      tz = 'UTC';
    }

    showGlassSheet(
      context: context,
      builder: (_) => AiCoachMealSuggestionSheet(
        userId: widget.userId,
        mealType: _selectedMealType.value,
        timezone: tz,
        // Pass nothing for current_workout / workout_schedule — backend
        // pre-fetches today's workout directly (more accurate anyway).
        onLogSuggestedFood: (food) {
          // Pre-fill the description box with the suggested food name so the
          // user can tap Analyze. Future: open a nested LogMealSheet pre-filled.
          final name = (food['name'] ?? food['food_name'] ?? '').toString();
          if (name.isNotEmpty) {
            _descriptionController.text = name;
            setState(() {});
          }
        },
        onOpenFullChat: ({seededExchange}) {
          // Close the meal-log sheet (optional — keeps the sheet open if the
          // user wants to come back) then open the global chat bottom sheet.
          // Full-chat continuity is Phase-2 (seededExchange is captured by
          // the caller; wiring it into the chat notifier's cache is a
          // follow-up since it requires the notifier's internal _saveToCache).
          Navigator.of(context).pop();
          // Defer to let the current modal finish dismissing.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showChatBottomSheet(context, ref);
          });
        },
      ),
    );
  }


  // ─── Barcode Scanner ──────────────────────────────────────────

  void _openBarcodeScanner() {
    showGlassSheet(
      context: context,
      builder: (context) => BarcodeScannerOverlay(
        onBarcodeDetected: (barcode) {
          Navigator.pop(context); // close scanner
          _handleBarcodeScan(barcode);
        },
        isDark: widget.isDark,
      ),
    );
  }


  /// Multi-image entry point for the food-log bottom bar's Camera / Gallery
  /// buttons. Camera now supports multi-shot via [_captureMultipleFromCamera]
  /// (take a photo → "Add another?" prompt → repeat). Gallery invokes
  /// pickMultiImage. Both route through /log-multi-image-stream with
  /// analysis_mode="auto" so the backend classifier decides plate vs menu vs buffet.
  Future<void> _pickImages(ImageSource source) async {
    List<XFile> files = [];
    List<Uint8List>? thumbBytesList;

    String snapPrompt = '';
    if (source == ImageSource.camera) {
      // Camera path retains its custom multi-shot flow (capture loop +
      // "Add another?" prompt). Thumb compression happens inline below
      // so we still get the Phase-2 paired-multipart benefit.
      final result = await _captureMultipleFromCamera(maxCount: 5, noun: 'photo');
      files = result.files;
      snapPrompt = result.prompt;
    } else {
      // Gallery path: use Phase-2 paired pick (returns originals + 768px thumbs)
      final artifacts = await pickFoodScanArtifactsBatch();
      if (artifacts.isEmpty) return;
      files = artifacts.map((a) => XFile(a.original.path)).toList();
      thumbBytesList = artifacts.map((a) => a.thumbBytes).toList();
    }
    if (files.isEmpty) return;

    // Camera path didn't produce thumbs above — compress in-memory now so
    // all paths benefit from the cheap Vision tile.
    if (thumbBytesList == null && files.isNotEmpty) {
      try {
        final List<Uint8List> thumbs = [];
        for (final xf in files) {
          final compressed = await FlutterImageCompress.compressWithFile(
            xf.path,
            minWidth: 768, minHeight: 768,
            quality: 85, format: CompressFormat.jpeg,
            autoCorrectionAngle: true,
          );
          if (compressed != null) thumbs.add(compressed);
        }
        if (thumbs.length == files.length) thumbBytesList = thumbs;
      } catch (e) {
        debugPrint('[food-scan] camera-path thumb compression failed: $e');
      }
    }

    final description = _descriptionController.text.trim();
    final merged = <String>[
      if (description.isNotEmpty) description,
      if (snapPrompt.isNotEmpty) snapPrompt,
    ].join(' — ');
    final userMessage = merged.isEmpty ? null : merged;

    await _analyzeMultiImages(
      files: files,
      thumbBytesList: thumbBytesList,
      analysisMode: 'auto',
      inputType: source == ImageSource.camera ? 'camera' : 'gallery',
      userMessage: userMessage,
    );
  }

  /// Take multiple photos in sequence from the camera. After each shot, prompts
  /// the user to add another or finish. Cancelling the camera mid-loop (system
  /// back / cancel button) exits the loop gracefully, preserving already-taken
  /// photos.
  Future<({List<XFile> files, String prompt})> _captureMultipleFromCamera({
    required int maxCount,
    required String noun,
  }) async {
    final picker = ImagePicker();
    final files = <XFile>[];
    String finalPrompt = '';
    while (files.length < maxCount) {
      final shot = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 90,
      );
      if (shot == null) break;
      files.add(shot);
      if (files.length >= maxCount) break;
      if (!mounted) break;
      final result = await _showAddAnotherPrompt(noun: noun, count: files.length);
      if (result == null) {
        // Sheet dismissed via swipe — treat as Done with no prompt change.
        break;
      }
      // Always remember the latest prompt the user typed; the FINAL sheet's
      // prompt is what gets sent. (Earlier prompts are overwritten by design.)
      finalPrompt = result.prompt;
      if (!result.addAnother) break;
    }
    return (files: files, prompt: finalPrompt);
  }

  /// Glass bottom sheet offering "Add another {noun}" or "Done — Analyze N".
  /// Also exposes a multiline TextField so the user can describe what's in
  /// the photos (e.g. "this also has flax seeds + whey protein"); the typed
  /// text is forwarded to Gemini alongside the image bytes.
  ///
  /// Returns null if the sheet is dismissed via swipe; otherwise returns
  /// `_AddAnotherResult(addAnother, prompt)`.
  Future<_AddAnotherResult?> _showAddAnotherPrompt({
    required String noun,
    required int count,
  }) async {
    final amber = const Color(0xFFF59E0B);
    final promptCtrl = TextEditingController();
    try {
      return await showGlassSheet<_AddAnotherResult>(
        context: context,
        builder: (ctx) {
          final colors = ThemeColors.of(ctx);
          final isDark = colors.isDark;
          return GlassSheet(
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  16 + MediaQuery.of(ctx).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
                      child: Text(
                        '$count $noun${count == 1 ? '' : 's'} captured', // TODO(i18n): noun is a runtime-injected English word; migrate at call-site with ICU plural
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    // Optional free-text describing what else is in the photos
                    // (ingredients hidden behind a sauce, brand of protein, etc).
                    // Forwarded as `user_message` to the analyze endpoint.
                    TextField(
                      controller: promptCtrl,
                      minLines: 2,
                      maxLines: 4,
                      textInputAction: TextInputAction.newline,
                      style: TextStyle(color: colors.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText:
                            AppLocalizations.of(ctx).logMealSheetAnythingElseInThe,
                        hintStyle:
                            TextStyle(color: colors.textSecondary, fontSize: 13),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _GlassMenuOption(
                      icon: Icons.add_a_photo_outlined,
                      label: 'Add another $noun', // TODO(i18n): noun is a runtime-injected English word; migrate at call-site
                      color: amber,
                      isDark: isDark,
                      onTap: () => Navigator.pop(
                        ctx,
                        _AddAnotherResult(
                          addAnother: true,
                          prompt: promptCtrl.text.trim(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _GlassMenuOption(
                      icon: Icons.check_circle_outline,
                      label: 'Done — Analyze $count $noun${count == 1 ? '' : 's'}', // TODO(i18n): noun is a runtime-injected English word; migrate at call-site with ICU plural
                      color: const Color(0xFF16A34A),
                      isDark: isDark,
                      onTap: () => Navigator.pop(
                        ctx,
                        _AddAnotherResult(
                          addAnother: false,
                          prompt: promptCtrl.text.trim(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } finally {
      promptCtrl.dispose();
    }
  }

  /// Scan Food entry — presents Camera vs Gallery picker (matching the
  /// `_scanMenu` pattern), then delegates to `_pickImages(source)` which
  /// supports multi-image on both sources (camera capture loop + gallery
  /// multi-pick). Wired from the home-grid "Scan Food" quick-action.
  Future<void> _pickFoodImagesWithSourceChoice() async {
    final green = const Color(0xFF16A34A);
    final source = await showGlassSheet<ImageSource>(
      context: context,
      builder: (ctx) {
        final colors = ThemeColors.of(ctx);
        final isDark = colors.isDark;
        return GlassSheet(
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 16),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.document_scanner_outlined,
                              size: 20, color: green),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(ctx).logMealSheetScanFood,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _GlassMenuOption(
                    icon: Icons.camera_alt_outlined,
                    label: AppLocalizations.of(ctx).logMealSheetTakeFoodPhoto,
                    subtitle: AppLocalizations.of(ctx).logMealSheetUpTo5Shots,
                    color: green,
                    isDark: isDark,
                    onTap: () => Navigator.pop(ctx, ImageSource.camera),
                  ),
                  const SizedBox(height: 10),
                  _GlassMenuOption(
                    icon: Icons.collections_outlined,
                    label: AppLocalizations.of(ctx).logMealSheetChooseFoodPhotos,
                    subtitle: AppLocalizations.of(ctx).logMealSheetPickUpTo5,
                    color: green,
                    isDark: isDark,
                    onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (source == null || !mounted) return;
    await _pickImages(source);
  }

  /// Menu scan — take or pick 1..N photos of a restaurant menu, send through
  /// /log-multi-image-stream with analysis_mode="menu". On response, open
  /// MenuAnalysisSheet for the user to tick items and log them.
  ///
  /// #15 re-scan-in-place: when [updateSavedMenuId] is non-null, this is a
  /// re-scan of an ALREADY-saved menu. Instead of opening the normal
  /// MenuAnalysisSheet save flow, the fresh scan results are PATCHed onto that
  /// saved `menu_analyses` row (no duplicate) and a refreshed saved-menu sheet
  /// is opened. See [_analyzeMultiImages] for where the branch lands.
  Future<void> _scanMenu({String? updateSavedMenuId}) async {
    // #15 — when the sheet was opened via `showMenuRescanSheet(...)` (the
    // one-tap re-scan entry from the Saved Menu sheet), the saved-menu id is
    // stashed in a library-level var because `autoOpenMenuScan` calls
    // `_scanMenu()` with no args from initState. Consume it exactly once so a
    // later normal menu scan in the same sheet doesn't accidentally re-scan.
    if (updateSavedMenuId == null && _pendingMenuRescanId != null) {
      updateSavedMenuId = _pendingMenuRescanId;
      _pendingMenuRescanId = null;
    }
    final picker = ImagePicker();
    final amber = const Color(0xFFF59E0B);
    final source = await showGlassSheet<ImageSource>(
      context: context,
      builder: (ctx) {
        final colors = ThemeColors.of(ctx);
        final isDark = colors.isDark;
        return GlassSheet(
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 16),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.menu_book_outlined, size: 20, color: amber),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(ctx).logMealSheetScanMenu,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _GlassMenuOption(
                    icon: Icons.camera_alt_outlined,
                    label: AppLocalizations.of(ctx).logMealSheetTakeMenuPhoto,
                    color: amber,
                    isDark: isDark,
                    onTap: () => Navigator.pop(ctx, ImageSource.camera),
                  ),
                  const SizedBox(height: 10),
                  _GlassMenuOption(
                    icon: Icons.collections_outlined,
                    label: AppLocalizations.of(ctx).logMealSheetChooseMenuPhotos,
                    subtitle: AppLocalizations.of(ctx).logMealSheetUpTo5Pages,
                    color: amber,
                    isDark: isDark,
                    onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (source == null) return;

    List<XFile> files = [];
    String snapPrompt = '';
    if (source == ImageSource.camera) {
      final result = await _captureMultipleFromCamera(maxCount: 5, noun: 'page');
      files = result.files;
      snapPrompt = result.prompt;
    } else {
      files = await picker.pickMultiImage(imageQuality: 90);
      if (files.length > 5) files = files.take(5).toList();
    }
    if (files.isEmpty) return;

    final description = _descriptionController.text.trim();
    final merged = <String>[
      if (description.isNotEmpty) description,
      if (snapPrompt.isNotEmpty) snapPrompt,
    ].join(' — ');
    final userMessage = merged.isEmpty ? null : merged;

    await _analyzeMultiImages(
      files: files,
      analysisMode: 'menu',
      inputType: 'menu_scan',
      userMessage: userMessage,
      updateSavedMenuId: updateSavedMenuId,
    );
  }

  // ─── Import Scan — Nutrition Label / App Screenshot (Parity A2) ──────

  /// Opens the chooser sheet that surfaces the two OCR-import flows that
  /// previously lived only inside the AI-Coach chat: scanning a physical
  /// nutrition-facts label and importing a screenshot from another tracking
  /// app (MyFitnessPal / Cronometer / etc.). Each option picks an image and
  /// routes through the direct `/nutrition/scan-*` endpoint into THIS sheet's
  /// standard result card for review/edit before logging.
  Future<void> _openImportScanSheet() async {
    final cyan = const Color(0xFF06B6D4);
    final choice = await showGlassSheet<String>(
      context: context,
      builder: (ctx) {
        final colors = ThemeColors.of(ctx);
        final isDark = colors.isDark;
        return GlassSheet(
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 16),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: cyan.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.document_scanner_outlined,
                              size: 20, color: cyan),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(ctx).logMealSheetScanImport,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _GlassMenuOption(
                    icon: Icons.qr_code_2_outlined,
                    label: AppLocalizations.of(ctx).logMealSheetScanNutritionLabel,
                    subtitle: AppLocalizations.of(ctx).logMealSheetReadMacrosOffA,
                    color: cyan,
                    isDark: isDark,
                    onTap: () => Navigator.pop(ctx, 'label'),
                  ),
                  const SizedBox(height: 10),
                  _GlassMenuOption(
                    icon: Icons.screenshot_outlined,
                    label: AppLocalizations.of(ctx).logMealSheetScanAppScreenshot,
                    subtitle: AppLocalizations.of(ctx).logMealSheetImportALogFrom,
                    color: cyan,
                    isDark: isDark,
                    onTap: () => Navigator.pop(ctx, 'screenshot'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (choice == null || !mounted) return;
    if (choice == 'label') {
      await _scanNutritionLabel();
    } else {
      await _scanAppScreenshot();
    }
  }

  /// Lets the user pick Camera vs Gallery for a scan flow. Returns null if
  /// dismissed. Mirrors the `_scanMenu` / `_pickFoodImagesWithSourceChoice`
  /// chooser so the scan flows feel native to this sheet.
  Future<ImageSource?> _pickScanImageSource(String title, Color color) {
    return showGlassSheet<ImageSource>(
      context: context,
      builder: (ctx) {
        final colors = ThemeColors.of(ctx);
        final isDark = colors.isDark;
        return GlassSheet(
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 16),
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  _GlassMenuOption(
                    icon: Icons.camera_alt_outlined,
                    label: AppLocalizations.of(ctx).logMealSheetTakeAPhoto,
                    color: color,
                    isDark: isDark,
                    onTap: () => Navigator.pop(ctx, ImageSource.camera),
                  ),
                  const SizedBox(height: 10),
                  _GlassMenuOption(
                    icon: Icons.collections_outlined,
                    label: AppLocalizations.of(ctx).logMealSheetChooseFromLibrary,
                    color: color,
                    isDark: isDark,
                    onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// C4 — nutrition-label scan. After picking the label photo we ask "how
  /// many servings did you eat?" (label serving size ≠ amount eaten), then
  /// call the direct endpoint. The result lands in the standard result card
  /// where the user can still edit any macro before logging.
  Future<void> _scanNutritionLabel() async {
    // Guest gate — a label scan is an AI photo analysis.
    final isGuest = ref.read(isGuestModeProvider);
    if (isGuest) {
      final canScan =
          await ref.read(guestUsageLimitsProvider.notifier).usePhotoScan();
      if (!canScan) {
        if (mounted) {
          Navigator.pop(context);
          GuestUpgradeSheet.show(context, feature: GuestFeatureLimit.photoScan);
        }
        return;
      }
    }

    final source =
        await _pickScanImageSource('Scan Nutrition Label', const Color(0xFF06B6D4));
    if (source == null || !mounted) return;

    final picker = ImagePicker();
    final shot = await picker.pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 90,
    );
    if (shot == null || !mounted) return;

    // C4: ask how many servings BEFORE the scan so Gemini multiplies macros
    // by the real amount eaten (default 1.0 — most foods are single-serving).
    final servings = await _askServingsConsumed();
    if (servings == null || !mounted) return; // user cancelled

    await _runScanImport(
      kind: 'label',
      imageFile: File(shot.path),
      servingsConsumed: servings,
      inputType: 'label_scan',
    );
  }

  /// Gap 4 — the nutrition label is still cut off after [photosSoFar] photo(s)
  /// (a common case when the panel wraps around a bottle). Offer to capture
  /// another piece; returns the new photo File, or null if the user declines.
  Future<File?> _promptAddAnotherLabelPhoto(int photosSoFar) async {
    if (!mounted) return null;
    final add = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final colors = ThemeColors.of(ctx);
        return AlertDialog(
          backgroundColor: colors.isDark ? AppColors.nearBlack : AppColorsLight.nearWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.document_scanner_outlined, color: AppColors.waterBlue),
              const SizedBox(width: 10),
              const Expanded(child: Text('Label cut off')),
            ],
          ),
          content: Text(
            "Looks like part of the label is cut off (this happens when it wraps "
            "around a bottle). Add another photo of the rest and we'll stitch "
            "them together. ($photosSoFar so far)",
            style: const TextStyle(fontSize: 14.5, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Use what I have'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.add_a_photo_outlined, size: 18),
              label: const Text('Add photo'),
            ),
          ],
        );
      },
    );
    if (add != true || !mounted) return null;

    final source = await _pickScanImageSource(
        'Add label photo', const Color(0xFF06B6D4));
    if (source == null || !mounted) return null;
    final picker = ImagePicker();
    final shot = await picker.pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 90,
    );
    if (shot == null) return null;
    return File(shot.path);
  }

  /// C4 — app-screenshot scan. A screenshot that turns out to be a recipe or
  /// a non-nutrition page is caught by the backend (422) and surfaces here as
  /// a `ScanImportException.routeTo` — we then offer to send the user to the
  /// recipe importer instead of logging garbage.
  Future<void> _scanAppScreenshot() async {
    final isGuest = ref.read(isGuestModeProvider);
    if (isGuest) {
      final canScan =
          await ref.read(guestUsageLimitsProvider.notifier).usePhotoScan();
      if (!canScan) {
        if (mounted) {
          Navigator.pop(context);
          GuestUpgradeSheet.show(context, feature: GuestFeatureLimit.photoScan);
        }
        return;
      }
    }

    final source = await _pickScanImageSource(
        'Scan App Screenshot', const Color(0xFF06B6D4));
    if (source == null || !mounted) return;

    final picker = ImagePicker();
    final shot = await picker.pickImage(
      source: source,
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 95, // screenshots are text — keep them crisp for OCR
    );
    if (shot == null || !mounted) return;

    await _runScanImport(
      kind: 'screenshot',
      imageFile: File(shot.path),
      inputType: 'screenshot_scan',
    );
  }

  /// Asks the user how many servings of a packaged food they ate. Returns the
  /// chosen count, or null if the dialog was dismissed (treated as cancel).
  Future<double?> _askServingsConsumed() async {
    final colors = ThemeColors.of(context);
    final isDark = colors.isDark;
    final cyan = const Color(0xFF06B6D4);
    final customCtrl = TextEditingController();
    try {
      return await showGlassSheet<double>(
        context: context,
        builder: (ctx) {
          return GlassSheet(
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    20, 8, 20, 16 + MediaQuery.of(ctx).viewInsets.bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
                      child: Text(
                        'How many servings did you eat?',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 2, 4, 14),
                      child: Text(
                        'The label lists nutrition per serving — pick how '
                        'much of it you actually had.',
                        style: TextStyle(
                            fontSize: 12.5, color: colors.textMuted),
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final s in const [0.5, 1.0, 1.5, 2.0, 3.0])
                          _ServingChip(
                            label: s == s.roundToDouble()
                                ? '${s.toInt()}'
                                : s.toString(),
                            color: cyan,
                            isDark: isDark,
                            onTap: () => Navigator.pop(ctx, s),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: customCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            style: TextStyle(
                                color: colors.textPrimary, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(context).logMealSheetCustomEG1,
                              hintStyle: TextStyle(
                                  color: colors.textSecondary, fontSize: 13),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            final v = double.tryParse(customCtrl.text.trim());
                            if (v != null && v > 0) Navigator.pop(ctx, v);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cyan,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(AppLocalizations.of(context).logMealSheetUse),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } finally {
      customCtrl.dispose();
    }
  }

  /// Runs a scan-import: calls the repository, then hands the result to the
  /// standard result card by setting `_analyzedResponse`. Surfaces C4
  /// edge-case metadata (glare / unit-conversion / multi-serving / low
  /// confidence) as a snackbar so the user knows what to double-check, and
  /// handles the recipe-routing exception.
  Future<void> _runScanImport({
    required String kind,
    required File imageFile,
    required String inputType,
    double servingsConsumed = 1.0,
    /// Gap 4 — accumulated extra label photos (pieces of a wrapped label).
    /// The first photo is [imageFile]; these are the additional captures.
    List<File> labelImages = const [],
  }) async {
    setState(() {
      _isLoading = true;
      _showLoadingIndicator = false;
      _error = null;
      _sourceType = 'image';
      _inputType = inputType;
      _capturedImagePath = imageFile.path;
      _currentStep = 0;
      _progressMessage = kind == 'label'
          ? 'Reading nutrition label…'
          : 'Importing screenshot…';
      _progressDetail = null;
    });
    _loadingDelayTimer?.cancel();
    _loadingDelayTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted && _isLoading) setState(() => _showLoadingIndicator = true);
    });

    ref.read(posthogServiceProvider).capture(
      eventName: 'food_scan_import',
      properties: <String, Object>{'kind': kind},
    );

    try {
      final repository = ref.read(nutritionRepositoryProvider);
      final ScanImportResult result;
      if (kind == 'label') {
        result = await repository.scanNutritionLabel(
          userId: widget.userId,
          imageFile: imageFile,
          servingsConsumed: servingsConsumed,
          caption: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          additionalImages: labelImages,
        );
        // Gap 4 — the panel is still cut off (e.g. wrapped around a bottle).
        // Offer to add another photo and re-scan the accumulated set, up to a
        // sane cap. Total photos = 1 (first) + labelImages.
        final totalPhotos = 1 + labelImages.length;
        if (mounted && result.needsMorePhotos && totalPhotos < 4) {
          _loadingDelayTimer?.cancel();
          final extra = await _promptAddAnotherLabelPhoto(totalPhotos);
          if (extra != null && mounted) {
            await _runScanImport(
              kind: 'label',
              imageFile: imageFile,
              inputType: inputType,
              servingsConsumed: servingsConsumed,
              labelImages: [...labelImages, extra],
            );
            return; // the recursive call renders the (re-scanned) result
          }
          // User declined more photos — fall through and show what we have.
        }
      } else {
        result = await repository.scanAppScreenshot(
          userId: widget.userId,
          imageFile: imageFile,
          caption: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        );
      }
      if (!mounted) return;

      _loadingDelayTimer?.cancel();
      final response = result.response;
      if (response.foodItems.isEmpty && response.totalCalories == 0) {
        setState(() {
          _isLoading = false;
          _showLoadingIndicator = false;
          _error = kind == 'label'
              ? 'Could not read this label. Try a clearer, well-lit photo.'
              : 'Could not read this screenshot. Try a clearer image.';
        });
        return;
      }

      setState(() {
        _isLoading = false;
        _showLoadingIndicator = false;
        _analyzedResponse = response;
        _sourceType = 'image';
        _originalFoodItems = List<FoodItemRanking>.from(response.foodItems);
        _pendingItemEdits.clear();
        _awaitingCoachTip = false;
      });

      // C4: tell the user what to verify. The result card already shows the
      // editable macros — these are advisory notes, not blockers.
      _showScanAdvisoryNotes(result);
    } on ScanImportException catch (e) {
      _loadingDelayTimer?.cancel();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _showLoadingIndicator = false;
      });
      if (e.routeTo == 'recipe') {
        // C4: screenshot is actually a recipe — offer the recipe importer.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context).logMealSheetThatLooksLikeA),
            action: SnackBarAction(
              label: AppLocalizations.of(context).buttonCancel,
              onPressed: () {},
            ),
          ),
        );
        setState(() => _error = e.message);
      } else {
        setState(() => _error = e.message);
      }
    } catch (e) {
      _loadingDelayTimer?.cancel();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _showLoadingIndicator = false;
        _error = 'Scan failed: $e';
      });
    }
  }

  /// Surfaces the C4 advisory notes from a scan (glare, unit conversion,
  /// multi-serving, low confidence) as one combined snackbar.
  void _showScanAdvisoryNotes(ScanImportResult result) {
    final notes = <String>[];
    if (result.unreadableFields.isNotEmpty) {
      notes.add(
          'Some fields were glared/cut off (${result.unreadableFields.join(', ')}) — check those.');
    }
    if (result.unitNotes.contains('kj_converted')) {
      notes.add('Energy was in kJ — converted to kcal.');
    }
    if (result.unitNotes.contains('per_100g_normalized')) {
      notes.add('Label was per-100g — normalized to the serving size.');
    }
    final spc = result.servingsPerContainer;
    if (result.kind == 'label' && spc != null && spc > 1) {
      notes.add(
          'This package has ${spc == spc.roundToDouble() ? spc.toInt() : spc} servings — confirm your portion.');
    }
    if (result.lowConfidence && notes.isEmpty) {
      notes.add('Low confidence on this scan — double-check the macros.');
    }
    if (notes.isEmpty || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(notes.join('  •  ')),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  /// Shared core that runs the /log-multi-image-stream pipeline and dispatches
  /// on the returned analysis_type:
  ///   - "plate"  → close sheet (log already persisted), show snackbar
  ///   - "menu"   → open MenuAnalysisSheet(analysisType: 'menu')
  ///   - "buffet" → open MenuAnalysisSheet(analysisType: 'buffet')
  Future<void> _analyzeMultiImages({
    required List<XFile> files,
    required String analysisMode,
    required String inputType,
    String? userMessage,
    /// Phase-2 §2.0: 768px-resized JPEG bytes per image (parallel-indexed
    /// with `files`). When provided, sent as multipart `images[]` for
    /// Vision; the originals from `files` go to S3 archive via
    /// `images_original[]`.
    List<Uint8List>? thumbBytesList,
    /// #15 re-scan-in-place: when set, the menu scan results are PATCHed onto
    /// this saved `menu_analyses` row instead of opening the normal save flow.
    /// Only honored for menu/buffet modes (a plate re-scan has no saved row).
    String? updateSavedMenuId,
  }) async {
    final isGuest = ref.read(isGuestModeProvider);
    if (isGuest) {
      final canScan = await ref.read(guestUsageLimitsProvider.notifier).usePhotoScan();
      if (!canScan) {
        if (mounted) {
          Navigator.pop(context);
          GuestUpgradeSheet.show(context, feature: GuestFeatureLimit.photoScan);
        }
        return;
      }
    }

    ref.read(posthogServiceProvider).capture(
      eventName: 'food_multi_image_scan',
      properties: <String, Object>{
        'count': files.length,
        'analysis_mode': analysisMode,
        'input_type': inputType,
      },
    );

    setState(() {
      _isLoading = true;
      _showLoadingIndicator = false;
      _error = null;
      _sourceType = analysisMode == 'menu' ? 'menu' : analysisMode == 'buffet' ? 'buffet' : 'image';
      _inputType = inputType;
      _capturedImagePath = files.first.path;
      _currentStep = 0;
      _progressMessage = 'Preparing ${files.length} photo${files.length == 1 ? '' : 's'}...';
      _progressDetail = null;
    });
    _loadingDelayTimer?.cancel();
    _loadingDelayTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted && _isLoading) setState(() => _showLoadingIndicator = true);
    });

    try {
      final repository = ref.read(nutritionRepositoryProvider);
      MultiImageAnalysisProgress? finalProgress;

      // Progressive streaming state: when the backend emits the first `page`
      // event for menu/buffet mode, we open the MenuAnalysisSheet and hand it
      // a streaming controller. Later pages are appended via the controller.
      MenuAnalysisStreamingController? streamingController;
      bool sheetOpened = false;
      String? pageAnalysisType;

      // #15 re-scan-in-place state. In re-scan mode we never open the live
      // streaming sheet — instead we silently accumulate every page's items
      // and image urls here, then PATCH the saved row once the scan finishes.
      // This keeps a cancelled/failed scan from ever touching the saved menu.
      final bool isRescan = updateSavedMenuId != null &&
          (analysisMode == 'menu' || analysisMode == 'buffet');
      final List<Map<String, dynamic>> rescanItems = [];
      final List<String> rescanPhotoUrls = [];

      Future<void> openSheetWithInitialItems(
        List<Map<String, dynamic>> initial,
        String type,
        MenuAnalysisStreamingController controller,
      ) async {
        setState(() {
          _isLoading = false;
          _showLoadingIndicator = false;
        });
        await showGlassSheet<void>(
          context: context,
          builder: (_) => GlassSheet(child: MenuAnalysisSheet(
            foodItems: initial,
            analysisType: type,
            isDark: widget.isDark,
            streamingController: controller,
            userId: widget.userId,
            mealType: _selectedMealType.value,
            onLogItems: (selected) async {
              // (WR1+WR4+WR6) Optimistic splice + background write + rollback.
              final ok = await _logMenuSelectedItems(
                selected: selected,
                analysisType: type,
              );
              if (ok && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context).logMealSheetLoggedItems(selected.length))),
                );
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              }
            },
          )),
        );
      }

      await for (final progress in repository.analyzeFoodFromImagesStreaming(
        userId: widget.userId,
        mealType: _selectedMealType.value,
        imageFiles: files.map((x) => File(x.path)).toList(),
        thumbBytesList: thumbBytesList, // Phase-2: 768px Vision thumbs
        analysisMode: analysisMode,
        userMessage: userMessage,
        inputType: inputType,
        // Auto / plate modes go through a human-consent review step:
        // backend returns analysis only; client renders _buildNutritionPreview
        // and the user taps "Log This Meal" to persist. Menu/buffet still
        // use MenuAnalysisSheet's existing selection flow (which is itself a
        // review step) and don't need this flag.
        confirmBeforeLog: analysisMode != 'menu' && analysisMode != 'buffet',
      )) {
        if (!mounted) return;

        if (progress.hasError) {
          _loadingDelayTimer?.cancel();
          streamingController?.markDone();
          setState(() {
            _isLoading = false;
            _showLoadingIndicator = false;
            _error = progress.message;
          });
          return;
        }

        if (progress.isPageEvent) {
          pageAnalysisType = progress.pageAnalysisType ?? pageAnalysisType;
          if (isRescan) {
            // Re-scan: accumulate silently; the sheet stays closed until the
            // PATCH succeeds. The progress indicator keeps showing meanwhile.
            rescanItems.addAll(progress.pageItems);
            if (progress.pageImageUrl != null &&
                progress.pageImageUrl!.isNotEmpty) {
              rescanPhotoUrls.add(progress.pageImageUrl!);
            }
            continue;
          }
          if (!sheetOpened) {
            sheetOpened = true;
            _loadingDelayTimer?.cancel();
            streamingController = MenuAnalysisStreamingController(
              totalPages: progress.totalPages ?? files.length,
              currentPage: progress.pageNumber ?? 1,
            );
            // Open the sheet with page 1 items; don't await since later pages
            // continue streaming into the controller.
            final typeForSheet = pageAnalysisType ?? 'menu';
            // Fire-and-forget so the stream loop keeps consuming.
            openSheetWithInitialItems(progress.pageItems, typeForSheet, streamingController!);
          } else {
            streamingController?.appendItems(
              progress.pageItems,
              page: progress.pageNumber,
              totalPages: progress.totalPages,
            );
          }
          continue;
        }

        if (progress.isPageError) {
          if (progress.pageNumber != null) {
            streamingController?.markPageError(progress.pageNumber!);
          }
          continue;
        }

        if (progress.isCompleted) {
          finalProgress = progress;
          setState(() => _analysisElapsedMs = progress.elapsedMs);
          break;
        }
        setState(() {
          _currentStep = progress.step;
          _totalSteps = progress.totalSteps;
          _progressMessage = progress.message;
          _progressDetail = progress.detail;
        });
      }

      _loadingDelayTimer?.cancel();

      // #15 re-scan-in-place: the scan finished and we never opened the live
      // sheet. Gather the freshest results (prefer the `done` payload, fall
      // back to the per-page accumulators for the progressive backend path)
      // and PATCH them onto the saved menu row. Handles its own completion.
      if (isRescan) {
        await _completeMenuRescan(
          savedMenuId: updateSavedMenuId,
          finalPayload: finalProgress?.result,
          accumulatedItems: rescanItems,
          accumulatedPhotoUrls: rescanPhotoUrls,
          analysisMode: analysisMode,
        );
        return;
      }

      // Progressive path: sheet is open and controller is managing items.
      // Just mark controller done and return; the sheet handles its own
      // lifecycle from here.
      if (sheetOpened) {
        streamingController?.markDone();
        setState(() {
          _isLoading = false;
          _showLoadingIndicator = false;
        });
        return;
      }

      if (!mounted || finalProgress == null || finalProgress.result == null) {
        setState(() {
          _isLoading = false;
          _showLoadingIndicator = false;
          if (_error == null) _error = 'Analysis failed. Please try again.';
        });
        return;
      }

      final payload = finalProgress.result!;
      final analysisType = (payload['analysis_type'] as String?) ?? 'plate';

      setState(() {
        _isLoading = false;
        _showLoadingIndicator = false;
      });

      if (analysisType == 'plate') {
        final isAnalysisOnly = payload['is_analysis_only'] == true;

        if (isAnalysisOnly) {
          // Human-consent path: backend returned analysis but did NOT write
          // a food_log row. Build a LogFoodResponse the review UI expects
          // and hand off to the same preview widget text/voice/single-camera
          // paths use. "Log This Meal" in that preview calls _handleLog()
          // which posts to /food-logs (via logFoodDirect) with any item
          // edits the user made here. No more auto-logged surprises.
          final imageUrlsRaw = (payload['image_urls'] as List?) ?? const [];
          final firstImageUrl = imageUrlsRaw.isNotEmpty ? imageUrlsRaw.first as String? : null;
          final storageKeysRaw = (payload['storage_keys'] as List?) ?? const [];
          final firstStorageKey = storageKeysRaw.isNotEmpty ? storageKeysRaw.first as String? : null;

          // Backend's plate path occasionally returns top-level macros as 0
          // even though every food_item has its own protein/carbs/fat — that
          // leaves the hero card showing "0g Protein / 0g Carbs / 0g Fat"
          // while the items below clearly have macros. Fall back to summing
          // from food_items whenever the top-level value is missing or zero.
          final foodItemsRaw = (payload['food_items'] as List?) ?? const [];
          num _sumField(String key) {
            num total = 0;
            for (final item in foodItemsRaw) {
              if (item is Map) {
                final v = item[key];
                if (v is num) total += v;
              }
            }
            return total;
          }
          num _resolveMacro(String key) {
            final raw = payload[key];
            if (raw is num && raw > 0) return raw;
            return _sumField(key);
          }
          final num _calories = _resolveMacro('total_calories');
          final num _protein = _resolveMacro('protein_g');
          final num _carbs = _resolveMacro('carbs_g');
          final num _fat = _resolveMacro('fat_g');
          final num _fiber = _resolveMacro('fiber_g');

          final previewJson = <String, dynamic>{
            'success': true,
            'food_items': foodItemsRaw,
            'total_calories': _calories,
            'protein_g': _protein,
            'carbs_g': _carbs,
            'fat_g': _fat,
            'fiber_g': _fiber == 0 ? payload['fiber_g'] : _fiber,
            'ai_suggestion': payload['ai_suggestion'] ?? payload['feedback'],
            'encouragements': payload['encouragements'],
            'warnings': payload['warnings'],
            'recommended_swap': payload['recommended_swap'],
            'personal_history_note': payload['personal_history_note'],
            'health_score': payload['health_score'],
            'inflammation_score': payload['inflammation_score'],
            'is_ultra_processed': payload['is_ultra_processed'],
            // A3 — carry the instruction-applied note into the review sheet.
            'applied_instruction_note': payload['applied_instruction_note'],
            'image_url': firstImageUrl,
            'image_storage_key': firstStorageKey,
            'source_type': 'image',
          };

          LogFoodResponse? parsed;
          try {
            parsed = LogFoodResponse.fromJson(previewJson);
          } catch (e) {
            debugPrint('❌ [LogMeal] Failed to parse plate preview payload: $e');
          }

          if (parsed == null || (parsed.foodItems.isEmpty && parsed.totalCalories == 0)) {
            setState(() {
              _error = "Couldn't identify food in these photos — try a clearer shot.";
            });
            return;
          }

          setState(() {
            _analyzedResponse = parsed;
            _sourceType = 'image';
            // Keep _capturedImagePath as the LOCAL file path set at :976
            // — the preview widget uses Image.file() when it's set. The S3
            // URL is already in parsed.imageUrl which the preview falls back
            // to if the local path is missing. Overwriting with an http URL
            // here would crash Image.file(File(httpUrl)).
            _originalFoodItems = List<FoodItemRanking>.from(parsed!.foodItems);
            _pendingItemEdits.clear();
            _analysisElapsedMs = (payload['total_time_ms'] as num?)?.toInt() ?? _analysisElapsedMs;
            // Gap 7 — capture tracker inputs from a photographed meal so the
            // confirm → /log-direct write populates sugar/caffeine/alcohol.
            final tm = <String, dynamic>{
              if (payload['added_sugar_g'] != null) 'added_sugar_g': payload['added_sugar_g'],
              if (payload['caffeine_mg'] != null) 'caffeine_mg': payload['caffeine_mg'],
              if (payload['alcohol_g'] != null) 'alcohol_g': payload['alcohol_g'],
            };
            _pendingTrackerMicros = tm.isEmpty ? null : tm;
          });
          return; // _buildNutritionPreview now renders with review + "Log This Meal"
        }

        // Legacy / fallback path: backend auto-logged. Refresh and close.
        ref
            .read(dailyNutritionProvider(_logSheetDateKey(widget.selectedDate))
                .notifier)
            .load(widget.userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).logMealSheetLoggedPhotos(files.length, (payload['total_calories'] ?? 0) as num)),
            ),
          );
          Navigator.of(context).pop();
        }
        return;
      }

      // Non-progressive fallback: auto-classified menu/buffet from batch path.
      final rawItems = (payload['food_items'] as List?) ?? const [];
      if (rawItems.isEmpty) {
        setState(() => _error = analysisType == 'menu'
            ? "Couldn't read this menu — try a clearer photo."
            : "Couldn't identify dishes — try a clearer photo.");
        return;
      }
      final foodItems = rawItems
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final imageUrls = (payload['image_urls'] as List?)?.cast<String>() ?? const [];
      final storageKeys = (payload['storage_keys'] as List?)?.cast<String>() ?? const [];
      // A3 — the menu-analysis `done` event now carries an optional
      // top-level `restaurant_name` (string or null) detected from the
      // scanned menu. Pass it through so the save-menu dialog can prefill
      // its Name field. Absent/null → behave as before (no prefill).
      final restaurantName = payload['restaurant_name'] as String?;

      if (!mounted) return;
      showGlassSheet<void>(
        context: context,
        builder: (_) => GlassSheet(child: MenuAnalysisSheet(
          foodItems: foodItems,
          analysisType: analysisType,
          isDark: widget.isDark,
          userId: widget.userId,
          mealType: _selectedMealType.value,
          restaurantName: restaurantName,
          onLogItems: (selected) async {
            // (WR1+WR4+WR6) Optimistic splice + background write + rollback.
            final ok = await _logMenuSelectedItems(
              selected: selected,
              analysisType: analysisType,
              imageUrl: imageUrls.isNotEmpty ? imageUrls.first : null,
              imageStorageKey: storageKeys.isNotEmpty ? storageKeys.first : null,
            );
            if (ok && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context).logMealSheetLoggedItems(selected.length))),
              );
              Navigator.of(context).pop(); // close MenuAnalysisSheet
              Navigator.of(context).pop(); // close LogMealSheet
            }
          },
        )),
      );
    } catch (e) {
      _loadingDelayTimer?.cancel();
      setState(() {
        _isLoading = false;
        _showLoadingIndicator = false;
        _error = e.toString();
      });
    }
  }

  /// #15 re-scan-in-place completion. Called only when a re-scan finished
  /// WITHOUT error or cancellation (a cancelled/failed scan returns earlier in
  /// `_analyzeMultiImages` and never reaches here, so the saved menu is never
  /// touched on the unhappy path). Builds the fresh sections/food_items/photo
  /// urls, PATCHes them onto the saved row, then opens the refreshed
  /// MenuAnalysisSheet for that saved menu.
  ///
  /// (Part 4 / WR1+WR4+WR6) Persist the dishes a user ticked off a
  /// menu / buffet analysis checklist — optimistically.
  ///
  /// Shared by all three MenuAnalysisSheet `onLogItems` call sites (fresh
  /// scan, progressive-streaming scan, re-scanned saved menu).
  ///
  /// Flow:
  ///  1. (WR1) Splice every selected dish into nutritionProvider state
  ///     IMMEDIATELY — one optimistic FoodLog per dish — so they appear in
  ///     the Nutrition Daily meal list + rings within one frame.
  ///  2. (WR6) Refresh Home's timeline.
  ///  3. Fire `/nutrition/log-selected-items` in the background.
  ///  4. On success: reconcile in place with a forced summary refresh (the
  ///     server now holds the authoritative rows).
  ///  5. (WR4) On failure: roll back every spliced row and surface a calm
  ///     retry snackbar — never a silent divergence.
  ///
  /// Returns true when the optimistic splice + dispatch happened (the caller
  /// closes the sheets); false only if there were no items to log.
  Future<bool> _logMenuSelectedItems({
    required List<Map<String, dynamic>> selected,
    required String analysisType,
    String? imageUrl,
    String? imageStorageKey,
  }) async {
    if (selected.isEmpty) return false;
    final repository = ref.read(nutritionRepositoryProvider);
    final nutritionNotifier = ref
        .read(dailyNutritionProvider(_logSheetDateKey(widget.selectedDate)).notifier);
    final mealType = _selectedMealType.value;
    // menu → 'menu', buffet → 'buffet' (mirrors the backend source_type map).
    final sourceType = analysisType == 'buffet' ? 'buffet' : 'menu';
    final inputType = analysisType == 'menu' ? 'menu_scan' : 'buffet_scan';

    // (WR1) Splice each ticked dish before the network round-trip. Keep the
    // optimistic ids so a failed write can roll every one of them back.
    final optimisticIds = <String>[];
    for (final item in selected) {
      final spliced = nutritionNotifier.spliceMenuItem(
        item: item,
        mealType: mealType,
        userId: widget.userId,
        sourceType: sourceType,
        imageUrl: imageUrl,
      );
      optimisticIds.add(spliced.id);
    }
    // (WR6) Show the new meals on Home's timeline too.
    nutritionNotifier.refreshTimeline();

    // Background write — UI already reflects the meals.
    () async {
      try {
        await repository.logSelectedMealItems(
          userId: widget.userId,
          mealType: mealType,
          analysisType: analysisType,
          items: selected,
          inputType: inputType,
          imageUrl: imageUrl,
          imageStorageKey: imageStorageKey,
        );
        // Reconcile: the server now holds the real rows. forceRefresh swaps
        // the optimistic rows for authoritative data in place.
        nutritionNotifier.load(widget.userId, forceRefresh: true);
        // Refresh the weekly NUTRITION STATS + inflammation trend.
        nutritionNotifier.refreshNutritionStats(widget.userId);
      } catch (e) {
        debugPrint('❌ [LogMeal] menu log-selected-items failed: $e');
        // (WR4) Roll back every optimistic row so the meal list doesn't show
        // dishes the server never stored.
        nutritionNotifier.optimisticRemoveLogs(optimisticIds);
        final messenger = ScaffoldMessenger.maybeOf(
          Navigator.of(context, rootNavigator: true).overlay?.context ??
              context,
        );
        messenger?.showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context).logMealSheetCouldnTLogThose),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: AppLocalizations.of(context).buttonRetry,
              onPressed: () => _logMenuSelectedItems(
                selected: selected,
                analysisType: analysisType,
                imageUrl: imageUrl,
                imageStorageKey: imageStorageKey,
              ),
            ),
          ),
        );
      }
    }();
    return true;
  }

  /// On PATCH failure: surfaces a clear error and returns — the saved menu row
  /// on the server is left exactly as it was (PATCH is atomic server-side).
  Future<void> _completeMenuRescan({
    required String savedMenuId,
    required Map<String, dynamic>? finalPayload,
    required List<Map<String, dynamic>> accumulatedItems,
    required List<String> accumulatedPhotoUrls,
    required String analysisMode,
  }) async {
    // Resolve the freshest scan results. The non-progressive backend path
    // returns everything in the `done` payload; the progressive path streams
    // per-page events which we accumulated in `accumulatedItems` instead.
    final List<Map<String, dynamic>> freshItems;
    final payloadItems = (finalPayload?['food_items'] as List?)
        ?.whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    if (payloadItems != null && payloadItems.isNotEmpty) {
      freshItems = payloadItems;
    } else {
      freshItems = accumulatedItems;
    }

    // Empty results → the photo was unreadable. Do NOT PATCH (that would wipe
    // the saved menu's existing dishes). Surface an error, leave row intact.
    if (freshItems.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _showLoadingIndicator = false;
        _error = analysisMode == 'menu'
            ? "Couldn't read this menu — the saved menu was left unchanged."
            : "Couldn't identify dishes — the saved menu was left unchanged.";
      });
      return;
    }

    // Sections (menu/buffet group headers) — optional; empty list is valid.
    final freshSections = (finalPayload?['sections'] as List?)
            ?.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        const <Map<String, dynamic>>[];

    // Photo urls — prefer the `done` payload's image_urls, fall back to the
    // per-page image urls accumulated during progressive streaming.
    final payloadPhotoUrls =
        (finalPayload?['image_urls'] as List?)?.cast<String>();
    final freshPhotoUrls = (payloadPhotoUrls != null &&
            payloadPhotoUrls.isNotEmpty)
        ? payloadPhotoUrls
        : accumulatedPhotoUrls;

    // `_analysisElapsedMs` is nullable (int?) — coalesce to 0 before use.
    final elapsedMs = (finalPayload?['total_time_ms'] as num?)?.toDouble() ??
        (_analysisElapsedMs ?? 0).toDouble();
    final elapsedSeconds = elapsedMs > 0 ? elapsedMs / 1000.0 : null;
    final analysisType =
        (finalPayload?['analysis_type'] as String?) ?? analysisMode;

    setState(() {
      _isLoading = false;
      _showLoadingIndicator = false;
    });

    final api = ref.read(apiClientProvider);

    Map<String, dynamic>? updatedRow;
    try {
      final resp = await api.patch<Map<String, dynamic>>(
        '/nutrition/menu-analyses/$savedMenuId',
        data: {
          'sections': freshSections,
          'food_items': freshItems,
          'menu_photo_urls': freshPhotoUrls,
          if (elapsedSeconds != null) 'elapsed_seconds': elapsedSeconds,
          'analysis_type': analysisType,
        },
      );
      updatedRow = resp.data;
    } catch (e) {
      // PATCH failed — the saved menu row is untouched on the server.
      if (mounted) {
        setState(() {
          _error = "Couldn't update the saved menu — it was left unchanged. "
              "Please try again.";
        });
      }
      return;
    }

    if (!mounted || updatedRow == null) return;

    // Refreshed sheet — reopen the saved menu with the new content. Passing
    // `savedMenuId` keeps the header bookmark in its "saved" state.
    final refreshedItems = (updatedRow['food_items'] as List?)
            ?.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        freshItems;
    final refreshedPhotoUrls =
        (updatedRow['menu_photo_urls'] as List?)?.cast<String>() ??
            freshPhotoUrls;
    final refreshedElapsed =
        (updatedRow['elapsed_seconds'] as num?)?.toDouble() ?? elapsedSeconds;
    final refreshedType =
        (updatedRow['analysis_type'] as String?) ?? analysisType;
    final savedTitle = updatedRow['title'] as String?;
    final restaurantName = updatedRow['restaurant_name'] as String?;
    final restaurantAddress = updatedRow['address'] as String?;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).logMealSheetMenuUpdated)),
    );

    await showGlassSheet<void>(
      context: context,
      builder: (_) => GlassSheet(child: MenuAnalysisSheet(
        foodItems: refreshedItems,
        analysisType: refreshedType,
        isDark: widget.isDark,
        userId: widget.userId,
        mealType: _selectedMealType.value,
        menuPhotoUrls: refreshedPhotoUrls,
        elapsedSeconds: refreshedElapsed,
        restaurantName: restaurantName,
        restaurantAddress: restaurantAddress,
        // Saved-menu identity — header renders in "saved" state, no re-save.
        savedMenuId: savedMenuId,
        savedTitle: savedTitle,
        onLogItems: (selected) async {
          // (WR1+WR4+WR6) Optimistic splice + background write + rollback.
          final ok = await _logMenuSelectedItems(
            selected: selected,
            analysisType: refreshedType,
            imageUrl:
                refreshedPhotoUrls.isNotEmpty ? refreshedPhotoUrls.first : null,
          );
          if (ok && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context).logMealSheetLoggedItems(selected.length))),
            );
            Navigator.of(context).pop(); // close MenuAnalysisSheet
            Navigator.of(context).pop(); // close LogMealSheet
          }
        },
      )),
    );
  }


  Future<void> _pickImage(ImageSource source) async {
    debugPrint('📸 [LogMeal] _pickImage started | source=${source.name}');

    final isGuest = ref.read(isGuestModeProvider);
    if (isGuest) {
      final canScan = await ref.read(guestUsageLimitsProvider.notifier).usePhotoScan();
      if (!canScan) {
        if (mounted) {
          Navigator.pop(context);
          GuestUpgradeSheet.show(context, feature: GuestFeatureLimit.photoScan);
        }
        return;
      }
    }

    try {
      // Phase-2 §2.0: pick paired artifacts (full-res original + 768px Vision thumb).
      // Falls back to legacy single-artifact path if compression fails.
      final artifacts = await pickFoodScanArtifacts(source);
      if (artifacts == null) return;
      final image = artifacts.original;

      ref.read(posthogServiceProvider).capture(
        eventName: 'food_photo_taken',
        properties: <String, Object>{'source': source == ImageSource.camera ? 'camera' : 'gallery'},
      );

      setState(() {
        _isLoading = true;
        _showLoadingIndicator = false;
        _error = null;
        _sourceType = 'image';
        _inputType = source == ImageSource.camera ? 'camera' : 'gallery';
        _capturedImagePath = image.path;
        _currentStep = 0;
        _progressMessage = 'Preparing image...';
        _progressDetail = null;
      });
      // Only show loading indicator if analysis takes > 500ms (avoids flash for cache hits)
      _loadingDelayTimer?.cancel();
      _loadingDelayTimer = Timer(const Duration(milliseconds: 500), () {
        if (mounted && _isLoading) {
          setState(() => _showLoadingIndicator = true);
        }
      });

      final repository = ref.read(nutritionRepositoryProvider);
      LogFoodResponse? response;

      await for (final progress in repository.analyzeFoodFromImageStreaming(
        userId: widget.userId,
        mealType: _selectedMealType.value,
        imageFile: image,
        thumbBytes: artifacts.thumbBytes, // 768px JPEG → Vision (single tile)
      )) {
        if (!mounted) return;

        if (progress.hasError) {
          _loadingDelayTimer?.cancel();
          setState(() { _isLoading = false; _showLoadingIndicator = false; _error = progress.message; });
          return;
        }

        if (progress.isCompleted && progress.foodLog != null) {
          // The `done` event renders the card immediately (~3s). The late
          // `coach_tips` event (progress.coachTips != null) arrives a few
          // seconds later carrying a foodLog with tips merged in — when it
          // does, re-render the preview so tips appear. We do NOT break on
          // `done`; we keep listening so the tips event isn't dropped.
          response = progress.foodLog;
          final isTips = progress.hasCoachTips;
          setState(() {
            _analysisElapsedMs = progress.elapsedMs;
            _isLoading = false;
            _showLoadingIndicator = false;
            if (response!.foodItems.isNotEmpty || response.totalCalories > 0) {
              _analyzedResponse = response;
              _sourceType = 'image';
              if (!isTips) {
                // Only reset edits on the first (done) render — a late tips
                // re-render must not wipe portion edits the user made.
                _originalFoodItems = List<FoodItemRanking>.from(response.foodItems);
                _pendingItemEdits.clear();
                // Shimmer the coach-tip card until coach_tips arrives.
                _awaitingCoachTip = (response.aiSuggestion == null ||
                        response.aiSuggestion!.trim().isEmpty) &&
                    (response.encouragements == null ||
                        !response.encouragements!
                            .any((e) => e.trim().isEmpty == false)) &&
                    (response.warnings == null ||
                        !response.warnings!
                            .any((w) => w.trim().isEmpty == false)) &&
                    (response.recommendedSwap == null ||
                        response.recommendedSwap!.trim().isEmpty);
              } else {
                _awaitingCoachTip = false;
              }
            }
          });
          _loadingDelayTimer?.cancel();
          if (isTips) break;  // tips arrived — stream is done
          continue;            // keep listening for coach_tips
        }

        setState(() {
          _currentStep = progress.step;
          _totalSteps = progress.totalSteps;
          _progressMessage = progress.message;
          _progressDetail = progress.detail;
        });
      }

      _loadingDelayTimer?.cancel();
      if (mounted && response != null) {
        setState(() { _isLoading = false; _showLoadingIndicator = false; });

        if (response.foodItems.isEmpty && response.totalCalories == 0) {
          setState(() { _error = 'Could not identify food in the image. Please try a clearer photo.'; });
          return;
        }
        // _analyzedResponse already set inside the loop on the `done` event.
        // _buildNutritionPreview renders food items, AI tips, editing.
      } else if (mounted && response == null) {
        // Stream completed but no response - show error
        debugPrint('❌ [LogMeal] Stream completed but response is null');
        setState(() {
          _isLoading = false;
          _showLoadingIndicator = false;
          _error = 'Analysis failed. Please try again.';
        });
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [LogMeal] Exception in _pickImage | error=$e');
      debugPrint('   stackTrace: $stackTrace');
      _loadingDelayTimer?.cancel();
      setState(() {
        _isLoading = false;
        _showLoadingIndicator = false;
        _error = e.toString();
      });
    }
  }



  /// Log an already analyzed food response.
  ///
  /// (Part 4) The optimistic splice into `nutritionProvider` now happens in
  /// the caller [_handleLog] BEFORE the network POST starts (WR1) — this
  /// method only handles the fast UI dismiss + post-meal review sheet and the
  /// background reconcile. [optimisticLogId] is the id of the row [_handleLog]
  /// spliced; it is passed through purely so this method does NOT splice a
  /// second time.
  void _logAnalyzedFood(LogFoodResponse response,
      [Future<void>? saveFuture,
      String? Function()? getSavedLogId,
      String? optimisticLogId]) async {
    debugPrint('✅ [LogMeal] _logAnalyzedFood called | calories=${response.totalCalories} | protein=${response.proteinG}g | foodItems=${response.foodItems.length} | optimisticLogId=$optimisticLogId');

    // Check if there's an active fast that should be ended
    final fastingState = ref.read(fastingProvider);
    if (fastingState.activeFast != null && response.totalCalories > 50) {
      debugPrint('⏰ [LogMeal] Active fast detected | calories > 50, showing end fast dialog');
      // Show dialog to confirm ending fast
      final shouldEndFast = await _showEndFastDialog(fastingState.activeFast!);
      if (!mounted) return;

      if (shouldEndFast == true) {
        // End the fast
        await ref.read(fastingProvider.notifier).endFast(
          userId: widget.userId,
          notes: 'Ended by meal log: ${response.foodItems.map((f) => f.name).join(", ")}',
        );
      } else if (shouldEndFast == null) {
        // User cancelled, don't log the meal
        return;
      }
      // If shouldEndFast == false, continue logging but don't end fast
    }

    // Capture refs before popping (widget unmounts after pop)
    final nutritionNotifier = ref
        .read(dailyNutritionProvider(_logSheetDateKey(widget.selectedDate)).notifier);
    final userId = widget.userId;
    final isDark = widget.isDark;
    final foodNames = response.foodItems.map((f) => f.name).toList();
    final totalCalories = response.totalCalories;
    // foodLogId from analysis response is null (not saved yet)
    // getSavedLogId() will have the real ID after save completes

    // Get the navigator's overlay context which survives the pop
    final overlay = Navigator.of(context).overlay;

    // NOTE (Part 4 / WR1): the optimistic splice into nutritionProvider
    // already happened in `_handleLog` BEFORE the network POST — the meal is
    // in the Nutrition Daily list + rings within one frame. We must NOT
    // splice again here or the row would be duplicated.

    // Close sheet immediately for snappy UX
    Navigator.pop(context);

    // Fire-and-forget: reconcile nutrition UI after the save SUCCEEDS. On
    // failure `saveFuture` rejects (handled in `_handleLog` — rollback +
    // retry snackbar) so we deliberately do NOT reconcile on the error path:
    // a forceRefresh there would just re-pull a server state that never had
    // the row, which the rollback already reflects.
    if (saveFuture != null) {
      unawaited(saveFuture.then((_) {
        // forceRefresh replaces the optimistic row with the authoritative
        // server row in place (server-derived fields: streak, adherence).
        nutritionNotifier.load(userId, forceRefresh: true);
        // Refresh the NUTRITION STATS section (weekly aggregates + inflammation
        // trend) so it reflects the new meal without a manual pull-to-refresh.
        nutritionNotifier.refreshNutritionStats(userId);
        // Schedule the 45-min reminder after save completes (needs foodLogId)
        final logId = getSavedLogId?.call();
        if (logId != null && logId.isNotEmpty) {
          _schedulePostMealReminder(
            userId: userId,
            foodLogId: logId,
            mealSummary: foodNames.isNotEmpty ? foodNames.first : null,
          );
        }
      }, onError: (_) {
        // Swallowed — `_handleLog` already rolled back / queued. No reconcile.
      }));
    } else {
      nutritionNotifier.load(userId, forceRefresh: true);
      nutritionNotifier.refreshNutritionStats(userId);
    }

    // Show success sheet immediately — don't block on backend save
    await Future.delayed(const Duration(milliseconds: 150));
    final reviewContext = overlay?.context;
    if (reviewContext != null && reviewContext.mounted) {
      showPostMealReviewSheet(
        reviewContext,
        foodNames: foodNames,
        totalCalories: totalCalories,
        isDark: isDark,
        userId: userId,
        foodLogId: getSavedLogId?.call(),
        saveFuture: saveFuture,
        getSavedLogId: getSavedLogId,
      );
    }
  }

  Future<void> _schedulePostMealReminder({
    required String userId,
    required String foodLogId,
    String? mealSummary,
  }) async {
    try {
      final repo = ref.read(nutritionRepositoryProvider);
      final settings = await repo.getPatternsSettings(userId);
      if (settings.postMealCheckinDisabled || !settings.postMealReminderEnabled) {
        return;
      }
      await PostMealCheckinReminderService.instance.scheduleForLog(
        foodLogId: foodLogId,
        loggedAt: DateTime.now(),
        mealSummary: mealSummary,
        reminderEnabled: settings.postMealReminderEnabled,
        checkinDisabled: settings.postMealCheckinDisabled,
      );
    } catch (e) {
      debugPrint('⚠️ [PostMeal] Could not schedule reminder: $e');
    }
  }


  Future<void> _handleBarcodeScan(String barcode) async {
    debugPrint('🔍 [LogMeal] Barcode scanned | barcode=$barcode | hasScanned=$_hasScanned');
    if (_hasScanned) {
      debugPrint('🔍 [LogMeal] Ignoring duplicate barcode scan');
      return;
    }
    _hasScanned = true;

    // Check guest limits for barcode scanning
    final isGuest = ref.read(isGuestModeProvider);
    if (isGuest) {
      final canScan = await ref.read(guestUsageLimitsProvider.notifier).useBarcodeScan();
      if (!canScan) {
        if (mounted) {
          Navigator.pop(context);
          GuestUpgradeSheet.show(context, feature: GuestFeatureLimit.barcodeScan);
        }
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _showLoadingIndicator = true;
      _error = null;
      _sourceType = 'barcode';
      _inputType = 'barcode';
    });

    try {
      final repository = ref.read(nutritionRepositoryProvider);
      debugPrint('🔍 [LogMeal] Looking up barcode in database...');
      final product = await repository.lookupBarcode(barcode);
      debugPrint('🔍 [LogMeal] Barcode lookup result | productName=${product.productName} | caloriesPer100g=${product.caloriesPer100g}');
      ref.read(posthogServiceProvider).capture(
        eventName: 'food_barcode_scanned',
        properties: <String, Object>{'barcode': barcode},
      );

      if (mounted) {
        final servings = await _showProductConfirmation(product);
        debugPrint('🔍 [LogMeal] Product confirmation | servings=$servings');
        if (servings != null) {
          debugPrint('🔍 [LogMeal] Logging barcode food | mealType=${_selectedMealType.value} | servings=$servings');
          final response = await repository.logFoodFromBarcode(
            userId: widget.userId,
            barcode: barcode,
            mealType: _selectedMealType.value,
            servings: servings,
          );

          if (mounted) {
            debugPrint('✅ [LogMeal] Barcode food logged successfully | calories=${response.totalCalories}');
            Navigator.pop(context);
            _showSuccessSnackbar(
              response.totalCalories,
              foodName: product.productName,
              proteinG: response.proteinG,
              carbsG: response.carbsG,
              fatG: response.fatG,
              foodLogId: response.foodLogId,
              dataSource: 'barcode',
            );
            // (WR1) Splice the barcode meal into nutritionProvider state so it
            // appears in the Nutrition Daily meal list + rings within one
            // frame. A plain loadTodaySummary() would hit the 5-min cache
            // skip and the new meal wouldn't show until the TTL elapsed.
            // logFoodFromBarcode already returns the real food_log_id, so the
            // spliced row carries it and the forceRefresh below is an in-place
            // reconcile, not a new insert.
            final nutritionNotifier = ref
        .read(dailyNutritionProvider(_logSheetDateKey(widget.selectedDate)).notifier);
            nutritionNotifier.spliceMenuItem(
              item: {
                'name': product.productName,
                'calories': response.totalCalories,
                'protein_g': response.proteinG,
                'carbs_g': response.carbsG,
                'fat_g': response.fatG,
                'amount': '1 serving',
              },
              mealType: _selectedMealType.value,
              userId: widget.userId,
              sourceType: 'barcode',
              logId: response.foodLogId,
              imageUrl: product.imageThumbUrl ?? product.imageUrl,
            );
            // (WR6) Reflect the new meal on Home's timeline.
            nutritionNotifier.refreshTimeline();
            // Reconcile server-derived fields in the background.
            nutritionNotifier.load(widget.userId,
                forceRefresh: true);
            // Refresh the weekly NUTRITION STATS + inflammation trend.
            nutritionNotifier.refreshNutritionStats(widget.userId);
          }
        } else {
          debugPrint('🔍 [LogMeal] User cancelled barcode confirmation');
          setState(() {
            _isLoading = false;
            _hasScanned = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ [LogMeal] Barcode scan error | error=$e');
      final friendly = _friendlyBarcodeError(e);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasScanned = false;
          _error = friendly;
        });
        _showBarcodeNotFoundRecovery(friendly);
      }
    }
  }

  /// Map a barcode lookup failure to copy a user can act on. The Dio raw
  /// exception ("DioException [bad response]: 404 …") is hostile UX —
  /// pick a short sentence per real cause and let the recovery sheet
  /// offer the next step.
  String _friendlyBarcodeError(Object e) {
    if (e is DioException) {
      final code = e.response?.statusCode;
      if (code == 404) {
        return "We couldn't find that product in our food database. You can log it manually instead.";
      }
      if (code == 400) {
        return "That barcode didn't look valid. Try scanning again with the whole code in frame.";
      }
      if (code == 503 || code == 502 || code == 504) {
        return "The food database is temporarily unavailable. Please try again shortly.";
      }
      if (code == 401 || code == 403) {
        return "Your session expired while scanning. Sign back in and try again.";
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError) {
        return "Network hiccup. Check your connection and try the scan again.";
      }
    }
    return "Barcode scan failed. Please try again or log this food manually.";
  }

  /// Bottom sheet shown after a failed barcode scan that lets the user
  /// jump straight into manual logging instead of staring at a red error
  /// box.
  void _showBarcodeNotFoundRecovery(String message) {
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Material(
              color: Theme.of(sheetCtx).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.qr_code_scanner_outlined,
                          color: Theme.of(sheetCtx).colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(sheetCtx).logMealSheetBarcodeScan,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      message,
                      style: const TextStyle(fontSize: 15, height: 1.35),
                    ),
                    const SizedBox(height: 18),
                    // Gap 3 — primary recovery: snap the nutrition label. The
                    // package is already in the user's hand, so the label is
                    // the highest-accuracy next step when the barcode isn't in
                    // the database. Reuses the existing label-scan pipeline.
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetCtx);
                        if (mounted) {
                          setState(() => _error = null);
                          // ignore: unawaited_futures
                          _scanNutritionLabel();
                        }
                      },
                      icon: const Icon(Icons.document_scanner_outlined, size: 18),
                      label: Text(
                        AppLocalizations.of(sheetCtx).customFoodBuilderScanLabel,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(sheetCtx),
                            child: Text(AppLocalizations.of(sheetCtx).logMealSheetTryAgain),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(sheetCtx);
                              if (mounted) {
                                setState(() {
                                  _error = null;
                                  _sourceType = 'text';
                                  _inputType = 'text';
                                });
                              }
                            },
                            child: Text(AppLocalizations.of(sheetCtx).logMealSheetLogManually),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }


  void _showSuccessSnackbar(
    int calories, {
    String? foodName,
    LogFoodResponse? response,
    double? proteinG,
    double? carbsG,
    double? fatG,
    String? foodLogId,
    String? dataSource,
  }) {
    // Capture context-dependent values before async gap
    final capturedContext = context;
    final apiClient = ref.read(apiClientProvider);

    // Derive a display name from food items or fallback
    final displayName = foodName ??
        (response?.foodItems.isNotEmpty == true
            ? response!.foodItems.map((f) => f.name).join(', ')
            : 'Food');

    // Use individual fields if provided, otherwise fall back to LogFoodResponse
    final effectiveProtein = proteinG ?? response?.proteinG;
    final effectiveCarbs = carbsG ?? response?.carbsG;
    final effectiveFat = fatG ?? response?.fatG;
    final effectiveFoodLogId = foodLogId ?? response?.foodLogId;
    final effectiveDataSource = dataSource ?? response?.sourceType;

    // Use Future.delayed to show snackbar after sheet animation completes
    // This ensures the nav bar is visible and snackbar appears above it
    Future.delayed(const Duration(milliseconds: 100), () {
      showAccuracyFeedbackSnackbar(
        capturedContext,
        foodName: displayName,
        calories: calories,
        onThumbsDown: () {
          showFoodReportDialog(
            capturedContext,
            apiClient: apiClient,
            foodName: displayName,
            originalCalories: calories,
            originalProtein: effectiveProtein,
            originalCarbs: effectiveCarbs,
            originalFat: effectiveFat,
            foodLogId: effectiveFoodLogId,
            dataSource: effectiveDataSource,
          );
        },
      );
    });
  }

  /// Manual "Add food" — opens a small text-input sheet, runs the existing
  /// streaming text-analysis endpoint, then APPENDS the resulting items onto
  /// the current preview (both `_analyzedResponse.foodItems` and
  /// `_originalFoodItems` so swap/edit diffs still line up). Reused from the
  /// preview action row, the bottom of the items list, and (via the shared
  /// `showAddFoodSheet` helper) from the menu-analysis sheet.
  Future<void> _handleAddFoodItem({required String entryPoint}) async {
    if (_addingFoodItem) return;
    if (_analyzedResponse == null) return;

    // Guest gate — same usage limit text describe uses, since this is
    // effectively a one-item text describe.
    final isGuest = ref.read(isGuestModeProvider);
    if (isGuest) {
      final canDescribe =
          await ref.read(guestUsageLimitsProvider.notifier).useTextDescribe();
      if (!canDescribe) {
        if (mounted) {
          GuestUpgradeSheet.show(context, feature: GuestFeatureLimit.textDescribe);
        }
        return;
      }
    }

    final description = await showAddFoodSheet(context);
    if (description == null || description.trim().isEmpty) return;
    if (!mounted) return;

    setState(() => _addingFoodItem = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final repository = ref.read(nutritionRepositoryProvider);
      LogFoodResponse? streamed;
      await for (final progress in repository.analyzeFoodFromTextStreaming(
        userId: widget.userId,
        description: description.trim(),
        mealType: _selectedMealType.value,
        moodBefore: _moodBefore?.value,
      )) {
        if (!mounted) return;
        if (progress.hasError) {
          messenger.showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).logMealSheetCouldnTAddFood(progress.message ?? ''))),
          );
          return;
        }
        if (progress.isCompleted && progress.foodLog != null) {
          streamed = progress.foodLog;
          break;
        }
      }

      if (!mounted) return;
      if (streamed == null || streamed.foodItems.isEmpty) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).logMealSheetCouldnTRecognizeAny),
          ),
        );
        return;
      }

      final updatedItems =
          List<FoodItemRanking>.from(_analyzedResponse!.foodItems)
            ..addAll(streamed.foodItems);
      _originalFoodItems ??=
          List<FoodItemRanking>.from(_analyzedResponse!.foodItems);
      _originalFoodItems!.addAll(streamed.foodItems);

      setState(() {
        _analyzedResponse = _rebuildResponseWithItems(updatedItems);
      });

      ref.read(posthogServiceProvider).capture(
        eventName: 'food_item_added_manually',
        properties: <String, Object>{
          'entry_point': entryPoint,
          'items_added': streamed.foodItems.length,
        },
      );
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).logMealSheetCouldnTAddFood(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _addingFoodItem = false);
    }
  }

  /// Build a compact, correction-framed description for the Refine flow.
  /// Lists the current item set (name + macros) plus, when the user has made
  /// manual per-item edits, an explicit "keep these exact" instruction so the
  /// re-analysis (RE2) never clobbers values the user already corrected.
  String _buildRefineDescription(String note) {
    final items = _analyzedResponse!.foodItems;
    final editedNames = _pendingItemEdits.keys
        .where((i) => i >= 0 && i < items.length)
        .map((i) => items[i].name.trim())
        .where((n) => n.isNotEmpty)
        .toSet();

    final itemLines = <String>[];
    for (final it in items) {
      final cal = it.calories ?? 0;
      final p = (it.proteinG ?? 0).round();
      final c = (it.carbsG ?? 0).round();
      final f = (it.fatG ?? 0).round();
      itemLines.add('- ${it.name}: ${cal}kcal, ${p}g protein, '
          '${c}g carbs, ${f}g fat');
    }
    final currentBlock = itemLines.isEmpty
        ? '(no items detected yet)'
        : itemLines.join('\n');

    final keepLine = editedNames.isEmpty
        ? ''
        : "\nKeep these items' nutrition EXACTLY as listed unless the "
            "correction directly changes them: ${editedNames.join(', ')}.";

    // The streaming text-analysis endpoint treats this whole string as a meal
    // description and returns a corrected full item list (handles add, remove,
    // modify, portion scaling, brand swaps — RE3/R1-R10 — in one pass).
    return 'Correcting a previous meal analysis.\n'
        'Current meal items:\n$currentBlock\n'
        "User correction: \"$note\".$keepLine\n"
        'Apply the correction and return the corrected FULL meal item list '
        'with accurate macros.';
  }

  /// Refine-with-AI — opens the glass note sheet, sends the note + current
  /// item set to the streaming text-analysis endpoint framed as a CORRECTION,
  /// and REPLACES the current item set with the result (Add appends; Refine
  /// replaces). Totals + scoring are recomputed via [_rebuildResponseWithItems]
  /// and the late `coach_tips` event. The previous analysis is kept on failure
  /// and a one-step revert is offered via `_previousResponse`.
  Future<void> _handleRefineMeal() async {
    if (_refiningMeal) return;
    if (_analyzedResponse == null) return;

    final isGuest = ref.read(isGuestModeProvider);
    if (isGuest) {
      final canDescribe =
          await ref.read(guestUsageLimitsProvider.notifier).useTextDescribe();
      if (!canDescribe) {
        if (mounted) {
          GuestUpgradeSheet.show(context, feature: GuestFeatureLimit.textDescribe);
        }
        return;
      }
    }

    final note = await showRefineFoodSheet(context);
    if (note == null || note.trim().isEmpty) return; // RE5: empty → no-op
    if (!mounted) return;

    // RE5: a too-short / nonsense note can't meaningfully correct a meal —
    // gentle no-op rather than destroying the current analysis.
    if (note.trim().length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).logMealSheetAddABitMore)),
      );
      return;
    }

    // RE12: snapshot the current analysis so the user can revert in one step,
    // and RE7: restore it untouched if the network call fails.
    final previousAnalysis = _analyzedResponse;
    final previousOriginals = _originalFoodItems == null
        ? null
        : List<FoodItemRanking>.from(_originalFoodItems!);
    final previousEdits = <int, List<FoodItemEdit>>{
      for (final e in _pendingItemEdits.entries) e.key: List.of(e.value),
    };

    setState(() {
      _refiningMeal = true;
      _isAnalyzing = true;
      _showLoadingIndicator = true;
      _progressMessage = 'Refining your meal...';
      _progressDetail = null;
      _awaitingCoachTip = false;
    });
    final messenger = ScaffoldMessenger.of(context);

    try {
      final repository = ref.read(nutritionRepositoryProvider);
      LogFoodResponse? streamed;
      await for (final progress in repository.analyzeFoodFromTextStreaming(
        userId: widget.userId,
        description: _buildRefineDescription(note.trim()),
        mealType: _selectedMealType.value,
        moodBefore: _moodBefore?.value,
      )) {
        if (!mounted) return;
        if (progress.hasError) {
          // RE7: keep the previous analysis intact on failure.
          messenger.showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).logMealSheetCouldnTRefineError(progress.message ?? ''))),
          );
          return;
        }
        if (progress.isCompleted && progress.foodLog != null) {
          streamed = progress.foodLog;
          if (progress.hasCoachTips) break;
          continue; // keep listening for the late coach_tips event
        }
        setState(() {
          _progressMessage = progress.message;
          _progressDetail = progress.detail;
        });
      }

      if (!mounted) return;
      // RE5/RE13: refine returned nothing usable — keep the prior analysis.
      if (streamed == null || streamed.foodItems.isEmpty) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).logMealSheetCouldnTApplyThat),
          ),
        );
        return;
      }

      final refined = streamed;
      // RE9: sanity-clamp implausible totals — flag rather than trust blindly.
      final cals = refined.totalCalories;
      if (cals <= 0 || cals > 6000) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              cals <= 0
                  ? 'That correction produced an empty meal — kept the previous estimate.'
                  : "That correction looks off ($cals kcal) — kept the previous estimate.",
            ),
          ),
        );
        return;
      }

      // REPLACE the item set (Add appends — Refine replaces). Re-snapshot the
      // originals so subsequent per-item edits diff against the refined values,
      // and clear stale per-item edits (they keyed the old item indices).
      setState(() {
        // Keep _previousResponse so the existing "back to results" / revert
        // affordance (RE12) can restore the pre-refine estimate.
        _previousResponse = previousAnalysis;
        _originalFoodItems = List<FoodItemRanking>.from(refined.foodItems);
        _pendingItemEdits.clear();
        // _rebuildResponseWithItems recomputes totals; health/inflammation
        // scoring (RE8) comes from the refined response itself.
        _analyzedResponse = refined;
        _awaitingCoachTip = (refined.aiSuggestion == null ||
                refined.aiSuggestion!.trim().isEmpty) &&
            (refined.encouragements == null ||
                !refined.encouragements!.any((e) => e.trim().isNotEmpty)) &&
            (refined.warnings == null ||
                !refined.warnings!.any((w) => w.trim().isNotEmpty)) &&
            (refined.recommendedSwap == null ||
                refined.recommendedSwap!.trim().isEmpty);
      });

      ref.read(posthogServiceProvider).capture(
        eventName: 'food_meal_refined',
        properties: <String, Object>{
          'note_length': note.trim().length,
          'items_before': previousAnalysis?.foodItems.length ?? 0,
          'items_after': refined.foodItems.length,
          'data_source': _sourceType,
        },
      );

      messenger.showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).logMealSheetMealRefined),
          action: SnackBarAction(
            label: AppLocalizations.of(context).logMealSheetUndo,
            onPressed: () {
              if (!mounted) return;
              setState(() {
                _analyzedResponse = previousAnalysis;
                _originalFoodItems = previousOriginals;
                _pendingItemEdits
                  ..clear()
                  ..addAll(previousEdits);
                _previousResponse = null;
                _awaitingCoachTip = false;
              });
            },
          ),
        ),
      );
    } catch (e) {
      // RE7: network/timeout mid-refine — previous analysis is still in state.
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).logMealSheetCouldnTRefineError(e.toString()))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _refiningMeal = false;
          _isAnalyzing = false;
          _showLoadingIndicator = false;
        });
      }
    }
  }

}

/// Result returned by [_LogMealSheetState._showAddAnotherPrompt] — bundles
/// the user's "add another vs done" choice with whatever they typed in the
/// per-photo prompt field, so the caller can forward the prompt to Gemini
/// as `user_message`.
class _AddAnotherResult {
  final bool addAnother;
  final String prompt;
  const _AddAnotherResult({required this.addAnother, required this.prompt});
}

/// Glass-styled row used inside the Scan Menu GlassSheet.
/// A compact tappable chip used by the "how many servings?" prompt (A2 / C4).
class _ServingChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _ServingChip({
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.18 : 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassMenuOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _GlassMenuOption({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// #15 — one-tap "re-scan a saved menu" entry point.
// ─────────────────────────────────────────────────────────────────────────

/// Library-level handoff slot for the saved-menu id being re-scanned.
///
/// `showLogMealSheet(autoOpenMenuScan: true)` triggers `_scanMenu()` from
/// `initState` with NO arguments, so there is no constructor channel to pass
/// the saved-menu id through. We stash it here just before opening the sheet;
/// `_scanMenu` consumes and clears it on first read. Single-shot by design —
/// only ever one re-scan in flight (the Saved Menu sheet is modal).
String? _pendingMenuRescanId;

/// #15 — launches the standard menu-scan flow (photo capture + SSE pipeline)
/// in re-scan-in-place mode for an already-saved menu. When the scan finishes
/// successfully, the fresh sections/food_items/photo urls are PATCHed onto the
/// saved `menu_analyses` row identified by [savedMenuId] (no duplicate row),
/// and the refreshed Menu Analysis sheet is reopened.
///
/// A cancelled or failed scan never PATCHes — the saved menu is left intact.
///
/// Reuses `showLogMealSheet(autoOpenMenuScan: true)` so the entire capture
/// pipeline (camera/gallery picker, multi-page, streaming progress) is shared
/// with a normal menu scan.
Future<void> showMenuRescanSheet(
  BuildContext context,
  WidgetRef ref, {
  required String savedMenuId,
}) async {
  // Stash the target id for `_scanMenu` to pick up. Set immediately before
  // showing the sheet so there's no window for a stale value to leak.
  _pendingMenuRescanId = savedMenuId;
  try {
    await showLogMealSheet(
      context,
      ref,
      autoOpenMenuScan: true,
    );
  } finally {
    // Defensive cleanup — if the sheet was dismissed before `_scanMenu` ever
    // ran (e.g. userId resolution failed in showLogMealSheet), clear the slot
    // so a later unrelated menu scan isn't wrongly treated as a re-scan.
    _pendingMenuRescanId = null;
  }
}
