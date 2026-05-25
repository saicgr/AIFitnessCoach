import 'package:flutter/widgets.dart';
import '../../l10n/generated/app_localizations.dart';

/// Converts a backend [actionData] map into a localized summary string.
///
/// Called by the chat bubble before falling back to the server-supplied
/// English `summary_text`. Returns `null` for unknown actions so the
/// caller can continue using the backend string unmodified.
///
/// Usage:
/// ```dart
/// final localized = ChatActionSummaryBuilder.build(context, message.actionData);
/// final display = localized ?? (message.actionData?['summary_text'] as String?);
/// ```
class ChatActionSummaryBuilder {
  ChatActionSummaryBuilder._();

  /// Returns a localized summary for a known action, or `null` for unknown
  /// actions (caller should fall back to backend's English `summary_text`).
  static String? build(
    BuildContext context,
    Map<String, dynamic>? actionData,
  ) {
    if (actionData == null) return null;
    final l10n = AppLocalizations.of(context);
    final action = actionData['action'] as String?;

    switch (action) {
      case 'equipment_calibrated':
        return l10n.actionEquipmentCalibratedSummary;

      case 'regenerate_workout_requested':
        return l10n.actionRegenerateRequestedSummary;

      case 'deload_started':
        final reason = (actionData['reason'] as String?) ?? '';
        return l10n.actionDeloadStartedSummary(reason);

      case 'workout_added':
        return l10n.actionWorkoutAddedSummary;

      case 'workout_removed':
        return l10n.actionWorkoutRemovedSummary;

      case 'exercise_swapped':
        final oldEx = (actionData['old_exercise'] as String?) ?? '';
        final newEx = (actionData['new_exercise'] as String?) ?? '';
        return l10n.actionExerciseSwappedSummary(oldEx, newEx);

      case 'food_logged':
        return l10n.actionFoodLoggedSummary;

      case 'meal_scanned':
        final count = (actionData['item_count'] as num?)?.toInt() ?? 0;
        return l10n.actionMealScannedSummary(count);

      case 'menu_scanned':
        final count = (actionData['item_count'] as num?)?.toInt() ?? 0;
        return l10n.actionMenuScannedSummary(count);

      case 'settings_changed':
        final name = (actionData['setting_name'] as String?) ?? '';
        return l10n.actionSettingsChangedSummary(name);

      case 'dark_mode_toggled':
        return l10n.actionDarkModeToggledSummary;

      case 'calibration_saved':
        return l10n.actionCalibrationSavedSummary;

      case 'hydration_logged':
        final amount = (actionData['amount'] as String?) ?? '';
        return l10n.actionHydrationLoggedSummary(amount);

      default:
        // Unknown action — let caller fall back to backend's English summary_text.
        return null;
    }
  }
}
