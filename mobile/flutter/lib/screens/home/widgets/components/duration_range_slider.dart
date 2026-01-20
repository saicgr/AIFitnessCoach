import 'package:flutter/material.dart';
import 'sheet_theme_colors.dart';

/// A widget for selecting workout duration range with a two-thumb slider
class DurationRangeSlider extends StatelessWidget {
  /// Current minimum duration value in minutes
  final double durationMin;

  /// Current maximum duration value in minutes
  final double durationMax;

  /// Callback when duration range changes
  final ValueChanged<RangeValues> onChanged;

  /// Minimum allowed duration in minutes
  final double minDuration;

  /// Maximum allowed duration in minutes
  final double maxDuration;

  /// Number of discrete steps
  final int? divisions;

  /// Whether the slider is disabled
  final bool disabled;

  /// Accent color for the slider
  final Color? accentColor;

  const DurationRangeSlider({
    super.key,
    required this.durationMin,
    required this.durationMax,
    required this.onChanged,
    this.minDuration = 15,
    this.maxDuration = 90,
    this.divisions = 15,
    this.disabled = false,
    this.accentColor,
  });

  String _formatDuration() {
    final min = durationMin.round();
    final max = durationMax.round();
    if (min == max) {
      return '$min min';
    }
    return '$min-$max min';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sheetColors;
    final sliderColor = accentColor ?? colors.orange;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 20, color: sliderColor),
              const SizedBox(width: 8),
              Text(
                'Duration',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: colors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: sliderColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatDuration(),
                  style: TextStyle(
                    color: sliderColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: sliderColor,
              inactiveTrackColor: colors.glassSurface,
              thumbColor: sliderColor,
              overlayColor: sliderColor.withOpacity(0.2),
              trackHeight: 6,
              rangeThumbShape: const RoundRangeSliderThumbShape(
                enabledThumbRadius: 10,
              ),
              rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
            ),
            child: RangeSlider(
              values: RangeValues(durationMin, durationMax),
              min: minDuration,
              max: maxDuration,
              divisions: divisions,
              onChanged: disabled ? null : onChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${minDuration.toInt()} min',
                  style: TextStyle(fontSize: 12, color: colors.textMuted),
                ),
                Text(
                  '${maxDuration.toInt()} min',
                  style: TextStyle(fontSize: 12, color: colors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
