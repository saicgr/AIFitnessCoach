import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../core/constants/app_colors.dart';
import '../../data/models/nutrition.dart';
import '../../data/models/fasting.dart';
import '../../data/providers/fasting_provider.dart';
import '../../data/repositories/nutrition_repository.dart';
import '../../data/services/api_client.dart';
import '../../widgets/main_shell.dart';

/// Shows the log meal bottom sheet from anywhere in the app
Future<void> showLogMealSheet(BuildContext context, WidgetRef ref) async {
  debugPrint('showLogMealSheet: Starting...');
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final userId = await ref.read(apiClientProvider).getUserId();

  debugPrint('showLogMealSheet: userId=$userId, context.mounted=${context.mounted}');

  if (userId == null || !context.mounted) {
    debugPrint('showLogMealSheet: Aborting - userId is null or context not mounted');
    return;
  }

  // Hide nav bar while sheet is open
  ref.read(floatingNavBarVisibleProvider.notifier).state = false;

  debugPrint('showLogMealSheet: About to show modal bottom sheet');
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => LogMealSheet(userId: userId, isDark: isDark),
  );

  debugPrint('showLogMealSheet: Bottom sheet closed');
  // Show nav bar when sheet is closed
  ref.read(floatingNavBarVisibleProvider.notifier).state = true;
}

/// Bottom sheet for logging meals with multiple input methods
class LogMealSheet extends ConsumerStatefulWidget {
  final String userId;
  final bool isDark;

  const LogMealSheet({super.key, required this.userId, required this.isDark});

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

  // Restaurant mode state - shows confidence ranges instead of exact values
  bool _restaurantMode = false;
  LogFoodResponse? _pendingFoodLog; // Holds analyzed food when restaurant mode needs portion selection

  @override
  void initState() {
    super.initState();
    // Describe tab is now at index 0 (default)
    _tabController = TabController(length: 5, vsync: this, initialIndex: 0);
    _selectedMealType = _getDefaultMealType();
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
    _tabController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _isLoading = true;
        _error = null;
        _currentStep = 0;
        _progressMessage = 'Preparing image...';
        _progressDetail = null;
      });

      final repository = ref.read(nutritionRepositoryProvider);

      // Use streaming for real-time progress updates
      await for (final progress in repository.logFoodFromImageStreaming(
        userId: widget.userId,
        mealType: _selectedMealType.value,
        imageFile: File(image.path),
      )) {
        if (!mounted) return;

        if (progress.hasError) {
          setState(() {
            _isLoading = false;
            _error = progress.message;
          });
          return;
        }

        if (progress.isCompleted && progress.foodLog != null) {
          if (_restaurantMode) {
            // Show portion selector instead of logging directly
            setState(() {
              _pendingFoodLog = progress.foodLog;
              _isLoading = false;
            });
            return;
          }
          Navigator.pop(context);
          _showSuccessSnackbar(progress.foodLog!.totalCalories);
          ref.read(nutritionProvider.notifier).loadTodaySummary(widget.userId);
          return;
        }

        // Update progress UI
        setState(() {
          _currentStep = progress.step;
          _totalSteps = progress.totalSteps;
          _progressMessage = progress.message;
          _progressDetail = progress.detail;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _logFromText() async {
    final description = _descriptionController.text.trim();
    if (description.isEmpty) return;

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

      // Use streaming for real-time progress updates
      await for (final progress in repository.logFoodFromTextStreaming(
        userId: widget.userId,
        description: description,
        mealType: _selectedMealType.value,
      )) {
        if (!mounted) return;

        if (progress.hasError) {
          setState(() {
            _isLoading = false;
            _error = progress.message;
          });
          return;
        }

        if (progress.isCompleted && progress.foodLog != null) {
          response = progress.foodLog;
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

      if (mounted && response != null) {
        setState(() => _isLoading = false);

        if (_restaurantMode) {
          // Show portion selector instead of confirmation dialog
          setState(() {
            _pendingFoodLog = response;
          });
          return;
        }

        // Show rainbow confirmation dialog
        final confirmed = await _showRainbowNutritionConfirmation(response, description);
        if (confirmed == true && mounted) {
          Navigator.pop(context);
          _showSuccessSnackbar(response.totalCalories);
          ref.read(nutritionProvider.notifier).loadTodaySummary(widget.userId);
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  /// Log an already analyzed food response
  void _logAnalyzedFood(LogFoodResponse response) async {
    // Check if there's an active fast that should be ended
    final fastingState = ref.read(fastingProvider);
    if (fastingState.activeFast != null && response.totalCalories > 50) {
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

  /// Log food with portion size multiplier (for restaurant mode)
  Future<void> _logWithPortion(double portionMultiplier) async {
    if (_pendingFoodLog == null) return;

    setState(() {
      _isLoading = true;
      _progressMessage = 'Logging meal...';
    });

    try {
      final repository = ref.read(nutritionRepositoryProvider);

      // Create adjusted food items with multiplied nutrition
      final adjustedItems = _pendingFoodLog!.foodItems.map((item) {
        final adjustedCalories = ((item['calories'] ?? 0) * portionMultiplier).round();
        final adjustedProtein = ((item['protein_g'] ?? 0) * portionMultiplier).round();
        final adjustedCarbs = ((item['carbs_g'] ?? 0) * portionMultiplier).round();
        final adjustedFat = ((item['fat_g'] ?? 0) * portionMultiplier).round();

        return {
          ...item,
          'calories': adjustedCalories,
          'protein_g': adjustedProtein,
          'carbs_g': adjustedCarbs,
          'fat_g': adjustedFat,
          'portion_adjusted': true,
          'portion_multiplier': portionMultiplier,
        };
      }).toList();

      // Calculate new totals
      final adjustedCalories = (_pendingFoodLog!.totalCalories * portionMultiplier).round();
      final adjustedProtein = (_pendingFoodLog!.proteinG * portionMultiplier).round();
      final adjustedCarbs = (_pendingFoodLog!.carbsG * portionMultiplier).round();
      final adjustedFat = (_pendingFoodLog!.fatG * portionMultiplier).round();

      // Log the adjusted food
      await repository.logAdjustedFood(
        userId: widget.userId,
        mealType: _selectedMealType.value,
        foodItems: adjustedItems,
        totalCalories: adjustedCalories,
        totalProtein: adjustedProtein,
        totalCarbs: adjustedCarbs,
        totalFat: adjustedFat,
        sourceType: 'restaurant',
        notes: 'Portion: ${_getPortionLabel(portionMultiplier)}',
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _pendingFoodLog = null;
        });
        Navigator.pop(context);
        _showSuccessSnackbar(adjustedCalories);
        ref.read(nutritionProvider.notifier).loadTodaySummary(widget.userId);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  String _getPortionLabel(double multiplier) {
    if (multiplier <= 0.75) return 'Light portion';
    if (multiplier >= 1.25) return 'Large portion';
    return 'Typical portion';
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

  Future<bool?> _showRainbowNutritionConfirmation(LogFoodResponse response, String description) {
    final isDark = widget.isDark;
    final nearBlack = isDark ? AppColors.nearBlack : AppColorsLight.nearWhite;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    // Rainbow colors for nutrition values
    const caloriesColor = Color(0xFFFF6B6B);  // Red/Coral
    const proteinColor = Color(0xFFFFD93D);   // Yellow/Gold
    const carbsColor = Color(0xFF6BCB77);     // Green
    const fatColor = Color(0xFF4D96FF);       // Blue
    const fiberColor = Color(0xFF9B59B6);     // Purple

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: nearBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Color(0xFFFFD93D), size: 28),
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Food description
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
                    child: Text(
                      description,
                      style: TextStyle(color: textPrimary, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Rainbow nutrition grid
            _RainbowNutritionCard(
              icon: Icons.local_fire_department,
              label: 'Calories',
              value: '${response.totalCalories}',
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
                    value: response.proteinG.toStringAsFixed(1),
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
                    value: response.carbsG.toStringAsFixed(1),
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
                    value: response.fatG.toStringAsFixed(1),
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
                    value: (response.fiberG ?? 0).toStringAsFixed(1),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6BCB77),
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
      ),
    );
  }

  Future<void> _handleBarcodeScan(String barcode) async {
    if (_hasScanned) return;
    _hasScanned = true;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = ref.read(nutritionRepositoryProvider);
      final product = await repository.lookupBarcode(barcode);

      if (mounted) {
        final confirmed = await _showProductConfirmation(product);
        if (confirmed == true) {
          final response = await repository.logFoodFromBarcode(
            userId: widget.userId,
            barcode: barcode,
            mealType: _selectedMealType.value,
          );

          if (mounted) {
            Navigator.pop(context);
            _showSuccessSnackbar(response.totalCalories);
            ref.read(nutritionProvider.notifier).loadTodaySummary(widget.userId);
          }
        } else {
          setState(() {
            _isLoading = false;
            _hasScanned = false;
          });
        }
      }
    } catch (e) {
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
        content: Column(
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
          ],
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Logged $calories kcal'),
        backgroundColor: widget.isDark ? AppColors.success : AppColorsLight.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final nearBlack = isDark ? AppColors.nearBlack : AppColorsLight.nearWhite;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final orange = isDark ? AppColors.orange : AppColorsLight.orange;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: nearBlack,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                      onTap: () => setState(() => _selectedMealType = type),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? teal.withValues(alpha: 0.2) : elevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? teal : cardBorder,
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
                                color: isSelected ? teal : textSecondary,
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

          // Restaurant mode toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GestureDetector(
              onTap: () => setState(() => _restaurantMode = !_restaurantMode),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _restaurantMode ? orange.withValues(alpha: 0.15) : elevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _restaurantMode ? orange : cardBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.restaurant,
                      size: 18,
                      color: _restaurantMode ? orange : textMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Restaurant Mode',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _restaurantMode ? orange : textMuted,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 40,
                      height: 22,
                      decoration: BoxDecoration(
                        color: _restaurantMode ? orange : cardBorder,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: AnimatedAlign(
                        duration: const Duration(milliseconds: 200),
                        alignment: _restaurantMode ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          width: 18,
                          height: 18,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (_restaurantMode)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Text(
                'Portions are estimated - pick the size that matches your meal',
                style: TextStyle(fontSize: 11, color: textMuted),
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
                color: teal,
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
                Tab(icon: Icon(Icons.mic, size: 18), text: 'Voice'),
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

          // Restaurant portion selector
          if (_pendingFoodLog != null && _restaurantMode)
            Expanded(
              child: _RestaurantPortionSelector(
                foodLog: _pendingFoodLog!,
                isDark: isDark,
                onSelectPortion: _logWithPortion,
                onCancel: () => setState(() => _pendingFoodLog = null),
              ),
            )
          // Loading indicator with streaming progress
          else if (_isLoading)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animated progress indicator with smooth transitions
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: _totalSteps > 0 ? _currentStep / _totalSteps : 0),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                        builder: (context, value, child) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 80,
                                height: 80,
                                child: CircularProgressIndicator(
                                  value: value > 0 ? value : null,
                                  strokeWidth: 6,
                                  color: teal,
                                  backgroundColor: teal.withValues(alpha: 0.2),
                                ),
                              ),
                              Text(
                                '$_currentStep/$_totalSteps',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: teal,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _progressMessage.isNotEmpty ? _progressMessage : 'Analyzing your food...',
                          key: ValueKey(_progressMessage),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (_progressDetail != null) ...[
                        const SizedBox(height: 8),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            _progressDetail!,
                            key: ValueKey(_progressDetail),
                            style: TextStyle(fontSize: 13, color: textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      // Animated progress bar
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: _totalSteps > 0 ? _currentStep / _totalSteps : 0),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                        builder: (context, value, child) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: value > 0 ? value : null,
                              backgroundColor: teal.withValues(alpha: 0.2),
                              valueColor: AlwaysStoppedAnimation(teal),
                              minHeight: 6,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
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
                  _VoiceTab(
                    onSubmit: (text) {
                      _descriptionController.text = text;
                      _logFromText();
                    },
                    isDark: isDark,
                  ),
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

  // Mood tracking state
  FoodMood? _moodBefore;
  FoodMood? _moodAfter;
  int _energyLevel = 3; // Default to middle (1-5 scale)

  // Streaming progress state
  int _currentStep = 0;
  int _totalSteps = 4;
  String _progressMessage = '';
  String? _progressDetail;

  // Rainbow colors for nutrition values
  static const caloriesColor = Color(0xFFFF6B6B);
  static const proteinColor = Color(0xFFFFD93D);
  static const carbsColor = Color(0xFF6BCB77);
  static const fatColor = Color(0xFF4D96FF);
  static const fiberColor = Color(0xFF9B59B6);

  Future<void> _handleAnalyze() async {
    if (widget.controller.text.trim().isEmpty) return;

    debugPrint('🍎 [LogMeal] Starting analysis with streaming...');
    setState(() {
      _isAnalyzing = true;
      _currentStep = 0;
      _progressMessage = 'Starting analysis...';
      _progressDetail = null;
    });

    try {
      final repository = ref.read(nutritionRepositoryProvider);
      LogFoodResponse? response;

      // Use streaming for real-time progress updates
      await for (final progress in repository.logFoodFromTextStreaming(
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
    setState(() => _analyzedResponse = null);
  }

  void _handleLog() {
    if (_analyzedResponse != null) {
      widget.onLog(_analyzedResponse!);
    }
  }

  Future<void> _handleSaveAsFavorite() async {
    if (_analyzedResponse == null || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      final repository = ref.read(nutritionRepositoryProvider);
      final description = widget.controller.text.trim();

      final request = SaveFoodRequest.fromLogResponse(
        _analyzedResponse!,
        description.length > 50 ? '${description.substring(0, 50)}...' : description,
        description: description,
        sourceType: widget.sourceType,
        barcode: widget.barcode,
        imageUrl: widget.imageUrl,
      );

      await repository.saveFood(
        userId: widget.userId,
        request: request,
      );

      if (mounted) {
        setState(() {
          _isSaved = true;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.star, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Saved to favorites!'),
              ],
            ),
            backgroundColor: const Color(0xFF6BCB77),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving food: $e');
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
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

    // If we have analyzed nutrition, show the preview
    if (_analyzedResponse != null) {
      return _buildNutritionPreview(isDark, textPrimary, textMuted, textSecondary, elevated, teal);
    }

    // Show streaming progress when analyzing
    if (_isAnalyzing) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated progress indicator with smooth transitions
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: _totalSteps > 0 ? _currentStep / _totalSteps : 0),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          value: value > 0 ? value : null,
                          strokeWidth: 6,
                          color: teal,
                          backgroundColor: teal.withValues(alpha: 0.2),
                        ),
                      ),
                      Text(
                        '$_currentStep/$_totalSteps',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: teal,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _progressMessage.isNotEmpty ? _progressMessage : 'Analyzing your food...',
                  key: ValueKey(_progressMessage),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (_progressDetail != null) ...[
                const SizedBox(height: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _progressDetail!,
                    key: ValueKey(_progressDetail),
                    style: TextStyle(fontSize: 13, color: textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // Animated progress bar
              SizedBox(
                width: 200,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: _totalSteps > 0 ? _currentStep / _totalSteps : 0),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: value > 0 ? value : null,
                        backgroundColor: teal.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation(teal),
                        minHeight: 6,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Otherwise show the input form
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What did you eat?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: widget.controller,
            maxLines: 5,
            minLines: 3,
            textAlignVertical: TextAlignVertical.top,
            style: TextStyle(color: textPrimary),
            decoration: InputDecoration(
              hintText: 'e.g., 2 eggs, toast with butter, and a glass of orange juice',
              hintStyle: TextStyle(color: textMuted),
              filled: true,
              fillColor: elevated,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _QuickSuggestion(label: 'Coffee', onTap: () => _appendText('coffee'), isDark: isDark),
              _QuickSuggestion(label: 'Eggs', onTap: () => _appendText('2 eggs'), isDark: isDark),
              _QuickSuggestion(label: 'Toast', onTap: () => _appendText('toast'), isDark: isDark),
              _QuickSuggestion(label: 'Salad', onTap: () => _appendText('salad'), isDark: isDark),
              _QuickSuggestion(label: 'Chicken', onTap: () => _appendText('chicken breast'), isDark: isDark),
              _QuickSuggestion(label: 'Rice', onTap: () => _appendText('1 cup rice'), isDark: isDark),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _handleAnalyze,
              icon: const Icon(Icons.send, size: 18),
              label: const Text(
                'Analyze with AI',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: teal,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with star and edit options
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Color(0xFFFFD93D), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'AI Estimated Nutrition',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                ),
              ),
              // Star button to save as favorite
              IconButton(
                onPressed: _isSaved || _isSaving ? null : _handleSaveAsFavorite,
                icon: _isSaving
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: const Color(0xFFFFD93D),
                        ),
                      )
                    : Icon(
                        _isSaved ? Icons.star : Icons.star_border,
                        size: 24,
                        color: _isSaved
                            ? const Color(0xFFFFD93D)
                            : textMuted,
                      ),
                tooltip: _isSaved ? 'Saved to favorites' : 'Save as favorite',
              ),
              TextButton.icon(
                onPressed: _handleEdit,
                icon: Icon(Icons.edit, size: 16, color: textMuted),
                label: Text('Edit', style: TextStyle(color: textMuted)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Mood tracking section
          _MoodTrackingSection(
            moodBefore: _moodBefore,
            moodAfter: _moodAfter,
            energyLevel: _energyLevel,
            onMoodBeforeChanged: (mood) => setState(() => _moodBefore = mood),
            onMoodAfterChanged: (mood) => setState(() => _moodAfter = mood),
            onEnergyLevelChanged: (level) => setState(() => _energyLevel = level),
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // Food description
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
                  child: Text(
                    description,
                    style: TextStyle(color: textPrimary, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Overall Meal Score Card (if available)
          if (response.overallMealScore != null || response.goalAlignmentPercentage != null)
            _OverallMealScoreCard(
              score: response.overallMealScore,
              alignmentPercentage: response.goalAlignmentPercentage,
              isDark: isDark,
            ),
          if (response.overallMealScore != null || response.goalAlignmentPercentage != null)
            const SizedBox(height: 16),

          // Collapsible Food Items Section
          if (response.foodItems.isNotEmpty)
            _CollapsibleFoodItemsSection(
              foodItems: response.foodItemsRanked,
              isDark: isDark,
            ),
          if (response.foodItems.isNotEmpty)
            const SizedBox(height: 16),

          // Nutrition cards
          _RainbowNutritionCard(
            icon: Icons.local_fire_department,
            label: 'Calories',
            value: '${response.totalCalories}',
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
                  value: response.proteinG.toStringAsFixed(1),
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
                  value: response.carbsG.toStringAsFixed(1),
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
                  value: response.fatG.toStringAsFixed(1),
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
                  value: (response.fiberG ?? 0).toStringAsFixed(1),
                  unit: 'g',
                  color: fiberColor,
                  isDark: isDark,
                  compact: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

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
          if (response.aiSuggestion != null ||
              (response.encouragements != null && response.encouragements!.isNotEmpty) ||
              (response.warnings != null && response.warnings!.isNotEmpty))
            const SizedBox(height: 16),

          Text(
            'These values are AI estimates based on your description.',
            style: TextStyle(fontSize: 12, color: textMuted, fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Log button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _handleLog,
              icon: const Icon(Icons.check, size: 20),
              label: const Text(
                'Log This Meal',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6BCB77),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
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
                      if (barcode.rawValue != null) {
                        _hasDetected = true;
                        widget.onBarcodeDetected(barcode.rawValue!);
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

class _QuickTab extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(nutritionProvider);
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

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
      padding: const EdgeInsets.all(16),
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
                    userId: userId,
                    description: item['name'] as String,
                    mealType: mealType.value,
                  );
                  onLogged();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to log: $e')),
                    );
                  }
                }
              },
              isDark: isDark,
            )),
      ],
    );
  }
}

class _QuickFoodItem extends StatelessWidget {
  final String name;
  final int calories;
  final VoidCallback onTap;
  final bool isDark;

  const _QuickFoodItem({
    required this.name,
    required this.calories,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
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
                  child: Text(
                    name,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary),
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
    if (score! >= 8) return const Color(0xFF6BCB77);  // Green
    if (score! >= 5) return const Color(0xFFFFD93D);  // Yellow
    return const Color(0xFFFF6B6B);  // Red
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

  const _CollapsibleFoodItemsSection({
    required this.foodItems,
    required this.isDark,
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
                ...widget.foodItems.map((item) => _FoodItemRankingCard(
                  item: item,
                  isDark: widget.isDark,
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

class _FoodItemRankingCard extends StatelessWidget {
  final FoodItemRanking item;
  final bool isDark;

  const _FoodItemRankingCard({required this.item, required this.isDark});

  Color _getScoreColor() {
    if (item.goalScore == null) return Colors.grey;
    if (item.goalScore! >= 8) return const Color(0xFF6BCB77);  // Green
    if (item.goalScore! >= 5) return const Color(0xFFFFD93D);  // Yellow
    return const Color(0xFFFF6B6B);  // Red
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final scoreColor = _getScoreColor();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Score badge
          if (item.goalScore != null)
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
                  '${item.goalScore}',
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
                  item.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                ),
                if (item.amount != null)
                  Text(
                    item.amount!,
                    style: TextStyle(fontSize: 12, color: textMuted),
                  ),
                if (item.reason != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      item.reason!,
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
                '${item.calories ?? 0}',
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
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

    const encourageColor = Color(0xFF6BCB77);  // Green
    const warningColor = Color(0xFFFF6B6B);    // Red
    const swapColor = Color(0xFF4D96FF);       // Blue

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
        return const Color(0xFF6BCB77); // Green
      case FoodMood.good:
        return const Color(0xFF4ECDC4); // Teal
      case FoodMood.neutral:
        return const Color(0xFF95A5A6); // Gray
      case FoodMood.tired:
        return const Color(0xFF9B59B6); // Purple
      case FoodMood.stressed:
        return const Color(0xFFE74C3C); // Red
      case FoodMood.hungry:
        return const Color(0xFFFF6B6B); // Coral
      case FoodMood.satisfied:
        return const Color(0xFF3498DB); // Blue
      case FoodMood.bloated:
        return const Color(0xFFF39C12); // Orange
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

// ─────────────────────────────────────────────────────────────────
// Restaurant Portion Selector - Shows min/typical/max portion options
// ─────────────────────────────────────────────────────────────────

class _RestaurantPortionSelector extends StatelessWidget {
  final LogFoodResponse foodLog;
  final bool isDark;
  final void Function(double multiplier) onSelectPortion;
  final VoidCallback onCancel;

  const _RestaurantPortionSelector({
    required this.foodLog,
    required this.isDark,
    required this.onSelectPortion,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;
    final orange = isDark ? AppColors.orange : AppColorsLight.orange;

    final baseCals = foodLog.totalCalories;
    final baseProtein = foodLog.proteinG.round();
    final baseCarbs = foodLog.carbsG.round();
    final baseFat = foodLog.fatG.round();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.restaurant, color: orange, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Portion Size',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Restaurant portions vary - pick what matches yours',
                      style: TextStyle(fontSize: 13, color: textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Food name summary
          if (foodLog.foodItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                foodLog.foodItems.map((f) => f['name'] ?? 'Food').join(', '),
                style: TextStyle(
                  fontSize: 14,
                  color: textMuted,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          const SizedBox(height: 16),

          // Portion options
          _PortionOption(
            title: 'Light Portion',
            subtitle: 'Smaller than typical, lighter prep',
            multiplier: 0.75,
            calories: (baseCals * 0.75).round(),
            protein: (baseProtein * 0.75).round(),
            carbs: (baseCarbs * 0.75).round(),
            fat: (baseFat * 0.75).round(),
            icon: Icons.expand_less,
            color: teal,
            isDark: isDark,
            onTap: () => onSelectPortion(0.75),
          ),

          const SizedBox(height: 12),

          _PortionOption(
            title: 'Typical Portion',
            subtitle: 'Standard restaurant serving',
            multiplier: 1.0,
            calories: baseCals,
            protein: baseProtein,
            carbs: baseCarbs,
            fat: baseFat,
            icon: Icons.horizontal_rule,
            color: orange,
            isDark: isDark,
            onTap: () => onSelectPortion(1.0),
            isRecommended: true,
          ),

          const SizedBox(height: 12),

          _PortionOption(
            title: 'Large Portion',
            subtitle: 'Generous serving, rich preparation',
            multiplier: 1.25,
            calories: (baseCals * 1.25).round(),
            protein: (baseProtein * 1.25).round(),
            carbs: (baseCarbs * 1.25).round(),
            fat: (baseFat * 1.25).round(),
            icon: Icons.expand_more,
            color: isDark ? AppColors.purple : AppColorsLight.purple,
            isDark: isDark,
            onTap: () => onSelectPortion(1.25),
          ),

          const SizedBox(height: 24),

          // Cancel button
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onCancel,
              child: Text(
                'Cancel',
                style: TextStyle(color: textMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PortionOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final double multiplier;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;
  final bool isRecommended;

  const _PortionOption({
    required this.title,
    required this.subtitle,
    required this.multiplier,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
    this.isRecommended = false,
  });

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isRecommended ? color.withValues(alpha: 0.1) : elevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isRecommended ? color : cardBorder,
              width: isRecommended ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),

              // Title and subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        if (isRecommended) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'TYPICAL',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: textMuted),
                    ),
                  ],
                ),
              ),

              // Calories
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$calories',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    'cal',
                    style: TextStyle(fontSize: 11, color: textMuted),
                  ),
                ],
              ),
            ],
          ),
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
                if (subText != null)
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
