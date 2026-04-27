import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/nutrition.dart';

class CollapsibleFoodItemsSection extends StatefulWidget {
  final List<FoodItemRanking> foodItems;
  final bool isDark;
  final void Function(int index, FoodItemRanking updatedItem)? onItemWeightChanged;
  final void Function(int index)? onItemRemoved;
  /// Per-field inline edit: (index, field, newValue) where field is one of
  /// 'calories' | 'protein_g' | 'carbs_g' | 'fat_g'. Parent decides whether
  /// to commit, diff against originals, and emit analytics.
  final void Function(int index, String field, num newValue)? onItemFieldEdited;
  /// Set of indices that have already been edited (for the "edited" badge).
  final Set<int> editedIndices;

  const CollapsibleFoodItemsSection({
    super.key,
    required this.foodItems,
    required this.isDark,
    this.onItemWeightChanged,
    this.onItemRemoved,
    this.onItemFieldEdited,
    this.editedIndices = const {},
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
                  isEdited: widget.editedIndices.contains(entry.key),
                  onWeightChanged: widget.onItemWeightChanged != null
                      ? (updatedItem) => widget.onItemWeightChanged!(entry.key, updatedItem)
                      : null,
                  onRemoved: widget.onItemRemoved != null
                      ? () => widget.onItemRemoved!(entry.key)
                      : null,
                  onFieldEdited: widget.onItemFieldEdited != null
                      ? (field, value) => widget.onItemFieldEdited!(entry.key, field, value)
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
  final bool isEdited;
  final void Function(FoodItemRanking updatedItem)? onWeightChanged;
  final VoidCallback? onRemoved;
  /// Inline per-field edit. [field] is 'calories' | 'protein_g' | 'carbs_g' | 'fat_g'.
  final void Function(String field, num newValue)? onFieldEdited;

  const _FoodItemRankingCard({
    required this.item,
    required this.isDark,
    this.isEdited = false,
    this.onWeightChanged,
    this.onRemoved,
    this.onFieldEdited,
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
  late double _baselineWeightPerUnit;
  String? _activePreset;

  @override
  void initState() {
    super.initState();
    _currentWeight = widget.item.weightG ?? 100.0;
    _currentCount = widget.item.count ?? 1;
    _baselineWeight = _currentWeight;
    // When weightPerUnitG isn't set, derive per-unit weight from total weight / count
    // so count mode doesn't treat the entire serving as one "piece"
    _baselineWeightPerUnit = widget.item.weightPerUnitG ??
        (_currentWeight / _currentCount);
    _activePreset = 'M';
    _weightController = TextEditingController(text: _currentWeight.round().toString());
    _countController = TextEditingController(text: _currentCount.toString());
    // Photo/camera items arrive as "5 pieces" / "2 tbsp" / "0.5 cup" with no
    // explicit gram weight or per-gram nutrition. Defaulting to weight mode
    // would show a misleading "100 g" placeholder. When count is known and
    // weight isn't, open in count mode. When BOTH are known, open in 'both'
    // mode so the count (e.g. "3 pcs") stays visible — users care about
    // discrete pieces, not just grams.
    final hasCount = widget.item.count != null;
    final hasExplicitWeight = widget.item.weightG != null;
    if (hasCount && hasExplicitWeight) {
      _displayMode = _PortionDisplayMode.both;
    } else if (hasCount && !hasExplicitWeight) {
      _displayMode = _PortionDisplayMode.count;
    } else {
      _displayMode = _PortionDisplayMode.weight;
    }
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
      final count = widget.item.count ?? 1;
      _baselineWeightPerUnit = widget.item.weightPerUnitG ??
          (_baselineWeight / count);
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
      final effectiveWeightPerUnit = widget.item.weightPerUnitG ?? _baselineWeightPerUnit;
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
        final effectiveWPU = widget.item.weightPerUnitG ?? _baselineWeightPerUnit;
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
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.item.name,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary),
                            maxLines: 2,
                            softWrap: true,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.isEdited) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: teal.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: teal.withValues(alpha: 0.4), width: 0.5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit_rounded, size: 9, color: teal),
                                const SizedBox(width: 3),
                                Text(
                                  'edited',
                                  style: TextStyle(fontSize: 9, color: teal, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    // Always show the inline portion adjuster when we have
                    // any quantity we can scale from. For items without
                    // usdaData/aiPerGram, _updateWeight/_updateCount fall
                    // back to proportional scaling of the AI-estimated
                    // macros — the same treatment text-logged foods get.
                    // Only a fully-unscalable item (no weight AND no count)
                    // keeps the read-only text line.
                    if (canScale ||
                        widget.item.weightG != null ||
                        widget.item.count != null)
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
                    if (widget.onFieldEdited != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: _buildMacroChipsRow(textPrimary, textMuted, teal),
                      ),
                  ],
                ),
              ),
              // Calories (tap-to-edit)
              _EditablePill(
                label: 'kcal',
                value: (_displayCalories ?? widget.item.calories ?? 0).toDouble(),
                isInt: true,
                isEdited: widget.isEdited,
                isDark: widget.isDark,
                accent: teal,
                onSaved: widget.onFieldEdited != null
                    ? (v) => widget.onFieldEdited!('calories', v.round())
                    : null,
                valueStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                unitStyle: TextStyle(fontSize: 10, color: textMuted),
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
                  Text(widget.item.weightPerUnitG != null ? 'pcs' : 'servings',
                      style: TextStyle(fontSize: 12, color: textMuted)),
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

    // Only expose Weight / Both tabs when we actually have a gram weight
    // to edit against. For AI-estimated count-only items (e.g. "5 pieces"
    // with no weight), weight mode would edit a fake 100 g placeholder.
    final hasWeightBaseline = widget.item.weightG != null || widget.item.canScale;
    final hasCount = widget.item.count != null;

    if (hasWeightBaseline && hasCount) {
      return Row(
        children: [
          toggleButton('Weight', _PortionDisplayMode.weight, borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), bottomLeft: Radius.circular(6))),
          toggleButton('Count', _PortionDisplayMode.count),
          toggleButton('Both', _PortionDisplayMode.both, borderRadius: const BorderRadius.only(topRight: Radius.circular(6), bottomRight: Radius.circular(6))),
        ],
      );
    }
    // Weight-only (no count from AI): single tab, no meaningful toggle.
    if (hasWeightBaseline) {
      return const SizedBox.shrink();
    }
    // Count-only: single tab, no meaningful toggle.
    return const SizedBox.shrink();
  }

  /// Inline-editable P / C / F chips. Shown only when onFieldEdited is wired.
  /// Uses macro-specific palette per feedback_accent_colors.md.
  Widget _buildMacroChipsRow(Color textPrimary, Color textMuted, Color accent) {
    final proteinColor = widget.isDark ? AppColors.macroProtein : AppColorsLight.macroProtein;
    final carbsColor = widget.isDark ? AppColors.macroCarbs : AppColorsLight.macroCarbs;
    final fatColor = widget.isDark ? AppColors.macroFat : AppColorsLight.macroFat;

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        _MacroChip(
          label: 'P',
          value: (widget.item.proteinG ?? 0).toDouble(),
          color: proteinColor,
          isDark: widget.isDark,
          onSaved: (v) => widget.onFieldEdited?.call('protein_g', double.parse(v.toStringAsFixed(1))),
        ),
        _MacroChip(
          label: 'C',
          value: (widget.item.carbsG ?? 0).toDouble(),
          color: carbsColor,
          isDark: widget.isDark,
          onSaved: (v) => widget.onFieldEdited?.call('carbs_g', double.parse(v.toStringAsFixed(1))),
        ),
        _MacroChip(
          label: 'F',
          value: (widget.item.fatG ?? 0).toDouble(),
          color: fatColor,
          isDark: widget.isDark,
          onSaved: (v) => widget.onFieldEdited?.call('fat_g', double.parse(v.toStringAsFixed(1))),
        ),
      ],
    );
  }
}

/// Inline tap-to-edit pill for the right-side "kcal" corner of a food row.
/// Normal state shows "248 kcal"; tapping swaps in a number TextField plus
/// ✓/✕ affordances. Saves via onSaved callback; cancel leaves the value alone.
class _EditablePill extends StatefulWidget {
  final String label;             // e.g. 'kcal'
  final double value;
  final bool isInt;
  final bool isEdited;
  final bool isDark;
  final Color accent;
  final TextStyle valueStyle;
  final TextStyle unitStyle;
  final void Function(num newValue)? onSaved;

  const _EditablePill({
    required this.label,
    required this.value,
    required this.isInt,
    required this.isEdited,
    required this.isDark,
    required this.accent,
    required this.valueStyle,
    required this.unitStyle,
    this.onSaved,
  });

  @override
  State<_EditablePill> createState() => _EditablePillState();
}

class _EditablePillState extends State<_EditablePill> {
  bool _editing = false;
  late TextEditingController _controller;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _fmt(widget.value));
  }

  @override
  void didUpdateWidget(covariant _EditablePill oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only sync the text field from parent when NOT actively editing —
    // otherwise we'd stomp the user's in-progress input.
    if (!_editing && oldWidget.value != widget.value) {
      _controller.text = _fmt(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _fmt(double v) {
    if (widget.isInt) return v.round().toString();
    // One decimal for macros, trimmed of trailing zero
    final s = v.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  void _commit() {
    final text = _controller.text.trim();
    final parsed = double.tryParse(text);
    if (parsed == null || parsed < 0 || parsed > 100000) {
      // Invalid — reset and exit edit mode
      _controller.text = _fmt(widget.value);
      setState(() => _editing = false);
      return;
    }
    setState(() => _editing = false);
    if (parsed != widget.value) {
      widget.onSaved?.call(widget.isInt ? parsed.round() : parsed);
    }
  }

  void _cancel() {
    _controller.text = _fmt(widget.value);
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_editing) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: widget.accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: widget.accent, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 52,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: true,
                keyboardType: TextInputType.numberWithOptions(decimal: !widget.isInt),
                textAlign: TextAlign.end,
                style: widget.valueStyle,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _commit(),
              ),
            ),
            const SizedBox(width: 4),
            Text(widget.label, style: widget.unitStyle),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: _commit,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(Icons.check_rounded, size: 16, color: widget.accent),
              ),
            ),
            GestureDetector(
              onTap: _cancel,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final editedColor = widget.isEdited ? widget.accent : null;
    final displayValueStyle = editedColor != null
        ? widget.valueStyle.copyWith(color: editedColor)
        : widget.valueStyle;

    return GestureDetector(
      onTap: widget.onSaved == null ? null : () => setState(() => _editing = true),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: widget.onSaved == null
            ? null
            : BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border(
                  bottom: BorderSide(
                    color: widget.accent.withValues(alpha: widget.isEdited ? 0.4 : 0.15),
                    width: 1,
                    style: BorderStyle.solid,
                  ),
                ),
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(_fmt(widget.value), style: displayValueStyle),
            Text(widget.label, style: widget.unitStyle),
          ],
        ),
      ),
    );
  }
}

/// Compact P / C / F inline-editable macro chip shown under the food name.
class _MacroChip extends StatefulWidget {
  final String label;   // 'P' | 'C' | 'F'
  final double value;
  final Color color;
  final bool isDark;
  final void Function(num newValue)? onSaved;

  const _MacroChip({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
    this.onSaved,
  });

  @override
  State<_MacroChip> createState() => _MacroChipState();
}

class _MacroChipState extends State<_MacroChip> {
  bool _editing = false;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _fmt(widget.value));
  }

  @override
  void didUpdateWidget(covariant _MacroChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing && oldWidget.value != widget.value) {
      _controller.text = _fmt(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _fmt(double v) {
    final s = v.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  void _commit() {
    final parsed = double.tryParse(_controller.text.trim());
    if (parsed == null || parsed < 0 || parsed > 10000) {
      _controller.text = _fmt(widget.value);
      setState(() => _editing = false);
      return;
    }
    setState(() => _editing = false);
    if (parsed != widget.value) widget.onSaved?.call(parsed);
  }

  void _cancel() {
    _controller.text = _fmt(widget.value);
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final textMuted = widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final bg = widget.color.withValues(alpha: 0.12);
    final borderCol = widget.color.withValues(alpha: _editing ? 0.9 : 0.4);

    if (_editing) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderCol, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${widget.label}:',
              style: TextStyle(fontSize: 11, color: widget.color, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 3),
            SizedBox(
              width: 36,
              child: TextField(
                controller: _controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(fontSize: 11, color: widget.color, fontWeight: FontWeight.w600),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _commit(),
              ),
            ),
            Text('g', style: TextStyle(fontSize: 10, color: textMuted)),
            const SizedBox(width: 3),
            GestureDetector(
              onTap: _commit,
              behavior: HitTestBehavior.opaque,
              child: Icon(Icons.check_rounded, size: 13, color: widget.color),
            ),
            GestureDetector(
              onTap: _cancel,
              behavior: HitTestBehavior.opaque,
              child: Icon(Icons.close_rounded, size: 11, color: textMuted),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: widget.onSaved == null ? null : () => setState(() => _editing = true),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: widget.color.withValues(alpha: 0.25), width: 0.5),
        ),
        child: Text(
          '${widget.label} ${_fmt(widget.value)}g',
          style: TextStyle(fontSize: 11, color: widget.color, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
