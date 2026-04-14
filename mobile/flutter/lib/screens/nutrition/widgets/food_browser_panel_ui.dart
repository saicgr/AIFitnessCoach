part of 'food_browser_panel.dart';

/// UI builder methods extracted from _FoodBrowserPanelState
extension _FoodBrowserPanelStateUI on _FoodBrowserPanelState {

  // ─── Browse Mode ─────────────────────────────────────────────

  Widget _buildBrowseMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter tabs
        _BrowseFilterTabs(
          selected: widget.filter,
          onChanged: widget.onFilterChanged,
          isDark: widget.isDark,
        ),
        const SizedBox(height: 8),
        // Content based on selected filter
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _buildBrowseContent(),
          ),
        ),
      ],
    );
  }


  Widget _buildBrowseContent() {
    switch (widget.filter) {
      case FoodBrowserFilter.recent:
        return _buildRecentAndSavedView();
      case FoodBrowserFilter.saved:
        return _buildSavedOnlyView();
      case FoodBrowserFilter.foodDb:
        return _buildFoodDbView();
    }
  }


  Widget _buildRecentAndSavedView() {
    final state = ref.watch(nutritionProvider);
    final recentLogs = state.recentLogs;
    final textMuted = widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    // Deduplicate recent items by food name
    final seen = <String>{};
    final uniqueRecent = <FoodLog>[];
    for (final log in recentLogs) {
      final name = log.foodItems.isNotEmpty ? log.foodItems.first.name : log.mealType;
      if (seen.add(name.toLowerCase())) {
        uniqueRecent.add(log);
      }
      if (uniqueRecent.length >= 8) break;
    }

    if (uniqueRecent.isEmpty && _savedFoods.isEmpty && !_savedFoodsLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.restaurant_outlined, color: textMuted, size: 40),
              const SizedBox(height: 12),
              Text(
                'Log a meal to see your history here',
                style: TextStyle(color: textMuted, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      children: [
        // Recent section
        if (uniqueRecent.isNotEmpty) ...[
          _BrowseSectionHeader(
            icon: Icons.schedule,
            title: 'RECENT',
            count: uniqueRecent.length,
            onSeeAll: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FoodHistoryScreen(userId: widget.userId)),
              );
            },
            isDark: widget.isDark,
          ),
          const SizedBox(height: 6),
          ...uniqueRecent.map((log) {
            final name = log.foodItems.isNotEmpty ? log.foodItems.first.name : log.mealType;
            final key = 'recent_${log.id}';
            return _FoodBrowserItem(
              name: name,
              calories: log.totalCalories,
              logState: _logStates[key],
              onAdd: () => _relogFoodLog(log),
              isDark: widget.isDark,
              imageUrl: log.imageUrl,
              sourceType: log.sourceType,
              heroTagSuffix: 'recent-${log.id}',
            );
          }),
          const SizedBox(height: 12),
        ],
        // Saved section
        if (_savedFoodsLoading)
          ..._buildShimmerRows(3)
        else if (_savedFoods.isNotEmpty) ...[
          _BrowseSectionHeader(
            icon: Icons.bookmark_outline,
            title: 'SAVED',
            count: _savedFoods.length,
            onSeeAll: () {
              widget.onFilterChanged(FoodBrowserFilter.saved);
            },
            isDark: widget.isDark,
          ),
          const SizedBox(height: 6),
          ..._savedFoods.take(5).map((food) {
            final key = 'saved_${food.id}';
            return _FoodBrowserItem(
              name: food.name,
              calories: food.totalCalories ?? 0,
              logState: _logStates[key],
              onAdd: () => _relogSavedFood(food),
              isDark: widget.isDark,
              imageUrl: food.imageUrl,
              sourceType: food.sourceType,
              heroTagSuffix: 'saved-${food.id}',
            );
          }),
        ],
      ],
    );
  }


  Widget _buildSavedOnlyView() {
    final textMuted = widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    if (_savedFoodsLoading) {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        children: [
          _BrowseSectionHeader(
            icon: Icons.bookmark,
            title: 'YOUR SAVED FOODS',
            isDark: widget.isDark,
          ),
          const SizedBox(height: 6),
          ..._buildShimmerRows(5),
        ],
      );
    }

    if (_savedFoods.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_border, color: textMuted, size: 40),
              const SizedBox(height: 12),
              Text(
                'No saved foods yet',
                style: TextStyle(color: textMuted, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Star foods after logging to save them',
                style: TextStyle(color: textMuted.withValues(alpha: 0.7), fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.pixels >= notification.metrics.maxScrollExtent - 100) {
          _loadMoreSaved();
        }
        return false;
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        children: [
          _BrowseSectionHeader(
            icon: Icons.bookmark,
            title: 'YOUR SAVED FOODS',
            isDark: widget.isDark,
          ),
          const SizedBox(height: 6),
          ..._savedFoods.map((food) {
            final key = 'saved_${food.id}';
            return _FoodBrowserItem(
              name: food.name,
              calories: food.totalCalories ?? 0,
              subtitle: food.description,
              logState: _logStates[key],
              onAdd: () => _relogSavedFood(food),
              isDark: widget.isDark,
              imageUrl: food.imageUrl,
              sourceType: food.sourceType,
              heroTagSuffix: 'saved-full-${food.id}',
            );
          }),
          if (_savedHasMore)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: widget.isDark ? AppColors.teal : AppColorsLight.teal,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }


  List<Widget> _buildShimmerRows(int count) {
    final elevated = widget.isDark ? AppColors.elevated : AppColorsLight.elevated;
    return List.generate(count, (i) => Container(
      height: 52,
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: elevated.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
    ));
  }

}
