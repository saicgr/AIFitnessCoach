part of 'habits_screen.dart';


/// Stateful content for the Add Habit sheet with search and category filter.
class _AddHabitSheetContent extends StatefulWidget {
  final List<HabitTemplate> allTemplates;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardBg;
  final Color accentColor;
  final bool isDark;
  final WidgetRef ref;
  final VoidCallback onCreateCustom;
  final Future<void> Function(HabitTemplate) onAddTemplate;
  final Color Function(String, Color) parseColor;
  final IconData Function(String) getIconFromName;

  const _AddHabitSheetContent({
    required this.allTemplates,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardBg,
    required this.accentColor,
    required this.isDark,
    required this.ref,
    required this.onCreateCustom,
    required this.onAddTemplate,
    required this.parseColor,
    required this.getIconFromName,
  });

  @override
  State<_AddHabitSheetContent> createState() => _AddHabitSheetContentState();
}


class _AddHabitSheetContentState extends State<_AddHabitSheetContent>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  HabitCategory? _selectedCategory; // null = All
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 3500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<HabitTemplate> get _filteredTemplates {
    var list = widget.allTemplates;
    if (_selectedCategory != null) {
      list = list.where((t) => t.category == _selectedCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((t) =>
        t.name.toLowerCase().contains(q) ||
        t.description.toLowerCase().contains(q)
      ).toList();
    }
    return list;
  }

  Map<HabitCategory, List<HabitTemplate>> get _groupedTemplates {
    final grouped = <HabitCategory, List<HabitTemplate>>{};
    for (final t in _filteredTemplates) {
      grouped.putIfAbsent(t.category, () => []).add(t);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupedTemplates;
    final hasResults = grouped.isNotEmpty;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              Text(
                'Add Habit',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: widget.textPrimary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.close, color: widget.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),

        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            controller: _searchController,
            style: TextStyle(color: widget.textPrimary, fontSize: 14),
            onChanged: (v) => setState(() => _searchQuery = v.trim()),
            decoration: InputDecoration(
              hintText: 'Search habits...',
              hintStyle: TextStyle(color: widget.textSecondary.withValues(alpha: 0.5), fontSize: 14),
              prefixIcon: Icon(Icons.search, color: widget.textSecondary, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      child: Icon(Icons.close, color: widget.textSecondary, size: 18),
                    )
                  : null,
              filled: true,
              fillColor: widget.cardBg,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        // Category filter chips
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoryChip(null, 'All'),
                ...HabitCategory.values.map(
                  (c) => _buildCategoryChip(c, c.label),
                ),
              ],
            ),
          ),
        ),

        // Scrollable content
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              // Create Custom — only show when not searching
              if (_searchQuery.isEmpty && _selectedCategory == null) ...[
                GestureDetector(
                  onTap: widget.onCreateCustom,
                  child: AnimatedBuilder(
                    animation: _shimmerController,
                    builder: (context, child) {
                      final t = _shimmerController.value;
                      // Shimmer sweeps during first 35% of cycle, idle the rest
                      final shimmerProgress = t < 0.35 ? t / 0.35 : -1.0;
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Stack(
                          children: [
                            child!,
                            if (shimmerProgress >= 0)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: FractionallySizedBox(
                                    widthFactor: 0.4,
                                    alignment: Alignment(-1.0 + 2.4 * shimmerProgress, 0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.white.withValues(alpha: 0),
                                            Colors.white.withValues(alpha: widget.isDark ? 0.12 : 0.25),
                                            Colors.white.withValues(alpha: 0),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.accentColor.withValues(alpha: 0.15),
                            widget.accentColor.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: widget.accentColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: widget.accentColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.edit_outlined,
                              color: widget.isDark ? Colors.black : Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Create Custom Habit',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: widget.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Define your own habit with custom name & icon',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: widget.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios, color: widget.accentColor, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'OR CHOOSE A TEMPLATE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: widget.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Empty state
              if (!hasResults)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.search_off, color: widget.textSecondary.withValues(alpha: 0.4), size: 40),
                        const SizedBox(height: 12),
                        Text(
                          'No habits found',
                          style: TextStyle(color: widget.textSecondary, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),

              // Templates by category
              for (final category in HabitCategory.values)
                if (grouped.containsKey(category)) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 12),
                    child: Text(
                      category.label.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: widget.textSecondary.withValues(alpha: 0.7),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  ...grouped[category]!.map((template) {
                    final templateColor = widget.parseColor(template.color, AppColors.accent);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () => widget.onAddTemplate(template),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: widget.cardBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: templateColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  widget.getIconFromName(template.icon),
                                  color: templateColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      template.name,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: widget.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      template.description,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: widget.textSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.add_circle_outline,
                                color: templateColor, size: 24),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(HabitCategory? category, String label) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          HapticService.selection();
          setState(() => _selectedCategory = category);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? widget.accentColor
                : widget.cardBg,
            borderRadius: BorderRadius.circular(17),
            border: isSelected
                ? null
                : Border.all(color: widget.textSecondary.withValues(alpha: 0.15)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? (widget.isDark ? Colors.black : Colors.white)
                  : widget.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

