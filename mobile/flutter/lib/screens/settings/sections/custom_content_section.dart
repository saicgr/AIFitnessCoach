import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/exercise_repository.dart';
import '../../../data/services/api_client.dart';
import '../widgets/section_header.dart';

/// Section for managing user's custom content: equipment, exercises, workouts.
///
/// Allows users to add and manage content not in the predefined lists.
class CustomContentSection extends StatelessWidget {
  const CustomContentSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SectionHeader(title: 'MY CUSTOM CONTENT'),
        SizedBox(height: 12),
        _CustomContentCard(),
      ],
    );
  }
}

class _CustomContentCard extends ConsumerWidget {
  const _CustomContentCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Material(
      color: elevatedColor,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // My Equipment
          _CustomContentTile(
            icon: Icons.fitness_center,
            title: 'My Equipment',
            subtitle: 'Add equipment not in the standard list',
            iconColor: AppColors.cyan,
            onTap: () => _showEquipmentSheet(context, ref),
          ),
          Divider(height: 1, color: cardBorder, indent: 50),

          // My Exercises - navigate to full screen
          _CustomContentTile(
            icon: Icons.sports_gymnastics,
            title: 'My Exercises',
            subtitle: 'Create custom & combo exercises',
            iconColor: AppColors.purple,
            onTap: () => context.push('/custom-exercises'),
          ),
        ],
      ),
    );
  }

  void _showEquipmentSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.elevated : AppColorsLight.elevated,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.fitness_center, color: AppColors.cyan),
                      const SizedBox(width: 12),
                      Text(
                        'My Custom Equipment',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color:
                              isDark ? Colors.white : AppColorsLight.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Add equipment that will be used when generating your workouts.',
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child:
                      _CustomEquipmentManager(scrollController: scrollController),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showExercisesSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.elevated : AppColorsLight.elevated,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.sports_gymnastics,
                          color: AppColors.purple),
                      const SizedBox(width: 12),
                      Text(
                        'My Custom Exercises',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color:
                              isDark ? Colors.white : AppColorsLight.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Create exercises that can be included in your AI-generated workouts.',
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child:
                      _CustomExercisesManager(scrollController: scrollController),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showComingSoonSnackbar(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.elevated
            : AppColorsLight.elevated,
      ),
    );
  }
}

/// Tile for each custom content type
class _CustomContentTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final bool isDisabled;
  final VoidCallback onTap;

  const _CustomContentTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.onTap,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: isDisabled ? 0.1 : 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isDisabled ? textMuted : iconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDisabled ? textMuted : textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget to manage custom equipment from settings
class _CustomEquipmentManager extends ConsumerStatefulWidget {
  final ScrollController scrollController;

  const _CustomEquipmentManager({required this.scrollController});

  @override
  ConsumerState<_CustomEquipmentManager> createState() =>
      _CustomEquipmentManagerState();
}

class _CustomEquipmentManagerState
    extends ConsumerState<_CustomEquipmentManager> {
  List<String> _customEquipment = [];
  final _textController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadCustomEquipment();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomEquipment() async {
    debugPrint('🏋️ [CustomEquipment] Loading custom equipment...');
    try {
      final authState = ref.read(authStateProvider);
      _userId = authState.user?.id;

      if (_userId == null) {
        debugPrint('⚠️ [CustomEquipment] User not logged in');
        setState(() => _isLoading = false);
        return;
      }

      // Fetch user data to get custom_equipment
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get('/users/$_userId');

      if (response.data != null) {
        final userData = response.data as Map<String, dynamic>;
        final customEquipmentData = userData['custom_equipment'];

        List<String> equipment = [];
        if (customEquipmentData != null) {
          if (customEquipmentData is List) {
            equipment = customEquipmentData.cast<String>();
          } else if (customEquipmentData is String && customEquipmentData.isNotEmpty) {
            // Parse JSON string
            try {
              final parsed = List<String>.from(
                (customEquipmentData as String).isNotEmpty
                    ? List.from(Uri.decodeComponent(customEquipmentData).split(','))
                    : [],
              );
              equipment = parsed;
            } catch (e) {
              debugPrint('⚠️ [CustomEquipment] Error parsing: $e');
            }
          }
        }

        debugPrint('✅ [CustomEquipment] Loaded ${equipment.length} custom equipment items');
        setState(() {
          _customEquipment = equipment;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('❌ [CustomEquipment] Error loading: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveCustomEquipment() async {
    if (_userId == null) return;

    setState(() => _isSaving = true);
    debugPrint('💾 [CustomEquipment] Saving ${_customEquipment.length} items...');

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.put(
        '/users/$_userId',
        data: {
          'custom_equipment': _customEquipment,
        },
      );
      debugPrint('✅ [CustomEquipment] Saved successfully');
    } catch (e) {
      debugPrint('❌ [CustomEquipment] Error saving: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _addEquipment(String name) async {
    if (name.trim().isEmpty) return;

    final trimmed = name.trim();
    if (_customEquipment.contains(trimmed)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$trimmed is already in your list'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _customEquipment.add(trimmed);
    });
    _textController.clear();

    // Save to backend
    await _saveCustomEquipment();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added "$trimmed" to your equipment'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.cyan.withValues(alpha: 0.9),
        ),
      );
    }
  }

  Future<void> _removeEquipment(String name) async {
    setState(() {
      _customEquipment.remove(name);
    });

    // Save to backend
    await _saveCustomEquipment();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed "$name"'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Add Equipment Input
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: 'Enter equipment name...',
                    hintStyle: TextStyle(color: textMuted),
                    filled: true,
                    fillColor:
                        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.cyan),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: _addEquipment,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => _addEquipment(_textController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Add',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Equipment List
        Expanded(
          child: _customEquipment.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 48,
                        color: textMuted,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No custom equipment yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add equipment above to get started',
                        style: TextStyle(
                          fontSize: 14,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _customEquipment.length,
                  itemBuilder: (context, index) {
                    final equipment = _customEquipment[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.pureBlack
                            : AppColorsLight.pureWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cardBorder),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.cyan.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.fitness_center,
                            color: AppColors.cyan,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          equipment,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.red,
                            size: 22,
                          ),
                          onPressed: () => _removeEquipment(equipment),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Custom exercise data model
class CustomExercise {
  final String id;
  final String name;
  final String primaryMuscle;
  final String equipment;
  final String instructions;
  final int defaultSets;
  final int? defaultReps;
  final bool isCompound;
  final String createdAt;

  CustomExercise({
    required this.id,
    required this.name,
    required this.primaryMuscle,
    required this.equipment,
    required this.instructions,
    required this.defaultSets,
    this.defaultReps,
    required this.isCompound,
    required this.createdAt,
  });

  factory CustomExercise.fromJson(Map<String, dynamic> json) {
    return CustomExercise(
      id: json['id'] as String,
      name: json['name'] as String,
      primaryMuscle: json['primary_muscle'] as String,
      equipment: json['equipment'] as String,
      instructions: json['instructions'] as String? ?? '',
      defaultSets: json['default_sets'] as int? ?? 3,
      defaultReps: json['default_reps'] as int?,
      isCompound: json['is_compound'] as bool? ?? false,
      createdAt: json['created_at'] as String,
    );
  }
}

/// Widget to manage custom exercises from settings
class _CustomExercisesManager extends ConsumerStatefulWidget {
  final ScrollController scrollController;

  const _CustomExercisesManager({required this.scrollController});

  @override
  ConsumerState<_CustomExercisesManager> createState() =>
      _CustomExercisesManagerState();
}

class _CustomExercisesManagerState
    extends ConsumerState<_CustomExercisesManager> {
  List<CustomExercise> _customExercises = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCustomExercises();
  }

  Future<void> _loadCustomExercises() async {
    debugPrint('🏋️ [CustomExercisesManager] Loading custom exercises...');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id;

      if (userId == null) {
        debugPrint('⚠️ [CustomExercisesManager] User not logged in');
        setState(() {
          _isLoading = false;
          _error = 'Not logged in';
        });
        return;
      }

      debugPrint('🏋️ [CustomExercisesManager] Fetching exercises for user: $userId');
      final exerciseRepo = ref.read(exerciseRepositoryProvider);
      final exercises = await exerciseRepo.getCustomExercises(userId);

      setState(() {
        _customExercises =
            exercises.map((e) => CustomExercise.fromJson(e)).toList();
        _isLoading = false;
      });
      debugPrint('✅ [CustomExercisesManager] Loaded ${_customExercises.length} custom exercises');
    } catch (e, stackTrace) {
      debugPrint('❌ [CustomExercisesManager] Error loading exercises: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _showAddExerciseDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddExerciseDialog(
        onAdd: _addExercise,
      ),
    );
  }

  Future<void> _addExercise(Map<String, dynamic> exerciseData) async {
    debugPrint('🏋️ [CustomExercisesManager] Adding new exercise: ${exerciseData['name']}');
    debugPrint('🏋️ [CustomExercisesManager] Exercise details - muscle: ${exerciseData['primary_muscle']}, equipment: ${exerciseData['equipment']}, sets: ${exerciseData['default_sets']}, reps: ${exerciseData['default_reps']}');

    try {
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id;

      if (userId == null) {
        debugPrint('⚠️ [CustomExercisesManager] Cannot add exercise - user not logged in');
        return;
      }

      final exerciseRepo = ref.read(exerciseRepositoryProvider);
      await exerciseRepo.createCustomExercise(userId, exerciseData);

      debugPrint('✅ [CustomExercisesManager] Successfully added exercise: ${exerciseData['name']}');

      // Reload the list
      await _loadCustomExercises();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added "${exerciseData['name']}"'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.purple.withValues(alpha: 0.9),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [CustomExercisesManager] Error adding exercise: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteExercise(CustomExercise exercise) async {
    debugPrint('🏋️ [CustomExercisesManager] Delete requested for exercise: ${exercise.name} (ID: ${exercise.id})');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Exercise?'),
        content: Text('Are you sure you want to delete "${exercise.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      debugPrint('🏋️ [CustomExercisesManager] Delete cancelled by user');
      return;
    }

    debugPrint('🏋️ [CustomExercisesManager] User confirmed deletion of: ${exercise.name}');

    try {
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id;

      if (userId == null) {
        debugPrint('⚠️ [CustomExercisesManager] Cannot delete exercise - user not logged in');
        return;
      }

      final exerciseRepo = ref.read(exerciseRepositoryProvider);
      await exerciseRepo.deleteCustomExercise(userId, exercise.id);

      debugPrint('✅ [CustomExercisesManager] Successfully deleted exercise: ${exercise.name}');

      // Reload the list
      await _loadCustomExercises();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted "${exercise.name}"'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [CustomExercisesManager] Error deleting exercise: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.red),
            const SizedBox(height: 12),
            Text(
              'Failed to load exercises',
              style: TextStyle(fontSize: 16, color: textMuted),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadCustomExercises,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Add Exercise Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showAddExerciseDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Custom Exercise'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Exercise List
        Expanded(
          child: _customExercises.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.sports_gymnastics,
                        size: 48,
                        color: textMuted,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No custom exercises yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap the button above to create one',
                        style: TextStyle(
                          fontSize: 14,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _customExercises.length,
                  itemBuilder: (context, index) {
                    final exercise = _customExercises[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.pureBlack
                            : AppColorsLight.pureWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cardBorder),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.purple.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.sports_gymnastics,
                            color: AppColors.purple,
                            size: 24,
                          ),
                        ),
                        title: Text(
                          exercise.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              _ExerciseTag(
                                  label: exercise.primaryMuscle,
                                  color: AppColors.cyan),
                              const SizedBox(width: 6),
                              _ExerciseTag(
                                  label: exercise.equipment,
                                  color: AppColors.orange),
                            ],
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.red,
                            size: 22,
                          ),
                          onPressed: () => _deleteExercise(exercise),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Small tag widget for exercise details
class _ExerciseTag extends StatelessWidget {
  final String label;
  final Color color;

  const _ExerciseTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}

/// Dialog for adding a new custom exercise
class _AddExerciseDialog extends StatefulWidget {
  final Future<void> Function(Map<String, dynamic>) onAdd;

  const _AddExerciseDialog({required this.onAdd});

  @override
  State<_AddExerciseDialog> createState() => _AddExerciseDialogState();
}

class _AddExerciseDialogState extends State<_AddExerciseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _instructionsController = TextEditingController();

  String _selectedMuscle = 'chest';
  String _selectedEquipment = 'bodyweight';
  int _sets = 3;
  int _reps = 10;
  bool _isCompound = false;
  bool _isLoading = false;

  final List<String> _muscleGroups = [
    'chest',
    'back',
    'shoulders',
    'biceps',
    'triceps',
    'abs',
    'quadriceps',
    'hamstrings',
    'glutes',
    'calves',
    'full body',
  ];

  final List<String> _equipmentOptions = [
    'bodyweight',
    'dumbbell',
    'barbell',
    'kettlebell',
    'cable machine',
    'resistance band',
    'medicine ball',
    'pull-up bar',
    'bench',
    'other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await widget.onAdd({
        'name': _nameController.text.trim(),
        'primary_muscle': _selectedMuscle,
        'equipment': _selectedEquipment,
        'instructions': _instructionsController.text.trim(),
        'default_sets': _sets,
        'default_reps': _reps,
        'is_compound': _isCompound,
      });

      if (mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Custom Exercise'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Exercise Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Exercise Name *',
                    hintText: 'e.g., Pike Push-ups',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an exercise name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Muscle Group
                DropdownButtonFormField<String>(
                  value: _selectedMuscle,
                  decoration: const InputDecoration(
                    labelText: 'Target Muscle *',
                  ),
                  items: _muscleGroups
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(m[0].toUpperCase() + m.substring(1)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedMuscle = value);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Equipment
                DropdownButtonFormField<String>(
                  value: _selectedEquipment,
                  decoration: const InputDecoration(
                    labelText: 'Equipment *',
                  ),
                  items: _equipmentOptions
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(e[0].toUpperCase() + e.substring(1)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedEquipment = value);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Sets and Reps
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Sets',
                              style: TextStyle(fontSize: 12)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              IconButton(
                                onPressed: _sets > 1
                                    ? () => setState(() => _sets--)
                                    : null,
                                icon: const Icon(Icons.remove),
                                iconSize: 20,
                              ),
                              Text('$_sets',
                                  style: const TextStyle(fontSize: 18)),
                              IconButton(
                                onPressed: _sets < 10
                                    ? () => setState(() => _sets++)
                                    : null,
                                icon: const Icon(Icons.add),
                                iconSize: 20,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Reps', style: TextStyle(fontSize: 12)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              IconButton(
                                onPressed: _reps > 1
                                    ? () => setState(() => _reps--)
                                    : null,
                                icon: const Icon(Icons.remove),
                                iconSize: 20,
                              ),
                              Text('$_reps',
                                  style: const TextStyle(fontSize: 18)),
                              IconButton(
                                onPressed: _reps < 50
                                    ? () => setState(() => _reps++)
                                    : null,
                                icon: const Icon(Icons.add),
                                iconSize: 20,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Compound toggle
                SwitchListTile(
                  title: const Text('Compound Exercise'),
                  subtitle: const Text('Targets multiple muscle groups'),
                  value: _isCompound,
                  onChanged: (value) => setState(() => _isCompound = value),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),

                // Instructions (optional)
                TextFormField(
                  controller: _instructionsController,
                  decoration: const InputDecoration(
                    labelText: 'Instructions (optional)',
                    hintText: 'Describe how to perform...',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.purple,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Add Exercise'),
        ),
      ],
    );
  }
}
