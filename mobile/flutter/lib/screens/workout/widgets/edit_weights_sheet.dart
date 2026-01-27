import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/equipment_item.dart';

/// Sheet for editing available weights for a specific equipment with quantity tracking
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
  late Map<double, int> _weightInventory;
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
    _weightUnit = widget.equipment.weightUnit;

    // Initialize inventory from equipment
    if (widget.equipment.weightInventory.isNotEmpty) {
      _weightInventory = Map.from(widget.equipment.weightInventory);
    } else if (widget.equipment.weights.isNotEmpty) {
      // Migrate from legacy weights - assume pairs (quantity 2)
      _weightInventory = {
        for (final w in widget.equipment.weights) w: 2,
      };
    } else {
      _weightInventory = {};
    }
  }

  @override
  void dispose() {
    _customWeightController.dispose();
    super.dispose();
  }

  List<double> get _commonWeights =>
      _weightUnit == 'kg' ? commonWeightsKg : commonWeightsLbs;

  /// Cycle quantity: 0 → 1 → 2 → 3 → 4 → 0
  void _cycleQuantity(double weight) {
    setState(() {
      final currentQty = _weightInventory[weight] ?? 0;
      if (currentQty == 0) {
        _weightInventory[weight] = 1;
      } else if (currentQty < 4) {
        _weightInventory[weight] = currentQty + 1;
      } else {
        _weightInventory.remove(weight);
      }
    });
  }

  /// Show dialog to directly set quantity
  Future<void> _setQuantity(double weight) async {
    final currentQty = _weightInventory[weight] ?? 0;
    final controller = TextEditingController(text: currentQty > 0 ? currentQty.toString() : '');

    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

        return AlertDialog(
          backgroundColor: isDark ? AppColors.elevated : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Set Quantity',
            style: TextStyle(color: textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_formatWeight(weight)} $_weightUnit',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  labelStyle: TextStyle(color: textPrimary.withValues(alpha: 0.7)),
                  hintText: 'Enter 0 to remove',
                  hintStyle: TextStyle(color: textPrimary.withValues(alpha: 0.5)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: textPrimary.withValues(alpha: 0.7)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final qty = int.tryParse(controller.text) ?? 0;
                Navigator.pop(context, qty);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.cyan : AppColorsLight.cyan,
                foregroundColor: isDark ? Colors.black : Colors.white,
              ),
              child: const Text('Set'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        if (result == 0) {
          _weightInventory.remove(weight);
        } else {
          _weightInventory[weight] = result;
        }
      });
    }
  }

  void _addCustomWeight() {
    final value = double.tryParse(_customWeightController.text.trim());
    if (value != null && value > 0) {
      setState(() {
        // Add or increment
        _weightInventory[value] = (_weightInventory[value] ?? 0) + 1;
      });
      _customWeightController.clear();
    }
  }

  void _removeWeight(double weight) {
    setState(() {
      _weightInventory.remove(weight);
    });
  }

  void _selectAll() {
    setState(() {
      for (final w in _commonWeights) {
        // Add with quantity 2 (pair) if not already present
        _weightInventory[w] = _weightInventory[w] ?? 2;
      }
    });
  }

  void _clearAll() {
    setState(() {
      _weightInventory.clear();
    });
  }

  String _formatWeight(double w) {
    return w == w.roundToDouble() ? w.toInt().toString() : w.toString();
  }

  int get _totalWeights => _weightInventory.values.fold(0, (sum, qty) => sum + qty);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final bgColor = isDark ? AppColors.elevated : AppColorsLight.surface;
    final accentColor = isDark ? AppColors.cyan : AppColorsLight.cyan;

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
                          color: textPrimary,
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

          // Quantity instructions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: accentColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tap to cycle quantity (0→1→2→3→4). Long press for custom amount.',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Selected weights display
          if (_weightInventory.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Selected: $_totalWeights items',
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
              height: 48,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _weightInventory.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final weight = _weightInventory.keys.toList()..sort();
                  final w = weight[index];
                  final qty = _weightInventory[w]!;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: accentColor,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$qty',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.black : Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_formatWeight(w)} $_weightUnit',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: accentColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _removeWeight(w),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],

          const Divider(height: 1),

          // Quick add section header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Text(
                  'Tap to cycle • Long press to set',
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
                    'Select All Pairs',
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
                  final qty = _weightInventory[weight] ?? 0;
                  final isSelected = qty > 0;

                  return GestureDetector(
                    onTap: () => _cycleQuantity(weight),
                    onLongPress: () => _setQuantity(weight),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? accentColor.withValues(alpha: 0.2)
                            : bgColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? accentColor : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1)),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: accentColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$qty',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.black : Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            '${_formatWeight(weight)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected
                                  ? accentColor
                                  : textSecondary,
                            ),
                          ),
                        ],
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
                    style: TextStyle(color: textPrimary),
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
                    foregroundColor: isDark ? Colors.black : Colors.white,
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
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _weightInventory.isEmpty
                      ? 'Save (No Weights)'
                      : 'Save $_totalWeights Weights',
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
    final accentColor = isDark ? AppColors.cyan : AppColorsLight.cyan;

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
                ? (isDark ? Colors.black : Colors.white)
                : (isDark ? Colors.white70 : AppColorsLight.textSecondary),
          ),
        ),
      ),
    );
  }

  void _save() {
    final updated = widget.equipment.copyWith(
      weightInventory: _weightInventory,
      weightUnit: _weightUnit,
    );
    widget.onSave(updated);
    Navigator.pop(context);
  }
}
