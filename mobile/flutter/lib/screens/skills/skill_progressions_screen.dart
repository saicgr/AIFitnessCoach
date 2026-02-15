import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/skill_progression.dart';
import '../../data/providers/skill_progression_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/segmented_tab_bar.dart';
import 'widgets/progression_chain_card.dart';
import 'widgets/category_filter_chips.dart';
import 'widgets/skill_progress_summary_card.dart';

/// Screen displaying all available skill progressions
class SkillProgressionsScreen extends ConsumerStatefulWidget {
  const SkillProgressionsScreen({super.key});

  @override
  ConsumerState<SkillProgressionsScreen> createState() =>
      _SkillProgressionsScreenState();
}

class _SkillProgressionsScreenState
    extends ConsumerState<SkillProgressionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final userId = ref.read(authStateProvider).user?.id;
    if (userId != null) {
      ref.read(skillProgressionProvider.notifier).setUserId(userId);
    }
    await Future.wait([
      ref.read(skillProgressionProvider.notifier).loadChains(),
      ref.read(skillProgressionProvider.notifier).loadUserProgress(userId: userId),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    final state = ref.watch(skillProgressionProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context, isDark),

            // Tab Bar
            _buildTabBar(context, elevated, cyan, textMuted, isDark),

            const SizedBox(height: 8),

            // Tab Content
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.error != null
                      ? _buildErrorState(context, state.error!, isDark)
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildMyProgressTab(context, state, isDark),
                            _buildAllChainsTab(context, state, isDark),
                          ],
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
                  'Skill Progressions',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Master bodyweight skills step by step',
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

  Widget _buildTabBar(
    BuildContext context,
    Color elevated,
    Color cyan,
    Color textMuted,
    bool isDark,
  ) {
    return SegmentedTabBar(
      controller: _tabController,
      showIcons: false,
      tabs: const [
        SegmentedTabItem(label: 'My Progress'),
        SegmentedTabItem(label: 'All Skills'),
      ],
    );
  }

  Widget _buildMyProgressTab(
    BuildContext context,
    SkillProgressionState state,
    bool isDark,
  ) {
    final startedChains = state.startedChains;

    if (startedChains.isEmpty) {
      return _buildEmptyProgressState(context, isDark);
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary card
          if (state.summary != null)
            SkillProgressSummaryCard(summary: state.summary!),

          const SizedBox(height: 24),

          // Active progressions header
          Text(
            'Active Progressions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),

          // Started chains
          ...startedChains.map((chain) {
            final progress = state.getProgressForChain(chain.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ProgressionChainCard(
                chain: chain,
                progress: progress,
                onTap: () => _openChainDetail(chain.id),
              ),
            );
          }),

          const SizedBox(height: 24),

          // Discover more section
          if (state.availableChains.isNotEmpty) ...[
            Text(
              'Discover More Skills',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            ...state.availableChains.take(3).map((chain) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ProgressionChainCard(
                  chain: chain,
                  onTap: () => _openChainDetail(chain.id),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildAllChainsTab(
    BuildContext context,
    SkillProgressionState state,
    bool isDark,
  ) {
    final chains = state.filteredChains;
    final categories = _extractCategories(state.chains);

    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
          // Category filter
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: CategoryFilterChips(
                categories: categories,
                selectedCategory: state.selectedCategory,
                onCategorySelected: (category) {
                  HapticService.light();
                  ref.read(skillProgressionProvider.notifier).setCategory(category);
                },
              ),
            ),
          ),

          // Chains grid
          chains.isEmpty
              ? SliverFillRemaining(
                  child: _buildEmptyFilterState(context, isDark),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final chain = chains[index];
                        final progress = state.getProgressForChain(chain.id);
                        return ProgressionChainCard(
                          chain: chain,
                          progress: progress,
                          isCompact: true,
                          onTap: () => _openChainDetail(chain.id),
                        );
                      },
                      childCount: chains.length,
                    ),
                  ),
                ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyProgressState(BuildContext context, bool isDark) {
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cyan.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.trending_up_rounded,
                size: 48,
                color: cyan,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Start Your Journey',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Choose a skill progression to begin mastering bodyweight movements step by step.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textSecondary,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                HapticService.light();
                _tabController.animateTo(1);
              },
              icon: const Icon(Icons.explore_rounded),
              label: const Text('Browse Skills'),
              style: FilledButton.styleFrom(
                backgroundColor: cyan,
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
  }

  Widget _buildEmptyFilterState(BuildContext context, bool isDark) {
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 48,
            color: textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No skills in this category',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error, bool isDark) {
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textSecondary
                        : AppColorsLight.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: FilledButton.styleFrom(backgroundColor: cyan),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _extractCategories(List<ProgressionChain> chains) {
    return chains.map((c) => c.category).toSet().toList()..sort();
  }

  void _openChainDetail(String chainId) {
    HapticService.light();
    context.push('/skills/$chainId');
  }
}
