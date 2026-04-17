import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../core/constants/app_colors.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../core/theme/theme_colors.dart';
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
import '../../widgets/app_tour/app_tour_controller.dart';
import '../../data/models/coach_persona.dart';
import '../ai_settings/ai_settings_screen.dart';
import '../../core/services/posthog_service.dart';
import 'widgets/accuracy_feedback_snackbar.dart';
import 'widgets/barcode_scanner_overlay.dart';
import '../../services/post_meal_checkin_reminder.dart';
import 'package:go_router/go_router.dart';
import 'widgets/food_browser_panel.dart';
import 'widgets/food_report_dialog.dart';
import 'widgets/food_analysis_loading.dart';
import 'widgets/inflammation_analysis_widget.dart';
import 'widgets/inflammation_tags_section.dart';
import 'widgets/log_meal_helpers.dart';
import 'widgets/meal_score_widgets.dart';
import 'widgets/ai_suggestion_section.dart';
import 'widgets/food_item_ranking_card.dart';
import 'widgets/micronutrients_section.dart';
import 'widgets/portion_amount_input.dart';
import 'widgets/post_meal_review_sheet.dart';
import 'widgets/ai_coach_meal_suggestion_sheet.dart';
import '../../widgets/floating_chat/floating_chat_overlay.dart';

part 'log_meal_sheet_ui.dart';

part 'log_meal_sheet_ui_1.dart';
part 'log_meal_sheet_ui_2.dart';


/// Shows the log meal bottom sheet from anywhere in the app
/// [initialMealType] - Optional meal type to pre-select (e.g., 'breakfast', 'lunch', 'dinner', 'snack')
Future<void> showLogMealSheet(BuildContext context, WidgetRef ref, {String? initialMealType, bool autoOpenCamera = false, bool autoOpenBarcode = false, DateTime? selectedDate}) async {
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
      autoOpenCamera: autoOpenCamera,
      autoOpenBarcode: autoOpenBarcode,
      selectedDate: selectedDate,
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
  final bool autoOpenCamera;
  final bool autoOpenBarcode;
  final DateTime? selectedDate;

  const LogMealSheet({
    super.key,
    required this.userId,
    required this.isDark,
    this.initialMealType,
    this.autoOpenCamera = false,
    this.autoOpenBarcode = false,
    this.selectedDate,
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
  LogFoodResponse? _previousResponse; // Stored when user goes back to input to allow returning to results
  // Per-item snapshot of the AI's original nutrition values, kept parallel to
  // _analyzedResponse!.foodItems — if the user removes an item, both lists
  // get shortened at the same index so diffs stay aligned.
  List<FoodItemRanking>? _originalFoodItems;
  // Pending pre-save edits, keyed by CURRENT food-item index in
  // _analyzedResponse.foodItems. Flushed to logFoodDirect → POST
  // /nutrition/log-direct when the user taps Log This Meal.
  final Map<int, List<FoodItemEdit>> _pendingItemEdits = {};
  bool _isAnalyzing = false;
  bool _isSaved = false;
  bool _hasLoggedThisSession = false;
  bool _isSaving = false;
  String _sourceType = 'text';
  String? _capturedImagePath; // Local file path of the photo taken/picked for display in results
  int? _analysisElapsedMs;

  // Voice input state
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;

  // Mood tracking state
  FoodMood? _moodBefore;
  FoodMood? _moodAfter;
  int _energyLevel = 3;

  // "More details" toggle for optional inputs (mood, energy, food items, micronutrients)
  bool _showMealDetails = false;

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

    debugPrint('🍽️ [LogMeal] Sheet initialized | userId=${widget.userId} | initialMealType=${widget.initialMealType?.value ?? "auto"} | selectedMealType=${_selectedMealType.value} | autoOpenCamera=${widget.autoOpenCamera}');

    if (widget.autoOpenCamera) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _pickImage(ImageSource.camera);
      });
    } else if (widget.autoOpenBarcode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openBarcodeScanner();
      });
    }
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

  void _handleEdit() {
    setState(() {
      _previousResponse = _analyzedResponse;
      _analyzedResponse = null;
      _analysisElapsedMs = null;
      _capturedImagePath = null;
      _sourceType = 'text';
    });
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

    // Macro colors
    final caloriesColor = isDark ? AppColors.coral : AppColorsLight.coral;
    final proteinColor = isDark ? AppColors.macroProtein : AppColorsLight.macroProtein;
    final carbsColor = isDark ? AppColors.macroCarbs : AppColorsLight.macroCarbs;
    final fatColor = isDark ? AppColors.macroFat : AppColorsLight.macroFat;
    final fiberColor = isDark ? AppColors.green : AppColorsLight.green;

    // Portion multiplier state
    double portionMultiplier = 1.0;

    return showDialog<({bool confirmed, double multiplier})>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Extract food names from AI response
          final foodNames = response.foodItems.isNotEmpty
              ? response.foodItems.map((f) => f.name).join(', ')
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
                  RainbowNutritionCard(
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
                        child: RainbowNutritionCard(
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
                        child: RainbowNutritionCard(
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
                        child: RainbowNutritionCard(
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
                        child: RainbowNutritionCard(
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
                    ConfidenceIndicator(
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

  Future<bool?> _showProductConfirmation(BarcodeProduct product) {
    final isDark = widget.isDark;
    final nearBlack = isDark ? AppColors.nearBlack : AppColorsLight.nearWhite;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accentColor = ref.colors(context).accent;
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

                // Food quality badges
                if (product.nutriscoreGrade != null || product.novaGroup != null ||
                    product.ecoscoreGrade != null || (product.additivesTags?.isNotEmpty ?? false) ||
                    (product.labelsTags?.isNotEmpty ?? false)) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (product.nutriscoreGrade != null)
                        NutriscoreBadge(
                            grade: product.nutriscoreGrade!, isDark: isDark),
                      if (product.novaGroup != null)
                        NovaBadge(group: product.novaGroup!, isDark: isDark),
                      if (product.ecoscoreGrade != null)
                        EcoscoreBadge(
                            grade: product.ecoscoreGrade!, isDark: isDark),
                      if (product.additivesTags != null && product.additivesTags!.isNotEmpty)
                        AdditivesCountBadge(
                            count: product.additivesTags!.length, isDark: isDark),
                      if (product.labelsTags != null)
                        ...product.labelsTags!.take(5).map((label) =>
                            FoodLabelChip(label: label, isDark: isDark)),
                    ],
                  ),
                ],

                // NOVA processing breakdown (expandable)
                if (product.novaGroup != null && product.ingredientsText != null) ...[
                  const SizedBox(height: 8),
                  NovaDetailSection(
                    novaGroup: product.novaGroup!,
                    ingredientsText: product.ingredientsText,
                    isDark: isDark,
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
                NutritionInfoRow(
                  label: 'Calories',
                  value: '${product.caloriesPer100g.toInt()} kcal',
                  isDark: isDark,
                ),
                NutritionInfoRow(
                  label: 'Protein',
                  value: '${product.proteinPer100g.toStringAsFixed(1)}g',
                  isDark: isDark,
                ),
                NutritionInfoRow(
                  label: 'Carbs',
                  value: '${product.carbsPer100g.toStringAsFixed(1)}g',
                  isDark: isDark,
                ),
                NutritionInfoRow(
                  label: 'Fat',
                  value: '${product.fatPer100g.toStringAsFixed(1)}g',
                  isDark: isDark,
                ),
                if (product.fiberPer100g > 0)
                  NutritionInfoRow(
                    label: 'Fiber',
                    value: '${product.fiberPer100g.toStringAsFixed(1)}g',
                    isDark: isDark,
                  ),
                if (product.sugarPer100g > 0)
                  NutritionInfoRow(
                    label: 'Sugar',
                    value: '${product.sugarPer100g.toStringAsFixed(1)}g',
                    isDark: isDark,
                  ),

                // Micronutrients (collapsible)
                if (product.hasMicronutrients) ...[
                  const SizedBox(height: 8),
                  _BarcodeMicronutrientsSection(product: product, isDark: isDark),
                ],

                // Allergens
                if (product.allergensList.isNotEmpty) ...[
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
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: product.allergensList.map((allergen) =>
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          allergen,
                          style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ).toList(),
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
            style: ElevatedButton.styleFrom(backgroundColor: accentColor),
            child: const Text('Log This'),
          ),
        ],
      ),
    );
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
        : _analyzedResponse != null
            ? screenHeight * 0.92
            : screenHeight * 0.85;

    return PopScope(
      canPop: _analyzedResponse == null || _hasLoggedThisSession,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        // User has unlogged analysis results — confirm discard
        final shouldDiscard = await _showDiscardAnalysisDialog(isDark);
        if (shouldDiscard == true && mounted) {
          Navigator.pop(context);
        } else if (shouldDiscard == false && mounted) {
          // User chose "Log This Meal" from the dialog
          _handleLog();
        }
      },
      child: Padding(
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
              color: _analyzedResponse != null
                  ? (isDark ? Colors.black.withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.95))
                  : GlassSheetStyle.backgroundColor(isDark),
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
                    child: FoodAnalysisLoadingIndicator(
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
    ),
    );
  }

  /// Dismiss confirmation dialog when user has unlogged analysis results.
  /// Returns true = discard, false = log the meal, null = cancel (stay).
  Future<bool?> _showDiscardAnalysisDialog(bool isDark) {
    final accentColor = ref.colors(context).accent;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final nearBlack = isDark ? AppColors.nearBlack : AppColorsLight.nearWhite;

    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => AlertDialog(
        backgroundColor: nearBlack,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Discard analysis?',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: textPrimary),
        ),
        content: Text(
          "You haven't logged this meal yet. Your analysis results will be lost.",
          style: TextStyle(fontSize: 14, color: textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), // Discard
            child: Text('Discard', style: TextStyle(color: textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, false), // Log This Meal
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Log This Meal'),
          ),
        ],
      ),
    );
  }
}


/// Collapsible micronutrients section for barcode products
class _BarcodeMicronutrientsSection extends StatefulWidget {
  final BarcodeProduct product;
  final bool isDark;

  const _BarcodeMicronutrientsSection({required this.product, required this.isDark});

  @override
  State<_BarcodeMicronutrientsSection> createState() => _BarcodeMicronutrientsSectionState();
}

class _BarcodeMicronutrientsSectionState extends State<_BarcodeMicronutrientsSection> {
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
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Icon(Icons.science_outlined, size: 16, color: AppColors.purple),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Vitamins & Minerals', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary))),
                  Icon(_isExpanded ? Icons.expand_less : Icons.expand_more, size: 18, color: textMuted),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            Divider(height: 1, color: cardBorder),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              child: Column(
                children: _buildMicronutrientRows(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildMicronutrientRows() {
    final p = widget.product;
    final rows = <Widget>[];

    if (p.vitaminA100g > 0) {
      rows.add(NutritionInfoRow(label: 'Vitamin A', value: '${p.vitaminA100g.toStringAsFixed(1)} µg', isDark: widget.isDark));
    }
    if (p.vitaminC100g > 0) {
      rows.add(NutritionInfoRow(label: 'Vitamin C', value: '${p.vitaminC100g.toStringAsFixed(1)} mg', isDark: widget.isDark));
    }
    if (p.vitaminD100g > 0) {
      rows.add(NutritionInfoRow(label: 'Vitamin D', value: '${p.vitaminD100g.toStringAsFixed(2)} µg', isDark: widget.isDark));
    }
    if (p.calcium100g > 0) {
      rows.add(NutritionInfoRow(label: 'Calcium', value: '${p.calcium100g.toStringAsFixed(1)} mg', isDark: widget.isDark));
    }
    if (p.iron100g > 0) {
      rows.add(NutritionInfoRow(label: 'Iron', value: '${p.iron100g.toStringAsFixed(2)} mg', isDark: widget.isDark));
    }
    if (p.potassium100g > 0) {
      rows.add(NutritionInfoRow(label: 'Potassium', value: '${p.potassium100g.toStringAsFixed(1)} mg', isDark: widget.isDark));
    }
    if (p.magnesium100g > 0) {
      rows.add(NutritionInfoRow(label: 'Magnesium', value: '${p.magnesium100g.toStringAsFixed(1)} mg', isDark: widget.isDark));
    }
    if (p.zinc100g > 0) {
      rows.add(NutritionInfoRow(label: 'Zinc', value: '${p.zinc100g.toStringAsFixed(2)} mg', isDark: widget.isDark));
    }

    return rows;
  }
}
