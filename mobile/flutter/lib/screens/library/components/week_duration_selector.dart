import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/branded_program.dart';

/// A widget for selecting program duration (weeks) and sessions per week.
///
/// Shows a slider with tick marks at anchor durations and a chip row
/// for sessions-per-week selection.
class WeekDurationSelector extends StatelessWidget {
  final ProgramDurationInfo durationInfo;
  final int selectedWeeks;
  final int selectedSessionsPerWeek;
  final ValueChanged<int> onWeeksChanged;
  final ValueChanged<int> onSessionsChanged;

  const WeekDurationSelector({
    super.key,
    required this.durationInfo,
    required this.selectedWeeks,
    required this.selectedSessionsPerWeek,
    required this.onWeeksChanged,
    required this.onSessionsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    final minW = durationInfo.minWeeks.toDouble();
    final maxW = durationInfo.maxWeeks.toDouble();
    final anchors = durationInfo.anchorWeeks;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Text(
            'CUSTOMIZE DURATION',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textMuted,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          // Weeks slider
          Row(
            children: [
              Icon(Icons.calendar_today, size: 18, color: cyan),
              const SizedBox(width: 8),
              Text(
                'Duration',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: cyan.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$selectedWeeks weeks',
                  style: TextStyle(
                    color: cyan,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: cyan,
              inactiveTrackColor: (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
              thumbColor: cyan,
              overlayColor: cyan.withOpacity(0.2),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: selectedWeeks.toDouble().clamp(minW, maxW),
              min: minW,
              max: maxW,
              divisions: (maxW - minW).round().clamp(1, 100),
              onChanged: (v) => onWeeksChanged(v.round()),
            ),
          ),

          // Anchor tick labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _buildTickLabels(anchors, minW, maxW, cyan, textMuted),
            ),
          ),

          const SizedBox(height: 24),

          // Sessions per week
          Row(
            children: [
              Icon(Icons.repeat, size: 18, color: cyan),
              const SizedBox(width: 8),
              Text(
                'Sessions / week',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Sessions chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: durationInfo.availableSessionsPerWeek.map((spw) {
              final isSelected = spw == selectedSessionsPerWeek;
              return ChoiceChip(
                label: Text('$spw/wk'),
                selected: isSelected,
                onSelected: (_) => onSessionsChanged(spw),
                selectedColor: cyan.withOpacity(0.25),
                backgroundColor: elevated,
                labelStyle: TextStyle(
                  color: isSelected ? cyan : textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
                side: BorderSide(
                  color: isSelected ? cyan : Colors.transparent,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Build positioned tick labels under the slider at anchor points.
  List<Widget> _buildTickLabels(
    List<int> anchors,
    double minW,
    double maxW,
    Color accentColor,
    Color mutedColor,
  ) {
    if (anchors.isEmpty) return [];

    // If only one anchor, show it centered
    if (anchors.length == 1) {
      return [
        Text(
          '${anchors.first}w',
          style: TextStyle(fontSize: 11, color: mutedColor, fontWeight: FontWeight.w500),
        ),
      ];
    }

    // Show min, max, and up to 3 middle anchors
    final labels = <int>[];
    labels.add(anchors.first);
    if (anchors.length > 2) {
      // Pick evenly spaced middle anchors
      final middleCount = (anchors.length - 2).clamp(0, 3);
      final step = (anchors.length - 1) / (middleCount + 1);
      for (int i = 1; i <= middleCount; i++) {
        labels.add(anchors[(step * i).round()]);
      }
    }
    labels.add(anchors.last);

    return labels.map((w) {
      final isSelected = w == selectedWeeks;
      return Text(
        '${w}w',
        style: TextStyle(
          fontSize: 11,
          color: isSelected ? accentColor : mutedColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
      );
    }).toList();
  }
}
