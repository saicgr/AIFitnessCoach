import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:simple_circular_progress_bar/simple_circular_progress_bar.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../data/models/trophy.dart';
import '../../data/models/trophy_filter_state.dart';
import '../../data/models/user_xp.dart';
import '../../data/providers/trophy_filter_provider.dart';
import '../../data/providers/xp_provider.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/glass_back_button.dart';
import '../../core/services/posthog_service.dart';
import '../../widgets/glass_sheet.dart';
import 'widgets/trophy_filter_sheet.dart';


part 'trophy_room_screen_part_trophy_status_filter.dart';
part 'trophy_room_screen_part_trophy_card.dart';

part 'trophy_room_screen_ui.dart';


/// Trophy Room - View all trophies with search, filters, and collapsible sections
class TrophyRoomScreen extends ConsumerStatefulWidget {
  const TrophyRoomScreen({super.key});

  @override
  ConsumerState<TrophyRoomScreen> createState() => _TrophyRoomScreenState();
}

class _TrophyRoomScreenState extends ConsumerState<TrophyRoomScreen> {
  TrophyStatusFilter _statusFilter = TrophyStatusFilter.all;
  final TextEditingController _searchController = TextEditingController();
  final Map<TrophyCategory, bool> _expandedSections = {};

  // Initialize all sections as expanded
  @override
  void initState() {
    super.initState();
    for (final category in TrophyCategory.values) {
      _expandedSections[category] = true;
    }
    // Defer provider modification until after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      ref.read(posthogServiceProvider).capture(eventName: 'trophy_room_viewed');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final notifier = ref.read(xpProvider.notifier);
    await Future.wait([
      notifier.loadUserXP(),
      notifier.loadTrophies(),
      notifier.loadTrophySummary(),
    ]);
  }

  List<TrophyProgress> _filterTrophies(List<TrophyProgress> trophies) {
    var filtered = trophies.toList();

    // Apply status filter
    switch (_statusFilter) {
      case TrophyStatusFilter.all:
        break;
      case TrophyStatusFilter.earned:
        filtered = filtered.where((t) => t.isEarned).toList();
        break;
      case TrophyStatusFilter.inProgress:
        filtered = filtered.where((t) => !t.isEarned && t.progressPercentage > 0).toList();
        break;
      case TrophyStatusFilter.locked:
        filtered = filtered.where((t) => !t.isEarned && t.progressPercentage == 0).toList();
        break;
    }

    // Apply provider filters (search, tier, muscle, category, sort)
    final filterNotifier = ref.read(trophyFilterProvider.notifier);
    filtered = filterNotifier.applyFilters(filtered);

    return filtered;
  }

  /// Group trophies by category
  Map<TrophyCategory, List<TrophyProgress>> _groupByCategory(List<TrophyProgress> trophies) {
    final grouped = <TrophyCategory, List<TrophyProgress>>{};
    for (final trophy in trophies) {
      final category = trophy.trophy.trophyCategory;
      grouped[category] ??= [];
      grouped[category]!.add(trophy);
    }
    return grouped;
  }

  /// Get mystery trophies (separate section)
  List<TrophyProgress> _getMysteryTrophies(List<TrophyProgress> trophies) {
    return trophies.where((t) => t.isMystery).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.background : AppColorsLight.background;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    // Get dynamic accent color
    final accentEnum = ref.watch(accentColorProvider);
    final accentColor = accentEnum.getColor(isDark);

    final xpState = ref.watch(xpProvider);
    final filterState = ref.watch(trophyFilterProvider);
    final userXp = xpState.userXp;
    final allTrophies = xpState.allTrophies;
    final summary = xpState.trophySummary;
    final isLoading = xpState.isLoading || xpState.isLoadingTrophies;

    final filteredTrophies = _filterTrophies(allTrophies);
    final groupedTrophies = _groupByCategory(filteredTrophies);
    final mysteryTrophies = _getMysteryTrophies(filteredTrophies);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // App Bar with header content
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: bgColor,
                surfaceTintColor: Colors.transparent,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildHeader(
                    userXp,
                    summary,
                    isDark,
                    textColor,
                    textMuted,
                    accentColor,
                    elevatedColor,
                    cardBorder,
                  ),
                ),
              ),

              // Search bar with filter button
              SliverToBoxAdapter(
                child: _buildSearchBar(
                  isDark,
                  textColor,
                  textMuted,
                  elevatedColor,
                  cardBorder,
                  accentColor,
                  filterState,
                ),
              ),

              // Status filter chips
              SliverToBoxAdapter(
                child: _buildStatusFilterChips(isDark, textColor, textMuted, cardBorder, accentColor),
              ),

              // Stats summary
              if (summary != null)
                SliverToBoxAdapter(
                  child: _buildStatsSummary(
                    summary,
                    isDark,
                    textColor,
                    textMuted,
                    elevatedColor,
                    cardBorder,
                    accentColor,
                  ),
                ),

              // Loading indicator
              if (isLoading)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: CircularProgressIndicator(color: accentColor),
                    ),
                  ),
                ),

              // Empty state
              if (!isLoading && filteredTrophies.isEmpty)
                SliverToBoxAdapter(
                  child: _buildEmptyState(textMuted),
                ),

              // Mystery Trophies section (special section at top)
              if (!isLoading && mysteryTrophies.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildMysterySection(
                    mysteryTrophies,
                    isDark,
                    textColor,
                    textMuted,
                    elevatedColor,
                    cardBorder,
                    accentColor,
                  ),
                ),

              // Category sections
              if (!isLoading && filteredTrophies.isNotEmpty)
                ...TrophyCategory.values.map((category) {
                  final categoryTrophies = groupedTrophies[category] ?? [];
                  // Filter out mystery trophies (shown in separate section)
                  final visibleTrophies = categoryTrophies.where((t) => !t.isMystery).toList();
                  if (visibleTrophies.isEmpty) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }
                  return SliverToBoxAdapter(
                    child: _buildCategorySection(
                      category,
                      visibleTrophies,
                      isDark,
                      textColor,
                      textMuted,
                      elevatedColor,
                      cardBorder,
                      accentColor,
                    ),
                  );
                }),

              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),

          // Floating back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: GlassBackButton(
              onTap: () => context.pop(),
            ),
          ),

          // Floating leaderboard button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: _buildFloatingButton(
              icon: Icons.leaderboard_outlined,
              onTap: () => context.push('/xp-leaderboard'),
              isDark: isDark,
              elevatedColor: elevatedColor,
              textColor: textColor,
              cardBorder: cardBorder,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
    required Color elevatedColor,
    required Color textColor,
    required Color cardBorder,
  }) {
    return GestureDetector(
      onTap: () {
        HapticService.light();
        onTap();
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.black.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: textColor,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildSearchBar(
    bool isDark,
    Color textColor,
    Color textMuted,
    Color elevatedColor,
    Color cardBorder,
    Color accentColor,
    TrophyFilterState filterState,
  ) {
    final filterNotifier = ref.read(trophyFilterProvider.notifier);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: textColor, fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Search trophies...',
          hintStyle: TextStyle(color: textMuted),
          prefixIcon: Icon(Icons.search, color: textMuted, size: 22),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.close, color: textMuted, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    filterNotifier.setSearchQuery('');
                  },
                ),
              Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.tune, color: textMuted, size: 22),
                    onPressed: () => _showFilterSheet(context),
                  ),
                  if (filterState.hasActiveFilters)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onChanged: (value) {
          filterNotifier.setSearchQuery(value);
        },
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    HapticService.medium();
    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => GlassSheet(
        showHandle: false,
        child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => const TrophyFilterSheet(),
      ),
      ),
    );
  }

  Widget _buildStatusFilterChips(
    bool isDark,
    Color textColor,
    Color textMuted,
    Color cardBorder,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: TrophyStatusFilter.values.map((filter) {
            final isSelected = _statusFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                avatar: Icon(
                  filter.icon,
                  size: 16,
                  color: isSelected ? accentColor : textMuted,
                ),
                label: Text(filter.displayName),
                selected: isSelected,
                onSelected: (_) {
                  HapticService.light();
                  setState(() => _statusFilter = filter);
                },
                backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
                selectedColor: accentColor.withValues(alpha: 0.2),
                checkmarkColor: accentColor,
                labelStyle: TextStyle(
                  fontSize: 13,
                  color: isSelected ? accentColor : textMuted,
                ),
                side: BorderSide(
                  color: isSelected
                      ? accentColor.withValues(alpha: 0.5)
                      : cardBorder,
                ),
                showCheckmark: false,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatsSummary(
    TrophyRoomSummary summary,
    bool isDark,
    Color textColor,
    Color textMuted,
    Color elevatedColor,
    Color cardBorder,
    Color accentColor,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.emoji_events,
            value: '${summary.earnedTrophies}',
            label: 'Earned',
            color: AppColors.green,
            textMuted: textMuted,
          ),
          _buildStatDivider(textMuted),
          _buildStatItem(
            icon: Icons.lock_open,
            value: '${summary.lockedTrophies}',
            label: 'Locked',
            color: textMuted,
            textMuted: textMuted,
          ),
          _buildStatDivider(textMuted),
          _buildStatItem(
            icon: Icons.help_outline,
            value: '${summary.secretDiscovered}/${summary.totalSecret}',
            label: 'Mystery',
            color: AppColors.purple,
            textMuted: textMuted,
          ),
          _buildStatDivider(textMuted),
          _buildStatItem(
            icon: Icons.stars,
            value: '${summary.totalPoints}',
            label: 'Points',
            color: accentColor,
            textMuted: textMuted,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required Color textMuted,
  }) {
    return Flexible(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: textMuted,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider(Color textMuted) {
    return Container(
      width: 1,
      height: 36,
      color: textMuted.withValues(alpha: 0.2),
    );
  }

  Widget _buildEmptyState(Color textMuted) {
    String message;
    switch (_statusFilter) {
      case TrophyStatusFilter.earned:
        message = 'No trophies earned yet.\nComplete workouts to start earning!';
        break;
      case TrophyStatusFilter.inProgress:
        message = 'No trophies in progress.\nStart working toward your goals!';
        break;
      case TrophyStatusFilter.locked:
        message = 'All trophies are either earned or in progress!';
        break;
      case TrophyStatusFilter.all:
        message = 'No trophies match your filters.\nTry adjusting your search or filters.';
        break;
    }

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 64,
            color: textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: textMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMysterySection(
    List<TrophyProgress> mysteryTrophies,
    bool isDark,
    Color textColor,
    Color textMuted,
    Color elevatedColor,
    Color cardBorder,
    Color accentColor,
  ) {
    final earnedCount = mysteryTrophies.where((t) => t.isEarned).length;
    final inProgressCount = mysteryTrophies.where((t) => !t.isEarned && t.progressPercentage > 0).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          GestureDetector(
            onTap: () {
              HapticService.light();
              // Mystery section is always expanded (no collapse)
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.purple.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text('❓', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mystery Trophies',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            _buildCountBadge('$earnedCount discovered', AppColors.purple),
                            const SizedBox(width: 8),
                            if (inProgressCount > 0)
                              _buildCountBadge('$inProgressCount close', AppColors.orange),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.purple.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${mysteryTrophies.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.purple,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Trophy cards
          ...mysteryTrophies.map((trophy) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _TrophyCard(
                trophyProgress: trophy,
                onTap: () => _showTrophyDetail(trophy, isDark, textColor, textMuted, elevatedColor, accentColor),
                isDark: isDark,
                textColor: textColor,
                textMuted: textMuted,
                elevatedColor: elevatedColor,
                cardBorder: cardBorder,
                accentColor: accentColor,
              ),
            );
          }),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildCategorySection(
    TrophyCategory category,
    List<TrophyProgress> trophies,
    bool isDark,
    Color textColor,
    Color textMuted,
    Color elevatedColor,
    Color cardBorder,
    Color accentColor,
  ) {
    final earnedCount = trophies.where((t) => t.isEarned).length;
    final inProgressCount = trophies.where((t) => !t.isEarned && t.progressPercentage > 0).length;
    final isExpanded = _expandedSections[category] ?? true;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header (collapsible)
          GestureDetector(
            onTap: () {
              HapticService.light();
              setState(() {
                _expandedSections[category] = !isExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(category.icon, style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.displayName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            _buildCountBadge('$earnedCount earned', AppColors.green),
                            const SizedBox(width: 8),
                            if (inProgressCount > 0)
                              _buildCountBadge('$inProgressCount in progress', AppColors.orange),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: earnedCount > 0
                          ? AppColors.green.withValues(alpha: 0.15)
                          : textMuted.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$earnedCount / ${trophies.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: earnedCount > 0 ? AppColors.green : textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: textMuted,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),

          // Trophy cards (collapsible)
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: Column(
              children: trophies.map((trophy) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _TrophyCard(
                    trophyProgress: trophy,
                    onTap: () => _showTrophyDetail(trophy, isDark, textColor, textMuted, elevatedColor, accentColor),
                    isDark: isDark,
                    textColor: textColor,
                    textMuted: textMuted,
                    elevatedColor: elevatedColor,
                    cardBorder: cardBorder,
                    accentColor: accentColor,
                  ),
                );
              }).toList(),
            ),
            secondChild: const SizedBox.shrink(),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildCountBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  void _showTrophyDetail(
    TrophyProgress trophy,
    bool isDark,
    Color textColor,
    Color textMuted,
    Color elevatedColor,
    Color accentColor,
  ) {
    HapticService.medium();
    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => _TrophyDetailSheet(
        trophyProgress: trophy,
        isDark: isDark,
        textColor: textColor,
        textMuted: textMuted,
        elevatedColor: elevatedColor,
        accentColor: accentColor,
      ),
    );
  }
}
