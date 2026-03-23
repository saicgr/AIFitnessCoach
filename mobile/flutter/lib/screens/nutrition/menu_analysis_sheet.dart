/// Full-screen modal bottom sheet for analyzing menus, buffets, and large
/// plate scans (6+ items). Supports sorting, filtering, portion adjustment,
/// and batch logging.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/providers/nutrition_preferences_provider.dart';

/// A full-screen modal bottom sheet that displays food analysis results
/// with sorting, portion adjustment, and logging capabilities.
class MenuAnalysisSheet extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> foodItems;
  final String analysisType; // "plate", "menu", or "buffet"
  final bool isDark;
  final void Function(List<Map<String, dynamic>>) onLogItems;

  const MenuAnalysisSheet({
    super.key,
    required this.foodItems,
    required this.analysisType,
    required this.isDark,
    required this.onLogItems,
  });

  @override
  ConsumerState<MenuAnalysisSheet> createState() => _MenuAnalysisSheetState();
}

enum _SortField { calories, protein, carbs, fat }

class _MenuAnalysisSheetState extends ConsumerState<MenuAnalysisSheet> {
  late List<Map<String, dynamic>> _items;
  late Set<int> _selected;
  late Map<int, double> _multipliers;
  bool _logged = false;
  _SortField? _sortField;
  bool _sortAsc = true;

  static const _presets = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
  static const _presetLabels = ['1/2', '3/4', '1x', '1 1/4', '1 1/2', '2x'];

  @override
  void initState() {
    super.initState();
    _items = _normalizeItems(widget.foodItems);
    _selected = Set<int>.from(List.generate(_items.length, (i) => i));
    _multipliers = {};
  }

  /// Normalize field names and defaults.
  List<Map<String, dynamic>> _normalizeItems(List<Map<String, dynamic>> raw) {
    return raw.map((item) {
      final normalized = Map<String, dynamic>.from(item);
      // Normalize macro names
      normalized['protein'] = (item['protein_g'] as num? ?? item['protein'] as num? ?? 0).toInt();
      normalized['carbs'] = (item['carbs_g'] as num? ?? item['carbs'] as num? ?? 0).toInt();
      normalized['fat'] = (item['fat_g'] as num? ?? item['fat'] as num? ?? 0).toInt();
      normalized['calories'] = (item['calories'] as num? ?? 0).toInt();
      normalized['weight_g'] ??= 100;
      return normalized;
    }).toList();
  }

  double _mult(int i) => _multipliers[i] ?? 1.0;

  int _adj(int i, String key) {
    final raw = (_items[i][key] as num? ?? 0).toDouble();
    return max(0, (raw * _mult(i)).round());
  }

  int get _selectedCalTotal {
    int t = 0;
    for (final i in _selected) {
      t += _adj(i, 'calories');
    }
    return t;
  }

  int get _selectedProteinTotal {
    int t = 0;
    for (final i in _selected) {
      t += _adj(i, 'protein');
    }
    return t;
  }

  int get _selectedCarbsTotal {
    int t = 0;
    for (final i in _selected) {
      t += _adj(i, 'carbs');
    }
    return t;
  }

  int get _selectedFatTotal {
    int t = 0;
    for (final i in _selected) {
      t += _adj(i, 'fat');
    }
    return t;
  }

  List<int> get _sortedIndices {
    final indices = List.generate(_items.length, (i) => i);
    if (_sortField == null) return indices;
    indices.sort((a, b) {
      final key = switch (_sortField!) {
        _SortField.calories => 'calories',
        _SortField.protein => 'protein',
        _SortField.carbs => 'carbs',
        _SortField.fat => 'fat',
      };
      final va = _adj(a, key);
      final vb = _adj(b, key);
      return _sortAsc ? va.compareTo(vb) : vb.compareTo(va);
    });
    return indices;
  }

  void _handleLog() {
    if (_logged || _selected.isEmpty) return;
    final items = _selected.map((i) {
      final item = _items[i];
      final m = _mult(i);
      return <String, dynamic>{
        'name': item['name'] ?? 'Unknown',
        'calories': _adj(i, 'calories'),
        'protein_g': _adj(i, 'protein'),
        'carbs_g': _adj(i, 'carbs'),
        'fat_g': _adj(i, 'fat'),
        if (m != 1.0) 'portion_multiplier': m,
      };
    }).toList();
    widget.onLogItems(items);
    setState(() => _logged = true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final isDark = widget.isDark;
    final prefs = ref.watch(nutritionPreferencesProvider);

    final targetCal = prefs.currentCalorieTarget;
    final targetP = prefs.currentProteinTarget;
    final targetC = prefs.currentCarbsTarget;
    final targetF = prefs.currentFatTarget;

    final title = switch (widget.analysisType) {
      'menu' => 'Menu Analysis',
      'buffet' => 'Buffet Analysis',
      _ => 'Food Analysis',
    };

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.nearBlack : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.textMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: colors.textMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Daily budget header
              _buildBudgetHeader(colors, isDark, targetCal, targetP, targetC, targetF),

              // Sort chips row
              _buildSortChips(colors, isDark),

              // Item list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemCount: _sortedIndices.length,
                  itemBuilder: (context, index) {
                    final i = _sortedIndices[index];
                    return _buildItemTile(i, colors, isDark);
                  },
                ),
              ),

              // Sticky bottom bar
              _buildBottomBar(colors, isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBudgetHeader(ThemeColors colors, bool isDark, int targetCal, int targetP, int targetC, int targetF) {
    final remainCal = max(0, targetCal - _selectedCalTotal);
    final remainP = max(0, targetP - _selectedProteinTotal);
    final remainC = max(0, targetC - _selectedCarbsTotal);
    final remainF = max(0, targetF - _selectedFatTotal);

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevated : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.cardBorder : Colors.grey.shade200,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BudgetChip(label: 'Cal', value: remainCal, color: AppColors.coral),
          _BudgetChip(label: 'P', value: remainP, color: AppColors.macroProtein),
          _BudgetChip(label: 'C', value: remainC, color: AppColors.macroCarbs),
          _BudgetChip(label: 'F', value: remainF, color: AppColors.macroFat),
        ],
      ),
    );
  }

  Widget _buildSortChips(ThemeColors colors, bool isDark) {
    Widget chip(String label, _SortField field) {
      final isActive = _sortField == field;
      return GestureDetector(
        onTap: () => setState(() {
          if (_sortField == field) {
            _sortAsc = !_sortAsc;
          } else {
            _sortField = field;
            _sortAsc = false; // default desc (highest first)
          }
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.orange.withValues(alpha: 0.15)
                : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(8),
            border: isActive ? Border.all(color: AppColors.orange.withValues(alpha: 0.4)) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? AppColors.orange : colors.textSecondary,
                ),
              ),
              if (isActive) ...[
                const SizedBox(width: 2),
                Icon(
                  _sortAsc ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 12,
                  color: AppColors.orange,
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: Row(
        children: [
          Text('Sort:', style: TextStyle(fontSize: 12, color: colors.textMuted)),
          const SizedBox(width: 8),
          chip('Calories', _SortField.calories),
          const SizedBox(width: 6),
          chip('Protein', _SortField.protein),
          const SizedBox(width: 6),
          chip('Carbs', _SortField.carbs),
          const SizedBox(width: 6),
          chip('Fat', _SortField.fat),
        ],
      ),
    );
  }

  Widget _buildItemTile(int i, ThemeColors colors, bool isDark) {
    final item = _items[i];
    final name = item['name'] as String? ?? 'Unknown';
    final amount = item['amount'] as String? ?? item['serving_size'] as String? ?? '';
    final isSelected = _selected.contains(i);
    final m = _mult(i);
    final rating = item['rating'] as String?;

    final cal = _adj(i, 'calories');
    final protein = _adj(i, 'protein');
    final carbs = _adj(i, 'carbs');
    final fat = _adj(i, 'fat');

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade50)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isSelected
            ? Border.all(color: isDark ? AppColors.cardBorder : Colors.grey.shade200)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name row + checkbox
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
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colors.textPrimary,
                      ),
                    ),
                    if (amount.isNotEmpty)
                      Text(
                        amount,
                        style: TextStyle(fontSize: 11, color: colors.textMuted),
                      ),
                  ],
                ),
              ),
              if (rating != null) _buildRatingBadge(rating, isDark),
            ],
          ),

          // Macros row
          Padding(
            padding: const EdgeInsets.only(left: 30, top: 6),
            child: Row(
              children: [
                _MacroLabel(label: '$cal', unit: 'cal', color: AppColors.coral),
                const SizedBox(width: 10),
                _MacroLabel(label: '$protein', unit: 'g P', color: AppColors.macroProtein),
                const SizedBox(width: 10),
                _MacroLabel(label: '$carbs', unit: 'g C', color: AppColors.macroCarbs),
                const SizedBox(width: 10),
                _MacroLabel(label: '$fat', unit: 'g F', color: AppColors.macroFat),
              ],
            ),
          ),

          // Portion multiplier buttons
          if (!_logged && isSelected)
            Padding(
              padding: const EdgeInsets.only(left: 30, top: 6),
              child: Row(
                children: List.generate(_presets.length, (pi) {
                  final isActive = m == _presets[pi];
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: GestureDetector(
                      onTap: () => setState(() => _multipliers[i] = _presets[pi]),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                            fontSize: 11,
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

  Widget _buildRatingBadge(String rating, bool isDark) {
    final Color color;
    final String label;
    switch (rating.toLowerCase()) {
      case 'green':
        color = const Color(0xFF4CAF50);
        label = 'Good';
      case 'red':
        color = const Color(0xFFE91E63);
        label = 'Limit';
      default:
        color = const Color(0xFFFF9800);
        label = 'Moderate';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _buildBottomBar(ThemeColors colors, bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).padding.bottom + 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevated : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.cardBorder : Colors.grey.shade200,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Summary
          Row(
            children: [
              Text(
                '${_selected.length} selected',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.textSecondary),
              ),
              const SizedBox(width: 8),
              Text('\u00b7', style: TextStyle(color: colors.textMuted)),
              const SizedBox(width: 8),
              Text(
                '$_selectedCalTotal cal',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.coral),
              ),
              const SizedBox(width: 8),
              Text(
                '${_selectedProteinTotal}g P',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.macroProtein),
              ),
              const SizedBox(width: 8),
              Text(
                '${_selectedCarbsTotal}g C',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.macroCarbs),
              ),
              const SizedBox(width: 8),
              Text(
                '${_selectedFatTotal}g F',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.macroFat),
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
                size: 18,
              ),
              label: Text(
                _logged
                    ? 'Logged'
                    : 'Log ${_selected.length} Item${_selected.length == 1 ? '' : 's'}',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _logged
                    ? AppColors.green.withValues(alpha: 0.15)
                    : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade200),
                disabledForegroundColor: _logged ? AppColors.green : colors.textMuted,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _BudgetChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$value',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          '$label left',
          style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.7)),
        ),
      ],
    );
  }
}

class _MacroLabel extends StatelessWidget {
  final String label;
  final String unit;
  final Color color;

  const _MacroLabel({required this.label, required this.unit, required this.color});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
          TextSpan(
            text: ' $unit',
            style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}
