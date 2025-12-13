import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/theme_provider.dart';
import '../../data/models/exercise.dart';
import '../../data/models/program.dart';
import '../../data/services/api_client.dart';

// ═══════════════════════════════════════════════════════════════════
// EXERCISE FILTER OPTIONS MODEL
// ═══════════════════════════════════════════════════════════════════

class FilterOption {
  final String name;
  final int count;

  FilterOption({required this.name, required this.count});

  factory FilterOption.fromJson(Map<String, dynamic> json) {
    return FilterOption(
      name: json['name'] as String,
      count: json['count'] as int,
    );
  }
}

class ExerciseFilterOptions {
  final List<FilterOption> bodyParts;
  final List<FilterOption> equipment;
  final List<FilterOption> exerciseTypes;
  final int totalExercises;

  ExerciseFilterOptions({
    required this.bodyParts,
    required this.equipment,
    required this.exerciseTypes,
    required this.totalExercises,
  });

  factory ExerciseFilterOptions.fromJson(Map<String, dynamic> json) {
    return ExerciseFilterOptions(
      bodyParts: (json['body_parts'] as List)
          .map((e) => FilterOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      equipment: (json['equipment'] as List)
          .map((e) => FilterOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      exerciseTypes: (json['exercise_types'] as List)
          .map((e) => FilterOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalExercises: json['total_exercises'] as int,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// EXERCISE PROVIDERS
// ═══════════════════════════════════════════════════════════════════

final exercisesProvider = FutureProvider.autoDispose<List<LibraryExercise>>((ref) async {
  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.get('${ApiConstants.library}/exercises');

  if (response.statusCode == 200) {
    final data = response.data as List;
    return data.map((e) => LibraryExercise.fromJson(e as Map<String, dynamic>)).toList();
  }
  throw Exception('Failed to load exercises');
});

final filterOptionsProvider = FutureProvider.autoDispose<ExerciseFilterOptions>((ref) async {
  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.get('${ApiConstants.library}/exercises/filter-options');

  if (response.statusCode == 200) {
    return ExerciseFilterOptions.fromJson(response.data as Map<String, dynamic>);
  }
  throw Exception('Failed to load filter options');
});

final exerciseSearchProvider = StateProvider<String>((ref) => '');
final selectedMuscleGroupProvider = StateProvider<String?>((ref) => null);
final selectedEquipmentProvider = StateProvider<String?>((ref) => null);
final selectedExerciseTypeProvider = StateProvider<String?>((ref) => null);

// ═══════════════════════════════════════════════════════════════════
// PROGRAM PROVIDERS
// ═══════════════════════════════════════════════════════════════════

final programsProvider = FutureProvider.autoDispose<List<LibraryProgram>>((ref) async {
  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.get('${ApiConstants.library}/programs');

  if (response.statusCode == 200) {
    final data = response.data as List;
    return data.map((e) => LibraryProgram.fromJson(e as Map<String, dynamic>)).toList();
  }
  throw Exception('Failed to load programs');
});

final programCategoriesProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.get('${ApiConstants.library}/programs/categories');

  if (response.statusCode == 200) {
    final data = response.data as List;
    return data.map((e) => e['name'] as String).toList();
  }
  throw Exception('Failed to load categories');
});

final programSearchProvider = StateProvider<String>((ref) => '');
final selectedProgramCategoryProvider = StateProvider<String?>((ref) => null);

// ═══════════════════════════════════════════════════════════════════
// MAIN LIBRARY SCREEN WITH TABS
// ═══════════════════════════════════════════════════════════════════

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Library',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Browse exercises and programs',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
                        ),
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: elevated,
                borderRadius: BorderRadius.circular(12),
                border: isDark ? null : Border.all(color: AppColorsLight.cardBorder),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: cyan.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                labelColor: cyan,
                unselectedLabelColor: textMuted,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 14,
                ),
                dividerColor: Colors.transparent,
                padding: const EdgeInsets.all(4),
                tabs: const [
                  Tab(text: 'Exercises'),
                  Tab(text: 'Programs'),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _ExercisesTab(),
                  _ProgramsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// EXERCISES TAB
// ═══════════════════════════════════════════════════════════════════

class _ExercisesTab extends ConsumerWidget {
  const _ExercisesTab();

  int _getActiveFilterCount(WidgetRef ref) {
    int count = 0;
    if (ref.read(selectedMuscleGroupProvider) != null) count++;
    if (ref.read(selectedEquipmentProvider) != null) count++;
    if (ref.read(selectedExerciseTypeProvider) != null) count++;
    return count;
  }

  void _showFilterSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _ExerciseFilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(exercisesProvider);
    final searchQuery = ref.watch(exerciseSearchProvider);
    final selectedMuscle = ref.watch(selectedMuscleGroupProvider);
    final selectedEquipment = ref.watch(selectedEquipmentProvider);
    final selectedType = ref.watch(selectedExerciseTypeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final activeFilters = _getActiveFilterCount(ref);

    return Column(
      children: [
        // Search bar with filter button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) =>
                      ref.read(exerciseSearchProvider.notifier).state = value,
                  decoration: InputDecoration(
                    hintText: 'Search exercises...',
                    prefixIcon: Icon(Icons.search, color: textMuted),
                    filled: true,
                    fillColor: elevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: isDark ? BorderSide.none : BorderSide(color: AppColorsLight.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: isDark ? BorderSide.none : BorderSide(color: AppColorsLight.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cyan),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Filter button
              GestureDetector(
                onTap: () => _showFilterSheet(context, ref),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: activeFilters > 0 ? cyan.withOpacity(0.2) : elevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: activeFilters > 0 ? cyan : (isDark ? Colors.transparent : AppColorsLight.cardBorder),
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.tune,
                        color: activeFilters > 0 ? cyan : textMuted,
                      ),
                      if (activeFilters > 0)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: cyan,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '$activeFilters',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Active filter chips (show currently applied filters)
        if (selectedMuscle != null || selectedEquipment != null || selectedType != null)
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                if (selectedMuscle != null)
                  _ActiveFilterChip(
                    label: selectedMuscle,
                    onRemove: () => ref.read(selectedMuscleGroupProvider.notifier).state = null,
                  ),
                if (selectedEquipment != null)
                  _ActiveFilterChip(
                    label: selectedEquipment,
                    onRemove: () => ref.read(selectedEquipmentProvider.notifier).state = null,
                  ),
                if (selectedType != null)
                  _ActiveFilterChip(
                    label: selectedType,
                    onRemove: () => ref.read(selectedExerciseTypeProvider.notifier).state = null,
                  ),
                // Clear all
                if (activeFilters > 1)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: GestureDetector(
                      onTap: () {
                        ref.read(selectedMuscleGroupProvider.notifier).state = null;
                        ref.read(selectedEquipmentProvider.notifier).state = null;
                        ref.read(selectedExerciseTypeProvider.notifier).state = null;
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: textMuted.withOpacity(0.5)),
                        ),
                        child: Text(
                          'Clear all',
                          style: TextStyle(
                            fontSize: 12,
                            color: textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

        if (selectedMuscle != null || selectedEquipment != null || selectedType != null)
          const SizedBox(height: 8),

        // Exercise list
        Expanded(
          child: exercisesAsync.when(
            loading: () => Center(
              child: CircularProgressIndicator(color: cyan),
            ),
            error: (e, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: isDark ? AppColors.error : AppColorsLight.error,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text('Failed to load exercises: $e'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.refresh(exercisesProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (exercises) {
              var filtered = exercises;

              // Apply search filter
              if (searchQuery.isNotEmpty) {
                filtered = filtered
                    .where((e) =>
                        e.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                        (e.muscleGroup?.toLowerCase().contains(searchQuery.toLowerCase()) ??
                            false) ||
                        (e.equipmentValue?.toLowerCase().contains(searchQuery.toLowerCase()) ??
                            false))
                    .toList();
              }

              // Apply muscle group filter
              if (selectedMuscle != null) {
                filtered = filtered
                    .where((e) => e.muscleGroup?.toLowerCase() == selectedMuscle.toLowerCase())
                    .toList();
              }

              // Apply equipment filter
              if (selectedEquipment != null) {
                filtered = filtered
                    .where((e) {
                      final equipList = e.equipment;
                      if (equipList == null) return false;
                      return equipList.any((eq) => eq.toLowerCase() == selectedEquipment.toLowerCase());
                    })
                    .toList();
              }

              // Apply exercise type filter (based on category or derived from video)
              if (selectedType != null) {
                filtered = filtered
                    .where((e) {
                      // Check category field
                      if (e.category != null && e.category!.toLowerCase() == selectedType.toLowerCase()) {
                        return true;
                      }
                      // Match based on exercise name patterns for types
                      final nameLower = e.name.toLowerCase();
                      final typeLower = selectedType.toLowerCase();
                      if (typeLower == 'yoga' && (nameLower.contains('yoga') || nameLower.contains('pose'))) {
                        return true;
                      }
                      if (typeLower == 'stretching' && (nameLower.contains('stretch') || nameLower.contains('mobility'))) {
                        return true;
                      }
                      if (typeLower == 'cardio' && (nameLower.contains('cardio') || nameLower.contains('hiit') || nameLower.contains('jump') || nameLower.contains('run'))) {
                        return true;
                      }
                      if (typeLower == 'strength' && (nameLower.contains('press') || nameLower.contains('curl') || nameLower.contains('row') || nameLower.contains('squat') || nameLower.contains('deadlift'))) {
                        return true;
                      }
                      return false;
                    })
                    .toList();
              }

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        color: textMuted,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      const Text('No exercises found'),
                      if (searchQuery.isNotEmpty || activeFilters > 0)
                        TextButton(
                          onPressed: () {
                            ref.read(exerciseSearchProvider.notifier).state = '';
                            ref.read(selectedMuscleGroupProvider.notifier).state = null;
                            ref.read(selectedEquipmentProvider.notifier).state = null;
                            ref.read(selectedExerciseTypeProvider.notifier).state = null;
                          },
                          child: const Text('Clear filters'),
                        ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final exercise = filtered[index];
                  return _ExerciseCard(exercise: exercise)
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: index * 50));
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// ACTIVE FILTER CHIP
// ═══════════════════════════════════════════════════════════════════

class _ActiveFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _ActiveFilterChip({
    required this.label,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: cyan.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cyan),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: cyan,
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onRemove,
              child: Icon(
                Icons.close,
                size: 14,
                color: cyan,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// EXERCISE FILTER SHEET
// ═══════════════════════════════════════════════════════════════════

class _ExerciseFilterSheet extends ConsumerWidget {
  const _ExerciseFilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterOptionsAsync = ref.watch(filterOptionsProvider);
    final selectedMuscle = ref.watch(selectedMuscleGroupProvider);
    final selectedEquipment = ref.watch(selectedEquipmentProvider);
    final selectedType = ref.watch(selectedExerciseTypeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBackground = isDark ? AppColors.nearBlack : AppColorsLight.pureWhite;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;
    final success = isDark ? AppColors.success : AppColorsLight.success;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: sheetBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filters',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(selectedMuscleGroupProvider.notifier).state = null;
                      ref.read(selectedEquipmentProvider.notifier).state = null;
                      ref.read(selectedExerciseTypeProvider.notifier).state = null;
                    },
                    child: Text(
                      'Clear all',
                      style: TextStyle(color: cyan),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Filter content
            Expanded(
              child: filterOptionsAsync.when(
                loading: () => Center(
                  child: CircularProgressIndicator(color: cyan),
                ),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: textMuted, size: 48),
                      const SizedBox(height: 16),
                      Text('Failed to load filters', style: TextStyle(color: textMuted)),
                      TextButton(
                        onPressed: () => ref.refresh(filterOptionsProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (filterOptions) {
                  return SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Body Part / Muscle Group section
                        _FilterSection(
                          title: 'BODY PART',
                          icon: Icons.accessibility_new,
                          color: purple,
                          options: filterOptions.bodyParts,
                          selectedValue: selectedMuscle,
                          onSelect: (value) {
                            ref.read(selectedMuscleGroupProvider.notifier).state =
                                selectedMuscle == value ? null : value;
                          },
                        ),

                        const SizedBox(height: 24),

                        // Equipment section
                        _FilterSection(
                          title: 'EQUIPMENT',
                          icon: Icons.fitness_center,
                          color: cyan,
                          options: filterOptions.equipment,
                          selectedValue: selectedEquipment,
                          onSelect: (value) {
                            ref.read(selectedEquipmentProvider.notifier).state =
                                selectedEquipment == value ? null : value;
                          },
                        ),

                        const SizedBox(height: 24),

                        // Exercise Type section
                        _FilterSection(
                          title: 'EXERCISE TYPE',
                          icon: Icons.category,
                          color: success,
                          options: filterOptions.exerciseTypes,
                          selectedValue: selectedType,
                          onSelect: (value) {
                            ref.read(selectedExerciseTypeProvider.notifier).state =
                                selectedType == value ? null : value;
                          },
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Apply button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// FILTER SECTION
// ═══════════════════════════════════════════════════════════════════

class _FilterSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<FilterOption> options;
  final String? selectedValue;
  final Function(String) onSelect;

  const _FilterSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.options,
    required this.selectedValue,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textMuted,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Options wrap
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selectedValue?.toLowerCase() == option.name.toLowerCase();
            return GestureDetector(
              onTap: () => onSelect(option.name),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? color.withOpacity(0.2) : elevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? color : (isDark ? Colors.transparent : AppColorsLight.cardBorder),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      option.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? color : textSecondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? color.withOpacity(0.3) : textMuted.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${option.count}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? color : textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// PROGRAMS TAB
// ═══════════════════════════════════════════════════════════════════

class _ProgramsTab extends ConsumerWidget {
  const _ProgramsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programsAsync = ref.watch(programsProvider);
    final categoriesAsync = ref.watch(programCategoriesProvider);
    final searchQuery = ref.watch(programSearchProvider);
    final selectedCategory = ref.watch(selectedProgramCategoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            onChanged: (value) =>
                ref.read(programSearchProvider.notifier).state = value,
            decoration: InputDecoration(
              hintText: 'Search programs...',
              prefixIcon: Icon(Icons.search, color: textMuted),
              filled: true,
              fillColor: elevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: isDark ? BorderSide.none : BorderSide(color: AppColorsLight.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: isDark ? BorderSide.none : BorderSide(color: AppColorsLight.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cyan),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Category filter chips
        SizedBox(
          height: 40,
          child: categoriesAsync.when(
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
            data: (categories) {
              return ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _FilterChip(
                    label: 'All',
                    isSelected: selectedCategory == null,
                    onTap: () {
                      ref.read(selectedProgramCategoryProvider.notifier).state = null;
                    },
                  ),
                  ...categories.map((category) => _FilterChip(
                        label: category,
                        isSelected: selectedCategory == category,
                        onTap: () {
                          ref.read(selectedProgramCategoryProvider.notifier).state =
                              selectedCategory == category ? null : category;
                        },
                      )),
                ],
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        // Programs list
        Expanded(
          child: programsAsync.when(
            loading: () => Center(
              child: CircularProgressIndicator(color: cyan),
            ),
            error: (e, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: isDark ? AppColors.error : AppColorsLight.error,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text('Failed to load programs: $e'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.refresh(programsProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (programs) {
              var filtered = programs;

              if (searchQuery.isNotEmpty) {
                filtered = filtered
                    .where((p) =>
                        p.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                        p.category.toLowerCase().contains(searchQuery.toLowerCase()) ||
                        (p.celebrityName?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
                        (p.goals?.any((g) => g.toLowerCase().contains(searchQuery.toLowerCase())) ?? false))
                    .toList();
              }

              if (selectedCategory != null) {
                filtered = filtered
                    .where((p) => p.category == selectedCategory)
                    .toList();
              }

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.fitness_center,
                        color: textMuted,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      const Text('No programs found'),
                      if (searchQuery.isNotEmpty || selectedCategory != null)
                        TextButton(
                          onPressed: () {
                            ref.read(programSearchProvider.notifier).state = '';
                            ref.read(selectedProgramCategoryProvider.notifier).state = null;
                          },
                          child: const Text('Clear filters'),
                        ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final program = filtered[index];
                  return _ProgramCard(program: program)
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: index * 50));
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════════

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? cyan.withOpacity(0.2) : elevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? cyan : cardBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? cyan : textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// EXERCISE CARD
// ═══════════════════════════════════════════════════════════════════

class _ExerciseCard extends StatelessWidget {
  final LibraryExercise exercise;

  const _ExerciseCard({required this.exercise});

  IconData _getBodyPartIcon(String? bodyPart) {
    switch (bodyPart?.toLowerCase()) {
      case 'chest':
        return Icons.fitness_center;
      case 'back':
        return Icons.airline_seat_flat;
      case 'shoulders':
        return Icons.accessibility_new;
      case 'biceps':
      case 'triceps':
      case 'arms':
        return Icons.sports_martial_arts;
      case 'core':
      case 'abdominals':
        return Icons.self_improvement;
      case 'quadriceps':
      case 'legs':
      case 'glutes':
      case 'hamstrings':
      case 'calves':
        return Icons.directions_run;
      case 'cardio':
      case 'other':
        return Icons.monitor_heart;
      case 'neck':
        return Icons.face;
      default:
        return Icons.fitness_center;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;
    final hasVideo = exercise.videoUrl != null && exercise.videoUrl!.isNotEmpty;

    return GestureDetector(
      onTap: () => _showExerciseDetail(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(16),
          border: isDark ? null : Border.all(color: AppColorsLight.cardBorder),
        ),
        child: Row(
          children: [
            // Thumbnail with video indicator
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    purple.withOpacity(0.3),
                    cyan.withOpacity(0.2),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Body part icon
                  Icon(
                    _getBodyPartIcon(exercise.bodyPart),
                    size: 36,
                    color: purple.withOpacity(0.8),
                  ),
                  // Video play indicator
                  if (hasVideo)
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: cyan,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          size: 14,
                          color: Colors.black,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (exercise.muscleGroup != null) ...[
                          _InfoBadge(
                            icon: Icons.accessibility_new,
                            text: exercise.muscleGroup!,
                            color: purple,
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (exercise.difficulty != null)
                          _InfoBadge(
                            icon: Icons.signal_cellular_alt,
                            text: exercise.difficulty!,
                            color: AppColors.getDifficultyColor(exercise.difficulty!),
                          ),
                      ],
                    ),
                    if (exercise.equipment != null &&
                        exercise.equipment!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        exercise.equipment!.take(2).join(', '),
                        style: TextStyle(
                          fontSize: 11,
                          color: textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Arrow
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                Icons.chevron_right,
                color: textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExerciseDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ExerciseDetailSheet(exercise: exercise),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// PROGRAM CARD
// ═══════════════════════════════════════════════════════════════════

class _ProgramCard extends StatelessWidget {
  final LibraryProgram program;

  const _ProgramCard({required this.program});

  Color _getCategoryColor(String category, bool isDark) {
    switch (category.toLowerCase()) {
      case 'celebrity workout':
        return isDark ? AppColors.purple : AppColorsLight.purple;
      case 'goal-based':
        return isDark ? AppColors.cyan : AppColorsLight.cyan;
      case 'sport training':
        return isDark ? AppColors.success : AppColorsLight.success;
      default:
        return isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'celebrity workout':
        return Icons.star;
      case 'goal-based':
        return Icons.track_changes;
      case 'sport training':
        return Icons.sports;
      default:
        return Icons.fitness_center;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final categoryColor = _getCategoryColor(program.category, isDark);

    return GestureDetector(
      onTap: () => _showProgramDetail(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(16),
          border: isDark ? null : Border.all(color: AppColorsLight.cardBorder),
        ),
        child: Row(
          children: [
            // Category icon area
            Container(
              width: 80,
              height: 100,
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.15),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: Center(
                child: Icon(
                  _getCategoryIcon(program.category),
                  size: 32,
                  color: categoryColor,
                ),
              ),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Program name
                    Text(
                      program.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Category & Difficulty badges
                    Row(
                      children: [
                        _InfoBadge(
                          icon: _getCategoryIcon(program.category),
                          text: program.category,
                          color: categoryColor,
                        ),
                        if (program.difficultyLevel != null) ...[
                          const SizedBox(width: 8),
                          _InfoBadge(
                            icon: Icons.signal_cellular_alt,
                            text: program.difficultyLevel!,
                            color: AppColors.getDifficultyColor(program.difficultyLevel!),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Duration & Sessions
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 12, color: textMuted),
                        const SizedBox(width: 4),
                        Text(
                          program.durationDisplay,
                          style: TextStyle(fontSize: 11, color: textSecondary),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.repeat, size: 12, color: textMuted),
                        const SizedBox(width: 4),
                        Text(
                          program.sessionsDisplay,
                          style: TextStyle(fontSize: 11, color: textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Arrow
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                Icons.chevron_right,
                color: textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProgramDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProgramDetailSheet(program: program),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// INFO BADGE (Shared)
// ═══════════════════════════════════════════════════════════════════

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoBadge({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// EXERCISE DETAIL SHEET
// ═══════════════════════════════════════════════════════════════════

class _ExerciseDetailSheet extends ConsumerStatefulWidget {
  final LibraryExercise exercise;

  const _ExerciseDetailSheet({required this.exercise});

  @override
  ConsumerState<_ExerciseDetailSheet> createState() => _ExerciseDetailSheetState();
}

class _ExerciseDetailSheetState extends ConsumerState<_ExerciseDetailSheet> {
  VideoPlayerController? _videoController;
  bool _isLoadingVideo = true;
  bool _videoInitialized = false;
  String? _videoError;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _loadVideo() async {
    // Use original_name to fetch the video
    final exerciseName = widget.exercise.originalName ?? widget.exercise.name;
    if (exerciseName.isEmpty) {
      setState(() {
        _isLoadingVideo = false;
        _videoError = 'No exercise name';
      });
      return;
    }

    try {
      final apiClient = ref.read(apiClientProvider);
      final videoResponse = await apiClient.get(
        '/videos/by-exercise/${Uri.encodeComponent(exerciseName)}',
      );

      if (videoResponse.statusCode == 200 && videoResponse.data != null) {
        final videoUrl = videoResponse.data['url'] as String?;
        if (videoUrl != null && mounted) {
          _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
          await _videoController!.initialize();
          _videoController!.setLooping(true);
          _videoController!.setVolume(0);
          _videoController!.play();
          setState(() {
            _videoInitialized = true;
            _isLoadingVideo = false;
          });
        }
      } else {
        setState(() {
          _isLoadingVideo = false;
          _videoError = 'Video not available';
        });
      }
    } catch (e) {
      debugPrint('Error loading video: $e');
      if (mounted) {
        setState(() {
          _isLoadingVideo = false;
          _videoError = 'Failed to load video';
        });
      }
    }
  }

  void _toggleVideo() {
    if (_videoController == null) return;
    if (_videoController!.value.isPlaying) {
      _videoController!.pause();
    } else {
      _videoController!.play();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercise;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBackground = isDark ? AppColors.nearBlack : AppColorsLight.pureWhite;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: sheetBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Video Player
              GestureDetector(
                onTap: _toggleVideo,
                child: Container(
                  width: double.infinity,
                  height: 300,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: elevated,
                    borderRadius: BorderRadius.circular(16),
                    border: isDark ? null : Border.all(color: AppColorsLight.cardBorder),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: _buildVideoContent(cyan, textMuted, purple),
                ),
              ),

              const SizedBox(height: 20),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  exercise.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),

              const SizedBox(height: 12),

              // Badges
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (exercise.muscleGroup != null)
                      _DetailBadge(
                        icon: Icons.accessibility_new,
                        label: 'Muscle',
                        value: exercise.muscleGroup!,
                        color: purple,
                      ),
                    if (exercise.difficulty != null)
                      _DetailBadge(
                        icon: Icons.signal_cellular_alt,
                        label: 'Level',
                        value: exercise.difficulty!,
                        color: AppColors.getDifficultyColor(exercise.difficulty!),
                      ),
                    if (exercise.type != null)
                      _DetailBadge(
                        icon: Icons.category,
                        label: 'Type',
                        value: exercise.type!,
                        color: cyan,
                      ),
                  ],
                ),
              ),

              // Equipment
              if (exercise.equipment != null && exercise.equipment!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EQUIPMENT NEEDED',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textMuted,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: exercise.equipment!.map((eq) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: elevated,
                              borderRadius: BorderRadius.circular(8),
                              border: isDark ? null : Border.all(color: AppColorsLight.cardBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.fitness_center,
                                  size: 14,
                                  color: textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  eq,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],

              // Instructions
              if (exercise.instructions != null &&
                  exercise.instructions!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'INSTRUCTIONS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textMuted,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...exercise.instructions!.asMap().entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: cyan.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${entry.key + 1}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: cyan,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  entry.value,
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoContent(Color cyan, Color textMuted, Color purple) {
    if (_isLoadingVideo) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: cyan),
            const SizedBox(height: 12),
            Text(
              'Loading video...',
              style: TextStyle(color: textMuted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (_videoInitialized && _videoController != null) {
      return Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          ),
          // Play/Pause overlay
          AnimatedOpacity(
            opacity: _videoController!.value.isPlaying ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(12),
              child: Icon(
                Icons.play_arrow,
                size: 48,
                color: cyan,
              ),
            ),
          ),
          // Muted indicator
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.volume_off,
                size: 16,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      );
    }

    // Fallback - no video available
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.videocam_off,
            size: 48,
            color: purple.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            _videoError ?? 'Video not available',
            style: TextStyle(color: textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// PROGRAM DETAIL SHEET
// ═══════════════════════════════════════════════════════════════════

class _ProgramDetailSheet extends StatelessWidget {
  final LibraryProgram program;

  const _ProgramDetailSheet({required this.program});

  Color _getCategoryColor(String category, bool isDark) {
    switch (category.toLowerCase()) {
      case 'celebrity workout':
        return isDark ? AppColors.purple : AppColorsLight.purple;
      case 'goal-based':
        return isDark ? AppColors.cyan : AppColorsLight.cyan;
      case 'sport training':
        return isDark ? AppColors.success : AppColorsLight.success;
      default:
        return isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'celebrity workout':
        return Icons.star;
      case 'goal-based':
        return Icons.track_changes;
      case 'sport training':
        return Icons.sports;
      default:
        return Icons.fitness_center;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBackground = isDark ? AppColors.nearBlack : AppColorsLight.pureWhite;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final categoryColor = _getCategoryColor(program.category, isDark);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: sheetBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Hero area with icon
              Container(
                width: double.infinity,
                height: 150,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      categoryColor.withOpacity(0.3),
                      categoryColor.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: isDark ? null : Border.all(color: AppColorsLight.cardBorder),
                ),
                child: Center(
                  child: Icon(
                    _getCategoryIcon(program.category),
                    size: 64,
                    color: categoryColor,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  program.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),

              // Celebrity name if present
              if (program.celebrityName != null) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Inspired by ${program.celebrityName}',
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Badges
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _DetailBadge(
                      icon: _getCategoryIcon(program.category),
                      label: 'Category',
                      value: program.category,
                      color: categoryColor,
                    ),
                    if (program.difficultyLevel != null)
                      _DetailBadge(
                        icon: Icons.signal_cellular_alt,
                        label: 'Level',
                        value: program.difficultyLevel!,
                        color: AppColors.getDifficultyColor(program.difficultyLevel!),
                      ),
                    if (program.durationWeeks != null)
                      _DetailBadge(
                        icon: Icons.calendar_today,
                        label: 'Duration',
                        value: '${program.durationWeeks} weeks',
                        color: cyan,
                      ),
                    if (program.sessionsPerWeek != null)
                      _DetailBadge(
                        icon: Icons.repeat,
                        label: 'Sessions',
                        value: '${program.sessionsPerWeek}/week',
                        color: cyan,
                      ),
                  ],
                ),
              ),

              // Description
              if (program.description != null && program.description!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DESCRIPTION',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textMuted,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        program.description!,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Goals
              if (program.goals != null && program.goals!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GOALS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textMuted,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: program.goals!.map((goal) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: cyan.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 14,
                                  color: cyan,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  goal,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: cyan,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],

              // Tags
              if (program.tags != null && program.tags!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TAGS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textMuted,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: program.tags!.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: elevated,
                              borderRadius: BorderRadius.circular(16),
                              border: isDark ? null : Border.all(color: AppColorsLight.cardBorder),
                            ),
                            child: Text(
                              '#$tag',
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Start Program button (placeholder)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Program "${program.name}" selected! Feature coming soon.'),
                          backgroundColor: cyan,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cyan,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Start This Program',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// DETAIL BADGE (Shared)
// ═══════════════════════════════════════════════════════════════════

class _DetailBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DetailBadge({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(8),
        border: isDark ? null : Border.all(color: AppColorsLight.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: textMuted,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
