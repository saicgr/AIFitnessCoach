import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/library_providers.dart';
import '../widgets/exercise_search_bar.dart';
import '../widgets/filter_chip_widget.dart';
import '../widgets/program_card.dart';

/// Programs tab content with search, category filter, and list
class ProgramsTab extends ConsumerWidget {
  const ProgramsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programsAsync = ref.watch(programsProvider);
    final categoriesAsync = ref.watch(programCategoriesProvider);
    final searchQuery = ref.watch(programSearchProvider);
    final selectedCategory = ref.watch(selectedProgramCategoryProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Column(
      children: [
        // Search bar
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: ProgramSearchBar(),
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
                  FilterChipWidget(
                    label: 'All',
                    isSelected: selectedCategory == null,
                    onTap: () {
                      ref.read(selectedProgramCategoryProvider.notifier).state =
                          null;
                    },
                  ),
                  ...categories.map((category) => FilterChipWidget(
                        label: category,
                        isSelected: selectedCategory == category,
                        onTap: () {
                          ref
                              .read(selectedProgramCategoryProvider.notifier)
                              .state = selectedCategory == category
                              ? null
                              : category;
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
                        p.name
                            .toLowerCase()
                            .contains(searchQuery.toLowerCase()) ||
                        p.category
                            .toLowerCase()
                            .contains(searchQuery.toLowerCase()) ||
                        (p.celebrityName
                                ?.toLowerCase()
                                .contains(searchQuery.toLowerCase()) ??
                            false) ||
                        (p.goals?.any((g) =>
                                g.toLowerCase().contains(searchQuery.toLowerCase())) ??
                            false))
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
                            ref
                                .read(selectedProgramCategoryProvider.notifier)
                                .state = null;
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
                  return ProgramCard(program: program)
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
