import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/nutrition.dart';

class CollapsibleFoodItemsSection extends StatefulWidget {
  final List<FoodItemRanking> foodItems;
  final bool isDark;
  final void Function(int index, FoodItemRanking updatedItem)? onItemWeightChanged;
  final void Function(int index)? onItemRemoved;

  const CollapsibleFoodItemsSection({
    super.key,
    required this.foodItems,
    required this.isDark,
    this.onItemWeightChanged,
    this.onItemRemoved,
  });

  @override
  State<CollapsibleFoodItemsSection> createState() => _CollapsibleFoodItemsSectionState();
}

class _CollapsibleFoodItemsSectionState extends State<CollapsibleFoodItemsSection> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final elevated = widget.isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = widget.isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = widget.isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final teal = widget.isDark ? AppColors.teal : AppColorsLight.teal;

    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.list_alt, size: 20, color: teal),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.foodItems.length} Food Items',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
                        ),
                        Text(
                          'Tap to ${_isExpanded ? 'hide' : 'see'} details',
                          style: TextStyle(fontSize: 12, color: textMuted),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more, color: textMuted),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                Divider(height: 1, color: cardBorder),
                ...widget.foodItems.asMap().entries.map((entry) => _FoodItemRankingCard(
                  item: entry.value,
                  isDark: widget.isDark,
                  onWeightChanged: widget.onItemWeightChanged != null
                      ? (updatedItem) => widget.onItemWeightChanged!(entry.key, updatedItem)
                      : null,
                  onRemoved: widget.onItemRemoved != null
                      ? () => widget.onItemRemoved!(entry.key)
                      : null,
                )),
              ],
            ),
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

class _FoodItemRankingCard extends StatefulWidget {
  final FoodItemRanking item;
  final bool isDark;
  final void Function(FoodItemRanking updatedItem)? onWeightChanged;
  final VoidCallback? onRemoved;

  const _FoodItemRankingCard({
    required this.item,
    required this.isDark,
    this.onWeightChanged,
    this.onRemoved,
  });

  @override
  State<_FoodItemRankingCard> createState() => _FoodItemRankingCardState();
}

enum _PortionDisplayMode { weight, count, both }

class _FoodItemRankingCardState extends State<_FoodItemRankingCard> {
  static const _presetMultipliers = {'S': 0.5, 'M': 1.0, 'L': 1.5, 'XL': 2.0};

  late TextEditingController _weightController;
  late TextEditingController _countController;
  late double _currentWeight;
  late int _currentCount;
  int? _displayCalories;
  _PortionDisplayMode _displayMode = _PortionDisplayMode.weight;
  late double _baselineWeight;
  String? _activePreset;

  @override
  void initState() {
    super.initState();
    _currentWeight = widget.item.weightG ?? 100.0;
    _currentCount = widget.item.count ?? 1;
    _baselineWeight = _currentWeight;
    _activePreset = 'M';
    _weightController = TextEditingController(text: _currentWeight.round().toString());
    _countController = TextEditingController(text: _currentCount.toString());
    _displayMode = _PortionDisplayMode.weight;
  }

  @override
  void dispose() {
    _weightController.dispose();
    _countController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_FoodItemRankingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.name != widget.item.name) {
      _baselineWeight = widget.item.weightG ?? 100.0;
      _activePreset = 'M';
    }
    if (oldWidget.item.weightG != widget.item.weightG) {
      _currentWeight = widget.item.weightG ?? 100.0;
      _weightController.text = _currentWeight.round().toString();
    }
    if (oldWidget.item.count != widget.item.count) {
      _currentCount = widget.item.count ?? 1;
      _countController.text = _currentCount.toString();
    }
  }

  Color _getScoreColor() {
    if (widget.item.goalScore == null) return Colors.grey;
    if (widget.item.goalScore! >= 8) return AppColors.textMuted;
    if (widget.item.goalScore! >= 5) return AppColors.textSecondary;
    return AppColors.textPrimary;
  }

  void _updateWeight(double newWeight, {bool fromPreset = false}) {
    if (newWeight <= 0 || newWeight > 5000) return;
    setState(() {
      if (!fromPreset) _activePreset = null;
      _currentWeight = newWeight;
      _weightController.text = newWeight.round().toString();
      if (widget.item.weightPerUnitG != null && widget.item.weightPerUnitG! > 0) {
        _currentCount = (newWeight / widget.item.weightPerUnitG!).round();
        _countController.text = _currentCount.toString();
      }
      final originalWeight = widget.item.weightG ?? 100.0;
      if (originalWeight > 0) {
        _displayCalories = ((widget.item.calories ?? 0) * (newWeight / originalWeight)).round();
      }
    });
    if (widget.onWeightChanged != null) {
      if (widget.item.canScale) {
        final updatedItem = widget.item.withWeight(newWeight);
        widget.onWeightChanged!(updatedItem);
      } else {
        final originalWeight = widget.item.weightG ?? 100.0;
        if (originalWeight > 0) {
          final ratio = newWeight / originalWeight;
          final scaled = FoodItemRanking(
            name: widget.item.name,
            amount: '${newWeight.round()} ${widget.item.unit ?? "g"}',
            calories: ((widget.item.calories ?? 0) * ratio).round(),
            proteinG: (widget.item.proteinG ?? 0) * ratio,
            carbsG: (widget.item.carbsG ?? 0) * ratio,
            fatG: (widget.item.fatG ?? 0) * ratio,
            fiberG: (widget.item.fiberG ?? 0) * ratio,
            weightG: newWeight,
            weightSource: 'exact',
            goalScore: widget.item.goalScore,
            goalAlignment: widget.item.goalAlignment,
            reason: widget.item.reason,
            usdaData: widget.item.usdaData,
            aiPerGram: widget.item.aiPerGram,
            count: widget.item.count,
            weightPerUnitG: widget.item.weightPerUnitG,
            unit: widget.item.unit,
          );
          widget.onWeightChanged!(scaled);
        }
      }
    }
  }

  void _updateCount(int newCount) {
    if (newCount <= 0 || newCount > 1000) return;
    setState(() {
      _activePreset = null;
      _currentCount = newCount;
      _countController.text = newCount.toString();
      final effectiveWeightPerUnit = widget.item.weightPerUnitG ?? _baselineWeight;
      _currentWeight = newCount * effectiveWeightPerUnit;
      _weightController.text = _currentWeight.round().toString();
      final originalWeight = widget.item.weightG ?? 100.0;
      final newWeight = _currentWeight;
      if (originalWeight > 0) {
        _displayCalories = ((widget.item.calories ?? 0) * (newWeight / originalWeight)).round();
      }
    });
    if (widget.onWeightChanged != null) {
      if (widget.item.canScaleByCount) {
        final updatedItem = widget.item.withCount(newCount);
        widget.onWeightChanged!(updatedItem);
      } else {
        final effectiveWPU = widget.item.weightPerUnitG ?? _baselineWeight;
        final newWeight = newCount * effectiveWPU;
        final originalWeight = widget.item.weightG ?? 100.0;
        if (originalWeight > 0) {
          final ratio = newWeight / originalWeight;
          final scaled = FoodItemRanking(
            name: widget.item.name,
            amount: '$newCount x ${effectiveWPU.round()}${widget.item.unit ?? "g"}',
            calories: ((widget.item.calories ?? 0) * ratio).round(),
            proteinG: (widget.item.proteinG ?? 0) * ratio,
            carbsG: (widget.item.carbsG ?? 0) * ratio,
            fatG: (widget.item.fatG ?? 0) * ratio,
            fiberG: (widget.item.fiberG ?? 0) * ratio,
            weightG: newWeight,
            weightSource: 'exact',
            goalScore: widget.item.goalScore,
            goalAlignment: widget.item.goalAlignment,
            reason: widget.item.reason,
            usdaData: widget.item.usdaData,
            aiPerGram: widget.item.aiPerGram,
            count: newCount,
            weightPerUnitG: effectiveWPU,
            unit: widget.item.unit,
          );
          widget.onWeightChanged!(scaled);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = widget.isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final teal = widget.isDark ? AppColors.teal : AppColorsLight.teal;
    final glassSurface = widget.isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final scoreColor = _getScoreColor();

    final canScale = widget.item.canScale;
    final isEstimated = widget.item.isWeightEstimated;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              // Score badge
              if (widget.item.goalScore != null)
                Column(
                  children: [
                    Text('Score', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: scoreColor.withValues(alpha: 0.7))),
                    const SizedBox(height: 2),
                    Container(
                      width: 42,
                      height: 36,
                      decoration: BoxDecoration(
                        color: scoreColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
                      ),
                      child: Center(
                        child: Text('${widget.item.goalScore}/10', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: scoreColor)),
                      ),
                    ),
                  ],
                )
              else
                const SizedBox(width: 42),
              const SizedBox(width: 12),
              // Food info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.item.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
                    if (canScale)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: _buildPortionAdjuster(glassSurface, textPrimary, textMuted, teal, isEstimated),
                      )
                    else if (widget.item.amount != null)
                      Text(widget.item.amount!, style: TextStyle(fontSize: 12, color: textMuted)),
                    if (widget.item.reason != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(widget.item.reason!, style: TextStyle(fontSize: 11, color: scoreColor, fontStyle: FontStyle.italic)),
                      ),
                  ],
                ),
              ),
              // Calories
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${_displayCalories ?? widget.item.calories ?? 0}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary)),
                  Text('kcal', style: TextStyle(fontSize: 10, color: textMuted)),
                ],
              ),
              // Remove button
              if (widget.onRemoved != null) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: widget.onRemoved,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 16, color: widget.isDark ? AppColors.error : AppColorsLight.error),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _onPresetTapped(String preset) {
    final multiplier = _presetMultipliers[preset]!;
    final newWeight = (_baselineWeight * multiplier).roundToDouble();
    setState(() => _activePreset = preset);
    _updateWeight(newWeight, fromPreset: true);
  }

  Widget _buildPortionPresets(Color teal, Color glassSurface, Color textMuted) {
    return Row(
      children: _presetMultipliers.keys.map((preset) {
        final isSelected = _activePreset == preset;
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: GestureDetector(
            onTap: () => _onPresetTapped(preset),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? teal.withValues(alpha: 0.2) : glassSurface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? teal.withValues(alpha: 0.5) : glassSurface,
                ),
              ),
              child: Text(
                preset,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? teal : textMuted,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPortionAdjuster(Color glassSurface, Color textPrimary, Color textMuted, Color teal, bool isEstimated) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => _displayMode == _PortionDisplayMode.weight
                  ? _updateWeight(_currentWeight - 10)
                  : _updateCount(_currentCount - 1),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: glassSurface, borderRadius: BorderRadius.circular(4)),
                child: Icon(Icons.remove, size: 14, color: textMuted),
              ),
            ),
            const SizedBox(width: 6),
            if (_displayMode == _PortionDisplayMode.weight)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 50,
                    child: TextField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: textPrimary, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        filled: true,
                        fillColor: glassSurface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
                      ),
                      onSubmitted: (value) {
                        final newWeight = double.tryParse(value);
                        if (newWeight != null) _updateWeight(newWeight);
                      },
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text('${widget.item.displayUnit}${isEstimated ? ' ~' : ''}', style: TextStyle(fontSize: 12, color: textMuted)),
                ],
              )
            else if (_displayMode == _PortionDisplayMode.count)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 40,
                    child: TextField(
                      controller: _countController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: textPrimary, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        filled: true,
                        fillColor: glassSurface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
                      ),
                      onSubmitted: (value) {
                        final newCount = int.tryParse(value);
                        if (newCount != null) _updateCount(newCount);
                      },
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text('pcs', style: TextStyle(fontSize: 12, color: textMuted)),
                ],
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 40,
                    child: TextField(
                      controller: _countController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: textPrimary, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        filled: true,
                        fillColor: glassSurface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
                      ),
                      onSubmitted: (value) {
                        final newCount = int.tryParse(value);
                        if (newCount != null) _updateCount(newCount);
                      },
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text('pcs = ${_currentWeight.round()}${widget.item.displayUnit}', style: TextStyle(fontSize: 12, color: textMuted)),
                ],
              ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => _displayMode == _PortionDisplayMode.weight
                  ? _updateWeight(_currentWeight + 10)
                  : _updateCount(_currentCount + 1),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: glassSurface, borderRadius: BorderRadius.circular(4)),
                child: Icon(Icons.add, size: 14, color: textMuted),
              ),
            ),
            if (isEstimated && _displayMode == _PortionDisplayMode.weight) ...[
              const SizedBox(width: 8),
              Tooltip(
                message: 'Weight estimated from "${widget.item.amount}"',
                child: Icon(Icons.info_outline, size: 14, color: teal.withValues(alpha: 0.7)),
              ),
            ],
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: _buildPortionPresets(teal, glassSurface, textMuted),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: _buildModeToggle(teal, glassSurface, textMuted),
        ),
      ],
    );
  }

  Widget _buildModeToggle(Color teal, Color glassSurface, Color textMuted) {
    Widget toggleButton(String label, _PortionDisplayMode mode, {BorderRadius? borderRadius}) {
      final isSelected = _displayMode == mode;
      return GestureDetector(
        onTap: () => setState(() => _displayMode = mode),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isSelected ? teal.withValues(alpha: 0.2) : glassSurface,
            borderRadius: borderRadius,
            border: Border.all(color: isSelected ? teal.withValues(alpha: 0.5) : glassSurface),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? teal : textMuted,
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        toggleButton('Weight', _PortionDisplayMode.weight, borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), bottomLeft: Radius.circular(6))),
        toggleButton('Count', _PortionDisplayMode.count),
        toggleButton('Both', _PortionDisplayMode.both, borderRadius: const BorderRadius.only(topRight: Radius.circular(6), bottomRight: Radius.circular(6))),
      ],
    );
  }
}
