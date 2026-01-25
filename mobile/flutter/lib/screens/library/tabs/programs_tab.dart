import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/library_providers.dart';
import '../widgets/exercise_search_bar.dart';
import '../widgets/filter_chip_widget.dart';
import '../widgets/program_card.dart';
import '../components/programs_intro_sheet.dart';

/// Programs tab content with search, category filter, and list
class ProgramsTab extends ConsumerStatefulWidget {
  const ProgramsTab({super.key});

  @override
  ConsumerState<ProgramsTab> createState() => _ProgramsTabState();
}

class _ProgramsTabState extends ConsumerState<ProgramsTab> {
  bool _hasShownIntro = false;

  @override
  void initState() {
    super.initState();
    // Show intro sheet after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasShownIntro && mounted) {
        _showIntroSheet();
        _hasShownIntro = true;
      }
    });
  }

  void _showIntroSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (context) => const ProgramsIntroSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final programsAsync = ref.watch(programsProvider);
    final categoriesAsync = ref.watch(programCategoriesProvider);
    final searchQuery = ref.watch(programSearchProvider);
    final selectedCategory = ref.watch(selectedProgramCategoryProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final orange = isDark ? AppColors.orange : AppColorsLight.orange;

    return Column(
      children: [
        // Info banner
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: orange.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: orange, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Programs are being finalized. Tap any to learn more!',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: orange,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.help_outline, color: orange, size: 20),
                onPressed: _showIntroSheet,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

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
            error: (error, _) {
              // Get user-friendly error message
              final errorMessage = error is AppException
                  ? error.userMessage
                  : ExceptionHandler.getUserMessage(error);
              final isNetworkError = error is NetworkException ||
                  errorMessage.contains('internet') ||
                  errorMessage.contains('connection');

              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isNetworkError ? Icons.wifi_off : Icons.error_outline,
                        color: isDark ? AppColors.error : AppColorsLight.error,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark
                              ? AppColors.textPrimary
                              : AppColorsLight.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => ref.invalidate(programsProvider),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cyan,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            data: (programs) {
              var filtered = programs;

              if (searchQuery.isNotEmpty) {
                filtered = filtered
                    .where((p) =>
                        p.name
                            .toLowerCase()
                            .contains(searchQuery.toLowerCase()) ||
                        (p.category
                                ?.toLowerCase()
                                .contains(searchQuery.toLowerCase()) ??
                            false) ||
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
                  return ProgramCard(
                    program: program,
                    showComingSoon: true, // All programs coming soon
                  )
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
