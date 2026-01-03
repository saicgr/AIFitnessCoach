import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Available units for portion measurement
enum PortionUnit {
  grams('g', 'Grams'),
  milliliters('ml', 'Milliliters'),
  ounces('oz', 'Ounces'),
  cups('cup', 'Cups'),
  tablespoons('tbsp', 'Tablespoons'),
  teaspoons('tsp', 'Teaspoons'),
  servings('srv', 'Servings');

  final String abbreviation;
  final String displayName;
  const PortionUnit(this.abbreviation, this.displayName);
}

/// Quick preset portion multipliers
class PortionPreset {
  final String label;
  final double multiplier;
  final String description;

  const PortionPreset({
    required this.label,
    required this.multiplier,
    required this.description,
  });

  static const List<PortionPreset> defaults = [
    PortionPreset(label: '½', multiplier: 0.5, description: 'Half'),
    PortionPreset(label: '¾', multiplier: 0.75, description: 'Three quarters'),
    PortionPreset(label: '1x', multiplier: 1.0, description: 'Standard'),
    PortionPreset(label: '1¼', multiplier: 1.25, description: 'One and a quarter'),
    PortionPreset(label: '1½', multiplier: 1.5, description: 'One and a half'),
    PortionPreset(label: '2x', multiplier: 2.0, description: 'Double'),
  ];
}

/// Custom portion input with both presets and manual entry
class PortionAmountInput extends StatefulWidget {
  final double initialMultiplier;
  final int baseCalories;
  final double baseProtein;
  final double baseCarbs;
  final double baseFat;
  final bool isDark;
  final void Function(double multiplier) onMultiplierChanged;

  const PortionAmountInput({
    super.key,
    this.initialMultiplier = 1.0,
    required this.baseCalories,
    required this.baseProtein,
    required this.baseCarbs,
    required this.baseFat,
    required this.isDark,
    required this.onMultiplierChanged,
  });

  @override
  State<PortionAmountInput> createState() => _PortionAmountInputState();
}

class _PortionAmountInputState extends State<PortionAmountInput> {
  late double _currentMultiplier;
  late TextEditingController _customController;
  bool _showCustomInput = false;

  @override
  void initState() {
    super.initState();
    _currentMultiplier = widget.initialMultiplier;
    _customController = TextEditingController(text: '100');
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _selectPreset(double multiplier) {
    setState(() {
      _currentMultiplier = multiplier;
      _showCustomInput = false;
    });
    widget.onMultiplierChanged(multiplier);
  }

  void _onCustomChanged(String value) {
    final parsed = double.tryParse(value);
    if (parsed != null && parsed > 0) {
      final multiplier = parsed / 100; // Convert percentage to multiplier
      setState(() => _currentMultiplier = multiplier);
      widget.onMultiplierChanged(multiplier);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = widget.isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = widget.isDark ? AppColors.elevated : AppColorsLight.elevated;
    final teal = widget.isDark ? AppColors.teal : AppColorsLight.teal;
    final glassSurface = widget.isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    // Calculate current values based on multiplier
    final currentCalories = (widget.baseCalories * _currentMultiplier).round();
    final currentProtein = (widget.baseProtein * _currentMultiplier).round();
    final currentCarbs = (widget.baseCarbs * _currentMultiplier).round();
    final currentFat = (widget.baseFat * _currentMultiplier).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.tune, color: teal, size: 20),
              const SizedBox(width: 8),
              Text(
                'Adjust Portion',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const Spacer(),
              // Current multiplier badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: teal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(_currentMultiplier * 100).round()}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: teal,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Quick preset buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PortionPreset.defaults.map((preset) {
              final isSelected = (_currentMultiplier - preset.multiplier).abs() < 0.01;
              return _PresetChip(
                label: preset.label,
                isSelected: isSelected,
                isDark: widget.isDark,
                onTap: () => _selectPreset(preset.multiplier),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          // Custom input toggle
          GestureDetector(
            onTap: () => setState(() => _showCustomInput = !_showCustomInput),
            child: Row(
              children: [
                Icon(
                  _showCustomInput ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 20,
                  color: textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  'Custom amount',
                  style: TextStyle(fontSize: 13, color: textMuted),
                ),
              ],
            ),
          ),

          // Custom input field
          if (_showCustomInput) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _customController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: textPrimary, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: '100',
                      hintStyle: TextStyle(color: textMuted),
                      suffixText: '%',
                      suffixStyle: TextStyle(color: textMuted),
                      filled: true,
                      fillColor: glassSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: _onCustomChanged,
                  ),
                ),
                const SizedBox(width: 12),
                // Quick adjustment buttons
                _AdjustButton(
                  icon: Icons.remove,
                  isDark: widget.isDark,
                  onTap: () {
                    final newMultiplier = (_currentMultiplier - 0.1).clamp(0.1, 5.0);
                    _customController.text = (newMultiplier * 100).round().toString();
                    _selectPreset(newMultiplier);
                  },
                ),
                const SizedBox(width: 8),
                _AdjustButton(
                  icon: Icons.add,
                  isDark: widget.isDark,
                  onTap: () {
                    final newMultiplier = (_currentMultiplier + 0.1).clamp(0.1, 5.0);
                    _customController.text = (newMultiplier * 100).round().toString();
                    _selectPreset(newMultiplier);
                  },
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),

          // Nutrition preview
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: glassSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NutrientPreview(label: 'Cal', value: currentCalories, isDark: widget.isDark),
                _NutrientPreview(label: 'P', value: currentProtein, unit: 'g', isDark: widget.isDark),
                _NutrientPreview(label: 'C', value: currentCarbs, unit: 'g', isDark: widget.isDark),
                _NutrientPreview(label: 'F', value: currentFat, unit: 'g', isDark: widget.isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _PresetChip({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? teal : glassSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? teal : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _AdjustButton extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _AdjustButton({
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

    return Material(
      color: teal.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: teal),
        ),
      ),
    );
  }
}

class _NutrientPreview extends StatelessWidget {
  final String label;
  final int value;
  final String? unit;
  final bool isDark;

  const _NutrientPreview({
    required this.label,
    required this.value,
    this.unit,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Column(
      children: [
        Text(
          '$value${unit ?? ''}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: textMuted,
          ),
        ),
      ],
    );
  }
}
