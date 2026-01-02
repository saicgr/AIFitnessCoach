import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/difficulty_utils.dart';
import '../../data/models/branded_program.dart';
import '../../data/providers/branded_program_provider.dart';
import '../../data/services/haptic_service.dart';
import 'widgets/program_details_sheet.dart';

/// Screen for browsing and selecting branded workout programs
class ProgramSelectionScreen extends ConsumerStatefulWidget {
  const ProgramSelectionScreen({super.key});

  @override
  ConsumerState<ProgramSelectionScreen> createState() =>
      _ProgramSelectionScreenState();
}

class _ProgramSelectionScreenState
    extends ConsumerState<ProgramSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load programs on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(brandedProgramsProvider.notifier).loadPrograms();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showProgramDetails(BrandedProgram program) {
    HapticService.selection();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProgramDetailsSheet(program: program),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    final state = ref.watch(brandedProgramsProvider);
    final featuredPrograms = state.featuredPrograms;
    final filteredPrograms = state.filteredPrograms;
    final categories = state.categories;
    final selectedCategory = state.selectedCategory;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(context, isDark),

            // Search bar
            _buildSearchBar(context, isDark, elevated, textMuted),

            const SizedBox(height: 8),

            // Category chips
            if (categories.isNotEmpty)
              _buildCategoryChips(
                  context, categories, selectedCategory, cyan, isDark),

            const SizedBox(height: 8),

            // Content
            Expanded(
              child: state.isLoading
                  ? Center(child: CircularProgressIndicator(color: cyan))
                  : state.error != null
                      ? _buildErrorState(context, state.error!, cyan)
                      : _buildProgramsList(
                          context,
                          featuredPrograms,
                          filteredPrograms,
                          isDark,
                          cyan,
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () {
              HapticService.light();
              context.pop();
            },
            icon: Icon(
              Icons.arrow_back_ios,
              color: textMuted,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Workout Programs',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose a structured training program',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppColors.textSecondary
                            : AppColorsLight.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(
    BuildContext context,
    bool isDark,
    Color elevated,
    Color textMuted,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(12),
          border:
              isDark ? null : Border.all(color: AppColorsLight.cardBorder),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            ref.read(brandedProgramsProvider.notifier).setSearchQuery(value);
          },
          decoration: InputDecoration(
            hintText: 'Search programs...',
            hintStyle: TextStyle(color: textMuted),
            prefixIcon: Icon(Icons.search, color: textMuted),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: textMuted),
                    onPressed: () {
                      _searchController.clear();
                      ref
                          .read(brandedProgramsProvider.notifier)
                          .setSearchQuery('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(
    BuildContext context,
    List<String> categories,
    String? selectedCategory,
    Color cyan,
    bool isDark,
  ) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // All filter
          _FilterChip(
            label: 'All',
            isSelected: selectedCategory == null,
            onTap: () {
              HapticService.selection();
              ref.read(brandedProgramsProvider.notifier).setCategory(null);
            },
            selectedColor: cyan,
            defaultColor: elevated,
            textMuted: textMuted,
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          // Category filters
          ...categories.map((category) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _FilterChip(
                  label: category,
                  isSelected: selectedCategory == category,
                  onTap: () {
                    HapticService.selection();
                    ref
                        .read(brandedProgramsProvider.notifier)
                        .setCategory(category);
                  },
                  selectedColor: cyan,
                  defaultColor: elevated,
                  textMuted: textMuted,
                  isDark: isDark,
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error, Color cyan) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load programs',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(brandedProgramsProvider.notifier).refresh();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramsList(
    BuildContext context,
    List<BrandedProgram> featured,
    List<BrandedProgram> filtered,
    bool isDark,
    Color cyan,
  ) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final state = ref.watch(brandedProgramsProvider);
    final showFeatured = state.searchQuery.isEmpty &&
        state.selectedCategory == null &&
        featured.isNotEmpty;

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 48,
              color: textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'No programs found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                ref.read(brandedProgramsProvider.notifier).clearFilters();
                _searchController.clear();
              },
              child: const Text('Clear filters'),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        // Featured section
        if (showFeatured) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Icon(Icons.star, size: 18, color: AppColors.yellow),
                  const SizedBox(width: 8),
                  Text(
                    'FEATURED',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textMuted,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: featured.length,
                itemBuilder: (context, index) {
                  final program = featured[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _FeaturedProgramCard(
                      program: program,
                      onTap: () => _showProgramDetails(program),
                      isDark: isDark,
                    ),
                  ).animate().fadeIn(delay: Duration(milliseconds: index * 50));
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                'ALL PROGRAMS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textMuted,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ],

        // All programs grid
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final program = filtered[index];
                return _ProgramGridCard(
                  program: program,
                  onTap: () => _showProgramDetails(program),
                  isDark: isDark,
                ).animate().fadeIn(delay: Duration(milliseconds: index * 30));
              },
              childCount: filtered.length,
            ),
          ),
        ),

        // Bottom padding
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

// ============================================================================
// SUPPORTING WIDGETS
// ============================================================================

/// Filter chip widget
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color selectedColor;
  final Color defaultColor;
  final Color textMuted;
  final bool isDark;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.selectedColor,
    required this.defaultColor,
    required this.textMuted,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor.withOpacity(0.2) : defaultColor,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: selectedColor.withOpacity(0.5))
              : isDark
                  ? null
                  : Border.all(color: AppColorsLight.cardBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? selectedColor : textMuted,
          ),
        ),
      ),
    );
  }
}

/// Featured program card (horizontal scroll)
class _FeaturedProgramCard extends StatelessWidget {
  final BrandedProgram program;
  final VoidCallback onTap;
  final bool isDark;

  const _FeaturedProgramCard({
    required this.program,
    required this.onTap,
    required this.isDark,
  });

  Color _getCategoryColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'celebrity workout':
        return isDark ? AppColors.purple : AppColorsLight.purple;
      case 'goal-based':
        return isDark ? AppColors.cyan : AppColorsLight.cyan;
      case 'sport training':
        return isDark ? AppColors.success : AppColorsLight.success;
      default:
        return isDark ? AppColors.cyan : AppColorsLight.cyan;
    }
  }

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final categoryColor = _getCategoryColor(program.category);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              categoryColor.withOpacity(0.3),
              elevated,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: isDark ? null : Border.all(color: AppColorsLight.cardBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  program.category ?? 'Program',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: categoryColor,
                  ),
                ),
              ),
              const Spacer(),
              // Program name
              Text(
                program.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (program.celebrityName != null) ...[
                const SizedBox(height: 4),
                Text(
                  'By ${program.celebrityName}',
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              // Stats row
              Row(
                children: [
                  _StatChip(
                    icon: Icons.calendar_today,
                    label: program.durationDisplay,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    icon: Icons.fitness_center,
                    label: program.sessionsDisplay,
                    isDark: isDark,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Program grid card
class _ProgramGridCard extends StatelessWidget {
  final BrandedProgram program;
  final VoidCallback onTap;
  final bool isDark;

  const _ProgramGridCard({
    required this.program,
    required this.onTap,
    required this.isDark,
  });

  Color _getCategoryColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'celebrity workout':
        return isDark ? AppColors.purple : AppColorsLight.purple;
      case 'goal-based':
        return isDark ? AppColors.cyan : AppColorsLight.cyan;
      case 'sport training':
        return isDark ? AppColors.success : AppColorsLight.success;
      default:
        return isDark ? AppColors.cyan : AppColorsLight.cyan;
    }
  }

  IconData _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
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
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final categoryColor = _getCategoryColor(program.category);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(16),
          border: isDark ? null : Border.all(color: AppColorsLight.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon header area
            Container(
              height: 70,
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.15),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
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
            // Content
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
                    const SizedBox(height: 4),
                    // Category
                    Text(
                      program.category ?? 'Program',
                      style: TextStyle(
                        fontSize: 11,
                        color: categoryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    // Stats
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 10, color: textMuted),
                        const SizedBox(width: 4),
                        Text(
                          program.durationDisplay,
                          style: TextStyle(fontSize: 10, color: textSecondary),
                        ),
                      ],
                    ),
                    if (program.difficultyLevel != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: DifficultyUtils.getColor(program.difficultyLevel!)
                              .withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          DifficultyUtils.getDisplayName(program.difficultyLevel!),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: DifficultyUtils.getColor(program.difficultyLevel!),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small stat chip
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: textMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: textSecondary),
        ),
      ],
    );
  }
}
