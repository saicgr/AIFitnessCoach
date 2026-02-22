import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../core/constants/app_colors.dart';
import '../../data/models/nutrition.dart';
import '../../data/models/fasting.dart';
import '../../data/providers/fasting_provider.dart';
import '../../data/providers/guest_mode_provider.dart';
import '../../data/providers/guest_usage_limits_provider.dart';
import '../../data/repositories/nutrition_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/api_client.dart';
import '../../data/providers/xp_provider.dart';
import '../../widgets/glass_sheet.dart';
import '../../widgets/guest_upgrade_sheet.dart';
import '../../widgets/main_shell.dart';
import '../../data/providers/nutrition_preferences_provider.dart';
import '../../data/services/food_search_service.dart' as search;
import 'widgets/food_browser_panel.dart';
import 'widgets/inflammation_analysis_widget.dart';
import 'widgets/portion_amount_input.dart';

/// Shows the log meal bottom sheet from anywhere in the app
/// [initialMealType] - Optional meal type to pre-select (e.g., 'breakfast', 'lunch', 'dinner', 'snack')
Future<void> showLogMealSheet(BuildContext context, WidgetRef ref, {String? initialMealType}) async {
  debugPrint('showLogMealSheet: Starting with initialMealType=$initialMealType');
  final isDark = Theme.of(context).brightness == Brightness.dark;

  // Try authStateProvider first, fallback to apiClientProvider for consistency
  final authState = ref.read(authStateProvider);
  String? userId = authState.user?.id;

  // Fallback to apiClient if authState doesn't have user ID
  if (userId == null || userId.isEmpty) {
    debugPrint('showLogMealSheet: authState userId is null, trying apiClient...');
    userId = await ref.read(apiClientProvider).getUserId();
  }

  debugPrint('showLogMealSheet: userId=$userId, context.mounted=${context.mounted}');

  // Check for null, empty string, or unmounted context
  if (userId == null || userId.isEmpty || !context.mounted) {
    debugPrint('showLogMealSheet: Aborting - userId is null/empty or context not mounted');
    return;
  }

  // Convert string to MealType if provided
  MealType? mealType;
  if (initialMealType != null) {
    mealType = MealType.values.firstWhere(
      (t) => t.value == initialMealType,
      orElse: () => MealType.lunch,
    );
  }

  // Hide nav bar while sheet is open
  ref.read(floatingNavBarVisibleProvider.notifier).state = false;

  debugPrint('showLogMealSheet: About to show modal bottom sheet');
  await showGlassSheet(
    context: context,
    builder: (context) => LogMealSheet(
      userId: userId!,
      isDark: isDark,
      initialMealType: mealType,
    ),
  );

  debugPrint('showLogMealSheet: Bottom sheet closed');
  // Show nav bar when sheet is closed
  ref.read(floatingNavBarVisibleProvider.notifier).state = true;
}

/// Bottom sheet for logging meals with multiple input methods
class LogMealSheet extends ConsumerStatefulWidget {
  final String userId;
  final bool isDark;
  final MealType? initialMealType;

  const LogMealSheet({
    super.key,
    required this.userId,
    required this.isDark,
    this.initialMealType,
  });

  @override
  ConsumerState<LogMealSheet> createState() => _LogMealSheetState();
}

class _LogMealSheetState extends ConsumerState<LogMealSheet> {
  MealType _selectedMealType = MealType.lunch;
  bool _isLoading = false;
  String? _error;

  // Streaming progress state
  int _currentStep = 0;
  int _totalSteps = 3;
  String _progressMessage = '';
  String? _progressDetail;

  // Delayed loading indicator: avoids flash for fast (cached) responses
  bool _showLoadingIndicator = false;
  Timer? _loadingDelayTimer;

  final _descriptionController = TextEditingController();
  bool _hasScanned = false;

  // Time picker state
  TimeOfDay _selectedTime = TimeOfDay.now();

  // Merged from _DescribeTab
  LogFoodResponse? _analyzedResponse;
  bool _isAnalyzing = false;
  bool _isSaved = false;
  bool _isSaving = false;
  String _sourceType = 'text';
  int? _analysisElapsedMs;

  // Voice input state
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;

  // Mood tracking state
  FoodMood? _moodBefore;
  FoodMood? _moodAfter;
  int _energyLevel = 3;

  // Food browser state
  FoodBrowserFilter _browserFilter = FoodBrowserFilter.recent;
  String _searchQuery = '';

  // Scroll/focus
  final ScrollController _scrollController = ScrollController();
  final FocusNode _textFieldFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _selectedMealType = widget.initialMealType ?? _getDefaultMealType();
    _selectedTime = TimeOfDay.now();
    _textFieldFocusNode.addListener(_onFocusChange);
    _descriptionController.addListener(_onDescriptionChanged);

    debugPrint('🍽️ [LogMeal] Sheet initialized | userId=${widget.userId} | initialMealType=${widget.initialMealType?.value ?? "auto"} | selectedMealType=${_selectedMealType.value}');
  }

  MealType _getDefaultMealType() {
    final hour = DateTime.now().hour;
    if (hour < 10) return MealType.breakfast;
    if (hour < 14) return MealType.lunch;
    if (hour < 17) return MealType.snack;
    return MealType.dinner;
  }

  @override
  void dispose() {
    debugPrint('🍽️ [LogMeal] Sheet disposed | userId=${widget.userId}');
    _loadingDelayTimer?.cancel();
    _descriptionController.removeListener(_onDescriptionChanged);
    _descriptionController.dispose();
    _textFieldFocusNode.removeListener(_onFocusChange);
    _textFieldFocusNode.dispose();
    _scrollController.dispose();
    _speech.stop();
    super.dispose();
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
        final service = ref.read(search.foodSearchServiceProvider);
        final cachedLogs = ref.read(nutritionProvider).recentLogs;
        service.search(query, widget.userId, cachedLogs: cachedLogs);
      }
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
        setState(() {
          _isAnalyzing = false;
          _showLoadingIndicator = false;
          _analyzedResponse = response;
        });
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

  void _handleEdit() {
    setState(() {
      _analyzedResponse = null;
      _analysisElapsedMs = null;
    });
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
      );
    });
  }

  Future<void> _handleLog() async {
    if (_analyzedResponse == null) return;

    final response = _analyzedResponse!;
    final repository = ref.read(nutritionRepositoryProvider);
    final mealType = _selectedMealType.value;
    final sourceType = _sourceType;
    final userId = widget.userId;

    // Optimistic: mark XP and close sheet immediately
    ref.read(xpProvider.notifier).markMealLogged();

    // Start the save (don't await here - let _logAnalyzedFood close the sheet first)
    final saveFuture = repository.logFoodDirect(
      userId: userId,
      mealType: mealType,
      analyzedFood: response,
      sourceType: sourceType,
    ).catchError((e) {
      debugPrint('❌ [LogMeal] Background save failed: $e');
    });

    _logAnalyzedFood(response, saveFuture);
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
      builder: (context) => _BarcodeScannerOverlay(
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

      setState(() {
        _isLoading = true;
        _showLoadingIndicator = false;
        _error = null;
        _sourceType = 'image';
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

        final detectedFoodNames = response.foodItems.isNotEmpty
            ? response.foodItems.map((f) => f['name']?.toString() ?? 'Food').join(', ')
            : 'Detected food';
        final result = await _showRainbowNutritionConfirmation(response, detectedFoodNames);

        if (result != null && result.confirmed && mounted) {
          final adjustedResponse = result.multiplier != 1.0
              ? response.copyWithMultiplier(result.multiplier)
              : response;

          setState(() { _isLoading = true; _progressMessage = 'Saving your meal...'; });

          try {
            await repository.logFoodDirect(
              userId: widget.userId,
              mealType: _selectedMealType.value,
              analyzedFood: adjustedResponse,
              sourceType: 'image',
            );

            if (mounted) {
              ref.read(xpProvider.notifier).markMealLogged();
              Navigator.pop(context);
              _showSuccessSnackbar(adjustedResponse.totalCalories);
              ref.read(nutritionProvider.notifier).loadTodaySummary(widget.userId);
            }
          } catch (saveError) {
            debugPrint('❌ [LogMeal] Save failed | error=$saveError');
            if (mounted) {
              setState(() {
                _isLoading = false;
                _error = 'Failed to save meal: $saveError';
              });
            }
          }
        } else {
          debugPrint('📋 [LogMeal] User cancelled or dismissed confirmation dialog');
        }
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
  void _logAnalyzedFood(LogFoodResponse response, [Future<void>? saveFuture]) async {
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

    // Close sheet immediately for snappy UX
    Navigator.pop(context);
    _showSuccessSnackbar(response.totalCalories);

    // Wait for backend save to complete, then refresh to show updated data
    if (saveFuture != null) {
      await saveFuture;
    }
    nutritionNotifier.loadTodaySummary(userId, forceRefresh: true);
  }

  /// Show dialog to ask user if they want to end their fast
  Future<bool?> _showEndFastDialog(FastingRecord activeFast) {
    final isDark = widget.isDark;
    final nearBlack = isDark ? AppColors.nearBlack : AppColorsLight.nearWhite;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;

    final elapsedHours = activeFast.elapsedMinutes ~/ 60;
    final elapsedMins = activeFast.elapsedMinutes % 60;

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: nearBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.restaurant, color: purple, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'End Your Fast?',
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You\'ve been fasting for ${elapsedHours}h ${elapsedMins}m.',
              style: TextStyle(color: textPrimary, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              'Logging this meal will end your fast. Continue?',
              style: TextStyle(color: textMuted, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null), // Cancel
            child: Text('Cancel', style: TextStyle(color: textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Log without ending fast
            child: Text('Log Only', style: TextStyle(color: purple)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), // End fast and log
            style: ElevatedButton.styleFrom(
              backgroundColor: purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('End Fast & Log'),
          ),
        ],
      ),
    );
  }

  /// Returns (confirmed, multiplier) - multiplier defaults to 1.0 if not adjusted
  Future<({bool confirmed, double multiplier})?> _showRainbowNutritionConfirmation(LogFoodResponse response, String description) {
    final isDark = widget.isDark;
    final nearBlack = isDark ? AppColors.nearBlack : AppColorsLight.nearWhite;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    // Rainbow colors for nutrition values
    const caloriesColor = AppColors.textPrimary;  // Red/Coral
    const proteinColor = AppColors.textSecondary;   // Yellow/Gold
    const carbsColor = AppColors.textMuted;     // Green
    const fatColor = AppColors.textSecondary;       // Blue
    const fiberColor = AppColors.textMuted;     // Purple

    // Portion multiplier state
    double portionMultiplier = 1.0;

    return showDialog<({bool confirmed, double multiplier})>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Extract food names from AI response
          final foodNames = response.foodItems.isNotEmpty
              ? response.foodItems.map((f) => f['name'] ?? 'Food').join(', ')
              : description;

          // Calculate adjusted values based on portion multiplier
          final adjustedCalories = (response.totalCalories * portionMultiplier).round();
          final adjustedProtein = response.proteinG * portionMultiplier;
          final adjustedCarbs = response.carbsG * portionMultiplier;
          final adjustedFat = response.fatG * portionMultiplier;
          final adjustedFiber = (response.fiberG ?? 0) * portionMultiplier;

          return AlertDialog(
            backgroundColor: nearBlack,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.textSecondary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'AI Estimated Nutrition',
                    style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Food name and description
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: elevated,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.restaurant, size: 20, color: textMuted),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                foodNames,
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (description.isNotEmpty && description.toLowerCase() != foodNames.toLowerCase()) ...[
                                const SizedBox(height: 4),
                                Text(
                                  description,
                                  style: TextStyle(
                                    color: textMuted,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Portion adjustment section
                  PortionAmountInput(
                    initialMultiplier: portionMultiplier,
                    baseCalories: response.totalCalories,
                    baseProtein: response.proteinG,
                    baseCarbs: response.carbsG,
                    baseFat: response.fatG,
                    isDark: isDark,
                    onMultiplierChanged: (newMultiplier) {
                      setDialogState(() {
                        portionMultiplier = newMultiplier;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // Rainbow nutrition grid (shows adjusted values)
                  _RainbowNutritionCard(
                    icon: Icons.local_fire_department,
                    label: 'Calories',
                    value: '$adjustedCalories',
                    unit: 'kcal',
                    color: caloriesColor,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _RainbowNutritionCard(
                          icon: Icons.fitness_center,
                          label: 'Protein',
                          value: adjustedProtein.toStringAsFixed(1),
                          unit: 'g',
                          color: proteinColor,
                          isDark: isDark,
                          compact: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _RainbowNutritionCard(
                          icon: Icons.grain,
                          label: 'Carbs',
                          value: adjustedCarbs.toStringAsFixed(1),
                          unit: 'g',
                          color: carbsColor,
                          isDark: isDark,
                          compact: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _RainbowNutritionCard(
                          icon: Icons.opacity,
                          label: 'Fat',
                          value: adjustedFat.toStringAsFixed(1),
                          unit: 'g',
                          color: fatColor,
                          isDark: isDark,
                          compact: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _RainbowNutritionCard(
                          icon: Icons.eco,
                          label: 'Fiber',
                          value: adjustedFiber.toStringAsFixed(1),
                          unit: 'g',
                          color: fiberColor,
                          isDark: isDark,
                          compact: true,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Confidence indicator
                  if (response.confidenceLevel != null)
                    _ConfidenceIndicator(
                      confidenceLevel: response.confidenceLevel!,
                      confidenceScore: response.confidenceScore,
                      sourceType: response.sourceType,
                      isDark: isDark,
                    ),

                  if (response.confidenceLevel == null)
                    Text(
                      'These values are AI estimates based on your description.',
                      style: TextStyle(fontSize: 12, color: textMuted, fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: Text('Cancel', style: TextStyle(color: textMuted)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, (confirmed: true, multiplier: portionMultiplier)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textMuted,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check, size: 18),
                    SizedBox(width: 8),
                    Text('Log This'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
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
            _showSuccessSnackbar(response.totalCalories);
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

  Future<bool?> _showProductConfirmation(BarcodeProduct product) {
    final isDark = widget.isDark;
    final nearBlack = isDark ? AppColors.nearBlack : AppColorsLight.nearWhite;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;
    final cardBg = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.04);

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: nearBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
        title: Text('Found Product', style: TextStyle(color: textPrimary)),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
            maxWidth: MediaQuery.of(context).size.width * 0.85,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product header with image
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.imageThumbUrl != null || product.imageUrl != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          product.imageThumbUrl ?? product.imageUrl!,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.image_not_supported_outlined,
                                color: textMuted, size: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.productName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          if (product.brand != null) ...[
                            const SizedBox(height: 2),
                            Text(product.brand!,
                                style: TextStyle(fontSize: 13, color: textMuted)),
                          ],
                          if (product.categories != null) ...[
                            const SizedBox(height: 2),
                            Text(product.categories!,
                                style: TextStyle(fontSize: 11, color: textMuted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                // Nutri-Score and NOVA badges
                if (product.nutriscoreGrade != null || product.novaGroup != null) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (product.nutriscoreGrade != null)
                        _NutriscoreBadge(
                            grade: product.nutriscoreGrade!, isDark: isDark),
                      if (product.novaGroup != null)
                        _NovaBadge(group: product.novaGroup!, isDark: isDark),
                    ],
                  ),
                ],

                // Serving size info
                if (product.servingSizeG != null || product.servingSize != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Serving: ${product.servingSize ?? '${product.servingSizeG!.toInt()}g'}',
                    style: TextStyle(fontSize: 12, color: textMuted),
                  ),
                ],

                const SizedBox(height: 12),
                Divider(color: textMuted.withValues(alpha: 0.2)),
                const SizedBox(height: 8),

                // Nutrition per 100g
                Text('Nutrition per 100g',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textMuted)),
                const SizedBox(height: 6),
                _NutritionInfoRow(
                  label: 'Calories',
                  value: '${product.caloriesPer100g.toInt()} kcal',
                  isDark: isDark,
                ),
                _NutritionInfoRow(
                  label: 'Protein',
                  value: '${product.proteinPer100g.toStringAsFixed(1)}g',
                  isDark: isDark,
                ),
                _NutritionInfoRow(
                  label: 'Carbs',
                  value: '${product.carbsPer100g.toStringAsFixed(1)}g',
                  isDark: isDark,
                ),
                _NutritionInfoRow(
                  label: 'Fat',
                  value: '${product.fatPer100g.toStringAsFixed(1)}g',
                  isDark: isDark,
                ),
                if (product.fiberPer100g > 0)
                  _NutritionInfoRow(
                    label: 'Fiber',
                    value: '${product.fiberPer100g.toStringAsFixed(1)}g',
                    isDark: isDark,
                  ),
                if (product.sugarPer100g > 0)
                  _NutritionInfoRow(
                    label: 'Sugar',
                    value: '${product.sugarPer100g.toStringAsFixed(1)}g',
                    isDark: isDark,
                  ),

                // Allergens
                if (product.allergens != null &&
                    product.allergens!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Divider(color: textMuted.withValues(alpha: 0.2)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 16, color: Colors.orange),
                      const SizedBox(width: 6),
                      Text('Allergens',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.allergens!,
                    style: TextStyle(fontSize: 12, color: textMuted),
                  ),
                ],

                // Ingredients
                if (product.ingredientsText != null &&
                    product.ingredientsText!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Divider(color: textMuted.withValues(alpha: 0.2)),
                  const SizedBox(height: 8),
                  Text('Ingredients',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textMuted)),
                  const SizedBox(height: 4),
                  Text(
                    product.ingredientsText!,
                    style: TextStyle(fontSize: 11, color: textMuted, height: 1.4),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Inflammation Analysis
                  const SizedBox(height: 16),
                  InflammationAnalysisWidget(
                    userId: widget.userId,
                    barcode: product.barcode,
                    ingredientsText: product.ingredientsText!,
                    productName: product.productName,
                    isDark: isDark,
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: teal),
            child: const Text('Log This'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackbar(int calories) {
    // Get scaffold messenger before any async operations
    final messenger = ScaffoldMessenger.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isDark = widget.isDark;

    // Use Future.delayed to show snackbar after sheet animation completes
    // This ensures the nav bar is visible and snackbar appears above it
    Future.delayed(const Duration(milliseconds: 100), () {
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('Logged $calories kcal'),
            ],
          ),
          backgroundColor: isDark ? AppColors.success : AppColorsLight.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: bottomPadding + 100, // Clear the floating nav bar (42px) + padding (16px) + buffer
          ),
        ),
      );
    });
  }

  // ─── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardVisible = keyboardHeight > 0;

    final sheetHeight = keyboardVisible
        ? screenHeight - keyboardHeight - MediaQuery.of(context).padding.top - 20
        : screenHeight * 0.85;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(GlassSheetStyle.borderRadius)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: GlassSheetStyle.blurSigma, sigmaY: GlassSheetStyle.blurSigma),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            height: sheetHeight,
            decoration: BoxDecoration(
              color: GlassSheetStyle.backgroundColor(isDark),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(GlassSheetStyle.borderRadius)),
              border: Border(
                top: BorderSide(color: GlassSheetStyle.borderColor(isDark), width: 0.5),
              ),
            ),
            child: Column(
              children: [
                // Handle
                GlassSheetHandle(isDark: isDark),

                // Header: time pill + meal type pill + saved foods
                _buildHeader(isDark),

                // Error message
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.error : AppColorsLight.error).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isDark ? AppColors.error : AppColorsLight.error),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: isDark ? AppColors.error : AppColorsLight.error, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: TextStyle(color: isDark ? AppColors.error : AppColorsLight.error, fontSize: 12),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _error = null),
                            child: Icon(Icons.close, size: 16, color: isDark ? AppColors.error : AppColorsLight.error),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Body: loading OR preview OR input
                if ((_isLoading || _isAnalyzing) && _showLoadingIndicator)
                  Expanded(
                    child: _FoodAnalysisLoadingIndicator(
                      currentStep: _currentStep,
                      totalSteps: _totalSteps,
                      progressMessage: _progressMessage,
                      progressDetail: _progressDetail,
                      isDark: isDark,
                    ),
                  )
                else if (_analyzedResponse != null)
                  Expanded(child: _buildNutritionPreview(isDark))
                else
                  Expanded(child: _buildInputView(isDark)),

                // Bottom bar: only in input state
                if (!_isLoading && !_isAnalyzing && _analyzedResponse == null)
                  _buildBottomBar(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────

  Widget _buildHeader(bool isDark) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    final timeText = _selectedTime.format(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          // Time picker pill
          GestureDetector(
            onTap: _showTimePicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: glassSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.06)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule, size: 16, color: textMuted),
                  const SizedBox(width: 6),
                  Text(timeText, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary)),
                  const SizedBox(width: 4),
                  Icon(Icons.expand_more, size: 16, color: textMuted),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Meal type pill
          GestureDetector(
            onTap: _showMealTypePicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: glassSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.06)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_selectedMealType.emoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(_selectedMealType.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary)),
                  const SizedBox(width: 4),
                  Icon(Icons.expand_more, size: 16, color: textMuted),
                ],
              ),
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }

  // ─── Input View ───────────────────────────────────────────────

  Widget _buildInputView(bool isDark) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    const orange = Color(0xFFF97316);

    return Column(
      children: [
        // Text input (compact)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _descriptionController,
                focusNode: _textFieldFocusNode,
                maxLines: null,
                minLines: 2,
                style: TextStyle(color: textPrimary, fontSize: 18, height: 1.4),
                decoration: InputDecoration(
                  hintText: _isListening ? 'Listening...' : 'What did you eat?',
                  hintStyle: TextStyle(
                    color: _isListening ? orange : textMuted.withValues(alpha: 0.6),
                    fontSize: 18,
                    fontStyle: _isListening ? FontStyle.italic : FontStyle.normal,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
              // Listening indicator
              if (_isListening)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(orange)),
                      ),
                      const SizedBox(width: 8),
                      Text('Speak now... tap mic to stop', style: TextStyle(fontSize: 12, color: orange, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        // Food browser panel (replaces quick suggestions)
        if (!_isListening)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
              child: FoodBrowserPanel(
                userId: widget.userId,
                mealType: _selectedMealType,
                isDark: isDark,
                searchQuery: _searchQuery,
                filter: _browserFilter,
                onFilterChanged: (filter) => setState(() => _browserFilter = filter),
                onFoodLogged: () {
                  // Refresh nutrition data
                  ref.read(nutritionProvider.notifier).loadTodaySummary(widget.userId);
                },
              ),
            ),
          ),
      ],
    );
  }

  // ─── Bottom Bar ───────────────────────────────────────────────

  Widget _buildBottomBar(bool isDark) {
    const orange = Color(0xFFF97316);
    final hasText = _descriptionController.text.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Action buttons row: icon buttons left, analyze pill right
          Row(
            children: [
              // Mic button
              _ActionIconButton(
                icon: _isListening ? Icons.stop : Icons.mic,
                isActive: _isListening,
                onTap: _toggleVoiceInput,
                isDark: isDark,
              ),
              const SizedBox(width: 4),

              // Camera button
              _ActionIconButton(
                icon: Icons.camera_alt,
                onTap: () => _pickImage(ImageSource.camera),
                isDark: isDark,
              ),
              const SizedBox(width: 4),

              // Gallery button
              _ActionIconButton(
                icon: Icons.photo_library_outlined,
                onTap: () => _pickImage(ImageSource.gallery),
                isDark: isDark,
              ),
              const SizedBox(width: 4),

              // Barcode button
              _ActionIconButton(
                icon: Icons.qr_code_scanner,
                onTap: _openBarcodeScanner,
                isDark: isDark,
              ),

              const Spacer(),

              // Analyze pill button
              ElevatedButton.icon(
                onPressed: hasText ? _handleAnalyze : null,
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text('Analyze', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: orange,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: orange.withValues(alpha: 0.3),
                  disabledForegroundColor: Colors.white54,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Daily macro summary pill
          _buildDailyMacroBar(isDark),
        ],
      ),
    );
  }

  Widget _buildDailyMacroBar(bool isDark) {
    final state = ref.watch(nutritionProvider);
    final summary = state.todaySummary;
    final targets = state.targets;
    final prefsState = ref.watch(nutritionPreferencesProvider);
    final dynamicTargets = prefsState.dynamicTargets;

    final cal = summary?.totalCalories ?? 0;
    final carbs = summary?.totalCarbsG.round() ?? 0;
    final protein = summary?.totalProteinG.round() ?? 0;
    final fat = summary?.totalFatG.round() ?? 0;

    final calTarget = dynamicTargets?.targetCalories ?? targets?.dailyCalorieTarget ?? 2000;
    final carbsTarget = dynamicTargets?.targetCarbsG ?? targets?.dailyCarbsTargetG?.round() ?? 200;
    final proteinTarget = dynamicTargets?.targetProteinG ?? targets?.dailyProteinTargetG?.round() ?? 150;
    final fatTarget = dynamicTargets?.targetFatG ?? targets?.dailyFatTargetG?.round() ?? 65;

    // Build adjustment label for training/rest day
    final adjustmentLabel = dynamicTargets != null &&
            dynamicTargets.adjustmentReason != 'base_targets' &&
            dynamicTargets.calorieAdjustment != 0
        ? ' (${dynamicTargets.calorieAdjustment > 0 ? '+' : ''}${dynamicTargets.calorieAdjustment})'
        : '';

    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    const amber = Color(0xFFFFB300);
    const purple = Color(0xFFAB47BC);
    const coral = Color(0xFFFF7043);

    Widget macroSegment(String label, int value, int target, Color color) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(width: 2),
          Text('$value', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary)),
          Text('/$target', style: TextStyle(fontSize: 13, color: textMuted)),
        ],
      );
    }

    final separator = Text(' · ', style: TextStyle(fontSize: 13, color: textMuted));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: glassSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
          width: 0.5,
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Calories
            Text('\u{1F525}', style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 2),
            Text('$cal', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary)),
            Text('/$calTarget', style: TextStyle(fontSize: 13, color: textMuted)),
            if (adjustmentLabel.isNotEmpty)
              Text(adjustmentLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF26A69A))),
            separator,
            macroSegment('C', carbs, carbsTarget, amber),
            separator,
            macroSegment('P', protein, proteinTarget, purple),
            separator,
            macroSegment('F', fat, fatTarget, coral),
          ],
        ),
      ),
    );
  }

  // ─── Nutrition Preview ────────────────────────────────────────

  Widget _buildNutritionPreview(bool isDark) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    const orange = Color(0xFFF97316);

    final response = _analyzedResponse!;
    final description = _descriptionController.text.trim();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Food description with Goal Score
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: elevated,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.search, size: 14, color: textMuted),
                                const SizedBox(width: 6),
                                Text('You searched:', style: TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.w500)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              description,
                              style: TextStyle(color: textSecondary, fontSize: 13, fontStyle: FontStyle.italic),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.restaurant, size: 14, color: isDark ? AppColors.teal : AppColorsLight.teal),
                                const SizedBox(width: 6),
                                Text('Found:', style: TextStyle(color: isDark ? AppColors.teal : AppColorsLight.teal, fontSize: 11, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ...response.foodItemsRanked.take(3).map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(
                                item.amount != null && item.amount!.isNotEmpty ? '${item.name} (${item.amount})' : item.name,
                                style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            )),
                            if (response.foodItemsRanked.length > 3)
                              Text('+${response.foodItemsRanked.length - 3} more items', style: TextStyle(color: textMuted, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                    if (response.overallMealScore != null) ...[
                      const SizedBox(width: 10),
                      _CompactGoalScore(score: response.overallMealScore!, isDark: isDark),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // AI Estimated header row
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary, size: 20),
                    const SizedBox(width: 8),
                    Text('AI Estimated', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
                    if (_analysisElapsedMs != null) ...[
                      const SizedBox(width: 8),
                      Text('(${(_analysisElapsedMs! / 1000).toStringAsFixed(1)}s)', style: TextStyle(fontSize: 12, color: textMuted)),
                    ],
                    const Spacer(),
                    // Star button
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _isSaved || _isSaving ? null : _handleSaveAsFavorite,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: _isSaving
                            ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary))
                            : Icon(_isSaved ? Icons.star : Icons.star_border, size: 24, color: _isSaved ? AppColors.yellow : textMuted),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _handleEdit,
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 14, color: textMuted),
                          const SizedBox(width: 4),
                          Text('Edit', style: TextStyle(fontSize: 12, color: textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Compact macros row
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(color: elevated, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      _AnimatedCalorieChip(calories: response.totalCalories, color: AppColors.coral),
                      _CompactMacroChip(icon: Icons.fitness_center, value: '${response.proteinG.toStringAsFixed(0)}g', unit: 'Protein', color: AppColors.yellow),
                      _CompactMacroChip(icon: Icons.grain, value: '${response.carbsG.toStringAsFixed(0)}g', unit: 'Carbs', color: AppColors.green),
                      _CompactMacroChip(icon: Icons.opacity, value: '${response.fatG.toStringAsFixed(0)}g', unit: 'Fat', color: AppColors.quickActionWater),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Mood tracking
                _MoodTrackingSection(
                  moodBefore: _moodBefore,
                  moodAfter: _moodAfter,
                  energyLevel: _energyLevel,
                  onMoodBeforeChanged: (mood) => setState(() => _moodBefore = mood),
                  onMoodAfterChanged: (mood) => setState(() => _moodAfter = mood),
                  onEnergyLevelChanged: (level) => setState(() => _energyLevel = level),
                  isDark: isDark,
                ),
                const SizedBox(height: 12),

                // Collapsible food items
                if (response.foodItems.isNotEmpty)
                  _CollapsibleFoodItemsSection(
                    foodItems: response.foodItemsRanked,
                    isDark: isDark,
                    onItemWeightChanged: (index, updatedItem) => _handleFoodItemWeightChange(index, updatedItem),
                  ),
                if (response.foodItems.isNotEmpty) const SizedBox(height: 12),

                // Micronutrients
                if (_hasMicronutrients(response))
                  _MicronutrientsSection(response: response, isDark: isDark),
                if (_hasMicronutrients(response)) const SizedBox(height: 12),

                // AI Suggestion
                if (response.aiSuggestion != null || (response.encouragements != null && response.encouragements!.isNotEmpty) || (response.warnings != null && response.warnings!.isNotEmpty))
                  _AISuggestionCard(
                    suggestion: response.aiSuggestion,
                    encouragements: response.encouragements,
                    warnings: response.warnings,
                    recommendedSwap: response.recommendedSwap,
                    isDark: isDark,
                  ),

                Text('AI estimates based on your description', style: TextStyle(fontSize: 11, color: textMuted, fontStyle: FontStyle.italic), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),

        // Fixed Log button at bottom
        Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _handleLog,
              icon: _isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                  : const Icon(Icons.check, size: 18),
              label: Text(_isSaving ? 'Saving...' : 'Log This Meal', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: orange,
                foregroundColor: Colors.white,
                disabledBackgroundColor: orange.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Action Icon Button (glassmorphic circular icon for bottom bar)
// ─────────────────────────────────────────────────────────────────

class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  final bool isActive;

  const _ActionIconButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    const orange = Color(0xFFF97316);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isActive ? orange : glassSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive
                ? orange
                : isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isActive ? Colors.white : textMuted,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Barcode Scanner Overlay (extracted from old _ScanTab)
// ─────────────────────────────────────────────────────────────────

class _BarcodeScannerOverlay extends StatefulWidget {
  final void Function(String) onBarcodeDetected;
  final bool isDark;

  const _BarcodeScannerOverlay({required this.onBarcodeDetected, required this.isDark});

  @override
  State<_BarcodeScannerOverlay> createState() => _BarcodeScannerOverlayState();
}

class _BarcodeScannerOverlayState extends State<_BarcodeScannerOverlay> {
  MobileScannerController? _controller;
  bool _hasDetected = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      formats: [BarcodeFormat.ean13, BarcodeFormat.ean8, BarcodeFormat.upcA, BarcodeFormat.upcE],
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

    return GlassSheet(
      maxHeightFraction: 0.75,
      child: Column(
        children: [
          // Header with close button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Row(
              children: [
                Icon(Icons.qr_code_scanner, color: teal, size: 22),
                const SizedBox(width: 10),
                Text('Scan a Barcode', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary)),
                const Spacer(),
                IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close, color: textMuted)),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: MobileScanner(
                      controller: _controller,
                      onDetect: (capture) {
                        if (_hasDetected) return;
                        for (final barcode in capture.barcodes) {
                          final value = barcode.rawValue;
                          if (value != null && RegExp(r'^\d{8,14}$').hasMatch(value)) {
                            _hasDetected = true;
                            widget.onBarcodeDetected(value);
                            break;
                          }
                        }
                      },
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: teal, width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Point your camera at a product barcode', style: TextStyle(fontSize: 14, color: textMuted)),
          ),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────
// Micronutrients Section
// ─────────────────────────────────────────────────────────────────

class _MicronutrientsSection extends StatefulWidget {
  final LogFoodResponse response;
  final bool isDark;

  const _MicronutrientsSection({required this.response, required this.isDark});

  @override
  State<_MicronutrientsSection> createState() => _MicronutrientsSectionState();
}

class _MicronutrientsSectionState extends State<_MicronutrientsSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final elevated = widget.isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = widget.isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = widget.isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.science_outlined, size: 20, color: AppColors.purple),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Vitamins & Minerals', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary))),
                  Icon(_isExpanded ? Icons.expand_less : Icons.expand_more, color: textMuted),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildMicronutrientsList(textPrimary, textMuted),
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildMicronutrientsList(Color textPrimary, Color textMuted) {
    final response = widget.response;
    final items = <Widget>[];

    if (response.sugarG != null) items.add(_buildMicroRow('Sugar', '${response.sugarG!.toStringAsFixed(1)}g', Colors.pink, textPrimary, textMuted));
    if (response.saturatedFatG != null) items.add(_buildMicroRow('Saturated Fat', '${response.saturatedFatG!.toStringAsFixed(1)}g', Colors.orange, textPrimary, textMuted));
    if (response.cholesterolMg != null) items.add(_buildMicroRow('Cholesterol', '${response.cholesterolMg!.toStringAsFixed(0)}mg', Colors.red, textPrimary, textMuted));
    if (response.sodiumMg != null) items.add(_buildMicroRow('Sodium', '${response.sodiumMg!.toStringAsFixed(0)}mg', Colors.amber, textPrimary, textMuted));
    if (response.potassiumMg != null) items.add(_buildMicroRow('Potassium', '${response.potassiumMg!.toStringAsFixed(0)}mg', Colors.teal, textPrimary, textMuted));
    if (response.calciumMg != null) items.add(_buildMicroRow('Calcium', '${response.calciumMg!.toStringAsFixed(0)}mg', Colors.blue, textPrimary, textMuted));
    if (response.ironMg != null) items.add(_buildMicroRow('Iron', '${response.ironMg!.toStringAsFixed(1)}mg', Colors.brown, textPrimary, textMuted));
    if (response.vitaminAIu != null) items.add(_buildMicroRow('Vitamin A', '${response.vitaminAIu!.toStringAsFixed(0)} IU', Colors.orange, textPrimary, textMuted));
    if (response.vitaminCMg != null) items.add(_buildMicroRow('Vitamin C', '${response.vitaminCMg!.toStringAsFixed(0)}mg', Colors.yellow.shade700, textPrimary, textMuted));
    if (response.vitaminDIu != null) items.add(_buildMicroRow('Vitamin D', '${response.vitaminDIu!.toStringAsFixed(0)} IU', Colors.amber.shade600, textPrimary, textMuted));

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text('No micronutrient data available', style: TextStyle(fontSize: 13, color: textMuted, fontStyle: FontStyle.italic)),
      );
    }

    return Padding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 12), child: Column(children: items));
  }

  Widget _buildMicroRow(String name, String value, Color color, Color textPrimary, Color textMuted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(child: Text(name, style: TextStyle(fontSize: 13, color: textMuted))),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────
// Helper Widgets
// ─────────────────────────────────────────────────────────────────

class _NutritionInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _NutritionInfoRow({required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: textMuted)),
          Text(value, style: TextStyle(color: textSecondary)),
        ],
      ),
    );
  }
}

/// Nutri-Score badge (A-E)
class _NutriscoreBadge extends StatelessWidget {
  final String grade;
  final bool isDark;

  const _NutriscoreBadge({required this.grade, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final g = grade.toUpperCase();
    final color = switch (g) {
      'A' => const Color(0xFF038141),
      'B' => const Color(0xFF85BB2F),
      'C' => const Color(0xFFFECB02),
      'D' => const Color(0xFFEE8100),
      _ => const Color(0xFFE63E11),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Nutri-Score ',
              style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMuted : AppColorsLight.textMuted)),
          Text(g,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

/// NOVA processing group badge (1-4)
class _NovaBadge extends StatelessWidget {
  final int group;
  final bool isDark;

  const _NovaBadge({required this.group, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = switch (group) {
      1 => const Color(0xFF038141),
      2 => const Color(0xFF85BB2F),
      3 => const Color(0xFFEE8100),
      _ => const Color(0xFFE63E11),
    };
    final label = switch (group) {
      1 => 'Unprocessed',
      2 => 'Processed ingredients',
      3 => 'Processed',
      _ => 'Ultra-processed',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('NOVA $group ',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: TextStyle(fontSize: 10, color: isDark ? AppColors.textMuted : AppColorsLight.textMuted)),
        ],
      ),
    );
  }
}

/// Rainbow-colored nutrition card for AI estimates
class _RainbowNutritionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;
  final bool isDark;
  final bool compact;

  const _RainbowNutritionCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.isDark,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 16, color: color),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: value,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      TextSpan(
                        text: ' $unit',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 24, color: color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: value,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            TextSpan(
                              text: ' $unit',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Overall Meal Score Card
// ─────────────────────────────────────────────────────────────────

/// Animated calorie chip with count-up and shimmer effect
class _AnimatedCalorieChip extends StatefulWidget {
  final int calories;
  final Color color;

  const _AnimatedCalorieChip({
    required this.calories,
    required this.color,
  });

  @override
  State<_AnimatedCalorieChip> createState() => _AnimatedCalorieChipState();
}

class _AnimatedCalorieChipState extends State<_AnimatedCalorieChip>
    with TickerProviderStateMixin {
  late AnimationController _countController;
  late AnimationController _shimmerController;
  late Animation<int> _countAnimation;

  @override
  void initState() {
    super.initState();

    // Count-up animation
    _countController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _countAnimation = IntTween(begin: 0, end: widget.calories).animate(
      CurvedAnimation(parent: _countController, curve: Curves.easeOutCubic),
    );

    // Shimmer animation
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _countController.forward();
  }

  @override
  void dispose() {
    _countController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department, size: 16, color: widget.color),
          const SizedBox(height: 4),
          AnimatedBuilder(
            animation: Listenable.merge([_countAnimation, _shimmerController]),
            builder: (context, child) {
              return ShaderMask(
                shaderCallback: (bounds) {
                  return LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.color,
                      widget.color.withValues(alpha: 0.5),
                      Colors.white,
                      widget.color.withValues(alpha: 0.5),
                      widget.color,
                    ],
                    stops: [
                      0.0,
                      _shimmerController.value - 0.3,
                      _shimmerController.value,
                      _shimmerController.value + 0.3,
                      1.0,
                    ].map((s) => s.clamp(0.0, 1.0)).toList(),
                  ).createShader(bounds);
                },
                blendMode: BlendMode.srcIn,
                child: Text(
                  '${_countAnimation.value}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.color,
                  ),
                ),
              );
            },
          ),
          Text(
            'kcal',
            style: TextStyle(
              fontSize: 9,
              color: widget.color.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact macro chip for the single-row macro display
class _CompactMacroChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String unit;
  final Color color;

  const _CompactMacroChip({
    required this.icon,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (unit.isNotEmpty)
            Text(
              unit,
              style: TextStyle(
                fontSize: 10,
                color: color.withValues(alpha: 0.7),
              ),
            ),
        ],
      ),
    );
  }
}

/// Compact goal score badge
class _CompactGoalScore extends StatelessWidget {
  final int score;
  final bool isDark;

  const _CompactGoalScore({
    required this.score,
    required this.isDark,
  });

  Color _getScoreColor() {
    // Semantic colors for score - visible in both themes
    if (score >= 8) return AppColors.green;  // Green for good score
    if (score >= 5) return AppColors.yellow;  // Yellow/amber for okay score
    return AppColors.coral;  // Red/coral for low score
  }

  @override
  Widget build(BuildContext context) {
    final scoreColor = _getScoreColor();
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: scoreColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scoreColor, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$score',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: scoreColor,
                  height: 1,
                ),
              ),
              Text(
                '/10',
                style: TextStyle(
                  fontSize: 10,
                  color: scoreColor.withValues(alpha: 0.7),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Goal Score',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w500,
            color: textMuted,
          ),
        ),
      ],
    );
  }
}

class _OverallMealScoreCard extends StatelessWidget {
  final int? score;
  final int? alignmentPercentage;
  final bool isDark;

  const _OverallMealScoreCard({
    this.score,
    this.alignmentPercentage,
    required this.isDark,
  });

  Color _getScoreColor() {
    if (score == null) return Colors.grey;
    if (score! >= 8) return AppColors.textMuted;  // Green
    if (score! >= 5) return AppColors.textSecondary;  // Yellow
    return AppColors.textPrimary;  // Red
  }

  String _getScoreLabel() {
    if (score == null) return 'N/A';
    if (score! >= 8) return 'Excellent';
    if (score! >= 6) return 'Good';
    if (score! >= 4) return 'Neutral';
    return 'Poor';
  }

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final scoreColor = _getScoreColor();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Circular score indicator
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scoreColor.withValues(alpha: 0.15),
              border: Border.all(color: scoreColor, width: 3),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    score?.toString() ?? '-',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: scoreColor,
                    ),
                  ),
                  Text(
                    '/10',
                    style: TextStyle(
                      fontSize: 10,
                      color: scoreColor.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.stars, size: 18, color: scoreColor),
                    const SizedBox(width: 6),
                    Text(
                      'Goal Score',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${_getScoreLabel()} - ${score ?? 0}/10',
                  style: TextStyle(
                    fontSize: 12,
                    color: scoreColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (alignmentPercentage != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: alignmentPercentage! / 100,
                            backgroundColor: textMuted.withValues(alpha: 0.2),
                            valueColor: AlwaysStoppedAnimation(scoreColor),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$alignmentPercentage%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: scoreColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Goal alignment',
                    style: TextStyle(fontSize: 10, color: textMuted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Collapsible Food Items Section
// ─────────────────────────────────────────────────────────────────

class _CollapsibleFoodItemsSection extends StatefulWidget {
  final List<FoodItemRanking> foodItems;
  final bool isDark;
  final void Function(int index, FoodItemRanking updatedItem)? onItemWeightChanged;

  const _CollapsibleFoodItemsSection({
    required this.foodItems,
    required this.isDark,
    this.onItemWeightChanged,
  });

  @override
  State<_CollapsibleFoodItemsSection> createState() => _CollapsibleFoodItemsSectionState();
}

class _CollapsibleFoodItemsSectionState extends State<_CollapsibleFoodItemsSection> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final elevated = widget.isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = widget.isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = widget.isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final teal = widget.isDark ? AppColors.teal : AppColorsLight.teal;

    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          // Header (always visible)
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.list_alt, size: 20, color: teal),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.foodItems.length} Food Items',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          'Tap to ${_isExpanded ? 'hide' : 'see'} details',
                          style: TextStyle(fontSize: 12, color: textMuted),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more, color: textMuted),
                  ),
                ],
              ),
            ),
          ),
          // Expanded content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                Divider(height: 1, color: cardBorder),
                ...widget.foodItems.asMap().entries.map((entry) => _FoodItemRankingCard(
                  item: entry.value,
                  isDark: widget.isDark,
                  onWeightChanged: widget.onItemWeightChanged != null
                      ? (updatedItem) => widget.onItemWeightChanged!(entry.key, updatedItem)
                      : null,
                )),
              ],
            ),
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

class _FoodItemRankingCard extends StatefulWidget {
  final FoodItemRanking item;
  final bool isDark;
  final void Function(FoodItemRanking updatedItem)? onWeightChanged;

  const _FoodItemRankingCard({
    required this.item,
    required this.isDark,
    this.onWeightChanged,
  });

  @override
  State<_FoodItemRankingCard> createState() => _FoodItemRankingCardState();
}

/// Display mode for portion adjustment
enum _PortionDisplayMode { weight, count, both }

class _FoodItemRankingCardState extends State<_FoodItemRankingCard> {
  late TextEditingController _weightController;
  late TextEditingController _countController;
  late double _currentWeight;
  late int _currentCount;
  _PortionDisplayMode _displayMode = _PortionDisplayMode.weight;

  @override
  void initState() {
    super.initState();
    _currentWeight = widget.item.weightG ?? 100.0;
    _currentCount = widget.item.count ?? 1;
    _weightController = TextEditingController(text: _currentWeight.round().toString());
    _countController = TextEditingController(text: _currentCount.toString());
    // Always default to weight mode - it's the universal unit
    _displayMode = _PortionDisplayMode.weight;
  }

  @override
  void dispose() {
    _weightController.dispose();
    _countController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_FoodItemRankingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.weightG != widget.item.weightG) {
      _currentWeight = widget.item.weightG ?? 100.0;
      _weightController.text = _currentWeight.round().toString();
    }
    if (oldWidget.item.count != widget.item.count) {
      _currentCount = widget.item.count ?? 1;
      _countController.text = _currentCount.toString();
    }
  }

  Color _getScoreColor() {
    if (widget.item.goalScore == null) return Colors.grey;
    if (widget.item.goalScore! >= 8) return AppColors.textMuted;  // Green
    if (widget.item.goalScore! >= 5) return AppColors.textSecondary;  // Blue
    return AppColors.textPrimary;  // Red
  }

  void _updateWeight(double newWeight) {
    if (newWeight <= 0 || newWeight > 5000) return;
    setState(() {
      _currentWeight = newWeight;
      _weightController.text = newWeight.round().toString();
      // Update count based on new weight if in count mode capable
      if (widget.item.weightPerUnitG != null && widget.item.weightPerUnitG! > 0) {
        _currentCount = (newWeight / widget.item.weightPerUnitG!).round();
        _countController.text = _currentCount.toString();
      }
    });
    if (widget.onWeightChanged != null && widget.item.canScale) {
      final updatedItem = widget.item.withWeight(newWeight);
      widget.onWeightChanged!(updatedItem);
    }
  }

  void _updateCount(int newCount) {
    if (newCount <= 0 || newCount > 1000) return;
    setState(() {
      _currentCount = newCount;
      _countController.text = newCount.toString();
      // Calculate weight from count
      if (widget.item.weightPerUnitG != null) {
        _currentWeight = newCount * widget.item.weightPerUnitG!;
        _weightController.text = _currentWeight.round().toString();
      }
    });
    if (widget.onWeightChanged != null && widget.item.canScaleByCount) {
      final updatedItem = widget.item.withCount(newCount);
      widget.onWeightChanged!(updatedItem);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = widget.isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final teal = widget.isDark ? AppColors.teal : AppColorsLight.teal;
    final glassSurface = widget.isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final scoreColor = _getScoreColor();

    final canScale = widget.item.canScale;
    final isEstimated = widget.item.isWeightEstimated;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              // Score badge
              if (widget.item.goalScore != null)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
                  ),
                  child: Center(
                    child: Text(
                      '${widget.item.goalScore}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(width: 36),
              const SizedBox(width: 12),
              // Food info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                      ),
                    ),
                    // Weight/Count editing row (if scalable)
                    if (canScale)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Input row based on display mode
                            Row(
                              children: [
                                // Decrease button
                                GestureDetector(
                                  onTap: () => _displayMode == _PortionDisplayMode.weight
                                      ? _updateWeight(_currentWeight - 10)
                                      : _updateCount(_currentCount - 1),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: glassSurface,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Icon(Icons.remove, size: 14, color: textMuted),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // Display based on mode
                                if (_displayMode == _PortionDisplayMode.weight)
                                  // Weight only mode
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 50,
                                        child: TextField(
                                          controller: _weightController,
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: textPrimary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          decoration: InputDecoration(
                                            isDense: true,
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 4,
                                            ),
                                            filled: true,
                                            fillColor: glassSurface,
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(4),
                                              borderSide: BorderSide.none,
                                            ),
                                          ),
                                          onSubmitted: (value) {
                                            final newWeight = double.tryParse(value);
                                            if (newWeight != null) {
                                              _updateWeight(newWeight);
                                            }
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${widget.item.displayUnit}${isEstimated ? ' ~' : ''}',
                                        style: TextStyle(fontSize: 12, color: textMuted),
                                      ),
                                    ],
                                  )
                                else if (_displayMode == _PortionDisplayMode.count)
                                  // Count only mode
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 40,
                                        child: TextField(
                                          controller: _countController,
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: textPrimary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          decoration: InputDecoration(
                                            isDense: true,
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 4,
                                            ),
                                            filled: true,
                                            fillColor: glassSurface,
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(4),
                                              borderSide: BorderSide.none,
                                            ),
                                          ),
                                          onSubmitted: (value) {
                                            final newCount = int.tryParse(value);
                                            if (newCount != null) {
                                              _updateCount(newCount);
                                            }
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        'pcs',
                                        style: TextStyle(fontSize: 12, color: textMuted),
                                      ),
                                    ],
                                  )
                                else
                                  // Both mode - show count = weight
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 40,
                                        child: TextField(
                                          controller: _countController,
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: textPrimary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          decoration: InputDecoration(
                                            isDense: true,
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 4,
                                            ),
                                            filled: true,
                                            fillColor: glassSurface,
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(4),
                                              borderSide: BorderSide.none,
                                            ),
                                          ),
                                          onSubmitted: (value) {
                                            final newCount = int.tryParse(value);
                                            if (newCount != null) {
                                              _updateCount(newCount);
                                            }
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        'pcs = ${_currentWeight.round()}${widget.item.displayUnit}',
                                        style: TextStyle(fontSize: 12, color: textMuted),
                                      ),
                                    ],
                                  ),
                                const SizedBox(width: 6),
                                // Increase button
                                GestureDetector(
                                  onTap: () => _displayMode == _PortionDisplayMode.weight
                                      ? _updateWeight(_currentWeight + 10)
                                      : _updateCount(_currentCount + 1),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: glassSurface,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Icon(Icons.add, size: 14, color: textMuted),
                                  ),
                                ),
                                if (isEstimated && _displayMode == _PortionDisplayMode.weight) ...[
                                  const SizedBox(width: 8),
                                  Tooltip(
                                    message: 'Weight estimated from "${widget.item.amount}"',
                                    child: Icon(
                                      Icons.info_outline,
                                      size: 14,
                                      color: teal.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            // Three-mode toggle (only show if item supports count-based scaling)
                            if (widget.item.canScaleByCount)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Row(
                                  children: [
                                    // Weight toggle
                                    GestureDetector(
                                      onTap: () => setState(() => _displayMode = _PortionDisplayMode.weight),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _displayMode == _PortionDisplayMode.weight
                                              ? teal.withValues(alpha: 0.2)
                                              : glassSurface,
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(6),
                                            bottomLeft: Radius.circular(6),
                                          ),
                                          border: Border.all(
                                            color: _displayMode == _PortionDisplayMode.weight
                                                ? teal.withValues(alpha: 0.5)
                                                : glassSurface,
                                          ),
                                        ),
                                        child: Text(
                                          'Weight',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: _displayMode == _PortionDisplayMode.weight
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                            color: _displayMode == _PortionDisplayMode.weight
                                                ? teal
                                                : textMuted,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Count toggle
                                    GestureDetector(
                                      onTap: () => setState(() => _displayMode = _PortionDisplayMode.count),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _displayMode == _PortionDisplayMode.count
                                              ? teal.withValues(alpha: 0.2)
                                              : glassSurface,
                                          border: Border.all(
                                            color: _displayMode == _PortionDisplayMode.count
                                                ? teal.withValues(alpha: 0.5)
                                                : glassSurface,
                                          ),
                                        ),
                                        child: Text(
                                          'Count',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: _displayMode == _PortionDisplayMode.count
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                            color: _displayMode == _PortionDisplayMode.count
                                                ? teal
                                                : textMuted,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Both toggle
                                    GestureDetector(
                                      onTap: () => setState(() => _displayMode = _PortionDisplayMode.both),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _displayMode == _PortionDisplayMode.both
                                              ? teal.withValues(alpha: 0.2)
                                              : glassSurface,
                                          borderRadius: const BorderRadius.only(
                                            topRight: Radius.circular(6),
                                            bottomRight: Radius.circular(6),
                                          ),
                                          border: Border.all(
                                            color: _displayMode == _PortionDisplayMode.both
                                                ? teal.withValues(alpha: 0.5)
                                                : glassSurface,
                                          ),
                                        ),
                                        child: Text(
                                          'Both',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: _displayMode == _PortionDisplayMode.both
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                            color: _displayMode == _PortionDisplayMode.both
                                                ? teal
                                                : textMuted,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      )
                    else if (widget.item.amount != null)
                      Text(
                        widget.item.amount!,
                        style: TextStyle(fontSize: 12, color: textMuted),
                      ),
                    if (widget.item.reason != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          widget.item.reason!,
                          style: TextStyle(
                            fontSize: 11,
                            color: scoreColor,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Calories
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${widget.item.calories ?? 0}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  Text(
                    'kcal',
                    style: TextStyle(fontSize: 10, color: textMuted),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// AI Suggestion Card
// ─────────────────────────────────────────────────────────────────

class _AISuggestionCard extends StatelessWidget {
  final String? suggestion;
  final List<String>? encouragements;
  final List<String>? warnings;
  final String? recommendedSwap;
  final bool isDark;

  const _AISuggestionCard({
    this.suggestion,
    this.encouragements,
    this.warnings,
    this.recommendedSwap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

    // Use proper accent colors for feedback types
    final encourageColor = isDark ? AppColors.green : AppColorsLight.green;
    final warningColor = isDark ? AppColors.error : AppColorsLight.error;
    final swapColor = isDark ? AppColors.purple : AppColorsLight.purple;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            teal.withValues(alpha: 0.1),
            teal.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: teal.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: teal.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.psychology, size: 20, color: teal),
              ),
              const SizedBox(width: 10),
              Text(
                'Coach Tip',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),

          // Encouragements
          if (encouragements != null && encouragements!.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...encouragements!.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.thumb_up, size: 14, color: encourageColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      e,
                      style: TextStyle(fontSize: 13, color: encourageColor),
                    ),
                  ),
                ],
              ),
            )),
          ],

          // Warnings
          if (warnings != null && warnings!.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...warnings!.map((w) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber, size: 14, color: warningColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      w,
                      style: TextStyle(fontSize: 13, color: warningColor),
                    ),
                  ),
                ],
              ),
            )),
          ],

          // General suggestion
          if (suggestion != null && suggestion!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              suggestion!,
              style: TextStyle(fontSize: 13, color: textPrimary),
            ),
          ],

          // Recommended swap
          if (recommendedSwap != null && recommendedSwap!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: swapColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: swapColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.swap_horiz, size: 18, color: swapColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      recommendedSwap!,
                      style: TextStyle(
                        fontSize: 12,
                        color: swapColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Mood Tracking Section
// ─────────────────────────────────────────────────────────────────

class _MoodTrackingSection extends StatefulWidget {
  final FoodMood? moodBefore;
  final FoodMood? moodAfter;
  final int energyLevel;
  final ValueChanged<FoodMood?> onMoodBeforeChanged;
  final ValueChanged<FoodMood?> onMoodAfterChanged;
  final ValueChanged<int> onEnergyLevelChanged;
  final bool isDark;

  const _MoodTrackingSection({
    required this.moodBefore,
    required this.moodAfter,
    required this.energyLevel,
    required this.onMoodBeforeChanged,
    required this.onMoodAfterChanged,
    required this.onEnergyLevelChanged,
    required this.isDark,
  });

  @override
  State<_MoodTrackingSection> createState() => _MoodTrackingSectionState();
}

class _MoodTrackingSectionState extends State<_MoodTrackingSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final elevated = widget.isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = widget.isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = widget.isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final purple = widget.isDark ? AppColors.purple : AppColorsLight.purple;

    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          // Header (always visible)
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.mood, size: 20, color: purple),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How are you feeling?',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          widget.moodBefore != null
                              ? 'Before: ${widget.moodBefore!.label}'
                              : 'Optional - track your mood',
                          style: TextStyle(fontSize: 12, color: textMuted),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more, color: textMuted),
                  ),
                ],
              ),
            ),
          ),
          // Expanded content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(height: 1, color: cardBorder),
                  const SizedBox(height: 16),

                  // Mood Before Eating
                  Text(
                    'Before eating',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: FoodMood.values.map((mood) => _MoodChip(
                      mood: mood,
                      isSelected: widget.moodBefore == mood,
                      onTap: () => widget.onMoodBeforeChanged(
                        widget.moodBefore == mood ? null : mood,
                      ),
                      isDark: widget.isDark,
                    )).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Mood After Eating (optional)
                  Text(
                    'After eating (optional)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: FoodMood.values.map((mood) => _MoodChip(
                      mood: mood,
                      isSelected: widget.moodAfter == mood,
                      onTap: () => widget.onMoodAfterChanged(
                        widget.moodAfter == mood ? null : mood,
                      ),
                      isDark: widget.isDark,
                    )).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Energy Level Slider
                  Text(
                    'Energy level',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.battery_1_bar, size: 18, color: textMuted),
                      Expanded(
                        child: Slider(
                          value: widget.energyLevel.toDouble(),
                          min: 1,
                          max: 5,
                          divisions: 4,
                          activeColor: purple,
                          inactiveColor: purple.withValues(alpha: 0.2),
                          onChanged: (value) => widget.onEnergyLevelChanged(value.round()),
                        ),
                      ),
                      Icon(Icons.battery_full, size: 18, color: purple),
                    ],
                  ),
                  Center(
                    child: Text(
                      _getEnergyLabel(widget.energyLevel),
                      style: TextStyle(
                        fontSize: 12,
                        color: purple,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  String _getEnergyLabel(int level) {
    switch (level) {
      case 1:
        return 'Very Low';
      case 2:
        return 'Low';
      case 3:
        return 'Moderate';
      case 4:
        return 'High';
      case 5:
        return 'Very High';
      default:
        return 'Moderate';
    }
  }
}

class _MoodChip extends StatelessWidget {
  final FoodMood mood;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _MoodChip({
    required this.mood,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  Color _getMoodColor() {
    switch (mood) {
      case FoodMood.great:
        return AppColors.textMuted; // Green
      case FoodMood.good:
        return AppColors.textSecondary; // Teal
      case FoodMood.neutral:
        return AppColors.textMuted; // Gray
      case FoodMood.tired:
        return AppColors.textMuted; // Purple
      case FoodMood.stressed:
        return AppColors.textMuted; // Red
      case FoodMood.hungry:
        return AppColors.textPrimary; // Coral
      case FoodMood.satisfied:
        return AppColors.textSecondary; // Blue
      case FoodMood.bloated:
        return AppColors.textSecondary; // Orange
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getMoodColor();
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : elevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              mood.emoji,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(width: 4),
            Text(
              mood.label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? color : textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Confidence indicator for AI estimates
class _ConfidenceIndicator extends StatelessWidget {
  final String confidenceLevel;
  final double? confidenceScore;
  final String? sourceType;
  final bool isDark;

  const _ConfidenceIndicator({
    required this.confidenceLevel,
    this.confidenceScore,
    this.sourceType,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final Color indicatorColor;
    final IconData indicatorIcon;
    final String displayText;
    final String? subText;

    switch (confidenceLevel) {
      case 'high':
        indicatorColor = isDark ? AppColors.green : AppColorsLight.green;
        indicatorIcon = Icons.verified;
        displayText = 'High confidence';
        subText = sourceType == 'barcode' ? 'Verified from barcode' : 'AI analysis confident';
        break;
      case 'medium':
        indicatorColor = isDark ? AppColors.orange : AppColorsLight.orange;
        indicatorIcon = Icons.info_outline;
        displayText = 'Medium confidence';
        subText = sourceType == 'restaurant'
            ? 'Restaurant estimate - actual may vary'
            : 'AI estimate - values may vary slightly';
        break;
      case 'low':
      default:
        indicatorColor = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
        indicatorIcon = Icons.help_outline;
        displayText = 'Estimate only';
        subText = 'Please verify these values';
        break;
    }

    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: indicatorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: indicatorColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(indicatorIcon, size: 16, color: indicatorColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      displayText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: indicatorColor,
                      ),
                    ),
                    if (confidenceScore != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        '(${(confidenceScore! * 100).toInt()}%)',
                        style: TextStyle(
                          fontSize: 11,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  subText,
                  style: TextStyle(
                    fontSize: 11,
                    color: textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Animated Food Analysis Loading Indicator
// ─────────────────────────────────────────────────────────────────

/// A dynamic loading indicator that feels alive even when waiting
class _FoodAnalysisLoadingIndicator extends StatefulWidget {
  final int currentStep;
  final int totalSteps;
  final String progressMessage;
  final String? progressDetail;
  final bool isDark;

  const _FoodAnalysisLoadingIndicator({
    required this.currentStep,
    required this.totalSteps,
    required this.progressMessage,
    this.progressDetail,
    required this.isDark,
  });

  @override
  State<_FoodAnalysisLoadingIndicator> createState() => _FoodAnalysisLoadingIndicatorState();
}

class _FoodAnalysisLoadingIndicatorState extends State<_FoodAnalysisLoadingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _stepBounceController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _stepBounceAnimation;
  int _tipIndex = 0;
  int _dotCount = 0;
  int _lastStep = 0;

  static const _tips = [
    'Did you know? Protein keeps you full longer',
    'Fun fact: Your body burns calories digesting food',
    'Tip: Eating slowly helps you feel satisfied',
    'Tracking meals builds awareness',
    'Small choices add up to big results',
    'Fiber is your gut\'s best friend',
    'Hydration boosts metabolism',
    'Consistency beats perfection',
    'Protein helps build and repair muscle',
    'Healthy fats are essential for brain function',
  ];

  @override
  void initState() {
    super.initState();

    // Pulse animation for the progress ring
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Rotation for the outer indicator
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Step bounce animation (triggers when step changes)
    _stepBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _stepBounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _stepBounceController, curve: Curves.easeOut));

    _lastStep = widget.currentStep;

    // Cycle through tips every 2.5 seconds
    _startTipCycler();
    // Animate dots
    _startDotAnimator();
  }

  void _startTipCycler() {
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _tipIndex = (_tipIndex + 1) % _tips.length;
        });
        _startTipCycler();
      }
    });
  }

  void _startDotAnimator() {
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _dotCount = (_dotCount + 1) % 4;
        });
        _startDotAnimator();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _FoodAnalysisLoadingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger bounce animation when step changes
    if (widget.currentStep != _lastStep) {
      _lastStep = widget.currentStep;
      _stepBounceController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _stepBounceController.dispose();
    super.dispose();
  }

  String get _dots => '.' * _dotCount + ' ' * (3 - _dotCount);

  @override
  Widget build(BuildContext context) {
    final teal = widget.isDark ? AppColors.teal : AppColorsLight.teal;
    final textPrimary = widget.isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = widget.isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final progress = widget.totalSteps > 0 ? widget.currentStep / widget.totalSteps : 0.0;

    // Use the backend message if available, otherwise cycle through tips
    final displayMessage = widget.progressMessage.isNotEmpty
        ? widget.progressMessage
        : _tips[_tipIndex];

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated progress ring
            AnimatedBuilder(
              animation: Listenable.merge([_pulseAnimation, _rotateController]),
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: SizedBox(
                    width: 100,
                    height: 100,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Rotating outer ring (shows activity)
                        Transform.rotate(
                          angle: _rotateController.value * 2 * 3.14159,
                          child: SizedBox(
                            width: 100,
                            height: 100,
                            child: CircularProgressIndicator(
                              value: null, // Indeterminate
                              strokeWidth: 3,
                              color: teal.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                        // Progress ring
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: progress),
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return CircularProgressIndicator(
                                value: value > 0 ? value : null,
                                strokeWidth: 6,
                                color: teal,
                                backgroundColor: teal.withValues(alpha: 0.15),
                                strokeCap: StrokeCap.round,
                              );
                            },
                          ),
                        ),
                        // Step counter with bounce animation on step change
                        AnimatedBuilder(
                          animation: _stepBounceAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _stepBounceAnimation.value,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${widget.currentStep}/${widget.totalSteps}',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: teal,
                                    ),
                                  ),
                                  Text(
                                    'steps',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // Main message with animated dots
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                '$displayMessage$_dots',
                key: ValueKey('$displayMessage$_dotCount'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Progress detail if available
            if (widget.progressDetail != null) ...[
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  widget.progressDetail!,
                  key: ValueKey(widget.progressDetail),
                  style: TextStyle(fontSize: 13, color: textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Animated progress bar with shimmer effect
            SizedBox(
              width: 200,
              child: Stack(
                children: [
                  // Background track
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: teal.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  // Progress fill
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return FractionallySizedBox(
                        widthFactor: value > 0 ? value : 0.0,
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                teal,
                                teal.withValues(alpha: 0.7),
                                teal,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      );
                    },
                  ),
                  // Shimmer overlay (activity indicator)
                  AnimatedBuilder(
                    animation: _rotateController,
                    builder: (context, child) {
                      return Positioned(
                        left: _rotateController.value * 180,
                        child: Container(
                          width: 20,
                          height: 6,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.white.withValues(alpha: 0.3),
                                Colors.transparent,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Subtle hint that it's working
            Text(
              'This usually takes a few seconds',
              style: TextStyle(
                fontSize: 12,
                color: textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
