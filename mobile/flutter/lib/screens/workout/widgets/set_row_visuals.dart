import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/copy/training_explainers.dart';
import '../../../core/theme/accent_color_provider.dart';

/// Shared visual helpers for the active-workout set rows.
///
/// Both [SetRow] (the legacy/single-set renderer in `set_row.dart`) and
/// [SetTrackingTable] (the canonical tabular renderer in
/// `set_tracking_table.dart`) reach into these helpers so the two surfaces
/// stay visually identical:
///   • Trend pill (↑/↓/· vs prior set's target)
///   • "Edited" chip when the user manually overrode the target
///   • Outline target-RIR pill + filled logged-RIR pill
///
/// Helpers are top-level functions that take primitives — they intentionally
/// know nothing about [ActiveSetData] / [SetRowData] so callers can wire them
/// in without forcing their data class to match.
class SetRowVisuals {
  SetRowVisuals._();

  /// Trend pill comparing this set's target against the prior set's target.
  ///
  /// Returns null when the pill should be suppressed entirely (PO disabled,
  /// no prior data and not first-ever, etc.). When [isFirstSetEver] is true,
  /// renders a muted "Starter weight" hint instead of a directional arrow.
  ///
  /// Display unit for weight delta is the unit the caller already shows in
  /// the TARGET cell — pass the converted display delta values for [targetWeightDisplay]
  /// and [previousSetTargetWeightDisplay], plus [unitLabel] ('lb' or 'kg').
  static Widget? buildTrendPill({
    required bool progressiveOverloadEnabled,
    required bool isFirstSetEver,
    required bool isDeload,
    required String metric, // 'weight' | 'reps' | 'time'
    required double targetWeightDisplay,
    required int targetReps,
    int? durationSeconds,
    double? previousSetTargetWeightDisplay,
    int? previousSetTargetReps,
    int? previousSetTargetSeconds,
    String unitLabel = 'lb',
  }) {
    if (!progressiveOverloadEnabled) return null;
    if (isFirstSetEver) {
      return const Text(
        'Starter weight',
        style: TextStyle(
          fontSize: 9,
          color: AppColors.textMuted,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    String? label;
    int direction = 0;
    switch (metric) {
      case 'reps':
        if (previousSetTargetReps == null) return null;
        final delta = targetReps - previousSetTargetReps;
        direction = delta.sign;
        label = delta == 0
            ? '· same'
            : '${delta > 0 ? '+' : '−'}${delta.abs()} rep${delta.abs() == 1 ? '' : 's'}';
        break;
      case 'time':
        if (previousSetTargetSeconds == null) return null;
        final cur = durationSeconds ?? previousSetTargetSeconds;
        final delta = cur - previousSetTargetSeconds;
        direction = delta.sign;
        label = delta == 0
            ? '· same'
            : '${delta > 0 ? '+' : '−'}${delta.abs()}s';
        break;
      case 'weight':
      default:
        final prev = previousSetTargetWeightDisplay;
        if (prev == null) {
          // No weight delta available. Try reps as a fallback for bodyweight
          // exercises that still have rep targets.
          if (previousSetTargetReps != null) {
            final delta = targetReps - previousSetTargetReps;
            direction = delta.sign;
            label = delta == 0
                ? '· same'
                : '${delta > 0 ? '+' : '−'}${delta.abs()} rep${delta.abs() == 1 ? '' : 's'}';
            break;
          }
          return null;
        }
        if (prev <= 0) return null;
        final delta = targetWeightDisplay - prev;
        if (delta.abs() < 0.05) {
          direction = 0;
          label = '· same';
        } else {
          direction = delta > 0 ? 1 : -1;
          final shown = delta.abs();
          label =
              '${delta > 0 ? '+' : '−'}${shown.toStringAsFixed(shown >= 10 ? 0 : 1)} $unitLabel';
        }
        break;
    }

    Color color;
    IconData? icon;
    if (isDeload && direction <= 0) {
      color = AppColors.purple;
      icon = Icons.bedtime_outlined;
    } else if (direction > 0) {
      color = AppColors.success;
      icon = Icons.arrow_upward;
    } else if (direction < 0) {
      color = AppColors.error;
      icon = Icons.arrow_downward;
    } else {
      color = AppColors.textMuted;
      icon = null;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, size: 9, color: color),
          if (icon != null) const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Small "Edited" chip rendered next to the trend pill when the user
  /// manually overrode the planned target. Returns null when not edited.
  static Widget? buildEditedChip({required bool isEdited}) {
    if (!isEdited) return null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.orange.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'Edited',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: AppColors.orange,
        ),
      ),
    );
  }

  /// Resolve the human-readable target-effort label for a set.
  ///
  /// Plain-English replacement for the old "Target RIR · AMRAP" jargon
  /// (Phase A.2). Label map:
  ///   • isAmrap OR set_type == 'failure' OR targetRir == 0 → "Push to failure"
  ///   • targetRir == 1                                     → "1 RIR (near max)"
  ///   • targetRir >= 2                                     → "Target RIR N"
  /// Returns null when there is no target-effort data to show.
  static String? targetEffortLabel({
    required bool isAmrap,
    required bool isFailureType,
    required int? targetRir,
  }) {
    if (isAmrap || isFailureType || targetRir == 0) return 'Push to failure';
    if (targetRir == 1) return '1 RIR (near max)';
    if (targetRir != null) return 'Target RIR $targetRir';
    return null;
  }

  /// Build the outline target-effort + filled logged-RIR pill row. Returns
  /// null when nothing should render (Easy mode on, or no RIR data at all).
  ///
  /// [setType] is the raw set type string (e.g. 'failure', 'normal'); when it
  /// equals 'failure' the target pill reads "Push to failure" regardless of
  /// the numeric RIR.
  ///
  /// When [context] is supplied the target pill becomes tappable and opens a
  /// plain-English RIR / failure explainer bottom sheet. Pass it from any
  /// surface that has a [BuildContext]; omit it to keep the pill static.
  static Widget? buildRirPills({
    required bool isEasyMode,
    required bool isAmrap,
    required int? targetRir,
    required int? actualRir,
    String? setType,
    BuildContext? context,
  }) {
    if (isEasyMode) return null;
    final widgets = <Widget>[];

    final isFailureType = setType?.toLowerCase() == 'failure';
    final targetLabel = targetEffortLabel(
      isAmrap: isAmrap,
      isFailureType: isFailureType,
      targetRir: targetRir,
    );

    if (targetLabel != null) {
      // "Push to failure" gets the orange treatment so it visually reads as a
      // higher-intensity instruction than a routine RIR target.
      final pushToFailure = targetLabel == 'Push to failure';
      final pillColor = pushToFailure ? AppColors.orange : AppColors.cyan;
      final pill = _rirPill(
        label: targetLabel,
        filled: false,
        color: pillColor,
        showInfoDot: context != null,
      );
      widgets.add(
        context == null
            ? pill
            : GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => showRirExplainerSheet(
                  context,
                  isAmrap: isAmrap,
                  isFailureType: isFailureType,
                  targetRir: targetRir,
                ),
                child: pill,
              ),
      );
    }

    if (actualRir != null) {
      if (widgets.isNotEmpty) widgets.add(const SizedBox(width: 4));
      widgets.add(_rirPill(
        label: 'Logged RIR $actualRir',
        filled: true,
        color: AppColors.cyan,
      ));
    }

    if (widgets.isEmpty) return null;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(mainAxisSize: MainAxisSize.min, children: widgets),
    );
  }

  static Widget _rirPill({
    required String label,
    required bool filled,
    required Color color,
    bool showInfoDot = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: filled ? color.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: filled ? 0 : 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          // A tiny "ⓘ" affordance hints the pill is tappable for an explainer.
          if (showInfoDot) ...[
            const SizedBox(width: 3),
            Icon(Icons.info_outline, size: 9, color: color),
          ],
        ],
      ),
    );
  }

  /// Show the plain-English RIR / "push to failure" explainer bottom sheet.
  ///
  /// Content comes from [TrainingExplainers] so the copy lives in one place
  /// and stays testable. Public so any set-row surface can trigger it.
  static Future<void> showRirExplainerSheet(
    BuildContext context, {
    required bool isAmrap,
    required bool isFailureType,
    int? targetRir,
  }) {
    final explainer = TrainingExplainers.forSet(
      isAmrap: isAmrap,
      isFailureType: isFailureType,
      targetRir: targetRir,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accent = AccentColorScope.of(context).getColor(isDark);

    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              20 + MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Grab handle.
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: textMuted.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        explainer.title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  explainer.body,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: textMuted,
                  ),
                ),
                if (explainer.takeaway != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      explainer.takeaway!,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: accent,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text(
                      'Got it',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
