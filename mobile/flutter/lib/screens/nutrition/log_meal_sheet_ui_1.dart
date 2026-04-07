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
        setState(() {
          _isAnalyzing = false;
          _showLoadingIndicator = false;
          _analyzedResponse = response;
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

    final currentItems = List<Map<String, dynamic>>.from(_analyzedResponse!.foodItems);
    if (index < 0 || index >= currentItems.length) return;

    currentItems[index] = updatedItem.toJson();

    int totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    double totalFiber = 0;

    for (final item in currentItems) {
      totalCalories += (item['calories'] as num?)?.toInt() ?? 0;
      totalProtein += (item['protein_g'] as num?)?.toDouble() ?? 0;
      totalCarbs += (item['carbs_g'] as num?)?.toDouble() ?? 0;
      totalFat += (item['fat_g'] as num?)?.toDouble() ?? 0;
      totalFiber += (item['fiber_g'] as num?)?.toDouble() ?? 0;
    }

    setState(() {
      _analyzedResponse = LogFoodResponse(
        success: _analyzedResponse!.success,
        foodLogId: _analyzedResponse!.foodLogId,
        foodItems: currentItems,
        totalCalories: totalCalories,
        proteinG: totalProtein,
        carbsG: totalCarbs,
        fatG: totalFat,
        fiberG: totalFiber,
        overallMealScore: _analyzedResponse!.overallMealScore,
        healthScore: _analyzedResponse!.healthScore,
        goalAlignmentPercentage: _analyzedResponse!.goalAlignmentPercentage,
        aiSuggestion: _analyzedResponse!.aiSuggestion,
        encouragements: _analyzedResponse!.encouragements,
        warnings: _analyzedResponse!.warnings,
        recommendedSwap: _analyzedResponse!.recommendedSwap,
        confidenceScore: _analyzedResponse!.confidenceScore,
        confidenceLevel: _analyzedResponse!.confidenceLevel,
        sourceType: _analyzedResponse!.sourceType,
        correctedQuery: _analyzedResponse!.correctedQuery,
        sodiumMg: _analyzedResponse!.sodiumMg,
        sugarG: _analyzedResponse!.sugarG,
        saturatedFatG: _analyzedResponse!.saturatedFatG,
        cholesterolMg: _analyzedResponse!.cholesterolMg,
        potassiumMg: _analyzedResponse!.potassiumMg,
        vitaminAIu: _analyzedResponse!.vitaminAIu,
        vitaminCMg: _analyzedResponse!.vitaminCMg,
        vitaminDIu: _analyzedResponse!.vitaminDIu,
        calciumMg: _analyzedResponse!.calciumMg,
        ironMg: _analyzedResponse!.ironMg,
        imageUrl: _analyzedResponse!.imageUrl,
        imageStorageKey: _analyzedResponse!.imageStorageKey,
        plateDescription: _analyzedResponse!.plateDescription,
      );
    });
  }


  void _handleFoodItemRemoved(int index) {
    if (_analyzedResponse == null) return;

    final currentItems = List<Map<String, dynamic>>.from(_analyzedResponse!.foodItems);
    if (index < 0 || index >= currentItems.length) return;
    currentItems.removeAt(index);

    if (currentItems.isEmpty) {
      // All items removed — clear the response to go back to input
      setState(() => _analyzedResponse = null);
      return;
    }

    int totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    double totalFiber = 0;

    for (final item in currentItems) {
      totalCalories += (item['calories'] as num?)?.toInt() ?? 0;
      totalProtein += (item['protein_g'] as num?)?.toDouble() ?? 0;
      totalCarbs += (item['carbs_g'] as num?)?.toDouble() ?? 0;
      totalFat += (item['fat_g'] as num?)?.toDouble() ?? 0;
      totalFiber += (item['fiber_g'] as num?)?.toDouble() ?? 0;
    }

    setState(() {
      _analyzedResponse = LogFoodResponse(
        success: _analyzedResponse!.success,
        foodLogId: _analyzedResponse!.foodLogId,
        foodItems: currentItems,
        totalCalories: totalCalories,
        proteinG: totalProtein,
        carbsG: totalCarbs,
        fatG: totalFat,
        fiberG: totalFiber,
        overallMealScore: _analyzedResponse!.overallMealScore,
        healthScore: _analyzedResponse!.healthScore,
        goalAlignmentPercentage: _analyzedResponse!.goalAlignmentPercentage,
        aiSuggestion: _analyzedResponse!.aiSuggestion,
        encouragements: _analyzedResponse!.encouragements,
        warnings: _analyzedResponse!.warnings,
        recommendedSwap: _analyzedResponse!.recommendedSwap,
        confidenceScore: _analyzedResponse!.confidenceScore,
        confidenceLevel: _analyzedResponse!.confidenceLevel,
        sourceType: _analyzedResponse!.sourceType,
        correctedQuery: _analyzedResponse!.correctedQuery,
        sodiumMg: _analyzedResponse!.sodiumMg,
        sugarG: _analyzedResponse!.sugarG,
        saturatedFatG: _analyzedResponse!.saturatedFatG,
        cholesterolMg: _analyzedResponse!.cholesterolMg,
        potassiumMg: _analyzedResponse!.potassiumMg,
        vitaminAIu: _analyzedResponse!.vitaminAIu,
        vitaminCMg: _analyzedResponse!.vitaminCMg,
        vitaminDIu: _analyzedResponse!.vitaminDIu,
        calciumMg: _analyzedResponse!.calciumMg,
        ironMg: _analyzedResponse!.ironMg,
        imageUrl: _analyzedResponse!.imageUrl,
        imageStorageKey: _analyzedResponse!.imageStorageKey,
        plateDescription: _analyzedResponse!.plateDescription,
      );
    });
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

    // Start the save — capture the food_log_id for post-meal review
    String? savedLogId;
    final saveFuture = repository.logFoodDirect(
      userId: userId,
      mealType: mealType,
      analyzedFood: response,
      sourceType: sourceType,
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
        setState(() {
          _analyzedResponse = response;
          _sourceType = 'image';
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
          notes: 'Ended by meal log: ${response.foodItems.map((f) => f['name'] ?? 'Food').join(", ")}',
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
    final foodNames = response.foodItems.map((f) => (f['name'] as String?) ?? 'Food').toList();
    final totalCalories = response.totalCalories;
    // foodLogId from analysis response is null (not saved yet)
    // getSavedLogId() will have the real ID after save completes

    // Get the navigator's overlay context which survives the pop
    final overlay = Navigator.of(context).overlay;

    // Close sheet immediately for snappy UX
    Navigator.pop(context);

    // Wait for backend save to complete, then refresh to show updated data
    if (saveFuture != null) {
      await saveFuture;
    }
    nutritionNotifier.loadTodaySummary(userId, forceRefresh: true);

    // Show post-log review sheet after a brief delay
    await Future.delayed(const Duration(milliseconds: 400));
    final reviewContext = overlay?.context;
    if (reviewContext != null && reviewContext.mounted) {
      showPostMealReviewSheet(
        reviewContext,
        foodNames: foodNames,
        totalCalories: totalCalories,
        isDark: isDark,
        userId: userId,
        foodLogId: getSavedLogId?.call(),
      );
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
            ? response!.foodItems.map((f) => f['name'] ?? 'Food').join(', ')
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
