import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/exceptions/app_exceptions.dart';
import '../../../data/models/skill_progression.dart';
import '../../../data/providers/skill_progression_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../skills/widgets/progression_chain_card.dart';
import '../../skills/widgets/category_filter_chips.dart';

/// Tab displaying skill progressions in the library
class SkillsTab extends ConsumerStatefulWidget {
  const SkillsTab({super.key});

  @override
  ConsumerState<SkillsTab> createState() => _SkillsTabState();
}

class _SkillsTabState extends ConsumerState<SkillsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Delay provider modification until after widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
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
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(skillProgressionProvider);
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    if (state.isLoading && state.chains.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.chains.isEmpty) {
      return _buildErrorState(context, state.error!, isDark);
    }

    final chains = state.filteredChains;
    final categories = _extractCategories(state.chains);

    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
          // Header banner to access full screen
          SliverToBoxAdapter(
            child: _buildSkillsBanner(context, state, isDark),
          ),

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

          // Active progressions section
          if (state.startedChains.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      size: 18,
                      color: cyan,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Your Active Skills',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 180,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: state.startedChains.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final chain = state.startedChains[index];
                    final progress = state.getProgressForChain(chain.id);
                    return SizedBox(
                      width: 160,
                      child: ProgressionChainCard(
                        chain: chain,
                        progress: progress,
                        isCompact: true,
                        onTap: () => _openChainDetail(chain.id),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
            ),
          ],

          // All chains section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Icon(
                    Icons.explore_rounded,
                    size: 18,
                    color: textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Explore Skills',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Spacer(),
                  Text(
                    '${chains.length} available',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Grid of all chains
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

  Widget _buildSkillsBanner(
    BuildContext context,
    SkillProgressionState state,
    bool isDark,
  ) {
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final startedCount = state.userProgress.length;
    final completedCount =
        state.userProgress.where((p) => p.isCompleted).length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cyan.withOpacity(0.15),
            elevated,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cyan.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.route_rounded,
              color: cyan,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Skill Progressions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  startedCount > 0
                      ? '$startedCount active, $completedCount mastered'
                      : 'Master bodyweight skills step by step',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.textSecondary
                            : AppColorsLight.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              HapticService.light();
              context.push('/skills');
            },
            icon: Icon(
              Icons.arrow_forward_rounded,
              color: cyan,
            ),
            style: IconButton.styleFrom(
              backgroundColor: cyan.withOpacity(0.1),
            ),
          ),
        ],
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

    // Get user-friendly error message
    final errorMessage = ExceptionHandler.getUserMessage(Exception(error));
    final isNetworkError = error.contains('internet') ||
        error.contains('connection') ||
        error.contains('timeout') ||
        error.contains('SocketException');

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isNetworkError ? Icons.wifi_off : Icons.error_outline_rounded,
              size: 48,
              color: isDark ? AppColors.error : AppColorsLight.error,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
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
  }

  List<String> _extractCategories(List<ProgressionChain> chains) {
    return chains.map((c) => c.category).toSet().toList()..sort();
  }

  void _openChainDetail(String chainId) {
    HapticService.light();
    context.push('/skills/$chainId');
  }
}
