import 'package:flutter/material.dart';

import '../../../../shareables/widgets/fitwiz_watermark.dart';

/// Legacy adapter — delegates to the unified [FitWizWatermark]. New code
/// should import the shareables module directly.
class AppWatermark extends StatelessWidget {
  final Color? backgroundColor;
  final List<Color>? gradientColors;

  const AppWatermark({
    super.key,
    this.backgroundColor,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const FitWizWatermark(iconSize: 24, fontSize: 13),
        ),
      ],
    );
  }
}
