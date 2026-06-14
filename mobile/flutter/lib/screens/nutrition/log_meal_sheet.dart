import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:dio/dio.dart' show DioException, DioExceptionType;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../core/constants/app_colors.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../core/theme/theme_colors.dart';
import '../../widgets/design_system/zealova.dart';
import '../../data/models/nutrition.dart';
import '../../data/models/fasting.dart';
import '../../data/providers/fasting_provider.dart';
import '../../data/providers/guest_mode_provider.dart';
import '../../data/providers/guest_usage_limits_provider.dart';
import '../../data/repositories/nutrition_repository.dart';
import '../../data/repositories/hydration_repository.dart';
import '../../data/models/hydration.dart' show HydrationSource;
import '../../data/repositories/auth_repository.dart';
import '../../data/services/api_client.dart';
import '../../data/services/haptic_service.dart';
import '../../data/services/last_used_service.dart';
import '../../data/providers/xp_provider.dart';
import '../../widgets/common/last_used_badge.dart';
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
import 'widgets/add_food_sheet.dart';
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
import 'widgets/health_reason_builder.dart';
import 'widgets/score_explain_sheet.dart';
import 'widgets/ai_suggestion_section.dart';
import 'widgets/food_item_ranking_card.dart';
import 'widgets/micronutrients_section.dart';
import 'widgets/portion_amount_input.dart';
import 'widgets/post_meal_review_sheet.dart';
import 'widgets/ai_coach_meal_suggestion_sheet.dart';
import '../../widgets/floating_chat/floating_chat_overlay.dart';
import '../../widgets/fullscreen_image_viewer.dart';
import 'menu_analysis_sheet.dart';
import '../../l10n/generated/app_localizations.dart';
import '../chat/widgets/media_picker_helper.dart' show
  pickFoodScanArtifacts, pickFoodScanArtifactsBatch, FoodScanArtifacts;

part 'log_meal_sheet_ui.dart';

part 'log_meal_sheet_ui_1.dart';
part 'log_meal_sheet_ui_2.dart';
part 'log_meal_sheet_l2.dart';

const String _kMealTypeLastUsedKey = 'meal_type';
const String _kFoodBrowserLastUsedKey = 'food_browser_filter';

/// A1 + L2 — the AI-logging modes. `snap` is the one-tap instant
/// single-photo path; `describe` is the multi-photo + prominent-
/// instruction form; `voice` (L2) is the hands-free dictation path
/// with a confirm-the-transcript step; `search` keeps the existing
/// typed food-search / browser experience reachable.
enum _AiLogMode { search, snap, describe, voice }


/// Shows the log meal bottom sheet from anywhere in the app
/// [initialMealType] - Optional meal type to pre-select (e.g., 'breakfast', 'lunch', 'dinner', 'snack')
Future<void> showLogMealSheet(
  BuildContext context,
  WidgetRef ref, {
  String? initialMealType,
  bool autoOpenCamera = false,
  bool autoOpenBarcode = false,
  bool autoOpenMultiImage = false,
  bool autoOpenMenuScan = false,
  DateTime? selectedDate,
}) async {
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
  try {
    await showGlassSheet(
      context: context,
      builder: (context) => LogMealSheet(
        userId: userId!,
        isDark: isDark,
        initialMealType: mealType,
        autoOpenCamera: autoOpenCamera,
        autoOpenBarcode: autoOpenBarcode,
        autoOpenMultiImage: autoOpenMultiImage,
        autoOpenMenuScan: autoOpenMenuScan,
        selectedDate: selectedDate,
      ),
    );
  } finally {
    // CRITICAL: restore nav bar even if Analyze is in flight when the user
    // swipe-dismisses, or any awaited future throws. Was naked before —
    // matched the same disappearing-nav-bar class as weekly_checkin had
    // (now fixed there with try/finally; mirroring the pattern here).
    debugPrint('showLogMealSheet: Bottom sheet closed');
    try {
      ref.read(floatingNavBarVisibleProvider.notifier).state = true;
    } catch (_) {/* container disposed mid-dismiss */}
  }
}

/// Bottom sheet for logging meals with multiple input methods
class LogMealSheet extends ConsumerStatefulWidget {
  final String userId;
  final bool isDark;
  final MealType? initialMealType;
  final bool autoOpenCamera;
  final bool autoOpenBarcode;
  /// Launch multi-image food scan picker immediately on open (from "Scan
  /// Food" home shortcut).
  final bool autoOpenMultiImage;
  /// Launch menu-scan picker immediately on open (from "Scan Menu" home
  /// shortcut).
  final bool autoOpenMenuScan;
  final DateTime? selectedDate;

  /// Imports feature — when the share router routes a food photo here
  /// (content_type=food_plate/food_buffet/app_screenshot), the S3 key of
  /// the already-uploaded photo is passed in. The sheet picks it up on
  /// first build and feeds it into the existing photo-log flow instead
  /// of opening the camera.
  final String? initialPhotoS3Key;

  /// Imports feature — for app_screenshot route, the OCR text result is
  /// supplied so the sheet can run the analyze-text streaming path
  /// without re-OCRing. Mutually exclusive with [initialPhotoS3Key].
  final String? initialTextLog;

  const LogMealSheet({
    super.key,
    required this.userId,
    required this.isDark,
    this.initialMealType,
    this.autoOpenCamera = false,
    this.autoOpenBarcode = false,
    this.autoOpenMultiImage = false,
    this.autoOpenMenuScan = false,
    this.selectedDate,
    this.initialPhotoS3Key,
    this.initialTextLog,
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

  // ─── A1 Snap / Describe mode state ─────────────────────────────
  /// Active AI-logging mode. Defaults to Search (the typed food-search /
  /// browser path); Snap is the one-tap instant-camera path.
  _AiLogMode _aiMode = _AiLogMode.search;
  /// Photos staged in the Describe form before the single Analyze round
  /// trip. Capped at 5 (the existing multi-image limit).
  final List<XFile> _describePhotos = [];
  /// Prominent pre-analysis instruction for the Describe form. Sent as
  /// `user_message` alongside the photos / text. Separate from
  /// `_descriptionController` so a food name and an instruction can both
  /// be supplied.
  final _describeInstructionController = TextEditingController();
  /// Re-entrancy guard so a second Analyze can't interleave with a
  /// Describe analysis already streaming (edge case C3).
  bool _describeAnalyzing = false;

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
  // Re-entrancy guard for the manual "Add food" flow — protects against
  // double-tapping the action chip while a stream is still in-flight.
  bool _addingFoodItem = false;
  // True between the `done` event (fast macro estimate) and the late
  // `coach_tips` event — drives the shimmer placeholder on the coach-tip
  // card so the "Coach's Tip" always appears even on the fast macro path.
  bool _awaitingCoachTip = false;
  // Re-entrancy guard for the Refine-with-AI correction flow.
  bool _refiningMeal = false;
  String _sourceType = 'text';
  /// Specific input method — sent to backend so food_logs.input_type is
  /// populated. Values match the migration-1960 CHECK allowlist: text, voice,
  /// camera, gallery, barcode, menu_scan, buffet_scan, multi_image_scan,
  /// chat, ai_suggestion, manual, image, copy, watch.
  String _inputType = 'text';
  // Gap 1 — water-in-text. When a typed/dictated entry ("2 eggs and a glass of
  // water") includes a beverage, the analyze stream returns {amount_ml,
  // drink_type} here so the food confirm can log the water to hydration too.
  // Cleared on edit/reset; consumed once in _handleLog.
  Map<String, dynamic>? _pendingHydration;
  // Gap 7 — opt-in tracker inputs ({added_sugar_g, caffeine_mg, alcohol_g})
  // from the analysis, forwarded to /log-direct on confirm so the
  // sugar/caffeine/alcohol trackers get real data. Cleared on edit/reset.
  Map<String, dynamic>? _pendingTrackerMicros;
  String? _capturedImagePath; // Local file path of the photo taken/picked for display in results
  int? _analysisElapsedMs;

  // Voice input state
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;

  // ─── L2 near-zero-friction state ───────────────────────────────
  /// Editable transcript captured in Voice mode. Held separately from
  /// `_descriptionController` so the user can review/fix a possible
  /// mis-transcription (C6) before it routes through analysis.
  final _voiceTranscriptController = TextEditingController();
  /// True while Voice mode's mic is actively capturing. Distinct from
  /// `_isListening` (which the Search-panel mic also uses) so the two
  /// surfaces never fight over UI state.
  bool _voiceCapturing = false;
  /// Set when the OS denied mic permission or speech is unavailable —
  /// drives Voice mode's graceful fallback message (C6).
  bool _voiceUnavailable = false;
  /// L2 "frequent meals" — the user's most-logged recent full meals,
  /// derived client-side from recent food_logs. Empty until loaded.
  List<_FrequentMeal> _frequentMeals = const [];
  /// True while the frequent-meals window is being fetched. Drives the
  /// strip's skeleton; a brand-new user resolves to an empty list (C8).
  bool _frequentMealsLoading = false;
  /// True once the frequent-meals fetch has completed at least once
  /// (so the empty state only shows after a real load, not before).
  bool _frequentMealsLoaded = false;
  /// The meal slot the sheet auto-predicted from time-of-day on open
  /// (L2). Null when the slot came from an explicit deep link or the
  /// user's last-used choice — used only to show the "predicted" hint.
  MealType? _predictedMealSlot;

  // Mood tracking state
  FoodMood? _moodBefore;
  FoodMood? _moodAfter;
  int _energyLevel = 3;

  // "More details" toggle for optional inputs (mood, energy, food items, micronutrients)
  bool _showMealDetails = false;

  // Food browser state. Initial value comes from LastUsedService in
  // initState — defaults to .recent when no prior choice persisted.
  FoodBrowserFilter _browserFilter = FoodBrowserFilter.recent;
  String _searchQuery = '';

  // Scroll/focus
  final ScrollController _scrollController = ScrollController();
  final FocusNode _textFieldFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Pre-select priority for meal type:
    //   1. explicit widget.initialMealType (deep link from quick actions, etc.)
    //   2. last-used meal type the user picked in this sheet
    //   3. time-of-day heuristic (_getDefaultMealType)
    final lastUsed = ref.read(lastUsedServiceProvider);
    // L2 meal-slot prediction: the time-of-day default is the
    // *predicted* slot. We still honour an explicit deep link or the
    // user's last-used choice first — but when neither is set, the
    // prediction wins AND we remember it so the UI can show a
    // dismissible "predicted" hint (the selector stays overridable —
    // C8 "prediction wrong → easy to override").
    final predicted = _getDefaultMealType();
    final lastUsedSlot = _resolveMealTypeFromKey(lastUsed.get(_kMealTypeLastUsedKey));
    _selectedMealType = widget.initialMealType ?? lastUsedSlot ?? predicted;
    if (widget.initialMealType == null && lastUsedSlot == null) {
      // Slot was filled purely by the time-of-day prediction.
      _predictedMealSlot = predicted;
    }
    final lastBrowserKey = lastUsed.get(_kFoodBrowserLastUsedKey);
    if (lastBrowserKey != null) {
      _browserFilter = FoodBrowserFilter.values.firstWhere(
        (f) => f.name == lastBrowserKey,
        orElse: () => FoodBrowserFilter.recent,
      );
    }
    _selectedTime = TimeOfDay.now();
    _textFieldFocusNode.addListener(_onFocusChange);
    _descriptionController.addListener(_onDescriptionChanged);

    debugPrint('🍽️ [LogMeal] Sheet initialized | userId=${widget.userId} | initialMealType=${widget.initialMealType?.value ?? "auto"} | selectedMealType=${_selectedMealType.value} | autoOpenCamera=${widget.autoOpenCamera}');

    if (widget.autoOpenCamera) {
      // Snap shortcut — one-tap instant single-photo path.
      _aiMode = _AiLogMode.snap;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _pickImage(ImageSource.camera);
      });
    } else if (widget.autoOpenBarcode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openBarcodeScanner();
      });
    } else if (widget.autoOpenMultiImage) {
      // Launched from the "Scan Food" home shortcut — present the same
      // Camera vs Gallery picker that Scan Menu uses (both paths support
      // multi-image: camera via capture loop, gallery via multi-pick).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _pickFoodImagesWithSourceChoice();
      });
    } else if (widget.autoOpenMenuScan) {
      // Launched from the "Scan Menu" home shortcut.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scanMenu();
      });
    }

    // L2 — load the user's frequent meals in the background so the
    // one-tap re-log strip is ready by the time they look at it. Never
    // blocks sheet open; a brand-new user just resolves to empty (C8).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadFrequentMeals();
    });
  }

  @override
  void dispose() {
    debugPrint('🍽️ [LogMeal] Sheet disposed | userId=${widget.userId}');
    _loadingDelayTimer?.cancel();
    _descriptionController.removeListener(_onDescriptionChanged);
    _descriptionController.dispose();
    _describeInstructionController.dispose();
    _voiceTranscriptController.dispose();
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
      _inputType = 'text';
      // Gap 1 — drop any detected beverage; the re-analysis re-detects it.
      _pendingHydration = null;
      // Gap 7 — drop tracker inputs; re-analysis re-derives them.
      _pendingTrackerMicros = null;
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
                AppLocalizations.of(context).logMealEndYourFast,
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
              AppLocalizations.of(context)!.logMealSheetYouVeBeenFasting(elapsedHours, elapsedMins),
              style: TextStyle(color: textPrimary, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).logMealLoggingThisMealWill,
              style: TextStyle(color: textMuted, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null), // Cancel
            child: Text(AppLocalizations.of(context).buttonCancel, style: TextStyle(color: textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Log without ending fast
            child: Text(AppLocalizations.of(context).logMealLogOnly, style: TextStyle(color: purple)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), // End fast and log
            style: ElevatedButton.styleFrom(
              backgroundColor: purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(AppLocalizations.of(context).logMealEndFastLog),
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
                    AppLocalizations.of(context).logMealAiEstimatedNutrition,
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
                    label: AppLocalizations.of(context).workoutSummaryGeneralCalories,
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
                          label: AppLocalizations.of(context).weeklyCheckinSheetProtein,
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
                          label: AppLocalizations.of(context).weeklyCheckinSheetCarbs,
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
                          label: AppLocalizations.of(context).weeklyCheckinSheetFat,
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
                          label: AppLocalizations.of(context).recipeBuilderSheetFiber,
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
                      AppLocalizations.of(context).logMealTheseValuesAreAi,
                      style: TextStyle(fontSize: 12, color: textMuted, fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: Text(AppLocalizations.of(context).buttonCancel, style: TextStyle(color: textMuted)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, (confirmed: true, multiplier: portionMultiplier)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textMuted,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check, size: 18),
                    SizedBox(width: 8),
                    Text(AppLocalizations.of(context).logMealLogThis),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Shows the barcode-product confirmation dialog.
  ///
  /// Returns the user's chosen servings count on confirm (defaults to 1.0),
  /// or `null` if cancelled. Caller must pass this back to the log endpoint
  /// so totals reflect what the user actually ate.
  Future<double?> _showProductConfirmation(BarcodeProduct product) {
    final isDark = widget.isDark;
    final nearBlack = isDark ? AppColors.nearBlack : AppColorsLight.nearWhite;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accentColor = ref.colors(context).accent;
    final cardBg = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.04);

    // Derived 1-10 scores from OFF metadata. Kept in-widget (no server trip)
    // because the mappings are deterministic and this dialog blocks the log
    // path — a round-trip here would add latency the user has no reason for.
    // Inflammation mapping mirrors backend/api/v1/nutrition/barcode.py's
    // nova_to_inflammation dict so the preview matches what gets persisted.
    int? inflammationScore;
    final novaGroup = product.novaGroup;
    if (novaGroup != null) {
      const novaToInflammation = {1: 3, 2: 4, 3: 6, 4: 8};
      inflammationScore = novaToInflammation[novaGroup] ?? 5;
    }
    final isUltraProcessed = novaGroup == 4;

    // Nutri-Score grade → 1-10 health score. The grade is a validated
    // composite score (macros + fibre + fruit-veg + sodium + saturates)
    // published by Santé publique France, so it's the right anchor for the
    // same 1-10 rubric the AI uses for text/photo meals.
    int? healthScore;
    final grade = product.nutriscoreGrade?.toLowerCase();
    if (grade != null) {
      const gradeToHealth = {'a': 9, 'b': 7, 'c': 5, 'd': 3, 'e': 2};
      healthScore = gradeToHealth[grade];
    }

    // Servings is mutable in the dialog — start at 1, user can step or type.
    double servings = 1.0;

    return showDialog<double>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
        backgroundColor: nearBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
        title: Text(AppLocalizations.of(context).logMealFoundProduct, style: TextStyle(color: textPrimary)),
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

                // Health + inflammation score badges (derived on-device from
                // OFF metadata; mirrors what text/photo flows surface). Placed
                // before the stepper so the user sees quality at a glance
                // before choosing servings.
                if (healthScore != null || inflammationScore != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (healthScore != null) ...[
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => ScoreExplainSheet.showHealth(
                            context,
                            score: healthScore,
                            // OFF/Nutri-Score derived — no AI reasons. Use
                            // locally derived tags so the chips still tell a
                            // useful story about ultra-processing / sugar.
                            reasons: healthReasonsFromSignals(
                              calories: product.caloriesPer100g.round(),
                              proteinG: product.proteinPer100g,
                              fiberG: product.fiberPer100g,
                              sugarG: product.sugarPer100g,
                              isUltraProcessed: isUltraProcessed,
                              inflammationScore: inflammationScore,
                            ),
                          ),
                          child: _ScorePill(
                            label: AppLocalizations.of(context).mealScoreWidgetsHealth,
                            score: healthScore,
                            isDark: isDark,
                            positiveIsHigh: true,
                            showHelpIcon: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (inflammationScore != null)
                        _ScorePill(
                          label: AppLocalizations.of(context).menuFilterInflammation,
                          score: inflammationScore,
                          isDark: isDark,
                          positiveIsHigh: false,
                          badge: isUltraProcessed ? 'UPF' : null,
                        ),
                    ],
                  ),
                ],

                // Servings stepper — per feedback_inline_editing.md we
                // prefer in-place editing over modals. Multiplier feeds the
                // totals row below and the dialog's return value so the
                // backend logs exactly what the user chose.
                const SizedBox(height: 12),
                // F1 — barcode lookups are verified-from-DB, so surface a
                // high-confidence ConfidenceIndicator (reuses the shared
                // widget) so the source is explicit on the confirm card.
                ConfidenceIndicator(
                  confidenceLevel: 'high',
                  sourceType: 'barcode',
                  isDark: isDark,
                ),

                const SizedBox(height: 12),
                _ServingsStepper(
                  value: servings,
                  servingLabel: product.servingSize ??
                      (product.servingSizeG != null
                          ? '${product.servingSizeG!.toInt()}g'
                          : '100g'),
                  isDark: isDark,
                  accent: accentColor,
                  onChanged: (next) => setDialogState(() => servings = next),
                ),

                // F1 — "How much of this serving did you eat?" Quick-percent
                // chips scale the serving count to a fraction so a partially
                // consumed item logs honestly (25 % = 0.25 servings, etc.).
                const SizedBox(height: 8),
                _PackagePercentRow(
                  isDark: isDark,
                  accent: accentColor,
                  current: servings,
                  onPick: (frac) => setDialogState(() => servings = frac),
                ),

                const SizedBox(height: 12),
                Divider(color: textMuted.withValues(alpha: 0.2)),
                const SizedBox(height: 8),

                // Nutrition for the user's chosen serving count.
                Builder(builder: (_) {
                  final perServingG = product.servingSizeG ?? 100.0;
                  final mult = (servings * perServingG) / 100.0;
                  final totalCalories = (product.caloriesPer100g * mult).round();
                  final totalProtein = product.proteinPer100g * mult;
                  final totalCarbs = product.carbsPer100g * mult;
                  final totalFat = product.fatPer100g * mult;
                  final totalFiber = product.fiberPer100g * mult;
                  final totalSugar = product.sugarPer100g * mult;
                  final servingsLabel =
                      servings == 1.0 ? '1 serving' : '${_trimServings(servings)} servings';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context)!.logMealSheetNutritionFor(servingsLabel),
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textMuted)),
                      const SizedBox(height: 6),
                      NutritionInfoRow(
                        label: AppLocalizations.of(context).workoutSummaryGeneralCalories,
                        value: AppLocalizations.of(context)!.logMealSheetKcal(totalCalories),
                        isDark: isDark,
                      ),
                      NutritionInfoRow(
                        label: AppLocalizations.of(context).weeklyCheckinSheetProtein,
                        value: AppLocalizations.of(context)!.logMealSheetG(totalProtein.toStringAsFixed(1)),
                        isDark: isDark,
                      ),
                      NutritionInfoRow(
                        label: AppLocalizations.of(context).weeklyCheckinSheetCarbs,
                        value: AppLocalizations.of(context)!.logMealSheetG2(totalCarbs.toStringAsFixed(1)),
                        isDark: isDark,
                      ),
                      NutritionInfoRow(
                        label: AppLocalizations.of(context).weeklyCheckinSheetFat,
                        value: AppLocalizations.of(context)!.logMealSheetG3(totalFat.toStringAsFixed(1)),
                        isDark: isDark,
                      ),
                      if (product.fiberPer100g > 0)
                        NutritionInfoRow(
                          label: AppLocalizations.of(context).recipeBuilderSheetFiber,
                          value: AppLocalizations.of(context)!.logMealSheetG4(totalFiber.toStringAsFixed(1)),
                          isDark: isDark,
                        ),
                      if (product.sugarPer100g > 0)
                        NutritionInfoRow(
                          label: AppLocalizations.of(context).logMealSugar,
                          value: AppLocalizations.of(context)!.logMealSheetG5(totalSugar.toStringAsFixed(1)),
                          isDark: isDark,
                        ),
                    ],
                  );
                }),

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
                      Text(AppLocalizations.of(context).nutritionSettingsScreenAllergens,
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
                  Text(AppLocalizations.of(context).recipeSuggestionCardIngredients,
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
            onPressed: () => Navigator.pop(context, null),
            child: Text(AppLocalizations.of(context).buttonCancel, style: TextStyle(color: textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, servings),
            style: ElevatedButton.styleFrom(backgroundColor: accentColor),
            child: Text(AppLocalizations.of(context).logMealLogThis),
          ),
        ],
      ),
      ),
    );
  }

  /// Trim trailing `.0` from integer servings so the UI shows `2 servings`
  /// instead of `2.0 servings`, while still showing `1.5 servings` for
  /// fractional values.
  String _trimServings(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
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
                      analysisType: _sourceType == 'menu'
                          ? 'menu'
                          : _sourceType == 'buffet'
                              ? 'buffet'
                              : 'plate',
                    ),
                  )
                else if (_analyzedResponse != null)
                  Expanded(child: _buildNutritionPreview(isDark))
                else
                  Expanded(child: _buildInputView(isDark)),

                // Bottom bar: only in the Search input state — Snap and
                // Describe modes have their own in-panel actions.
                if (!_isLoading &&
                    !_isAnalyzing &&
                    _analyzedResponse == null &&
                    _aiMode == _AiLogMode.search)
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
          AppLocalizations.of(context).logMealDiscardAnalysis,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: textPrimary),
        ),
        content: Text(
          AppLocalizations.of(context).logMealYouHavenTLogged,
          style: TextStyle(fontSize: 14, color: textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), // Discard
            child: Text(AppLocalizations.of(context).syncDetailsDiscard, style: TextStyle(color: textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, false), // Log This Meal
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(AppLocalizations.of(context).logMealSheetLogThisMeal),
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
                  Expanded(child: Text(AppLocalizations.of(context).micronutrientsVitaminsMinerals, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary))),
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
      rows.add(NutritionInfoRow(label: AppLocalizations.of(context).logMealVitaminA, value: AppLocalizations.of(context)!.logMealSheetG6(p.vitaminA100g.toStringAsFixed(1)), isDark: widget.isDark));
    }
    if (p.vitaminC100g > 0) {
      rows.add(NutritionInfoRow(label: AppLocalizations.of(context).logMealVitaminC, value: AppLocalizations.of(context)!.logMealSheetMg(p.vitaminC100g.toStringAsFixed(1)), isDark: widget.isDark));
    }
    if (p.vitaminD100g > 0) {
      rows.add(NutritionInfoRow(label: AppLocalizations.of(context).logMealVitaminD, value: AppLocalizations.of(context)!.logMealSheetG7(p.vitaminD100g.toStringAsFixed(2)), isDark: widget.isDark));
    }
    if (p.calcium100g > 0) {
      rows.add(NutritionInfoRow(label: AppLocalizations.of(context).logMealCalcium, value: AppLocalizations.of(context)!.logMealSheetMg2(p.calcium100g.toStringAsFixed(1)), isDark: widget.isDark));
    }
    if (p.iron100g > 0) {
      rows.add(NutritionInfoRow(label: AppLocalizations.of(context).logMealIron, value: AppLocalizations.of(context)!.logMealSheetMg3(p.iron100g.toStringAsFixed(2)), isDark: widget.isDark));
    }
    if (p.potassium100g > 0) {
      rows.add(NutritionInfoRow(label: AppLocalizations.of(context).logMealPotassium, value: AppLocalizations.of(context)!.logMealSheetMg4(p.potassium100g.toStringAsFixed(1)), isDark: widget.isDark));
    }
    if (p.magnesium100g > 0) {
      rows.add(NutritionInfoRow(label: AppLocalizations.of(context).logMealMagnesium, value: AppLocalizations.of(context)!.logMealSheetMg5(p.magnesium100g.toStringAsFixed(1)), isDark: widget.isDark));
    }
    if (p.zinc100g > 0) {
      rows.add(NutritionInfoRow(label: AppLocalizations.of(context).logMealZinc, value: AppLocalizations.of(context)!.logMealSheetMg6(p.zinc100g.toStringAsFixed(2)), isDark: widget.isDark));
    }

    return rows;
  }
}

/// Compact 1-10 score badge used in the barcode confirmation dialog.
///
/// [positiveIsHigh] flips the palette: for "Health", 10 is green; for
/// "Inflammation", 10 is red.
class _ScorePill extends StatelessWidget {
  final String label;
  final int score;
  final bool isDark;
  final bool positiveIsHigh;
  final String? badge;
  final bool showHelpIcon;

  const _ScorePill({
    required this.label,
    required this.score,
    required this.isDark,
    required this.positiveIsHigh,
    this.badge,
    this.showHelpIcon = false,
  });

  Color _color() {
    final effective = positiveIsHigh ? score : (11 - score);
    if (effective >= 8) return const Color(0xFF2ECC71); // green
    if (effective >= 5) return const Color(0xFFF5A623); // amber
    return const Color(0xFFE74C3C); // red
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$score',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            '/10',
            style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.75)),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textPrimary,
            ),
          ),
          if (showHelpIcon) ...[
            const SizedBox(width: 4),
            Icon(Icons.help_outline, size: 12, color: textMuted),
          ],
          if (badge != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badge!,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: textMuted,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Inline-editable servings stepper for the barcode confirmation dialog.
///
/// Renders `−  [typed field] ×  label  +` where the label is the product's
/// native serving description ("30g", "1 bar") so the user reasons in real
/// units, not abstract servings. Clamped to [0.25, 10.0]; fractional values
/// are allowed so users can log "half a bar".
/// F1 — quick "how much of this serving did you eat?" percent chips. Each chip
/// sets the serving count to a fraction (25 % → 0.25 servings) so a partially
/// consumed item logs honestly. Wraps (never overflows) on small screens.
class _PackagePercentRow extends StatelessWidget {
  final bool isDark;
  final Color accent;
  final double current;
  final ValueChanged<double> onPick;

  const _PackagePercentRow({
    required this.isDark,
    required this.accent,
    required this.current,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    const fractions = <(String, double)>[
      ('¼', 0.25),
      ('½', 0.5),
      ('¾', 0.75),
      ('All', 1.0),
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('Ate',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: textMuted)),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final f in fractions)
                Semantics(
                  button: true,
                  label: 'Ate ${f.$1} of a serving',
                  selected: (current - f.$2).abs() < 0.01,
                  child: GestureDetector(
                    onTap: () {
                      HapticService.selection();
                      onPick(f.$2);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: (current - f.$2).abs() < 0.01
                            ? accent.withValues(alpha: 0.18)
                            : accent.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: (current - f.$2).abs() < 0.01
                              ? accent.withValues(alpha: 0.5)
                              : accent.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Text(
                        f.$1,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ServingsStepper extends StatefulWidget {
  final double value;
  final String servingLabel;
  final bool isDark;
  final Color accent;
  final ValueChanged<double> onChanged;

  const _ServingsStepper({
    required this.value,
    required this.servingLabel,
    required this.isDark,
    required this.accent,
    required this.onChanged,
  });

  @override
  State<_ServingsStepper> createState() => _ServingsStepperState();
}

class _ServingsStepperState extends State<_ServingsStepper> {
  static const _min = 0.25;
  static const _max = 10.0;
  static const _step = 0.25;

  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _format(widget.value));
  }

  @override
  void didUpdateWidget(covariant _ServingsStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final expected = _format(widget.value);
      if (_controller.text != expected) {
        _controller.text = expected;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _format(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  void _clampAndEmit(double v) {
    final clamped = v.clamp(_min, _max).toDouble();
    _controller.text = _format(clamped);
    widget.onChanged(clamped);
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = widget.isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final surface = widget.isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);

    Widget roundBtn(IconData icon, VoidCallback onTap) => InkResponse(
          radius: 20,
          onTap: onTap,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: surface,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: textPrimary),
          ),
        );

    return Row(
      children: [
        Text(
          AppLocalizations.of(context).recipeBuilderServings,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textMuted,
          ),
        ),
        const Spacer(),
        roundBtn(
          Icons.remove_rounded,
          () => _clampAndEmit(widget.value - _step),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 56,
          child: TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              filled: true,
              fillColor: surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (raw) {
              final parsed = double.tryParse(raw);
              if (parsed != null) _clampAndEmit(parsed);
            },
            onEditingComplete: () {
              final parsed = double.tryParse(_controller.text);
              if (parsed != null) _clampAndEmit(parsed);
            },
          ),
        ),
        const SizedBox(width: 8),
        roundBtn(
          Icons.add_rounded,
          () => _clampAndEmit(widget.value + _step),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            AppLocalizations.of(context)!.logMealSheetValue(widget.servingLabel),
            style: TextStyle(fontSize: 12, color: textMuted),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
