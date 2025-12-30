import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/custom_exercises_provider.dart';
import '../../data/models/custom_exercise.dart';
import '../../data/services/haptic_service.dart';
import 'widgets/custom_exercise_card.dart';
import 'widgets/create_exercise_sheet.dart';
import 'widgets/empty_custom_exercises.dart';

/// Screen for viewing and managing custom exercises
class CustomExercisesScreen extends ConsumerStatefulWidget {
  const CustomExercisesScreen({super.key});

  @override
  ConsumerState<CustomExercisesScreen> createState() => _CustomExercisesScreenState();
}

class _CustomExercisesScreenState extends ConsumerState<CustomExercisesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize custom exercises
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customExercisesProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final state = ref.watch(customExercisesProvider);

    // Listen for success/error messages
    ref.listen<CustomExercisesState>(customExercisesProvider, (previous, next) {
      if (next.successMessage != null && previous?.successMessage != next.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        ref.read(customExercisesProvider.notifier).clearSuccess();
      }
      if (next.error != null && previous?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        ref.read(customExercisesProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, isDark, state),
            if (state.exercises.isNotEmpty) ...[
              _buildSearchBar(context, isDark),
              _buildTabBar(context, isDark),
              const SizedBox(height: 8),
            ],
            Expanded(
              child: state.isLoading && state.exercises.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : state.exercises.isEmpty
                      ? EmptyCustomExercises(
                          onCreatePressed: () => _showCreateSheet(context),
                        )
                      : _buildTabContent(context, isDark, state),
            ),
          ],
        ),
      ),
      floatingActionButton: state.exercises.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateSheet(context),
              backgroundColor: isDark ? AppColors.cyan : AppColorsLight.cyan,
              icon: const Icon(Icons.add, color: Colors.black),
              label: const Text(
                'Create',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, CustomExercisesState state) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final stats = state.stats;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              HapticService.light();
              context.pop();
            },
            icon: Icon(Icons.arrow_back_ios, color: textMuted, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Exercises',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (stats != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${stats.totalCustomExercises} exercises, ${stats.totalUses} uses',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
                        ),
                  ),
                ],
              ],
            ),
          ),
          if (state.isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isDark) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(12),
          border: isDark ? null : Border.all(color: AppColorsLight.cardBorder),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() => _searchQuery = value);
          },
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
          ),
          decoration: InputDecoration(
            hintText: 'Search exercises...',
            hintStyle: TextStyle(color: textMuted),
            prefixIcon: Icon(Icons.search, color: textMuted),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: textMuted),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, bool isDark) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(12),
        border: isDark ? null : Border.all(color: AppColorsLight.cardBorder),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: cyan.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        labelColor: cyan,
        unselectedLabelColor: textMuted,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Simple'),
          Tab(text: 'Combos'),
        ],
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, bool isDark, CustomExercisesState state) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildExerciseList(context, isDark, _filterExercises(state.exercises)),
        _buildExerciseList(context, isDark, _filterExercises(state.simpleExercises)),
        _buildExerciseList(context, isDark, _filterExercises(state.compositeExercises)),
      ],
    );
  }

  List<CustomExercise> _filterExercises(List<CustomExercise> exercises) {
    if (_searchQuery.isEmpty) return exercises;
    final query = _searchQuery.toLowerCase();
    return exercises.where((e) {
      return e.name.toLowerCase().contains(query) ||
          e.primaryMuscle.toLowerCase().contains(query) ||
          e.equipment.toLowerCase().contains(query);
    }).toList();
  }

  Widget _buildExerciseList(BuildContext context, bool isDark, List<CustomExercise> exercises) {
    if (exercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty ? 'No exercises match your search' : 'No exercises in this category',
              style: TextStyle(
                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(customExercisesProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: exercises.length,
        itemBuilder: (context, index) {
          final exercise = exercises[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CustomExerciseCard(
              exercise: exercise,
              onTap: () => _showExerciseDetails(context, exercise),
              onDelete: () => _confirmDelete(context, exercise),
            ),
          );
        },
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    HapticService.light();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateExerciseSheet(),
    );
  }

  void _showExerciseDetails(BuildContext context, CustomExercise exercise) {
    HapticService.light();
    // For now, show a simple details dialog
    // Later this can be a full detail screen
    showDialog(
      context: context,
      builder: (context) => _ExerciseDetailsDialog(exercise: exercise),
    );
  }

  void _confirmDelete(BuildContext context, CustomExercise exercise) {
    HapticService.medium();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Exercise'),
        content: Text('Are you sure you want to delete "${exercise.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(customExercisesProvider.notifier).deleteExercise(exercise.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Dialog showing exercise details
class _ExerciseDetailsDialog extends StatelessWidget {
  final CustomExercise exercise;

  const _ExerciseDetailsDialog({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(exercise.name)),
          if (exercise.isComposite)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: cyan.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                exercise.typeLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cyan,
                ),
              ),
            ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetail('Muscle', exercise.primaryMuscle),
            _buildDetail('Equipment', exercise.equipment),
            _buildDetail('Sets', exercise.defaultSets.toString()),
            if (exercise.defaultReps != null)
              _buildDetail('Reps', exercise.defaultReps.toString()),
            if (exercise.defaultRestSeconds != null)
              _buildDetail('Rest', '${exercise.defaultRestSeconds}s'),
            if (exercise.instructions != null && exercise.instructions!.isNotEmpty)
              _buildDetail('Instructions', exercise.instructions!),
            if (exercise.isComposite && exercise.componentExercises != null) ...[
              const SizedBox(height: 16),
              const Text(
                'Components',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...exercise.componentExercises!.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: cyan.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              '${c.order}',
                              style: TextStyle(
                                color: cyan,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${c.name} ${c.targetDisplay.isNotEmpty ? "(${c.targetDisplay})" : ""}',
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
            if (exercise.usageCount > 0) ...[
              const SizedBox(height: 16),
              Text(
                'Used ${exercise.usageCount} times${exercise.lastUsedFormatted != null ? " - Last: ${exercise.lastUsedFormatted}" : ""}',
                style: TextStyle(
                  color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
