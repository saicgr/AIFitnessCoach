import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_colors.dart';

/// A dialog shown when there's a mismatch between selected training split
/// and the user's current workout days.
///
/// Provides two options:
/// 1. Keep current days (AI will suggest a compatible split)
/// 2. Update to the split's recommended schedule
class ScheduleMismatchDialog extends StatefulWidget {
  final String splitName;
  final int requiredDays;
  final int currentDayCount;
  final String currentDayNames;
  final List<int> newDays;
  final String newDayNames;
  final String compatibleSplitName;
  final VoidCallback onKeepDays;
  final VoidCallback onUpdateDays;

  const ScheduleMismatchDialog({
    super.key,
    required this.splitName,
    required this.requiredDays,
    required this.currentDayCount,
    required this.currentDayNames,
    required this.newDays,
    required this.newDayNames,
    required this.compatibleSplitName,
    required this.onKeepDays,
    required this.onUpdateDays,
  });

  @override
  State<ScheduleMismatchDialog> createState() => _ScheduleMismatchDialogState();
}

class _ScheduleMismatchDialogState extends State<ScheduleMismatchDialog> {
  String? _selectedOption;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accentColor = isDark ? AppColors.cyan : AppColorsLight.cyan;

    return AlertDialog(
      backgroundColor: elevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.calendar_month, color: AppColors.orange, size: 24),
          const SizedBox(width: 10),
          Text(
            'Schedule Mismatch',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.splitName} requires ${widget.requiredDays} days per week, but you currently have ${widget.currentDayCount} days selected.',
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // Option 1: Keep current days
          _buildOptionTile(
            isSelected: _selectedOption == 'keep',
            onTap: () => setState(() => _selectedOption = 'keep'),
            title: 'Keep my current days',
            subtitle: widget.currentDayNames,
            description: 'AI will switch to ${widget.compatibleSplitName} instead',
            isDark: isDark,
            textPrimary: textPrimary,
            textMuted: textMuted,
            cardBorder: cardBorder,
            accentColor: accentColor,
          ),

          const SizedBox(height: 12),

          // Option 2: Update to split's schedule
          _buildOptionTile(
            isSelected: _selectedOption == 'update',
            onTap: () => setState(() => _selectedOption = 'update'),
            title: 'Update to ${widget.splitName} schedule',
            subtitle: widget.newDayNames,
            description: 'Use the full ${widget.requiredDays}-day program',
            isRecommended: true,
            isDark: isDark,
            textPrimary: textPrimary,
            textMuted: textMuted,
            cardBorder: cardBorder,
            accentColor: accentColor,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(color: textMuted),
          ),
        ),
        TextButton(
          onPressed: _selectedOption == null
              ? null
              : () {
                  if (_selectedOption == 'keep') {
                    widget.onKeepDays();
                  } else {
                    widget.onUpdateDays();
                  }
                },
          child: Text(
            'Confirm',
            style: TextStyle(
              color: _selectedOption == null ? textMuted : accentColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionTile({
    required bool isSelected,
    required VoidCallback onTap,
    required String title,
    required String subtitle,
    required String description,
    bool isRecommended = false,
    required bool isDark,
    required Color textPrimary,
    required Color textMuted,
    required Color cardBorder,
    required Color accentColor,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.1)
              : (isDark ? AppColors.elevated : AppColorsLight.elevated),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accentColor : cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Radio indicator
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? accentColor : textMuted,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentColor,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (isRecommended)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Recommended',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper functions for schedule mismatch handling
class ScheduleMismatchHelper {
  /// Get default workout day indices for a given day count
  static List<int> getDefaultDaysForCount(int dayCount) {
    switch (dayCount) {
      case 2: return [0, 3];           // Mon, Thu
      case 3: return [0, 2, 4];        // Mon, Wed, Fri
      case 4: return [0, 1, 3, 4];     // Mon, Tue, Thu, Fri
      case 5: return [0, 1, 2, 3, 4];  // Mon-Fri
      case 6: return [0, 1, 2, 3, 4, 5]; // Mon-Sat
      default: return [];
    }
  }

  /// Get the compatible split for a given day count
  static String getCompatibleSplitForDays(int dayCount) {
    switch (dayCount) {
      case 2: return 'full_body_minimal';
      case 3: return 'full_body';
      case 4: return 'upper_lower';
      case 5: return 'pplul';
      case 6: return 'ppl_6day';
      default: return 'dont_know';
    }
  }

  /// Format day indices as readable names
  static String formatDayNames(List<int> dayIndices) {
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return dayIndices.map((i) => dayNames[i]).join(', ');
  }

  /// Get a display-friendly name for a split key
  static String getSplitDisplayName(String splitKey) {
    const splitNames = {
      'full_body': 'Full Body',
      'full_body_minimal': 'Full Body (2-Day)',
      'upper_lower': 'Upper/Lower',
      'push_pull_legs': 'Push/Pull/Legs',
      'ppl_3day': 'Push/Pull/Legs',
      'ppl_6day': 'Push/Pull/Legs (6-Day)',
      'pplul': 'PPLUL (5-Day)',
      'phul': 'PHUL',
      'arnold_split': 'Arnold Split',
      'body_part': 'Bro Split',
      'dont_know': 'AI Adaptive',
      'ai_adaptive': 'AI Adaptive',
    };
    return splitNames[splitKey] ?? splitKey;
  }
}
