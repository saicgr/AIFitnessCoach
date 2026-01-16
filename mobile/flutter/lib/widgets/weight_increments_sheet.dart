import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../core/providers/weight_increments_provider.dart';

/// Shows the weight increments customization bottom sheet.
Future<void> showWeightIncrementsSheet(BuildContext context) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const WeightIncrementsSheet(),
  );
}

/// Bottom sheet for customizing equipment-specific weight increments.
class WeightIncrementsSheet extends ConsumerWidget {
  const WeightIncrementsSheet({super.key});

  /// Increment options for kg.
  static const incrementOptionsKg = [0.5, 1.0, 1.25, 2.0, 2.5, 4.0, 5.0, 10.0];

  /// Increment options for lbs.
  static const incrementOptionsLbs = [1.0, 2.0, 2.5, 5.0, 10.0, 15.0, 20.0, 25.0];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(weightIncrementsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.nearBlack : AppColorsLight.pureWhite;
    final cardBackground = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accentColor = isDark ? AppColors.orange : AppColorsLight.orange;

    final isKg = state.unit == 'kg';
    final options = isKg ? incrementOptionsKg : incrementOptionsLbs;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header with unit toggle
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.tune,
                      color: accentColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Weight Increments',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                        ),
                        Text(
                          'Customize +/- step size per equipment',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Unit toggle (kg/lbs)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cardBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildUnitToggleButton(
                        context,
                        ref,
                        'kg',
                        isKg,
                        () {
                          HapticFeedback.selectionClick();
                          ref.read(weightIncrementsProvider.notifier).setUnit('kg');
                        },
                        textPrimary,
                        textMuted,
                        accentColor,
                      ),
                    ),
                    Expanded(
                      child: _buildUnitToggleButton(
                        context,
                        ref,
                        'lbs',
                        !isKg,
                        () {
                          HapticFeedback.selectionClick();
                          ref.read(weightIncrementsProvider.notifier).setUnit('lbs');
                        },
                        textPrimary,
                        textMuted,
                        accentColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Equipment rows
              Text(
                'EQUIPMENT INCREMENTS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: textMuted,
                ),
              ),
              const SizedBox(height: 12),

              _buildEquipmentRow(
                context,
                ref,
                'Dumbbells',
                Icons.fitness_center,
                'dumbbell',
                state.dumbbell,
                options,
                state.unit,
                isDark,
                cardBackground,
                textPrimary,
                textSecondary,
                textMuted,
                cardBorder,
                accentColor,
              ),
              const SizedBox(height: 12),
              _buildEquipmentRow(
                context,
                ref,
                'Barbell',
                Icons.sports_martial_arts,
                'barbell',
                state.barbell,
                options,
                state.unit,
                isDark,
                cardBackground,
                textPrimary,
                textSecondary,
                textMuted,
                cardBorder,
                accentColor,
              ),
              const SizedBox(height: 12),
              _buildEquipmentRow(
                context,
                ref,
                'Machine',
                Icons.precision_manufacturing,
                'machine',
                state.machine,
                options,
                state.unit,
                isDark,
                cardBackground,
                textPrimary,
                textSecondary,
                textMuted,
                cardBorder,
                accentColor,
              ),
              const SizedBox(height: 12),
              _buildEquipmentRow(
                context,
                ref,
                'Kettlebell',
                Icons.sports_handball,
                'kettlebell',
                state.kettlebell,
                options,
                state.unit,
                isDark,
                cardBackground,
                textPrimary,
                textSecondary,
                textMuted,
                cardBorder,
                accentColor,
              ),
              const SizedBox(height: 12),
              _buildEquipmentRow(
                context,
                ref,
                'Cable',
                Icons.cable,
                'cable',
                state.cable,
                options,
                state.unit,
                isDark,
                cardBackground,
                textPrimary,
                textSecondary,
                textMuted,
                cardBorder,
                accentColor,
              ),
              const SizedBox(height: 24),

              // Reset button
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    ref.read(weightIncrementsProvider.notifier).resetToDefaults();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reset to default increments'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.refresh,
                    color: textMuted,
                    size: 18,
                  ),
                  label: Text(
                    'Reset to Defaults',
                    style: TextStyle(
                      color: textMuted,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnitToggleButton(
    BuildContext context,
    WidgetRef ref,
    String unit,
    bool isSelected,
    VoidCallback onTap,
    Color textPrimary,
    Color textMuted,
    Color accentColor,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            unit.toUpperCase(),
            style: TextStyle(
              color: isSelected ? Colors.white : textMuted,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEquipmentRow(
    BuildContext context,
    WidgetRef ref,
    String label,
    IconData icon,
    String equipment,
    double currentValue,
    List<double> options,
    String unit,
    bool isDark,
    Color cardBackground,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
    Color cardBorder,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label row
          Row(
            children: [
              Icon(icon, size: 20, color: textSecondary),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_formatIncrement(currentValue)} $unit',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Increment chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((value) {
              final isSelected = value == currentValue;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref.read(weightIncrementsProvider.notifier).setIncrement(equipment, value);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accentColor
                        : (isDark ? AppColors.surface : AppColorsLight.surface),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? accentColor : cardBorder,
                    ),
                  ),
                  child: Text(
                    _formatIncrement(value),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _formatIncrement(double value) {
    // Remove trailing zeros for cleaner display
    if (value == value.toInt()) {
      return value.toInt().toString();
    }
    return value.toString();
  }
}
