import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../data/services/haptic_service.dart';
import '../../beast_mode_constants.dart';

/// Tappable monospace cell for editable table values.
class TappableCell extends StatelessWidget {
  final String text;
  final Color textColor;
  final bool isDark;
  final VoidCallback onTap;

  const TappableCell({
    super.key,
    required this.text,
    required this.textColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticService.selection();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.orange.withValues(alpha: isDark ? 0.06 : 0.04),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.orange.withValues(alpha: 0.15)),
        ),
        child: Text(
          text,
          style: TextStyle(
              fontSize: 11, color: textColor, fontFamily: 'monospace'),
        ),
      ),
    );
  }
}

/// Tappable bias dropdown cell for mood multipliers.
class TappableBiasCell extends StatelessWidget {
  final String current;
  final Color textColor;
  final bool isDark;
  final ValueChanged<String> onSelected;

  const TappableBiasCell({
    super.key,
    required this.current,
    required this.textColor,
    required this.isDark,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticService.selection();
        _showBiasDropdown(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.orange.withValues(alpha: isDark ? 0.06 : 0.04),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.orange.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(current,
                  style: TextStyle(fontSize: 10, color: textColor),
                  overflow: TextOverflow.ellipsis),
            ),
            Icon(Icons.arrow_drop_down, size: 12, color: AppColors.orange),
          ],
        ),
      ),
    );
  }

  void _showBiasDropdown(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final textPrimary =
            isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select Bias',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textPrimary)),
              const SizedBox(height: 12),
              ...kBiasOptions.map((bias) {
                final isSelected = bias == current;
                return ListTile(
                  dense: true,
                  title: Text(bias,
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected ? AppColors.orange : textPrimary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      )),
                  trailing: isSelected
                      ? Icon(Icons.check, color: AppColors.orange, size: 18)
                      : null,
                  onTap: () {
                    HapticService.selection();
                    onSelected(bias);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
