/// Food Analysis Result Card
///
/// Renders buffet/menu/multi-food analysis results in chat.
/// Shows traffic-light dish ratings, suggested plate, and budget info.
library;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';

/// Card that displays a structured food analysis result from the AI.
/// Handles buffet analysis, menu analysis, and multi-food image analysis.
class FoodAnalysisResultCard extends StatefulWidget {
  final Map<String, dynamic> data;
  /// Called when user taps "Log Selected Items" with the list of selected dishes.
  /// Each dish is a Map with name, calories, protein, carbs, fat, etc.
  final void Function(List<Map<String, dynamic>> items)? onLogItems;

  const FoodAnalysisResultCard({
    super.key,
    required this.data,
    this.onLogItems,
  });

  @override
  State<FoodAnalysisResultCard> createState() => _FoodAnalysisResultCardState();
}

class _FoodAnalysisResultCardState extends State<FoodAnalysisResultCard> {
  bool _greenExpanded = false;
  bool _yellowExpanded = false;
  bool _redExpanded = false;
  final Set<String> _selectedDishes = {};
  bool _itemsLogged = false;

  static const _collapsedItemCount = 5;

  static const Color _greenColor = Color(0xFF4CAF50);
  static const Color _yellowColor = Color(0xFFFF9800);
  static const Color _redColor = Color(0xFFE91E63);

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final isDark = colors.isDark;
    final action = widget.data['action'] as String?;
    final analysisType = widget.data['analysis_type'] as String? ?? _inferType(action);

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
          _buildHeader(colors, isDark, analysisType),

          // Dish groups
          if (analysisType == 'menu')
            _buildMenuSections(colors, isDark)
          else
            _buildDishGroups(colors, isDark),

          // Suggested plate / recommended order
          _buildSuggestedSelection(colors, isDark, analysisType),

          // Daily budget bar
          _buildDailyBudget(colors, isDark),

          // Log Selected Items button (buffet/menu only)
          if (analysisType != 'plate')
            _buildLogSelectedButton(colors, isDark),

          // Tips
          _buildTips(colors),

          // Disclaimer
          _buildDisclaimer(colors),
        ],
      ),
    );
  }

  String _inferType(String? action) {
    switch (action) {
      case 'analyze_buffet':
        return 'buffet';
      case 'analyze_menu':
        return 'menu';
      case 'analyze_multi_food_images':
        return 'plate';
      default:
        return 'plate';
    }
  }

  Widget _buildHeader(ThemeColors colors, bool isDark, String analysisType) {
    final IconData icon;
    final String title;

    switch (analysisType) {
      case 'buffet':
        icon = Icons.restaurant_rounded;
        title = 'Buffet Analysis';
        break;
      case 'menu':
        icon = Icons.menu_book_rounded;
        title = 'Menu Analysis';
        break;
      default:
        icon = Icons.fastfood_rounded;
        title = 'Food Analysis';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _greenColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: _greenColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDishGroups(ThemeColors colors, bool isDark) {
    final dishes = (widget.data['dishes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (dishes.isEmpty) return const SizedBox.shrink();

    final greenDishes = dishes.where((d) => _getRating(d) == 'green').toList();
    final yellowDishes = dishes.where((d) => _getRating(d) == 'yellow').toList();
    final redDishes = dishes.where((d) => _getRating(d) == 'red').toList();

    return Column(
      children: [
        if (greenDishes.isNotEmpty)
          _buildDishSection(
            colors, isDark,
            label: 'Great Choices',
            icon: Icons.check_circle,
            color: _greenColor,
            dishes: greenDishes,
            isExpanded: _greenExpanded,
            onToggle: () => setState(() => _greenExpanded = !_greenExpanded),
          ),
        if (yellowDishes.isNotEmpty)
          _buildDishSection(
            colors, isDark,
            label: 'In Moderation',
            icon: Icons.info_outline,
            color: _yellowColor,
            dishes: yellowDishes,
            isExpanded: _yellowExpanded,
            onToggle: () => setState(() => _yellowExpanded = !_yellowExpanded),
          ),
        if (redDishes.isNotEmpty)
          _buildDishSection(
            colors, isDark,
            label: 'Limit These',
            icon: Icons.warning_amber_rounded,
            color: _redColor,
            dishes: redDishes,
            isExpanded: _redExpanded,
            onToggle: () => setState(() => _redExpanded = !_redExpanded),
          ),
      ],
    );
  }

  Widget _buildMenuSections(ThemeColors colors, bool isDark) {
    final sections = (widget.data['sections'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (sections.isEmpty) {
      // Fall back to dishes if sections not provided
      return _buildDishGroups(colors, isDark);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sections.map((section) {
          final sectionName = section['name'] as String? ?? 'Items';
          final items = (section['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Text(
                  sectionName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
              ),
              ...items.map((item) => _buildDishTile(colors, isDark, item, showCheckbox: true)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDishSection(
    ThemeColors colors,
    bool isDark, {
    required String label,
    required IconData icon,
    required Color color,
    required List<Map<String, dynamic>> dishes,
    required bool isExpanded,
    required VoidCallback onToggle,
  }) {
    final visible = isExpanded || dishes.length <= _collapsedItemCount
        ? dishes
        : dishes.take(_collapsedItemCount).toList();
    final hasMore = dishes.length > _collapsedItemCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                '$label (${dishes.length})',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...visible.map((dish) => _buildDishTile(colors, isDark, dish, showCheckbox: true)),
          if (hasMore && !isExpanded)
            GestureDetector(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 4),
                child: Text(
                  'Show ${dishes.length - _collapsedItemCount} more...',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colors.accent,
                  ),
                ),
              ),
            ),
          if (hasMore && isExpanded)
            GestureDetector(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 4),
                child: Text(
                  'Show less',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colors.accent,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDishTile(ThemeColors colors, bool isDark, Map<String, dynamic> dish, {bool showCheckbox = false}) {
    final name = dish['name'] as String? ?? 'Unknown dish';
    final calories = dish['calories'] as num?;
    final protein = dish['protein'] as num?;
    final rating = _getRating(dish);
    final dotColor = _ratingColor(rating);
    final dishKey = '${name}_${calories ?? 0}';
    final isSelected = _selectedDishes.contains(dishKey);

    return GestureDetector(
      onTap: showCheckbox && !_itemsLogged
          ? () => setState(() {
                if (isSelected) {
                  _selectedDishes.remove(dishKey);
                } else {
                  _selectedDishes.add(dishKey);
                }
              })
          : null,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            if (showCheckbox && !_itemsLogged) ...[
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: isSelected,
                  onChanged: (val) => setState(() {
                    if (val == true) {
                      _selectedDishes.add(dishKey);
                    } else {
                      _selectedDishes.remove(dishKey);
                    }
                  }),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  activeColor: _greenColor,
                  side: BorderSide(color: colors.textMuted, width: 1.5),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (calories != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  '${calories.toInt()} cal',
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            if (protein != null)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(
                  '${protein.toInt()}g P',
                  style: TextStyle(
                    fontSize: 11,
                    color: _greenColor.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedSelection(ThemeColors colors, bool isDark, String analysisType) {
    final suggestedPlate = widget.data['suggested_plate'] as Map<String, dynamic>?;
    final recommendedOrder = widget.data['recommended_order'] as Map<String, dynamic>?;
    final selection = suggestedPlate ?? recommendedOrder;

    if (selection == null) return const SizedBox.shrink();

    final items = (selection['items'] as List?)?.cast<String>() ?? [];
    final totalCalories = selection['total_calories'] as num?;
    final totalProtein = selection['total_protein'] as num?;
    final title = analysisType == 'menu' ? 'Recommended Order' : 'Suggested Plate';

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _greenColor.withOpacity(isDark ? 0.08 : 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _greenColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star_rounded, size: 16, color: _greenColor),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _greenColor,
                ),
              ),
            ],
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  Icon(Icons.check, size: 12, color: _greenColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
          if (totalCalories != null || totalProtein != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  if (totalCalories != null)
                    Text(
                      '${totalCalories.toInt()} cal total',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                      ),
                    ),
                  if (totalCalories != null && totalProtein != null)
                    Text(
                      ' \u00b7 ',
                      style: TextStyle(fontSize: 11, color: colors.textMuted),
                    ),
                  if (totalProtein != null)
                    Text(
                      '${totalProtein.toInt()}g protein',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _greenColor,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDailyBudget(ThemeColors colors, bool isDark) {
    final budget = widget.data['daily_budget_remaining'] as Map<String, dynamic>?;
    if (budget == null) return const SizedBox.shrink();

    final remaining = (budget['calories_remaining'] as num?)?.toDouble() ?? 0;
    final total = (budget['daily_target'] as num?)?.toDouble() ?? 2000;
    final consumed = total - remaining;
    final progress = (consumed / total).clamp(0.0, 1.0);
    final mealLabel = budget['for_meal'] as String? ?? 'remaining meals';

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart_outline, size: 14, color: colors.textMuted),
              const SizedBox(width: 6),
              Text(
                'Leaves you ${remaining.toInt()} cal for $mealLabel',
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.05),
              color: progress > 0.9 ? _redColor : (progress > 0.7 ? _yellowColor : _greenColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogSelectedButton(ThemeColors colors, bool isDark) {
    if (_itemsLogged) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
        child: Row(
          children: [
            Icon(Icons.check_circle, size: 16, color: _greenColor),
            const SizedBox(width: 6),
            Text(
              'Items logged to nutrition tracker',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _greenColor,
              ),
            ),
          ],
        ),
      );
    }

    // Gather all dishes from all sources
    final allDishes = _getAllDishes();
    if (allDishes.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Select all / deselect all
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() {
                  if (_selectedDishes.length == allDishes.length) {
                    _selectedDishes.clear();
                  } else {
                    _selectedDishes.clear();
                    for (final dish in allDishes) {
                      final name = dish['name'] as String? ?? '';
                      final cal = dish['calories'] as num? ?? 0;
                      _selectedDishes.add('${name}_$cal');
                    }
                  }
                }),
                child: Text(
                  _selectedDishes.length == allDishes.length ? 'Deselect All' : 'Select All',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colors.accent,
                  ),
                ),
              ),
              const Spacer(),
              if (_selectedDishes.isNotEmpty)
                Text(
                  '${_selectedDishes.length} selected',
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.textMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Log button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _selectedDishes.isEmpty
                  ? null
                  : () {
                      final selected = allDishes.where((d) {
                        final name = d['name'] as String? ?? '';
                        final cal = d['calories'] as num? ?? 0;
                        return _selectedDishes.contains('${name}_$cal');
                      }).toList();
                      widget.onLogItems?.call(selected);
                      setState(() => _itemsLogged = true);
                    },
              icon: const Icon(Icons.add_circle_outline, size: 16),
              label: Text(
                _selectedDishes.isEmpty
                    ? 'Select items to log'
                    : 'Log ${_selectedDishes.length} Item${_selectedDishes.length == 1 ? '' : 's'}',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _greenColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.grey.shade200,
                disabledForegroundColor: colors.textMuted,
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
    );
  }

  /// Collect all dishes from buffet `dishes` or menu `sections`.
  List<Map<String, dynamic>> _getAllDishes() {
    final dishes = (widget.data['dishes'] as List?)?.cast<Map<String, dynamic>>();
    if (dishes != null && dishes.isNotEmpty) return dishes;

    final sections = (widget.data['sections'] as List?)?.cast<Map<String, dynamic>>();
    if (sections != null) {
      final all = <Map<String, dynamic>>[];
      for (final section in sections) {
        final items = (section['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        all.addAll(items);
      }
      return all;
    }
    return [];
  }

  Widget _buildTips(ThemeColors colors) {
    final tips = (widget.data['tips'] as List?)?.cast<String>() ?? [];
    if (tips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 14, color: colors.textMuted),
              const SizedBox(width: 6),
              Text(
                'Tips',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...tips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.textMuted,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tip,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildDisclaimer(ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Text(
        'AI nutrition analysis is estimated. Consult a dietitian for personalized dietary advice.',
        style: TextStyle(
          fontSize: 10,
          fontStyle: FontStyle.italic,
          color: colors.textMuted,
          height: 1.3,
        ),
      ),
    );
  }

  String _getRating(Map<String, dynamic> dish) {
    final rating = dish['rating'] as String? ?? dish['traffic_light'] as String? ?? 'yellow';
    return rating.toLowerCase();
  }

  Color _ratingColor(String rating) {
    switch (rating) {
      case 'green':
        return _greenColor;
      case 'red':
        return _redColor;
      default:
        return _yellowColor;
    }
  }
}
