import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/widgets/skeleton/skeleton.dart';
import '../../data/models/skill_progression.dart';
import '../../data/providers/skill_progression_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/design_system/zealova.dart';
import 'widgets/progression_chain_card.dart';
import 'widgets/category_filter_chips.dart';
import 'widgets/skill_progress_summary_card.dart';

import '../../l10n/generated/app_localizations.dart';
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
    // Non-blocking: load after first frame so the skeleton renders instantly.
    _scheduleInitialLoad();
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

  /// Schedule the first data load AFTER the initial frame so `initState`
  /// never blocks on a network round-trip — the screen paints its skeleton
  /// (or any in-memory state retained by the notifier) instantly.
  void _scheduleInitialLoad() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // If the StateNotifier already holds chains from an earlier visit this
      // session, the build shows them instantly; this call silently
      // revalidates. On a true cold open it fills the skeleton.
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;

    final state = ref.watch(skillProgressionProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            ZealovaAppBar(
              title: AppLocalizations.of(context).skillsSkillProgressions,
              kicker: AppLocalizations.of(context)
                  .skillProgressionsMasterBodyweightSkillsStep,
              onBack: () {
                HapticService.light();
                context.pop();
              },
            ),

            // Tab Bar
            _buildTabBar(context),

            const SizedBox(height: 8),

            // Tab Content.
            //
            // Cache-first: the StateNotifier retains `chains` in memory across
            // visits, so once any chain data exists the real tabs render
            // immediately — a background reload never blanks the screen. The
            // layout-matched skeleton shows ONLY on a genuine cold load (no
            // chains yet AND no error).
            Expanded(
              child: state.chains.isNotEmpty
                  ? TabBarView(
                      controller: _tabController,
                      children: [
                        _buildMyProgressTab(context, state, isDark),
                        _buildAllChainsTab(context, state, isDark),
                      ],
                    )
                  : state.error != null
                      ? _buildErrorState(context, state.error!, isDark)
                      : _buildSkeleton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          return ZealovaTextTabs(
            tabs: [
              AppLocalizations.of(context).skillProgressionsMyProgress,
              AppLocalizations.of(context).skillProgressionsAllSkills,
            ],
            activeIndex: _tabController.index,
            onChanged: (i) {
              HapticService.light();
              _tabController.animateTo(i);
            },
          );
        },
      ),
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
          ZealovaSectionKicker(
            AppLocalizations.of(context).skillProgressionsActiveProgressions,
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
            ZealovaSectionKicker(
              AppLocalizations.of(context).skillProgressionsDiscoverMoreSkills,
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
                  hasScrollBody: false,
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

  /// Layout-matched skeleton shown on a true first-ever cold load. Mirrors the
  /// 2-column progression-chain grid so the skeleton -> content swap is
  /// reflow-free.
  Widget _buildSkeleton() {
    return const SkeletonGrid(
      itemCount: 6,
      crossAxisCount: 2,
      childAspectRatio: 0.85,
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
      scrollable: true,
    );
  }

  Widget _buildEmptyProgressState(BuildContext context, bool isDark) {
    final tc = ThemeColors.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tc.surface,
                border: Border.all(color: AppColors.cardBorder),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.trending_up_rounded,
                size: 36,
                color: tc.accent,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context).skillProgressionsStartYourJourney.toUpperCase(),
              style: ZType.disp(24, color: tc.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).skillProgressionsChooseASkillProgression,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: tc.textSecondary,
                  ),
            ),
            const SizedBox(height: 28),
            ZealovaButton(
              label: AppLocalizations.of(context).skillProgressionsBrowseSkills,
              expand: false,
              trailingIcon: Icons.explore_rounded,
              onTap: () {
                HapticService.light();
                _tabController.animateTo(1);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFilterState(BuildContext context, bool isDark) {
    final tc = ThemeColors.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 40,
            color: tc.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).skillProgressionsNoSkillsInThis.toUpperCase(),
            style: ZType.lbl(13, color: tc.textMuted, letterSpacing: 1.4),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error, bool isDark) {
    final tc = ThemeColors.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).workoutGenerationSomethingWentWrong.toUpperCase(),
              style: ZType.disp(20, color: tc.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: tc.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),
            ZealovaButton(
              label: AppLocalizations.of(context).workoutStateCardsTryAgain,
              expand: false,
              trailingIcon: Icons.refresh_rounded,
              onTap: _loadData,
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
