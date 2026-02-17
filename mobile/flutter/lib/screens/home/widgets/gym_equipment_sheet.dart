import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/equipment_item.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../widgets/sheet_header.dart';
import '../../workout/widgets/edit_weights_sheet.dart';

/// Equipment categories and their items - matching gym equipment structure
const Map<String, List<String>> gymEquipmentCategories = {
  'Free Weights': [
    'bumper_plates',
    'dumbbells',
    'kettlebells',
    'barbell',
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
    'chest_press_machine',
    'assisted_pullup_machine',
  ],
  'Cardio': [
    'treadmill',
    'stationary_bike',
    'elliptical',
    'rowing_machine',
    'stair_climber',
    'assault_bike',
  ],
  'Bodyweight & Accessories': [
    'bodyweight',
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
    'trx',
    'battle_ropes',
  ],
};

/// Equipment that supports weight customization
const List<String> weightedGymEquipment = [
  'bumper_plates',
  'dumbbells',
  'kettlebells',
  'barbell',
  'ez_curl_bar',
  'trap_bar',
  'weight_plates',
  'medicine_ball',
  'cable_machine',
];

/// Equipment icons for visual display
const Map<String, IconData> equipmentIcons = {
  'bumper_plates': Icons.fitness_center,
  'dumbbells': Icons.fitness_center,
  'kettlebells': Icons.sports_mma,
  'barbell': Icons.fitness_center,
  'ez_curl_bar': Icons.fitness_center,
  'trap_bar': Icons.fitness_center,
  'weight_plates': Icons.circle_outlined,
  'medicine_ball': Icons.sports_baseball,
  'cable_machine': Icons.cable,
  'smith_machine': Icons.grid_3x3,
  'leg_press': Icons.airline_seat_legroom_extra,
  'treadmill': Icons.directions_run,
  'stationary_bike': Icons.pedal_bike,
  'elliptical': Icons.directions_walk,
  'rowing_machine': Icons.rowing,
  'pull_up_bar': Icons.straighten,
  'resistance_bands': Icons.waves,
  'bodyweight': Icons.accessibility_new,
};

/// Format equipment name for display
String _formatEquipmentName(String name) {
  return name
      .split('_')
      .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
      .join(' ');
}

/// Sheet for managing gym profile equipment with categories, weights, and search
///
/// Features:
/// - Categorized equipment list (Free Weights, Machines, Cardio, etc.)
/// - Search/filter functionality
/// - Select All / Deselect All per category
/// - Edit weights for weighted equipment (dumbbells, barbells, etc.)
/// - Displays current weight range inline
class GymEquipmentSheet extends StatefulWidget {
  /// Initial equipment selection (names as strings)
  final List<String> selectedEquipment;

  /// Initial equipment details (with weights)
  final List<EquipmentItem> equipmentDetails;

  /// Callback when equipment is saved
  final void Function(
    List<String> equipment,
    List<Map<String, dynamic>> equipmentDetails,
  ) onSave;

  /// Optional title override
  final String? title;

  /// Optional callback for back button - if null, no back button shown
  final VoidCallback? onBack;

  const GymEquipmentSheet({
    super.key,
    required this.selectedEquipment,
    required this.equipmentDetails,
    required this.onSave,
    this.title,
    this.onBack,
  });

  @override
  State<GymEquipmentSheet> createState() => _GymEquipmentSheetState();
}

class _GymEquipmentSheetState extends State<GymEquipmentSheet> {
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

    // Initialize selected equipment
    _selectedEquipment = Set.from(
      widget.selectedEquipment.map((e) => e.toLowerCase().replaceAll(' ', '_')),
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

  void _resetAll() {
    setState(() {
      _selectedEquipment.clear();
      _equipmentMap.clear();
    });
  }

  void _selectAllInCategory(String category) {
    final items = gymEquipmentCategories[category] ?? [];
    setState(() {
      for (final name in items) {
        _selectedEquipment.add(name);
        _equipmentMap.putIfAbsent(name, () => EquipmentItem.fromName(name));
      }
    });
  }

  void _deselectAllInCategory(String category) {
    final items = gymEquipmentCategories[category] ?? [];
    setState(() {
      for (final name in items) {
        _selectedEquipment.remove(name);
      }
    });
  }

  List<MapEntry<String, List<String>>> get _filteredCategories {
    if (_searchQuery.isEmpty) {
      return gymEquipmentCategories.entries.toList();
    }

    final query = _searchQuery.toLowerCase();
    final filtered = <String, List<String>>{};

    for (final entry in gymEquipmentCategories.entries) {
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

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.9,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 8),
            child: Row(
              children: [
                // Back button (if provided)
                if (widget.onBack != null) ...[
                  SheetBackButton(
                    onTap: () {
                      Navigator.of(context).pop();
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        widget.onBack?.call();
                      });
                    },
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title ?? 'Equipment',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColorsLight.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${_selectedEquipment.length} selected',
                            style: TextStyle(
                              fontSize: 13,
                              color: textMuted,
                            ),
                          ),
                          if (_selectedEquipment.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: _resetAll,
                              child: Text(
                                'Reset All',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.red.shade400,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
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

          // Search bar at bottom (like in the screenshot)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surface : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.elevated : AppColorsLight.cardBorder,
                ),
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Filter equipment by name',
                hintStyle: TextStyle(color: textMuted, fontSize: 14),
                prefixIcon: Icon(Icons.filter_list, color: textMuted, size: 20),
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

          // Save button
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 16,
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Save ${_selectedEquipment.length} Items',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
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
    final allSelected = selectedInCategory == items.length && items.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header with Deselect All
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Row(
            children: [
              Text(
                category,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColorsLight.textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  if (allSelected || selectedInCategory > 0) {
                    _deselectAllInCategory(category);
                  } else {
                    _selectAllInCategory(category);
                  }
                },
                child: Text(
                  selectedInCategory > 0 ? 'Deselect All' : 'Select All',
                  style: TextStyle(
                    fontSize: 13,
                    color: accentColor,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Equipment items in this category
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
    final hasWeights = weightedGymEquipment.contains(name);
    final equipment = _equipmentMap[name];

    // Build weights display string
    String? weightsDisplay;
    if (hasWeights && equipment?.weights.isNotEmpty == true) {
      final unit = equipment!.weightUnit == 'kg' ? 'kg' : 'lb';
      weightsDisplay = equipment.weights
          .map((w) => '${w == w.roundToDouble() ? w.toInt() : w} $unit')
          .join(', ');
    }

    final icon = equipmentIcons[name] ?? Icons.fitness_center;

    return InkWell(
      onTap: () => _toggleEquipment(name),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: (isDark ? AppColors.elevated : AppColorsLight.cardBorder).withOpacity(0.5),
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Equipment icon/image placeholder
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? accentColor : textMuted,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),

            // Equipment info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatEquipmentName(name),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : AppColorsLight.textPrimary,
                    ),
                  ),
                  if (weightsDisplay != null && isSelected) ...[
                    const SizedBox(height: 2),
                    Text(
                      weightsDisplay,
                      style: TextStyle(
                        fontSize: 13,
                        color: textMuted,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (hasWeights && isSelected) ...[
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => _showEditWeights(name),
                      child: Text(
                        'Edit Weights',
                        style: TextStyle(
                          fontSize: 13,
                          color: accentColor,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Checkbox
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? accentColor : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isSelected ? accentColor : textMuted.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  void _saveChanges() {
    // Build lists for callback
    final equipment = _selectedEquipment.toList();
    final equipmentDetails = _selectedEquipment.map((name) {
      final item = _equipmentMap[name] ?? EquipmentItem.fromName(name);
      return item.toJson();
    }).toList();

    widget.onSave(equipment, equipmentDetails);
    Navigator.pop(context);
  }
}
