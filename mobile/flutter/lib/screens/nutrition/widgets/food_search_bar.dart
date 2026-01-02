import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/food_search_service.dart';

/// Filter options for food search
enum FoodSearchFilter {
  all('All'),
  saved('Saved'),
  recent('Recent');

  final String label;
  const FoodSearchFilter(this.label);
}

/// A Material 3 search bar for food search with debouncing
class FoodSearchBar extends ConsumerStatefulWidget {
  final String userId;
  final Function(String query)? onSearch;
  final Function(FoodSearchResult result)? onResultSelected;
  final Function(FoodSearchFilter filter)? onFilterChanged;
  final FoodSearchFilter initialFilter;
  final bool autofocus;
  final String? hintText;
  final EdgeInsetsGeometry? padding;

  const FoodSearchBar({
    super.key,
    required this.userId,
    this.onSearch,
    this.onResultSelected,
    this.onFilterChanged,
    this.initialFilter = FoodSearchFilter.all,
    this.autofocus = false,
    this.hintText,
    this.padding,
  });

  @override
  ConsumerState<FoodSearchBar> createState() => _FoodSearchBarState();
}

class _FoodSearchBarState extends ConsumerState<FoodSearchBar> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late FoodSearchFilter _selectedFilter;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _selectedFilter = widget.initialFilter;

    _focusNode.addListener(_handleFocusChange);

    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _onSearchChanged(String query) {
    final searchService = ref.read(foodSearchServiceProvider);
    searchService.search(query, widget.userId);
    widget.onSearch?.call(query);
  }

  void _clearSearch() {
    _controller.clear();
    final searchService = ref.read(foodSearchServiceProvider);
    searchService.cancel();
    // Emit initial state to clear results
    _onSearchChanged('');
  }

  void _onFilterTapped(FoodSearchFilter filter) {
    setState(() {
      _selectedFilter = filter;
    });
    widget.onFilterChanged?.call(filter);

    // Re-search with new filter if there's a query
    if (_controller.text.isNotEmpty) {
      _onSearchChanged(_controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final searchState = ref.watch(foodSearchStateProvider);

    final backgroundColor =
        isDark ? AppColors.elevated : AppColorsLight.elevated;
    final borderColor = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accentColor = isDark ? AppColors.cyan : AppColorsLight.cyan;

    final isLoading = searchState.maybeWhen(
      data: (state) => state is FoodSearchLoading,
      orElse: () => false,
    );

    return Padding(
      padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isFocused ? accentColor : borderColor,
                width: _isFocused ? 2 : 1,
              ),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: accentColor.withOpacity(0.2),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // Search icon or loading indicator
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: isLoading
                        ? SizedBox(
                            key: const ValueKey('loading'),
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(accentColor),
                            ),
                          )
                        : Icon(
                            key: const ValueKey('search'),
                            Icons.search_rounded,
                            color: _isFocused ? accentColor : textMuted,
                            size: 22,
                          ),
                  ),
                ),

                // Text field
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    onChanged: _onSearchChanged,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.hintText ?? 'Search foods...',
                      hintStyle: TextStyle(
                        color: textMuted,
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (query) {
                      // Add to recent searches
                      if (query.trim().isNotEmpty) {
                        ref
                            .read(recentSearchesProvider.notifier)
                            .addSearch(query);
                      }
                    },
                  ),
                ),

                // Clear button
                if (_controller.text.isNotEmpty)
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: textMuted,
                      size: 20,
                    ),
                    onPressed: _clearSearch,
                    splashRadius: 20,
                  )
                else
                  const SizedBox(width: 8),
              ],
            ),
          ),

          // Filter chips
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: FoodSearchFilter.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = FoodSearchFilter.values[index];
                final isSelected = _selectedFilter == filter;

                return _FilterChip(
                  label: filter.label,
                  isSelected: isSelected,
                  onTap: () => _onFilterTapped(filter),
                  accentColor: accentColor,
                  isDark: isDark,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual filter chip
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color accentColor;
  final bool isDark;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.accentColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isSelected
        ? accentColor
        : isDark
            ? AppColors.elevated
            : AppColorsLight.elevated;
    final textColor = isSelected
        ? Colors.white
        : isDark
            ? AppColors.textSecondary
            : AppColorsLight.textSecondary;
    final borderColor = isSelected
        ? accentColor
        : isDark
            ? AppColors.cardBorder
            : AppColorsLight.cardBorder;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Compact search bar for inline use
class FoodSearchBarCompact extends ConsumerStatefulWidget {
  final String userId;
  final Function(String query)? onSearch;
  final bool autofocus;
  final String? hintText;

  const FoodSearchBarCompact({
    super.key,
    required this.userId,
    this.onSearch,
    this.autofocus = false,
    this.hintText,
  });

  @override
  ConsumerState<FoodSearchBarCompact> createState() =>
      _FoodSearchBarCompactState();
}

class _FoodSearchBarCompactState extends ConsumerState<FoodSearchBarCompact> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();

    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    final searchService = ref.read(foodSearchServiceProvider);
    searchService.search(query, widget.userId);
    widget.onSearch?.call(query);
  }

  void _clearSearch() {
    _controller.clear();
    _onSearchChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final searchState = ref.watch(foodSearchStateProvider);

    final backgroundColor =
        isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accentColor = isDark ? AppColors.cyan : AppColorsLight.cyan;

    final isLoading = searchState.maybeWhen(
      data: (state) => state is FoodSearchLoading,
      orElse: () => false,
    );

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                    ),
                  )
                : Icon(
                    Icons.search_rounded,
                    color: textMuted,
                    size: 20,
                  ),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: _onSearchChanged,
              style: TextStyle(
                color: textPrimary,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText ?? 'Search foods...',
                hintStyle: TextStyle(
                  color: textMuted,
                  fontSize: 15,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
              ),
            ),
          ),
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.close_rounded,
                color: textMuted,
                size: 18,
              ),
              onPressed: _clearSearch,
              splashRadius: 18,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
            ),
        ],
      ),
    );
  }
}

/// Recent searches dropdown
class RecentSearchesList extends ConsumerWidget {
  final Function(String query) onSearchTapped;
  final VoidCallback? onClearAll;

  const RecentSearchesList({
    super.key,
    required this.onSearchTapped,
    this.onClearAll,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final recentSearches = ref.watch(recentSearchesProvider);

    if (recentSearches.isEmpty) {
      return const SizedBox.shrink();
    }

    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final backgroundColor =
        isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Searches',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              if (onClearAll != null)
                GestureDetector(
                  onTap: onClearAll,
                  child: Text(
                    'Clear All',
                    style: TextStyle(
                      color: isDark ? AppColors.cyan : AppColorsLight.cyan,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recentSearches.map((search) {
              return GestureDetector(
                onTap: () => onSearchTapped(search),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.glassSurface
                        : AppColorsLight.glassSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? AppColors.cardBorder
                          : AppColorsLight.cardBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 14,
                        color: textMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        search,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
