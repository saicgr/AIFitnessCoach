import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/equipment_item.dart';

/// Sheet for editing available weights for a specific equipment
class EditWeightsSheet extends StatefulWidget {
  final EquipmentItem equipment;
  final void Function(EquipmentItem updated) onSave;

  const EditWeightsSheet({
    super.key,
    required this.equipment,
    required this.onSave,
  });

  @override
  State<EditWeightsSheet> createState() => _EditWeightsSheetState();
}

class _EditWeightsSheetState extends State<EditWeightsSheet> {
  late List<double> _selectedWeights;
  late String _weightUnit;
  final TextEditingController _customWeightController = TextEditingController();

  // Common weight increments for quick-add
  static const List<double> commonWeightsLbs = [
    5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80, 85, 90, 95, 100
  ];
  static const List<double> commonWeightsKg = [
    2.5, 5, 7.5, 10, 12.5, 15, 17.5, 20, 22.5, 25, 27.5, 30, 32.5, 35, 37.5, 40, 42.5, 45
  ];

  @override
  void initState() {
    super.initState();
    _selectedWeights = List.from(widget.equipment.weights);
    _weightUnit = widget.equipment.weightUnit;
  }

  @override
  void dispose() {
    _customWeightController.dispose();
    super.dispose();
  }

  List<double> get _commonWeights =>
      _weightUnit == 'kg' ? commonWeightsKg : commonWeightsLbs;

  void _toggleWeight(double weight) {
    setState(() {
      if (_selectedWeights.contains(weight)) {
        _selectedWeights.remove(weight);
      } else {
        _selectedWeights.add(weight);
        _selectedWeights.sort();
      }
    });
  }

  void _addCustomWeight() {
    final value = double.tryParse(_customWeightController.text.trim());
    if (value != null && value > 0 && !_selectedWeights.contains(value)) {
      setState(() {
        _selectedWeights.add(value);
        _selectedWeights.sort();
      });
      _customWeightController.clear();
    }
  }

  void _removeWeight(double weight) {
    setState(() {
      _selectedWeights.remove(weight);
    });
  }

  void _selectAll() {
    setState(() {
      for (final w in _commonWeights) {
        if (!_selectedWeights.contains(w)) {
          _selectedWeights.add(w);
        }
      }
      _selectedWeights.sort();
    });
  }

  void _clearAll() {
    setState(() {
      _selectedWeights.clear();
    });
  }

  String _formatWeight(double w) {
    return w == w.roundToDouble() ? w.toInt().toString() : w.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final bgColor = isDark ? AppColors.elevated : AppColorsLight.surface;
    final accentColor = isDark ? AppColors.cyan : AppColorsLight.accent;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit Weights',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColorsLight.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.equipment.displayName,
                        style: TextStyle(
                          fontSize: 14,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                // Unit toggle
                Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildUnitButton('lbs', isDark),
                      _buildUnitButton('kg', isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Selected weights display
          if (_selectedWeights.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Selected:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: textMuted,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _clearAll,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 32),
                    ),
                    child: Text(
                      'Clear All',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[400],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 44,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedWeights.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final weight = _selectedWeights[index];
                  return Chip(
                    label: Text(
                      '${_formatWeight(weight)} $_weightUnit',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => _removeWeight(weight),
                    backgroundColor: accentColor.withOpacity(0.15),
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],

          const Divider(height: 1),

          // Quick add section header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Text(
                  'Tap to add/remove',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textMuted,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _selectAll,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                  ),
                  child: Text(
                    'Select All',
                    style: TextStyle(
                      fontSize: 12,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Common weights grid
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _commonWeights.map((weight) {
                  final isSelected = _selectedWeights.contains(weight);
                  return GestureDetector(
                    onTap: () => _toggleWeight(weight),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? accentColor.withOpacity(0.2)
                            : bgColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? accentColor : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        '${_formatWeight(weight)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected
                              ? accentColor
                              : (isDark ? Colors.white70 : AppColorsLight.textSecondary),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Custom weight input
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customWeightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: InputDecoration(
                      hintText: 'Custom weight...',
                      hintStyle: TextStyle(color: textMuted, fontSize: 14),
                      filled: true,
                      fillColor: bgColor,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      suffixText: _weightUnit,
                    ),
                    onSubmitted: (_) => _addCustomWeight(),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filled(
                  onPressed: _addCustomWeight,
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Save button
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              0,
              16,
              MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 16,
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _selectedWeights.isEmpty
                      ? 'Save (No Weights)'
                      : 'Save ${_selectedWeights.length} Weights',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitButton(String unit, bool isDark) {
    final isSelected = _weightUnit == unit;
    final accentColor = isDark ? AppColors.cyan : AppColorsLight.accent;

    return GestureDetector(
      onTap: () => setState(() => _weightUnit = unit),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          unit,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : AppColorsLight.textSecondary),
          ),
        ),
      ),
    );
  }

  void _save() {
    final updated = widget.equipment.copyWith(
      weights: _selectedWeights,
      weightUnit: _weightUnit,
    );
    widget.onSave(updated);
    Navigator.pop(context);
  }
}
