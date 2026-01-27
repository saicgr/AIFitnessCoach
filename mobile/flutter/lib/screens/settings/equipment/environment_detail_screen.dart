import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/environment_equipment_provider.dart';
import '../../../models/equipment_item.dart';

/// Screen showing equipment details for a specific workout environment.
class EnvironmentDetailScreen extends ConsumerStatefulWidget {
  final WorkoutEnvironment environment;
  final List<String> equipment;
  final bool isCurrentEnvironment;

  const EnvironmentDetailScreen({
    super.key,
    required this.environment,
    required this.equipment,
    required this.isCurrentEnvironment,
  });

  @override
  ConsumerState<EnvironmentDetailScreen> createState() => _EnvironmentDetailScreenState();
}

class _EnvironmentDetailScreenState extends ConsumerState<EnvironmentDetailScreen> {
  late List<EquipmentItem> _equipmentItems;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _equipmentItems = widget.equipment.map((e) => EquipmentItem.fromName(e)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Scaffold(
      backgroundColor: isDark ? AppColors.pureBlack : AppColorsLight.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.pureBlack : AppColorsLight.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : AppColorsLight.textPrimary,
          ),
          onPressed: () => _handleBack(),
        ),
        title: Row(
          children: [
            Text(
              widget.environment.icon,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 8),
            Text(
              widget.environment.displayName,
              style: TextStyle(
                color: isDark ? Colors.white : AppColorsLight.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _saveChanges,
              child: Text(
                'Save',
                style: TextStyle(
                  color: AppColors.cyan,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Status banner
          if (widget.isCurrentEnvironment)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: AppColors.cyan.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.cyan, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'This is your active environment',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.cyan,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // Equipment list
          Expanded(
            child: _equipmentItems.isEmpty
                ? _buildEmptyState(isDark, textMuted)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _equipmentItems.length,
                    itemBuilder: (context, index) {
                      final item = _equipmentItems[index];
                      return _EquipmentCard(
                        item: item,
                        onEdit: () => _editEquipment(index),
                        onDelete: () => _deleteEquipment(index),
                      );
                    },
                  ),
          ),

          // Bottom action bar
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.elevated : AppColorsLight.elevated,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showAddEquipmentSheet(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Equipment'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.cyan,
                        side: BorderSide(color: AppColors.cyan),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (!widget.isCurrentEnvironment)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _useThisEnvironment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.cyan,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Use This',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, Color textMuted) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 64,
            color: textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No equipment added',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColorsLight.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Add Equipment" to get started',
            style: TextStyle(
              fontSize: 14,
              color: textMuted,
            ),
          ),
        ],
      ),
    );
  }

  void _handleBack() {
    if (_hasChanges) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unsaved Changes'),
          content: const Text('You have unsaved changes. Do you want to save them before leaving?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Discard'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _saveChanges();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _saveChanges() {
    // Save detailed equipment with quantities and weights
    final equipmentDetails = _equipmentItems.map((e) => e.toJson()).toList();
    ref.read(environmentEquipmentProvider.notifier).setEquipmentDetails(equipmentDetails);

    setState(() => _hasChanges = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Equipment saved')),
    );
  }

  void _editEquipment(int index) {
    _showEquipmentEditor(_equipmentItems[index], (updated) {
      setState(() {
        _equipmentItems[index] = updated;
        _hasChanges = true;
      });
    });
  }

  void _deleteEquipment(int index) {
    HapticFeedback.mediumImpact();
    final item = _equipmentItems[index];

    setState(() {
      _equipmentItems.removeAt(index);
      _hasChanges = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.displayName} removed'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _equipmentItems.insert(index, item);
            });
          },
        ),
      ),
    );
  }

  void _showAddEquipmentSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) => _AddEquipmentSheet(
        existingEquipment: _equipmentItems.map((e) => e.name).toSet(),
        onAdd: (item) {
          setState(() {
            _equipmentItems.add(item);
            _hasChanges = true;
          });
        },
      ),
    );
  }

  void _showEquipmentEditor(EquipmentItem item, void Function(EquipmentItem) onSave) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) => _EditEquipmentSheet(
        item: item,
        onSave: onSave,
      ),
    );
  }

  void _useThisEnvironment() {
    HapticFeedback.selectionClick();

    final equipmentNames = _equipmentItems.map((e) => e.name).toList();

    // Save equipment first, then switch environment
    ref.read(environmentEquipmentProvider.notifier).setEquipment(equipmentNames);
    ref.read(environmentEquipmentProvider.notifier).setEnvironment(widget.environment);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Switched to ${widget.environment.displayName}')),
    );

    Navigator.pop(context);
  }
}

class _EquipmentCard extends StatelessWidget {
  final EquipmentItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EquipmentCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevated : AppColorsLight.elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Equipment icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.pureBlack : Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    _getEquipmentIcon(item.name),
                    color: AppColors.cyan,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),

                // Name and details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.displayName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColorsLight.textPrimary,
                        ),
                      ),
                      if (item.summary.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.summary,
                          style: TextStyle(
                            fontSize: 13,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Actions
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.delete_outline,
                    color: Colors.red.withValues(alpha: 0.7),
                    size: 20,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getEquipmentIcon(String name) {
    switch (name.toLowerCase()) {
      case 'dumbbells':
      case 'barbell':
      case 'kettlebells':
        return Icons.fitness_center;
      case 'treadmill':
      case 'stationary_bike':
      case 'elliptical':
      case 'rowing_machine':
        return Icons.directions_run;
      case 'pull_up_bar':
      case 'dip_station':
        return Icons.sports_gymnastics;
      case 'yoga_mat':
      case 'foam_roller':
        return Icons.self_improvement;
      case 'resistance_bands':
      case 'trx_suspension':
        return Icons.change_history;
      default:
        return Icons.fitness_center;
    }
  }
}

class _AddEquipmentSheet extends StatefulWidget {
  final Set<String> existingEquipment;
  final void Function(EquipmentItem) onAdd;

  const _AddEquipmentSheet({
    required this.existingEquipment,
    required this.onAdd,
  });

  @override
  State<_AddEquipmentSheet> createState() => _AddEquipmentSheetState();
}

class _AddEquipmentSheetState extends State<_AddEquipmentSheet> {
  final _searchController = TextEditingController();
  final _customNameController = TextEditingController();
  String _searchQuery = '';
  bool _showCustomForm = false;

  @override
  void dispose() {
    _searchController.dispose();
    _customNameController.dispose();
    super.dispose();
  }

  List<String> get _filteredEquipment {
    final available = commonEquipmentOptions
        .where((e) => !widget.existingEquipment.contains(e))
        .toList();

    if (_searchQuery.isEmpty) return available;

    return available
        .where((e) => getEquipmentDisplayName(e).toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Add Equipment',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColorsLight.textPrimary,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() => _showCustomForm = !_showCustomForm),
                    icon: Icon(
                      _showCustomForm ? Icons.list : Icons.add,
                      size: 18,
                    ),
                    label: Text(_showCustomForm ? 'Browse' : 'Custom'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (_showCustomForm) ...[
              // Custom equipment form
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    TextField(
                      controller: _customNameController,
                      decoration: InputDecoration(
                        labelText: 'Equipment Name',
                        hintText: 'e.g., TRX Bands',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_customNameController.text.trim().isNotEmpty) {
                            final name = _customNameController.text.trim().toLowerCase().replaceAll(' ', '_');
                            final item = EquipmentItem(
                              name: name,
                              displayName: _customNameController.text.trim(),
                            );
                            widget.onAdd(item);
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.cyan,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Add Custom Equipment'),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Search field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search equipment...',
                    prefixIcon: Icon(Icons.search, color: textMuted),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cardBorder),
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.pureBlack.withValues(alpha: 0.3) : Colors.grey[100],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Equipment list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredEquipment.length,
                  itemBuilder: (context, index) {
                    final equip = _filteredEquipment[index];
                    return ListTile(
                      title: Text(getEquipmentDisplayName(equip)),
                      leading: Icon(Icons.fitness_center, color: textMuted),
                      trailing: Icon(Icons.add, color: AppColors.cyan),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        widget.onAdd(EquipmentItem.fromName(equip));
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EditEquipmentSheet extends StatefulWidget {
  final EquipmentItem item;
  final void Function(EquipmentItem) onSave;

  const _EditEquipmentSheet({
    required this.item,
    required this.onSave,
  });

  @override
  State<_EditEquipmentSheet> createState() => _EditEquipmentSheetState();
}

class _EditEquipmentSheetState extends State<_EditEquipmentSheet> {
  late TextEditingController _quantityController;
  late TextEditingController _weightsController;
  late TextEditingController _notesController;
  late String _weightUnit;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: widget.item.quantity.toString());
    _weightsController = TextEditingController(
      text: widget.item.weights.map((w) => w == w.roundToDouble() ? w.toInt().toString() : w.toString()).join(', '),
    );
    _notesController = TextEditingController(text: widget.item.notes ?? '');
    _weightUnit = widget.item.weightUnit;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _weightsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Edit ${widget.item.displayName}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColorsLight.textPrimary,
              ),
            ),
            const SizedBox(height: 24),

            // Quantity
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Quantity',
                hintText: 'e.g., 2',
                helperText: 'How many do you have?',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            // Weights
            TextField(
              controller: _weightsController,
              decoration: InputDecoration(
                labelText: 'Available Weights',
                hintText: 'e.g., 15, 25, 40',
                helperText: 'Separate multiple weights with commas',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: DropdownButton<String>(
                  value: _weightUnit,
                  underline: const SizedBox(),
                  items: ['lbs', 'kg'].map((unit) {
                    return DropdownMenuItem(value: unit, child: Text(unit));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _weightUnit = value);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'e.g., Adjustable 5-50lbs',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final quantity = int.tryParse(_quantityController.text) ?? 1;
    final weights = _weightsController.text
        .split(',')
        .map((s) => double.tryParse(s.trim()))
        .whereType<double>()
        .toList();

    final updated = widget.item.copyWith(
      quantity: quantity,
      weights: weights,
      weightUnit: _weightUnit,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    widget.onSave(updated);
    Navigator.pop(context);
  }
}
