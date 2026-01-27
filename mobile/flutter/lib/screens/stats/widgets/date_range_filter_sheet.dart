import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/providers/consistency_provider.dart';
import '../../../data/services/haptic_service.dart';

/// Bottom sheet for selecting date range for stats filtering
class DateRangeFilterSheet extends ConsumerStatefulWidget {
  const DateRangeFilterSheet({super.key});

  static Future<void> show(BuildContext context, WidgetRef ref) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DateRangeFilterSheet(),
    );
  }

  @override
  ConsumerState<DateRangeFilterSheet> createState() =>
      _DateRangeFilterSheetState();
}

class _DateRangeFilterSheetState extends ConsumerState<DateRangeFilterSheet> {
  HeatmapTimeRange? _selectedPreset;
  DateTimeRange? _customRange;
  bool _isCustomSelected = false;

  @override
  void initState() {
    super.initState();
    // Initialize with current selection
    _selectedPreset = ref.read(heatmapTimeRangeProvider);
    _customRange = ref.read(customStatsDateRangeProvider);
    _isCustomSelected = _customRange != null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.6),
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
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: textMuted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Select Date Range',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ),

            // Preset buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...HeatmapTimeRange.values.map((preset) => _PresetChip(
                        label: preset.label,
                        isSelected: !_isCustomSelected && _selectedPreset == preset,
                        onTap: () {
                          HapticService.light();
                          setState(() {
                            _selectedPreset = preset;
                            _isCustomSelected = false;
                            _customRange = null;
                          });
                        },
                      )),
                  _PresetChip(
                    label: 'Custom',
                    isSelected: _isCustomSelected,
                    onTap: () => _showCustomDatePicker(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Current selection display
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.pureBlack.withOpacity(0.3)
                      : AppColorsLight.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 20,
                      color: cyan,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getSelectionDisplayText(),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Apply button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _applySelection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cyan,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Apply',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
            ),
          ),
        ),
      ),
    );
  }

  String _getSelectionDisplayText() {
    if (_isCustomSelected && _customRange != null) {
      final formatter = DateFormat('MMM d, yyyy');
      return '${formatter.format(_customRange!.start)} - ${formatter.format(_customRange!.end)}';
    }

    if (_selectedPreset != null) {
      final now = DateTime.now();
      final start = now.subtract(Duration(days: _selectedPreset!.weeks * 7));
      final formatter = DateFormat('MMM d, yyyy');
      return '${formatter.format(start)} - ${formatter.format(now)}';
    }

    return 'Select a date range';
  }

  Future<void> _showCustomDatePicker(BuildContext context) async {
    HapticService.light();

    final now = DateTime.now();
    final initialRange = _customRange ??
        DateTimeRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: initialRange,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.cyan,
              brightness: isDark ? Brightness.dark : Brightness.light,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      HapticService.medium();
      setState(() {
        _customRange = picked;
        _isCustomSelected = true;
        _selectedPreset = null;
      });
    }
  }

  void _applySelection() {
    HapticService.medium();

    if (_isCustomSelected && _customRange != null) {
      // Set custom date range
      ref.read(customStatsDateRangeProvider.notifier).state = _customRange;
      ref.read(heatmapTimeRangeProvider.notifier).state =
          HeatmapTimeRange.threeMonths; // Reset preset
    } else if (_selectedPreset != null) {
      // Set preset
      ref.read(heatmapTimeRangeProvider.notifier).state = _selectedPreset!;
      ref.read(customStatsDateRangeProvider.notifier).state = null;
    }

    Navigator.pop(context);
  }
}

/// Preset selection chip
class _PresetChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Material(
      color: isSelected
          ? cyan
          : (isDark ? AppColors.pureBlack.withOpacity(0.3) : AppColorsLight.background),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? cyan
                  : (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : (isDark ? textPrimary : textMuted),
            ),
          ),
        ),
      ),
    );
  }
}
