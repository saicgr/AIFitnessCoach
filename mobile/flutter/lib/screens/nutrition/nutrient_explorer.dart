import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/micronutrients.dart';

/// Nutrient Explorer Tab - MacroFactor/Cronometer inspired
/// Shows all vitamins, minerals, fatty acids, and other nutrients
/// with progress bars and the ability to see top contributors.
class NutrientExplorerTab extends StatefulWidget {
  final String userId;
  final DailyMicronutrientSummary? summary;
  final bool isLoading;
  final VoidCallback onRefresh;
  final bool isDark;

  const NutrientExplorerTab({
    super.key,
    required this.userId,
    this.summary,
    required this.isLoading,
    required this.onRefresh,
    required this.isDark,
  });

  @override
  State<NutrientExplorerTab> createState() => _NutrientExplorerTabState();
}

class _NutrientExplorerTabState extends State<NutrientExplorerTab> {
  String _selectedCategory = 'all';

  @override
  Widget build(BuildContext context) {
    final teal = widget.isDark ? AppColors.teal : AppColorsLight.teal;

    if (widget.isLoading) {
      return _NutrientLoadingSkeleton(isDark: widget.isDark);
    }

    if (widget.summary == null) {
      return _EmptyNutrientState(
        isDark: widget.isDark,
        onRefresh: widget.onRefresh,
      );
    }

    final summary = widget.summary!;

    return RefreshIndicator(
      onRefresh: () async => widget.onRefresh(),
      color: teal,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Score Overview Card
            _NutrientScoreCard(
              summary: summary,
              isDark: widget.isDark,
            ).animate().fadeIn().scale(),

            const SizedBox(height: 16),

            // Category Filter Chips
            _CategoryFilterRow(
              selectedCategory: _selectedCategory,
              onCategoryChanged: (category) {
                setState(() => _selectedCategory = category);
              },
              isDark: widget.isDark,
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 16),

            // Nutrient Sections
            if (_selectedCategory == 'all' || _selectedCategory == 'vitamins')
              _NutrientSection(
                title: 'VITAMINS',
                icon: Icons.wb_sunny_outlined,
                nutrients: summary.vitamins,
                categoryColor: AppColors.textPrimary,
                isDark: widget.isDark,
                onNutrientTap: (nutrient) => _showNutrientDetail(nutrient),
              ).animate().fadeIn(delay: 150.ms),

            if (_selectedCategory == 'all' || _selectedCategory == 'minerals')
              _NutrientSection(
                title: 'MINERALS',
                icon: Icons.diamond_outlined,
                nutrients: summary.minerals,
                categoryColor: AppColors.textSecondary,
                isDark: widget.isDark,
                onNutrientTap: (nutrient) => _showNutrientDetail(nutrient),
              ).animate().fadeIn(delay: 200.ms),

            if (_selectedCategory == 'all' || _selectedCategory == 'fats')
              _NutrientSection(
                title: 'FATTY ACIDS',
                icon: Icons.water_drop_outlined,
                nutrients: summary.fattyAcids,
                categoryColor: AppColors.textSecondary,
                isDark: widget.isDark,
                onNutrientTap: (nutrient) => _showNutrientDetail(nutrient),
              ).animate().fadeIn(delay: 250.ms),

            if (_selectedCategory == 'all' || _selectedCategory == 'other')
              _NutrientSection(
                title: 'OTHER',
                icon: Icons.more_horiz,
                nutrients: summary.other,
                categoryColor: AppColors.textMuted,
                isDark: widget.isDark,
                onNutrientTap: (nutrient) => _showNutrientDetail(nutrient),
              ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  void _showNutrientDetail(NutrientProgress nutrient) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NutrientDetailSheet(
        nutrient: nutrient,
        userId: widget.userId,
        isDark: widget.isDark,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Nutrient Score Card - Shows overall micronutrient score
// ─────────────────────────────────────────────────────────────────

class _NutrientScoreCard extends StatelessWidget {
  final DailyMicronutrientSummary summary;
  final bool isDark;

  const _NutrientScoreCard({
    required this.summary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final score = summary.overallScore;
    final optimalCount = summary.optimalNutrients.length;
    final totalCount = summary.allNutrients.length;
    final lowCount = summary.lowNutrients.length;
    final overCount = summary.overNutrients.length;

    Color scoreColor;
    String scoreLabel;
    if (score >= 80) {
      scoreColor = AppColors.textPrimary;
      scoreLabel = 'Excellent';
    } else if (score >= 60) {
      scoreColor = AppColors.textPrimary;
      scoreLabel = 'Good';
    } else if (score >= 40) {
      scoreColor = AppColors.textSecondary;
      scoreLabel = 'Needs Attention';
    } else {
      scoreColor = AppColors.textSecondary;
      scoreLabel = 'Low';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scoreColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Score Circle
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: scoreColor, width: 4),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${score.toInt()}%',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: scoreColor,
                        ),
                      ),
                      Text(
                        'Score',
                        style: TextStyle(
                          fontSize: 10,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Stats
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nutrient Score',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      scoreLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: scoreColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _StatChip(
                          label: 'Optimal',
                          count: optimalCount,
                          color: AppColors.textPrimary,
                        ),
                        const SizedBox(width: 8),
                        _StatChip(
                          label: 'Low',
                          count: lowCount,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        _StatChip(
                          label: 'High',
                          count: overCount,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar showing optimal percentage
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (score / 100).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: isDark
                        ? AppColors.glassSurface
                        : AppColorsLight.glassSurface,
                    color: scoreColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$optimalCount/$totalCount optimal',
                style: TextStyle(
                  fontSize: 12,
                  color: textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Category Filter Row
// ─────────────────────────────────────────────────────────────────

class _CategoryFilterRow extends StatelessWidget {
  final String selectedCategory;
  final void Function(String) onCategoryChanged;
  final bool isDark;

  const _CategoryFilterRow({
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final categories = [
      ('all', 'All'),
      ('vitamins', 'Vitamins'),
      ('minerals', 'Minerals'),
      ('fats', 'Fats'),
      ('other', 'Other'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected = selectedCategory == cat.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _FilterChip(
              label: cat.$2,
              isSelected: isSelected,
              onTap: () => onCategoryChanged(cat.$1),
              isDark: isDark,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? teal : elevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? teal : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : textMuted,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Nutrient Section - Group of nutrients with header
// ─────────────────────────────────────────────────────────────────

class _NutrientSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<NutrientProgress> nutrients;
  final Color categoryColor;
  final bool isDark;
  final void Function(NutrientProgress) onNutrientTap;

  const _NutrientSection({
    required this.title,
    required this.icon,
    required this.nutrients,
    required this.categoryColor,
    required this.isDark,
    required this.onNutrientTap,
  });

  @override
  Widget build(BuildContext context) {
    if (nutrients.isEmpty) return const SizedBox.shrink();

    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: categoryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textMuted,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                Text(
                  '${nutrients.length} nutrients',
                  style: TextStyle(
                    fontSize: 11,
                    color: textMuted,
                  ),
                ),
              ],
            ),
          ),
          // Nutrient Items
          ...nutrients.map((nutrient) => _NutrientRow(
                nutrient: nutrient,
                categoryColor: categoryColor,
                isDark: isDark,
                onTap: () => onNutrientTap(nutrient),
              )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _NutrientRow extends StatelessWidget {
  final NutrientProgress nutrient;
  final Color categoryColor;
  final bool isDark;
  final VoidCallback onTap;

  const _NutrientRow({
    required this.nutrient,
    required this.categoryColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final glassSurface =
        isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    // Get status color
    final statusColor = _getStatusColor(nutrient.statusEnum);
    final percentage = nutrient.percentage.clamp(0.0, 150.0);
    final displayPercentage = percentage > 100 ? 100.0 : percentage;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Nutrient name
            Expanded(
              flex: 3,
              child: Text(
                nutrient.displayName,
                style: TextStyle(
                  fontSize: 14,
                  color: textPrimary,
                ),
              ),
            ),
            // Current value
            Expanded(
              flex: 2,
              child: Text(
                '${nutrient.formattedCurrent} ${nutrient.unit}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: statusColor,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(width: 12),
            // Progress bar
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (displayPercentage / 100).clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: glassSurface,
                      color: statusColor,
                    ),
                  ),
                  // Floor indicator (if exists)
                  if (nutrient.floorValue != null) ...[
                    Positioned(
                      left: (nutrient.floorValue! / nutrient.targetValue * 100)
                              .clamp(0.0, 100.0) /
                          100 *
                          MediaQuery.of(context).size.width *
                          0.2,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 2,
                        color: textMuted.withOpacity(0.5),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Percentage
            SizedBox(
              width: 40,
              child: Text(
                '${percentage.toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: statusColor,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(NutrientStatus status) {
    switch (status) {
      case NutrientStatus.low:
        return AppColors.textSecondary;
      case NutrientStatus.optimal:
        return AppColors.textPrimary;
      case NutrientStatus.high:
        return AppColors.textSecondary;
      case NutrientStatus.overCeiling:
        return AppColors.textMuted;
    }
  }
}

// ─────────────────────────────────────────────────────────────────
// Nutrient Detail Sheet - Shows detailed info when tapped
// ─────────────────────────────────────────────────────────────────

class NutrientDetailSheet extends StatefulWidget {
  final NutrientProgress nutrient;
  final String userId;
  final bool isDark;
  final List<String>? currentPinnedNutrients;
  final VoidCallback? onPinChanged;

  const NutrientDetailSheet({
    super.key,
    required this.nutrient,
    required this.userId,
    required this.isDark,
    this.currentPinnedNutrients,
    this.onPinChanged,
  });

  @override
  State<NutrientDetailSheet> createState() => _NutrientDetailSheetState();
}

class _NutrientDetailSheetState extends State<NutrientDetailSheet> {
  bool _isPinning = false;
  late bool _isPinned;

  @override
  void initState() {
    super.initState();
    _isPinned = widget.currentPinnedNutrients?.contains(widget.nutrient.nutrientKey) ?? false;
  }

  Future<void> _togglePin() async {
    if (_isPinning) return;

    setState(() => _isPinning = true);

    try {
      // TODO: Call repository to update pinned nutrients
      // For now, just toggle locally
      setState(() {
        _isPinned = !_isPinned;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isPinned
                ? '${widget.nutrient.displayName} added to pinned nutrients'
                : '${widget.nutrient.displayName} removed from pinned nutrients'),
            duration: const Duration(seconds: 2),
          ),
        );
        widget.onPinChanged?.call();
      }
    } catch (e) {
      debugPrint('Error toggling pin: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update pinned nutrients')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPinning = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nearBlack = widget.isDark ? AppColors.nearBlack : AppColorsLight.nearWhite;
    final elevated = widget.isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = widget.isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary =
        widget.isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final teal = widget.isDark ? AppColors.teal : AppColorsLight.teal;

    final statusColor = _getStatusColor(widget.nutrient.statusEnum);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: nearBlack,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: textMuted.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header with pin button
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.nutrient.displayName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getCategoryLabel(widget.nutrient.categoryEnum),
                      style: TextStyle(
                        fontSize: 14,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Pin button
              IconButton(
                onPressed: _isPinning ? null : _togglePin,
                icon: _isPinning
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: teal,
                        ),
                      )
                    : Icon(
                        _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                        color: _isPinned ? teal : textMuted,
                      ),
                tooltip: _isPinned ? 'Unpin nutrient' : 'Pin to dashboard',
              ),
              const SizedBox(width: 8),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getStatusLabel(widget.nutrient.statusEnum),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Big Progress Display
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: elevated,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // Current / Target
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Text(
                          widget.nutrient.formattedCurrent,
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                        Text(
                          'Current',
                          style: TextStyle(
                            fontSize: 12,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        '/',
                        style: TextStyle(
                          fontSize: 36,
                          color: textMuted,
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          widget.nutrient.formattedTarget,
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          'Target ${widget.nutrient.unit}',
                          style: TextStyle(
                            fontSize: 12,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 3-Tier Progress bar with floor/target/ceiling markers
                _ThreeTierProgressBar(
                  currentValue: widget.nutrient.currentValue,
                  floorValue: widget.nutrient.floorValue,
                  targetValue: widget.nutrient.targetValue,
                  ceilingValue: widget.nutrient.ceilingValue,
                  unit: widget.nutrient.unit,
                  statusColor: statusColor,
                  isDark: widget.isDark,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Top Contributors (if available)
          if (widget.nutrient.topContributors != null &&
              widget.nutrient.topContributors!.isNotEmpty) ...[
            Text(
              'TOP CONTRIBUTORS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textMuted,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            ...widget.nutrient.topContributors!.take(3).map((contributor) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        contributor['food_name'] ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 14,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '${contributor['contribution']?.toStringAsFixed(1) ?? '0'} ${widget.nutrient.unit}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          // Nutrient info
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: elevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: textMuted),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getNutrientInfo(widget.nutrient.nutrientKey),
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Color _getStatusColor(NutrientStatus status) {
    switch (status) {
      case NutrientStatus.low:
        return AppColors.textSecondary;
      case NutrientStatus.optimal:
        return AppColors.textPrimary;
      case NutrientStatus.high:
        return AppColors.textSecondary;
      case NutrientStatus.overCeiling:
        return AppColors.textMuted;
    }
  }

  String _getStatusLabel(NutrientStatus status) {
    switch (status) {
      case NutrientStatus.low:
        return 'Below Target';
      case NutrientStatus.optimal:
        return 'Optimal';
      case NutrientStatus.high:
        return 'Above Target';
      case NutrientStatus.overCeiling:
        return 'Over Limit';
    }
  }

  String _getCategoryLabel(NutrientCategory category) {
    switch (category) {
      case NutrientCategory.vitamin:
        return 'Vitamin';
      case NutrientCategory.mineral:
        return 'Mineral';
      case NutrientCategory.fattyAcid:
        return 'Fatty Acid';
      case NutrientCategory.other:
        return 'Other Nutrient';
    }
  }

  String _getNutrientInfo(String key) {
    final info = {
      'vitamin_a_ug': 'Important for vision, immune function, and skin health.',
      'vitamin_c_mg': 'Essential for immune function and collagen production.',
      'vitamin_d_iu': 'Critical for bone health and immune function.',
      'vitamin_e_mg': 'An antioxidant that protects cells from damage.',
      'vitamin_k_ug': 'Important for blood clotting and bone health.',
      'vitamin_b1_mg': 'Helps convert food into energy.',
      'vitamin_b2_mg': 'Important for energy production and cell function.',
      'vitamin_b3_mg': 'Supports digestive system and skin health.',
      'vitamin_b6_mg': 'Important for brain development and function.',
      'vitamin_b9_ug': 'Essential for DNA synthesis and cell division.',
      'vitamin_b12_ug': 'Crucial for nerve function and red blood cell formation.',
      'choline_mg': 'Supports brain health and liver function.',
      'calcium_mg': 'Essential for bone health and muscle function.',
      'iron_mg': 'Critical for oxygen transport in blood.',
      'magnesium_mg': 'Important for muscle and nerve function.',
      'zinc_mg': 'Supports immune function and wound healing.',
      'selenium_ug': 'An antioxidant that supports thyroid function.',
      'potassium_mg': 'Important for heart health and muscle function.',
      'sodium_mg': 'Regulates fluid balance. Excess can increase blood pressure.',
      'phosphorus_mg': 'Essential for bone and teeth health.',
      'copper_mg': 'Helps with iron absorption and nerve function.',
      'manganese_mg': 'Supports bone health and metabolism.',
      'iodine_ug': 'Critical for thyroid hormone production.',
      'omega3_g': 'Reduces inflammation and supports heart health.',
      'omega6_g': 'Essential fatty acid for brain function.',
      'fiber_g': 'Supports digestive health and helps control blood sugar.',
      'cholesterol_mg': 'Used by body for hormones. Excess may affect heart health.',
      'sugar_g': 'Provides quick energy. Excess can affect health.',
      'water_ml': 'Essential for all body functions and hydration.',
      'caffeine_mg': 'Stimulant that affects alertness. Limit recommended.',
    };
    return info[key] ?? 'An important nutrient for overall health.';
  }
}

// ─────────────────────────────────────────────────────────────────
// Loading Skeleton
// ─────────────────────────────────────────────────────────────────

class _NutrientLoadingSkeleton extends StatelessWidget {
  final bool isDark;

  const _NutrientLoadingSkeleton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Score card skeleton
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: elevated,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 16),
          // Filter chips skeleton
          Row(
            children: List.generate(
              4,
              (_) => Container(
                margin: const EdgeInsets.only(right: 8),
                width: 70,
                height: 32,
                decoration: BoxDecoration(
                  color: elevated,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Nutrient sections skeleton
          ...List.generate(
            3,
            (_) => Container(
              margin: const EdgeInsets.only(bottom: 16),
              height: 200,
              decoration: BoxDecoration(
                color: elevated,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────────

class _EmptyNutrientState extends StatelessWidget {
  final bool isDark;
  final VoidCallback onRefresh;

  const _EmptyNutrientState({
    required this.isDark,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: teal.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.science_outlined,
                size: 40,
                color: teal,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Nutrient Data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Log some food to see your micronutrient intake',
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: OutlinedButton.styleFrom(
                foregroundColor: teal,
                side: BorderSide(color: teal),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Three-Tier Progress Bar - Shows floor, target, ceiling
// ─────────────────────────────────────────────────────────────────

class _ThreeTierProgressBar extends StatelessWidget {
  final double currentValue;
  final double? floorValue;
  final double targetValue;
  final double? ceilingValue;
  final String unit;
  final Color statusColor;
  final bool isDark;

  const _ThreeTierProgressBar({
    required this.currentValue,
    this.floorValue,
    required this.targetValue,
    this.ceilingValue,
    required this.unit,
    required this.statusColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    // Calculate the max value for the bar (150% of target or ceiling, whichever is higher)
    final maxValue = ceilingValue != null
        ? ceilingValue! * 1.1
        : targetValue * 1.5;

    // Calculate positions as percentages
    final floorPercent = floorValue != null ? (floorValue! / maxValue) : 0.0;
    final targetPercent = targetValue / maxValue;
    final ceilingPercent = ceilingValue != null ? (ceilingValue! / maxValue) : 1.0;
    final currentPercent = (currentValue / maxValue).clamp(0.0, 1.0);

    // Determine zone colors
    Color deficientColor = AppColors.textMuted; // Red - below floor
    Color lowColor = AppColors.textSecondary; // Yellow - between floor and target
    Color optimalColor = AppColors.textPrimary; // Green - at target or above
    Color excessiveColor = AppColors.textMuted; // Red - over ceiling

    return Column(
      children: [
        // Visual progress bar with zones
        Container(
          height: 24,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: glassSurface,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return Stack(
                children: [
                  // Zone backgrounds (subtle)
                  if (floorValue != null) ...[
                    // Deficient zone (0 to floor)
                    Positioned(
                      left: 0,
                      width: width * floorPercent,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: deficientColor.withOpacity(0.1),
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    // Low zone (floor to target)
                    Positioned(
                      left: width * floorPercent,
                      width: width * (targetPercent - floorPercent),
                      top: 0,
                      bottom: 0,
                      child: Container(
                        color: lowColor.withOpacity(0.1),
                      ),
                    ),
                  ],
                  // Optimal zone (target to ceiling or end)
                  Positioned(
                    left: width * targetPercent,
                    width: ceilingValue != null
                        ? width * (ceilingPercent - targetPercent)
                        : width * (1 - targetPercent),
                    top: 0,
                    bottom: 0,
                    child: Container(
                      color: optimalColor.withOpacity(0.1),
                    ),
                  ),
                  // Excessive zone (over ceiling)
                  if (ceilingValue != null)
                    Positioned(
                      left: width * ceilingPercent,
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: excessiveColor.withOpacity(0.1),
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(12),
                          ),
                        ),
                      ),
                    ),

                  // Current value fill
                  Positioned(
                    left: 0,
                    width: width * currentPercent,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  // Floor marker
                  if (floorValue != null)
                    Positioned(
                      left: width * floorPercent - 1,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 2,
                        decoration: BoxDecoration(
                          color: lowColor,
                          boxShadow: [
                            BoxShadow(
                              color: lowColor.withOpacity(0.5),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Target marker
                  Positioned(
                    left: width * targetPercent - 1,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 2,
                      decoration: BoxDecoration(
                        color: optimalColor,
                        boxShadow: [
                          BoxShadow(
                            color: optimalColor.withOpacity(0.5),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Ceiling marker
                  if (ceilingValue != null)
                    Positioned(
                      left: width * ceilingPercent - 1,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 2,
                        decoration: BoxDecoration(
                          color: excessiveColor,
                          boxShadow: [
                            BoxShadow(
                              color: excessiveColor.withOpacity(0.5),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        // Labels row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Floor label
            if (floorValue != null)
              _TierLabel(
                label: 'Floor',
                value: '${floorValue!.toStringAsFixed(0)}$unit',
                color: AppColors.textSecondary,
              )
            else
              const SizedBox(width: 60),

            // Target label (center)
            _TierLabel(
              label: 'Target',
              value: '${targetValue.toStringAsFixed(0)}$unit',
              color: AppColors.textPrimary,
              isCenter: true,
            ),

            // Ceiling label
            if (ceilingValue != null)
              _TierLabel(
                label: 'Ceiling',
                value: '${ceilingValue!.toStringAsFixed(0)}$unit',
                color: AppColors.textMuted,
              )
            else
              const SizedBox(width: 60),
          ],
        ),

        const SizedBox(height: 8),

        // Current value badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getStatusIcon(),
                size: 16,
                color: statusColor,
              ),
              const SizedBox(width: 6),
              Text(
                'Current: ${currentValue.toStringAsFixed(1)}$unit',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${(currentValue / targetValue * 100).toStringAsFixed(0)}%)',
                style: TextStyle(
                  fontSize: 12,
                  color: statusColor.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getStatusIcon() {
    if (floorValue != null && currentValue < floorValue!) {
      return Icons.warning_amber; // Below floor - deficient
    } else if (currentValue < targetValue) {
      return Icons.arrow_upward; // Below target - low
    } else if (ceilingValue != null && currentValue > ceilingValue!) {
      return Icons.error_outline; // Over ceiling - excessive
    } else {
      return Icons.check_circle; // Optimal
    }
  }
}

class _TierLabel extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isCenter;

  const _TierLabel({
    required this.label,
    required this.value,
    required this.color,
    this.isCenter = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
