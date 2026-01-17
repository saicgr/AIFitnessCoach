import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';

/// Bottom sheet with searchable equipment list
class EquipmentSearchSheet extends StatefulWidget {
  final Set<String> selectedEquipment;
  final List<String> allEquipment;
  final Function(Set<String>) onSelectionChanged;
  /// Optional callback for custom equipment changes (separate list for backend)
  final Function(List<String>)? onCustomEquipmentChanged;
  /// Initial custom equipment (for edit mode)
  final List<String> initialCustomEquipment;

  const EquipmentSearchSheet({
    super.key,
    required this.selectedEquipment,
    required this.allEquipment,
    required this.onSelectionChanged,
    this.onCustomEquipmentChanged,
    this.initialCustomEquipment = const [],
  });

  /// All equipment available in the database (excluding basic ones shown in main list)
  static const List<String> databaseEquipment = [
    // Unconventional/Farm Equipment
    'battle ropes',
    'hay bale',
    'sandbag',
    'tire',
    'tire, sledgehammer',
    // Indian/Traditional Equipment
    'gada (mace)',
    'gar nal (stone neck ring)',
    'jori (indian clubs)',
    'lathi (bamboo staff)',
    'mallakhamb pole',
    'matka (water pot)',
    'nal (stone lock)',
    'samtola (indian barbell)',
    'rope',
    // Gym Machines
    'Ab Roller',
    'Airbike',
    'Assisted Pull Up Machine',
    'Balance Board',
    'Bench',
    'Box',
    'Cable Pulley Machine',
    'Cable Row Machine',
    'Chair',
    'Chest Press Machine',
    'Dip Station',
    'Elliptical Machine',
    'Exercise Ball',
    'EZ Bar',
    'Hack Squat Machine',
    'Hammer Strength Machines',
    'Hyperextension Bench',
    'Jump rope',
    'Lat Pull Down Machine',
    'Leg Extension Machine',
    'Leg Press Machine',
    'Loop Resistance Band',
    'Medicine Ball',
    'Rowing Machine',
    'Seated Hip Abductor Machine',
    'Ski Ergometer',
    'Slam Ball',
    'Smith Machine',
    'Stationary Exercise Bike',
    'Suspension Trainer',
    'Trap Bar',
    'Treadmill',
    'Triceps Extension Machine',
    'Weight Plate',
    'Yoga Mat',
  ];

  @override
  State<EquipmentSearchSheet> createState() => _EquipmentSearchSheetState();
}

class _EquipmentSearchSheetState extends State<EquipmentSearchSheet> {
  late Set<String> _selected;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late List<String> _customEquipment; // User-added custom equipment

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.selectedEquipment);
    // Initialize with any existing custom equipment
    _customEquipment = List.from(widget.initialCustomEquipment);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _filteredEquipment {
    // Combine standard equipment with user's custom equipment
    final baseList = widget.allEquipment.isNotEmpty
        ? widget.allEquipment
        : EquipmentSearchSheet.databaseEquipment;
    final equipmentList = [..._customEquipment, ...baseList];

    if (_searchQuery.isEmpty) {
      return equipmentList;
    }
    return equipmentList
        .where((e) => e.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _showAddCustomEquipmentDialog() {
    _showAddCustomEquipmentDialogWithText('');
  }

  void _showAddCustomEquipmentDialogWithText(String prefillText) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final controller = TextEditingController(text: prefillText);
    // Position cursor at end
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
        title: Text(
          'Add Custom Equipment',
          style: TextStyle(color: textPrimary),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          style: TextStyle(color: textPrimary),
          decoration: InputDecoration(
            hintText: 'e.g., Homemade pull-up bar',
            hintStyle: TextStyle(
              color: (isDark ? AppColors.textSecondary : AppColorsLight.textSecondary),
            ),
            filled: true,
            fillColor: isDark ? AppColors.glassSurface : AppColorsLight.glassSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.accent),
            ),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              _addCustomEquipment(value.trim());
              Navigator.of(ctx).pop();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                _addCustomEquipment(controller.text.trim());
                Navigator.of(ctx).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addCustomEquipment(String equipment) {
    HapticFeedback.mediumImpact();
    setState(() {
      _customEquipment.add(equipment);
      _selected.add(equipment);
    });
    widget.onSelectionChanged(_selected);
    // Also notify about custom equipment changes (for separate backend tracking)
    widget.onCustomEquipmentChanged?.call(List.from(_customEquipment));
  }

  void _toggleEquipment(String equipment) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selected.contains(equipment)) {
        _selected.remove(equipment);
      } else {
        _selected.add(equipment);
      }
    });
    widget.onSelectionChanged(_selected);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
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
          child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: cardBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Other Equipment',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    if (_selected.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: AppColors.accentGradient,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${_selected.length} selected',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Search from 100+ equipment types',
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.glassSurface : AppColorsLight.glassSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cardBorder),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                style: TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search equipment...',
                  hintStyle: TextStyle(color: textSecondary),
                  prefixIcon: Icon(Icons.search, color: textSecondary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: textSecondary),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // "Add Custom" button at TOP (always visible, no scrolling needed)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildAddCustomButton(
              isDark: isDark,
              textSecondary: textSecondary,
              cardBorder: cardBorder,
            ),
          ),

          const SizedBox(height: 8),

          // Equipment list
          Expanded(
            child: _filteredEquipment.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: textSecondary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No equipment found',
                          style: TextStyle(
                            fontSize: 16,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () {
                            // Pre-fill with search query
                            _showAddCustomEquipmentDialogWithText(_searchQuery);
                          },
                          icon: const Icon(Icons.add_circle_outline, color: AppColors.accent),
                          label: Text(
                            'Add "$_searchQuery"',
                            style: const TextStyle(color: AppColors.accent),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _filteredEquipment.length,
                    itemBuilder: (context, index) {
                      final equipment = _filteredEquipment[index];
                      final isSelected = _selected.contains(equipment);
                      final isCustom = _customEquipment.contains(equipment);

                      return _buildEquipmentItem(
                        equipment: equipment,
                        isSelected: isSelected,
                        isDark: isDark,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        cardBorder: cardBorder,
                        isCustom: isCustom,
                      );
                    },
                  ),
          ),

          // Done button
          Padding(
            padding: const EdgeInsets.all(20),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddCustomButton({
    required bool isDark,
    required Color textSecondary,
    required Color cardBorder,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: GestureDetector(
        onTap: _showAddCustomEquipmentDialog,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.glassSurface : AppColorsLight.glassSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.5),
              width: 1,
              style: BorderStyle.solid,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add,
                  color: AppColors.accent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Can't find your equipment?",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    ),
                    Text(
                      'Add custom equipment',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.accent.withValues(alpha: 0.7),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEquipmentItem({
    required String equipment,
    required bool isSelected,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color cardBorder,
    bool isCustom = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => _toggleEquipment(equipment),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: isSelected ? AppColors.accentGradient : null,
            color: isSelected
                ? null
                : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.accent : cardBorder,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isCustom ? Icons.handyman : _getEquipmentIcon(equipment),
                color: isSelected ? Colors.white : textSecondary,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        _formatEquipmentName(equipment),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? Colors.white : textPrimary,
                        ),
                      ),
                    ),
                    if (isCustom) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.2)
                              : AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'CUSTOM',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? null
                      : Border.all(color: cardBorder, width: 2),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatEquipmentName(String equipment) {
    // Capitalize first letter of each word
    return equipment.split(' ').map((word) {
      if (word.isEmpty) return word;
      // Handle parentheses
      if (word.startsWith('(')) {
        return '(${word.substring(1, 2).toUpperCase()}${word.substring(2)}';
      }
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  IconData _getEquipmentIcon(String equipment) {
    final lower = equipment.toLowerCase();

    // Unconventional/Farm
    if (lower.contains('hay') || lower.contains('bale')) return Icons.grass;
    if (lower.contains('tire')) return Icons.circle_outlined;
    if (lower.contains('sandbag')) return Icons.inventory_2;
    if (lower.contains('battle rope') || lower.contains('rope')) return Icons.cable;
    if (lower.contains('sledgehammer')) return Icons.hardware;

    // Indian/Traditional
    if (lower.contains('gada') || lower.contains('mace')) return Icons.sports_martial_arts;
    if (lower.contains('jori') || lower.contains('club')) return Icons.sports_martial_arts;
    if (lower.contains('lathi') || lower.contains('staff')) return Icons.straighten;
    if (lower.contains('mallakhamb')) return Icons.sports_gymnastics;
    if (lower.contains('matka') || lower.contains('pot')) return Icons.local_drink;
    if (lower.contains('nal') || lower.contains('stone')) return Icons.fitness_center;
    if (lower.contains('samtola')) return Icons.line_weight;

    // Cardio machines
    if (lower.contains('treadmill')) return Icons.directions_run;
    if (lower.contains('bike') || lower.contains('cycle')) return Icons.pedal_bike;
    if (lower.contains('elliptical')) return Icons.directions_walk;
    if (lower.contains('rowing')) return Icons.rowing;
    if (lower.contains('ski')) return Icons.downhill_skiing;
    if (lower.contains('jump rope')) return Icons.sports;

    // Weight equipment
    if (lower.contains('barbell') || lower.contains('bar')) return Icons.line_weight;
    if (lower.contains('dumbbell')) return Icons.fitness_center;
    if (lower.contains('kettlebell')) return Icons.sports_handball;
    if (lower.contains('plate')) return Icons.circle;
    if (lower.contains('trap bar')) return Icons.hexagon_outlined;

    // Machines
    if (lower.contains('machine') || lower.contains('press')) return Icons.precision_manufacturing;
    if (lower.contains('cable')) return Icons.settings_ethernet;
    if (lower.contains('smith')) return Icons.view_column;
    if (lower.contains('bench')) return Icons.weekend;
    if (lower.contains('rack')) return Icons.grid_on;

    // Other
    if (lower.contains('ball')) return Icons.sports_baseball;
    if (lower.contains('band')) return Icons.cable;
    if (lower.contains('mat') || lower.contains('yoga')) return Icons.self_improvement;
    if (lower.contains('box')) return Icons.check_box_outline_blank;
    if (lower.contains('chair')) return Icons.chair;
    if (lower.contains('suspension') || lower.contains('trx')) return Icons.sports_gymnastics;
    if (lower.contains('roller')) return Icons.sports;
    if (lower.contains('dip')) return Icons.fitness_center;
    if (lower.contains('pull up') || lower.contains('pull-up')) return Icons.sports_gymnastics;

    return Icons.fitness_center;
  }
}
