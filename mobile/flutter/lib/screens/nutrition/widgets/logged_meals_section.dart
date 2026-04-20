import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/nutrition.dart';
import '../../../data/services/api_client.dart';
import '../../../utils/time_formatters.dart';
import '../../../widgets/fullscreen_image_viewer.dart';
import '../../../widgets/glass_sheet.dart';
import 'food_report_dialog.dart';
import 'food_source_indicator.dart';

class LoggedMealsSection extends StatelessWidget {
  final List<FoodLog> meals;
  final void Function(String) onDeleteMeal;
  final void Function(String mealId, String targetMealType) onCopyMeal;
  final void Function(String mealId, String targetMealType) onMoveMeal;
  /// Copy a single item (parent.foodItems[itemIdx]) into `targetMealType` as
  /// a standalone food log. Leaves the source meal untouched.
  final void Function(String sourceLogId, int itemIdx, String targetMealType)? onCopyItem;
  /// Move a single item into `targetMealType` as a standalone food log, then
  /// remove it from the source meal (deletes the source when it was the last
  /// item).
  final void Function(String sourceLogId, int itemIdx, String targetMealType)? onMoveItem;
  final void Function(String logId, int calories, double proteinG, double carbsG, double fatG, {double? weightG, List<Map<String, dynamic>>? foodItems, List<FoodItemEdit>? itemEdits}) onUpdateMeal;
  final void Function(String logId, DateTime newTime) onUpdateMealTime;
  final void Function(String logId, String notes) onUpdateMealNotes;
  final void Function(String logId, {String? moodBefore, String? moodAfter, int? energyLevel}) onUpdateMealMood;
  final void Function(FoodLog meal) onSaveFoodToFavorites;
  final void Function(String? mealType) onLogMeal;
  /// Fetch existing per-field edit history for a given log.
  final Future<List<FoodLogEditRecord>> Function(String logId)? onFetchItemEdits;
  final ApiClient? apiClient;
  final bool isDark;
  final String userId;
  final VoidCallback onFoodSaved;
  final int? calorieTarget;
  final int totalCaloriesEaten;
  // Hero summary extras — macro targets and consumed values (passed from daily_tab).
  final int proteinTarget;
  final int carbsTarget;
  final int fatTarget;
  final double consumedProtein;
  final double consumedCarbs;
  final double consumedFat;
  /// Opens the EditTargetsSheet when the hero-row pencil is tapped.
  final VoidCallback? onEditTargets;

  const LoggedMealsSection({
    super.key,
    required this.meals,
    required this.onDeleteMeal,
    required this.onCopyMeal,
    required this.onMoveMeal,
    this.onCopyItem,
    this.onMoveItem,
    required this.onUpdateMeal,
    required this.onUpdateMealTime,
    required this.onUpdateMealNotes,
    required this.onUpdateMealMood,
    required this.onSaveFoodToFavorites,
    required this.onLogMeal,
    this.onFetchItemEdits,
    this.apiClient,
    required this.isDark,
    required this.userId,
    required this.onFoodSaved,
    this.calorieTarget,
    required this.totalCaloriesEaten,
    this.proteinTarget = 0,
    this.carbsTarget = 0,
    this.fatTarget = 0,
    this.consumedProtein = 0,
    this.consumedCarbs = 0,
    this.consumedFat = 0,
    this.onEditTargets,
  });

  static const _mealTypes = [
    {'id': 'breakfast', 'label': 'Breakfast', 'emoji': '\u{1F373}'},
    {'id': 'lunch', 'label': 'Lunch', 'emoji': '\u{1F957}'},
    {'id': 'dinner', 'label': 'Dinner', 'emoji': '\u{1F37D}\u{FE0F}'},
    {'id': 'snack', 'label': 'Snacks', 'emoji': '\u{1F34E}'},
  ];

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    // Group meals by type
    final mealsByType = <String, List<FoodLog>>{};
    for (final meal in meals) {
      mealsByType.putIfAbsent(meal.mealType, () => []).add(meal);
    }

    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hero summary (calories remaining + progress + macro mini-bars)
          _buildHeroRow(context),
          Divider(height: 1, color: cardBorder),
          // ── Meal sections (each a self-managed _MealSection for expand state)
          ..._mealTypes.asMap().entries.map((entry) {
            final index = entry.key;
            final mealInfo = entry.value;
            final mealId = mealInfo['id']!;
            final typeMeals = mealsByType[mealId] ?? [];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MealSection(
                  mealId: mealId,
                  label: mealInfo['label']!,
                  typeMeals: typeMeals,
                  owner: this,
                ),
                if (index < _mealTypes.length - 1)
                  Divider(height: 1, thickness: 1, color: cardBorder),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Hero summary row (calories remaining + progress + macro chips)
  // ──────────────────────────────────────────────────────────────

  Widget _buildHeroRow(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final purple = isDark ? AppColors.macroProtein : AppColorsLight.macroProtein;
    final cyan = isDark ? AppColors.macroCarbs : AppColorsLight.macroCarbs;
    final orange = isDark ? AppColors.macroFat : AppColorsLight.macroFat;

    final target = calorieTarget ?? 0;
    final remaining = target - totalCaloriesEaten;
    final isOver = remaining < 0;
    final progress = target > 0
        ? (totalCaloriesEaten / target).clamp(0.0, 1.0)
        : 0.0;

    // Hero number + eaten/target + edit pencil
    final heroHeader = Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                target > 0
                    ? '${remaining.abs()}${isOver ? ' over' : ' left'}'
                    : '$totalCaloriesEaten eaten',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: isOver ? AppColors.error : textPrimary,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              if (target > 0)
                Text(
                  '$totalCaloriesEaten / $target cal',
                  style: TextStyle(fontSize: 12, color: textMuted),
                )
              else
                Text(
                  'Set a calorie target to track remaining',
                  style: TextStyle(fontSize: 11, color: textMuted),
                ),
            ],
          ),
        ),
        if (onEditTargets != null)
          IconButton(
            onPressed: onEditTargets,
            icon: Icon(Icons.edit_outlined, size: 16, color: textMuted),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            tooltip: 'Edit targets',
          ),
      ],
    );

    // Progress bar
    Widget progressBar() => ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: elevated == AppColors.elevated
                ? Colors.white10
                : Colors.black12,
            valueColor: AlwaysStoppedAnimation<Color>(isOver ? AppColors.error : accent),
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          heroHeader,
          if (target > 0) ...[
            const SizedBox(height: 10),
            progressBar(),
          ],
          const SizedBox(height: 12),
          // Three macro mini-bars laid out evenly
          Row(
            children: [
              Expanded(child: _MacroMiniBar(
                label: 'Protein',
                consumed: consumedProtein,
                target: proteinTarget,
                color: purple,
                isDark: isDark,
              )),
              const SizedBox(width: 12),
              Expanded(child: _MacroMiniBar(
                label: 'Carbs',
                consumed: consumedCarbs,
                target: carbsTarget,
                color: cyan,
                isDark: isDark,
              )),
              const SizedBox(width: 12),
              Expanded(child: _MacroMiniBar(
                label: 'Fat',
                consumed: consumedFat,
                target: fatTarget,
                color: orange,
                isDark: isDark,
              )),
            ],
          ),
        ],
      ),
    );
  }

  /// Renders a single food-item row. Leading 28dp source slot +
  /// name/amount on the left + cal/protein/time stacked on the right.
  ///
  /// Swipe-right → edit portion sheet. Swipe-left → delete (whole log if
  /// single-item, or just this item if [onDeleteChild] is provided).
  /// Returns a small "via X" badge Widget for non-default log sources — or
  /// null when nothing useful to show (image with thumbnail, plain text, or
  /// unknown source).
  ///
  /// The goal is a single-glance answer to "how did this row get here?".
  /// Image-sourced rows already show a thumbnail in the leading slot so they
  /// need no extra badge. Text (manual) is the default and doesn't warrant
  /// a chip either. Everything else gets a labeled pill (Chat / Barcode /
  /// Nutrition Label / Screenshot / Restaurant).
  Widget? _buildSourceBadge(FoodLog meal, Color textMuted) {
    final label = switch (meal.sourceType) {
      'chat' => 'AI Chat',
      'parse_app_screenshot' => 'App Screenshot',
      'parse_nutrition_label' => 'Nutrition Label',
      'barcode' => 'Barcode',
      'restaurant' => 'Restaurant',
      _ => null,
    };
    if (label == null) return null;
    final icon = switch (meal.sourceType) {
      'chat' => Icons.chat_bubble_outline_rounded,
      'parse_app_screenshot' => Icons.phone_iphone_rounded,
      'parse_nutrition_label' => Icons.receipt_long_rounded,
      'barcode' => Icons.qr_code_scanner_rounded,
      'restaurant' => Icons.storefront_outlined,
      _ => Icons.info_outline,
    };
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: textMuted.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 10, color: textMuted),
            const SizedBox(width: 4),
            Text(
              'via $label',
              style: TextStyle(fontSize: 10, color: textMuted, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  /// Long-press → quick-actions menu. Tap → details sheet.
  Widget _buildFoodItemRow({
    required BuildContext context,
    required FoodLog meal,
    required String foodName,
    required int calories,
    String? amount,
    double? proteinG,
    required DateTime time,
    required Color textPrimary,
    required Color textMuted,
    required Color accent,
    bool showTime = true,
    bool showLeading = true,
    Widget? leadingOverride,
    Future<bool> Function()? onDeleteChild,
  }) {
    final timeStr = TimeFormatters.logTime(time);

    return Dismissible(
      key: ValueKey('${meal.id}_${foodName}_${amount ?? ''}'),
      direction: DismissDirection.horizontal,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16),
        color: accent.withValues(alpha: 0.9),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit, color: Colors.white, size: 18),
            SizedBox(width: 4),
            Text('Edit', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: AppColors.error.withValues(alpha: 0.9),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Delete', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            SizedBox(width: 4),
            Icon(Icons.delete_outline, color: Colors.white, size: 18),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe right = Edit portion. For single-item meals route to the
          // per-item editor so macros are editable (and edits are audited
          // into food_log_edits + learned into user_food_overrides). For
          // multi-item meals fall through to the whole-meal multiplier sheet.
          if (meal.foodItems.length == 1) {
            _showEditItemPortionSheet(context, meal, 0);
          } else {
            _showEditPortionSheet(context, meal);
          }
          return false;
        }
        // Swipe left = Delete — single-item deletes whole log,
        // multi-item child delegates to onDeleteChild which removes just
        // this entry from parent.foodItems[].
        if (onDeleteChild != null) {
          await onDeleteChild();
          // Always return false: _removeChildItem triggers the async state
          // update; the rebuild removes this widget from the list. Returning
          // true would leave a dismissed Dismissible in the tree before the
          // async update finishes, which throws the "still part of tree" error.
          return false;
        }
        final messenger = ScaffoldMessenger.of(context);
        bool undone = false;
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            content: const Text('Meal deleted'),
            action: SnackBarAction(label: 'Undo', onPressed: () { undone = true; }),
            duration: const Duration(seconds: 4),
          ),
        );
        await Future.delayed(const Duration(seconds: 4));
        if (!undone) {
          onDeleteMeal(meal.id);
        }
        // Always return false so the Dismissible resets; the async state
        // mutation in onDeleteMeal triggers a rebuild that removes this row.
        return false;
      },
      child: InkWell(
        onTap: () => _showMealDetails(context, meal),
        onLongPress: () {
          HapticFeedback.mediumImpact();
          _showQuickActionsMenu(context, meal);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (showLeading) ...[
                leadingOverride ?? _buildSourceIndicator(
                  context: context,
                  meal: meal,
                  textMuted: textMuted,
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      foodName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (amount != null && amount.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          amount,
                          style: TextStyle(fontSize: 11, color: textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    // Source badge — "via AI Chat" / "via Barcode" / etc.
                    // Null for image-with-thumbnail (already visible) and
                    // plain text entries (default).
                    _buildSourceBadge(meal, textMuted) ?? const SizedBox.shrink(),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$calories cal',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  if (proteinG != null && proteinG > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '${proteinG.round()}g protein',
                        style: TextStyle(fontSize: 11, color: textMuted),
                      ),
                    ),
                  if (showTime)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 10,
                          color: textMuted.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Leading source indicator (28×28 slot)
  // Thumbnail for imageUrl, icon for barcode/chat/restaurant, else empty.
  // ──────────────────────────────────────────────────────────────

  Widget _buildSourceIndicator({
    required BuildContext context,
    required FoodLog meal,
    required Color textMuted,
  }) {
    return FoodSourceIndicator(
      imageUrl: meal.imageUrl,
      sourceType: meal.sourceType,
      heroTag: 'food-photo-${meal.id}',
      mutedColor: textMuted,
      viewerTitle: _viewerTitleForMeal(meal),
    );
  }

  /// Best-effort dish name for the fullscreen-photo top pill.
  /// Mirrors `_GroupedMealRow._groupTitle()` precedence so the pill
  /// matches the row label the user just tapped:
  ///   1. user's caption / query
  ///   2. first detected food item (image-source meals)
  ///   3. first food item name (any source) as last resort
  String? _viewerTitleForMeal(FoodLog meal) {
    String trim40(String s) => s.length <= 40 ? s : '${s.substring(0, 40)}…';
    final q = meal.userQuery?.trim();
    if (q != null && q.isNotEmpty) return trim40(q);
    if (meal.foodItems.isNotEmpty) {
      final name = meal.foodItems.first.name.trim();
      if (name.isNotEmpty) return trim40(name);
    }
    return null;
  }

  // ============================================
  // Meal Details Sheet (tap)
  // ============================================

  void _showMealDetails(BuildContext context, FoodLog meal) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDarkTheme ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDarkTheme ? AppColors.textMuted : AppColorsLight.textMuted;
    final accentEnum = AccentColorScope.of(context);
    final teal = accentEnum.getColor(isDarkTheme);
    final cardBorder = isDarkTheme ? AppColors.cardBorder : AppColorsLight.cardBorder;

    showGlassSheet(
      context: context,
      builder: (ctx) => GlassSheet(
        maxHeightFraction: 0.75,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    _getMealEmoji(meal.mealType),
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meal.mealType.substring(0, 1).toUpperCase() +
                              meal.mealType.substring(1),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          '${meal.totalCalories} kcal',
                          style: TextStyle(
                            fontSize: 14,
                            color: teal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showEditPortionSheet(context, meal);
                    },
                    icon: Icon(Icons.edit_outlined, color: teal, size: 20),
                    tooltip: 'Edit portion',
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _copyMealTo(context, meal);
                    },
                    icon: Icon(Icons.content_copy, color: teal, size: 20),
                    tooltip: 'Copy to...',
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _moveMealTo(context, meal);
                    },
                    icon: Icon(Icons.drive_file_move_outline, color: teal, size: 20),
                    tooltip: 'Move to...',
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      onDeleteMeal(meal.id);
                    },
                    icon: Icon(Icons.delete_outline, color: AppColors.error),
                    tooltip: 'Delete meal',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Food items list
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  // Photo thumbnail (for photo-logged meals) — tap to maximize
                  if (meal.imageUrl != null) ...[
                    GestureDetector(
                      onTap: () => showFullscreenImage(
                        ctx,
                        networkUrl: meal.imageUrl,
                        heroTag: 'meal_image_${meal.id}',
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Hero(
                              tag: 'meal_image_${meal.id}',
                              child: Image.network(
                                meal.imageUrl!,
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.fullscreen_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Food items — each field tap-to-edit; saves write
                  // back to the food_log row AND insert audit rows.
                  ..._buildEditableFoodItems(ctx, meal, textPrimary, textMuted, teal, cardBorder),

                  // Health Score & AI Feedback
                  if (meal.healthScore != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _scoreColor(meal.healthScore!).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _scoreColor(meal.healthScore!).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _scoreColor(meal.healthScore!).withValues(alpha: 0.2),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${meal.healthScore}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _scoreColor(meal.healthScore!),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Health Score',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                ),
                                Text(
                                  _scoreLabel(meal.healthScore!),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _scoreColor(meal.healthScore!),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Meal-level Inflammation Score
                  if (meal.inflammationScore != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _inflammationColor(meal.inflammationScore!).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _inflammationColor(meal.inflammationScore!).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _inflammationColor(meal.inflammationScore!).withValues(alpha: 0.2),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${meal.inflammationScore}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _inflammationColor(meal.inflammationScore!),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text('Inflammation Score',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () => _showInflammationInfo(context),
                                      child: Icon(Icons.info_outline, size: 16, color: textMuted),
                                    ),
                                  ],
                                ),
                                Text(
                                  _inflammationLabel(meal.inflammationScore!),
                                  style: TextStyle(fontSize: 11, color: _inflammationColor(meal.inflammationScore!)),
                                ),
                              ],
                            ),
                          ),
                          // Progress bar
                          SizedBox(
                            width: 80,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: meal.inflammationScore! / 10.0,
                                backgroundColor: cardBorder.withValues(alpha: 0.3),
                                valueColor: AlwaysStoppedAnimation<Color>(_inflammationColor(meal.inflammationScore!)),
                                minHeight: 6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Ultra-processed meal-level badge
                  if (meal.isUltraProcessed == true) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 18, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('Contains ultra-processed items',
                              style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w500)),
                          ),
                          GestureDetector(
                            onTap: () => _showUltraProcessedInfo(context),
                            child: Icon(Icons.info_outline, size: 16, color: Colors.red.withValues(alpha: 0.7)),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (meal.aiFeedback != null && meal.aiFeedback!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardBorder.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.auto_awesome, size: 16, color: teal),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              meal.aiFeedback!,
                              style: TextStyle(
                                fontSize: 12,
                                color: textMuted,
                                height: 1.4,
                              ),
                              maxLines: 5,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Notes
                  if (meal.notes != null && meal.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardBorder.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.note_outlined, size: 16, color: textMuted),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              meal.notes!,
                              style: TextStyle(fontSize: 12, color: textMuted, fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Mood & Energy
                  if (meal.moodBefore != null || meal.moodAfter != null || meal.energyLevel != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardBorder.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          if (meal.moodBeforeEnum != null) ...[
                            Text(meal.moodBeforeEnum!.emoji, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_forward, size: 12, color: textMuted),
                            const SizedBox(width: 4),
                          ],
                          if (meal.moodAfterEnum != null)
                            Text(meal.moodAfterEnum!.emoji, style: const TextStyle(fontSize: 16)),
                          if (meal.energyLevel != null) ...[
                            const Spacer(),
                            Icon(Icons.bolt, size: 14, color: teal),
                            const SizedBox(width: 2),
                            Text(
                              '${meal.energyLevel}/5',
                              style: TextStyle(fontSize: 12, color: textMuted, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  // Micronutrients
                  if (meal.hasMicronutrients) ...[
                    const SizedBox(height: 8),
                    _buildMicronutrientsSection(meal, textPrimary, textMuted, teal, cardBorder),
                  ],
                ],
              ),
            ),
            // Macros summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: cardBorder)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MacroSummaryItem(
                    label: 'Protein',
                    value: '${meal.proteinG.toStringAsFixed(0)}g',
                    color: AppColors.purple,
                    isDark: isDarkTheme,
                  ),
                  _MacroSummaryItem(
                    label: 'Carbs',
                    value: '${meal.carbsG.toStringAsFixed(0)}g',
                    color: AppColors.orange,
                    isDark: isDarkTheme,
                  ),
                  _MacroSummaryItem(
                    label: 'Fat',
                    value: '${meal.fatG.toStringAsFixed(0)}g',
                    color: AppColors.error,
                    isDark: isDarkTheme,
                  ),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  /// Renders each food item with inline-editable kcal/P/C/F. Wrapped in a
  /// single stateful widget (`_EditableFoodItemsList`) so edits get optimistic
  /// UI updates without waiting for the parent meal state to refresh from
  /// backend.
  List<Widget> _buildEditableFoodItems(
    BuildContext ctx,
    FoodLog meal,
    Color textPrimary,
    Color textMuted,
    Color teal,
    Color cardBorder,
  ) {
    return [
      _EditableFoodItemsList(
        meal: meal,
        textPrimary: textPrimary,
        textMuted: textMuted,
        accent: teal,
        cardBorder: cardBorder,
        onCommit: (logId, updatedItems, totalCal, totalP, totalC, totalF, edit) {
          onUpdateMeal(
            logId,
            totalCal,
            totalP,
            totalC,
            totalF,
            foodItems: updatedItems,
            itemEdits: [edit],
          );
        },
        onDeleteMeal: onDeleteMeal,
        onAnalyzeText: apiClient != null
            ? (description) async {
                final response = await apiClient!.post(
                  '/nutrition/analyze-text',
                  data: {'description': description},
                );
                return response.data as Map<String, dynamic>;
              }
            : null,
      ),
      const SizedBox(height: 8),
      if (onFetchItemEdits != null)
        _EditHistoryLink(
          logId: meal.id,
          accent: teal,
          textMuted: textMuted,
          fetchEdits: onFetchItemEdits!,
        ),
    ];
  }

  // ============================================
  // Long-Press Quick Actions Menu
  // ============================================

  void _showQuickActionsMenu(BuildContext context, FoodLog meal) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDarkTheme ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDarkTheme ? AppColors.textMuted : AppColorsLight.textMuted;
    final accentEnum = AccentColorScope.of(context);
    final teal = accentEnum.getColor(isDarkTheme);
    final cardBorder = isDarkTheme ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final foodName = meal.foodItems.isNotEmpty
        ? (meal.foodItems.length == 1
            ? meal.foodItems.first.name
            : '${meal.foodItems.first.name} + ${meal.foodItems.length - 1} more')
        : 'Food';

    showGlassSheet(
      context: context,
      builder: (ctx) => GlassSheet(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 16,
            bottom: MediaQuery.of(ctx).padding.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          foodName,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${meal.totalCalories} kcal',
                          style: TextStyle(fontSize: 12, color: textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: Icon(Icons.close, color: textMuted, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Edit group — single-item meals go straight to the per-item
              // editor so macros are editable (multi-item parent stays on
              // the multiplier-only whole-meal sheet to avoid ambiguous
              // parent-to-item delta distribution).
              _ActionTile(
                icon: Icons.edit_outlined,
                label: 'Edit portion',
                iconColor: teal,
                textColor: textPrimary,
                onTap: () {
                  Navigator.pop(ctx);
                  if (meal.foodItems.length == 1) {
                    _showEditItemPortionSheet(context, meal, 0);
                  } else {
                    _showEditPortionSheet(context, meal);
                  }
                },
              ),
              _ActionTile(
                icon: Icons.schedule,
                label: 'Edit time',
                iconColor: teal,
                textColor: textPrimary,
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditTimeDialog(context, meal);
                },
              ),
              _ActionTile(
                icon: Icons.note_add_outlined,
                label: meal.notes != null ? 'Edit note' : 'Add note',
                iconColor: teal,
                textColor: textPrimary,
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditNotesSheet(context, meal);
                },
              ),

              Divider(height: 16, color: cardBorder),

              // Organize group
              _ActionTile(
                icon: Icons.content_copy,
                label: 'Copy to...',
                iconColor: teal,
                textColor: textPrimary,
                onTap: () {
                  Navigator.pop(ctx);
                  _copyMealTo(context, meal);
                },
              ),
              _ActionTile(
                icon: Icons.drive_file_move_outline,
                label: 'Move to...',
                iconColor: teal,
                textColor: textPrimary,
                onTap: () {
                  Navigator.pop(ctx);
                  _moveMealTo(context, meal);
                },
              ),
              _ActionTile(
                icon: Icons.bookmark_add_outlined,
                label: 'Save to My Foods',
                iconColor: teal,
                textColor: textPrimary,
                onTap: () {
                  Navigator.pop(ctx);
                  onSaveFoodToFavorites(meal);
                },
              ),

              Divider(height: 16, color: cardBorder),

              // Feedback group
              _ActionTile(
                icon: Icons.mood,
                label: 'Log mood & energy',
                iconColor: teal,
                textColor: textPrimary,
                onTap: () {
                  Navigator.pop(ctx);
                  _showMoodEnergySheet(context, meal);
                },
              ),
              _ActionTile(
                icon: Icons.flag_outlined,
                label: 'Report incorrect data',
                iconColor: teal,
                textColor: textPrimary,
                onTap: () {
                  Navigator.pop(ctx);
                  _showReportDialog(context, meal);
                },
              ),

              Divider(height: 16, color: cardBorder),

              // Delete
              _ActionTile(
                icon: Icons.delete_outline,
                label: 'Delete',
                iconColor: AppColors.error,
                textColor: AppColors.error,
                onTap: () {
                  Navigator.pop(ctx);
                  onDeleteMeal(meal.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // Per-item Quick Actions Menu
  // ============================================

  /// Quick-actions sheet scoped to a single food item inside a multi-item
  /// parent meal. Offers per-item Adjust Portion, Copy-to-meal, Move-to-meal,
  /// and Remove. Sibling of `_showQuickActionsMenu` (meal-scoped).
  void _showItemQuickActionsMenu(BuildContext context, FoodLog parent, int itemIdx) {
    final item = parent.foodItems[itemIdx];
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDarkTheme ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDarkTheme ? AppColors.textMuted : AppColorsLight.textMuted;
    final accent = AccentColorScope.of(context).getColor(isDarkTheme);

    showGlassSheet(
      context: context,
      builder: (ctx) => GlassSheet(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 16,
            bottom: MediaQuery.of(ctx).padding.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header — this food's name + its cal so the user can tell they
              // got the item-scoped menu (vs. the meal-scoped one).
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${item.calories ?? 0} kcal · ${item.amount ?? ''}',
                          style: TextStyle(fontSize: 12, color: textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: Icon(Icons.close, color: textMuted, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              _ActionTile(
                icon: Icons.edit_outlined,
                label: 'Adjust portion',
                iconColor: accent,
                textColor: textPrimary,
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditItemPortionSheet(context, parent, itemIdx);
                },
              ),
              if (onCopyItem != null)
                _ActionTile(
                  icon: Icons.copy_outlined,
                  label: 'Copy to another meal',
                  iconColor: accent,
                  textColor: textPrimary,
                  onTap: () {
                    Navigator.pop(ctx);
                    _showMealTypePicker(context, parent, 'Copy ${item.name} to...', (type) {
                      onCopyItem!(parent.id, itemIdx, type);
                    });
                  },
                ),
              if (onMoveItem != null)
                _ActionTile(
                  icon: Icons.drive_file_move_outlined,
                  label: 'Move to another meal',
                  iconColor: accent,
                  textColor: textPrimary,
                  onTap: () {
                    Navigator.pop(ctx);
                    _showMealTypePicker(context, parent, 'Move ${item.name} to...', (type) {
                      onMoveItem!(parent.id, itemIdx, type);
                    });
                  },
                ),
              const Divider(height: 16),
              _ActionTile(
                icon: Icons.delete_outline,
                label: 'Remove from meal',
                iconColor: AppColors.error,
                textColor: AppColors.error,
                onTap: () {
                  Navigator.pop(ctx);
                  // Delegate to the existing _FoodGroup helper via a synthetic
                  // dismissal — same effect as swipe-left.
                  _removeChildItemFromMenu(context, parent, itemIdx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper: mirrors `_FoodGroup._removeChildItem` but invoked from the menu
  /// rather than a Dismissible. Updates the parent meal's items array and
  /// recomputes totals; deletes the whole log when the item was the last one.
  void _removeChildItemFromMenu(BuildContext context, FoodLog parent, int itemIdx) {
    final messenger = ScaffoldMessenger.of(context);
    bool undone = false;
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Removed ${parent.foodItems[itemIdx].name}'),
        action: SnackBarAction(label: 'Undo', onPressed: () { undone = true; }),
        duration: const Duration(seconds: 4),
      ),
    );
    Future.delayed(const Duration(seconds: 4), () {
      if (undone) return;
      if (parent.foodItems.length <= 1) {
        onDeleteMeal(parent.id);
        return;
      }
      final remaining = [
        for (int i = 0; i < parent.foodItems.length; i++)
          if (i != itemIdx) parent.foodItems[i],
      ];
      final newCal = remaining.fold<int>(0, (s, f) => s + (f.calories ?? 0));
      final newProtein = remaining.fold<double>(0, (s, f) => s + (f.proteinG ?? 0));
      final newCarbs = remaining.fold<double>(0, (s, f) => s + (f.carbsG ?? 0));
      final newFat = remaining.fold<double>(0, (s, f) => s + (f.fatG ?? 0));
      onUpdateMeal(
        parent.id,
        newCal,
        newProtein,
        newCarbs,
        newFat,
        foodItems: remaining.map((f) => f.toJson()).toList(),
      );
    });
  }

  // ============================================
  // Edit Portion Sheet
  // ============================================

  void _showEditPortionSheet(BuildContext context, FoodLog meal) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDarkTheme ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDarkTheme ? AppColors.textMuted : AppColorsLight.textMuted;
    final accentEnum = AccentColorScope.of(context);
    final accent = accentEnum.getColor(isDarkTheme);
    final glassSurface = isDarkTheme ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final macroProtein = isDarkTheme ? AppColors.macroProtein : AppColorsLight.macroProtein;
    final macroCarbs = isDarkTheme ? AppColors.macroCarbs : AppColorsLight.macroCarbs;
    final macroFat = isDarkTheme ? AppColors.macroFat : AppColorsLight.macroFat;

    // Baselines captured at open time — used both for multiplier-driven
    // defaults and as the `previous_value` in any per-item audit rows when
    // the user overrides a whole-meal macro. Capturing whole-meal AND
    // per-item baselines lets us distribute a whole-meal correction back
    // to items proportionally by each item's pre-edit share of that macro.
    final baselineMealCal = meal.totalCalories.toDouble();
    final baselineMealP = meal.proteinG;
    final baselineMealC = meal.carbsG;
    final baselineMealF = meal.fatG;
    final itemBaselines = [
      for (final it in meal.foodItems)
        {
          'cal': (it.calories ?? 0).toDouble(),
          'p': it.proteinG ?? 0.0,
          'c': it.carbsG ?? 0.0,
          'f': it.fatG ?? 0.0,
        },
    ];

    // Per-field "user typed here" flags — prevents scaled-by-multiplier
    // values from being misinterpreted as corrections when the user only
    // touched the portion scale.
    final calCtl = TextEditingController(text: baselineMealCal.round().toString());
    final pCtl = TextEditingController(text: baselineMealP.round().toString());
    final cCtl = TextEditingController(text: baselineMealC.round().toString());
    final fCtl = TextEditingController(text: baselineMealF.round().toString());
    bool calOverridden = false;
    bool pOverridden = false;
    bool cOverridden = false;
    bool fOverridden = false;

    double multiplier = 1.0;

    void refreshMacroControllers() {
      if (!calOverridden) calCtl.text = (baselineMealCal * multiplier).round().toString();
      if (!pOverridden) pCtl.text = (baselineMealP * multiplier).round().toString();
      if (!cOverridden) cCtl.text = (baselineMealC * multiplier).round().toString();
      if (!fOverridden) fCtl.text = (baselineMealF * multiplier).round().toString();
    }

    double parseOr(TextEditingController c, double fallback) {
      final v = double.tryParse(c.text.trim());
      return (v != null && v >= 0) ? v : fallback;
    }

    // Weight unit toggle state
    const weightUnits = ['g', 'oz', 'lb', 'kg', 'ml', 'mg'];
    int selectedUnitIndex = 0;

    // Determine available edit modes
    final hasWeight = meal.hasWeightData;
    final hasCount = meal.hasCountData;
    final firstItemWithWeight = hasWeight ? meal.foodItems.firstWhere((i) => i.hasWeightData) : null;
    final firstItemWithCount = hasCount ? meal.foodItems.firstWhere((i) => i.hasCountData) : null;

    // Initialize unit index from the item's unit
    if (firstItemWithWeight != null) {
      final itemUnit = (firstItemWithWeight.unit ?? 'g').toLowerCase();
      final idx = weightUnits.indexOf(itemUnit);
      if (idx >= 0) selectedUnitIndex = idx;
    }

    // Serving presets with size labels
    const servingPresets = [
      (label: '\u00BD', multiplier: 0.5, size: 'Small'),
      (label: '\u00BE', multiplier: 0.75, size: 'Medium'),
      (label: '1x', multiplier: 1.0, size: 'Standard'),
      (label: '1\u00BC', multiplier: 1.25, size: 'Large'),
      (label: '1\u00BD', multiplier: 1.5, size: 'X-Large'),
      (label: '2x', multiplier: 2.0, size: 'Double'),
      (label: '3x', multiplier: 3.0, size: 'Triple'),
    ];

    // Unit conversion factors from grams
    double convertFromGrams(double grams, String unit) {
      switch (unit) {
        case 'oz': return grams / 28.3495;
        case 'lb': return grams / 453.592;
        case 'kg': return grams / 1000.0;
        case 'ml': return grams; // 1:1 for water-density approximation
        case 'mg': return grams * 1000.0;
        default: return grams;
      }
    }

    double convertToGrams(double value, String unit) {
      switch (unit) {
        case 'oz': return value * 28.3495;
        case 'lb': return value * 453.592;
        case 'kg': return value * 1000.0;
        case 'ml': return value;
        case 'mg': return value / 1000.0;
        default: return value;
      }
    }

    showGlassSheet(
      context: context,
      builder: (ctx) => GlassSheet(
        child: StatefulBuilder(
          builder: (context, setState) {
            final currentUnit = weightUnits[selectedUnitIndex];

            return Padding(
              padding: EdgeInsets.only(
                left: 16, right: 16, top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(Icons.tune, color: accent, size: 20),
                      const SizedBox(width: 8),
                      Text('Adjust Portion', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${(multiplier * 100).round()}%',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: accent),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Serving presets with size labels
                  Text('Servings', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textMuted)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: servingPresets.map((preset) {
                      final isSelected = (multiplier - preset.multiplier).abs() < 0.01;
                      return GestureDetector(
                        onTap: () => setState(() {
                          multiplier = preset.multiplier;
                          refreshMacroControllers();
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? accent : glassSurface,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                preset.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Colors.white : textPrimary,
                                ),
                              ),
                              Text(
                                preset.size,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: isSelected ? Colors.white70 : textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  // Weight + Quantity on same row
                  if (hasWeight || hasCount) ...[
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Weight input with unit toggle
                        if (hasWeight && firstItemWithWeight != null)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Weight', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textMuted)),
                                const SizedBox(height: 8),
                                TextField(
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: TextStyle(color: textPrimary, fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: '${convertFromGrams((firstItemWithWeight.weightG ?? 0) * multiplier, currentUnit).round()}',
                                    hintStyle: TextStyle(color: textMuted),
                                    suffixIcon: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedUnitIndex = (selectedUnitIndex + 1) % weightUnits.length;
                                        });
                                      },
                                      child: Container(
                                        width: 44,
                                        alignment: Alignment.center,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: accent.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            currentUnit,
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: accent),
                                          ),
                                        ),
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: glassSurface,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    isDense: true,
                                  ),
                                  onChanged: (value) {
                                    final newValue = double.tryParse(value);
                                    if (newValue != null && newValue > 0 && firstItemWithWeight.weightG != null && firstItemWithWeight.weightG! > 0) {
                                      final newWeightG = convertToGrams(newValue, currentUnit);
                                      setState(() {
                                        multiplier = (newWeightG / firstItemWithWeight.weightG!).clamp(0.1, 10.0);
                                        refreshMacroControllers();
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),

                        // Spacer between weight and quantity
                        if (hasWeight && firstItemWithWeight != null && hasCount && firstItemWithCount != null)
                          const SizedBox(width: 16),

                        // Quantity input
                        if (hasCount && firstItemWithCount != null)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Quantity', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textMuted)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _AdjustBtn(icon: Icons.remove, color: accent, onTap: () {
                                      final currentCount = (firstItemWithCount.count! * multiplier).round();
                                      if (currentCount > 1) {
                                        setState(() {
                                          multiplier = ((currentCount - 1) / firstItemWithCount.count!).clamp(0.1, 10.0);
                                          refreshMacroControllers();
                                        });
                                      }
                                    }),
                                    Expanded(
                                      child: Center(
                                        child: Text(
                                          '${(firstItemWithCount.count! * multiplier).round()}',
                                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary),
                                        ),
                                      ),
                                    ),
                                    _AdjustBtn(icon: Icons.add, color: accent, onTap: () {
                                      final currentCount = (firstItemWithCount.count! * multiplier).round();
                                      setState(() {
                                        multiplier = ((currentCount + 1) / firstItemWithCount.count!).clamp(0.1, 10.0);
                                        refreshMacroControllers();
                                      });
                                    }),
                                  ],
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Editable whole-meal macros. The AI occasionally nails
                  // portion scale but misses on a macro — let the user fix
                  // the aggregate. Typed corrections are distributed to
                  // items proportionally (see Save handler) so food_items[]
                  // stays coherent and per-item audit rows fire correctly.
                  Text(
                    'Nutrition (edit if the AI got it wrong)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textMuted),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _MacroField(
                        controller: calCtl,
                        label: 'Cal',
                        color: textPrimary,
                        glassSurface: glassSurface,
                        onChanged: () => calOverridden = true,
                      )),
                      const SizedBox(width: 8),
                      Expanded(child: _MacroField(
                        controller: pCtl,
                        label: 'P (g)',
                        color: macroProtein,
                        glassSurface: glassSurface,
                        onChanged: () => pOverridden = true,
                      )),
                      const SizedBox(width: 8),
                      Expanded(child: _MacroField(
                        controller: cCtl,
                        label: 'C (g)',
                        color: macroCarbs,
                        glassSurface: glassSurface,
                        onChanged: () => cOverridden = true,
                      )),
                      const SizedBox(width: 8),
                      Expanded(child: _MacroField(
                        controller: fCtl,
                        label: 'F (g)',
                        color: macroFat,
                        glassSurface: glassSurface,
                        onChanged: () => fOverridden = true,
                      )),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Read the final numbers the user sees on-screen —
                        // whether typed or multiplier-scaled.
                        final newCal = parseOr(calCtl, baselineMealCal * multiplier).round();
                        final newP = parseOr(pCtl, baselineMealP * multiplier);
                        final newC = parseOr(cCtl, baselineMealC * multiplier);
                        final newF = parseOr(fCtl, baselineMealF * multiplier);

                        final anyOverride = calOverridden || pOverridden || cOverridden || fOverridden;
                        if (!anyOverride) {
                          // Pure portion scale — old behavior: update totals,
                          // leave food_items[] untouched. No audit rows.
                          onUpdateMeal(meal.id, newCal, newP, newC, newF);
                          return;
                        }

                        // Distribute whole-meal corrections back to each item
                        // by that item's share of the pre-edit meal total.
                        // Zero-share guard: if a macro was 0 across the whole
                        // meal, split the new value equally across items so
                        // we don't drop it.
                        double share(int i, String field, double totalBaseline) {
                          if (totalBaseline <= 0) {
                            return 1.0 / meal.foodItems.length;
                          }
                          final ib = itemBaselines[i][field]!;
                          return ib / totalBaseline;
                        }

                        final updatedItems = <Map<String, dynamic>>[];
                        final edits = <FoodItemEdit>[];
                        for (int i = 0; i < meal.foodItems.length; i++) {
                          final it = meal.foodItems[i];
                          final b = itemBaselines[i];
                          // Overridden macros → proportional distribution.
                          // Non-overridden → multiplier-scaled from baseline.
                          final itCal = calOverridden
                              ? (share(i, 'cal', baselineMealCal) * newCal).round()
                              : (b['cal']! * multiplier).round();
                          final itP = pOverridden
                              ? share(i, 'p', baselineMealP) * newP
                              : b['p']! * multiplier;
                          final itC = cOverridden
                              ? share(i, 'c', baselineMealC) * newC
                              : b['c']! * multiplier;
                          final itF = fOverridden
                              ? share(i, 'f', baselineMealF) * newF
                              : b['f']! * multiplier;

                          updatedItems.add({
                            ...it.toJson(),
                            'calories': itCal,
                            'protein_g': itP,
                            'carbs_g': itC,
                            'fat_g': itF,
                            if (multiplier != 1.0) 'portion_multiplier': multiplier,
                          });

                          // Per-item audit rows — ONLY for fields the user
                          // overrode at the parent level. Portion-scaled
                          // changes aren't corrections, so no audit and no
                          // user_food_overrides UPSERT for them.
                          void maybeEdit(String field, double prev, double next, bool overridden) {
                            if (!overridden) return;
                            if ((prev - next).abs() < 0.01) return;
                            edits.add(FoodItemEdit(
                              foodItemIndex: i,
                              foodItemName: it.name,
                              editedField: field,
                              previousValue: prev,
                              updatedValue: next,
                            ));
                          }
                          maybeEdit('calories', b['cal']!, itCal.toDouble(), calOverridden);
                          maybeEdit('protein_g', b['p']!, itP, pOverridden);
                          maybeEdit('carbs_g', b['c']!, itC, cOverridden);
                          maybeEdit('fat_g', b['f']!, itF, fOverridden);
                        }

                        // Recompute totals from the distributed items so the
                        // parent row sums exactly match what we stored in
                        // food_items[] (avoids rounding drift).
                        int totalCal = 0;
                        double totalP = 0, totalC = 0, totalF = 0;
                        for (final it in updatedItems) {
                          totalCal += (it['calories'] as num? ?? 0).round();
                          totalP += (it['protein_g'] as num? ?? 0).toDouble();
                          totalC += (it['carbs_g'] as num? ?? 0).toDouble();
                          totalF += (it['fat_g'] as num? ?? 0).toDouble();
                        }

                        onUpdateMeal(
                          meal.id,
                          totalCal,
                          totalP,
                          totalC,
                          totalF,
                          foodItems: updatedItems,
                          itemEdits: edits.isNotEmpty ? edits : null,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================
  // Per-item Adjust Portion sheet — scoped to parent.foodItems[itemIdx].
  // Weight/count/serving controls + editable Cal/P/C/F. Save writes back
  // the updated item, recomputes parent totals, and emits FoodItemEdit
  // audit rows for each changed field so `food_log_edits` tracks the
  // correction AND the backend UPSERTs user_food_overrides for future logs.
  // ============================================

  void _showEditItemPortionSheet(BuildContext context, FoodLog parent, int itemIdx) {
    final item = parent.foodItems[itemIdx];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final macroP = isDark ? AppColors.macroProtein : AppColorsLight.macroProtein;
    final macroC = isDark ? AppColors.macroCarbs : AppColorsLight.macroCarbs;
    final macroF = isDark ? AppColors.macroFat : AppColorsLight.macroFat;

    // Baselines captured once at open time — used both to compute the
    // multiplier-driven defaults and as `previous_value` in the audit rows.
    final baselineCal = (item.calories ?? 0).toDouble();
    final baselineP = item.proteinG ?? 0.0;
    final baselineC = item.carbsG ?? 0.0;
    final baselineF = item.fatG ?? 0.0;

    double multiplier = 1.0;
    const weightUnits = ['g', 'oz', 'lb', 'kg', 'ml', 'mg'];
    int selectedUnitIndex = () {
      final u = (item.unit ?? 'g').toLowerCase();
      final i = weightUnits.indexOf(u);
      return i >= 0 ? i : 0;
    }();

    final hasWeight = item.hasWeightData;
    final hasCount = item.hasCountData;

    const servingPresets = [
      (label: '\u00BD', multiplier: 0.5, size: 'Small'),
      (label: '\u00BE', multiplier: 0.75, size: 'Medium'),
      (label: '1x', multiplier: 1.0, size: 'Standard'),
      (label: '1\u00BC', multiplier: 1.25, size: 'Large'),
      (label: '1\u00BD', multiplier: 1.5, size: 'X-Large'),
      (label: '2x', multiplier: 2.0, size: 'Double'),
      (label: '3x', multiplier: 3.0, size: 'Triple'),
    ];

    double convertFromGrams(double grams, String unit) {
      switch (unit) {
        case 'oz': return grams / 28.3495;
        case 'lb': return grams / 453.592;
        case 'kg': return grams / 1000.0;
        case 'ml': return grams;
        case 'mg': return grams * 1000.0;
        default: return grams;
      }
    }

    double convertToGrams(double value, String unit) {
      switch (unit) {
        case 'oz': return value * 28.3495;
        case 'lb': return value * 453.592;
        case 'kg': return value * 1000.0;
        case 'ml': return value;
        case 'mg': return value / 1000.0;
        default: return value;
      }
    }

    // Controllers for the four editable macro fields. Prefilled with
    // baseline × 1.0 = baseline. If the user changes the multiplier or
    // weight/count AFTER opening, we re-fill these controllers UNLESS the
    // user has manually typed into them (the `*Overridden` flags).
    final calController = TextEditingController(text: baselineCal.round().toString());
    final pController = TextEditingController(text: baselineP.round().toString());
    final cController = TextEditingController(text: baselineC.round().toString());
    final fController = TextEditingController(text: baselineF.round().toString());

    bool calOverridden = false;
    bool pOverridden = false;
    bool cOverridden = false;
    bool fOverridden = false;

    // When multiplier changes and the user hasn't manually typed in a field,
    // we refresh the field from `baseline × multiplier`.
    void refreshMacroControllers() {
      if (!calOverridden) calController.text = (baselineCal * multiplier).round().toString();
      if (!pOverridden) pController.text = (baselineP * multiplier).round().toString();
      if (!cOverridden) cController.text = (baselineC * multiplier).round().toString();
      if (!fOverridden) fController.text = (baselineF * multiplier).round().toString();
    }

    double parseOr(TextEditingController c, double fallback) {
      final v = double.tryParse(c.text.trim());
      return (v != null && v >= 0) ? v : fallback;
    }

    showGlassSheet(
      context: context,
      builder: (ctx) => GlassSheet(
        child: StatefulBuilder(
          builder: (context, setState) {
            final currentUnit = weightUnits[selectedUnitIndex];

            return Padding(
              padding: EdgeInsets.only(
                left: 16, right: 16, top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header — food name on the right chip (instead of the whole-meal 100%)
                  Row(
                    children: [
                      Icon(Icons.tune, color: accent, size: 20),
                      const SizedBox(width: 8),
                      Text('Adjust Portion', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary)),
                      const Spacer(),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            item.name,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: accent),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Serving presets
                  Text('Servings', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textMuted)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: servingPresets.map((preset) {
                      final isSelected = (multiplier - preset.multiplier).abs() < 0.01;
                      return GestureDetector(
                        onTap: () => setState(() {
                          multiplier = preset.multiplier;
                          refreshMacroControllers();
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? accent : glassSurface,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                preset.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Colors.white : textPrimary,
                                ),
                              ),
                              Text(
                                preset.size,
                                style: TextStyle(fontSize: 9, color: isSelected ? Colors.white70 : textMuted),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  // Weight + Count row — only shown when the item has those dims
                  if (hasWeight || hasCount) ...[
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasWeight && item.weightG != null)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Weight', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textMuted)),
                                const SizedBox(height: 8),
                                TextField(
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: TextStyle(color: textPrimary, fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: '${convertFromGrams(item.weightG! * multiplier, currentUnit).round()}',
                                    hintStyle: TextStyle(color: textMuted),
                                    suffixIcon: GestureDetector(
                                      onTap: () => setState(() {
                                        selectedUnitIndex = (selectedUnitIndex + 1) % weightUnits.length;
                                      }),
                                      child: Container(
                                        width: 44,
                                        alignment: Alignment.center,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: accent.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            currentUnit,
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: accent),
                                          ),
                                        ),
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: glassSurface,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    isDense: true,
                                  ),
                                  onChanged: (value) {
                                    final newValue = double.tryParse(value);
                                    if (newValue != null && newValue > 0 && item.weightG != null && item.weightG! > 0) {
                                      final newWeightG = convertToGrams(newValue, currentUnit);
                                      setState(() {
                                        multiplier = (newWeightG / item.weightG!).clamp(0.1, 10.0);
                                        refreshMacroControllers();
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        if (hasWeight && item.weightG != null && hasCount && item.count != null)
                          const SizedBox(width: 16),
                        if (hasCount && item.count != null)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Quantity', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textMuted)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _AdjustBtn(icon: Icons.remove, color: accent, onTap: () {
                                      final currentCount = (item.count! * multiplier).round();
                                      if (currentCount > 1) {
                                        setState(() {
                                          multiplier = ((currentCount - 1) / item.count!).clamp(0.1, 10.0);
                                          refreshMacroControllers();
                                        });
                                      }
                                    }),
                                    Expanded(
                                      child: Center(
                                        child: Text(
                                          '${(item.count! * multiplier).round()}',
                                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary),
                                        ),
                                      ),
                                    ),
                                    _AdjustBtn(icon: Icons.add, color: accent, onTap: () {
                                      final currentCount = (item.count! * multiplier).round();
                                      setState(() {
                                        multiplier = ((currentCount + 1) / item.count!).clamp(0.1, 10.0);
                                        refreshMacroControllers();
                                      });
                                    }),
                                  ],
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Editable macros — user can override anything the AI got wrong.
                  Text(
                    'Nutrition (edit if the AI got it wrong)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textMuted),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _MacroField(
                        controller: calController,
                        label: 'Cal',
                        color: textPrimary,
                        glassSurface: glassSurface,
                        onChanged: () => calOverridden = true,
                      )),
                      const SizedBox(width: 8),
                      Expanded(child: _MacroField(
                        controller: pController,
                        label: 'P (g)',
                        color: macroP,
                        glassSurface: glassSurface,
                        onChanged: () => pOverridden = true,
                      )),
                      const SizedBox(width: 8),
                      Expanded(child: _MacroField(
                        controller: cController,
                        label: 'C (g)',
                        color: macroC,
                        glassSurface: glassSurface,
                        onChanged: () => cOverridden = true,
                      )),
                      const SizedBox(width: 8),
                      Expanded(child: _MacroField(
                        controller: fController,
                        label: 'F (g)',
                        color: macroF,
                        glassSurface: glassSurface,
                        onChanged: () => fOverridden = true,
                      )),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        final newCal = parseOr(calController, baselineCal).round();
                        final newP = parseOr(pController, baselineP);
                        final newC = parseOr(cController, baselineC);
                        final newF = parseOr(fController, baselineF);

                        // Build the updated item JSON preserving non-macro fields
                        // (ingredients, micros, weight_g, count, unit, etc.).
                        final updatedItemJson = <String, dynamic>{
                          ...item.toJson(),
                          'calories': newCal,
                          'protein_g': newP,
                          'carbs_g': newC,
                          'fat_g': newF,
                          if (multiplier != 1.0) 'portion_multiplier': multiplier,
                        };

                        // Replace just this item in the parent's items array.
                        final updatedItems = <Map<String, dynamic>>[
                          for (int i = 0; i < parent.foodItems.length; i++)
                            if (i == itemIdx) updatedItemJson else parent.foodItems[i].toJson(),
                        ];

                        // Build one FoodItemEdit per field the user MANUALLY
                        // TYPED in. Fields that only changed because of a
                        // serving/weight/count multiplier scale are portion
                        // changes, not corrections — those land in the
                        // food_items[] JSONB (and the parent totals) but
                        // must NOT produce audit rows or personalize future
                        // logs via user_food_overrides.
                        final edits = <FoodItemEdit>[];
                        void maybeEdit(String field, double prev, double next, bool overridden) {
                          if (!overridden) return;
                          if ((prev - next).abs() < 0.01) return;
                          edits.add(FoodItemEdit(
                            foodItemIndex: itemIdx,
                            foodItemName: item.name,
                            editedField: field,
                            previousValue: prev,
                            updatedValue: next,
                          ));
                        }
                        maybeEdit('calories', baselineCal, newCal.toDouble(), calOverridden);
                        maybeEdit('protein_g', baselineP, newP, pOverridden);
                        maybeEdit('carbs_g', baselineC, newC, cOverridden);
                        maybeEdit('fat_g', baselineF, newF, fOverridden);

                        // Recompute parent totals from the full updated items list.
                        int totalCal = 0;
                        double totalP = 0, totalC = 0, totalF = 0;
                        for (final it in updatedItems) {
                          totalCal += (it['calories'] as num? ?? 0).round();
                          totalP += (it['protein_g'] as num? ?? 0).toDouble();
                          totalC += (it['carbs_g'] as num? ?? 0).toDouble();
                          totalF += (it['fat_g'] as num? ?? 0).toDouble();
                        }

                        Navigator.pop(context);
                        onUpdateMeal(
                          parent.id,
                          totalCal,
                          totalP,
                          totalC,
                          totalF,
                          foodItems: updatedItems,
                          itemEdits: edits.isNotEmpty ? edits : null,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================
  // Copy / Move Meal Pickers
  // ============================================

  void _copyMealTo(BuildContext parentContext, FoodLog meal) {
    _showMealTypePicker(parentContext, meal, 'Copy to...', (type) {
      onCopyMeal(meal.id, type);
    });
  }

  void _moveMealTo(BuildContext parentContext, FoodLog meal) {
    _showMealTypePicker(parentContext, meal, 'Move to...', (type) {
      onMoveMeal(meal.id, type);
    });
  }

  void _showMealTypePicker(BuildContext parentContext, FoodLog meal, String title, void Function(String type) onSelect) {
    final isDarkTheme = Theme.of(parentContext).brightness == Brightness.dark;
    final textPrimary = isDarkTheme ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final accentEnum = AccentColorScope.of(parentContext);
    final accent = accentEnum.getColor(isDarkTheme);

    final mealTypes = [
      {'id': 'breakfast', 'label': 'Breakfast', 'emoji': '\u{1F373}'},
      {'id': 'lunch', 'label': 'Lunch', 'emoji': '\u{2600}\u{FE0F}'},
      {'id': 'dinner', 'label': 'Dinner', 'emoji': '\u{1F319}'},
      {'id': 'snack', 'label': 'Snack', 'emoji': '\u{1F34E}'},
    ];

    showGlassSheet(
      context: parentContext,
      builder: (ctx) => GlassSheet(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 16,
            bottom: MediaQuery.of(ctx).padding.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
              ),
              const SizedBox(height: 12),
              ...mealTypes.map((type) => ListTile(
                leading: Text(type['emoji']!, style: const TextStyle(fontSize: 20)),
                title: Text(
                  type['label']!,
                  style: TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                tileColor: meal.mealType == type['id'] ? accent.withValues(alpha: 0.1) : null,
                trailing: meal.mealType == type['id']
                    ? Text('Current', style: TextStyle(fontSize: 12, color: accent))
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  onSelect(type['id']!);
                },
              )),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // Edit Time Dialog
  // ============================================

  void _showEditTimeDialog(BuildContext context, FoodLog meal) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(meal.loggedAt),
    );
    if (time != null) {
      final newDateTime = DateTime(
        meal.loggedAt.year,
        meal.loggedAt.month,
        meal.loggedAt.day,
        time.hour,
        time.minute,
      );
      onUpdateMealTime(meal.id, newDateTime);
    }
  }

  // ============================================
  // Edit Notes Sheet
  // ============================================

  void _showEditNotesSheet(BuildContext context, FoodLog meal) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDarkTheme ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDarkTheme ? AppColors.textMuted : AppColorsLight.textMuted;
    final accentEnum = AccentColorScope.of(context);
    final accent = accentEnum.getColor(isDarkTheme);
    final glassSurface = isDarkTheme ? AppColors.glassSurface : AppColorsLight.glassSurface;

    final controller = TextEditingController(text: meal.notes ?? '');

    showGlassSheet(
      context: context,
      builder: (ctx) => GlassSheet(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).padding.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Note', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 3,
                maxLength: 500,
                autofocus: true,
                style: TextStyle(color: textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'e.g. ate at restaurant, homemade...',
                  hintStyle: TextStyle(color: textMuted),
                  filled: true,
                  fillColor: glassSurface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    onUpdateMealNotes(meal.id, controller.text.trim());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) => controller.dispose());
  }

  // ============================================
  // Mood & Energy Sheet
  // ============================================

  void _showMoodEnergySheet(BuildContext context, FoodLog meal) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDarkTheme ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDarkTheme ? AppColors.textMuted : AppColorsLight.textMuted;
    final accentEnum = AccentColorScope.of(context);
    final accent = accentEnum.getColor(isDarkTheme);
    final glassSurface = isDarkTheme ? AppColors.glassSurface : AppColorsLight.glassSurface;

    FoodMood? moodBefore = meal.moodBeforeEnum;
    FoodMood? moodAfter = meal.moodAfterEnum;
    int energyLevel = meal.energyLevel ?? 3;

    showGlassSheet(
      context: context,
      builder: (ctx) => GlassSheet(
        child: StatefulBuilder(
          builder: (_, setState) => Padding(
            padding: EdgeInsets.only(
              left: 16, right: 16, top: 16,
              bottom: MediaQuery.of(ctx).padding.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('How did you feel?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary)),
                const SizedBox(height: 16),

                // Before eating
                Text('Before eating', style: TextStyle(fontSize: 13, color: textMuted)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: FoodMood.values.map((mood) {
                    final isSelected = moodBefore == mood;
                    return GestureDetector(
                      onTap: () => setState(() => moodBefore = isSelected ? null : mood),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? accent : glassSurface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${mood.emoji} ${mood.displayName}',
                          style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : textPrimary),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // After eating
                Text('After eating', style: TextStyle(fontSize: 13, color: textMuted)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: FoodMood.values.map((mood) {
                    final isSelected = moodAfter == mood;
                    return GestureDetector(
                      onTap: () => setState(() => moodAfter = isSelected ? null : mood),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? accent : glassSurface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${mood.emoji} ${mood.displayName}',
                          style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : textPrimary),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Energy level
                Row(
                  children: [
                    Text('Energy level', style: TextStyle(fontSize: 13, color: textMuted)),
                    const Spacer(),
                    Text('$energyLevel/5', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: accent)),
                  ],
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: accent,
                    inactiveTrackColor: glassSurface,
                    thumbColor: accent,
                    overlayColor: accent.withValues(alpha: 0.2),
                  ),
                  child: Slider(
                    value: energyLevel.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    onChanged: (v) => setState(() => energyLevel = v.round()),
                  ),
                ),
                const SizedBox(height: 16),

                // Save
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      onUpdateMealMood(
                        meal.id,
                        moodBefore: moodBefore?.value,
                        moodAfter: moodAfter?.value,
                        energyLevel: energyLevel,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Save', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================
  // Report Dialog
  // ============================================

  void _showReportDialog(BuildContext context, FoodLog meal) {
    if (apiClient == null) return;
    showFoodReportDialog(
      context,
      apiClient: apiClient!,
      foodName: meal.foodItems.isNotEmpty ? meal.foodItems.first.name : 'Food',
      originalCalories: meal.totalCalories,
      originalProtein: meal.proteinG,
      originalCarbs: meal.carbsG,
      originalFat: meal.fatG,
      foodLogId: meal.id,
      dataSource: 'food_log',
    );
  }

  // ============================================
  // Micronutrients Section
  // ============================================

  Widget _buildMicronutrientsSection(FoodLog meal, Color textPrimary, Color textMuted, Color teal, Color cardBorder) {
    final nutrients = <MapEntry<String, String>>[];
    if (meal.sodiumMg != null) nutrients.add(MapEntry('Sodium', '${meal.sodiumMg!.round()}mg'));
    if (meal.sugarG != null) nutrients.add(MapEntry('Sugar', '${meal.sugarG!.toStringAsFixed(1)}g'));
    if (meal.saturatedFatG != null) nutrients.add(MapEntry('Sat. Fat', '${meal.saturatedFatG!.toStringAsFixed(1)}g'));
    if (meal.cholesterolMg != null) nutrients.add(MapEntry('Cholesterol', '${meal.cholesterolMg!.round()}mg'));
    if (meal.potassiumMg != null) nutrients.add(MapEntry('Potassium', '${meal.potassiumMg!.round()}mg'));
    if (meal.calciumMg != null) nutrients.add(MapEntry('Calcium', '${meal.calciumMg!.round()}mg'));
    if (meal.ironMg != null) nutrients.add(MapEntry('Iron', '${meal.ironMg!.toStringAsFixed(1)}mg'));
    if (meal.vitaminAUg != null) nutrients.add(MapEntry('Vitamin A', '${meal.vitaminAUg!.round()}\u00B5g'));
    if (meal.vitaminCMg != null) nutrients.add(MapEntry('Vitamin C', '${meal.vitaminCMg!.toStringAsFixed(1)}mg'));
    if (meal.vitaminDIu != null) nutrients.add(MapEntry('Vitamin D', '${meal.vitaminDIu!.round()}IU'));

    if (nutrients.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBorder.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science_outlined, size: 14, color: teal),
              const SizedBox(width: 6),
              Text('Micronutrients', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: nutrients.map((e) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${e.key}: ', style: TextStyle(fontSize: 11, color: textMuted)),
                Text(e.value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textPrimary)),
              ],
            )).toList(),
          ),
        ],
      ),
    );
  }

  // ============================================
  // Helpers
  // ============================================

  String _getMealEmoji(String mealType) {
    switch (mealType) {
      case 'breakfast': return '\u{1F373}';
      case 'lunch': return '\u{1F957}';
      case 'dinner': return '\u{1F37D}\u{FE0F}';
      case 'snack': return '\u{1F34E}';
      default: return '\u{1F374}';
    }
  }

  Color _scoreColor(int score) {
    if (score >= 7) return Colors.green;
    if (score >= 4) return Colors.orange;
    return AppColors.error;
  }

  String _scoreLabel(int score) {
    if (score >= 8) return 'Excellent';
    if (score >= 7) return 'Good';
    if (score >= 5) return 'Average';
    if (score >= 3) return 'Below average';
    return 'Poor';
  }

  Color _inflammationColor(int score) {
    if (score <= 3) return Colors.green;
    if (score <= 5) return Colors.teal;
    if (score <= 7) return Colors.orange;
    return Colors.red;
  }

  String _inflammationLabel(int score) {
    if (score <= 2) return 'Anti-inflammatory';
    if (score <= 4) return 'Mildly anti-inflammatory';
    if (score == 5) return 'Neutral';
    if (score <= 7) return 'Mildly inflammatory';
    if (score <= 9) return 'Inflammatory';
    return 'Highly inflammatory';
  }

  void _showInflammationInfo(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_fire_department, color: Colors.orange),
                const SizedBox(width: 8),
                Text('Inflammation Score', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black)),
              ],
            ),
            const SizedBox(height: 16),
            Text('Rates how inflammatory a food is based on processing level, fat profile, sugar content, fiber, and antioxidant properties.',
              style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87, height: 1.5)),
            const SizedBox(height: 16),
            _buildInfoRow('1-3', 'Anti-inflammatory', Colors.green),
            _buildInfoRow('4-5', 'Neutral', Colors.teal),
            _buildInfoRow('6-7', 'Mildly inflammatory', Colors.orange),
            _buildInfoRow('8-10', 'Inflammatory', Colors.red),
            const SizedBox(height: 16),
            Text('Lower is better for reducing body inflammation and gut health.',
              style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.black54, fontStyle: FontStyle.italic)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String range, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 40,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(range, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
              textAlign: TextAlign.center),
          ),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 14, color: color)),
        ],
      ),
    );
  }

  void _showUltraProcessedInfo(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red),
                const SizedBox(width: 8),
                Text('Ultra-Processed Foods', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black)),
              ],
            ),
            const SizedBox(height: 16),
            Text('Ultra-processed foods (NOVA Group 4) contain industrial additives like emulsifiers, hydrogenated oils, artificial sweeteners, and protein isolates — substances not found in home cooking.',
              style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87, height: 1.5)),
            const SizedBox(height: 12),
            Text('Research links regular consumption to increased inflammation, obesity, heart disease, and digestive issues.',
              style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87, height: 1.5)),
            const SizedBox(height: 12),
            Text('Examples: soft drinks, instant noodles, packaged snacks, chicken nuggets, most breakfast cereals.',
              style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.black54, fontStyle: FontStyle.italic)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ============================================
// Helper Widgets
// ============================================

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color textColor;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 14),
            Text(label, style: TextStyle(fontSize: 14, color: textColor)),
          ],
        ),
      ),
    );
  }
}

class _AdjustBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AdjustBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }
}

// Editable macro field used by both Adjust Portion sheets (per-item AND
// whole-meal parent). One TextField per macro (Cal / P / C / F), tinted with
// the macro color. `onChanged` fires once the user edits the field so the
// sheet knows to stop auto-overwriting it when the multiplier / weight /
// count changes.
class _MacroField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final Color color;
  final Color glassSurface;
  final VoidCallback onChanged;

  const _MacroField({
    required this.controller,
    required this.label,
    required this.color,
    required this.glassSurface,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8))),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            filled: true,
            fillColor: glassSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            isDense: true,
          ),
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }
}

class _MacroSummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _MacroSummaryItem({required this.label, required this.value, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: textMuted)),
      ],
    );
  }
}

/// Signature: (logId, updated food_items JSON, new meal totals, single audit row)
typedef _EditCommit = void Function(
  String logId,
  List<Map<String, dynamic>> updatedItems,
  int totalCalories,
  double totalProteinG,
  double totalCarbsG,
  double totalFatG,
  FoodItemEdit edit,
);

/// List of food items in the meal-detail sheet with inline tap-to-edit
/// kcal/P/C/F. Keeps a local copy of food items so edits show optimistically
/// without waiting for the parent `meals` provider to refresh.
class _EditableFoodItemsList extends StatefulWidget {
  final FoodLog meal;
  final Color textPrimary;
  final Color textMuted;
  final Color accent;
  final Color cardBorder;
  final _EditCommit onCommit;
  final void Function(String logId)? onDeleteMeal;
  /// Calls POST /nutrition/analyze-text and returns the raw JSON response.
  /// Used by swap/add to auto-fill macros via Gemini.
  final Future<Map<String, dynamic>> Function(String description)? onAnalyzeText;

  const _EditableFoodItemsList({
    required this.meal,
    required this.textPrimary,
    required this.textMuted,
    required this.accent,
    required this.cardBorder,
    required this.onCommit,
    this.onDeleteMeal,
    this.onAnalyzeText,
  });

  @override
  State<_EditableFoodItemsList> createState() => _EditableFoodItemsListState();
}

class _EditableFoodItemsListState extends State<_EditableFoodItemsList> {
  late List<Map<String, dynamic>> _items;
  /// Track indices with at least one edit — drives the "edited" badge.
  final Set<int> _editedIndices = {};

  @override
  void initState() {
    super.initState();
    // Deep-copy so we can mutate without touching the original FoodLog.
    _items = widget.meal.foodItems
        .map((f) => Map<String, dynamic>.from(f.toJson()))
        .toList();
  }

  void _onFieldSaved(int index, String field, num newValue) {
    if (index < 0 || index >= _items.length) return;
    final prev = ((_items[index][field] as num?) ?? 0);
    if (prev == newValue) return;

    setState(() {
      _items[index] = {..._items[index], field: newValue};
      _editedIndices.add(index);
    });

    // Recompute meal totals from the authoritative items list
    int totalCal = 0;
    double totalP = 0, totalC = 0, totalF = 0;
    for (final it in _items) {
      totalCal += ((it['calories'] as num?) ?? 0).round();
      totalP += ((it['protein_g'] as num?) ?? 0).toDouble();
      totalC += ((it['carbs_g'] as num?) ?? 0).toDouble();
      totalF += ((it['fat_g'] as num?) ?? 0).toDouble();
    }

    final edit = FoodItemEdit(
      foodItemIndex: index,
      foodItemName: (_items[index]['name'] as String?) ?? 'item',
      editedField: field,
      previousValue: prev,
      updatedValue: newValue,
    );

    widget.onCommit(widget.meal.id, _items, totalCal, totalP, totalC, totalF, edit);
  }

  /// Recompute totals and commit with a synthetic edit entry.
  void _commitFullUpdate({String editField = 'calories', int editIndex = 0, num prevValue = 0, num newValue = 0}) {
    int totalCal = 0;
    double totalP = 0, totalC = 0, totalF = 0;
    for (final it in _items) {
      totalCal += ((it['calories'] as num?) ?? 0).round();
      totalP += ((it['protein_g'] as num?) ?? 0).toDouble();
      totalC += ((it['carbs_g'] as num?) ?? 0).toDouble();
      totalF += ((it['fat_g'] as num?) ?? 0).toDouble();
    }
    final edit = FoodItemEdit(
      foodItemIndex: editIndex,
      foodItemName: editIndex < _items.length
          ? ((_items[editIndex]['name'] as String?) ?? 'item') : 'item',
      editedField: editField,
      previousValue: prevValue,
      updatedValue: newValue,
    );
    widget.onCommit(widget.meal.id, _items, totalCal, totalP, totalC, totalF, edit);
  }

  void _removeItem(int index) {
    if (index < 0 || index >= _items.length) return;
    final removed = _items[index];
    final removedName = (removed['name'] as String?) ?? 'item';
    final removedCal = ((removed['calories'] as num?) ?? 0).round();

    if (_items.length <= 1) {
      // Last item — delete the whole log
      widget.onDeleteMeal?.call(widget.meal.id);
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _items.removeAt(index);
      _editedIndices.clear();
    });
    _commitFullUpdate(editField: 'removed_item', editIndex: 0, prevValue: removedCal, newValue: 0);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed $removedName'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSwapOrAddDialog({int? replaceIndex}) {
    final isSwap = replaceIndex != null;
    final existing = isSwap ? _items[replaceIndex] : null;
    final existingName = isSwap ? ((existing!['name'] as String?) ?? 'item') : null;

    final nameCtrl = TextEditingController();
    final calCtrl = TextEditingController();
    final proteinCtrl = TextEditingController();
    final carbsCtrl = TextEditingController();
    final fatCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetTextPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final sheetTextMuted = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final bg = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          bool isAnalyzing = false;

          Future<void> analyzeFood() async {
            final desc = nameCtrl.text.trim();
            if (desc.isEmpty || widget.onAnalyzeText == null) return;

            setSheetState(() { isAnalyzing = true; });
            try {
              final result = await widget.onAnalyzeText!(desc);
              // Extract the first food item from the analysis
              final items = result['food_items'] as List<dynamic>?;
              if (items != null && items.isNotEmpty) {
                final item = items[0] as Map<String, dynamic>;
                calCtrl.text = '${((item['calories'] as num?) ?? 0).round()}';
                proteinCtrl.text = '${((item['protein_g'] as num?) ?? 0).toDouble()}';
                carbsCtrl.text = '${((item['carbs_g'] as num?) ?? 0).toDouble()}';
                fatCtrl.text = '${((item['fat_g'] as num?) ?? 0).toDouble()}';
                if (amountCtrl.text.isEmpty) {
                  amountCtrl.text = (item['amount'] as String?) ?? '';
                }
                // Use the AI's name if more specific
                final aiName = item['name'] as String?;
                if (aiName != null && aiName.isNotEmpty) {
                  nameCtrl.text = aiName;
                }
                setSheetState(() {});
              }
            } catch (e) {
              debugPrint('Analyze error: $e');
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text('Analysis failed: ${e.toString().length > 60 ? '${e.toString().substring(0, 60)}...' : e}'),
                      behavior: SnackBarBehavior.floating),
                );
              }
            } finally {
              if (ctx.mounted) setSheetState(() { isAnalyzing = false; });
            }
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isSwap ? 'Swap $existingName' : 'Add Item',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: sheetTextPrimary),
                ),
                const SizedBox(height: 16),
                // Food name + Analyze button
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: nameCtrl,
                        autofocus: true,
                        style: TextStyle(color: sheetTextPrimary),
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => analyzeFood(),
                        decoration: InputDecoration(
                          labelText: 'Food name',
                          hintText: isSwap ? 'e.g., Sweet Tea' : 'e.g., Side Salad',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    if (widget.onAnalyzeText != null) ...[
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: isAnalyzing ? null : analyzeFood,
                          icon: isAnalyzing
                              ? SizedBox(width: 16, height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: widget.accent))
                              : Icon(Icons.auto_awesome_rounded, size: 18),
                          label: Text(isAnalyzing ? '' : 'AI', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.accent.withValues(alpha: 0.15),
                            foregroundColor: widget.accent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (widget.onAnalyzeText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Type a food and tap AI to auto-fill macros',
                        style: TextStyle(fontSize: 11, color: sheetTextMuted)),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  style: TextStyle(color: sheetTextPrimary),
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    hintText: 'e.g., medium, 1 cup, 350ml',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(
                      controller: calCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: sheetTextPrimary),
                      decoration: InputDecoration(
                        labelText: 'Cal',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(
                      controller: proteinCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: sheetTextPrimary),
                      decoration: InputDecoration(
                        labelText: 'Protein',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(
                      controller: carbsCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: sheetTextPrimary),
                      decoration: InputDecoration(
                        labelText: 'Carbs',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(
                      controller: fatCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: sheetTextPrimary),
                      decoration: InputDecoration(
                        labelText: 'Fat',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    )),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) return;

                      final newItem = <String, dynamic>{
                        'name': name,
                        'amount': amountCtrl.text.trim().isNotEmpty ? amountCtrl.text.trim() : null,
                        'calories': int.tryParse(calCtrl.text) ?? 0,
                        'protein_g': double.tryParse(proteinCtrl.text) ?? 0,
                        'carbs_g': double.tryParse(carbsCtrl.text) ?? 0,
                        'fat_g': double.tryParse(fatCtrl.text) ?? 0,
                      };

                      Navigator.of(ctx).pop();

                      setState(() {
                        if (isSwap) {
                          final prevCal = ((_items[replaceIndex]['calories'] as num?) ?? 0).round();
                          _items[replaceIndex] = newItem;
                          _editedIndices.add(replaceIndex);
                          _commitFullUpdate(editField: 'swapped_item', editIndex: replaceIndex,
                              prevValue: prevCal, newValue: newItem['calories'] as int);
                        } else {
                          _items.add(newItem);
                          _editedIndices.add(_items.length - 1);
                          _commitFullUpdate(editField: 'added_item', editIndex: _items.length - 1,
                              prevValue: 0, newValue: newItem['calories'] as int);
                        }
                      });
                    },
                    child: Text(isSwap ? 'Swap Item' : 'Add Item',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final proteinCol = Theme.of(context).brightness == Brightness.dark
        ? AppColors.macroProtein
        : AppColorsLight.macroProtein;
    final carbsCol = Theme.of(context).brightness == Brightness.dark
        ? AppColors.macroCarbs
        : AppColorsLight.macroCarbs;
    final fatCol = Theme.of(context).brightness == Brightness.dark
        ? AppColors.macroFat
        : AppColorsLight.macroFat;

    return Column(
      children: [
        ..._items.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          final edited = _editedIndices.contains(idx);
          final name = (item['name'] as String?) ?? 'item';
          final amount = item['amount'] as String?;
          final calories = ((item['calories'] as num?) ?? 0).round();
          final protein = ((item['protein_g'] as num?) ?? 0).toDouble();
          final carbs = ((item['carbs_g'] as num?) ?? 0).toDouble();
          final fat = ((item['fat_g'] as num?) ?? 0).toDouble();

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.cardBorder.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: edited
                  ? Border.all(color: widget.accent.withValues(alpha: 0.45), width: 1)
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600, color: widget.textPrimary,
                              ),
                              maxLines: 2,
                              softWrap: true,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (edited) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: widget.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.edit_rounded, size: 9, color: widget.accent),
                                  const SizedBox(width: 3),
                                  Text('edited',
                                      style: TextStyle(
                                          fontSize: 9, color: widget.accent, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Per-item action buttons: swap and remove
                    InkWell(
                      onTap: () => _showSwapOrAddDialog(replaceIndex: idx),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(Icons.swap_horiz_rounded, size: 18, color: widget.accent),
                      ),
                    ),
                    const SizedBox(width: 2),
                    InkWell(
                      onTap: () => _removeItem(idx),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(Icons.close_rounded, size: 18, color: Colors.red.shade400),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _InlineEditableChip(
                      label: 'Cal',
                      value: calories.toDouble(),
                      isInt: true,
                      suffix: '',
                      color: widget.accent,
                      onSaved: (v) => _onFieldSaved(idx, 'calories', v.round()),
                    ),
                    _InlineEditableChip(
                      label: 'P',
                      value: protein,
                      isInt: false,
                      suffix: 'g',
                      color: proteinCol,
                      onSaved: (v) => _onFieldSaved(idx, 'protein_g', double.parse(v.toStringAsFixed(1))),
                    ),
                    _InlineEditableChip(
                      label: 'C',
                      value: carbs,
                      isInt: false,
                      suffix: 'g',
                      color: carbsCol,
                      onSaved: (v) => _onFieldSaved(idx, 'carbs_g', double.parse(v.toStringAsFixed(1))),
                    ),
                    _InlineEditableChip(
                      label: 'F',
                      value: fat,
                      isInt: false,
                      suffix: 'g',
                      color: fatCol,
                      onSaved: (v) => _onFieldSaved(idx, 'fat_g', double.parse(v.toStringAsFixed(1))),
                    ),
                  ],
                ),
                if (amount != null) ...[
                  const SizedBox(height: 4),
                  Text('Amount: $amount',
                      style: TextStyle(fontSize: 11, color: widget.textMuted)),
                ],
              ],
            ),
          );
        }),
        // Add Item button
        const SizedBox(height: 4),
        InkWell(
          onTap: () => _showSwapOrAddDialog(),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: widget.accent.withValues(alpha: 0.4), width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, size: 18, color: widget.accent),
                const SizedBox(width: 6),
                Text('Add Item', style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: widget.accent,
                )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Compact tap-to-edit pill for Cal / P / C / F chips on the nutrition
/// meal-details sheet. Separate from the ranking-card variant so neither
/// widget has to expose internal state to the other.
class _InlineEditableChip extends StatefulWidget {
  final String label;
  final double value;
  final bool isInt;
  final String suffix;
  final Color color;
  final void Function(num) onSaved;

  const _InlineEditableChip({
    required this.label,
    required this.value,
    required this.isInt,
    required this.suffix,
    required this.color,
    required this.onSaved,
  });

  @override
  State<_InlineEditableChip> createState() => _InlineEditableChipState();
}

class _InlineEditableChipState extends State<_InlineEditableChip> {
  bool _editing = false;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _fmt(widget.value));
  }

  @override
  void didUpdateWidget(covariant _InlineEditableChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing && oldWidget.value != widget.value) {
      _controller.text = _fmt(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _fmt(double v) {
    if (widget.isInt) return v.round().toString();
    final s = v.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  void _commit() {
    final parsed = double.tryParse(_controller.text.trim());
    if (parsed == null || parsed < 0 || parsed > 100000) {
      _controller.text = _fmt(widget.value);
      setState(() => _editing = false);
      return;
    }
    setState(() => _editing = false);
    if (parsed != widget.value) widget.onSaved(widget.isInt ? parsed.round() : parsed);
  }

  void _cancel() {
    _controller.text = _fmt(widget.value);
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.color.withValues(alpha: 0.15);
    if (_editing) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: widget.color, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${widget.label}:',
                style: TextStyle(fontSize: 10, color: widget.color, fontWeight: FontWeight.w700)),
            const SizedBox(width: 3),
            SizedBox(
              width: 40,
              child: TextField(
                controller: _controller,
                autofocus: true,
                keyboardType: TextInputType.numberWithOptions(decimal: !widget.isInt),
                style: TextStyle(
                    fontSize: 10, color: widget.color, fontWeight: FontWeight.w600),
                decoration: const InputDecoration(
                  isDense: true, contentPadding: EdgeInsets.zero, border: InputBorder.none,
                ),
                onSubmitted: (_) => _commit(),
              ),
            ),
            if (widget.suffix.isNotEmpty)
              Text(widget.suffix,
                  style: TextStyle(
                      fontSize: 10, color: widget.color, fontWeight: FontWeight.w600)),
            const SizedBox(width: 3),
            GestureDetector(
              onTap: _commit,
              behavior: HitTestBehavior.opaque,
              child: Icon(Icons.check_rounded, size: 13, color: widget.color),
            ),
            GestureDetector(
              onTap: _cancel,
              behavior: HitTestBehavior.opaque,
              child: Icon(Icons.close_rounded, size: 11, color: widget.color.withValues(alpha: 0.6)),
            ),
          ],
        ),
      );
    }
    return GestureDetector(
      onTap: () => setState(() => _editing = true),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: widget.color.withValues(alpha: 0.25), width: 0.5),
        ),
        child: Text(
          '${widget.label}: ${_fmt(widget.value)}${widget.suffix}',
          style: TextStyle(fontSize: 10, color: widget.color, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// Collapsible "Edit history" link — fetches edits lazily on tap.
class _EditHistoryLink extends StatefulWidget {
  final String logId;
  final Color accent;
  final Color textMuted;
  final Future<List<FoodLogEditRecord>> Function(String logId) fetchEdits;

  const _EditHistoryLink({
    required this.logId,
    required this.accent,
    required this.textMuted,
    required this.fetchEdits,
  });

  @override
  State<_EditHistoryLink> createState() => _EditHistoryLinkState();
}

class _EditHistoryLinkState extends State<_EditHistoryLink> {
  bool _expanded = false;
  bool _loading = false;
  String? _error;
  List<FoodLogEditRecord> _edits = const [];

  Future<void> _toggle() async {
    if (_expanded) {
      setState(() => _expanded = false);
      return;
    }
    setState(() {
      _expanded = true;
      _loading = true;
      _error = null;
    });
    try {
      final rows = await widget.fetchEdits(widget.logId);
      if (!mounted) return;
      setState(() {
        _edits = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load history';
        _loading = false;
      });
    }
  }

  String _fieldLabel(String f) {
    switch (f) {
      case 'calories':
        return 'Calories';
      case 'protein_g':
        return 'Protein';
      case 'carbs_g':
        return 'Carbs';
      case 'fat_g':
        return 'Fat';
    }
    return f;
  }

  String _fmt(num v, String field) {
    if (field == 'calories') return v.round().toString();
    final s = v.toDouble().toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: _toggle,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history, size: 14, color: widget.accent),
                const SizedBox(width: 6),
                Text(
                  _expanded ? 'Hide edit history' : 'View edit history',
                  style: TextStyle(
                    fontSize: 12, color: widget.accent, fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.expand_more, size: 16, color: widget.accent),
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
            child: _loading
                ? Padding(
                    padding: const EdgeInsets.all(8),
                    child: SizedBox(
                      height: 16,
                      child: LinearProgressIndicator(
                        backgroundColor: widget.accent.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation(widget.accent),
                      ),
                    ),
                  )
                : _error != null
                    ? Text(_error!, style: TextStyle(fontSize: 12, color: widget.textMuted))
                    : _edits.isEmpty
                        ? Text('No edits yet',
                            style: TextStyle(fontSize: 12, color: widget.textMuted))
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _edits.map((e) {
                              final when = e.editedAt.toLocal();
                              final dateStr =
                                  '${when.month}/${when.day} ${when.hour.toString().padLeft(2, '0')}:${when.minute.toString().padLeft(2, '0')}';
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 3),
                                child: Text(
                                  '• ${e.foodItemName} · ${_fieldLabel(e.editedField)}: '
                                  '${_fmt(e.previousValue, e.editedField)} → '
                                  '${_fmt(e.updatedValue, e.editedField)}  '
                                  '($dateStr)',
                                  style: TextStyle(fontSize: 11, color: widget.textMuted, height: 1.3),
                                ),
                              );
                            }).toList(),
                          ),
          ),
      ],
    );
  }
}

// ============================================
// _MealSection — per-meal collapsible section.
// Manages its own expand/collapse state so the parent
// LoggedMealsSection can stay StatelessWidget.
// ============================================

class _MealSection extends StatefulWidget {
  final String mealId;
  final String label;
  final List<FoodLog> typeMeals;
  final LoggedMealsSection owner;

  const _MealSection({
    required this.mealId,
    required this.label,
    required this.typeMeals,
    required this.owner,
  });

  @override
  State<_MealSection> createState() => _MealSectionState();
}

class _MealSectionState extends State<_MealSection> {
  bool? _userExpanded; // null = use smart default from typeMeals

  bool get _isExpanded => _userExpanded ?? widget.typeMeals.isNotEmpty;

  void _toggle() {
    HapticFeedback.selectionClick();
    setState(() => _userExpanded = !_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final owner = widget.owner;
    final isDark = owner.isDark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accent = AccentColorScope.of(context).getColor(isDark);
    // Macro colors match the daily summary bar (🔥 cal · C cyan · P purple · F orange).
    final macroC = isDark ? AppColors.macroCarbs : AppColorsLight.macroCarbs;
    final macroP = isDark ? AppColors.macroProtein : AppColorsLight.macroProtein;
    final macroF = isDark ? AppColors.macroFat : AppColorsLight.macroFat;

    final totalCal = widget.typeMeals.fold<int>(0, (s, m) => s + m.totalCalories);
    final totalProtein = widget.typeMeals.fold<double>(0, (s, m) => s + m.proteinG);
    final totalCarbs = widget.typeMeals.fold<double>(0, (s, m) => s + m.carbsG);
    final totalFat = widget.typeMeals.fold<double>(0, (s, m) => s + m.fatG);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row — tap toggles; + button adds; pills show totals
        InkWell(
          onTap: _toggle,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
            child: Row(
              children: [
                AnimatedRotation(
                  duration: const Duration(milliseconds: 180),
                  turns: _isExpanded ? 0.25 : 0,
                  child: Icon(Icons.chevron_right, size: 20, color: textMuted),
                ),
                const SizedBox(width: 4),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                // 4 macro pills in daily-summary-bar order (cal · C · P · F).
                // Horizontal scroll prevents clipping on narrow devices when
                // all four are present alongside the "+" button.
                Flexible(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (totalCal > 0) _StatPill(label: '$totalCal cal', color: accent),
                        if (totalCarbs > 0) ...[
                          const SizedBox(width: 6),
                          _StatPill(label: '${totalCarbs.round()}g C', color: macroC),
                        ],
                        if (totalProtein > 0) ...[
                          const SizedBox(width: 6),
                          _StatPill(label: '${totalProtein.round()}g P', color: macroP),
                        ],
                        if (totalFat > 0) ...[
                          const SizedBox(width: 6),
                          _StatPill(label: '${totalFat.round()}g F', color: macroF),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () => owner.onLogMeal(widget.mealId),
                  icon: Icon(Icons.add_rounded, size: 20, color: accent),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  tooltip: 'Log ${widget.label}',
                ),
              ],
            ),
          ),
        ),
        // Items or empty state
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 180),
          crossFadeState: _isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox(width: double.infinity, height: 0),
          secondChild: widget.typeMeals.isEmpty
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                  child: Row(
                    children: [
                      Text(
                        'No foods logged',
                        style: TextStyle(fontSize: 12, color: textMuted),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => owner.onLogMeal(widget.mealId),
                        icon: Icon(Icons.add_rounded, size: 16, color: accent),
                        label: Text(
                          'Log food',
                          style: TextStyle(
                            fontSize: 12,
                            color: accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...widget.typeMeals.map((meal) {
                      if (meal.foodItems.length <= 1) {
                        // Single-item log → flat row
                        final food = meal.foodItems.isEmpty
                            ? null
                            : meal.foodItems.first;
                        return owner._buildFoodItemRow(
                          context: context,
                          meal: meal,
                          foodName: food?.name ?? (meal.userQuery ?? 'Food'),
                          calories: food?.calories ?? meal.totalCalories,
                          amount: food?.amount,
                          proteinG: food?.proteinG ?? meal.proteinG,
                          time: meal.loggedAt,
                          textPrimary: textPrimary,
                          textMuted: textMuted,
                          accent: accent,
                        );
                      }
                      // Multi-item log → group parent + indented children
                      return _FoodGroup(
                        meal: meal,
                        owner: owner,
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                        accent: accent,
                        cardBorder: cardBorder,
                      );
                    }),
                    const SizedBox(height: 4),
                  ],
                ),
        ),
      ],
    );
  }
}

// ============================================
// _StatPill — compact accent/macro-tinted pill for meal header totals.
// ============================================

class _StatPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ============================================
// _MacroMiniBar — hero-row macro progress (P/C/F).
// ============================================

class _MacroMiniBar extends StatelessWidget {
  final String label;
  final double consumed;
  final int target;
  final Color color;
  final bool isDark;

  const _MacroMiniBar({
    required this.label,
    required this.consumed,
    required this.target,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final progress = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;
    final showTarget = target > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: textMuted, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            Text(
              showTarget
                  ? '${consumed.round()}/${target}g'
                  : '${consumed.round()}g',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 3,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

// ============================================
// _FoodGroup — parent row with thumbnail + user-query title + summary;
// indented child rows with a subtle 1dp connector line on the left.
// Rendered when a single FoodLog contains ≥2 food items (photo with
// multiple foods, chat "log my breakfast: oatmeal banana coffee", etc.).
// ============================================

class _FoodGroup extends StatelessWidget {
  final FoodLog meal;
  final LoggedMealsSection owner;
  final Color textPrimary;
  final Color textMuted;
  final Color accent;
  final Color cardBorder;

  const _FoodGroup({
    required this.meal,
    required this.owner,
    required this.textPrimary,
    required this.textMuted,
    required this.accent,
    required this.cardBorder,
  });

  /// Title priority:
  ///   1. `userQuery` — the user's originating input (caption, dish name).
  ///   2. For image-logged meals: join the top 2 detected food names
  ///      ("Masala Dosa, Coconut Chutney + 1 more" for 3+). Answers
  ///      "what did the AI see" directly, using the list it extracted.
  ///   3. `aiFeedback` first sentence — non-image fallback.
  ///   4. Item count — last-ditch fallback.
  /// Deliberately never produces the generic "Logged via image" string —
  /// the backend no longer clobbers aiFeedback with that placeholder, but
  /// old rows predating the fix would still contain it, so we defensively
  /// prefer the food-names join on image sources.
  String _groupTitle() {
    String truncate(String s) => s.length <= 40 ? s : '${s.substring(0, 40)}…';

    final q = meal.userQuery?.trim();
    if (q != null && q.isNotEmpty) return truncate(q);

    if (meal.sourceType == 'image' && meal.foodItems.isNotEmpty) {
      final names = meal.foodItems
          .map((f) => f.name.trim())
          .where((n) => n.isNotEmpty)
          .toList();
      if (names.isNotEmpty) {
        final head = names.take(2).join(', ');
        final extra = names.length - 2;
        return truncate(extra > 0 ? '$head + $extra more' : head);
      }
    }

    final fb = meal.aiFeedback?.trim();
    if (fb != null && fb.isNotEmpty) {
      final firstSentenceEnd = fb.indexOf(RegExp(r'[.!?]'));
      final first = firstSentenceEnd > 0 ? fb.substring(0, firstSentenceEnd) : fb;
      return truncate(first);
    }
    return '${meal.foodItems.length} items';
  }

  @override
  Widget build(BuildContext context) {
    final title = _groupTitle();
    final summary = '${meal.foodItems.length} items · ${meal.totalCalories} cal · ${meal.proteinG.round()}g protein';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Parent row
        Dismissible(
          key: ValueKey('group_${meal.id}'),
          direction: DismissDirection.horizontal,
          background: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 16),
            color: accent.withValues(alpha: 0.9),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit, color: Colors.white, size: 18),
                SizedBox(width: 4),
                Text('Edit', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          secondaryBackground: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            color: AppColors.error.withValues(alpha: 0.9),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Delete', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                SizedBox(width: 4),
                Icon(Icons.delete_outline, color: Colors.white, size: 18),
              ],
            ),
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              owner._showEditPortionSheet(context, meal);
              return false;
            }
            // Whole-group delete with undo
            final messenger = ScaffoldMessenger.of(context);
            bool undone = false;
            messenger.clearSnackBars();
            messenger.showSnackBar(
              SnackBar(
                content: const Text('Meal deleted'),
                action: SnackBarAction(label: 'Undo', onPressed: () { undone = true; }),
                duration: const Duration(seconds: 4),
              ),
            );
            await Future.delayed(const Duration(seconds: 4));
            if (!undone) owner.onDeleteMeal(meal.id);
            // Always return false so the Dismissible resets; the async state
            // mutation in onDeleteMeal triggers a rebuild that removes the
            // whole group (parent row + all child rows) in one pass.
            return false;
          },
          child: InkWell(
            onTap: () => owner._showMealDetails(context, meal),
            onLongPress: () {
              HapticFeedback.mediumImpact();
              owner._showQuickActionsMenu(context, meal);
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  owner._buildSourceIndicator(
                    context: context,
                    meal: meal,
                    textMuted: textMuted,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          summary,
                          style: TextStyle(fontSize: 11, color: textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Source badge so users see at a glance that a meal
                        // came from AI Chat / Barcode / Nutrition Label /
                        // App Screenshot / Restaurant. Image logs keep the
                        // thumbnail in the leading slot; manual text entries
                        // (default) intentionally render nothing here.
                        owner._buildSourceBadge(meal, textMuted) ?? const SizedBox.shrink(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatTime(meal.loggedAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: textMuted.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // ── Children with subtle connector line on the left
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Connector: 28dp left + 14dp left edge = line at ~28dp offset
              Container(
                width: 28 + 14, // align under thumbnail center (14 padding + 14 half-thumbnail)
                alignment: Alignment.center,
                child: Container(
                  width: 1,
                  color: textMuted.withValues(alpha: 0.22),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < meal.foodItems.length; i++)
                      _buildChildRow(context, meal, i),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChildRow(BuildContext context, FoodLog parent, int idx) {
    final food = parent.foodItems[idx];
    return Dismissible(
      key: ValueKey('child_${parent.id}_$idx'),
      direction: DismissDirection.horizontal,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16),
        color: accent.withValues(alpha: 0.9),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit, color: Colors.white, size: 18),
            SizedBox(width: 4),
            Text('Edit', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: AppColors.error.withValues(alpha: 0.9),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Remove', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            SizedBox(width: 4),
            Icon(Icons.delete_outline, color: Colors.white, size: 18),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe-right on a child row opens the per-ITEM portion editor
          // (previously opened the whole-meal editor, which was wrong —
          // the user was clearly targeting one food).
          owner._showEditItemPortionSheet(context, parent, idx);
          return false;
        }
        // Remove just this item from parent.foodItems[] and recompute totals.
        await _removeChildItem(context, parent, idx);
        // Always return false: _removeChildItem triggers the async state
        // update (either onUpdateMeal for partial remove or onDeleteMeal when
        // it was the last item); the rebuild removes this child row. Returning
        // true would leave a dismissed Dismissible in the tree before the
        // async update finishes, which throws the "still part of tree" error.
        return false;
      },
      child: InkWell(
        onTap: () => owner._showMealDetails(context, parent),
        onLongPress: () {
          HapticFeedback.mediumImpact();
          // Per-item menu (Adjust portion, Copy/Move to other meal, Remove)
          // instead of the whole-meal menu — fixes the user's report that
          // long-pressing any child always hit the parent.
          owner._showItemQuickActionsMenu(context, parent, idx);
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (food.amount != null && food.amount!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          food.amount!,
                          style: TextStyle(fontSize: 11, color: textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${food.calories ?? 0} cal',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  if (food.proteinG != null && food.proteinG! > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '${food.proteinG!.round()}g protein',
                        style: TextStyle(fontSize: 11, color: textMuted),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Remove a single food item from a multi-item log, recompute totals,
  /// and persist via `owner.onUpdateMeal`. If this was the last remaining
  /// item, delete the whole log instead.
  Future<bool> _removeChildItem(BuildContext context, FoodLog parent, int idx) async {
    final messenger = ScaffoldMessenger.of(context);
    bool undone = false;
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Removed ${parent.foodItems[idx].name}'),
        action: SnackBarAction(label: 'Undo', onPressed: () { undone = true; }),
        duration: const Duration(seconds: 4),
      ),
    );
    await Future.delayed(const Duration(seconds: 4));
    if (undone) return false;

    if (parent.foodItems.length <= 1) {
      // Last item → delete whole log
      owner.onDeleteMeal(parent.id);
      return true;
    }

    final remaining = [
      for (int i = 0; i < parent.foodItems.length; i++)
        if (i != idx) parent.foodItems[i],
    ];
    final newCal = remaining.fold<int>(0, (s, f) => s + (f.calories ?? 0));
    final newProtein = remaining.fold<double>(0, (s, f) => s + (f.proteinG ?? 0));
    final newCarbs = remaining.fold<double>(0, (s, f) => s + (f.carbsG ?? 0));
    final newFat = remaining.fold<double>(0, (s, f) => s + (f.fatG ?? 0));

    owner.onUpdateMeal(
      parent.id,
      newCal,
      newProtein,
      newCarbs,
      newFat,
      foodItems: remaining.map((f) => f.toJson()).toList(),
    );
    return true;
  }

  String _formatTime(DateTime t) => TimeFormatters.logTime(t);
}
