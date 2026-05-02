import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/custom_exercises_provider.dart';
import '../../../data/models/custom_exercise.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/segmented_tab_bar.dart';

part 'create_exercise_sheet_part_dashed_border_painter.dart';

part 'create_exercise_sheet_ui.dart';


/// Bottom sheet for creating a new custom exercise
class CreateExerciseSheet extends ConsumerStatefulWidget {
  /// Optional initial name to pre-fill the exercise name field
  final String? initialName;

  const CreateExerciseSheet({super.key, this.initialName});

  @override
  ConsumerState<CreateExerciseSheet> createState() => _CreateExerciseSheetState();
}

class _CreateExerciseSheetState extends ConsumerState<CreateExerciseSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Simple exercise fields
  final _nameController = TextEditingController();
  final _instructionsController = TextEditingController();
  String _primaryMuscle = 'chest';
  String _equipment = 'dumbbell';
  int _defaultSets = 3;
  int _defaultReps = 10;
  bool _isCompound = false;

  // Advanced fields
  final _restController = TextEditingController();
  final _rpeController = TextEditingController();
  final _tempoController = TextEditingController();
  final _notesController = TextEditingController();
  final _romController = TextEditingController();
  final _inclineController = TextEditingController();
  final _durationController = TextEditingController();
  final _distanceController = TextEditingController();
  String? _selectedBandColor;
  bool _showAdvanced = false;

  static const _bandColorOptions = [
    ('yellow', 'Yellow'),
    ('red', 'Red'),
    ('green', 'Green'),
    ('blue', 'Blue'),
    ('black', 'Black'),
    ('purple', 'Purple'),
  ];

  // Composite exercise fields
  final _comboNameController = TextEditingController();
  final _comboNotesController = TextEditingController();
  ComboType _comboType = ComboType.superset;
  String _comboPrimaryMuscle = 'chest';
  String _comboEquipment = 'dumbbell';
  final List<ComponentExercise> _components = [];
  final _componentNameController = TextEditingController();
  int _componentReps = 10;

  bool _isSubmitting = false;
  File? _selectedImage;
  bool _isAnalyzing = false;
  final _imagePicker = ImagePicker();

  final List<String> _muscleGroups = [
    'chest', 'back', 'shoulders', 'biceps', 'triceps',
    'forearms', 'abs', 'core', 'quadriceps', 'hamstrings',
    'glutes', 'calves', 'full body',
  ];

  final List<String> _equipmentOptions = [
    'bodyweight', 'dumbbell', 'barbell', 'kettlebell',
    'cable', 'machine', 'resistance band', 'medicine ball',
    'slam ball', 'other',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.initialName != null) {
      _nameController.text = widget.initialName!;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _instructionsController.dispose();
    _comboNameController.dispose();
    _comboNotesController.dispose();
    _componentNameController.dispose();
    _restController.dispose();
    _rpeController.dispose();
    _tempoController.dispose();
    _notesController.dispose();
    _romController.dispose();
    _inclineController.dispose();
    _durationController.dispose();
    _distanceController.dispose();
    super.dispose();
  }

  bool get _nameLooksCardio {
    final n = _nameController.text.toLowerCase();
    return n.contains('walk') || n.contains('run') || n.contains('jog') ||
        n.contains('hike') || n.contains('cycle') || n.contains('swim') ||
        n.contains('row') || n.contains('sprint');
  }

  bool get _nameLooksTimed {
    final n = _nameController.text.toLowerCase();
    return n.contains('plank') || n.contains('hold') || n.contains('hang') ||
        n.contains('wall sit') || n.contains('isometric') || n.contains('static');
  }

  bool get _nameLooksStretch {
    final n = _nameController.text.toLowerCase();
    return n.contains('stretch') || n.contains('yoga') || n.contains('mobility');
  }

  bool get _equipmentUsesBand => _equipment.toLowerCase().contains('band');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.elevated : AppColorsLight.pureWhite;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.9,
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
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Create Exercise',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
          ),

          // Tab bar
          SegmentedTabBar(
            controller: _tabController,
            showIcons: false,
            tabs: const [
              SegmentedTabItem(label: 'Simple'),
              SegmentedTabItem(label: 'Combo'),
            ],
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSimpleForm(context, isDark),
                _buildComboForm(context, isDark),
              ],
            ),
          ),
        ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleForm(BuildContext context, bool isDark) {
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo section
            _buildPhotoSection(isDark, cyan),
            const SizedBox(height: 20),

            // Name field
            _buildLabel('Exercise Name', isDark),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _nameController,
              hint: 'e.g., My Custom Press',
              isDark: isDark,
              validator: (v) => v?.isEmpty == true ? 'Name required' : null,
            ),
            const SizedBox(height: 20),

            // Muscle group
            _buildLabel('Primary Muscle', isDark),
            const SizedBox(height: 8),
            _buildDropdown(
              value: _primaryMuscle,
              items: _muscleGroups,
              onChanged: (v) => setState(() => _primaryMuscle = v!),
              isDark: isDark,
            ),
            const SizedBox(height: 20),

            // Equipment
            _buildLabel('Equipment', isDark),
            const SizedBox(height: 8),
            _buildDropdown(
              value: _equipment,
              items: _equipmentOptions,
              onChanged: (v) => setState(() => _equipment = v!),
              isDark: isDark,
            ),
            const SizedBox(height: 20),

            // Sets and Reps
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Default Sets', isDark),
                      const SizedBox(height: 8),
                      _buildNumberStepper(
                        value: _defaultSets,
                        min: 1,
                        max: 10,
                        onChanged: (v) => setState(() => _defaultSets = v),
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Default Reps', isDark),
                      const SizedBox(height: 8),
                      _buildNumberStepper(
                        value: _defaultReps,
                        min: 1,
                        max: 50,
                        onChanged: (v) => setState(() => _defaultReps = v),
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Compound toggle
            _buildToggleTile(
              'Compound Exercise',
              'Targets multiple muscle groups',
              _isCompound,
              (v) => setState(() => _isCompound = v),
              isDark,
            ),
            const SizedBox(height: 20),

            // Instructions (optional)
            _buildLabel('Instructions (optional)', isDark),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _instructionsController,
              hint: 'Describe how to perform this exercise...',
              isDark: isDark,
              maxLines: 4,
            ),
            const SizedBox(height: 20),

            // Advanced fields (collapsible)
            _buildAdvancedSection(isDark),
            const SizedBox(height: 32),

            // Create button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _createSimpleExercise,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cyan,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text(
                        'Create Exercise',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildComboForm(BuildContext context, bool isDark) {
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Combo name
          _buildLabel('Combo Name', isDark),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _comboNameController,
            hint: 'e.g., Bench Press & Chest Fly Superset',
            isDark: isDark,
          ),
          const SizedBox(height: 20),

          // Combo type
          _buildLabel('Combo Type', isDark),
          const SizedBox(height: 8),
          _buildComboTypeSelector(isDark),
          const SizedBox(height: 20),

          // Muscle and Equipment row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Muscle', isDark),
                    const SizedBox(height: 8),
                    _buildDropdown(
                      value: _comboPrimaryMuscle,
                      items: _muscleGroups,
                      onChanged: (v) => setState(() => _comboPrimaryMuscle = v!),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Equipment', isDark),
                    const SizedBox(height: 8),
                    _buildDropdown(
                      value: _comboEquipment,
                      items: _equipmentOptions,
                      onChanged: (v) => setState(() => _comboEquipment = v!),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Components section
          Row(
            children: [
              Text(
                'Exercises (${_components.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              if (_components.length < 5)
                TextButton.icon(
                  onPressed: () => _showAddComponentDialog(context, isDark),
                  icon: Icon(Icons.add, size: 18, color: cyan),
                  label: Text('Add', style: TextStyle(color: cyan)),
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (_components.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surface : AppColorsLight.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.black12,
                  style: BorderStyle.solid,
                ),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.layers_outlined, size: 40, color: textSecondary),
                    const SizedBox(height: 8),
                    Text(
                      'Add at least 2 exercises',
                      style: TextStyle(color: textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else
            ...List.generate(_components.length, (index) {
              final comp = _components[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildComponentTile(comp, index, isDark),
              );
            }),

          const SizedBox(height: 20),

          // Notes (optional)
          _buildLabel('Notes (optional)', isDark),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _comboNotesController,
            hint: 'Any special instructions...',
            isDark: isDark,
            maxLines: 3,
          ),
          const SizedBox(height: 32),

          // Create button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting || _components.length < 2
                  ? null
                  : _createComboExercise,
              style: ElevatedButton.styleFrom(
                backgroundColor: cyan,
                foregroundColor: Colors.black,
                disabledBackgroundColor: cyan.withOpacity(0.3),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : Text(
                      _components.length < 2
                          ? 'Add ${2 - _components.length} more exercises'
                          : 'Create Combo Exercise',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPhotoSection(bool isDark, Color cyan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Photo (optional)', isDark),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _selectedImage == null ? () => _showImageSourceSheet() : null,
          child: Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surface : AppColorsLight.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.12),
                width: 1.5,
                style: BorderStyle.solid,
              ),
            ),
            child: _selectedImage != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            HapticService.light();
                            setState(() => _selectedImage = null);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : CustomPaint(
                    painter: _DashedBorderPainter(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.15),
                      borderRadius: 12,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt_outlined,
                            size: 40,
                            color: isDark
                                ? AppColors.textMuted
                                : AppColorsLight.textMuted,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add Photo',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.textMuted
                                  : AppColorsLight.textMuted,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
        if (_selectedImage != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isAnalyzing ? null : _analyzeWithAI,
              style: ElevatedButton.styleFrom(
                backgroundColor: cyan.withValues(alpha: 0.15),
                foregroundColor: cyan,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: cyan.withValues(alpha: 0.3)),
                ),
              ),
              icon: _isAnalyzing
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cyan,
                      ),
                    )
                  : Icon(Icons.auto_awesome, size: 18, color: cyan),
              label: Text(
                _isAnalyzing ? 'Analyzing...' : 'Analyze with AI',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: cyan,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showImageSourceSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.elevated : AppColorsLight.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() => _selectedImage = File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _analyzeWithAI() async {
    if (_selectedImage == null) return;

    setState(() => _isAnalyzing = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final bytes = await _selectedImage!.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await apiClient.post(
        '/custom-exercises/$userId/analyze-photo',
        data: {'image_base64': base64Image},
      );

      final data = response.data as Map<String, dynamic>;

      setState(() {
        if (data['name'] != null) {
          _nameController.text = data['name'] as String;
        }
        if (data['primary_muscle'] != null) {
          final muscle = (data['primary_muscle'] as String).toLowerCase();
          if (_muscleGroups.contains(muscle)) {
            _primaryMuscle = muscle;
          }
        }
        if (data['equipment'] != null) {
          final equip = (data['equipment'] as String).toLowerCase();
          if (_equipmentOptions.contains(equip)) {
            _equipment = equip;
          }
        }
        if (data['is_compound'] != null) {
          _isCompound = data['is_compound'] as bool;
        }
        if (data['instructions'] != null) {
          _instructionsController.text = data['instructions'] as String;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI filled exercise details — review and save'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to analyze photo: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  Widget _buildComboTypeSelector(bool isDark) {
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ComboType.values.map((type) {
        final isSelected = type == _comboType;
        return GestureDetector(
          onTap: () {
            HapticService.light();
            setState(() => _comboType = type);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? cyan.withOpacity(0.2) : (isDark ? AppColors.surface : AppColorsLight.surface),
              borderRadius: BorderRadius.circular(10),
              border: isSelected ? Border.all(color: cyan, width: 2) : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isSelected ? cyan : (isDark ? Colors.white : Colors.black),
                  ),
                ),
                Text(
                  type.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildComponentTile(ComponentExercise comp, int index, bool isDark) {
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : AppColorsLight.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: cyan.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                '${comp.order}',
                style: TextStyle(
                  color: cyan,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comp.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (comp.targetDisplay.isNotEmpty)
                  Text(
                    comp.targetDisplay,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              HapticService.light();
              setState(() => _components.removeAt(index));
            },
            icon: const Icon(Icons.close, size: 18),
            color: Colors.red.withOpacity(0.7),
          ),
        ],
      ),
    );
  }

  void _showAddComponentDialog(BuildContext context, bool isDark) {
    _componentNameController.clear();
    _componentReps = 10;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Exercise'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _componentNameController,
                decoration: const InputDecoration(
                  labelText: 'Exercise Name',
                  hintText: 'e.g., Bench Press',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Reps: '),
                  IconButton(
                    onPressed: () {
                      if (_componentReps > 1) {
                        setDialogState(() => _componentReps--);
                      }
                    },
                    icon: const Icon(Icons.remove),
                  ),
                  Text('$_componentReps', style: const TextStyle(fontSize: 18)),
                  IconButton(
                    onPressed: () {
                      if (_componentReps < 50) {
                        setDialogState(() => _componentReps++);
                      }
                    },
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_componentNameController.text.isNotEmpty) {
                  setState(() {
                    _components.add(ComponentExercise(
                      name: _componentNameController.text,
                      order: _components.length + 1,
                      reps: _componentReps,
                    ));
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createSimpleExercise() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    String? textOrNull(TextEditingController c) {
      final t = c.text.trim();
      return t.isEmpty ? null : t;
    }

    final durationMinutes = double.tryParse(_durationController.text.trim());
    final durationSeconds = durationMinutes != null ? (durationMinutes * 60).round() : null;

    final result = await ref.read(customExercisesProvider.notifier).createSimpleExercise(
          name: _nameController.text.trim(),
          primaryMuscle: _primaryMuscle,
          equipment: _equipment,
          instructions: textOrNull(_instructionsController),
          defaultSets: _defaultSets,
          defaultReps: _defaultReps,
          isCompound: _isCompound,
          defaultRestSeconds: int.tryParse(_restController.text.trim()),
          defaultRpe: int.tryParse(_rpeController.text.trim()),
          defaultTempo: textOrNull(_tempoController),
          defaultBandColor: _selectedBandColor,
          defaultNotes: textOrNull(_notesController),
          defaultRangeOfMotion: textOrNull(_romController),
          defaultInclinePercent: double.tryParse(_inclineController.text.trim()),
          defaultDurationSeconds: durationSeconds,
          defaultDistanceMiles: double.tryParse(_distanceController.text.trim()),
          imageFilePath: _selectedImage?.path,
        );

    setState(() => _isSubmitting = false);

    if (result != null && mounted) {
      Navigator.pop(context);
    }
  }

  Widget _buildAdvancedSection(bool isDark) {
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final surface = isDark ? AppColors.surface : AppColorsLight.surface;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              HapticService.light();
              setState(() => _showAdvanced = !_showAdvanced);
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(Icons.science_outlined, color: cyan, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Advanced (optional)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Rest, RPE, tempo, incline, distance, duration, notes',
                          style: TextStyle(fontSize: 12, color: textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _showAdvanced ? Icons.expand_less : Icons.expand_more,
                    color: textMuted,
                  ),
                ],
              ),
            ),
          ),
          if (_showAdvanced) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rest
                  _buildAdvField('Rest (sec)', _restController, isDark, keyboard: true),
                  const SizedBox(height: 10),

                  // RPE
                  _buildAdvField('RPE (1-10)', _rpeController, isDark, keyboard: true),
                  const SizedBox(height: 10),

                  // Tempo (strength-ish)
                  if (!_nameLooksCardio)
                    _buildAdvField('Tempo (e.g. 3-0-1-0)', _tempoController, isDark),
                  if (!_nameLooksCardio) const SizedBox(height: 10),

                  // Duration — only for timed / stretch / cardio
                  if (_nameLooksTimed || _nameLooksStretch || _nameLooksCardio)
                    _buildAdvField(
                      _nameLooksCardio ? 'Duration (min)' : 'Hold duration (sec)',
                      _durationController,
                      isDark,
                      keyboard: true,
                    ),
                  if (_nameLooksTimed || _nameLooksStretch || _nameLooksCardio)
                    const SizedBox(height: 10),

                  // Incline — cardio / bench
                  if (_nameLooksCardio ||
                      _nameController.text.toLowerCase().contains('bench') ||
                      _nameController.text.toLowerCase().contains('incline'))
                    _buildAdvField('Incline (%)', _inclineController, isDark, keyboard: true),
                  if (_nameLooksCardio ||
                      _nameController.text.toLowerCase().contains('bench') ||
                      _nameController.text.toLowerCase().contains('incline'))
                    const SizedBox(height: 10),

                  // Distance — walking/running/swimming
                  if (_nameLooksCardio)
                    _buildAdvField('Distance (mi)', _distanceController, isDark, keyboard: true),
                  if (_nameLooksCardio) const SizedBox(height: 10),

                  // ROM — strength / stretch
                  _buildAdvField('Range of motion', _romController, isDark),
                  const SizedBox(height: 10),

                  // Band color chips
                  if (_equipmentUsesBand) ...[
                    Text(
                      'Band',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _bandColorOptions.map((e) {
                        final (value, label) = e;
                        final isSelected = _selectedBandColor == value;
                        return GestureDetector(
                          onTap: () {
                            HapticService.light();
                            setState(() {
                              _selectedBandColor = isSelected ? null : value;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? cyan.withValues(alpha: 0.2) : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? cyan : textMuted.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                color: isSelected ? cyan : textMuted,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Notes
                  Text(
                    'Notes',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildTextField(
                    controller: _notesController,
                    hint: 'e.g. Focus on squeeze at top, slow eccentric',
                    isDark: isDark,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdvField(
    String label,
    TextEditingController controller,
    bool isDark, {
    bool keyboard = false,
  }) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return Row(
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: textMuted),
          ),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: keyboard
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white : Colors.black,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: textMuted.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: textMuted.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDark ? AppColors.cyan : AppColorsLight.cyan,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _createComboExercise() async {
    if (_comboNameController.text.isEmpty || _components.length < 2) return;

    setState(() => _isSubmitting = true);

    final result = await ref.read(customExercisesProvider.notifier).createCompositeExercise(
          name: _comboNameController.text.trim(),
          primaryMuscle: _comboPrimaryMuscle,
          equipment: _comboEquipment,
          comboType: _comboType,
          components: _components,
          customNotes: _comboNotesController.text.trim().isEmpty
              ? null
              : _comboNotesController.text.trim(),
        );

    setState(() => _isSubmitting = false);

    if (result != null && mounted) {
      Navigator.pop(context);
    }
  }
}
