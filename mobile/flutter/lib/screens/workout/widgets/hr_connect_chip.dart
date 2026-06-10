/// Slim one-line "connect a heart rate monitor" hint for the Summary tab.
///
/// Replaces the old full-height empty Heart Rate card: when a session has no
/// HR readings there's nothing to chart, so the section collapses to this
/// single-row chip instead of a 100px placeholder. The full chart card still
/// renders (in workout_summary_general.dart) whenever readings exist.
library;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';

class HrConnectChip extends StatelessWidget {
  final bool isDark;

  const HrConnectChip({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // The localized string carries a layout newline for the old tall
    // placeholder — flatten it for this single-line chip.
    final label = AppLocalizations.of(context)
        .workoutSummaryGeneralConnectAHeartRate
        .replaceAll('\\n', ' ')
        .replaceAll('\n', ' ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevated : AppColorsLight.elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.favorite_border,
            size: 16,
            color: isDark ? AppColors.textMuted : Colors.grey.shade400,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? AppColors.textMuted : Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
