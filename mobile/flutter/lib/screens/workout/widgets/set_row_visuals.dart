import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

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

  /// Build the outline target-RIR + filled logged-RIR pill row. Returns null
  /// when nothing should render (Easy mode on, or no RIR data at all).
  static Widget? buildRirPills({
    required bool isEasyMode,
    required bool isAmrap,
    required int? targetRir,
    required int? actualRir,
  }) {
    if (isEasyMode) return null;
    final widgets = <Widget>[];

    if (isAmrap) {
      widgets.add(_rirPill(
        label: 'Target RIR · AMRAP',
        filled: false,
        color: AppColors.cyan,
      ));
    } else if (targetRir != null) {
      widgets.add(_rirPill(
        label: 'Target RIR $targetRir',
        filled: false,
        color: AppColors.cyan,
      ));
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
    return Row(mainAxisSize: MainAxisSize.min, children: widgets);
  }

  static Widget _rirPill({
    required String label,
    required bool filled,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: filled ? color.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: filled ? 0 : 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
