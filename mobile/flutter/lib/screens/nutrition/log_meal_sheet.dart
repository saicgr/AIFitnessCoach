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
import '../../widgets/guest_upgrade_sheet.dart';
import '../../widgets/main_shell.dart';
import '../../data/services/food_search_service.dart' as search;
import 'widgets/food_search_bar.dart';
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
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.2),
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

class _LogMealSheetState extends ConsumerState<LogMealSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  MealType _selectedMealType = MealType.lunch;
  bool _isLoading = false;
  String? _error;

  // Streaming progress state
  int _currentStep = 0;
  int _totalSteps = 4;
  String _progressMessage = '';
  String? _progressDetail;

  final _descriptionController = TextEditingController();
  bool _hasScanned = false;

  @override
  void initState() {
    super.initState();
    // 4 tabs: Describe (with voice), Photo, Scan, Quick
    _tabController = TabController(length: 4, vsync: this, initialIndex: 0);
    // Use initial meal type if provided, otherwise default based on time
    _selectedMealType = widget.initialMealType ?? _getDefaultMealType();

    debugPrint('🍽️ [LogMeal] Sheet initialized | userId=${widget.userId} | initialMealType=${widget.initialMealType?.value ?? "auto"} | selectedMealType=${_selectedMealType.value}');

    // Log tab changes for user context
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final tabNames = ['Describe', 'Photo', 'Scan', 'Quick'];
      debugPrint('🔄 [LogMeal] Tab changed | tab=${tabNames[_tabController.index]} | index=${_tabController.index}');
    }
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
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    debugPrint('📸 [LogMeal] _pickImage started | source=${source.name} | userId=${widget.userId}');

    // Check guest limits for photo scanning
    final isGuest = ref.read(isGuestModeProvider);
    if (isGuest) {
      debugPrint('📸 [LogMeal] Guest mode detected, checking limits');
      final canScan = await ref.read(guestUsageLimitsProvider.notifier).usePhotoScan();
      if (!canScan) {
        debugPrint('⚠️ [LogMeal] Guest photo scan limit reached');
        if (mounted) {
          Navigator.pop(context);
          GuestUpgradeSheet.show(context, feature: GuestFeatureLimit.photoScan);
        }
        return;
      }
    }

    try {
      final picker = ImagePicker();
      debugPrint('📸 [LogMeal] Opening image picker...');
      final image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) {
        debugPrint('📸 [LogMeal] User cancelled image picker');
        return;
      }

      debugPrint('📸 [LogMeal] Image selected | path=${image.path}');

      setState(() {
        _isLoading = true;
        _error = null;
        _currentStep = 0;
        _progressMessage = 'Preparing image...';
        _progressDetail = null;
      });

      final repository = ref.read(nutritionRepositoryProvider);
      LogFoodResponse? response;

      debugPrint('📸 [LogMeal] Starting image analysis stream | mealType=${_selectedMealType.value}');
      final stopwatch = Stopwatch()..start();

      // Use ANALYZE-ONLY streaming - does NOT save to database yet
      await for (final progress in repository.analyzeFoodFromImageStreaming(
        userId: widget.userId,
        mealType: _selectedMealType.value,
        imageFile: File(image.path),
      )) {
        if (!mounted) {
          debugPrint('⚠️ [LogMeal] Widget unmounted during analysis');
          return;
        }

        if (progress.hasError) {
          debugPrint('❌ [LogMeal] Analysis error | message=${progress.message} | elapsed=${stopwatch.elapsedMilliseconds}ms');
          setState(() {
            _isLoading = false;
            _error = progress.message;
          });
          return;
        }

        if (progress.isCompleted && progress.foodLog != null) {
          response = progress.foodLog;
          debugPrint('✅ [LogMeal] Analysis complete | elapsed=${stopwatch.elapsedMilliseconds}ms');
          break;
        }

        // Update progress UI
        debugPrint('🔄 [LogMeal] Progress update | step=${progress.step}/${progress.totalSteps} | ${progress.message}');
        setState(() {
          _currentStep = progress.step;
          _totalSteps = progress.totalSteps;
          _progressMessage = progress.message;
          _progressDetail = progress.detail;
        });
      }

      stopwatch.stop();

      if (mounted && response != null) {
        setState(() => _isLoading = false);

        // Log detailed response info for debugging
        debugPrint('📊 [LogMeal] Response received:');
        debugPrint('   - success: ${response.success}');
        debugPrint('   - foodItems count: ${response.foodItems.length}');
        debugPrint('   - totalCalories: ${response.totalCalories}');
        debugPrint('   - protein: ${response.proteinG}g');
        debugPrint('   - carbs: ${response.carbsG}g');
        debugPrint('   - fat: ${response.fatG}g');
        debugPrint('   - fiber: ${response.fiberG}g');
        if (response.foodItems.isNotEmpty) {
          debugPrint('   - foodItems: ${response.foodItems.map((f) => f['name']).toList()}');
        }

        // Validate that we actually detected food with nutrition data
        if (response.foodItems.isEmpty && response.totalCalories == 0) {
          debugPrint('⚠️ [LogMeal] Empty response - no food detected');
          setState(() {
            _error = 'Could not identify food in the image. Please try a clearer photo with visible food items.';
          });
          return;
        }

        // Show rainbow confirmation dialog for user to review with portion editing
        // Extract food names from the response for display
        final detectedFoodNames = response.foodItems.isNotEmpty
            ? response.foodItems.map((f) => f['name']?.toString() ?? 'Food').join(', ')
            : 'Detected food';
        debugPrint('🎯 [LogMeal] Showing confirmation dialog | foods="$detectedFoodNames"');
        final result = await _showRainbowNutritionConfirmation(response, detectedFoodNames);
        debugPrint('📋 [LogMeal] Dialog result | confirmed=${result?.confirmed} | multiplier=${result?.multiplier}');

        if (result != null && result.confirmed && mounted) {
          // Apply portion multiplier to the response
          final adjustedResponse = result.multiplier != 1.0
              ? response.copyWithMultiplier(result.multiplier)
              : response;

          debugPrint('💾 [LogMeal] Saving meal | calories=${adjustedResponse.totalCalories} | multiplier=${result.multiplier}');

          // NOW actually save to database after user confirmation
          setState(() {
            _isLoading = true;
            _progressMessage = 'Saving your meal...';
          });

          try {
            await repository.logFoodDirect(
              userId: widget.userId,
              mealType: _selectedMealType.value,
              analyzedFood: adjustedResponse,
              sourceType: 'image',
            );

            debugPrint('✅ [LogMeal] Meal saved successfully');
            if (mounted) {
              // Award XP for daily goal
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
          _error = 'Analysis failed. Please try again.';
        });
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [LogMeal] Exception in _pickImage | error=$e');
      debugPrint('   stackTrace: $stackTrace');
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _logFromText() async {
    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      debugPrint('📝 [LogMeal] _logFromText called but description is empty');
      return;
    }

    debugPrint('📝 [LogMeal] _logFromText started | description="$description" | mealType=${_selectedMealType.value}');

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

    setState(() {
      _isLoading = true;
      _error = null;
      _currentStep = 0;
      _progressMessage = 'Starting analysis...';
      _progressDetail = null;
    });

    try {
      final repository = ref.read(nutritionRepositoryProvider);
      LogFoodResponse? response;

      debugPrint('📝 [LogMeal] Starting text analysis stream...');
      final stopwatch = Stopwatch()..start();

      // Use ANALYZE-ONLY streaming - does NOT save to database yet
      await for (final progress in repository.analyzeFoodFromTextStreaming(
        userId: widget.userId,
        description: description,
        mealType: _selectedMealType.value,
      )) {
        if (!mounted) {
          debugPrint('⚠️ [LogMeal] Widget unmounted during text analysis');
          return;
        }

        if (progress.hasError) {
          debugPrint('❌ [LogMeal] Text analysis error | message=${progress.message} | elapsed=${stopwatch.elapsedMilliseconds}ms');
          setState(() {
            _isLoading = false;
            _error = progress.message;
          });
          return;
        }

        if (progress.isCompleted && progress.foodLog != null) {
          response = progress.foodLog;
          debugPrint('✅ [LogMeal] Text analysis complete | elapsed=${stopwatch.elapsedMilliseconds}ms');
          break;
        }

        // Update progress UI
        debugPrint('🔄 [LogMeal] Text progress | step=${progress.step}/${progress.totalSteps} | ${progress.message}');
        setState(() {
          _currentStep = progress.step;
          _totalSteps = progress.totalSteps;
          _progressMessage = progress.message;
          _progressDetail = progress.detail;
        });
      }

      stopwatch.stop();

      if (mounted && response != null) {
        setState(() => _isLoading = false);

        // Log detailed response info for debugging
        debugPrint('📊 [LogMeal] Text response received:');
        debugPrint('   - success: ${response.success}');
        debugPrint('   - foodItems count: ${response.foodItems.length}');
        debugPrint('   - totalCalories: ${response.totalCalories}');
        debugPrint('   - protein: ${response.proteinG}g | carbs: ${response.carbsG}g | fat: ${response.fatG}g');
        if (response.foodItems.isNotEmpty) {
          debugPrint('   - foodItems: ${response.foodItems.map((f) => f['name']).toList()}');
        }

        // Validate that we actually got nutrition data
        if (response.foodItems.isEmpty && response.totalCalories == 0) {
          debugPrint('⚠️ [LogMeal] Empty text response - no food detected');
          setState(() {
            _error = 'Could not analyze "$description". Please try a more specific food description.';
          });
          return;
        }

        // Show rainbow confirmation dialog for user to review with portion editing
        debugPrint('🎯 [LogMeal] Showing text confirmation dialog');
        final result = await _showRainbowNutritionConfirmation(response, description);
        debugPrint('📋 [LogMeal] Text dialog result | confirmed=${result?.confirmed} | multiplier=${result?.multiplier}');
        if (result != null && result.confirmed && mounted) {
          // Apply portion multiplier to the response
          final adjustedResponse = result.multiplier != 1.0
              ? response.copyWithMultiplier(result.multiplier)
              : response;

          debugPrint('💾 [LogMeal] Saving text meal | calories=${adjustedResponse.totalCalories} | multiplier=${result.multiplier}');

          // NOW actually save to database after user confirmation
          setState(() {
            _isLoading = true;
            _progressMessage = 'Saving your meal...';
          });

          try {
            await repository.logFoodDirect(
              userId: widget.userId,
              mealType: _selectedMealType.value,
              analyzedFood: adjustedResponse,
              sourceType: 'text',
            );

            debugPrint('✅ [LogMeal] Text meal saved successfully');
            if (mounted) {
              // Award XP for daily goal
              ref.read(xpProvider.notifier).markMealLogged();
              Navigator.pop(context);
              _showSuccessSnackbar(adjustedResponse.totalCalories);
              ref.read(nutritionProvider.notifier).loadTodaySummary(widget.userId);
            }
          } catch (saveError) {
            debugPrint('❌ [LogMeal] Text save failed | error=$saveError');
            if (mounted) {
              setState(() {
                _isLoading = false;
                _error = 'Failed to save meal: $saveError';
              });
            }
          }
        } else {
          debugPrint('📋 [LogMeal] User cancelled text confirmation dialog');
        }
      } else if (mounted && response == null) {
        // Stream completed but no response - show error
        debugPrint('❌ [LogMeal] Text stream completed but response is null');
        setState(() {
          _isLoading = false;
          _error = 'Analysis failed. Please try again.';
        });
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [LogMeal] Exception in _logFromText | error=$e');
      debugPrint('   stackTrace: $stackTrace');
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  /// Log an already analyzed food response
  void _logAnalyzedFood(LogFoodResponse response) async {
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

    Navigator.pop(context);
    _showSuccessSnackbar(response.totalCalories);
    ref.read(nutritionProvider.notifier).loadTodaySummary(widget.userId);
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

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: nearBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Found Product', style: TextStyle(color: textPrimary)),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
            maxWidth: MediaQuery.of(context).size.width * 0.85,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                if (product.brand != null) ...[
                  const SizedBox(height: 4),
                  Text(product.brand!, style: TextStyle(color: textMuted)),
                ],
                const SizedBox(height: 16),
                _NutritionInfoRow(
                  label: 'Calories',
                  value: '${product.caloriesPer100g.toInt()} kcal/100g',
                  isDark: isDark,
                ),
                _NutritionInfoRow(
                  label: 'Protein',
                  value: '${product.proteinPer100g.toStringAsFixed(1)}g/100g',
                  isDark: isDark,
                ),
                _NutritionInfoRow(
                  label: 'Carbs',
                  value: '${product.carbsPer100g.toStringAsFixed(1)}g/100g',
                  isDark: isDark,
                ),
                _NutritionInfoRow(
                  label: 'Fat',
                  value: '${product.fatPer100g.toStringAsFixed(1)}g/100g',
                  isDark: isDark,
                ),
                // Inflammation Analysis Section
                if (product.ingredientsText != null &&
                    product.ingredientsText!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Divider(color: textMuted.withValues(alpha: 0.3)),
                  const SizedBox(height: 12),
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

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final nearBlack = isDark ? AppColors.nearBlack : AppColorsLight.nearWhite;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    // Use orange as the primary accent color throughout the sheet
    const orange = Color(0xFFF97316); // Primary app accent - consistent orange

    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardVisible = keyboardHeight > 0;

    // When keyboard is visible, reduce sheet height to fit above keyboard
    // Otherwise, sheet takes 85% of screen height
    final sheetHeight = keyboardVisible
        ? screenHeight - keyboardHeight - MediaQuery.of(context).padding.top - 20
        : screenHeight * 0.85;

    return Padding(
      // Add bottom padding equal to keyboard height so sheet sits above keyboard
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            height: sheetHeight,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.6),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.1),
                width: 0.5,
              ),
            ),
          ),
          child: Column(
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Row(
              children: [
                Text(
                  'Log a Meal',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: textMuted),
                ),
              ],
            ),
          ),

          // Meal type selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: MealType.values.map((type) {
                final isSelected = _selectedMealType == type;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () {
                        debugPrint('🍽️ [LogMeal] Meal type changed | from=${_selectedMealType.value} | to=${type.value}');
                        setState(() => _selectedMealType = type);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? orange.withValues(alpha: 0.15) : elevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? orange : cardBorder,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(type.emoji, style: const TextStyle(fontSize: 20)),
                            const SizedBox(height: 2),
                            Text(
                              type.label,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                color: isSelected ? orange : textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),

          // Tab bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: elevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: orange,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: textMuted,
              labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(icon: Icon(Icons.edit, size: 18), text: 'Describe'),
                Tab(icon: Icon(Icons.camera_alt, size: 18), text: 'Photo'),
                Tab(icon: Icon(Icons.qr_code_scanner, size: 18), text: 'Scan'),
                Tab(icon: Icon(Icons.flash_on, size: 18), text: 'Quick'),
              ],
            ),
          ),

          // Error message
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.error : AppColorsLight.error).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isDark ? AppColors.error : AppColorsLight.error),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: isDark ? AppColors.error : AppColorsLight.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: isDark ? AppColors.error : AppColorsLight.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Loading indicator with streaming progress
          if (_isLoading)
            Expanded(
              child: _FoodAnalysisLoadingIndicator(
                currentStep: _currentStep,
                totalSteps: _totalSteps,
                progressMessage: _progressMessage,
                progressDetail: _progressDetail,
                isDark: isDark,
              ),
            )
          else
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _DescribeTab(
                    controller: _descriptionController,
                    onLog: _logAnalyzedFood,
                    isDark: isDark,
                    userId: widget.userId,
                    mealType: _selectedMealType.value,
                    sourceType: 'text',
                  ),
                  _PhotoTab(onPickImage: _pickImage, isDark: isDark),
                  _ScanTab(onBarcodeDetected: _handleBarcodeScan, isDark: isDark),
                  _QuickTab(
                    userId: widget.userId,
                    mealType: _selectedMealType,
                    onLogged: () {
                      Navigator.pop(context);
                      ref.read(nutritionProvider.notifier).loadTodaySummary(widget.userId);
                    },
                    isDark: isDark,
                  ),
                ],
              ),
            ),
        ],
      ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Photo Tab
// ─────────────────────────────────────────────────────────────────

class _PhotoTab extends StatelessWidget {
  final void Function(ImageSource) onPickImage;
  final bool isDark;

  const _PhotoTab({required this.onPickImage, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onPickImage(ImageSource.camera),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: elevated,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: teal.withValues(alpha: 0.3)),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: teal.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.camera_alt, size: 40, color: teal),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Take a Photo',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'AI will identify and estimate nutrition',
                          style: TextStyle(fontSize: 13, color: textMuted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => onPickImage(ImageSource.gallery),
              icon: Icon(Icons.photo_library, color: cyan),
              label: Text('Choose from Gallery', style: TextStyle(color: cyan)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: cyan),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Voice Tab
// ─────────────────────────────────────────────────────────────────

class _VoiceTab extends StatefulWidget {
  final void Function(String) onSubmit;
  final bool isDark;

  const _VoiceTab({required this.onSubmit, required this.isDark});

  @override
  State<_VoiceTab> createState() => _VoiceTabState();
}

class _VoiceTabState extends State<_VoiceTab> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;
  String _recognizedText = '';
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onStatus: (status) {
          debugPrint('Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            if (mounted) {
              setState(() => _isListening = false);
              // Auto-submit if we have text
              if (_recognizedText.isNotEmpty) {
                widget.onSubmit(_recognizedText);
              }
            }
          }
        },
        onError: (error) {
          debugPrint('Speech error: $error');
          if (mounted) {
            setState(() {
              _isListening = false;
              _statusMessage = 'Error: ${error.errorMsg}';
            });
          }
        },
      );
      if (mounted) {
        setState(() {
          _statusMessage = _speechAvailable ? '' : 'Speech recognition not available';
        });
      }
    } catch (e) {
      debugPrint('Speech init error: $e');
      if (mounted) {
        setState(() {
          _speechAvailable = false;
          _statusMessage = 'Could not initialize speech recognition';
        });
      }
    }
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      setState(() => _statusMessage = 'Speech recognition not available');
      return;
    }

    setState(() {
      _isListening = true;
      _recognizedText = '';
      _statusMessage = '';
    });

    await _speech.listen(
      onResult: (result) {
        if (mounted) {
          setState(() {
            _recognizedText = result.recognizedWords;
          });
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: 'en_US',
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  void _toggleListening() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;
    final coral = isDark ? AppColors.coral : AppColorsLight.coral;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Mic button
                GestureDetector(
                  onTap: _toggleListening,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: EdgeInsets.all(_isListening ? 40 : 32),
                    decoration: BoxDecoration(
                      color: _isListening ? coral.withValues(alpha: 0.2) : teal.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      boxShadow: _isListening
                          ? [BoxShadow(color: coral.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 5)]
                          : null,
                    ),
                    child: Icon(
                      _isListening ? Icons.stop : Icons.mic,
                      size: 48,
                      color: _isListening ? coral : teal,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _isListening ? 'Listening...' : 'Tap to Speak',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary),
                ),
                const SizedBox(height: 8),
                Text('Describe what you ate', style: TextStyle(fontSize: 14, color: textMuted)),

                // Show recognized text
                if (_recognizedText.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: teal.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.format_quote, size: 16, color: teal),
                            const SizedBox(width: 8),
                            Text('You said:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: teal)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _recognizedText,
                          style: TextStyle(fontSize: 16, color: textPrimary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          setState(() => _recognizedText = '');
                        },
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Try Again'),
                      ),
                      const SizedBox(width: 16),
                      FilledButton.icon(
                        onPressed: () => widget.onSubmit(_recognizedText),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Log This'),
                      ),
                    ],
                  ),
                ] else ...[
                  // Show example when no text recognized
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: elevated, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Example:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textMuted)),
                        const SizedBox(height: 8),
                        Text(
                          '"I had two scrambled eggs with toast and a glass of orange juice"',
                          style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Status message or tip
          if (_statusMessage.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.warning : AppColorsLight.warning).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: isDark ? AppColors.warning : AppColorsLight.warning),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _statusMessage,
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: teal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.tips_and_updates_outlined, size: 20, color: teal),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Speak naturally - AI will estimate nutrition from your description',
                      style: TextStyle(fontSize: 12, color: textSecondary),
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
// Describe Tab - Two-step flow: Analyze → Preview → Log
// ─────────────────────────────────────────────────────────────────

class _DescribeTab extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final void Function(LogFoodResponse) onLog;
  final bool isDark;
  final String userId;
  final String mealType;
  final String sourceType;
  final String? barcode;
  final String? imageUrl;

  const _DescribeTab({
    required this.controller,
    required this.onLog,
    required this.isDark,
    required this.userId,
    required this.mealType,
    this.sourceType = 'text',
    this.barcode,
    this.imageUrl,
  });

  @override
  ConsumerState<_DescribeTab> createState() => _DescribeTabState();
}

class _DescribeTabState extends ConsumerState<_DescribeTab> {
  LogFoodResponse? _analyzedResponse;
  bool _isAnalyzing = false;
  bool _isSaved = false;
  bool _isSaving = false;

  // Scroll controller for keyboard handling
  final ScrollController _scrollController = ScrollController();
  final FocusNode _textFieldFocusNode = FocusNode();
  final GlobalKey _textFieldKey = GlobalKey();

  // Voice input state
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;

  // Mood tracking state
  FoodMood? _moodBefore;
  FoodMood? _moodAfter;
  int _energyLevel = 3; // Default to middle (1-5 scale)

  // Streaming progress state
  int _currentStep = 0;
  int _totalSteps = 3; // Analyze-only has 3 steps (save happens separately on confirm)
  String _progressMessage = '';
  String? _progressDetail;
  int? _analysisElapsedMs; // Time taken for AI analysis

  // Rainbow colors for nutrition values
  static const caloriesColor = AppColors.textPrimary;
  static const proteinColor = AppColors.textSecondary;
  static const carbsColor = AppColors.textMuted;
  static const fatColor = AppColors.textSecondary;
  static const fiberColor = AppColors.textMuted;

  @override
  void initState() {
    super.initState();
    // Listen for focus changes to scroll when keyboard appears
    _textFieldFocusNode.addListener(_onFocusChange);
    // Initialize speech recognition
    _initSpeech();
  }

  @override
  void dispose() {
    _textFieldFocusNode.removeListener(_onFocusChange);
    _textFieldFocusNode.dispose();
    _scrollController.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onStatus: (status) {
          debugPrint('🎤 Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            if (mounted) {
              setState(() => _isListening = false);
            }
          }
        },
        onError: (error) {
          debugPrint('🎤 Speech error: $error');
          if (mounted) {
            setState(() => _isListening = false);
          }
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
            widget.controller.text = result.recognizedWords;
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
      // Delay to allow keyboard animation to complete
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _textFieldKey.currentContext != null) {
          // Scroll the text field into view
          Scrollable.ensureVisible(
            _textFieldKey.currentContext!,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
          );
        }
      });
    }
  }

  Future<void> _handleAnalyze() async {
    if (widget.controller.text.trim().isEmpty) return;

    debugPrint('🍎 [LogMeal] Starting analysis with streaming...');
    setState(() {
      _isAnalyzing = true;
      _currentStep = 0;
      _progressMessage = 'Starting analysis...';
      _progressDetail = null;
      _analysisElapsedMs = null; // Reset elapsed time
    });

    try {
      final repository = ref.read(nutritionRepositoryProvider);
      LogFoodResponse? response;

      // Use streaming for real-time progress updates (analyze-only, no save)
      await for (final progress in repository.analyzeFoodFromTextStreaming(
        userId: widget.userId,
        description: widget.controller.text.trim(),
        mealType: widget.mealType,
      )) {
        if (!mounted) return;

        if (progress.hasError) {
          setState(() {
            _isAnalyzing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${progress.message}'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        if (progress.isCompleted && progress.foodLog != null) {
          response = progress.foodLog;
          // Capture elapsed time when analysis completes
          setState(() {
            _analysisElapsedMs = progress.elapsedMs;
          });
          break;
        }

        // Update progress UI
        setState(() {
          _currentStep = progress.step;
          _totalSteps = progress.totalSteps;
          _progressMessage = progress.message;
          _progressDetail = progress.detail;
        });
      }

      debugPrint('🍎 [LogMeal] Streaming complete, response: $response');
      if (mounted && response != null) {
        setState(() {
          _isAnalyzing = false;
          _analyzedResponse = response;
        });
        debugPrint('🍎 [LogMeal] _analyzedResponse set to: $_analyzedResponse');
      } else if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    } catch (e) {
      debugPrint('🍎 [LogMeal] Streaming error: $e');
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleEdit() {
    setState(() {
      _analyzedResponse = null;
      _analysisElapsedMs = null;
    });
  }

  /// Handle weight change for a food item - recalculates totals
  void _handleFoodItemWeightChange(int index, FoodItemRanking updatedItem) {
    if (_analyzedResponse == null) return;

    // Update the food item in the list
    final currentItems = List<Map<String, dynamic>>.from(_analyzedResponse!.foodItems);
    if (index < 0 || index >= currentItems.length) return;

    currentItems[index] = updatedItem.toJson();

    // Recalculate totals from all items
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

    // Create updated response with new values
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

    setState(() {
      _isSaving = true;
    });

    try {
      final repository = ref.read(nutritionRepositoryProvider);

      // Actually save the analyzed food to the database
      await repository.logFoodDirect(
        userId: widget.userId,
        mealType: widget.mealType,
        analyzedFood: _analyzedResponse!,
        sourceType: widget.sourceType,
      );

      if (mounted) {
        setState(() => _isSaving = false);
        // Award XP for daily goal
        ref.read(xpProvider.notifier).markMealLogged();
        // Call parent's onLog for any additional handling (fasting, navigation, etc.)
        widget.onLog(_analyzedResponse!);
      }
    } catch (e) {
      debugPrint('❌ [LogMeal] Error saving food: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save meal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleSaveAsFavorite() async {
    debugPrint('⭐ [SaveFood] _handleSaveAsFavorite called');
    debugPrint('⭐ [SaveFood] _analyzedResponse: ${_analyzedResponse != null ? "present" : "NULL"}');
    debugPrint('⭐ [SaveFood] _isSaving: $_isSaving');

    if (_isSaving) {
      debugPrint('⭐ [SaveFood] Already saving, returning');
      return;
    }

    if (_analyzedResponse == null) {
      debugPrint('❌ [SaveFood] No analyzed response to save');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please analyze the food first before saving'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repository = ref.read(nutritionRepositoryProvider);
      final description = widget.controller.text.trim();

      debugPrint('⭐ [SaveFood] Creating SaveFoodRequest...');
      debugPrint('⭐ [SaveFood] Food items count: ${_analyzedResponse!.foodItems.length}');

      final request = SaveFoodRequest.fromLogResponse(
        _analyzedResponse!,
        description.length > 50 ? '${description.substring(0, 50)}...' : description,
        description: description,
        sourceType: widget.sourceType,
        barcode: widget.barcode,
        imageUrl: widget.imageUrl,
      );

      debugPrint('⭐ [SaveFood] Request created, calling saveFood API...');
      debugPrint('⭐ [SaveFood] Request JSON: ${request.toJson()}');

      await repository.saveFood(
        userId: widget.userId,
        request: request,
      );

      debugPrint('✅ [SaveFood] Food saved successfully!');

      if (mounted) {
        setState(() {
          _isSaved = true;
          _isSaving = false;
        });
        final bottomPadding = MediaQuery.of(context).padding.bottom;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.star, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Saved to favorites!'),
              ],
            ),
            backgroundColor: AppColors.textMuted,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: bottomPadding + 100, // Clear the floating nav bar
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [SaveFood] Error saving food: $e');
      debugPrint('❌ [SaveFood] Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _appendText(String text) {
    if (widget.controller.text.isNotEmpty && !widget.controller.text.endsWith(', ')) {
      widget.controller.text += ', ';
    }
    widget.controller.text += text;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    // Use orange as the primary accent color
    const orange = Color(0xFFF97316);

    // If we have analyzed nutrition, show the preview
    if (_analyzedResponse != null) {
      return _buildNutritionPreview(isDark, textPrimary, textMuted, textSecondary, elevated, orange);
    }

    // Show streaming progress when analyzing
    if (_isAnalyzing) {
      return _FoodAnalysisLoadingIndicator(
        currentStep: _currentStep,
        totalSteps: _totalSteps,
        progressMessage: _progressMessage,
        progressDetail: _progressDetail,
        isDark: isDark,
      );
    }

    // Simple AI-first describe input
    return SingleChildScrollView(
      controller: _scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text input field with voice button
          Container(
            key: _textFieldKey,
            decoration: BoxDecoration(
              color: elevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isListening
                    ? orange
                    : widget.controller.text.trim().isNotEmpty
                        ? orange
                        : (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
                width: (_isListening || widget.controller.text.trim().isNotEmpty) ? 1.5 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _textFieldFocusNode,
                    maxLines: 3,
                    minLines: 2,
                    style: TextStyle(color: textPrimary, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: _isListening
                          ? 'Listening...'
                          : 'Describe what you ate...\ne.g., "chicken with rice"',
                      hintStyle: TextStyle(
                        color: _isListening ? orange : textMuted,
                        fontSize: 14,
                        fontStyle: _isListening ? FontStyle.italic : FontStyle.normal,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                // Voice input button
                Padding(
                  padding: const EdgeInsets.only(top: 8, right: 8),
                  child: GestureDetector(
                    onTap: _toggleVoiceInput,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _isListening
                            ? orange
                            : orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _isListening ? Icons.stop : Icons.mic,
                        size: 22,
                        color: _isListening ? Colors.white : orange,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Listening indicator
          if (_isListening)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(orange),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Speak now... tap mic to stop',
                    style: TextStyle(fontSize: 12, color: orange, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Analyze with AI button - always visible when there's text
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.controller.text.trim().isNotEmpty ? _handleAnalyze : null,
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text(
                'Analyze with AI',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: orange,
                foregroundColor: Colors.white,
                disabledBackgroundColor: orange.withValues(alpha: 0.3),
                disabledForegroundColor: Colors.white54,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Helper text
          Text(
            'AI will identify foods and estimate nutrition automatically',
            style: TextStyle(fontSize: 12, color: textMuted),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Quick suggestions
          Text(
            'Quick suggestions',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _QuickSuggestion(label: 'Coffee', onTap: () => _appendText('coffee'), isDark: isDark),
              _QuickSuggestion(label: '2 Eggs', onTap: () => _appendText('2 eggs'), isDark: isDark),
              _QuickSuggestion(label: 'Toast', onTap: () => _appendText('toast with butter'), isDark: isDark),
              _QuickSuggestion(label: 'Salad', onTap: () => _appendText('mixed salad'), isDark: isDark),
              _QuickSuggestion(label: 'Chicken', onTap: () => _appendText('grilled chicken breast'), isDark: isDark),
              _QuickSuggestion(label: 'Rice', onTap: () => _appendText('1 cup rice'), isDark: isDark),
              _QuickSuggestion(label: 'Protein shake', onTap: () => _appendText('protein shake'), isDark: isDark),
              _QuickSuggestion(label: 'Sandwich', onTap: () => _appendText('turkey sandwich'), isDark: isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionPreview(
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color textSecondary,
    Color elevated,
    Color teal,
  ) {
    final response = _analyzedResponse!;
    final description = widget.controller.text.trim();

    return Column(
      children: [
        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Food description at top with Goal Score
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Food description - show original query AND matched food
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
                            // Original search query
                            Row(
                              children: [
                                Icon(Icons.search, size: 14, color: textMuted),
                                const SizedBox(width: 6),
                                Text(
                                  'You searched:',
                                  style: TextStyle(
                                    color: textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              description,
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            // Matched food items with quantities
                            Row(
                              children: [
                                Icon(Icons.restaurant, size: 14, color: isDark ? AppColors.teal : AppColorsLight.teal),
                                const SizedBox(width: 6),
                                Text(
                                  'Found:',
                                  style: TextStyle(
                                    color: isDark ? AppColors.teal : AppColorsLight.teal,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Display matched food items with their amounts
                            ...response.foodItemsRanked.take(3).map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(
                                item.amount != null && item.amount!.isNotEmpty
                                    ? '${item.name} (${item.amount})'
                                    : item.name,
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            )),
                            if (response.foodItemsRanked.length > 3)
                              Text(
                                '+${response.foodItemsRanked.length - 3} more items',
                                style: TextStyle(
                                  color: textMuted,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    // Goal Score (if available)
                    if (response.overallMealScore != null) ...[
                      const SizedBox(width: 10),
                      _CompactGoalScore(
                        score: response.overallMealScore!,
                        isDark: isDark,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // AI Estimated header row
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'AI Estimated',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
                    ),
                    // Show analysis time if available
                    if (_analysisElapsedMs != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '(${(_analysisElapsedMs! / 1000).toStringAsFixed(1)}s)',
                        style: TextStyle(fontSize: 12, color: textMuted),
                      ),
                    ],
                    const Spacer(),
                    // Star button - larger tap area for better UX
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _isSaved || _isSaving ? null : () {
                        debugPrint('⭐ [StarButton] Tapped! _isSaved=$_isSaved, _isSaving=$_isSaving');
                        _handleSaveAsFavorite();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: _isSaving
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary),
                              )
                            : Icon(
                                _isSaved ? Icons.star : Icons.star_border,
                                size: 24,
                                color: _isSaved ? AppColors.yellow : textMuted,
                              ),
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

                // COMPACT MACROS ROW - All 4 in one row with animated calories
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: elevated,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // Animated calorie display - use coral/red for visibility
                      _AnimatedCalorieChip(
                        calories: response.totalCalories,
                        color: AppColors.coral,  // Red/coral for calories - visible in both themes
                      ),
                      _CompactMacroChip(
                        icon: Icons.fitness_center,
                        value: '${response.proteinG.toStringAsFixed(0)}g',
                        unit: 'Protein',
                        color: AppColors.yellow,  // Gold for protein
                      ),
                      _CompactMacroChip(
                        icon: Icons.grain,
                        value: '${response.carbsG.toStringAsFixed(0)}g',
                        unit: 'Carbs',
                        color: AppColors.green,  // Green for carbs
                      ),
                      _CompactMacroChip(
                        icon: Icons.opacity,
                        value: '${response.fatG.toStringAsFixed(0)}g',
                        unit: 'Fat',
                        color: AppColors.quickActionWater,  // Blue for fat
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Mood tracking (compact)
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

                // Collapsible Food Items Section (with updated colors)
                if (response.foodItems.isNotEmpty)
                  _CollapsibleFoodItemsSection(
                    foodItems: response.foodItemsRanked,
                    isDark: isDark,
                    onItemWeightChanged: (index, updatedItem) {
                      _handleFoodItemWeightChange(index, updatedItem);
                    },
                  ),
                if (response.foodItems.isNotEmpty)
                  const SizedBox(height: 12),

                // Micronutrients Section (collapsible)
                if (_hasMicronutrients(response))
                  _MicronutrientsSection(response: response, isDark: isDark),
                if (_hasMicronutrients(response))
                  const SizedBox(height: 12),

                // AI Suggestion Card (if available)
                if (response.aiSuggestion != null ||
                    (response.encouragements != null && response.encouragements!.isNotEmpty) ||
                    (response.warnings != null && response.warnings!.isNotEmpty))
                  _AISuggestionCard(
                    suggestion: response.aiSuggestion,
                    encouragements: response.encouragements,
                    warnings: response.warnings,
                    recommendedSwap: response.recommendedSwap,
                    isDark: isDark,
                  ),

                Text(
                  'AI estimates based on your description',
                  style: TextStyle(fontSize: 11, color: textMuted, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),

        // Fixed Log button at bottom
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _handleLog,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(Icons.check, size: 18),
              label: Text(
                _isSaving ? 'Saving...' : 'Log This Meal',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF97316), // Orange accent
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFF97316).withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Check if response has any micronutrient data
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
}

/// Collapsible micronutrients section showing vitamins & minerals
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
          // Header - tap to expand/collapse
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.science_outlined, size: 20, color: AppColors.purple),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Vitamins & Minerals',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: textMuted,
                  ),
                ],
              ),
            ),
          ),
          // Expandable content
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

    // Add items only if they have values
    if (response.sugarG != null) {
      items.add(_buildMicroRow('Sugar', '${response.sugarG!.toStringAsFixed(1)}g', Colors.pink, textPrimary, textMuted));
    }
    if (response.saturatedFatG != null) {
      items.add(_buildMicroRow('Saturated Fat', '${response.saturatedFatG!.toStringAsFixed(1)}g', Colors.orange, textPrimary, textMuted));
    }
    if (response.cholesterolMg != null) {
      items.add(_buildMicroRow('Cholesterol', '${response.cholesterolMg!.toStringAsFixed(0)}mg', Colors.red, textPrimary, textMuted));
    }
    if (response.sodiumMg != null) {
      items.add(_buildMicroRow('Sodium', '${response.sodiumMg!.toStringAsFixed(0)}mg', Colors.amber, textPrimary, textMuted));
    }
    if (response.potassiumMg != null) {
      items.add(_buildMicroRow('Potassium', '${response.potassiumMg!.toStringAsFixed(0)}mg', Colors.teal, textPrimary, textMuted));
    }
    if (response.calciumMg != null) {
      items.add(_buildMicroRow('Calcium', '${response.calciumMg!.toStringAsFixed(0)}mg', Colors.blue, textPrimary, textMuted));
    }
    if (response.ironMg != null) {
      items.add(_buildMicroRow('Iron', '${response.ironMg!.toStringAsFixed(1)}mg', Colors.brown, textPrimary, textMuted));
    }
    if (response.vitaminAIu != null) {
      items.add(_buildMicroRow('Vitamin A', '${response.vitaminAIu!.toStringAsFixed(0)} IU', Colors.orange, textPrimary, textMuted));
    }
    if (response.vitaminCMg != null) {
      items.add(_buildMicroRow('Vitamin C', '${response.vitaminCMg!.toStringAsFixed(0)}mg', Colors.yellow.shade700, textPrimary, textMuted));
    }
    if (response.vitaminDIu != null) {
      items.add(_buildMicroRow('Vitamin D', '${response.vitaminDIu!.toStringAsFixed(0)} IU', Colors.amber.shade600, textPrimary, textMuted));
    }

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          'No micronutrient data available',
          style: TextStyle(fontSize: 13, color: textMuted, fontStyle: FontStyle.italic),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(children: items),
    );
  }

  Widget _buildMicroRow(String name, String value, Color color, Color textPrimary, Color textMuted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: TextStyle(fontSize: 13, color: textMuted),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickSuggestion extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  const _QuickSuggestion({required this.label, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cardBorder),
        ),
        child: Text('+ $label', style: TextStyle(fontSize: 12, color: textSecondary)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Food Search Input - Combines search bar with text input
// ─────────────────────────────────────────────────────────────────

class _FoodSearchInput extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final String userId;
  final bool isDark;
  final Function(String query)? onSearch;
  final Function(search.FoodSearchResult result)? onResultSelected;
  final FoodSearchFilter selectedFilter;
  final Function(FoodSearchFilter filter)? onFilterChanged;

  const _FoodSearchInput({
    required this.controller,
    required this.userId,
    required this.isDark,
    this.onSearch,
    this.onResultSelected,
    required this.selectedFilter,
    this.onFilterChanged,
  });

  @override
  ConsumerState<_FoodSearchInput> createState() => _FoodSearchInputState();
}

class _FoodSearchInputState extends ConsumerState<_FoodSearchInput> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);

    // Listen to controller changes for search
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _onTextChanged() {
    final query = widget.controller.text.trim();
    final searchService = ref.read(search.foodSearchServiceProvider);
    searchService.search(query, widget.userId);
    widget.onSearch?.call(query);
  }

  void _clearSearch() {
    widget.controller.clear();
    final searchService = ref.read(search.foodSearchServiceProvider);
    searchService.cancel();
    widget.onSearch?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final searchState = ref.watch(search.foodSearchStateProvider);

    final backgroundColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final borderColor = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accentColor = isDark ? AppColors.cyan : AppColorsLight.cyan;

    final isLoading = searchState.maybeWhen(
      data: (state) => state is search.FoodSearchLoading,
      orElse: () => false,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search/input bar
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isFocused ? accentColor : borderColor,
              width: _isFocused ? 2 : 1,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: accentColor.withOpacity(0.2),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Search icon or loading indicator
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: isLoading
                      ? SizedBox(
                          key: const ValueKey('loading'),
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                          ),
                        )
                      : Icon(
                          key: const ValueKey('search'),
                          Icons.search_rounded,
                          color: _isFocused ? accentColor : textMuted,
                          size: 22,
                        ),
                ),
              ),

              // Text field
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search foods or describe your meal...',
                    hintStyle: TextStyle(
                      color: textMuted,
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                  textInputAction: TextInputAction.search,
                  maxLines: 1,
                ),
              ),

              // Clear button
              if (widget.controller.text.isNotEmpty)
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: textMuted,
                    size: 20,
                  ),
                  onPressed: _clearSearch,
                  splashRadius: 20,
                )
              else
                const SizedBox(width: 8),
            ],
          ),
        ),

        // Filter chips
        const SizedBox(height: 12),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: FoodSearchFilter.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final filter = FoodSearchFilter.values[index];
              final isSelected = widget.selectedFilter == filter;

              return _buildFilterChip(
                label: filter.label,
                isSelected: isSelected,
                onTap: () => widget.onFilterChanged?.call(filter),
                accentColor: accentColor,
                isDark: isDark,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color accentColor,
    required bool isDark,
  }) {
    final backgroundColor = isSelected
        ? accentColor
        : isDark
            ? AppColors.elevated
            : AppColorsLight.elevated;
    final textColor = isSelected
        ? Colors.white
        : isDark
            ? AppColors.textSecondary
            : AppColorsLight.textSecondary;
    final borderColor = isSelected
        ? accentColor
        : isDark
            ? AppColors.cardBorder
            : AppColorsLight.cardBorder;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Scan Tab
// ─────────────────────────────────────────────────────────────────

class _ScanTab extends StatefulWidget {
  final void Function(String) onBarcodeDetected;
  final bool isDark;

  const _ScanTab({required this.onBarcodeDetected, required this.isDark});

  @override
  State<_ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends State<_ScanTab> {
  MobileScannerController? _controller;
  bool _hasDetected = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      // Only detect product barcode formats (not QR codes, URLs, etc.)
      formats: [
        BarcodeFormat.ean13,    // 13-digit European Article Number
        BarcodeFormat.ean8,     // 8-digit EAN
        BarcodeFormat.upcA,     // 12-digit Universal Product Code
        BarcodeFormat.upcE,     // 8-digit compressed UPC
      ],
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

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: MobileScanner(
                  controller: _controller,
                  onDetect: (capture) {
                    if (_hasDetected) return;
                    for (final barcode in capture.barcodes) {
                      final value = barcode.rawValue;
                      // Validate: must be 8-14 digits (product barcodes)
                      if (value != null &&
                          RegExp(r'^\d{8,14}$').hasMatch(value)) {
                        _hasDetected = true;
                        widget.onBarcodeDetected(value);
                        break;
                      }
                    }
                  },
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
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                'Scan a Barcode',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Point your camera at a product barcode',
                style: TextStyle(fontSize: 14, color: textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Quick Tab
// ─────────────────────────────────────────────────────────────────

class _QuickTab extends ConsumerStatefulWidget {
  final String userId;
  final MealType mealType;
  final VoidCallback onLogged;
  final bool isDark;

  const _QuickTab({
    required this.userId,
    required this.mealType,
    required this.onLogged,
    required this.isDark,
  });

  @override
  ConsumerState<_QuickTab> createState() => _QuickTabState();
}

class _QuickTabState extends ConsumerState<_QuickTab> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all'; // all, saved, recent
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      setState(() => _isSearching = true);
      final service = ref.read(search.foodSearchServiceProvider);
      service.search(query, widget.userId);
    } else {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _handleResultSelected(search.FoodSearchResult result) async {
    // Log the selected food
    final repository = ref.read(nutritionRepositoryProvider);
    try {
      await repository.logFoodFromText(
        userId: widget.userId,
        description: result.name,
        mealType: widget.mealType.value,
      );
      // Award XP for daily goal
      ref.read(xpProvider.notifier).markMealLogged();
      widget.onLogged();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to log: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textMuted = widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = widget.isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final elevated = widget.isDark ? AppColors.elevated : AppColorsLight.elevated;
    final teal = widget.isDark ? AppColors.teal : AppColorsLight.teal;
    final cardBorder = widget.isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Container(
            decoration: BoxDecoration(
              color: elevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _isSearching ? teal : cardBorder),
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: widget.isDark ? AppColors.textPrimary : AppColorsLight.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search saved & recent foods...',
                hintStyle: TextStyle(color: textMuted, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: textMuted),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: textMuted),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _isSearching = false);
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ),

        // Filter chips
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              _FilterChip(
                label: 'All',
                isSelected: _selectedFilter == 'all',
                onTap: () => setState(() => _selectedFilter = 'all'),
                isDark: widget.isDark,
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Saved',
                isSelected: _selectedFilter == 'saved',
                onTap: () => setState(() => _selectedFilter = 'saved'),
                isDark: widget.isDark,
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Recent',
                isSelected: _selectedFilter == 'recent',
                onTap: () => setState(() => _selectedFilter = 'recent'),
                isDark: widget.isDark,
              ),
            ],
          ),
        ),

        // Results
        Expanded(
          child: _isSearching
              ? _buildSearchResults()
              : _buildDefaultList(),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    final searchState = ref.watch(search.foodSearchStateProvider);

    return searchState.when(
      data: (state) {
        switch (state) {
          case search.FoodSearchLoading():
            return const Center(child: CircularProgressIndicator());

          case search.FoodSearchResults(:final saved, :final recent, :final database, :final query):
            final allResults = <search.FoodSearchResult>[];
            if (_selectedFilter == 'all' || _selectedFilter == 'saved') {
              allResults.addAll(saved);
            }
            if (_selectedFilter == 'all' || _selectedFilter == 'recent') {
              allResults.addAll(recent);
            }
            if (_selectedFilter == 'all') {
              allResults.addAll(database);
            }

            if (allResults.isEmpty) {
              return _buildEmptySearchState(query);
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: allResults.length,
              itemBuilder: (context, index) {
                final result = allResults[index];
                return _QuickFoodItem(
                  name: result.name,
                  calories: result.calories,
                  subtitle: result.source.label,
                  onTap: () => _handleResultSelected(result),
                  isDark: widget.isDark,
                );
              },
            );

          case search.FoodSearchError(:final message):
            return Center(
              child: Text('Error: $message', style: const TextStyle(color: Colors.red)),
            );

          case search.FoodSearchInitial():
            return const SizedBox.shrink();
        }
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildEmptySearchState(String query) {
    final textMuted = widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = widget.isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 48, color: textMuted),
          const SizedBox(height: 16),
          Text('No saved foods match "$query"', style: TextStyle(fontSize: 16, color: textSecondary)),
          const SizedBox(height: 8),
          Text('Use the Describe tab to log new foods', style: TextStyle(fontSize: 14, color: textMuted)),
        ],
      ),
    );
  }

  Widget _buildDefaultList() {
    final state = ref.watch(nutritionProvider);
    final textMuted = widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = widget.isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    // Build recent items from food logs
    final recentItems = <String, Map<String, dynamic>>{};
    for (final log in state.recentLogs.take(20)) {
      for (final item in log.foodItems) {
        if (!recentItems.containsKey(item.name)) {
          recentItems[item.name] = {
            'name': item.name,
            'calories': item.calories ?? 0,
          };
        }
      }
    }

    // Load saved foods based on filter
    if (_selectedFilter == 'saved' || _selectedFilter == 'all') {
      return FutureBuilder<SavedFoodsResponse>(
        future: ref.read(nutritionRepositoryProvider).getSavedFoods(
          userId: widget.userId,
          limit: 20,
        ),
        builder: (context, snapshot) {
          final savedFoods = snapshot.data?.items ?? [];

          // Build the list based on filter
          final List<Widget> children = [];

          // Add saved foods section
          if ((_selectedFilter == 'all' || _selectedFilter == 'saved') && savedFoods.isNotEmpty) {
            children.add(
              Text(
                'SAVED FOODS',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textMuted, letterSpacing: 1.5),
              ),
            );
            children.add(const SizedBox(height: 12));
            children.addAll(savedFoods.take(10).map((food) => _QuickFoodItem(
              name: food.name,
              calories: food.totalCalories ?? 0,
              subtitle: food.description,
              onTap: () async {
                final repository = ref.read(nutritionRepositoryProvider);
                try {
                  await repository.logFoodFromText(
                    userId: widget.userId,
                    description: food.name,
                    mealType: widget.mealType.value,
                  );
                  // Award XP for daily goal
                  ref.read(xpProvider.notifier).markMealLogged();
                  widget.onLogged();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to log: $e')),
                    );
                  }
                }
              },
              isDark: widget.isDark,
            )));
            if (_selectedFilter == 'all' && recentItems.isNotEmpty) {
              children.add(const SizedBox(height: 24));
            }
          }

          // Add recent items section
          if ((_selectedFilter == 'all' || _selectedFilter == 'recent') && recentItems.isNotEmpty) {
            children.add(
              Text(
                'RECENT ITEMS',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textMuted, letterSpacing: 1.5),
              ),
            );
            children.add(const SizedBox(height: 12));
            children.addAll(recentItems.values.take(10).map((item) => _QuickFoodItem(
              name: item['name'] as String,
              calories: item['calories'] as int,
              onTap: () async {
                final repository = ref.read(nutritionRepositoryProvider);
                try {
                  await repository.logFoodFromText(
                    userId: widget.userId,
                    description: item['name'] as String,
                    mealType: widget.mealType.value,
                  );
                  // Award XP for daily goal
                  ref.read(xpProvider.notifier).markMealLogged();
                  widget.onLogged();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to log: $e')),
                    );
                  }
                }
              },
              isDark: widget.isDark,
            )));
          }

          // Empty state
          if (children.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _selectedFilter == 'saved' ? Icons.star_border : Icons.history,
                    size: 64,
                    color: textMuted,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _selectedFilter == 'saved' ? 'No saved foods' : 'No recent items',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedFilter == 'saved'
                      ? 'Star foods after logging to save them here'
                      : 'Log some meals to see them here',
                    style: TextStyle(fontSize: 14, color: textMuted),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: children,
          );
        },
      );
    }

    // Recent only filter
    if (recentItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: textMuted),
            const SizedBox(height: 16),
            Text(
              'No recent items',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textSecondary),
            ),
            const SizedBox(height: 8),
            Text('Log some meals to see them here', style: TextStyle(fontSize: 14, color: textMuted)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Text(
          'RECENT ITEMS',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textMuted, letterSpacing: 1.5),
        ),
        const SizedBox(height: 12),
        ...recentItems.values.take(10).map((item) => _QuickFoodItem(
              name: item['name'] as String,
              calories: item['calories'] as int,
              onTap: () async {
                final repository = ref.read(nutritionRepositoryProvider);
                try {
                  await repository.logFoodFromText(
                    userId: widget.userId,
                    description: item['name'] as String,
                    mealType: widget.mealType.value,
                  );
                  // Award XP for daily goal
                  ref.read(xpProvider.notifier).markMealLogged();
                  widget.onLogged();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to log: $e')),
                    );
                  }
                }
              },
              isDark: widget.isDark,
            )),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? teal : elevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? teal : (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : textMuted,
          ),
        ),
      ),
    );
  }
}

class _QuickFoodItem extends StatelessWidget {
  final String name;
  final int calories;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isDark;

  const _QuickFoodItem({
    required this.name,
    required this.calories,
    this.subtitle,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: elevated,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(fontSize: 12, color: textMuted),
                        ),
                      ],
                    ],
                  ),
                ),
                Text('$calories kcal', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: teal)),
                const SizedBox(width: 8),
                Icon(Icons.add_circle, color: teal, size: 24),
              ],
            ),
          ),
        ),
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
  bool _isExpanded = false;

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
