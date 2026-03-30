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
    initialChildSize: 0.75,
    minChildSize: 0.4,
    maxChildSize: 0.85,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.85,
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

/// Slider-based bottom sheet for customizing equipment-specific weight increments.
class WeightIncrementsSheet extends ConsumerStatefulWidget {
  final ScrollController? scrollController;

  const WeightIncrementsSheet({super.key, this.scrollController});

  @override
  ConsumerState<WeightIncrementsSheet> createState() => _WeightIncrementsSheetState();
}

class _WeightIncrementsSheetState extends ConsumerState<WeightIncrementsSheet> {
  /// Snap points for the slider (common real-world increments).
  static const _snapPoints = [0.5, 1.0, 1.25, 2.0, 2.5, 5.0, 10.0, 15.0, 20.0, 25.0];

  /// Find the nearest snap point index for a value.
  static int _nearestSnapIndex(double value) {
    int closest = 0;
    double minDiff = (value - _snapPoints[0]).abs();
    for (int i = 1; i < _snapPoints.length; i++) {
      final diff = (value - _snapPoints[i]).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = i;
      }
    }
    return closest;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(weightIncrementsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBackground = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accentColor = isDark ? AppColors.orange : AppColorsLight.orange;
    final isKg = state.unit == 'kg';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.tune, color: accentColor, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weight Increments',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        'Customize +/- step size per equipment',
                        style: TextStyle(color: textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Unit toggle
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(weightIncrementsProvider.notifier)
                        .setUnit(isKg ? 'lbs' : 'kg');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
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
            const SizedBox(height: 12),

            // Equipment sliders
            _buildSliderRow(
              context, ref, 'Dumbbells', Icons.fitness_center, 'dumbbell',
              state.dumbbell, state.unit, isDark, cardBackground, textPrimary,
              textSecondary, textMuted, cardBorder, accentColor,
            ),
            const SizedBox(height: 6),
            _buildBarbellRow(
              context, ref, state, isDark, cardBackground, textPrimary,
              textSecondary, textMuted, cardBorder, accentColor,
            ),
            const SizedBox(height: 6),
            _buildSliderRow(
              context, ref, 'Machine', Icons.precision_manufacturing, 'machine',
              state.machine, state.unit, isDark, cardBackground, textPrimary,
              textSecondary, textMuted, cardBorder, accentColor,
            ),
            const SizedBox(height: 6),
            _buildSliderRow(
              context, ref, 'Kettlebell', Icons.sports_handball, 'kettlebell',
              state.kettlebell, state.unit, isDark, cardBackground, textPrimary,
              textSecondary, textMuted, cardBorder, accentColor,
            ),
            const SizedBox(height: 6),
            _buildSliderRow(
              context, ref, 'Cable', Icons.cable, 'cable',
              state.cable, state.unit, isDark, cardBackground, textPrimary,
              textSecondary, textMuted, cardBorder, accentColor,
            ),
            const SizedBox(height: 10),

            // Use Defaults + Info
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    ref.read(weightIncrementsProvider.notifier).resetToDefaults();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Reset to ${isKg ? "kg" : "lbs"} defaults'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: Icon(Icons.refresh, color: textMuted, size: 16),
                  label: Text('Use Defaults', style: TextStyle(color: textMuted, fontSize: 13)),
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
                            const Text('Based on standard commercial gym equipment:', style: TextStyle(fontSize: 13)),
                            const SizedBox(height: 12),
                            _infoRow('Dumbbells', defaults.dumbbell, state.unit),
                            _infoRow('Barbell', defaults.barbell, '${state.unit} total'),
                            _infoRow('Machine', defaults.machine, state.unit),
                            _infoRow('Kettlebell', defaults.kettlebell, state.unit),
                            _infoRow('Cable', defaults.cable, state.unit),
                            const SizedBox(height: 12),
                            Text('Sources: Rogue, Life Fitness, Eleiko', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                          ],
                        ),
                        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Got it'))],
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.info_outline, size: 16, color: textMuted),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Standard equipment row with slider.
  Widget _buildSliderRow(
    BuildContext context, WidgetRef ref, String label, IconData icon,
    String equipment, double currentValue, String unit, bool isDark,
    Color cardBg, Color textPrimary, Color textSecondary, Color textMuted,
    Color cardBorder, Color accent,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: textSecondary),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
              const Spacer(),
              _valueBadge(currentValue, unit, accent),
              const SizedBox(width: 6),
              _customInputButton(context, ref, equipment, currentValue, unit, accent, textMuted),
            ],
          ),
          const SizedBox(height: 2),
          _incrementSlider(equipment, currentValue, accent, textMuted, ref),
        ],
      ),
    );
  }

  /// Barbell row with per-side toggle.
  Widget _buildBarbellRow(
    BuildContext context, WidgetRef ref, WeightIncrementsState state,
    bool isDark, Color cardBg, Color textPrimary, Color textSecondary,
    Color textMuted, Color cardBorder, Color accent,
  ) {
    final perSide = state.barbellPerSide;
    final displayValue = state.barbell;
    final totalValue = perSide ? displayValue * 2 : displayValue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.sports_martial_arts, size: 16, color: textSecondary),
              const SizedBox(width: 6),
              Text('Barbell', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
              const Spacer(),
              _valueBadge(displayValue, perSide ? '${state.unit}/side' : state.unit, accent),
              const SizedBox(width: 6),
              _customInputButton(context, ref, 'barbell', displayValue, state.unit, accent, textMuted),
            ],
          ),
          const SizedBox(height: 2),
          _incrementSlider('barbell', displayValue, accent, textMuted, ref),
          const SizedBox(height: 2),
          // Per-side toggle
          Row(
            children: [
              Text(
                perSide
                    ? '${_fmt(displayValue)} ${state.unit}/side = ${_fmt(totalValue)} ${state.unit} total'
                    : '${_fmt(displayValue)} ${state.unit} total',
                style: TextStyle(fontSize: 11, color: textMuted),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref.read(weightIncrementsProvider.notifier).setBarbellPerSide(!perSide);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: perSide ? accent.withValues(alpha: 0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: perSide ? accent.withValues(alpha: 0.4) : textMuted.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'Per side',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: perSide ? FontWeight.w700 : FontWeight.w500,
                      color: perSide ? accent : textMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// The horizontal slider with tick marks.
  Widget _incrementSlider(
    String equipment, double currentValue, Color accent, Color tickColor, WidgetRef ref,
  ) {
    final snapIdx = _nearestSnapIndex(currentValue);

    return SliderTheme(
      data: SliderThemeData(
        activeTrackColor: accent,
        inactiveTrackColor: accent.withValues(alpha: 0.15),
        thumbColor: accent,
        overlayColor: accent.withValues(alpha: 0.1),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
        trackHeight: 2.5,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
        tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 1.5),
        activeTickMarkColor: accent.withValues(alpha: 0.5),
        inactiveTickMarkColor: tickColor.withValues(alpha: 0.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 28,
            child: Slider(
              value: snapIdx.toDouble(),
              min: 0,
              max: (_snapPoints.length - 1).toDouble(),
              divisions: _snapPoints.length - 1,
              onChanged: (val) {
                final newValue = _snapPoints[val.round()];
                HapticFeedback.selectionClick();
                ref.read(weightIncrementsProvider.notifier).setIncrement(equipment, newValue);
              },
            ),
          ),
          // Tick labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _snapPoints.map((v) {
                final isSelected = v == currentValue;
                return Text(
                  _fmt(v),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? accent : tickColor.withValues(alpha: 0.7),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Value badge showing current increment.
  Widget _valueBadge(double value, String unit, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${_fmt(value)} $unit',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: accent),
      ),
    );
  }

  /// Custom input button (pencil icon).
  Widget _customInputButton(
    BuildContext context, WidgetRef ref, String equipment,
    double currentValue, String unit, Color accent, Color muted,
  ) {
    return GestureDetector(
      onTap: () => _showCustomInputDialog(context, ref, equipment, currentValue, unit),
      child: Icon(Icons.edit, size: 16, color: muted),
    );
  }

  /// Dialog for custom increment value.
  void _showCustomInputDialog(
    BuildContext context, WidgetRef ref, String equipment,
    double currentValue, String unit,
  ) {
    final controller = TextEditingController(text: _fmt(currentValue));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Custom Increment'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(
            suffixText: unit,
            hintText: 'e.g. 2.5',
            border: const OutlineInputBorder(),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val > 0 && val <= 50) {
                ref.read(weightIncrementsProvider.notifier).setIncrement(equipment, val);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, double value, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text('${_fmt(value)} $unit', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  static String _fmt(double v) => v == v.toInt() ? v.toInt().toString() : v.toString();
}
