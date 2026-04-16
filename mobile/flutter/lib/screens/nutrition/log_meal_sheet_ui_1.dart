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
      setState(() => _isListening = true);
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
          response = progress.foodLog;
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

      debugPrint('🍎 [LogMeal] Streaming complete, response: $response');
      _loadingDelayTimer?.cancel();
      if (mounted && response != null) {
        final description = _descriptionController.text.trim();
        ref.read(posthogServiceProvider).capture(
          eventName: 'food_text_analyzed',
          properties: <String, Object>{
            'description_length': description.length,
            'meal_type': _selectedMealType.name,
          },
        );
        final finalResponse = response;
        setState(() {
          _isAnalyzing = false;
          _showLoadingIndicator = false;
          _analyzedResponse = finalResponse;
          // Snapshot the AI's per-item nutrition so inline edits diff against
          // the original values (shallow copy — FoodItemRanking is immutable).
          _originalFoodItems = List<FoodItemRanking>.from(finalResponse.foodItems);
          _pendingItemEdits.clear();
        });
        // Show "Log This Meal" tooltip tour on first analysis
        _triggerLogMealTour();
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
      imageUrl: base.imageUrl,
      imageStorageKey: base.imageStorageKey,
      plateDescription: base.plateDescription,
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

    // Start the save — capture the food_log_id for post-meal review
    String? savedLogId;
    final saveFuture = repository.logFoodDirect(
      userId: userId,
      mealType: mealType,
      analyzedFood: response,
      sourceType: sourceType,
      itemEdits: pendingEdits,
    ).then((savedResponse) {
      savedLogId = savedResponse.foodLogId;
      return savedResponse;
    }).catchError((e) {
      debugPrint('❌ [LogMeal] Background save failed: $e');
    });

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
              return ListTile(
                leading: Text(type.emoji, style: const TextStyle(fontSize: 24)),
                title: Text(
                  type.label,
                  style: TextStyle(
                    color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: isSelected ? Icon(Icons.check, color: isDark ? AppColors.teal : AppColorsLight.teal) : null,
                onTap: () {
                  setState(() => _selectedMealType = type);
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
      final picker = ImagePicker();
      final image = await picker.pickImage(source: source, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
      if (image == null) return;

      ref.read(posthogServiceProvider).capture(
        eventName: 'food_photo_taken',
        properties: <String, Object>{'source': source == ImageSource.camera ? 'camera' : 'gallery'},
      );

      setState(() {
        _isLoading = true;
        _showLoadingIndicator = false;
        _error = null;
        _sourceType = 'image';
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
        imageFile: File(image.path),
      )) {
        if (!mounted) return;

        if (progress.hasError) {
          _loadingDelayTimer?.cancel();
          setState(() { _isLoading = false; _showLoadingIndicator = false; _error = progress.message; });
          return;
        }

        if (progress.isCompleted && progress.foodLog != null) {
          response = progress.foodLog;
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
      if (mounted && response != null) {
        setState(() { _isLoading = false; _showLoadingIndicator = false; });

        if (response.foodItems.isEmpty && response.totalCalories == 0) {
          setState(() { _error = 'Could not identify food in the image. Please try a clearer photo.'; });
          return;
        }

        // Use the rich preview (same as text search) instead of the bare dialog
        final finalResponse = response;
        setState(() {
          _analyzedResponse = finalResponse;
          _sourceType = 'image';
          _originalFoodItems = List<FoodItemRanking>.from(finalResponse.foodItems);
          _pendingItemEdits.clear();
        });
        // _buildNutritionPreview renders with food items, AI tips, editing.
        // "Log This Meal" button calls _handleLog() which saves.
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
        final confirmed = await _showProductConfirmation(product);
        debugPrint('🔍 [LogMeal] Product confirmation | confirmed=$confirmed');
        if (confirmed == true) {
          debugPrint('🔍 [LogMeal] Logging barcode food | mealType=${_selectedMealType.value}');
          final response = await repository.logFoodFromBarcode(
            userId: widget.userId,
            barcode: barcode,
            mealType: _selectedMealType.value,
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

}
