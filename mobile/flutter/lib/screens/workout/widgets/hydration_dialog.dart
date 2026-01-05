import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';

/// Shows a bottom sheet for logging water/drink intake
Future<int?> showHydrationDialog({
  required BuildContext context,
  required int totalIntakeMl,
}) async {
  int selectedAmount = 250;
  bool useOz = false;
  final customController = TextEditingController();

  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setModalState) {
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

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Title with unit toggle
                Row(
                  children: [
                    const Icon(Icons.water_drop, color: Colors.blue, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Log Water Intake',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Total: ${formatTotal()}',
                            style: const TextStyle(
                              color: AppColors.textMuted,
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
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.blue),
                        ),
                        child: Text(
                          useOz ? 'oz' : 'ml',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
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
                      onTap: (amount) {
                        setModalState(() {
                          selectedAmount = amount;
                          customController.clear();
                        });
                      },
                    ),
                    _DrinkAmountChip(
                      amountMl: 3785,
                      label: '1 gal',
                      selected: selectedAmount,
                      useOz: useOz,
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
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Custom amount',
                    hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.5)),
                    filled: true,
                    fillColor: AppColors.elevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    suffixText: useOz ? 'oz' : 'ml',
                    suffixStyle: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
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
                      Navigator.pop(ctx, selectedAmount);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Log ${formatAmount(selectedAmount)}',
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
  );
}

class _DrinkAmountChip extends StatelessWidget {
  final int amountMl;
  final String? label;
  final int selected;
  final bool useOz;
  final ValueChanged<int> onTap;

  const _DrinkAmountChip({
    required this.amountMl,
    this.label,
    required this.selected,
    required this.useOz,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = amountMl == selected;
    final displayLabel = label ??
        (useOz ? '${(amountMl / 29.5735).toStringAsFixed(1)}oz' : '${amountMl}ml');

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap(amountMl);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.2) : AppColors.elevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : AppColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          displayLabel,
          style: TextStyle(
            color: isSelected ? Colors.blue : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
