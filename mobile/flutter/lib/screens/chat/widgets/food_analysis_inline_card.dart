/// Inline food analysis card for plate scans (1-5 items).
/// Displayed directly in chat when user photographs a plate.
library;

import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';

/// Inline card shown inside a chat bubble for food analysis results.
/// Each item has a checkbox, macro chips, and portion multiplier buttons.
class FoodAnalysisInlineCard extends StatefulWidget {
  final List<Map<String, dynamic>> foodItems;
  final void Function(List<Map<String, dynamic>> items) onLogItems;

  const FoodAnalysisInlineCard({
    super.key,
    required this.foodItems,
    required this.onLogItems,
  });

  @override
  State<FoodAnalysisInlineCard> createState() => _FoodAnalysisInlineCardState();
}

class _FoodAnalysisInlineCardState extends State<FoodAnalysisInlineCard> {
  late final Set<int> _selected;
  late final Map<int, double> _multipliers;
  bool _logged = false;

  static const _presets = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
  static const _presetLabels = ['1/2', '3/4', '1x', '1 1/4', '1 1/2', '2x'];

  @override
  void initState() {
    super.initState();
    _selected = Set<int>.from(List.generate(widget.foodItems.length, (i) => i));
    _multipliers = {};
  }

  double _mult(int i) => _multipliers[i] ?? 1.0;

  int _adjustedVal(int i, String key) {
    final item = widget.foodItems[i];
    final raw = (item[key] as num? ?? item['${key}_g'] as num? ?? 0).toDouble();
    return max(0, (raw * _mult(i)).round());
  }

  int _adjustedCal(int i) {
    final item = widget.foodItems[i];
    final raw = (item['calories'] as num? ?? 0).toDouble();
    return max(0, (raw * _mult(i)).round());
  }

  int get _selectedCalTotal {
    int total = 0;
    for (final i in _selected) {
      total += _adjustedCal(i);
    }
    return total;
  }

  void _handleLog() {
    if (_logged || _selected.isEmpty) return;
    final items = _selected.map((i) {
      final item = widget.foodItems[i];
      final m = _mult(i);
      return <String, dynamic>{
        'name': item['name'] ?? 'Unknown',
        'calories': _adjustedCal(i),
        'protein_g': _adjustedVal(i, 'protein'),
        'carbs_g': _adjustedVal(i, 'carbs'),
        'fat_g': _adjustedVal(i, 'fat'),
        if (item['weight_g'] != null) 'weight_g': ((item['weight_g'] as num) * m).round(),
        if (m != 1.0) 'portion_multiplier': m,
      };
    }).toList();
    widget.onLogItems(items);
    setState(() => _logged = true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final isDark = colors.isDark;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.glassSurface : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.cardBorder : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.fastfood_rounded, size: 16, color: AppColors.green),
                ),
                const SizedBox(width: 10),
                Text(
                  'Food Analysis',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // Food items
          ...List.generate(widget.foodItems.length, (i) => _buildItem(i, colors, isDark)),

          // Bottom summary + log button
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            child: Column(
              children: [
                // Summary row
                Row(
                  children: [
                    Text(
                      'Selected: ${_selected.length} item${_selected.length == 1 ? '' : 's'}',
                      style: TextStyle(fontSize: 12, color: colors.textSecondary),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '\u00b7',
                      style: TextStyle(fontSize: 12, color: colors.textMuted),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$_selectedCalTotal cal',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.coral,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Log button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _logged || _selected.isEmpty ? null : _handleLog,
                    icon: Icon(
                      _logged ? Icons.check_circle : Icons.add_circle_outline,
                      size: 16,
                    ),
                    label: Text(
                      _logged
                          ? 'Logged'
                          : 'Log This Meal',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _logged
                          ? AppColors.green.withValues(alpha: 0.15)
                          : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade200),
                      disabledForegroundColor: _logged
                          ? AppColors.green
                          : colors.textMuted,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(int i, ThemeColors colors, bool isDark) {
    final item = widget.foodItems[i];
    final name = item['name'] as String? ?? 'Unknown';
    final amount = item['amount'] as String? ?? item['serving_size'] as String? ?? '';
    final isSelected = _selected.contains(i);
    final m = _mult(i);

    final cal = _adjustedCal(i);
    final protein = _adjustedVal(i, 'protein');
    final carbs = _adjustedVal(i, 'carbs');
    final fat = _adjustedVal(i, 'fat');

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 14, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main row: checkbox + name/amount + cal
          Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Checkbox(
                  value: isSelected,
                  onChanged: _logged
                      ? null
                      : (val) => setState(() {
                            if (val == true) {
                              _selected.add(i);
                            } else {
                              _selected.remove(i);
                            }
                          }),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  activeColor: AppColors.orange,
                  side: BorderSide(color: colors.textMuted, width: 1.5),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: colors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (amount.isNotEmpty)
                      Text(
                        amount,
                        style: TextStyle(fontSize: 11, color: colors.textMuted),
                      ),
                  ],
                ),
              ),
              Text(
                '$cal cal',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: m != 1.0 ? AppColors.orange : AppColors.coral,
                ),
              ),
            ],
          ),

          // Macro chips row
          Padding(
            padding: const EdgeInsets.only(left: 28, top: 4),
            child: Row(
              children: [
                _MacroChip(label: '${protein}g P', color: AppColors.macroProtein),
                const SizedBox(width: 6),
                _MacroChip(label: '${carbs}g C', color: AppColors.macroCarbs),
                const SizedBox(width: 6),
                _MacroChip(label: '${fat}g F', color: AppColors.macroFat),
              ],
            ),
          ),

          // Portion multiplier row
          if (!_logged)
            Padding(
              padding: const EdgeInsets.only(left: 28, top: 4),
              child: Row(
                children: List.generate(_presets.length, (pi) {
                  final isActive = m == _presets[pi];
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _multipliers[i] = _presets[pi];
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.orange.withValues(alpha: 0.15)
                              : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(6),
                          border: isActive
                              ? Border.all(color: AppColors.orange.withValues(alpha: 0.4))
                              : null,
                        ),
                        child: Text(
                          _presetLabels[pi],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                            color: isActive ? AppColors.orange : colors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MacroChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
