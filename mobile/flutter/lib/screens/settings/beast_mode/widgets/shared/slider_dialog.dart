import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';

/// Shows a bottom sheet with a slider for editing a single value.
void showSliderDialog({
  required BuildContext context,
  required String title,
  required double value,
  required double min,
  required double max,
  required double step,
  required String Function(double) format,
  required ValueChanged<double> onChanged,
}) {
  var currentValue = value;
  final divisions = ((max - min) / step).round();

  showModalBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).brightness == Brightness.dark
        ? AppColors.elevated
        : AppColorsLight.elevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      final textPrimary =
          isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
      return StatefulBuilder(builder: (ctx, setSheetState) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textPrimary)),
              const SizedBox(height: 4),
              Text(format(currentValue),
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.orange,
                      fontFamily: 'monospace')),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.orange,
                  inactiveTrackColor: AppColors.orange.withValues(alpha: 0.2),
                  thumbColor: AppColors.orange,
                  overlayColor: AppColors.orange.withValues(alpha: 0.1),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: currentValue.clamp(min, max),
                  min: min,
                  max: max,
                  divisions: divisions,
                  onChanged: (v) {
                    setSheetState(() => currentValue = v);
                    onChanged(v);
                  },
                ),
              ),
            ],
          ),
        );
      });
    },
  );
}
