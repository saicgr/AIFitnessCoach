import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../core/providers/weight_increments_provider.dart';
import 'glass_sheet.dart';

/// Shows the weight increments customization bottom sheet.
Future<void> showWeightIncrementsSheet(BuildContext context) async {
  await showGlassSheet(
    context: context,
    useRootNavigator: true,
    enableDrag: true,
    initialChildSize: 0.85,
    minChildSize: 0.4,
    maxChildSize: 0.95,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => GlassSheet(
        showHandle: false,
        child: WeightIncrementsSheet(
          scrollController: scrollController,
        ),
      ),
    ),
  );
}

/// Bottom sheet for customizing equipment-specific weight increments.
class WeightIncrementsSheet extends ConsumerWidget {
  final ScrollController? scrollController;

  const WeightIncrementsSheet({super.key, this.scrollController});

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

    return SafeArea(
        child: SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    // Inline kg/lbs toggle
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref.read(weightIncrementsProvider.notifier)
                            .setUnit(isKg ? 'lbs' : 'kg');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.swap_horiz, size: 14, color: accentColor),
                            const SizedBox(width: 4),
                            Text(
                              isKg ? 'kg' : 'lbs',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: accentColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
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

              // Reset button with info
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      ref.read(weightIncrementsProvider.notifier).resetToDefaults();
                      final defaults = WeightIncrementsState.defaultsForUnit(state.unit);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Reset to ${isKg ? "kg" : "lbs"} defaults: '
                            'Dumbbell ${_formatIncrement(defaults.dumbbell)}, '
                            'Barbell ${_formatIncrement(defaults.barbell)}, '
                            'Machine ${_formatIncrement(defaults.machine)}',
                          ),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.refresh,
                      color: textMuted,
                      size: 18,
                    ),
                    label: Text(
                      'Use Defaults',
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      final defaults = WeightIncrementsState.defaultsForUnit(state.unit);
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text('Default Increments (${isKg ? "kg" : "lbs"})'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Based on standard commercial gym equipment:',
                                style: TextStyle(fontSize: 13),
                              ),
                              const SizedBox(height: 12),
                              _buildDefaultRow('Dumbbells', defaults.dumbbell, state.unit),
                              _buildDefaultRow('Barbell', defaults.barbell, state.unit),
                              _buildDefaultRow('Machine', defaults.machine, state.unit),
                              _buildDefaultRow('Kettlebell', defaults.kettlebell, state.unit),
                              _buildDefaultRow('Cable', defaults.cable, state.unit),
                              const SizedBox(height: 12),
                              Text(
                                'Sources: Rogue, Life Fitness, Eleiko',
                                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Got it'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.info_outline, size: 18, color: textMuted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
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

  Widget _buildDefaultRow(String label, double value, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            '${_formatIncrement(value)} $unit',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
