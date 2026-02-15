import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/hydration.dart';
import '../../../widgets/glass_sheet.dart';

/// Result from the hydration dialog
class HydrationDialogResult {
  final DrinkType drinkType;
  final int amountMl;

  const HydrationDialogResult({
    required this.drinkType,
    required this.amountMl,
  });
}

/// Shows a bottom sheet for logging drink intake with type selection
Future<HydrationDialogResult?> showHydrationDialog({
  required BuildContext context,
  required int totalIntakeMl,
  DrinkType initialDrinkType = DrinkType.water,
}) async {
  DrinkType selectedDrinkType = initialDrinkType;
  int selectedAmount = 250;
  bool useOz = false;
  final customController = TextEditingController();

  return showGlassSheet<HydrationDialogResult>(
    context: context,
    enableDrag: true,
    builder: (ctx) => GlassSheet(
      child: StatefulBuilder(
      builder: (context, setModalState) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
        final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
        final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
        final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

        Color getDrinkColor(DrinkType type) {
          switch (type) {
            case DrinkType.water:
              return AppColors.teal;
            case DrinkType.proteinShake:
              return AppColors.purple;
            case DrinkType.sportsDrink:
              return AppColors.orange;
            case DrinkType.coffee:
              return const Color(0xFF8B4513);
            case DrinkType.other:
              return textMuted;
          }
        }

        String formatAmount(int ml) {
          if (useOz) {
            return '${(ml / 29.5735).toStringAsFixed(1)} oz';
          }
          return '${ml}ml';
        }

        String formatTotal() {
          if (useOz) {
            return '${(totalIntakeMl / 29.5735).toStringAsFixed(1)} oz';
          }
          return '${(totalIntakeMl / 1000).toStringAsFixed(2)}L';
        }

        final drinkColor = getDrinkColor(selectedDrinkType);

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title row with close button
                Row(
                  children: [
                    Text(
                      selectedDrinkType.emoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Log ${selectedDrinkType.label}',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Total today: ${formatTotal()}',
                            style: TextStyle(
                              color: textMuted,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Unit toggle
                    GestureDetector(
                      onTap: () {
                        setModalState(() => useOz = !useOz);
                        HapticFeedback.selectionClick();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: drinkColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: drinkColor),
                        ),
                        child: Text(
                          useOz ? 'oz' : 'ml',
                          style: TextStyle(
                            color: drinkColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Drink type selector
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: DrinkType.values.map((type) {
                      final isSelected = type == selectedDrinkType;
                      final typeColor = getDrinkColor(type);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setModalState(() => selectedDrinkType = type);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? typeColor.withOpacity(0.2) : elevated,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? typeColor : cardBorder,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(type.emoji, style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 6),
                                Text(
                                  type.label,
                                  style: TextStyle(
                                    color: isSelected ? typeColor : textMuted,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 20),

                // Quick amount buttons
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _DrinkAmountChip(
                      amountMl: 250,
                      selected: selectedAmount,
                      useOz: useOz,
                      accentColor: drinkColor,
                      isDark: isDark,
                      onTap: (amount) {
                        setModalState(() {
                          selectedAmount = amount;
                          customController.clear();
                        });
                      },
                    ),
                    _DrinkAmountChip(
                      amountMl: 350,
                      selected: selectedAmount,
                      useOz: useOz,
                      accentColor: drinkColor,
                      isDark: isDark,
                      onTap: (amount) {
                        setModalState(() {
                          selectedAmount = amount;
                          customController.clear();
                        });
                      },
                    ),
                    _DrinkAmountChip(
                      amountMl: 500,
                      selected: selectedAmount,
                      useOz: useOz,
                      accentColor: drinkColor,
                      isDark: isDark,
                      onTap: (amount) {
                        setModalState(() {
                          selectedAmount = amount;
                          customController.clear();
                        });
                      },
                    ),
                    _DrinkAmountChip(
                      amountMl: 750,
                      selected: selectedAmount,
                      useOz: useOz,
                      accentColor: drinkColor,
                      isDark: isDark,
                      onTap: (amount) {
                        setModalState(() {
                          selectedAmount = amount;
                          customController.clear();
                        });
                      },
                    ),
                    _DrinkAmountChip(
                      amountMl: 1000,
                      selected: selectedAmount,
                      useOz: useOz,
                      accentColor: drinkColor,
                      isDark: isDark,
                      onTap: (amount) {
                        setModalState(() {
                          selectedAmount = amount;
                          customController.clear();
                        });
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Custom input
                TextField(
                  controller: customController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(color: textPrimary, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Custom amount',
                    hintStyle: TextStyle(color: textMuted.withOpacity(0.5)),
                    filled: true,
                    fillColor: elevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    suffixText: useOz ? 'oz' : 'ml',
                    suffixStyle: TextStyle(color: drinkColor, fontWeight: FontWeight.bold),
                  ),
                  onChanged: (val) {
                    final parsed = double.tryParse(val);
                    if (parsed != null && parsed > 0) {
                      setModalState(() {
                        selectedAmount = useOz ? (parsed * 29.5735).round() : parsed.round();
                      });
                    }
                  },
                ),

                const SizedBox(height: 20),

                // Log button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx, HydrationDialogResult(
                        drinkType: selectedDrinkType,
                        amountMl: selectedAmount,
                      ));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: drinkColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Log ${formatAmount(selectedAmount)} ${selectedDrinkType.label}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),

                SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
              ],
            ),
          ),
        );
      },
    ),
    ),
  );
}

class _DrinkAmountChip extends StatelessWidget {
  final int amountMl;
  final String? label;
  final int selected;
  final bool useOz;
  final Color accentColor;
  final bool isDark;
  final ValueChanged<int> onTap;

  const _DrinkAmountChip({
    required this.amountMl,
    this.label,
    required this.selected,
    required this.useOz,
    required this.accentColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = amountMl == selected;
    final displayLabel = label ??
        (useOz ? '${(amountMl / 29.5735).toStringAsFixed(1)}oz' : '${amountMl}ml');

    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap(amountMl);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withOpacity(0.2) : elevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accentColor : cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          displayLabel,
          style: TextStyle(
            color: isSelected ? accentColor : textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
