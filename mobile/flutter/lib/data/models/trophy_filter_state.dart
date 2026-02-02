import 'package:flutter/foundation.dart';
import 'trophy.dart';

/// Sort options for trophy list
enum TrophySortOption {
  progressDesc,    // Progress high to low
  difficultyAsc,   // Bronze -> Platinum
  xpRewardDesc,    // Highest XP first
  recentlyEarned,  // Most recently earned first
}

extension TrophySortOptionExtension on TrophySortOption {
  String get displayName {
    switch (this) {
      case TrophySortOption.progressDesc:
        return 'Progress (High to Low)';
      case TrophySortOption.difficultyAsc:
        return 'Difficulty (Easy to Hard)';
      case TrophySortOption.xpRewardDesc:
        return 'XP Reward (High to Low)';
      case TrophySortOption.recentlyEarned:
        return 'Recently Earned';
    }
  }
}

/// Filter state for trophy room
@immutable
class TrophyFilterState {
  /// Selected tiers: bronze, silver, gold, platinum, mystery
  final Set<String> selectedTiers;

  /// Selected muscle groups: Chest, Back, Shoulders, Arms, Legs, Core
  final Set<String> selectedMuscleGroups;

  /// Selected categories
  final Set<TrophyCategory> selectedCategories;

  /// Current sort option
  final TrophySortOption sortOption;

  /// Search query
  final String searchQuery;

  const TrophyFilterState({
    this.selectedTiers = const {},
    this.selectedMuscleGroups = const {},
    this.selectedCategories = const {},
    this.sortOption = TrophySortOption.progressDesc,
    this.searchQuery = '',
  });

  /// Check if any filters are active
  bool get hasActiveFilters =>
    selectedTiers.isNotEmpty ||
    selectedMuscleGroups.isNotEmpty ||
    selectedCategories.isNotEmpty ||
    searchQuery.isNotEmpty;

  /// Get count of active filters
  int get activeFilterCount {
    int count = 0;
    count += selectedTiers.length;
    count += selectedMuscleGroups.length;
    count += selectedCategories.length;
    if (searchQuery.isNotEmpty) count += 1;
    return count;
  }

  TrophyFilterState copyWith({
    Set<String>? selectedTiers,
    Set<String>? selectedMuscleGroups,
    Set<TrophyCategory>? selectedCategories,
    TrophySortOption? sortOption,
    String? searchQuery,
  }) {
    return TrophyFilterState(
      selectedTiers: selectedTiers ?? this.selectedTiers,
      selectedMuscleGroups: selectedMuscleGroups ?? this.selectedMuscleGroups,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      sortOption: sortOption ?? this.sortOption,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrophyFilterState &&
        setEquals(other.selectedTiers, selectedTiers) &&
        setEquals(other.selectedMuscleGroups, selectedMuscleGroups) &&
        setEquals(other.selectedCategories, selectedCategories) &&
        other.sortOption == sortOption &&
        other.searchQuery == searchQuery;
  }

  @override
  int get hashCode {
    return Object.hash(
      selectedTiers,
      selectedMuscleGroups,
      selectedCategories,
      sortOption,
      searchQuery,
    );
  }
}
