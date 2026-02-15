import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/equipment_item.dart';
import '../../../widgets/glass_sheet.dart';
import 'edit_weights_sheet.dart';

/// Equipment categories and their items
const Map<String, List<String>> equipmentCategories = {
  'Free Weights': [
    'dumbbells',
    'barbell',
    'kettlebells',
    'ez_curl_bar',
    'trap_bar',
    'weight_plates',
    'medicine_ball',
  ],
  'Machines': [
    'cable_machine',
    'smith_machine',
    'leg_press',
    'lat_pulldown',
    'leg_curl_machine',
    'leg_extension_machine',
    'chest_fly_machine',
    'shoulder_press_machine',
    'hack_squat',
    'seated_row_machine',
  ],
  'Cardio': [
    'treadmill',
    'stationary_bike',
    'elliptical',
    'rowing_machine',
    'stair_climber',
  ],
  'Bodyweight & Accessories': [
    'pull_up_bar',
    'dip_station',
    'resistance_bands',
    'adjustable_bench',
    'flat_bench',
    'incline_bench',
    'decline_bench',
    'yoga_mat',
    'stability_ball',
    'foam_roller',
    'ab_wheel',
    'jump_rope',
  ],
};

/// Equipment that supports weight customization
const List<String> weightedEquipment = [
  'dumbbells',
  'barbell',
  'kettlebells',
  'ez_curl_bar',
  'trap_bar',
  'weight_plates',
  'medicine_ball',
  'cable_machine',
];

/// Format equipment name for display
String _formatEquipmentName(String name) {
  return name
      .split('_')
      .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
      .join(' ');
}

/// Sheet for editing workout equipment selection
class EditWorkoutEquipmentSheet extends StatefulWidget {
  /// Current equipment for the workout (names as strings)
  final List<String> currentEquipment;

  /// Equipment items with weight details (from user profile or workout)
  final List<EquipmentItem> equipmentDetails;

  /// Callback when changes are applied
  final void Function(List<EquipmentItem> selectedEquipment) onApply;

  const EditWorkoutEquipmentSheet({
    super.key,
    required this.currentEquipment,
    required this.equipmentDetails,
    required this.onApply,
  });

  @override
  State<EditWorkoutEquipmentSheet> createState() => _EditWorkoutEquipmentSheetState();
}

class _EditWorkoutEquipmentSheetState extends State<EditWorkoutEquipmentSheet> {
  late Map<String, EquipmentItem> _equipmentMap;
  late Set<String> _selectedEquipment;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize equipment map from provided details
    _equipmentMap = {
      for (final item in widget.equipmentDetails) item.name: item,
    };

    // Initialize selected equipment from current workout equipment
    _selectedEquipment = Set.from(
      widget.currentEquipment.map((e) => e.toLowerCase().replaceAll(' ', '_')),
    );

    // Ensure all selected equipment has an entry in the map
    for (final name in _selectedEquipment) {
      _equipmentMap.putIfAbsent(name, () => EquipmentItem.fromName(name));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleEquipment(String name) {
    setState(() {
      if (_selectedEquipment.contains(name)) {
        _selectedEquipment.remove(name);
      } else {
        _selectedEquipment.add(name);
        // Ensure it exists in map
        _equipmentMap.putIfAbsent(name, () => EquipmentItem.fromName(name));
      }
    });
  }

  void _showEditWeights(String equipmentName) {
    final equipment = _equipmentMap[equipmentName] ?? EquipmentItem.fromName(equipmentName);

    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        child: EditWeightsSheet(
          equipment: equipment,
          onSave: (updated) {
            setState(() {
              _equipmentMap[equipmentName] = updated;
            });
          },
        ),
      ),
    );
  }

  void _selectAllInCategory(String category) {
    final items = equipmentCategories[category] ?? [];
    setState(() {
      for (final name in items) {
        _selectedEquipment.add(name);
        _equipmentMap.putIfAbsent(name, () => EquipmentItem.fromName(name));
      }
    });
  }

  void _deselectAllInCategory(String category) {
    final items = equipmentCategories[category] ?? [];
    setState(() {
      for (final name in items) {
        _selectedEquipment.remove(name);
      }
    });
  }

  List<MapEntry<String, List<String>>> get _filteredCategories {
    if (_searchQuery.isEmpty) {
      return equipmentCategories.entries.toList();
    }

    final query = _searchQuery.toLowerCase();
    final filtered = <String, List<String>>{};

    for (final entry in equipmentCategories.entries) {
      final matchingItems = entry.value
          .where((name) =>
              name.contains(query) ||
              _formatEquipmentName(name).toLowerCase().contains(query))
          .toList();

      if (matchingItems.isNotEmpty) {
        filtered[entry.key] = matchingItems;
      }
    }

    return filtered.entries.toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final bgColor = isDark ? AppColors.elevated : AppColorsLight.surface;
    final accentColor = isDark ? AppColors.cyan : AppColorsLight.accent;

    return Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit Equipment',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColorsLight.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_selectedEquipment.length} items selected',
                        style: TextStyle(
                          fontSize: 13,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: textMuted),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search equipment...',
                hintStyle: TextStyle(color: textMuted, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: textMuted, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        icon: Icon(Icons.clear, color: textMuted, size: 18),
                      )
                    : null,
                filled: true,
                fillColor: bgColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const Divider(height: 1),

          // Equipment list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: _filteredCategories.length,
              itemBuilder: (context, index) {
                final category = _filteredCategories[index];
                return _buildCategorySection(
                  category.key,
                  category.value,
                  isDark,
                  textMuted,
                  bgColor,
                  accentColor,
                );
              },
            ),
          ),

          // Apply button
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surface : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.elevated : AppColorsLight.cardBorder,
                ),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _applyChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Apply Changes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
    );
  }

  Widget _buildCategorySection(
    String category,
    List<String> items,
    bool isDark,
    Color textMuted,
    Color bgColor,
    Color accentColor,
  ) {
    final selectedInCategory = items.where((e) => _selectedEquipment.contains(e)).length;
    final allSelected = selectedInCategory == items.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
          child: Row(
            children: [
              Text(
                category.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: textMuted,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '($selectedInCategory/${items.length})',
                style: TextStyle(
                  fontSize: 11,
                  color: textMuted.withOpacity(0.7),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  if (allSelected) {
                    _deselectAllInCategory(category);
                  } else {
                    _selectAllInCategory(category);
                  }
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 28),
                ),
                child: Text(
                  allSelected ? 'Deselect' : 'Select All',
                  style: TextStyle(
                    fontSize: 12,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Equipment items
        ...items.map((name) => _buildEquipmentItem(
              name,
              isDark,
              textMuted,
              bgColor,
              accentColor,
            )),
      ],
    );
  }

  Widget _buildEquipmentItem(
    String name,
    bool isDark,
    Color textMuted,
    Color bgColor,
    Color accentColor,
  ) {
    final isSelected = _selectedEquipment.contains(name);
    final hasWeights = weightedEquipment.contains(name);
    final equipment = _equipmentMap[name];
    final weightsInfo = equipment?.weights.isNotEmpty == true
        ? '${equipment!.weights.first.toInt()}-${equipment.weights.last.toInt()} ${equipment.weightUnit}'
        : null;

    return InkWell(
      onTap: () => _toggleEquipment(name),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Checkbox
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isSelected ? accentColor : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? accentColor : textMuted.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),

            // Equipment name and weights info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatEquipmentName(name),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                      color: isDark ? Colors.white : AppColorsLight.textPrimary,
                    ),
                  ),
                  if (weightsInfo != null && isSelected) ...[
                    const SizedBox(height: 2),
                    Text(
                      weightsInfo,
                      style: TextStyle(
                        fontSize: 12,
                        color: accentColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Edit weights button (only for weighted equipment when selected)
            if (hasWeights && isSelected)
              TextButton(
                onPressed: () => _showEditWeights(name),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: const Size(0, 32),
                  backgroundColor: bgColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Weights',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : AppColorsLight.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: textMuted,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _applyChanges() {
    // Build list of selected equipment items with their details
    final selectedItems = _selectedEquipment.map((name) {
      return _equipmentMap[name] ?? EquipmentItem.fromName(name);
    }).toList();

    widget.onApply(selectedItems);
    Navigator.pop(context);
  }
}
