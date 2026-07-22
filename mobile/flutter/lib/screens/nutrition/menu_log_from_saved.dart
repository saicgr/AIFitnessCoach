/// Logging dishes off a SAVED menu (History screen / Saved hub).
///
/// The fresh-scan path lives in `log_meal_sheet_ui_1.dart`
/// (`_logMenuSelectedItems`), which can rely on the Log Meal sheet's own
/// meal-type selector and target date. A menu REOPENED from history has
/// neither, so this file is the single place that fills those two gaps and
/// persists the selection.
///
/// Why it exists: both reopen call sites used to pass an empty `onLogItems`
/// closure — `menu_analysis_history_screen.dart` and `saved_hub_screen.dart`
/// each had a stub whose comment claimed the sheet handled logging. It did
/// not. `MenuAnalysisSheet` flipped its button to "Logged" and nothing was
/// ever written, on every saved menu, for every user.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/nutrition_repository.dart'
    show
        nutritionRepositoryProvider,
        dailyNutritionProvider,
        todayNutritionKey;
import '../../l10n/generated/app_localizations.dart';

/// Infer a meal type from the current hour.
///
/// Mirrors `_inferMealType` in `recipes/fridge_recipe_detail_sheet.dart` so a
/// dish lands in the same bucket no matter which surface logged it. A saved
/// menu is reopened to log what you're eating NOW, so "now" is the right basis.
String inferMealTypeForNow([DateTime? now]) {
  final h = (now ?? DateTime.now()).hour;
  if (h < 11) return 'breakfast';
  if (h < 16) return 'lunch';
  if (h < 21) return 'dinner';
  return 'snack';
}

/// Persist the dishes ticked off a saved menu.
///
/// Returns true only when the server confirmed the write — `MenuAnalysisSheet`
/// uses that to decide whether its button may show "Logged", so a failure can
/// never be reported as success.
Future<bool> logItemsFromSavedMenu({
  required WidgetRef ref,
  required BuildContext context,
  required String userId,
  required List<Map<String, dynamic>> items,
  required String analysisType,
  String? imageUrl,
}) async {
  if (items.isEmpty) return false;

  final l10n = AppLocalizations.of(context);
  // Capture before the await — the sheet may be popped by the time we return.
  final messenger = ScaffoldMessenger.maybeOf(
    Navigator.of(context, rootNavigator: true).overlay?.context ?? context,
  );
  final mealType = inferMealTypeForNow();

  try {
    await ref.read(nutritionRepositoryProvider).logSelectedMealItems(
          userId: userId,
          mealType: mealType,
          analysisType: analysisType,
          items: items,
          inputType: analysisType == 'buffet' ? 'buffet_scan' : 'menu_scan',
          imageUrl: imageUrl,
        );

    // The server now holds the authoritative rows — pull them into today's
    // view so the meal list and rings reflect the log without a manual refresh.
    final notifier =
        ref.read(dailyNutritionProvider(todayNutritionKey()).notifier);
    notifier.load(userId, forceRefresh: true);
    notifier.refreshTimeline();

    messenger?.showSnackBar(
      SnackBar(
        content: Text(l10n.logMealSheetLoggedItems(items.length)),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return true;
  } catch (e) {
    debugPrint('❌ [SavedMenu] log-selected-items failed: $e');
    messenger?.showSnackBar(
      SnackBar(
        content: Text(l10n.logMealSheetCouldnTLogThose),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return false;
  }
}
