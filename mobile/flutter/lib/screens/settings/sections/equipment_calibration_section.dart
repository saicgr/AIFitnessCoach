import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/equipment_calibration_repository.dart';
import '../../equipment/equipment_calibration_screen.dart';
import '../widgets/section_header.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Entry point on the Equipment settings page that opens the per-user
/// calibration flow (Phase 1 of workouts overhaul).
///
/// Shows the count of calibrated rows when present so users can tell at a
/// glance whether they've already set their bar weights / sled / plates.
class EquipmentCalibrationSection extends ConsumerWidget {
  const EquipmentCalibrationSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor =
        isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final listAsync = ref.watch(equipmentCalibrationListProvider);
    final count = listAsync.asData?.value.length ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: AppLocalizations.of(context).equipmentCalibrationCalibration),
        const SizedBox(height: 12),
        Material(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const EquipmentCalibrationScreen(),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: cardBorder.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      color: textPrimary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context).equipmentCalibrationTitle,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          count == 0
                              ? AppLocalizations.of(context).equipmentCalibrationSetBarSledCable
                              : '$count item${count == 1 ? '' : 's'} calibrated',
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
