import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/equipment_item.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../widgets/sheet_header.dart';
import '../../workout/widgets/edit_weights_sheet.dart';
import 'import_equipment_sheet.dart';

import '../../../l10n/generated/app_localizations.dart';
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
  'Racks & Benches': [
    'bench',
    'squat_rack',
    'adjustable_bench',
    'flat_bench',
    'incline_bench',
    'decline_bench',
  ],
  'Bodyweight & Accessories': [
    'bodyweight',
    'pull_up_bar',
    'dip_station',
    'resistance_bands',
    'yoga_mat',
    'stability_ball',
    'foam_roller',
    'ab_wheel',
    'jump_rope',
    'trx',
    'battle_ropes',
  ],
};

/// Free-weight equipment that holds an inventory of individual weights
/// (e.g. "you own pairs of 25, 30, 35 lb dumbbells"). Uses the
/// rack-style picker in EditWeightsSheet.
const List<String> freeWeightInventoryEquipment = [
  'bumper_plates',
  'dumbbells',
  'kettlebells',
  'barbell',
  'ez_curl_bar',
  'trap_bar',
  'weight_plates',
  'medicine_ball',
];

/// Stack-based machines where the user pins a weight on a stack. Configured
/// by min / max / increment in EditWeightsSheet; the generated weight list
/// is stored back into weightInventory with quantity 1 each so downstream
/// pickers still see the full available weights.
const List<String> stackMachineEquipment = [
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
];

/// Union of all equipment that supports the Edit Weights link. Kept as a
/// single name for backwards-compat with the rest of the codebase.
final List<String> weightedGymEquipment = [
  ...freeWeightInventoryEquipment,
  ...stackMachineEquipment,
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
  'bench': Icons.weekend,
  'squat_rack': Icons.fitness_center,
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

  /// If provided, enables the "Import from PDF/photo/URL" button in the
  /// header. Null when the parent is still constructing a new profile
  /// (e.g. step 2 of AddGymProfileSheet) — in that case the import entry
  /// lives on the parent screen instead.
  final String? gymProfileId;

  /// Current workout environment — forwarded to the import flow so the
  /// extractor can override only when it infers a different one.
  final String? workoutEnvironment;

  const GymEquipmentSheet({
    super.key,
    required this.selectedEquipment,
    required this.equipmentDetails,
    required this.onSave,
    this.title,
    this.onBack,
    this.gymProfileId,
    this.workoutEnvironment,
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

    // Expand the abstract 'full_gym' token to every known equipment item
    // so commercial-gym profiles show all 43 items pre-selected.
    if (_selectedEquipment.remove('full_gym')) {
      for (final items in gymEquipmentCategories.values) {
        _selectedEquipment.addAll(items);
      }
    }

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

  /// Names of all built-in (catalog) equipment slugs across categories.
  Set<String> get _catalogNames =>
      {for (final items in gymEquipmentCategories.values) ...items};

  /// User-added custom equipment slugs (anything in the map that isn't part of
  /// the built-in catalog). Custom items are rendered in their own section.
  List<String> get _customEquipmentNames {
    final catalog = _catalogNames;
    final names = _equipmentMap.values
        .where((e) => e.isCustom || !catalog.contains(e.name))
        .map((e) => e.name)
        .toSet()
        .toList()
      ..sort();
    return names;
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

  /// Custom equipment names filtered by the active search query.
  List<String> get _filteredCustomEquipment {
    final all = _customEquipmentNames;
    if (_searchQuery.isEmpty) return all;
    final query = _searchQuery.toLowerCase();
    return all.where((name) {
      final display = (_equipmentMap[name]?.displayName ??
              _formatEquipmentName(name))
          .toLowerCase();
      return name.contains(query) || display.contains(query);
    }).toList();
  }

  /// Open the add-custom-equipment dialog and merge the result into the map.
  Future<void> _addCustomEquipment() async {
    final result = await showDialog<EquipmentItem>(
      context: context,
      builder: (ctx) => const _CustomEquipmentDialog(),
    );
    if (result == null || !mounted) return;
    setState(() {
      // Avoid clobbering an existing slug — suffix if needed.
      var slug = result.name;
      if (_equipmentMap.containsKey(slug) &&
          _equipmentMap[slug]?.displayName != result.displayName) {
        slug = '${slug}_${DateTime.now().millisecondsSinceEpoch % 100000}';
      }
      _equipmentMap[slug] = result.copyWith(name: slug, isCustom: true);
      _selectedEquipment.add(slug);
    });
  }

  /// Edit an existing custom equipment item via the same dialog.
  Future<void> _editCustomEquipment(String slug) async {
    final existing = _equipmentMap[slug];
    if (existing == null) return;
    final result = await showDialog<EquipmentItem>(
      context: context,
      builder: (ctx) => _CustomEquipmentDialog(initial: existing),
    );
    if (result == null || !mounted) return;
    setState(() {
      _equipmentMap[slug] = result.copyWith(name: slug, isCustom: true);
      _selectedEquipment.add(slug);
    });
  }

  void _removeCustomEquipment(String slug) {
    setState(() {
      _equipmentMap.remove(slug);
      _selectedEquipment.remove(slug);
    });
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
            padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 12, 8),
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
                        widget.title ?? AppLocalizations.of(context).trainingSetupCardEquipment,
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
                            AppLocalizations.of(context)!.gymEquipmentSheetSelected(_selectedEquipment.length),
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
                                AppLocalizations.of(context).moodCardResetAll,
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

          // AI import entry — only when we know the profile id
          if (widget.gymProfileId != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: _ImportFromAIButton(
                onTap: () => _openImportSheet(context),
                accentColor: accentColor,
                isDark: isDark,
              ),
            ),

          // Equipment list — custom-equipment section first, then the catalog.
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              // +1 leading slot for the custom-equipment section / CTA.
              itemCount: _filteredCategories.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildCustomEquipmentSection(
                    isDark,
                    textMuted,
                    bgColor,
                    accentColor,
                  );
                }
                final category = _filteredCategories[index - 1];
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
                hintText: AppLocalizations.of(context).gymEquipmentFilterEquipmentByName,
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
                  AppLocalizations.of(context)!.gymEquipmentSheetSaveItems(_selectedEquipment.length),
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
                  selectedInCategory > 0 ? AppLocalizations.of(context).measurementsScreenPartDeselectAll : AppLocalizations.of(context).openAllCratesSelectAll,
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

  /// Custom-equipment section: a header, an "Add custom equipment" CTA, and a
  /// row per user-added item. Supports grip trainers, grip rings, finger
  /// exercisers, adjustable dumbbells / banded ranges — anything not in the
  /// built-in catalog, with an optional weight range/increment.
  Widget _buildCustomEquipmentSection(
    bool isDark,
    Color textMuted,
    Color bgColor,
    Color accentColor,
  ) {
    final custom = _filteredCustomEquipment;
    // Hide the section entirely while searching unless a custom item matches —
    // but always keep the CTA when not searching so users can discover it.
    final showCta = _searchQuery.isEmpty;
    if (!showCta && custom.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Row(
            children: [
              Text(
                'Custom Equipment',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColorsLight.textPrimary,
                ),
              ),
            ],
          ),
        ),

        // Existing custom items
        ...custom.map((name) => _buildCustomEquipmentItem(
              name,
              isDark,
              textMuted,
              bgColor,
              accentColor,
            )),

        // Add CTA (only when not searching)
        if (showCta)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: InkWell(
              onTap: _addCustomEquipment,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline_rounded,
                        color: accentColor, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add custom equipment',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : AppColorsLight.textPrimary,
                            ),
                          ),
                          Text(
                            'Grip trainer, bands, adjustable dumbbells…',
                            style: TextStyle(
                              fontSize: 11,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCustomEquipmentItem(
    String name,
    bool isDark,
    Color textMuted,
    Color bgColor,
    Color accentColor,
  ) {
    final isSelected = _selectedEquipment.contains(name);
    final equipment = _equipmentMap[name];
    final summary = equipment?.summary ?? '';

    return InkWell(
      onTap: () => _toggleEquipment(name),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: (isDark ? AppColors.elevated : AppColorsLight.cardBorder)
                  .withOpacity(0.5),
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.build_circle_outlined,
                color: isSelected ? accentColor : textMuted,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    equipment?.displayName ?? _formatEquipmentName(name),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color:
                          isDark ? Colors.white : AppColorsLight.textPrimary,
                    ),
                  ),
                  if (summary.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      summary,
                      style: TextStyle(fontSize: 13, color: textMuted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _editCustomEquipment(name),
                        child: Text(
                          AppLocalizations.of(context).commonEdit,
                          style: TextStyle(
                            fontSize: 13,
                            color: accentColor,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () => _removeCustomEquipment(name),
                        child: Text(
                          AppLocalizations.of(context).commonDelete,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.red.shade400,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
                        AppLocalizations.of(context).gymEquipmentEditWeights,
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
    // Pop only this modal sheet, never the underlying workout route. The
    // active workout screen used to be unmounted by an unguarded pop here.
    final route = ModalRoute.of(context);
    if (route != null && route.isCurrent && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  /// Open the AI import sheet. Requires [widget.gymProfileId] to be non-null
  /// because the backend needs an existing profile to attach results to.
  ///
  /// The import flow writes directly to the profile via
  /// `gymProfilesProvider.notifier.updateProfile()`, so after it completes
  /// we close this equipment sheet and let the caller pick up the refreshed
  /// profile through Riverpod.
  void _openImportSheet(BuildContext parentCtx) {
    final profileId = widget.gymProfileId;
    if (profileId == null) return; // defensive — button is hidden otherwise

    // Snapshot current selections so the import merges, not overwrites.
    final existingEquipment = _selectedEquipment.toList();
    final existingDetails = _selectedEquipment
        .map((name) =>
            (_equipmentMap[name] ?? EquipmentItem.fromName(name)).toJson())
        .toList();

    showGlassSheet(
      context: parentCtx,
      builder: (ctx) => GlassSheet(
        child: Consumer(
          builder: (ctx, ref, _) => ImportEquipmentSheet(
            gymProfileId: profileId,
            existingEquipment: existingEquipment,
            existingEquipmentDetails: existingDetails,
            currentEnvironment: widget.workoutEnvironment ?? 'commercial_gym',
          ),
        ),
      ),
    );
    // Once the user completes the import, the provider updates itself —
    // close this local sheet so the stale snapshot isn't shown. We use a
    // post-frame callback so we don't pop during build.
    //
    // We watch the gymProfilesProvider from a helper consumer below.
  }
}

/// Dialog to add / edit a custom or adjustable piece of equipment.
///
/// Captures an arbitrary name plus an OPTIONAL weight range (min / max /
/// increment) and unit. The range is expanded into concrete selectable stops
/// (via [EquipmentItem.expandRange]) so progression snaps to real available
/// weights downstream (Gravl B2: grip trainer 10-160 lb, adjustable dumbbells,
/// banded ranges). Leaving the range blank creates a plain named item (e.g. a
/// grip ring with fixed resistance).
class _CustomEquipmentDialog extends StatefulWidget {
  final EquipmentItem? initial;

  const _CustomEquipmentDialog({this.initial});

  @override
  State<_CustomEquipmentDialog> createState() => _CustomEquipmentDialogState();
}

class _CustomEquipmentDialogState extends State<_CustomEquipmentDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _minCtrl;
  late final TextEditingController _maxCtrl;
  late final TextEditingController _stepCtrl;
  late final TextEditingController _notesCtrl;
  late String _unit; // 'lbs' | 'kg'
  String? _error;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    _nameCtrl = TextEditingController(text: init?.displayName ?? '');
    _minCtrl = TextEditingController(
        text: init?.weightMin != null ? _fmt(init!.weightMin!) : '');
    _maxCtrl = TextEditingController(
        text: init?.weightMax != null ? _fmt(init!.weightMax!) : '');
    _stepCtrl = TextEditingController(
        text: init?.weightIncrement != null
            ? _fmt(init!.weightIncrement!)
            : '');
    _notesCtrl = TextEditingController(text: init?.notes ?? '');
    _unit = init?.weightUnit ?? 'lbs';
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _minCtrl.dispose();
    _maxCtrl.dispose();
    _stepCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String _slugify(String name) {
    final slug = name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    if (slug.isNotEmpty) return slug;
    return 'custom_${DateTime.now().millisecondsSinceEpoch}';
  }

  double? _parse(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter a name');
      return;
    }
    final min = _parse(_minCtrl.text);
    final max = _parse(_maxCtrl.text);
    final step = _parse(_stepCtrl.text);

    // Range is optional, but if one bound is given the other must be too and
    // the range must be valid.
    if ((min != null) != (max != null)) {
      setState(() => _error = 'Enter both min and max, or leave both blank');
      return;
    }
    if (min != null && max != null && max < min) {
      setState(() => _error = 'Max must be ≥ min');
      return;
    }

    final notes = _notesCtrl.text.trim();
    final item = EquipmentItem(
      name: _slugify(name),
      displayName: name,
      weightUnit: _unit,
      isCustom: true,
      weightMin: min,
      weightMax: max,
      weightIncrement: step,
      notes: notes.isEmpty ? null : notes,
    );
    Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.cyan : AppColorsLight.accent;
    final textPrimary =
        isDark ? Colors.white : AppColorsLight.textPrimary;
    final isEdit = widget.initial != null;

    InputDecoration deco(String hint) => InputDecoration(
          hintText: hint,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        );

    return AlertDialog(
      title: Text(isEdit ? 'Edit Equipment' : 'Add Custom Equipment'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: deco('Name (e.g. Grip Trainer)'),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text('Weight range (optional)',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textPrimary)),
                const Spacer(),
                // Unit toggle
                _UnitToggle(
                  unit: _unit,
                  accent: accent,
                  onChanged: (u) => setState(() => _unit = u),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9.]')),
                    ],
                    decoration: deco('Min'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _maxCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9.]')),
                    ],
                    decoration: deco('Max'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _stepCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9.]')),
                    ],
                    decoration: deco('Step'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'e.g. 10 to 160 step 10 → snaps weights to real stops.',
              style: TextStyle(
                  fontSize: 11,
                  color: textPrimary.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              decoration: deco('Notes (optional)'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!,
                  style: TextStyle(
                      color: Colors.red.shade400, fontSize: 12)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context).commonCancel),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
          ),
          child: Text(AppLocalizations.of(context).commonDone),
        ),
      ],
    );
  }
}

/// Small lbs/kg pill toggle used inside [_CustomEquipmentDialog].
class _UnitToggle extends StatelessWidget {
  final String unit;
  final Color accent;
  final ValueChanged<String> onChanged;

  const _UnitToggle({
    required this.unit,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    Widget pill(String value, String label) {
      final selected = unit == value;
      return GestureDetector(
        onTap: () => onChanged(value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: selected ? accent : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected
                  ? Colors.white
                  : Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: accent.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [pill('lbs', 'lb'), pill('kg', 'kg')],
      ),
    );
  }
}

/// Compact "AI import" call-to-action shown above the equipment list.
class _ImportFromAIButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color accentColor;
  final bool isDark;

  const _ImportFromAIButton({
    required this.onTap,
    required this.accentColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accentColor.withValues(alpha: 0.18),
              accentColor.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentColor.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: accentColor, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).gymEquipmentImportFromPdfPhotos,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.white
                          : AppColorsLight.textPrimary,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context).gymEquipmentLetAiPopulateYour,
                    style: TextStyle(
                      fontSize: 11,
                      color: (isDark
                              ? Colors.white
                              : AppColorsLight.textPrimary)
                          .withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: accentColor, size: 18),
          ],
        ),
      ),
    );
  }
}
