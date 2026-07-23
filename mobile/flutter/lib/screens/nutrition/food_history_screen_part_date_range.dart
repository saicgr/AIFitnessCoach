part of 'food_history_screen.dart';


// ─── Date Range Enum ────────────────────────────────────────────────────────

enum _DateRange {
  all('All Time'),
  today('Today'),
  thisWeek('This Week'),
  thisMonth('This Month'),
  last30('Last 30d'),
  custom('Custom');

  final String label;
  const _DateRange(this.label);
}


// ─── Collapsible Filter Bar ─────────────────────────────────────────────────

class _CollapsibleFilterBar extends StatefulWidget {
  final _DateRange selectedDateRange;
  final DateTimeRange? customDateRange;
  final String? selectedMealFilter;
  final String? selectedSourceFilter;
  final ValueChanged<_DateRange> onDateRangeChanged;
  final ValueChanged<String?> onMealFilterChanged;
  final ValueChanged<String?> onSourceFilterChanged;
  final bool isDark;

  const _CollapsibleFilterBar({
    required this.selectedDateRange,
    required this.customDateRange,
    required this.selectedMealFilter,
    required this.selectedSourceFilter,
    required this.onDateRangeChanged,
    required this.onMealFilterChanged,
    required this.onSourceFilterChanged,
    required this.isDark,
  });

  @override
  State<_CollapsibleFilterBar> createState() => _CollapsibleFilterBarState();
}


class _CollapsibleFilterBarState extends State<_CollapsibleFilterBar> {
  bool _expanded = false;

  String get _dateLabel {
    if (widget.selectedDateRange == _DateRange.custom && widget.customDateRange != null) {
      final fmt = DateFormat('MMM d');
      return '${fmt.format(widget.customDateRange!.start)} - ${fmt.format(widget.customDateRange!.end)}';
    }
    return widget.selectedDateRange.label;
  }

  String get _mealLabel {
    if (widget.selectedMealFilter == null) return 'All Meals';
    return widget.selectedMealFilter![0].toUpperCase() +
        widget.selectedMealFilter!.substring(1);
  }

  String get _sourceLabel {
    switch (widget.selectedSourceFilter) {
      case 'usda': return 'USDA';
      case 'usda_branded': return 'Branded';
      case 'openfoodfacts': return 'Open Food Facts';
      case 'indb': return 'Indian';
      case 'cnf': return 'Canadian';
      default: return 'All DBs';
    }
  }

  bool get _hasActiveFilters =>
      widget.selectedDateRange != _DateRange.all ||
      widget.selectedMealFilter != null ||
      widget.selectedSourceFilter != null;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final accent = tc.accent;
    final textMuted = tc.textMuted;
    final textSecondary = tc.textSecondary;
    final cardBg = tc.surface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Collapsed summary bar — always visible
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _hasActiveFilters ? accent : AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.tune,
                    size: 16,
                    color: _hasActiveFilters ? accent : textMuted,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$_dateLabel · $_mealLabel · $_sourceLabel',
                      style: ZType.lbl(
                        11,
                        color: _hasActiveFilters ? textSecondary : textMuted,
                        letterSpacing: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more,
                      size: 20,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded filter rows
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date range chips
                  ZealovaSectionKicker(
                    AppLocalizations.of(context).foodHistoryScreenDateRange,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _DateRange.values.map((range) {
                      final isSelected = widget.selectedDateRange == range;
                      return ZealovaChip(
                        label: range.label,
                        icon: range == _DateRange.custom ? Icons.calendar_today : null,
                        selected: isSelected,
                        onTap: () => widget.onDateRangeChanged(range),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  // Meal type chips
                  ZealovaSectionKicker(
                    AppLocalizations.of(context).foodHistoryScreenMealType,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      (null, 'All', '🍴'),
                      ('breakfast', 'Breakfast', '🍳'),
                      ('lunch', 'Lunch', '🥗'),
                      ('dinner', 'Dinner', '🌙'),
                      ('snack', 'Snack', '🍎'),
                    ].map((filter) {
                      final (value, label, emoji) = filter;
                      final isSelected = widget.selectedMealFilter == value;
                      return ZealovaChip(
                        label: label,
                        emoji: emoji,
                        selected: isSelected,
                        onTap: () => widget.onMealFilterChanged(value),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  // Database source chips
                  ZealovaSectionKicker(
                    AppLocalizations.of(context).foodHistoryScreenDatabase,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      (null, 'All'),
                      ('usda', 'USDA'),
                      ('usda_branded', 'Branded'),
                      ('openfoodfacts', 'Open Food Facts'),
                      ('indb', 'Indian'),
                      ('cnf', 'Canadian'),
                    ].map((filter) {
                      final (value, label) = filter;
                      final isSelected = widget.selectedSourceFilter == value;
                      return ZealovaChip(
                        label: label,
                        selected: isSelected,
                        onTap: () => widget.onSourceFilterChanged(value),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}


// ─── Quick Stats ────────────────────────────────────────────────────────────

class _QuickStats {
  final int totalMeals;
  final int avgDailyCals;
  final double totalProteinG;
  final int daysTracked;
  final FoodLog? topMeal;

  const _QuickStats({
    this.totalMeals = 0,
    this.avgDailyCals = 0,
    this.totalProteinG = 0,
    this.daysTracked = 0,
    this.topMeal,
  });
}


class _QuickStatsCard extends StatelessWidget {
  final _QuickStats stats;
  final Color cardBg;

  const _QuickStatsCard({
    required this.stats,
    required this.cardBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: ZealovaStatTile(
              value: '${stats.totalMeals}',
              label: AppLocalizations.of(context).foodHistoryScreenMeals,
              align: CrossAxisAlignment.center,
            ),
          ),
          _statDivider(),
          Expanded(
            child: ZealovaStatTile(
              value: '${stats.avgDailyCals}',
              label: AppLocalizations.of(context).foodHistoryScreenAvgDay,
              accentValue: true,
              align: CrossAxisAlignment.center,
            ),
          ),
          _statDivider(),
          Expanded(
            child: ZealovaStatTile(
              value: '${stats.totalProteinG.round()}',
              unit: 'g',
              label: AppLocalizations.of(context).weeklyCheckinSheetProtein,
              align: CrossAxisAlignment.center,
            ),
          ),
          _statDivider(),
          Expanded(
            child: ZealovaStatTile(
              value: '${stats.daysTracked}',
              label: AppLocalizations.of(context).scheduleMealDays,
              align: CrossAxisAlignment.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: AppColors.hairline,
    );
  }
}


// ─── Search Results View ────────────────────────────────────────────────────

class _SearchResultsView extends ConsumerWidget {
  final String userId;
  final bool isDark;
  final Function(FoodSearchResult result)? onRelogResult;

  const _SearchResultsView({
    required this.userId,
    required this.isDark,
    this.onRelogResult,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tc = ThemeColors.of(context);
    final searchState = ref.watch(foodSearchStateProvider);
    final textMuted = tc.textMuted;
    final textPrimary = tc.textPrimary;
    final textSecondary = tc.textSecondary;
    final cardBg = tc.surface;
    final cardBorder = AppColors.cardBorder;
    final teal = tc.accent;

    return searchState.when(
      data: (state) {
        if (state is FoodSearchLoading) {
          return Center(child: CircularProgressIndicator(color: teal));
        }
        if (state is FoodSearchError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: textMuted, size: 48),
                const SizedBox(height: 12),
                Text(
                  state.message,
                  style: TextStyle(color: textMuted, fontSize: 14),
                ),
              ],
            ),
          );
        }
        if (state is FoodSearchResults) {
          final results = state;
          if (results.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off, color: textMuted, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'No results for "${results.query}"',
                    style: TextStyle(color: textMuted, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          final allResults = results.allResults;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: allResults.length,
            itemBuilder: (context, index) {
              final result = allResults[index];
              return _SearchResultTile(
                result: result,
                isDark: isDark,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                textMuted: textMuted,
                cardBg: cardBg,
                cardBorder: cardBorder,
                teal: teal,
                onTap: () => onRelogResult?.call(result),
              );
            },
          );
        }
        // FoodSearchInitial
        return const SizedBox.shrink();
      },
      loading: () => Center(child: CircularProgressIndicator(color: teal)),
      error: (e, _) => Center(
        child: Text(
          AppLocalizations.of(context).foodHistoryScreenSearchError,
          style: TextStyle(color: textMuted),
        ),
      ),
    );
  }
}


class _SearchResultTile extends StatelessWidget {
  final FoodSearchResult result;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color cardBg;
  final Color cardBorder;
  final Color teal;
  final VoidCallback? onTap;

  const _SearchResultTile({
    required this.result,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.cardBg,
    required this.cardBorder,
    required this.teal,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.cardBorder),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            result.source.label.substring(0, 1).toUpperCase(),
            style: ZType.lbl(13, color: textMuted, letterSpacing: 0.5),
          ),
        ),
        title: Text(
          result.name,
          style: TextStyle(
            color: textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Row(
            children: [
              Text(
                '${result.calories} cal',
                style: ZType.data(12, color: teal),
              ),
              if (result.protein != null) ...[
                Text('  ', style: TextStyle(color: textMuted, fontSize: 12)),
                Text(
                  '${result.protein!.round()}g P',
                  style: ZType.data(12, color: AppColors.macroProtein),
                ),
              ],
              Text(
                '  ${result.source.label}',
                style: TextStyle(color: textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
        trailing: Icon(Icons.add_circle_outline, color: teal, size: 22),
        onTap: onTap,
      ),
    );
  }
}


// ─── History List View ──────────────────────────────────────────────────────

class _HistoryListView extends StatelessWidget {
  final List<FoodLog> logs;
  final List<SavedFood> frequentFoods;
  final Map<String, List<FoodLog>> groupedLogs;
  final _QuickStats stats;
  final bool hasMore;
  final bool isLoadingMore;
  final bool isDark;
  final VoidCallback onLoadMore;
  final Function(SavedFood) onRelogSavedFood;
  final Function(FoodLog) onRelogFoodLog;
  final Function(FoodLog) onEditFoodLog;
  final Function(FoodLog) onDeleteFoodLog;
  final String Function(String) getMealEmoji;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color cardBg;
  final Color cardBorder;
  final Color teal;
  final ApiClient? apiClient;

  const _HistoryListView({
    required this.logs,
    required this.frequentFoods,
    required this.groupedLogs,
    required this.stats,
    required this.hasMore,
    required this.isLoadingMore,
    required this.isDark,
    required this.onLoadMore,
    required this.onRelogSavedFood,
    required this.onRelogFoodLog,
    required this.onEditFoodLog,
    required this.onDeleteFoodLog,
    required this.getMealEmoji,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.cardBg,
    required this.cardBorder,
    required this.teal,
    this.apiClient,
  });

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty && frequentFoods.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restaurant_outlined, color: textMuted, size: 56),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).foodHistoryScreenNoFoodHistoryYet.toUpperCase(),
              style: ZType.disp(18, color: textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).foodHistoryScreenStartLoggingMealsTo,
              style: TextStyle(color: textMuted, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // Quick stats card
        if (stats.totalMeals > 0) ...[
          _QuickStatsCard(
            stats: stats,
            cardBg: cardBg,
          ),
          const SizedBox(height: 16),
        ],

        // Frequently Eaten section
        if (frequentFoods.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.bolt,
            title: AppLocalizations.of(context).foodHistoryScreenFrequentlyEaten,
            textPrimary: textPrimary,
            teal: teal,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: frequentFoods.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final food = frequentFoods[index];
                return _FrequentFoodChip(
                  food: food,
                  rank: index + 1,
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  teal: teal,
                  onTap: () => onRelogSavedFood(food),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Recent History section
        if (logs.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.schedule,
            title: AppLocalizations.of(context).nutritionShowcaseRecent,
            textPrimary: textPrimary,
            teal: teal,
          ),
          const SizedBox(height: 8),
          ...groupedLogs.entries.expand((entry) {
            // Per-day summary
            final dayLogs = entry.value;
            final dayCals = dayLogs.fold<int>(0, (s, l) => s + l.totalCalories);
            // Per-day sum-of-known: an unknown-macro meal contributes 0 to the
            // day protein total (`?? 0` INSIDE the sum), never "—".
            final dayProtein =
                dayLogs.fold<double>(0, (s, l) => s + (l.proteinG ?? 0));

            return [
              // Date header with day totals
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Row(
                  children: [
                    Text(
                      entry.key.toUpperCase(),
                      style: ZType.lbl(12, color: textSecondary, letterSpacing: 1.4),
                    ),
                    const Spacer(),
                    Text(
                      '$dayCals cal',
                      style: ZType.data(12, color: teal),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${dayProtein.round()}g P',
                      style: ZType.data(12, color: AppColors.macroProtein),
                    ),
                  ],
                ),
              ),
              // Food log items for this date
              ...dayLogs.map((log) => _FoodLogTile(
                    log: log,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    cardBg: cardBg,
                    cardBorder: cardBorder,
                    teal: teal,
                    getMealEmoji: getMealEmoji,
                    onTap: () => onEditFoodLog(log),
                    onDismissed: () => onDeleteFoodLog(log),
                    apiClient: apiClient,
                  )),
            ];
          }),

          // Load more button
          if (hasMore)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: isLoadingMore
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: teal,
                        ),
                      )
                    : TextButton(
                        onPressed: onLoadMore,
                        child: Text(
                          AppLocalizations.of(context).foodHistoryScreenLoadMore.toUpperCase(),
                          style: ZType.lbl(12, color: teal, letterSpacing: 1.5),
                        ),
                      ),
              ),
            ),
        ],

        const SizedBox(height: 32),
      ],
    );
  }
}


// ─── Section Header ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color textPrimary;
  final Color teal;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.textPrimary,
    required this.teal,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: teal, size: 16),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: ZType.lbl(13, color: textPrimary, letterSpacing: 1.5),
        ),
      ],
    );
  }
}

