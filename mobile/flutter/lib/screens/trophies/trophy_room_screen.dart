import 'dart:ui';
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
import 'widgets/trophy_filter_sheet.dart';

/// Filter options for trophy status display
enum TrophyStatusFilter {
  all,
  earned,
  inProgress,
  locked,
}

extension TrophyStatusFilterExtension on TrophyStatusFilter {
  String get displayName {
    switch (this) {
      case TrophyStatusFilter.all:
        return 'All';
      case TrophyStatusFilter.earned:
        return 'Earned';
      case TrophyStatusFilter.inProgress:
        return 'In Progress';
      case TrophyStatusFilter.locked:
        return 'Locked';
    }
  }

  IconData get icon {
    switch (this) {
      case TrophyStatusFilter.all:
        return Icons.grid_view_rounded;
      case TrophyStatusFilter.earned:
        return Icons.emoji_events;
      case TrophyStatusFilter.inProgress:
        return Icons.trending_up;
      case TrophyStatusFilter.locked:
        return Icons.lock_outline;
    }
  }
}

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
            child: _buildFloatingButton(
              icon: Icons.arrow_back,
              onTap: () => context.pop(),
              isDark: isDark,
              elevatedColor: elevatedColor,
              textColor: textColor,
              cardBorder: cardBorder,
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

  Widget _buildHeader(
    UserXP? userXp,
    TrophyRoomSummary? summary,
    bool isDark,
    Color textColor,
    Color textMuted,
    Color accentColor,
    Color elevatedColor,
    Color cardBorder,
  ) {
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final currentLevel = userXp?.currentLevel ?? 1;
    final progressFraction = userXp?.progressFraction ?? 0.0;
    final xpTitle = userXp?.xpTitle ?? XPTitle.novice;
    final titleColor = Color(xpTitle.colorValue);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 70, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            isDark ? AppColors.elevated : AppColorsLight.elevated,
            isDark ? AppColors.background : AppColorsLight.background,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Icon(
                Icons.emoji_events,
                size: 28,
                color: accentColor,
              ),
              const SizedBox(width: 12),
              Text(
                'Trophy Room',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // XP Progress Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: glassSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder),
            ),
            child: Row(
              children: [
                // Circular progress with level
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SimpleCircularProgressBar(
                      size: 64,
                      progressStrokeWidth: 5,
                      backStrokeWidth: 4,
                      valueNotifier: ValueNotifier(progressFraction * 100),
                      progressColors: [
                        accentColor.withValues(alpha: 0.7),
                        accentColor,
                        accentColor.withValues(alpha: 0.9),
                      ],
                      backColor: textMuted.withValues(alpha: 0.15),
                      mergeMode: true,
                      animationDuration: 1,
                      startAngle: -90,
                    ),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            titleColor,
                            titleColor.withValues(alpha: 0.7),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: titleColor.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          currentLevel.toString(),
                          style: TextStyle(
                            fontSize: currentLevel >= 100 ? 14 : 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 16),

                // Level info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Level ${userXp?.currentLevel ?? 1}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: titleColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: titleColor.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              xpTitle.displayName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: titleColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progressFraction,
                          minHeight: 8,
                          backgroundColor: textMuted.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation(accentColor),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${userXp?.xpInCurrentLevel ?? 0} / ${userXp?.xpToNextLevel ?? 50} XP',
                        style: TextStyle(
                          fontSize: 11,
                          color: textMuted,
                        ),
                      ),
                    ],
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => const TrophyFilterSheet(),
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
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

/// Trophy card with tier-based visual styling
class _TrophyCard extends StatelessWidget {
  final TrophyProgress trophyProgress;
  final VoidCallback? onTap;
  final bool isDark;
  final Color textColor;
  final Color textMuted;
  final Color elevatedColor;
  final Color cardBorder;
  final Color accentColor;

  const _TrophyCard({
    required this.trophyProgress,
    this.onTap,
    required this.isDark,
    required this.textColor,
    required this.textMuted,
    required this.elevatedColor,
    required this.cardBorder,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final trophy = trophyProgress.trophy;
    final isEarned = trophyProgress.isEarned;
    final isMystery = trophyProgress.isMystery;
    final tier = trophy.trophyTier;
    final primaryColor = isMystery ? AppColors.purple : tier.primaryColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isEarned
              ? primaryColor.withValues(alpha: 0.15)
              : isMystery
                  ? AppColors.purple.withValues(alpha: 0.08)
                  : elevatedColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEarned
                ? primaryColor.withValues(alpha: 0.4)
                : isMystery
                    ? AppColors.purple.withValues(alpha: 0.3)
                    : cardBorder,
            width: isEarned ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Trophy icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isEarned
                    ? LinearGradient(
                        colors: tier.gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isEarned
                    ? null
                    : isMystery
                        ? AppColors.purple.withValues(alpha: 0.2)
                        : textMuted.withValues(alpha: 0.2),
                boxShadow: isEarned
                    ? [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  trophyProgress.displayIcon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    trophyProgress.displayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isEarned ? textColor : (isMystery ? AppColors.purple : textMuted),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    trophyProgress.displayDescription,
                    style: TextStyle(
                      fontSize: 12,
                      color: textMuted,
                      fontStyle: isMystery ? FontStyle.italic : FontStyle.normal,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Tier badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isEarned
                              ? primaryColor.withValues(alpha: 0.2)
                              : isMystery
                                  ? AppColors.purple.withValues(alpha: 0.15)
                                  : textMuted.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          trophyProgress.displayTier,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isEarned ? primaryColor : (isMystery ? AppColors.purple : textMuted),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // XP badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          trophyProgress.displayXp,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: accentColor,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Progress indicator
                      if (!isEarned)
                        Text(
                          '${trophyProgress.progressPercentage.round()}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: trophyProgress.progressPercentage > 0 ? AppColors.orange : textMuted,
                          ),
                        ),
                    ],
                  ),
                  // Progress bar
                  if (!isEarned && !isMystery) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: trophyProgress.progressFraction,
                        minHeight: 4,
                        backgroundColor: textMuted.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation(primaryColor.withValues(alpha: 0.7)),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Status icon
            const SizedBox(width: 8),
            if (isEarned)
              Icon(
                Icons.check_circle,
                color: primaryColor,
                size: 24,
              )
            else
              Icon(
                Icons.chevron_right,
                color: textMuted,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

/// Trophy detail bottom sheet
class _TrophyDetailSheet extends StatelessWidget {
  final TrophyProgress trophyProgress;
  final bool isDark;
  final Color textColor;
  final Color textMuted;
  final Color elevatedColor;
  final Color accentColor;

  const _TrophyDetailSheet({
    required this.trophyProgress,
    required this.isDark,
    required this.textColor,
    required this.textMuted,
    required this.elevatedColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final trophy = trophyProgress.trophy;
    final tier = trophy.trophyTier;
    final isEarned = trophyProgress.isEarned;
    final isMystery = trophyProgress.isMystery;
    final primaryColor = isMystery ? AppColors.purple : tier.primaryColor;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.8)
                : Colors.white.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.1),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: textMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Trophy icon with tier styling
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: isEarned && !isMystery
                              ? LinearGradient(colors: tier.gradientColors)
                              : null,
                          color: isEarned
                              ? null
                              : isMystery
                                  ? AppColors.purple.withValues(alpha: 0.2)
                                  : textMuted.withValues(alpha: 0.2),
                          boxShadow: isEarned
                              ? [
                                  BoxShadow(
                                    color: primaryColor.withValues(alpha: 0.4),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            trophyProgress.displayIcon,
                            style: const TextStyle(fontSize: 40),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Name
                      Text(
                        trophyProgress.displayName,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isMystery ? AppColors.purple : textColor,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 8),

                      // Tier badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: primaryColor.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          trophyProgress.displayTier,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Description
                      Text(
                        trophyProgress.displayDescription,
                        style: TextStyle(
                          fontSize: 14,
                          color: textMuted,
                          height: 1.5,
                          fontStyle: isMystery ? FontStyle.italic : FontStyle.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 20),

                      // Progress or earned date
                      if (isEarned)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.green.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.green,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Earned ${_formatDate(trophyProgress.earnedAt)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.green,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (!isMystery)
                        Column(
                          children: [
                            Text(
                              '${trophyProgress.currentValue.toInt()} / ${trophy.thresholdValue?.toInt() ?? 0} ${trophy.thresholdUnit ?? ''}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: 200,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: trophyProgress.progressFraction,
                                  minHeight: 8,
                                  backgroundColor: textMuted.withValues(alpha: 0.15),
                                  valueColor: AlwaysStoppedAnimation(primaryColor),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${trophyProgress.progressPercentage.round()}% complete',
                              style: TextStyle(
                                fontSize: 12,
                                color: textMuted,
                              ),
                            ),
                          ],
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.purple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.purple.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.help_outline,
                                color: AppColors.purple,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Progress hidden until discovered',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.purple,
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 20),

                      // Rewards
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 16,
                                  color: accentColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  trophyProgress.displayXp,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: accentColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (trophy.hasMerchReward && !isMystery)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.purple.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.card_giftcard,
                                    size: 16,
                                    color: AppColors.purple,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    trophy.merchReward!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.purple,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Safe area padding
                SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.month}/${date.day}/${date.year}';
  }
}
