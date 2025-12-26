import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/personal_goals_service.dart';
import '../../../data/providers/goal_suggestions_provider.dart';
import 'suggestion_card.dart';

/// Netflix-style carousel for goal suggestions organized by category
class SuggestionCarousel extends ConsumerWidget {
  final String userId;
  final Function(GoalSuggestionItem) onSuggestionTap;
  final Function(GoalSuggestionItem) onAccept;
  final Function(GoalSuggestionItem) onDismiss;

  const SuggestionCarousel({
    super.key,
    required this.userId,
    required this.onSuggestionTap,
    required this.onAccept,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestionsAsync = ref.watch(
      goalSuggestionsProvider(GoalSuggestionsParams(userId: userId)),
    );

    return suggestionsAsync.when(
      data: (response) {
        if (response.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 8),
            ...response.categories.map((category) => _buildCategoryRow(
                  context,
                  category,
                )),
            const SizedBox(height: 16),
          ],
        );
      },
      loading: () => _buildLoadingState(context),
      error: (error, stack) => _buildErrorState(context, ref),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return Row(
      children: [
        const Icon(Icons.lightbulb_outline, color: AppColors.orange, size: 20),
        const SizedBox(width: 8),
        Text(
          'Suggested Goals',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const Spacer(),
        Icon(
          Icons.auto_awesome,
          size: 16,
          color: AppColors.purple.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 4),
        Text(
          'AI',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.purple.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryRow(BuildContext context, SuggestionCategoryGroup category) {
    if (category.suggestions.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    // Parse accent color
    final accentColor = _parseColor(category.accentColor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        // Category header
        Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              _getCategoryIcon(category.categoryIcon),
              size: 18,
              color: accentColor,
            ),
            const SizedBox(width: 8),
            Text(
              category.categoryTitle,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${category.suggestions.length}',
              style: TextStyle(
                fontSize: 12,
                color: textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Horizontal scroll of cards
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: category.suggestions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final suggestion = category.suggestions[index];
              return SuggestionCard(
                suggestion: suggestion,
                accentColor: accentColor,
                onTap: () => onSuggestionTap(suggestion),
                onAccept: () => onAccept(suggestion),
                onDismiss: () => onDismiss(suggestion),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) => _buildShimmerCard(context),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Container(
      width: 200,
      height: 140,
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: textSecondary, size: 20),
          const SizedBox(width: 8),
          Text(
            'Could not load suggestions',
            style: TextStyle(color: textSecondary, fontSize: 14),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              ref.invalidate(goalSuggestionsProvider(
                GoalSuggestionsParams(userId: userId, forceRefresh: true),
              ));
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceAll('#', '0xFF')));
    } catch (_) {
      return AppColors.cyan;
    }
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'emoji_events':
        return Icons.emoji_events;
      case 'people':
        return Icons.people;
      case 'explore':
        return Icons.explore;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'trending_up':
        return Icons.trending_up;
      default:
        return Icons.flag;
    }
  }
}
