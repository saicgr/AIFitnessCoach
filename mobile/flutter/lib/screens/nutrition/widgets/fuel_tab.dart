import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/micronutrients.dart';
import '../../../data/services/haptic_service.dart';
import '../nutrient_explorer.dart';
import '../tabs/hydration_tab.dart';

/// Merged Nutrients + Water tab — a single Fuel tab with a pill segmented
/// control at the top to switch between the two views.
///
/// Combining them frees up slots in the parent TabController for Recipes and
/// Patterns without dropping any existing functionality.
class FuelTab extends StatefulWidget {
  final String userId;
  final DailyMicronutrientSummary? micronutrients;
  final bool isLoading;
  final VoidCallback onRefreshMicronutrients;
  final bool isDark;

  /// Optional initial inner section ('nutrients' or 'water'). When provided,
  /// overrides the default Nutrients landing — used by the hydration-reminder
  /// notification deep-link so tapping a water banner lands on the Water pill.
  final String? initialSection;

  const FuelTab({
    super.key,
    required this.userId,
    required this.micronutrients,
    required this.isLoading,
    required this.onRefreshMicronutrients,
    required this.isDark,
    this.initialSection,
  });

  @override
  State<FuelTab> createState() => _FuelTabState();
}

enum _FuelSection { nutrients, water }

class _FuelTabState extends State<FuelTab> with AutomaticKeepAliveClientMixin {
  late _FuelSection _section = widget.initialSection == 'water'
      ? _FuelSection.water
      : _FuelSection.nutrients;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final textPrimary = widget.isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final surface = widget.isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _buildPill(
                  label: 'Nutrients',
                  icon: Icons.science_outlined,
                  selected: _section == _FuelSection.nutrients,
                  onTap: () {
                    HapticService.light();
                    setState(() => _section = _FuelSection.nutrients);
                  },
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
                const SizedBox(width: 4),
                _buildPill(
                  label: 'Water',
                  icon: Icons.water_drop_outlined,
                  selected: _section == _FuelSection.water,
                  onTap: () {
                    HapticService.light();
                    setState(() => _section = _FuelSection.water);
                  },
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _section == _FuelSection.nutrients
                ? NutrientExplorerTab(
                    key: const ValueKey('fuel-nutrients'),
                    userId: widget.userId,
                    summary: widget.micronutrients,
                    isLoading: widget.isLoading,
                    onRefresh: widget.onRefreshMicronutrients,
                    isDark: widget.isDark,
                  )
                : HydrationTab(
                    key: const ValueKey('fuel-water'),
                    userId: widget.userId,
                    isDark: widget.isDark,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPill({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
    required Color textPrimary,
    required Color textMuted,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.cyan.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: selected
                ? Border.all(color: AppColors.cyan.withValues(alpha: 0.35))
                : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? AppColors.cyan : textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? textPrimary : textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
