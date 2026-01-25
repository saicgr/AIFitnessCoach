import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/branded_program.dart';
import '../../../data/services/haptic_service.dart';
import '../providers/library_providers.dart';
import '../widgets/filter_chip_widget.dart';
import '../widgets/program_card.dart';
import '../widgets/program_carousel_section.dart';
import '../components/programs_intro_sheet.dart';

/// Format category name: replace underscores with spaces and capitalize each word
String _formatCategoryName(String category) {
  return category
      .replaceAll('_', ' ')
      .split(' ')
      .map((word) => word.isNotEmpty
          ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
          : '')
      .join(' ');
}

/// Group programs into sections for carousel display
Map<String, List<BrandedProgram>> _groupProgramsIntoSections(List<BrandedProgram> programs) {
  final Map<String, List<BrandedProgram>> sections = {};

  // Featured - first 5 programs or random selection
  final featured = programs.take(5).toList();
  if (featured.isNotEmpty) {
    sections['Featured Programs'] = featured;
  }

  // Beginner Friendly
  final beginner = programs.where((p) =>
    p.difficultyLevel?.toLowerCase() == 'beginner' ||
    p.category?.toLowerCase() == 'general_fitness'
  ).toList();
  if (beginner.isNotEmpty) {
    sections['Beginner Friendly'] = beginner;
  }

  // Build Strength
  final strength = programs.where((p) =>
    p.category?.toLowerCase() == 'strength' ||
    p.category?.toLowerCase() == 'hypertrophy'
  ).toList();
  if (strength.isNotEmpty) {
    sections['Build Strength'] = strength;
  }

  // Athletic Performance
  final athletic = programs.where((p) =>
    p.category?.toLowerCase() == 'athletic' ||
    p.category?.toLowerCase() == 'sport_training'
  ).toList();
  if (athletic.isNotEmpty) {
    sections['Athletic Performance'] = athletic;
  }

  // Home Workouts
  final home = programs.where((p) =>
    p.category?.toLowerCase() == 'bodyweight' ||
    p.category?.toLowerCase() == 'home'
  ).toList();
  if (home.isNotEmpty) {
    sections['Home Workouts'] = home;
  }

  // Celebrity Programs
  final celebrity = programs.where((p) =>
    p.category?.toLowerCase() == 'celebrity_workout' ||
    p.celebrityName != null
  ).toList();
  if (celebrity.isNotEmpty) {
    sections['Celebrity Programs'] = celebrity;
  }

  // All Programs (as fallback if not enough in categories)
  if (sections.length < 3 && programs.length > 5) {
    sections['All Programs'] = programs;
  }

  return sections;
}

/// Programs tab content with search, category filter, and list
class ProgramsTab extends ConsumerStatefulWidget {
  const ProgramsTab({super.key});

  @override
  ConsumerState<ProgramsTab> createState() => _ProgramsTabState();
}

class _ProgramsTabState extends ConsumerState<ProgramsTab> {
  bool _hasShownIntro = false;
  bool _isSearchExpanded = false;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

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

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
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

  void _toggleSearch() {
    HapticService.light();
    setState(() {
      _isSearchExpanded = !_isSearchExpanded;
      if (_isSearchExpanded) {
        _searchFocusNode.requestFocus();
      } else {
        _searchFocusNode.unfocus();
        _searchController.clear();
        ref.read(programSearchProvider.notifier).state = '';
      }
    });
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
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final accentColor = ref.colors(context).accent;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Stack(
      children: [
        // Main content
        Column(
          children: [
            // Info banner - compact single line
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule_rounded, color: orange, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Programs coming soon — tap any to learn more',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: orange,
                    ),
                  ),
                ],
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
                      FilterChipWidget(
                        label: 'All',
                        isSelected: selectedCategory == null,
                        onTap: () {
                          ref.read(selectedProgramCategoryProvider.notifier).state =
                              null;
                        },
                      ),
                      ...categories.map((category) => FilterChipWidget(
                            label: _formatCategoryName(category),
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
                                setState(() {
                                  _isSearchExpanded = false;
                                  _searchController.clear();
                                });
                              },
                              child: const Text('Clear filters'),
                            ),
                        ],
                      ),
                    );
                  }

                  // If searching or filtering, show list view
                  if (searchQuery.isNotEmpty || selectedCategory != null) {
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final program = filtered[index];
                        return ProgramCard(
                          program: program,
                          showComingSoon: true,
                        )
                            .animate()
                            .fadeIn(delay: Duration(milliseconds: index * 50));
                      },
                    );
                  }

                  // Netflix-style carousel layout
                  final sections = _groupProgramsIntoSections(filtered);
                  final sectionEntries = sections.entries.toList();

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: sectionEntries.length,
                    itemBuilder: (context, index) {
                      final entry = sectionEntries[index];
                      final isFeatured = entry.key == 'Featured Programs';

                      return ProgramCarouselSection(
                        title: entry.key,
                        programs: entry.value,
                        isFeatured: isFeatured,
                      )
                          .animate()
                          .fadeIn(delay: Duration(milliseconds: index * 100));
                    },
                  );
                },
              ),
            ),
          ],
        ),

        // Floating search button / expanded search bar
        Positioned(
          left: _isSearchExpanded ? 16 : null,
          right: 16,
          bottom: bottomPadding + 16,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: _isSearchExpanded
                ? _buildExpandedSearchBar(context, isDark, elevated, accentColor, textMuted)
                : _buildSearchFAB(context, isDark, accentColor),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchFAB(BuildContext context, bool isDark, Color accentColor) {
    return GestureDetector(
      onTap: _toggleSearch,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(isDark ? 0.3 : 0.2),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: accentColor.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.search_rounded,
                color: accentColor,
                size: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedSearchBar(
    BuildContext context,
    bool isDark,
    Color elevated,
    Color accentColor,
    Color textMuted,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: accentColor.withOpacity(isDark ? 0.15 : 0.1),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: accentColor.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 18),
              Icon(
                Icons.search_rounded,
                color: accentColor,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: (value) {
                    ref.read(programSearchProvider.notifier).state = value;
                  },
                  cursorColor: accentColor,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search programs...',
                    hintStyle: TextStyle(
                      color: textMuted.withOpacity(0.7),
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Close button
              GestureDetector(
                onTap: _toggleSearch,
                child: Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.close_rounded,
                      color: accentColor,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
