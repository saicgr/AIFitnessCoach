import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/inflammation_analysis.dart';
import '../../../data/providers/inflammation_analysis_provider.dart';

/// Colors for inflammation display - monochrome
class InflammationColors {
  static Color get inflammatory => AppColors.textMuted; // Gray for inflammatory
  static Color get antiInflammatory => AppColors.textPrimary; // White for anti-inflammatory
  static Color get neutral => AppColors.textMuted; // Gray
  static Color get additive => AppColors.textSecondary; // Secondary gray

  static Color getColor(InflammationType type) {
    switch (type) {
      case InflammationType.inflammatory:
        return inflammatory;
      case InflammationType.antiInflammatory:
        return antiInflammatory;
      case InflammationType.additive:
        return additive;
      case InflammationType.neutral:
      case InflammationType.unknown:
        return neutral;
    }
  }
}

/// Widget to display inflammation analysis results
class InflammationAnalysisWidget extends ConsumerStatefulWidget {
  final String userId;
  final String barcode;
  final String ingredientsText;
  final String? productName;
  final bool isDark;
  final bool showFullList;

  const InflammationAnalysisWidget({
    super.key,
    required this.userId,
    required this.barcode,
    required this.ingredientsText,
    this.productName,
    required this.isDark,
    this.showFullList = false,
  });

  @override
  ConsumerState<InflammationAnalysisWidget> createState() =>
      _InflammationAnalysisWidgetState();
}

class _InflammationAnalysisWidgetState
    extends ConsumerState<InflammationAnalysisWidget> {
  bool _analysisStarted = false;

  @override
  void initState() {
    super.initState();
    // Start analysis after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAnalysis();
    });
  }

  void _startAnalysis() {
    if (_analysisStarted) return;
    _analysisStarted = true;

    final notifier = ref.read(
      inflammationByIngredientsProvider(widget.ingredientsText).notifier,
    );
    notifier.analyze(
      userId: widget.userId,
      barcode: widget.barcode,
      productName: widget.productName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      inflammationByIngredientsProvider(widget.ingredientsText),
    );

    final textMuted =
        widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated =
        widget.isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder =
        widget.isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    // Loading state
    if (state.isLoading) {
      return _InflammationLoadingCard(isDark: widget.isDark);
    }

    // Error state
    if (state.error != null) {
      return _InflammationErrorCard(
        error: state.error!,
        onRetry: () {
          ref
              .read(inflammationByIngredientsProvider(widget.ingredientsText)
                  .notifier)
              .retry();
        },
        isDark: widget.isDark,
      );
    }

    // No analysis yet
    if (state.analysis == null) {
      return _InflammationLoadingCard(isDark: widget.isDark);
    }

    final analysis = state.analysis!;

    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with overall score
          _InflammationScoreHeader(
            score: analysis.overallScore,
            description: analysis.scoreDescription,
            isDark: widget.isDark,
          ),

          // Summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              analysis.summary,
              style: TextStyle(fontSize: 13, color: textMuted),
            ),
          ),

          const SizedBox(height: 16),

          // Ingredient counts row
          _InflammationCountsRow(
            inflammatoryCount: analysis.inflammatoryCount,
            antiInflammatoryCount: analysis.antiInflammatoryCount,
            neutralCount: analysis.neutralCount,
            isDark: widget.isDark,
          ),

          const SizedBox(height: 16),

          // Ingredients list
          _IngredientsSection(
            ingredients: analysis.ingredientAnalyses,
            isDark: widget.isDark,
            showFullList: widget.showFullList,
          ),

          // Recommendation (if available)
          if (analysis.recommendation != null) ...[
            Divider(height: 24, color: cardBorder),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _RecommendationCard(
                recommendation: analysis.recommendation!,
                isDark: widget.isDark,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Loading state card
class _InflammationLoadingCard extends StatelessWidget {
  final bool isDark;

  const _InflammationLoadingCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: teal,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analyzing ingredients...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.textPrimary
                        : AppColorsLight.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'AI is checking for inflammatory compounds',
                  style: TextStyle(fontSize: 12, color: textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Error state card
class _InflammationErrorCard extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  final bool isDark;

  const _InflammationErrorCard({
    required this.error,
    required this.onRetry,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 24),
          const SizedBox(height: 8),
          Text(
            'Could not analyze ingredients',
            style: TextStyle(fontSize: 13, color: textMuted),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

/// Score header with visual indicator
class _InflammationScoreHeader extends StatelessWidget {
  final int score;
  final String description;
  final bool isDark;

  const _InflammationScoreHeader({
    required this.score,
    required this.description,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    // Color based on score (lower = healthier = green, higher = inflammatory = red)
    Color scoreColor;
    if (score <= 3) {
      scoreColor = InflammationColors.antiInflammatory;
    } else if (score <= 6) {
      scoreColor = AppColors.warning;
    } else {
      scoreColor = InflammationColors.inflammatory;
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Score circle
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: scoreColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: scoreColor, width: 2),
            ),
            child: Center(
              child: Text(
                '$score',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: scoreColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inflammation Score',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.science_outlined, color: scoreColor, size: 24),
        ],
      ),
    );
  }
}

/// Row showing counts of each ingredient type
class _InflammationCountsRow extends StatelessWidget {
  final int inflammatoryCount;
  final int antiInflammatoryCount;
  final int neutralCount;
  final bool isDark;

  const _InflammationCountsRow({
    required this.inflammatoryCount,
    required this.antiInflammatoryCount,
    required this.neutralCount,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _CountChip(
            count: antiInflammatoryCount,
            label: 'Good',
            color: InflammationColors.antiInflammatory,
            icon: Icons.thumb_up_outlined,
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _CountChip(
            count: neutralCount,
            label: 'Neutral',
            color: InflammationColors.neutral,
            icon: Icons.remove,
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _CountChip(
            count: inflammatoryCount,
            label: 'Concern',
            color: InflammationColors.inflammatory,
            icon: Icons.warning_amber_outlined,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

/// Count chip widget
class _CountChip extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final IconData icon;
  final bool isDark;

  const _CountChip({
    required this.count,
    required this.label,
    required this.color,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Section showing all ingredients with color coding
class _IngredientsSection extends StatefulWidget {
  final List<AnalyzedIngredient> ingredients;
  final bool isDark;
  final bool showFullList;

  const _IngredientsSection({
    required this.ingredients,
    required this.isDark,
    required this.showFullList,
  });

  @override
  State<_IngredientsSection> createState() => _IngredientsSectionState();
}

class _IngredientsSectionState extends State<_IngredientsSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        widget.isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final teal = widget.isDark ? AppColors.teal : AppColorsLight.teal;

    // Sort ingredients: inflammatory first, then neutral, then anti-inflammatory
    final sortedIngredients = List<AnalyzedIngredient>.from(widget.ingredients)
      ..sort((a, b) {
        final order = {
          InflammationType.inflammatory: 0,
          InflammationType.additive: 1,
          InflammationType.neutral: 2,
          InflammationType.unknown: 3,
          InflammationType.antiInflammatory: 4,
        };
        return (order[a.type] ?? 3).compareTo(order[b.type] ?? 3);
      });

    final displayCount = (widget.showFullList || _expanded)
        ? sortedIngredients.length
        : sortedIngredients.length.clamp(0, 6);
    final hasMore = sortedIngredients.length > 6 && !widget.showFullList;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ingredients Analysis',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sortedIngredients
                .take(displayCount)
                .map((ingredient) => _IngredientChip(
                      ingredient: ingredient,
                      isDark: widget.isDark,
                    ))
                .toList(),
          ),
          if (hasMore) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _expanded
                        ? 'Show less'
                        : 'Show ${sortedIngredients.length - 6} more',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: teal,
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: teal,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Individual ingredient chip with color coding
class _IngredientChip extends StatelessWidget {
  final AnalyzedIngredient ingredient;
  final bool isDark;

  const _IngredientChip({
    required this.ingredient,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color = InflammationColors.getColor(ingredient.type);

    return Tooltip(
      message: ingredient.reason,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              ingredient.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.textPrimary
                    : AppColorsLight.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Recommendation card
class _RecommendationCard extends StatelessWidget {
  final String recommendation;
  final bool isDark;

  const _RecommendationCard({
    required this.recommendation,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: teal.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: teal.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, size: 18, color: teal),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              recommendation,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.textPrimary
                    : AppColorsLight.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
