import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/micronutrients.dart';
import '../../data/repositories/nutrition_repository.dart';
import '../../widgets/glass_sheet.dart';

part 'nutrient_explorer_part_nutrient_score_card.dart';
part 'nutrient_explorer_part_tier_label.dart';


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
                categoryColor: const Color(0xFFFF9F43), // Warm orange
                isDark: widget.isDark,
                onNutrientTap: (nutrient) => _showNutrientDetail(nutrient),
              ).animate().fadeIn(delay: 150.ms),

            if (_selectedCategory == 'all' || _selectedCategory == 'minerals')
              _NutrientSection(
                title: 'MINERALS',
                icon: Icons.diamond_outlined,
                nutrients: summary.minerals,
                categoryColor: const Color(0xFF00D9C0), // Teal
                isDark: widget.isDark,
                onNutrientTap: (nutrient) => _showNutrientDetail(nutrient),
              ).animate().fadeIn(delay: 200.ms),

            if (_selectedCategory == 'all' || _selectedCategory == 'fats')
              _NutrientSection(
                title: 'FATTY ACIDS',
                icon: Icons.water_drop_outlined,
                nutrients: summary.fattyAcids,
                categoryColor: const Color(0xFF4D96FF), // Blue
                isDark: widget.isDark,
                onNutrientTap: (nutrient) => _showNutrientDetail(nutrient),
              ).animate().fadeIn(delay: 250.ms),

            if (_selectedCategory == 'all' || _selectedCategory == 'other')
              _NutrientSection(
                title: 'OTHER',
                icon: Icons.more_horiz,
                nutrients: summary.other,
                categoryColor: const Color(0xFF9B59B6), // Purple
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
    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        child: NutrientDetailSheet(
          nutrient: nutrient,
          userId: widget.userId,
          isDark: widget.isDark,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Nutrient Detail Sheet - Shows detailed info when tapped
// ─────────────────────────────────────────────────────────────────

class NutrientDetailSheet extends ConsumerStatefulWidget {
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
  ConsumerState<NutrientDetailSheet> createState() => _NutrientDetailSheetState();
}

class _NutrientDetailSheetState extends ConsumerState<NutrientDetailSheet> {
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
      // Toggle locally first for instant UI feedback
      final newPinned = !_isPinned;
      setState(() => _isPinned = newPinned);

      // Persist to backend
      final currentPinned = List<String>.from(widget.currentPinnedNutrients ?? []);
      if (newPinned) {
        if (!currentPinned.contains(widget.nutrient.nutrientKey)) {
          currentPinned.add(widget.nutrient.nutrientKey);
        }
      } else {
        currentPinned.remove(widget.nutrient.nutrientKey);
      }
      await ref.read(nutritionRepositoryProvider).updatePinnedNutrients(
        userId: widget.userId,
        pinnedNutrients: currentPinned,
      );

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
        return const Color(0xFFFFC107); // Amber - below target
      case NutrientStatus.optimal:
        return const Color(0xFF4CAF50); // Green - on target
      case NutrientStatus.high:
        return const Color(0xFFFF9800); // Orange - above target
      case NutrientStatus.overCeiling:
        return const Color(0xFFF44336); // Red - over limit
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
