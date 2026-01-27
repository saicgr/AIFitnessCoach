import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:simple_circular_progress_bar/simple_circular_progress_bar.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../data/models/trophy.dart';
import '../../data/models/user_xp.dart';
import '../../data/providers/xp_provider.dart';
import '../../data/services/haptic_service.dart';

/// Filter options for trophy display
enum TrophyFilter {
  all,
  earned,
  inProgress,
  locked,
}

extension TrophyFilterExtension on TrophyFilter {
  String get displayName {
    switch (this) {
      case TrophyFilter.all:
        return 'All';
      case TrophyFilter.earned:
        return 'Earned';
      case TrophyFilter.inProgress:
        return 'In Progress';
      case TrophyFilter.locked:
        return 'Locked';
    }
  }

  IconData get icon {
    switch (this) {
      case TrophyFilter.all:
        return Icons.grid_view_rounded;
      case TrophyFilter.earned:
        return Icons.emoji_events;
      case TrophyFilter.inProgress:
        return Icons.trending_up;
      case TrophyFilter.locked:
        return Icons.lock_outline;
    }
  }
}

/// Trophy Room - View all trophies with filtering and categories
class TrophyRoomScreen extends ConsumerStatefulWidget {
  const TrophyRoomScreen({super.key});

  @override
  ConsumerState<TrophyRoomScreen> createState() => _TrophyRoomScreenState();
}

class _TrophyRoomScreenState extends ConsumerState<TrophyRoomScreen>
    with SingleTickerProviderStateMixin {
  TrophyFilter _selectedFilter = TrophyFilter.all;
  TrophyCategory? _selectedCategory;
  late TabController _tabController;

  // Simplified tabs: All, Fitness, Lifestyle, Special
  static const List<String> _tabNames = ['All', 'Fitness', 'Lifestyle', 'Special'];

  // Category groupings for tabs
  static const Map<String, List<TrophyCategory>> _categoryGroups = {
    'Fitness': [
      TrophyCategory.exerciseMastery,
      TrophyCategory.volume,
      TrophyCategory.time,
      TrophyCategory.personalRecords,
      TrophyCategory.consistency,
    ],
    'Lifestyle': [
      TrophyCategory.nutrition,
      TrophyCategory.fasting,
      TrophyCategory.bodyComposition,
      TrophyCategory.social,
    ],
    'Special': [
      TrophyCategory.aiCoach,
      TrophyCategory.special,
      TrophyCategory.worldRecord,
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabNames.length,
      vsync: this,
    );
    _tabController.addListener(_onTabChanged);
    // Defer provider modification until after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {});
    HapticService.light();
  }

  List<TrophyCategory>? _getSelectedCategories() {
    if (_tabController.index == 0) return null; // All
    final tabName = _tabNames[_tabController.index];
    return _categoryGroups[tabName];
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
    // Filter by category group
    final selectedCategories = _getSelectedCategories();
    var filtered = selectedCategories != null
        ? trophies.where((t) => selectedCategories.contains(t.trophy.trophyCategory)).toList()
        : trophies;

    // Filter by status
    switch (_selectedFilter) {
      case TrophyFilter.all:
        break;
      case TrophyFilter.earned:
        filtered = filtered.where((t) => t.isEarned).toList();
        break;
      case TrophyFilter.inProgress:
        filtered = filtered.where((t) => !t.isEarned && t.progressPercentage > 0).toList();
        break;
      case TrophyFilter.locked:
        filtered = filtered.where((t) => !t.isEarned && t.progressPercentage == 0).toList();
        break;
    }

    // Filter out non-visible trophies (hidden until earned)
    filtered = filtered.where((t) => t.isVisible).toList();

    // Sort: earned first, then by progress, then by tier
    filtered.sort((a, b) {
      if (a.isEarned != b.isEarned) {
        return a.isEarned ? -1 : 1;
      }
      if (a.progressPercentage != b.progressPercentage) {
        return b.progressPercentage.compareTo(a.progressPercentage);
      }
      return a.trophy.tierLevel.compareTo(b.trophy.tierLevel);
    });

    return filtered;
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
    final userXp = xpState.userXp;
    final allTrophies = xpState.allTrophies;
    final summary = xpState.trophySummary;
    final isLoading = xpState.isLoading || xpState.isLoadingTrophies;

    final filteredTrophies = _filterTrophies(allTrophies);

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: bgColor,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: textColor),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.leaderboard_outlined, color: textMuted),
                onPressed: () => context.push('/xp-leaderboard'),
                tooltip: 'XP Leaderboard',
              ),
            ],
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

          // Category tabs - styled container
          SliverToBoxAdapter(
            child: _buildCategoryTabs(isDark, elevatedColor, accentColor, textMuted, cardBorder),
          ),

          // Filter chips
          SliverToBoxAdapter(
            child: _buildFilterChips(isDark, textColor, textMuted, cardBorder, accentColor),
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

          // Trophy list
          if (!isLoading && filteredTrophies.isEmpty)
            SliverToBoxAdapter(
              child: _buildEmptyState(textMuted),
            ),

          if (!isLoading && filteredTrophies.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: _buildTrophyList(
                filteredTrophies,
                isDark,
                textColor,
                textMuted,
                elevatedColor,
                cardBorder,
                accentColor,
              ),
            ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
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

  Widget _buildCategoryTabs(
    bool isDark,
    Color elevatedColor,
    Color accentColor,
    Color textMuted,
    Color cardBorder,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(12),
        border: isDark ? null : Border.all(color: cardBorder),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: accentColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        labelColor: accentColor,
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
        tabs: _tabNames.map((name) => Tab(text: name)).toList(),
      ),
    );
  }

  Widget _buildFilterChips(
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
          children: TrophyFilter.values.map((filter) {
            final isSelected = _selectedFilter == filter;
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
                  setState(() => _selectedFilter = filter);
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
            label: 'Secret',
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
    switch (_selectedFilter) {
      case TrophyFilter.earned:
        message = 'No trophies earned yet.\nComplete workouts to start earning!';
        break;
      case TrophyFilter.inProgress:
        message = 'No trophies in progress.\nStart working toward your goals!';
        break;
      case TrophyFilter.locked:
        message = 'All trophies are either earned or in progress!';
        break;
      case TrophyFilter.all:
        message = 'No trophies available in this category.';
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

  Widget _buildTrophyList(
    List<TrophyProgress> trophies,
    bool isDark,
    Color textColor,
    Color textMuted,
    Color elevatedColor,
    Color cardBorder,
    Color accentColor,
  ) {
    // Group by category if showing "All" tab
    if (_tabController.index == 0) {
      return _buildGroupedTrophyList(
        trophies,
        isDark,
        textColor,
        textMuted,
        elevatedColor,
        cardBorder,
        accentColor,
      );
    }

    // Show flat list for specific tab
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final trophy = trophies[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
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
        },
        childCount: trophies.length,
      ),
    );
  }

  Widget _buildGroupedTrophyList(
    List<TrophyProgress> trophies,
    bool isDark,
    Color textColor,
    Color textMuted,
    Color elevatedColor,
    Color cardBorder,
    Color accentColor,
  ) {
    // Group trophies by tab groups (Fitness, Lifestyle, Special)
    final groupedByTab = <String, List<TrophyProgress>>{};

    for (final entry in _categoryGroups.entries) {
      final tabName = entry.key;
      final categories = entry.value;
      final tabTrophies = trophies.where(
        (t) => categories.contains(t.trophy.trophyCategory)
      ).toList();
      if (tabTrophies.isNotEmpty) {
        groupedByTab[tabName] = tabTrophies;
      }
    }

    final tabOrder = ['Fitness', 'Lifestyle', 'Special'].where((t) => groupedByTab.containsKey(t)).toList();

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final tabName = tabOrder[index];
          final tabTrophies = groupedByTab[tabName]!;
          final earnedCount = tabTrophies.where((t) => t.isEarned).length;
          final tabIndex = _tabNames.indexOf(tabName);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tab group header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      _getTabIcon(tabName),
                      size: 20,
                      color: textMuted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tabName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        overflow: TextOverflow.ellipsis,
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
                        '$earnedCount / ${tabTrophies.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: earnedCount > 0 ? AppColors.green : textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ...tabTrophies.take(4).map((trophy) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _TrophyCard(
                    trophyProgress: trophy,
                    compact: true,
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
              if (tabTrophies.length > 4)
                TextButton(
                  onPressed: () {
                    HapticService.light();
                    _tabController.animateTo(tabIndex);
                  },
                  child: Text(
                    'View all ${tabTrophies.length} trophies →',
                    style: TextStyle(
                      fontSize: 13,
                      color: accentColor,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
            ],
          );
        },
        childCount: tabOrder.length,
      ),
    );
  }

  IconData _getTabIcon(String tabName) {
    switch (tabName) {
      case 'Fitness':
        return Icons.fitness_center;
      case 'Lifestyle':
        return Icons.self_improvement;
      case 'Special':
        return Icons.auto_awesome;
      default:
        return Icons.emoji_events;
    }
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
  final bool compact;
  final bool isDark;
  final Color textColor;
  final Color textMuted;
  final Color elevatedColor;
  final Color cardBorder;
  final Color accentColor;

  const _TrophyCard({
    required this.trophyProgress,
    this.onTap,
    this.compact = false,
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
    final tier = trophy.trophyTier;
    final primaryColor = tier.primaryColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(compact ? 12 : 16),
        decoration: BoxDecoration(
          color: isEarned
              ? primaryColor.withValues(alpha: 0.15)
              : elevatedColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEarned
                ? primaryColor.withValues(alpha: 0.4)
                : cardBorder,
            width: isEarned ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Trophy icon
            Container(
              width: compact ? 36 : 48,
              height: compact ? 36 : 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isEarned
                    ? LinearGradient(
                        colors: tier.gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isEarned ? null : textMuted.withValues(alpha: 0.2),
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
                  trophy.icon,
                  style: TextStyle(
                    fontSize: compact ? 18 : 24,
                  ),
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
                      fontSize: compact ? 14 : 16,
                      fontWeight: FontWeight.w600,
                      color: isEarned ? textColor : textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isEarned
                              ? primaryColor.withValues(alpha: 0.2)
                              : textMuted.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tier.displayName,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isEarned ? primaryColor : textMuted,
                          ),
                        ),
                      ),
                      if (!compact) ...[
                        const SizedBox(width: 8),
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
                            '+${trophy.xpReward} XP',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: accentColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (!compact && !isEarned) ...[
                    const SizedBox(height: 8),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: trophyProgress.progressFraction,
                        minHeight: 6,
                        backgroundColor: textMuted.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation(primaryColor.withValues(alpha: 0.7)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${trophyProgress.currentValue.toInt()} / ${trophy.thresholdValue?.toInt() ?? 0} • ${trophyProgress.progressPercentage.round()}%',
                      style: TextStyle(
                        fontSize: 10,
                        color: textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Status icon
            if (isEarned)
              Icon(
                Icons.check_circle,
                color: primaryColor,
                size: compact ? 18 : 24,
              )
            else if (compact)
              Text(
                '${trophyProgress.progressPercentage.round()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textMuted,
                ),
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

/// Category header with trophy count
class _TrophyCategoryHeader extends StatelessWidget {
  final TrophyCategory category;
  final int earnedCount;
  final int totalCount;
  final Color textColor;
  final Color textMuted;
  final Color accentColor;

  const _TrophyCategoryHeader({
    required this.category,
    required this.earnedCount,
    required this.totalCount,
    required this.textColor,
    required this.textMuted,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(
            category.iconData,
            size: 20,
            color: textMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              category.displayName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              overflow: TextOverflow.ellipsis,
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
              '$earnedCount / $totalCount',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: earnedCount > 0 ? AppColors.green : textMuted,
              ),
            ),
          ),
        ],
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
    final primaryColor = tier.primaryColor;

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
                          gradient: isEarned
                              ? LinearGradient(colors: tier.gradientColors)
                              : null,
                          color: isEarned ? null : textMuted.withValues(alpha: 0.2),
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
                            trophy.icon,
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
                          color: textColor,
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
                          tier.displayName,
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
                      else
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
                                  '+${trophy.xpReward} XP',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: accentColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (trophy.hasMerchReward)
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
