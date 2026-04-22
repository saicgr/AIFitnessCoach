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
import '../../data/repositories/nutrition_repository.dart';

/// A full-screen modal bottom sheet that displays food analysis results
/// with sorting, portion adjustment, and logging capabilities.
///
/// Supports progressive item loading: the sheet can be opened with items from
/// page 1 and then be fed additional items as later pages complete backend
/// analysis. Pass a [MenuAnalysisStreamingController] to enable this mode.
class MenuAnalysisSheet extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> foodItems;
  final String analysisType; // "plate", "menu", or "buffet"
  final bool isDark;
  final void Function(List<Map<String, dynamic>>) onLogItems;

  /// Optional controller that lets the caller append items as additional
  /// pages finish processing on the backend. When non-null, the sheet shows
  /// a "Scanning page X of N" header until [MenuAnalysisStreamingController.done]
  /// is called.
  final MenuAnalysisStreamingController? streamingController;

  const MenuAnalysisSheet({
    super.key,
    required this.foodItems,
    required this.analysisType,
    required this.isDark,
    required this.onLogItems,
    this.streamingController,
  });

  @override
  ConsumerState<MenuAnalysisSheet> createState() => _MenuAnalysisSheetState();
}

/// Controller for progressively feeding items into an open [MenuAnalysisSheet]
/// as backend page-scans complete. The caller constructs one of these, passes
/// it to the sheet, then calls [appendItems] / [markPageError] / [markDone]
/// as SSE events arrive. The sheet listens and updates itself.
class MenuAnalysisStreamingController extends ChangeNotifier {
  int _currentPage;
  int _totalPages;
  bool _done = false;
  final List<int> _failedPages = [];
  final List<Map<String, dynamic>> _pendingItems = [];

  MenuAnalysisStreamingController({required int totalPages, int currentPage = 1})
      : _totalPages = totalPages,
        _currentPage = currentPage;

  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get isDone => _done;
  List<int> get failedPages => List.unmodifiable(_failedPages);

  /// Items appended since the last consumer read. Consumer drains by reading
  /// this and clearing it during setState.
  List<Map<String, dynamic>> consumePending() {
    final copy = List<Map<String, dynamic>>.from(_pendingItems);
    _pendingItems.clear();
    return copy;
  }

  void appendItems(List<Map<String, dynamic>> items, {int? page, int? totalPages}) {
    _pendingItems.addAll(items);
    if (page != null) _currentPage = page;
    if (totalPages != null) _totalPages = totalPages;
    notifyListeners();
  }

  void markPageError(int page) {
    _failedPages.add(page);
    notifyListeners();
  }

  void markDone() {
    _done = true;
    notifyListeners();
  }
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
    // Start with nothing selected — user opts in per item. Auto-selecting all
    // on a 30+ item menu makes the budget counters read as "way over" before
    // the user has a chance to express intent.
    _selected = <int>{};
    _multipliers = {};
    widget.streamingController?.addListener(_onStreamingUpdate);
  }

  @override
  void dispose() {
    widget.streamingController?.removeListener(_onStreamingUpdate);
    super.dispose();
  }

  void _onStreamingUpdate() {
    final controller = widget.streamingController;
    if (controller == null) return;
    final newItems = controller.consumePending();
    if (newItems.isEmpty && mounted) {
      // Only progress / done state changed — still need a rebuild so the
      // "Scanning page X of N" chip updates.
      setState(() {});
      return;
    }
    if (!mounted) return;
    setState(() {
      _items.addAll(_normalizeItems(newItems));
    });
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

  void _toggleSelectAll() {
    setState(() {
      if (_selected.length == _items.length) {
        _selected.clear();
      } else {
        _selected
          ..clear()
          ..addAll(List.generate(_items.length, (i) => i));
      }
    });
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
                    if (!_logged && _items.isNotEmpty)
                      TextButton(
                        onPressed: _toggleSelectAll,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.orange,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          _selected.length == _items.length ? 'Clear all' : 'Select all',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    IconButton(
                      icon: Icon(Icons.close, color: colors.textMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Per-page streaming progress (only while backend is still
              // processing later pages).
              if (widget.streamingController != null && !widget.streamingController!.isDone)
                _buildScanProgressChip(colors, isDark),

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

  Widget _buildScanProgressChip(ThemeColors colors, bool isDark) {
    final c = widget.streamingController!;
    final failedNote = c.failedPages.isEmpty
        ? ''
        : ' · page${c.failedPages.length == 1 ? '' : 's'} ${c.failedPages.join(', ')} failed';
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(AppColors.orange),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Scanning page ${c.currentPage} of ${c.totalPages}...$failedNote',
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetHeader(ThemeColors colors, bool isDark, int targetCal, int targetP, int targetC, int targetF) {
    // Subtract today's already-logged meals first, then the items the user has
    // selected in this sheet. Allow negative — rendering an honest "over by X"
    // is more useful than clamping to 0 which hides reality.
    final summary = ref.watch(nutritionProvider).todaySummary;
    final loggedCal = summary?.totalCalories ?? 0;
    final loggedP = (summary?.totalProteinG ?? 0).round();
    final loggedC = (summary?.totalCarbsG ?? 0).round();
    final loggedF = (summary?.totalFatG ?? 0).round();

    final remainCal = targetCal - loggedCal - _selectedCalTotal;
    final remainP = targetP - loggedP - _selectedProteinTotal;
    final remainC = targetC - loggedC - _selectedCarbsTotal;
    final remainF = targetF - loggedF - _selectedFatTotal;

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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BudgetChip(label: 'Cal', value: remainCal, color: AppColors.coral),
              _BudgetChip(label: 'Protein', value: remainP, color: AppColors.macroProtein),
              _BudgetChip(label: 'Carbs', value: remainC, color: AppColors.macroCarbs),
              _BudgetChip(label: 'Fat', value: remainF, color: AppColors.macroFat),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Daily budget after today\'s logged meals + selected items',
            style: TextStyle(fontSize: 10, color: colors.textMuted),
          ),
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

          // Per-dish inflammation score chip — small, non-intrusive; only
          // rendered when Gemini supplied a score (0-10). Colors match the
          // food-history edit sheet for consistency.
          if ((item['inflammation_score'] as num?) != null)
            _MenuInflammationChip(score: (item['inflammation_score'] as num).toInt())
          else
            const SizedBox.shrink(),

          // Per-dish AI coach tip — one crisp sentence from Gemini. Rendered
          // only when present to avoid an empty pill on sparse responses.
          if ((item['coach_tip'] as String?)?.trim().isNotEmpty ?? false)
            _MenuCoachTipRow(
              tip: (item['coach_tip'] as String).trim(),
              isDark: isDark,
              textPrimary: colors.textPrimary,
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
  final int value; // positive = under budget; negative = over
  final Color color;

  const _BudgetChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final isOver = value < 0;
    // Over-budget uses a single red so it's unmistakable across macros.
    const overColor = Color(0xFFEF4444);
    final displayColor = isOver ? overColor : color;
    final magnitude = value.abs();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$magnitude',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: displayColor),
        ),
        Text(
          isOver ? '$label over' : '$label left',
          style: TextStyle(fontSize: 10, color: displayColor.withValues(alpha: 0.8)),
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

/// Compact inflammation score chip for each dish row. Matches the color ramp
/// used in food_history_screen_part_frequent_food_chip.dart:_InflammationRow
/// so users see the same tone everywhere (green 0-3, amber 4-6, red 7-10).
class _MenuInflammationChip extends StatelessWidget {
  final int score;
  const _MenuInflammationChip({required this.score});

  @override
  Widget build(BuildContext context) {
    final tone = score <= 3
        ? const Color(0xFF10B981)
        : score <= 6
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);
    final label = score <= 3
        ? 'Anti-inflammatory'
        : score <= 6
            ? 'Mildly inflammatory'
            : 'Highly inflammatory';
    return Padding(
      padding: const EdgeInsets.only(left: 30, top: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: tone.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: tone.withValues(alpha: 0.35), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$score',
              style: TextStyle(color: tone, fontSize: 10, fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: tone, fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

/// Per-dish AI coach tip row — one short sentence rendered below macros.
/// Uses the AI-coach purple consistent with the log preview.
class _MenuCoachTipRow extends StatelessWidget {
  final String tip;
  final bool isDark;
  final Color textPrimary;

  const _MenuCoachTipRow({
    required this.tip,
    required this.isDark,
    required this.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFA855F7); // purple-500 — matches AI coach visuals
    return Padding(
      padding: const EdgeInsets.only(left: 30, top: 6, right: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 12, color: accent),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                fontSize: 11,
                height: 1.35,
                color: textPrimary.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
