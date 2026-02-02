import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/trophy.dart';
import '../models/trophy_filter_state.dart';

/// Provider for trophy filter state
final trophyFilterProvider =
    StateNotifierProvider<TrophyFilterNotifier, TrophyFilterState>((ref) {
  return TrophyFilterNotifier();
});

/// State notifier for managing trophy filters
class TrophyFilterNotifier extends StateNotifier<TrophyFilterState> {
  TrophyFilterNotifier() : super(const TrophyFilterState());

  /// Toggle a tier filter
  void toggleTier(String tier) {
    final newTiers = Set<String>.from(state.selectedTiers);
    if (newTiers.contains(tier)) {
      newTiers.remove(tier);
    } else {
      newTiers.add(tier);
    }
    state = state.copyWith(selectedTiers: newTiers);
  }

  /// Toggle a muscle group filter
  void toggleMuscleGroup(String group) {
    final newGroups = Set<String>.from(state.selectedMuscleGroups);
    if (newGroups.contains(group)) {
      newGroups.remove(group);
    } else {
      newGroups.add(group);
    }
    state = state.copyWith(selectedMuscleGroups: newGroups);
  }

  /// Toggle a category filter
  void toggleCategory(TrophyCategory category) {
    final newCategories = Set<TrophyCategory>.from(state.selectedCategories);
    if (newCategories.contains(category)) {
      newCategories.remove(category);
    } else {
      newCategories.add(category);
    }
    state = state.copyWith(selectedCategories: newCategories);
  }

  /// Set the sort option
  void setSortOption(TrophySortOption option) {
    state = state.copyWith(sortOption: option);
  }

  /// Set search query
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Reset all filters
  void resetFilters() {
    state = const TrophyFilterState();
  }

  /// Apply filters to a list of trophies
  List<TrophyProgress> applyFilters(List<TrophyProgress> trophies) {
    var filtered = trophies.toList();

    // Apply search filter
    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      filtered = filtered.where((t) {
        final name = t.displayName.toLowerCase();
        final desc = t.displayDescription.toLowerCase();
        final category = t.trophy.trophyCategory.displayName.toLowerCase();
        return name.contains(query) ||
            desc.contains(query) ||
            category.contains(query);
      }).toList();
    }

    // Apply tier filter
    if (state.selectedTiers.isNotEmpty) {
      filtered = filtered.where((t) {
        if (t.isMystery && state.selectedTiers.contains('mystery')) {
          return true;
        }
        return state.selectedTiers.contains(t.trophy.tier.toLowerCase());
      }).toList();
    }

    // Apply muscle group filter
    if (state.selectedMuscleGroups.isNotEmpty) {
      filtered = filtered.where((t) {
        final group = t.muscleGroup;
        return group != null && state.selectedMuscleGroups.contains(group);
      }).toList();
    }

    // Apply category filter
    if (state.selectedCategories.isNotEmpty) {
      filtered = filtered.where((t) {
        return state.selectedCategories.contains(t.trophy.trophyCategory);
      }).toList();
    }

    // Apply sort
    switch (state.sortOption) {
      case TrophySortOption.progressDesc:
        filtered.sort((a, b) {
          // Earned first
          if (a.isEarned != b.isEarned) {
            return a.isEarned ? -1 : 1;
          }
          // Then by progress
          return b.progressPercentage.compareTo(a.progressPercentage);
        });
        break;
      case TrophySortOption.difficultyAsc:
        filtered.sort((a, b) {
          // Earned first
          if (a.isEarned != b.isEarned) {
            return a.isEarned ? -1 : 1;
          }
          // Mystery trophies last in difficulty sort
          if (a.isMystery != b.isMystery) {
            return a.isMystery ? 1 : -1;
          }
          // Then by tier level
          return a.trophy.tierLevel.compareTo(b.trophy.tierLevel);
        });
        break;
      case TrophySortOption.xpRewardDesc:
        filtered.sort((a, b) {
          // Earned first
          if (a.isEarned != b.isEarned) {
            return a.isEarned ? -1 : 1;
          }
          // Mystery trophies last (unknown XP)
          if (a.isMystery != b.isMystery) {
            return a.isMystery ? 1 : -1;
          }
          // Then by XP reward
          return b.trophy.xpReward.compareTo(a.trophy.xpReward);
        });
        break;
      case TrophySortOption.recentlyEarned:
        filtered.sort((a, b) {
          // Earned trophies first, sorted by earned date
          if (a.isEarned && b.isEarned) {
            if (a.earnedAt == null) return 1;
            if (b.earnedAt == null) return -1;
            return b.earnedAt!.compareTo(a.earnedAt!);
          }
          if (a.isEarned) return -1;
          if (b.isEarned) return 1;
          // Then by progress
          return b.progressPercentage.compareTo(a.progressPercentage);
        });
        break;
    }

    return filtered;
  }
}
