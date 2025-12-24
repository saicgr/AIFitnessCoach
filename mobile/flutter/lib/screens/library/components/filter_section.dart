import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/filter_option.dart';

/// Collapsible filter section with multi-select chips
class FilterSection extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<FilterOption> options;
  final Set<String> selectedValues;
  final Function(String) onToggle;
  final int initialShowCount;
  final bool initiallyExpanded;

  const FilterSection({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.options,
    required this.selectedValues,
    required this.onToggle,
    this.initialShowCount = 6,
    this.initiallyExpanded = false,
  });

  @override
  State<FilterSection> createState() => _FilterSectionState();
}

class _FilterSectionState extends State<FilterSection> {
  bool _showAll = false;
  bool _isExpanded = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isExpanded =
        widget.initiallyExpanded || widget.selectedValues.isNotEmpty;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(FilterSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-expand if any value is selected
    if (widget.selectedValues.isNotEmpty && !_isExpanded) {
      setState(() => _isExpanded = true);
    }
  }

  List<FilterOption> get _filteredOptions {
    List<FilterOption> options;
    if (_searchQuery.isEmpty) {
      options = List.from(widget.options);
    } else {
      options = widget.options
          .where((opt) =>
              opt.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Ensure "Other" is always at the end
    options.sort((a, b) {
      final aIsOther = a.name.toLowerCase() == 'other';
      final bIsOther = b.name.toLowerCase() == 'other';
      if (aIsOther && !bIsOther) return 1;
      if (!aIsOther && bIsOther) return -1;
      return 0; // Keep original order for non-"Other" items
    });

    return options;
  }

  String _shortenName(String name) {
    // Shorten long equipment names
    if (name.length <= 20) return name;

    // Common abbreviations
    final replacements = {
      'Hammer Strength': 'HS',
      'Iso-Lateral': 'Iso',
      'MTS ': '',
      'Machine': 'Mach.',
      'Resistance Band': 'Res. Band',
      'Cable Pulley Machine': 'Cable',
      'Dual Cable Pulley Machine': 'Dual Cable',
      'Plate-Loaded': 'Plate',
      'Plate Loaded': 'Plate',
    };

    String shortened = name;
    for (final entry in replacements.entries) {
      shortened = shortened.replaceAll(entry.key, entry.value);
    }

    // If still too long, truncate
    if (shortened.length > 25) {
      shortened = '${shortened.substring(0, 22)}...';
    }

    return shortened;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final glassSurface =
        isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    final filteredOpts = _filteredOptions;
    final displayOptions = _showAll || _searchQuery.isNotEmpty
        ? filteredOpts
        : filteredOpts.take(widget.initialShowCount).toList();
    final hasMore =
        filteredOpts.length > widget.initialShowCount && _searchQuery.isEmpty;

    final hasSelection = widget.selectedValues.isNotEmpty;
    final selectionCount = widget.selectedValues.length;
    final selectionText = selectionCount == 1
        ? widget.selectedValues.first
        : '$selectionCount selected';

    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasSelection ? widget.color.withOpacity(0.3) : cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Collapsible header
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(widget.icon, size: 18, color: widget.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.textPrimary
                                    : AppColorsLight.textPrimary,
                              ),
                            ),
                            if (hasSelection) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: widget.color.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$selectionCount',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: widget.color,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (hasSelection)
                          Text(
                            selectionText,
                            style: TextStyle(
                              fontSize: 12,
                              color: widget.color,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: textMuted,
                  ),
                ],
              ),
            ),
          ),

          // Expandable options
          if (_isExpanded) ...[
            Divider(height: 1, color: cardBorder),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search field - only show if many options
                  if (widget.options.length > 6) ...[
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: glassSurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.textPrimary
                              : AppColorsLight.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'Search ${widget.title.toLowerCase()}...',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: textMuted,
                          ),
                          prefixIcon:
                              Icon(Icons.search, size: 20, color: textMuted),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                  child: Icon(Icons.close,
                                      size: 18, color: textMuted),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // No results message
                  if (displayOptions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'No matching options',
                          style: TextStyle(
                            fontSize: 13,
                            color: textMuted,
                          ),
                        ),
                      ),
                    )
                  else
                    // Options wrap - multi-select chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: displayOptions.map((option) {
                        final isSelected = widget.selectedValues.any(
                            (v) => v.toLowerCase() == option.name.toLowerCase());
                        final displayName = _shortenName(option.name);
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => widget.onToggle(option.name),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? widget.color.withOpacity(0.2)
                                    : (isDark
                                        ? AppColors.glassSurface
                                        : AppColorsLight.glassSurface),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? widget.color
                                      : Colors.transparent,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isSelected) ...[
                                    Icon(Icons.check,
                                        size: 16, color: widget.color),
                                    const SizedBox(width: 4),
                                  ],
                                  Text(
                                    displayName,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? widget.color
                                          : textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                  // Show more/less button
                  if (hasMore)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: GestureDetector(
                        onTap: () => setState(() => _showAll = !_showAll),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _showAll
                                  ? 'Show less'
                                  : 'Show ${widget.options.length - widget.initialShowCount} more',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: widget.color,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _showAll
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              size: 18,
                              color: widget.color,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
