import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/trophy.dart';
import '../../../data/models/trophy_filter_state.dart';
import '../../../data/providers/trophy_filter_provider.dart';
import '../../../data/services/haptic_service.dart';

/// Trophy filter bottom sheet with tier, muscle group, category, and sort options
class TrophyFilterSheet extends ConsumerWidget {
  const TrophyFilterSheet({super.key});

  static const List<String> _tiers = ['bronze', 'silver', 'gold', 'platinum', 'mystery'];
  static const List<String> _muscleGroups = ['Chest', 'Back', 'Shoulders', 'Arms', 'Legs', 'Core'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final filterState = ref.watch(trophyFilterProvider);
    final notifier = ref.read(trophyFilterProvider.notifier);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.1),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: textMuted.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Title
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Icon(Icons.tune, color: textColor, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Filter Trophies',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                        if (filterState.hasActiveFilters)
                          TextButton(
                            onPressed: () {
                              HapticService.light();
                              notifier.resetFilters();
                            },
                            child: const Text('Reset'),
                          ),
                      ],
                    ),
                  ),

                  // Difficulty section
                  _buildSectionHeader('DIFFICULTY', textMuted),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _tiers.map((tier) {
                        final isSelected = filterState.selectedTiers.contains(tier);
                        return _buildFilterChip(
                          label: _getTierLabel(tier),
                          icon: _getTierIcon(tier),
                          isSelected: isSelected,
                          color: _getTierColor(tier),
                          onTap: () {
                            HapticService.light();
                            notifier.toggleTier(tier);
                          },
                          isDark: isDark,
                          textMuted: textMuted,
                          cardBorder: cardBorder,
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Muscle Group section
                  _buildSectionHeader('MUSCLE GROUP', textMuted),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _muscleGroups.map((group) {
                        final isSelected = filterState.selectedMuscleGroups.contains(group);
                        return _buildFilterChip(
                          label: group,
                          icon: _getMuscleIcon(group),
                          isSelected: isSelected,
                          color: AppColors.quickActionWater,
                          onTap: () {
                            HapticService.light();
                            notifier.toggleMuscleGroup(group);
                          },
                          isDark: isDark,
                          textMuted: textMuted,
                          cardBorder: cardBorder,
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Category section
                  _buildSectionHeader('CATEGORY', textMuted),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: TrophyCategory.values.map((category) {
                        final isSelected = filterState.selectedCategories.contains(category);
                        return _buildFilterChip(
                          label: category.displayName,
                          icon: category.icon,
                          isSelected: isSelected,
                          color: AppColors.green,
                          onTap: () {
                            HapticService.light();
                            notifier.toggleCategory(category);
                          },
                          isDark: isDark,
                          textMuted: textMuted,
                          cardBorder: cardBorder,
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Sort by section
                  _buildSectionHeader('SORT BY', textMuted),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: elevatedColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Column(
                        children: TrophySortOption.values.map((option) {
                          final isSelected = filterState.sortOption == option;
                          return RadioListTile<TrophySortOption>(
                            title: Text(
                              option.displayName,
                              style: TextStyle(
                                fontSize: 14,
                                color: isSelected ? textColor : textMuted,
                              ),
                            ),
                            value: option,
                            groupValue: filterState.sortOption,
                            onChanged: (value) {
                              if (value != null) {
                                HapticService.light();
                                notifier.setSortOption(value);
                              }
                            },
                            dense: true,
                            visualDensity: VisualDensity.compact,
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Apply button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: ElevatedButton(
                      onPressed: () {
                        HapticService.medium();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.quickActionWater,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        filterState.hasActiveFilters
                            ? 'Apply ${filterState.activeFilterCount} Filters'
                            : 'Apply Filters',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color textMuted) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          color: textMuted,
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
    required Color textMuted,
    required Color cardBorder,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.2)
              : isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color.withValues(alpha: 0.6) : cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? color : textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTierLabel(String tier) {
    switch (tier) {
      case 'bronze':
        return 'Bronze';
      case 'silver':
        return 'Silver';
      case 'gold':
        return 'Gold';
      case 'platinum':
        return 'Platinum';
      case 'mystery':
        return 'Mystery';
      default:
        return tier;
    }
  }

  String _getTierIcon(String tier) {
    switch (tier) {
      case 'bronze':
        return '🥉';
      case 'silver':
        return '🥈';
      case 'gold':
        return '🥇';
      case 'platinum':
        return '💎';
      case 'mystery':
        return '❓';
      default:
        return '🏆';
    }
  }

  Color _getTierColor(String tier) {
    switch (tier) {
      case 'bronze':
        return const Color(0xFFCD7F32);
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'gold':
        return const Color(0xFFFFD700);
      case 'platinum':
        return const Color(0xFFE5E4E2);
      case 'mystery':
        return AppColors.purple;
      default:
        return AppColors.quickActionWater;
    }
  }

  String _getMuscleIcon(String group) {
    switch (group) {
      case 'Chest':
        return '🫁';
      case 'Back':
        return '🔙';
      case 'Shoulders':
        return '💪';
      case 'Arms':
        return '💪';
      case 'Legs':
        return '🦵';
      case 'Core':
        return '🧘';
      default:
        return '💪';
    }
  }
}
