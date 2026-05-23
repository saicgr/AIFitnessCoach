import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../widgets/glass_sheet.dart';
import '../../../../../widgets/main_shell.dart' show floatingNavBarVisibleProvider;

/// Shows a bottom sheet with a slider for editing a single value.
Future<void> showSliderDialog({
  required BuildContext context,
  required String title,
  required double value,
  required double min,
  required double max,
  required double step,
  required String Function(double) format,
  required ValueChanged<double> onChanged,
}) async {
  var currentValue = value;
  final divisions = ((max - min) / step).round();

  final container = ProviderScope.containerOf(context, listen: false);
  container.read(floatingNavBarVisibleProvider.notifier).state = false;
  try {
    await showGlassSheet<void>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final textPrimary =
            isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
        return GlassSheet(
          opaque: true,
          child: StatefulBuilder(builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                      inactiveTrackColor:
                          AppColors.orange.withValues(alpha: 0.2),
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
          }),
        );
      },
    );
  } finally {
    Future.microtask(() {
      try {
        container.read(floatingNavBarVisibleProvider.notifier).state = true;
      } catch (_) {}
    });
  }
}
