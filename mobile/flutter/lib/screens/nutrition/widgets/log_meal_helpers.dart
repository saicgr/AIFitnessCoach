import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Nutrition info row for barcode product details
class NutritionInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const NutritionInfoRow({super.key, required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: textMuted)),
          Text(value, style: TextStyle(color: textSecondary)),
        ],
      ),
    );
  }
}

/// Nutri-Score badge (A-E) with tooltip
class NutriscoreBadge extends StatelessWidget {
  final String grade;
  final bool isDark;

  const NutriscoreBadge({super.key, required this.grade, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final g = grade.toUpperCase();
    final color = switch (g) {
      'A' => const Color(0xFF038141),
      'B' => const Color(0xFF85BB2F),
      'C' => const Color(0xFFFECB02),
      'D' => const Color(0xFFEE8100),
      _ => const Color(0xFFE63E11),
    };
    return Tooltip(
      message: 'Nutri-Score rates overall nutritional quality\nfrom A (best) to E (worst)',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Nutri-Score ',
                style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMuted : AppColorsLight.textMuted)),
            Text(g,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}

/// NOVA processing group badge (1-4) with (i) icon for expandable detail
class NovaBadge extends StatelessWidget {
  final int group;
  final bool isDark;
  final VoidCallback? onInfoTap;

  const NovaBadge({super.key, required this.group, required this.isDark, this.onInfoTap});

  static Color colorForGroup(int group) => switch (group) {
    1 => const Color(0xFF038141),
    2 => const Color(0xFF85BB2F),
    3 => const Color(0xFFEE8100),
    _ => const Color(0xFFE63E11),
  };

  static String labelForGroup(int group) => switch (group) {
    1 => 'Unprocessed',
    2 => 'Processed ingredients',
    3 => 'Processed',
    _ => 'Ultra-processed',
  };

  @override
  Widget build(BuildContext context) {
    final color = colorForGroup(group);
    final label = labelForGroup(group);
    return GestureDetector(
      onTap: onInfoTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('NOVA $group ',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
            Text(label,
                style: TextStyle(fontSize: 10, color: isDark ? AppColors.textMuted : AppColorsLight.textMuted)),
            if (onInfoTap != null) ...[
              const SizedBox(width: 4),
              Icon(Icons.info_outline, size: 13, color: color.withValues(alpha: 0.7)),
            ],
          ],
        ),
      ),
    );
  }
}


// ═══════════════════════════════════════════════════════════════════
// NOVA DETAIL SECTION - Expandable ingredient processing breakdown
// ═══════════════════════════════════════════════════════════════════

/// Processing category for an ingredient
enum ProcessingLevel {
  ultraProcessed,
  harmfulInExcess,
  okInModeration,
  minimallyProcessed;

  String get label => switch (this) {
    ultraProcessed => 'Ultra-processed',
    harmfulInExcess => 'Harmful in excess',
    okInModeration => 'OK in moderation',
    minimallyProcessed => 'Minimally processed',
  };

  Color get color => switch (this) {
    ultraProcessed => const Color(0xFFE63E11),
    harmfulInExcess => const Color(0xFFEE8100),
    okInModeration => const Color(0xFFFECB02),
    minimallyProcessed => const Color(0xFF038141),
  };

  IconData get icon => switch (this) {
    ultraProcessed => Icons.warning_rounded,
    harmfulInExcess => Icons.report_problem_outlined,
    okInModeration => Icons.check_circle_outline,
    minimallyProcessed => Icons.eco,
  };

  int get sortOrder => switch (this) {
    ultraProcessed => 0,
    harmfulInExcess => 1,
    okInModeration => 2,
    minimallyProcessed => 3,
  };
}

/// Single classified ingredient
class ClassifiedIngredient {
  final String name;
  final ProcessingLevel level;
  final String reason;

  const ClassifiedIngredient({required this.name, required this.level, required this.reason});
}

/// Expandable NOVA detail section showing per-ingredient processing breakdown
class NovaDetailSection extends StatefulWidget {
  final int novaGroup;
  final String? ingredientsText;
  final bool isDark;

  const NovaDetailSection({
    super.key,
    required this.novaGroup,
    this.ingredientsText,
    required this.isDark,
  });

  @override
  State<NovaDetailSection> createState() => _NovaDetailSectionState();
}

class _NovaDetailSectionState extends State<NovaDetailSection> {
  bool _isExpanded = false;

  // Ultra-processed markers (artificial additives, industrial ingredients)
  static const _ultraProcessedPatterns = [
    'hydrogenated', 'high-fructose', 'high fructose', 'corn syrup',
    'artificial', 'dextrose', 'maltodextrin', 'modified starch',
    'modified food starch', 'emulsifier', 'mono- and diglycerides',
    'polysorbate', 'carrageenan', 'xanthan gum', 'guar gum',
    'sodium benzoate', 'potassium sorbate', 'bht', 'bha', 'tbhq',
    'sodium nitrite', 'sodium nitrate', 'aspartame', 'sucralose',
    'acesulfame', 'saccharin', 'flavor enhancer', 'monosodium glutamate',
    'msg', 'autolyzed yeast', 'hydrolyzed', 'isolate', 'textured',
    'interesterified', 'partially hydrogenated', 'fully hydrogenated',
  ];

  // E-number pattern for food additives
  static final _eNumberPattern = RegExp(r'\bE\d{3,4}[a-z]?\b', caseSensitive: false);

  // Harmful in excess (refined, excessive sugar/sodium)
  static const _harmfulPatterns = [
    'sugar', 'syrup', 'fructose', 'sucrose', 'glucose',
    'dextrin', 'molasses', 'caramel color', 'palm oil',
    'refined', 'bleached flour', 'enriched flour',
    'sodium', 'salt',
  ];

  // OK in moderation (processed but not inherently harmful)
  static const _moderatePatterns = [
    'butter', 'cream', 'cheese', 'yogurt', 'milk powder',
    'starch', 'vinegar', 'yeast', 'baking soda', 'baking powder',
    'gelatin', 'pectin', 'lecithin', 'citric acid', 'lactic acid',
    'ascorbic acid', 'tocopherol',
  ];

  List<ClassifiedIngredient> _classifyIngredients() {
    if (widget.ingredientsText == null || widget.ingredientsText!.isEmpty) return [];

    // Parse ingredients: split by comma, clean up
    final raw = widget.ingredientsText!
        .replaceAll(RegExp(r'\([^)]*\)'), '') // Remove parenthetical sub-ingredients
        .split(RegExp(r'[,;.]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && s.length > 1)
        .toList();

    final results = <ClassifiedIngredient>[];

    for (final ingredient in raw) {
      final lower = ingredient.toLowerCase();

      // Check ultra-processed
      if (_ultraProcessedPatterns.any((p) => lower.contains(p)) ||
          _eNumberPattern.hasMatch(ingredient)) {
        results.add(ClassifiedIngredient(
          name: ingredient,
          level: ProcessingLevel.ultraProcessed,
          reason: _getUltraProcessedReason(lower),
        ));
        continue;
      }

      // Check harmful in excess
      if (_harmfulPatterns.any((p) => lower.contains(p))) {
        results.add(ClassifiedIngredient(
          name: ingredient,
          level: ProcessingLevel.harmfulInExcess,
          reason: _getHarmfulReason(lower),
        ));
        continue;
      }

      // Check OK in moderation
      if (_moderatePatterns.any((p) => lower.contains(p))) {
        results.add(ClassifiedIngredient(
          name: ingredient,
          level: ProcessingLevel.okInModeration,
          reason: 'Processed but generally safe in normal amounts',
        ));
        continue;
      }

      // Default: minimally processed
      results.add(ClassifiedIngredient(
        name: ingredient,
        level: ProcessingLevel.minimallyProcessed,
        reason: 'Whole or minimally processed ingredient',
      ));
    }

    // Sort: ultra-processed first, then harmful, then moderate, then natural
    results.sort((a, b) => a.level.sortOrder.compareTo(b.level.sortOrder));
    return results;
  }

  String _getUltraProcessedReason(String lower) {
    if (lower.contains('hydrogenated')) return 'Contains trans fats from industrial processing';
    if (lower.contains('high-fructose') || lower.contains('high fructose') || lower.contains('corn syrup')) {
      return 'Industrial sweetener linked to metabolic issues';
    }
    if (lower.contains('artificial')) return 'Artificial additive — synthetic compound';
    if (lower.contains('maltodextrin')) return 'Highly processed starch with high glycemic index';
    if (lower.contains('modified starch') || lower.contains('modified food starch')) {
      return 'Chemically or physically modified from natural form';
    }
    if (_eNumberPattern.hasMatch(lower)) return 'Food additive (E-number classified)';
    if (lower.contains('emulsifier') || lower.contains('mono- and diglycerides')) {
      return 'Industrial emulsifier used in processed foods';
    }
    if (lower.contains('carrageenan')) return 'Thickener linked to gut inflammation';
    if (lower.contains('nitrite') || lower.contains('nitrate')) return 'Preservative — linked to health concerns in excess';
    if (lower.contains('aspartame') || lower.contains('sucralose') || lower.contains('acesulfame') || lower.contains('saccharin')) {
      return 'Artificial sweetener — synthetic sugar substitute';
    }
    if (lower.contains('hydrolyzed')) return 'Chemically broken down protein (may contain MSG)';
    if (lower.contains('isolate')) return 'Industrially extracted and purified';
    return 'Ultra-processed industrial ingredient';
  }

  String _getHarmfulReason(String lower) {
    if (lower.contains('sugar') || lower.contains('syrup') || lower.contains('fructose') ||
        lower.contains('sucrose') || lower.contains('glucose') || lower.contains('molasses')) {
      return 'Added sugar — promotes inflammation and insulin spikes';
    }
    if (lower.contains('palm oil')) return 'High in saturated fat and linked to inflammation';
    if (lower.contains('salt') || lower.contains('sodium')) return 'Excess sodium raises blood pressure';
    if (lower.contains('refined') || lower.contains('bleached') || lower.contains('enriched flour')) {
      return 'Refined grain — stripped of fiber and nutrients';
    }
    if (lower.contains('caramel color')) return 'May contain carcinogenic byproducts (4-MEI)';
    return 'Can be harmful in excessive amounts';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.ingredientsText == null || widget.ingredientsText!.isEmpty) {
      return const SizedBox.shrink();
    }

    final classified = _classifyIngredients();
    if (classified.isEmpty) return const SizedBox.shrink();

    final novaColor = NovaBadge.colorForGroup(widget.novaGroup);
    final textPrimary = widget.isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = widget.isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = widget.isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    // Count by category
    final ultraCount = classified.where((c) => c.level == ProcessingLevel.ultraProcessed).length;
    final harmfulCount = classified.where((c) => c.level == ProcessingLevel.harmfulInExcess).length;
    final moderateCount = classified.where((c) => c.level == ProcessingLevel.okInModeration).length;
    final naturalCount = classified.where((c) => c.level == ProcessingLevel.minimallyProcessed).length;

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: Container(
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.factory_outlined, size: 18, color: novaColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Processing Breakdown',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                      ),
                    ),
                    // Category summary chips
                    if (ultraCount > 0)
                      _CountChip(count: ultraCount, color: ProcessingLevel.ultraProcessed.color),
                    if (harmfulCount > 0)
                      _CountChip(count: harmfulCount, color: ProcessingLevel.harmfulInExcess.color),
                    if (moderateCount > 0)
                      _CountChip(count: moderateCount, color: ProcessingLevel.okInModeration.color),
                    if (naturalCount > 0)
                      _CountChip(count: naturalCount, color: ProcessingLevel.minimallyProcessed.color),
                    const SizedBox(width: 4),
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                      color: textMuted,
                    ),
                  ],
                ),
              ),
            ),

            // Expanded content
            if (_isExpanded) ...[
              Divider(height: 1, color: cardBorder),

              // NOVA explanation
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                child: Text(
                  'NOVA classifies foods by degree of industrial processing (Group 1-4). '
                  'Higher groups indicate more industrial ingredients.',
                  style: TextStyle(fontSize: 11, color: textMuted, height: 1.4),
                ),
              ),

              // Processing bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: _ProcessingBar(
                  ultraCount: ultraCount,
                  harmfulCount: harmfulCount,
                  moderateCount: moderateCount,
                  naturalCount: naturalCount,
                  isDark: widget.isDark,
                ),
              ),

              // Legend
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    if (ultraCount > 0) _LegendItem(level: ProcessingLevel.ultraProcessed, count: ultraCount),
                    if (harmfulCount > 0) _LegendItem(level: ProcessingLevel.harmfulInExcess, count: harmfulCount),
                    if (moderateCount > 0) _LegendItem(level: ProcessingLevel.okInModeration, count: moderateCount),
                    if (naturalCount > 0) _LegendItem(level: ProcessingLevel.minimallyProcessed, count: naturalCount),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Ingredient list
              ...classified.map((ing) => _IngredientRow(
                ingredient: ing,
                isDark: widget.isDark,
              )),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final int count;
  final Color color;
  const _CountChip({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 3),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$count',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}

class _ProcessingBar extends StatelessWidget {
  final int ultraCount;
  final int harmfulCount;
  final int moderateCount;
  final int naturalCount;
  final bool isDark;

  const _ProcessingBar({
    required this.ultraCount,
    required this.harmfulCount,
    required this.moderateCount,
    required this.naturalCount,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final total = ultraCount + harmfulCount + moderateCount + naturalCount;
    if (total == 0) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 8,
        child: Row(
          children: [
            if (ultraCount > 0)
              Expanded(
                flex: ultraCount,
                child: Container(color: ProcessingLevel.ultraProcessed.color),
              ),
            if (harmfulCount > 0)
              Expanded(
                flex: harmfulCount,
                child: Container(color: ProcessingLevel.harmfulInExcess.color),
              ),
            if (moderateCount > 0)
              Expanded(
                flex: moderateCount,
                child: Container(color: ProcessingLevel.okInModeration.color),
              ),
            if (naturalCount > 0)
              Expanded(
                flex: naturalCount,
                child: Container(color: ProcessingLevel.minimallyProcessed.color),
              ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final ProcessingLevel level;
  final int count;
  const _LegendItem({required this.level, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: level.color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '${level.label} ($count)',
          style: TextStyle(fontSize: 10, color: Colors.grey[400]),
        ),
      ],
    );
  }
}

class _IngredientRow extends StatelessWidget {
  final ClassifiedIngredient ingredient;
  final bool isDark;
  const _IngredientRow({required this.ingredient, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final level = ingredient.level;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(level.icon, size: 14, color: level.color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ingredient.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                  ),
                ),
                Text(
                  ingredient.reason,
                  style: TextStyle(fontSize: 10, color: textMuted, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: level.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              level.label,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: level.color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rainbow-colored nutrition card for AI estimates
class RainbowNutritionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;
  final bool isDark;
  final bool compact;

  const RainbowNutritionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.isDark,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 16, color: color),
                    const SizedBox(width: 6),
                    Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color)),
                  ],
                ),
                const SizedBox(height: 6),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(text: value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary)),
                      TextSpan(text: ' $unit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color)),
                    ],
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 24, color: color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color)),
                      const SizedBox(height: 2),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(text: value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary)),
                            TextSpan(text: ' $unit', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

/// Confidence indicator for AI estimates
class ConfidenceIndicator extends StatelessWidget {
  final String confidenceLevel;
  final double? confidenceScore;
  final String? sourceType;
  final bool isDark;

  const ConfidenceIndicator({
    super.key,
    required this.confidenceLevel,
    this.confidenceScore,
    this.sourceType,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final Color indicatorColor;
    final IconData indicatorIcon;
    final String displayText;
    final String subText;

    switch (confidenceLevel) {
      case 'high':
        indicatorColor = isDark ? AppColors.green : AppColorsLight.green;
        indicatorIcon = Icons.verified;
        displayText = 'High confidence';
        subText = sourceType == 'barcode' ? 'Verified from barcode' : 'AI analysis confident';
        break;
      case 'medium':
        indicatorColor = isDark ? AppColors.orange : AppColorsLight.orange;
        indicatorIcon = Icons.info_outline;
        displayText = 'Medium confidence';
        subText = sourceType == 'restaurant'
            ? 'Restaurant estimate - actual may vary'
            : 'AI estimate - values may vary slightly';
        break;
      case 'low':
      default:
        indicatorColor = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
        indicatorIcon = Icons.help_outline;
        displayText = 'Estimate only';
        subText = 'Please verify these values';
        break;
    }

    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: indicatorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: indicatorColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(indicatorIcon, size: 16, color: indicatorColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(displayText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: indicatorColor)),
                    if (confidenceScore != null) ...[
                      const SizedBox(width: 6),
                      Text('(${(confidenceScore! * 100).toInt()}%)', style: TextStyle(fontSize: 11, color: textMuted)),
                    ],
                  ],
                ),
                Text(subText, style: TextStyle(fontSize: 11, color: textMuted, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Action icon button (glassmorphic circular icon for bottom bar)
class ActionIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  final bool isActive;
  final Color? color;

  const ActionIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.isDark,
    this.isActive = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFFF97316);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isActive ? c : c.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? c : c.withValues(alpha: 0.25),
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isActive ? Colors.white : c.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}


// ═══════════════════════════════════════════════════════════════════
// ADDITIONAL BADGES - Eco-Score, Labels, Additives
// ═══════════════════════════════════════════════════════════════════

/// Eco-Score badge (A-E) with tooltip
class EcoscoreBadge extends StatelessWidget {
  final String grade;
  final bool isDark;

  const EcoscoreBadge({super.key, required this.grade, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final g = grade.toUpperCase();
    final color = switch (g) {
      'A' => const Color(0xFF038141),
      'B' => const Color(0xFF85BB2F),
      'C' => const Color(0xFFFECB02),
      'D' => const Color(0xFFEE8100),
      _ => const Color(0xFFE63E11),
    };
    return Tooltip(
      message: 'Eco-Score rates environmental impact\nfrom A (low impact) to E (high impact)',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.eco, size: 12, color: color),
            const SizedBox(width: 4),
            Text('Eco-Score ',
                style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMuted : AppColorsLight.textMuted)),
            Text(g,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}

/// Label chip for product labels (Organic, Vegan, etc.)
class FoodLabelChip extends StatelessWidget {
  final String label;
  final bool isDark;

  const FoodLabelChip({super.key, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = _labelColor(label);
    final icon = _labelIcon(label);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color),
          ),
        ],
      ),
    );
  }

  Color _labelColor(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('organic') || lower.contains('bio')) return const Color(0xFF038141);
    if (lower.contains('vegan')) return const Color(0xFF038141);
    if (lower.contains('vegetarian')) return const Color(0xFF85BB2F);
    if (lower.contains('gluten') && lower.contains('free')) return const Color(0xFFEE8100);
    if (lower.contains('palm oil free')) return const Color(0xFF038141);
    if (lower.contains('no') || lower.contains('free')) return const Color(0xFF85BB2F);
    return isDark ? AppColors.textMuted : AppColorsLight.textMuted;
  }

  IconData? _labelIcon(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('organic') || lower.contains('bio')) return Icons.eco;
    if (lower.contains('vegan')) return Icons.spa;
    if (lower.contains('vegetarian')) return Icons.grass;
    if (lower.contains('gluten') && lower.contains('free')) return Icons.no_food;
    if (lower.contains('halal')) return Icons.verified;
    if (lower.contains('kosher')) return Icons.verified;
    return null;
  }
}

/// Additives count badge
class AdditivesCountBadge extends StatelessWidget {
  final int count;
  final bool isDark;

  const AdditivesCountBadge({super.key, required this.count, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = count > 5
        ? const Color(0xFFE63E11)
        : count > 2
            ? const Color(0xFFEE8100)
            : const Color(0xFFFECB02);

    return Tooltip(
      message: '$count food additive${count != 1 ? 's' : ''} detected',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.science_outlined, size: 12, color: color),
            const SizedBox(width: 4),
            Text('$count additive${count != 1 ? 's' : ''}',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color)),
          ],
        ),
      ),
    );
  }
}
