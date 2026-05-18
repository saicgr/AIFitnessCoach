part of 'log_meal_sheet.dart';

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
          const SnackBar(content: Text('Speech recognition not available')),
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
        final cachedLogs = ref.read(nutritionProvider).recentLogs;
        service.search(query, widget.userId, cachedLogs: cachedLogs);
      }
    }
  }


  void _triggerImmediateSearch() {
    final query = _descriptionController.text.trim();
    if (query.length >= 3) {
      final service = ref.read(search.foodSearchServiceProvider);
      final cachedLogs = ref.read(nutritionProvider).recentLogs;
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
      _progressMessage = 'Starting analysis...';
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

        if (progress.isCompleted && progress.foodLog != null) {
          // The `done` event renders the macro card immediately (~2-3s). A
          // late `coach_tips` event (progress.hasCoachTips) may follow a few
          // seconds later carrying a foodLog with the coach commentary merged
          // in. We do NOT break on `done` — keep listening so the tip swaps
          // in when it arrives. The shimmer placeholder shows meanwhile.
          final finalResponse = progress.foodLog!;
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
          _error = 'Analysis failed. Please try again.';
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
            title: 'Log This Meal',
            description: 'Tap here to save your meal to your daily log. Analyzing alone doesn\'t log it!',
            position: TooltipPosition.above,
          ),
        ],
      );
    });
  }


  /// Always returns null so the backend stamps `logged_at` at server-now.
  /// The Nutrition tab auto-snaps to today after a successful log (see
  /// `_refreshAfterLog` in `nutrition_screen.dart`), so the meal lands where
  /// it actually exists in the DB rather than where the user happened to be
  /// browsing when they tapped Log Meal.
  String? _buildLoggedAtForSelectedDate() => null;

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

    // Start the save — capture the food_log_id for post-meal review.
    // Wrapped in an unawaited async IIFE (instead of `.then().catchError(...)`)
    // because catchError that returns void breaks the chained Future's type
    // contract — Dart 3 surfaces this as `'Null' is not a subtype of
    // 'LogFoodResponse'` when the chain rethrows. The IIFE pattern makes the
    // result type unambiguous (`Future<void>`) and keeps the same fire-and-
    // forget behaviour: errors are debugPrinted, not surfaced to the UI.
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
        );
        savedLogId = savedResponse.foodLogId;
      } catch (e) {
        debugPrint('❌ [LogMeal] Background save failed: $e');
      }
    }();
    unawaited(saveFuture);

    _logAnalyzedFood(response, saveFuture, () => savedLogId);
  }


  Future<void> _handleSaveAsFavorite() async {
    if (_isSaving || _analyzedResponse == null) return;

    setState(() => _isSaving = true);

    try {
      final repository = ref.read(nutritionRepositoryProvider);
      final description = _descriptionController.text.trim();

      final request = SaveFoodRequest.fromLogResponse(
        _analyzedResponse!,
        description.length > 50 ? '${description.substring(0, 50)}...' : description,
        description: description,
        sourceType: _sourceType,
      );

      await repository.saveFood(userId: widget.userId, request: request);

      if (mounted) {
        setState(() { _isSaved = true; _isSaving = false; });
        final bottomPadding = MediaQuery.of(context).padding.bottom;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [Icon(Icons.star, color: Colors.white, size: 20), SizedBox(width: 8), Text('Saved to favorites!')]),
            backgroundColor: AppColors.textMuted,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: EdgeInsets.only(left: 16, right: 16, bottom: bottomPadding + 100),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ [SaveFood] Error: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red),
        );
      }
    }
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
                        '$count $noun${count == 1 ? '' : 's'} captured',
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
                            'Anything else in the photos? (e.g. flax seeds, whey protein)',
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
                      label: 'Add another $noun',
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
                      label: 'Done — Analyze $count $noun${count == 1 ? '' : 's'}',
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
                            'Scan Food',
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
                    label: 'Take Food Photo',
                    subtitle: 'Up to 5 shots — add another between photos',
                    color: green,
                    isDark: isDark,
                    onTap: () => Navigator.pop(ctx, ImageSource.camera),
                  ),
                  const SizedBox(height: 10),
                  _GlassMenuOption(
                    icon: Icons.collections_outlined,
                    label: 'Choose Food Photos',
                    subtitle: 'Pick up to 5 from your library',
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
  Future<void> _scanMenu() async {
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
                            'Scan Menu',
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
                    label: 'Take Menu Photo',
                    color: amber,
                    isDark: isDark,
                    onTap: () => Navigator.pop(ctx, ImageSource.camera),
                  ),
                  const SizedBox(height: 10),
                  _GlassMenuOption(
                    icon: Icons.collections_outlined,
                    label: 'Choose Menu Photos',
                    subtitle: 'Up to 5 pages of the same menu',
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
                            'Scan & Import',
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
                    label: 'Scan nutrition label',
                    subtitle: 'Read macros off a packaged food label',
                    color: cyan,
                    isDark: isDark,
                    onTap: () => Navigator.pop(ctx, 'label'),
                  ),
                  const SizedBox(height: 10),
                  _GlassMenuOption(
                    icon: Icons.screenshot_outlined,
                    label: 'Scan app screenshot',
                    subtitle: 'Import a log from MyFitnessPal, Cronometer…',
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
                    label: 'Take a photo',
                    color: color,
                    isDark: isDark,
                    onTap: () => Navigator.pop(ctx, ImageSource.camera),
                  ),
                  const SizedBox(height: 10),
                  _GlassMenuOption(
                    icon: Icons.collections_outlined,
                    label: 'Choose from library',
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
                              hintText: 'Custom (e.g. 1.25)',
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
                          child: const Text('Use'),
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
        );
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
            content: const Text(
                'That looks like a recipe — paste it into the recipe importer.'),
            action: SnackBarAction(
              label: 'OK',
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

      Future<void> openSheetWithInitialItems(
        List<Map<String, dynamic>> initial,
        String type,
        MenuAnalysisStreamingController controller,
      ) async {
        setState(() {
          _isLoading = false;
          _showLoadingIndicator = false;
        });
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => MenuAnalysisSheet(
            foodItems: initial,
            analysisType: type,
            isDark: widget.isDark,
            streamingController: controller,
            userId: widget.userId,
            mealType: _selectedMealType.value,
            onLogItems: (selected) async {
              try {
                await repository.logSelectedMealItems(
                  userId: widget.userId,
                  mealType: _selectedMealType.value,
                  analysisType: type,
                  items: selected,
                  inputType: type == 'menu' ? 'menu_scan' : 'buffet_scan',
                );
                if (mounted) {
                  ref.read(nutritionProvider.notifier).loadTodaySummary(widget.userId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Logged ${selected.length} item${selected.length == 1 ? '' : 's'}')),
                  );
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to log: $e')),
                  );
                }
              }
            },
          ),
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
          });
          return; // _buildNutritionPreview now renders with review + "Log This Meal"
        }

        // Legacy / fallback path: backend auto-logged. Refresh and close.
        ref.read(nutritionProvider.notifier).loadTodaySummary(widget.userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logged ${files.length} photo${files.length == 1 ? '' : 's'} '
                  '(${payload['total_calories'] ?? 0} kcal)'),
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
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => MenuAnalysisSheet(
          foodItems: foodItems,
          analysisType: analysisType,
          isDark: widget.isDark,
          userId: widget.userId,
          mealType: _selectedMealType.value,
          restaurantName: restaurantName,
          onLogItems: (selected) async {
            try {
              await repository.logSelectedMealItems(
                userId: widget.userId,
                mealType: _selectedMealType.value,
                analysisType: analysisType,
                items: selected,
                inputType: analysisType == 'menu' ? 'menu_scan' : 'buffet_scan',
                imageUrl: imageUrls.isNotEmpty ? imageUrls.first : null,
                imageStorageKey: storageKeys.isNotEmpty ? storageKeys.first : null,
              );
              if (mounted) {
                ref.read(nutritionProvider.notifier).loadTodaySummary(widget.userId);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Logged ${selected.length} item${selected.length == 1 ? '' : 's'}')),
                );
                Navigator.of(context).pop(); // close MenuAnalysisSheet
                Navigator.of(context).pop(); // close LogMealSheet
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to log: $e')),
                );
              }
            }
          },
        ),
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



  /// Log an already analyzed food response
  void _logAnalyzedFood(LogFoodResponse response, [Future<void>? saveFuture, String? Function()? getSavedLogId]) async {
    debugPrint('✅ [LogMeal] _logAnalyzedFood called | calories=${response.totalCalories} | protein=${response.proteinG}g | foodItems=${response.foodItems.length}');

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
    final nutritionNotifier = ref.read(nutritionProvider.notifier);
    final userId = widget.userId;
    final isDark = widget.isDark;
    final foodNames = response.foodItems.map((f) => f.name).toList();
    final totalCalories = response.totalCalories;
    // foodLogId from analysis response is null (not saved yet)
    // getSavedLogId() will have the real ID after save completes

    // Get the navigator's overlay context which survives the pop
    final overlay = Navigator.of(context).overlay;

    // Optimistic update: splice the new log into local state immediately so
    // the Nutrition tab shows the meal before the background refresh returns.
    nutritionNotifier.spliceLog(response, _selectedMealType.value, userId);

    // Close sheet immediately for snappy UX
    Navigator.pop(context);

    // Fire-and-forget: refresh nutrition UI after save completes
    if (saveFuture != null) {
      unawaited(saveFuture.then((_) {
        nutritionNotifier.loadTodaySummary(userId, forceRefresh: true);
        // Schedule the 45-min reminder after save completes (needs foodLogId)
        final logId = getSavedLogId?.call();
        if (logId != null && logId.isNotEmpty) {
          _schedulePostMealReminder(
            userId: userId,
            foodLogId: logId,
            mealSummary: foodNames.isNotEmpty ? foodNames.first : null,
          );
        }
      }));
    } else {
      nutritionNotifier.loadTodaySummary(userId, forceRefresh: true);
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
            ref.read(nutritionProvider.notifier).loadTodaySummary(widget.userId);
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
      setState(() {
        _isLoading = false;
        _hasScanned = false;
        _error = e.toString();
      });
    }
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
            SnackBar(content: Text('Couldn\'t add food: ${progress.message}')),
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
          const SnackBar(
            content: Text("Couldn't recognize any food in that description."),
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
          SnackBar(content: Text('Couldn\'t add food: $e')),
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
        const SnackBar(content: Text('Add a bit more detail to refine.')),
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
            SnackBar(content: Text("Couldn't refine: ${progress.message}")),
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
          const SnackBar(
            content: Text("Couldn't apply that correction — meal unchanged."),
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
          content: const Text('Meal refined'),
          action: SnackBarAction(
            label: 'Undo',
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
          SnackBar(content: Text("Couldn't refine: $e")),
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
