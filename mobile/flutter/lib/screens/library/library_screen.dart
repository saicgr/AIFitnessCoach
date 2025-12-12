import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/theme_provider.dart';
import '../../data/models/exercise.dart';
import '../../data/services/api_client.dart';

// Provider for exercises
final exercisesProvider = FutureProvider.autoDispose<List<LibraryExercise>>((ref) async {
  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.get(ApiConstants.exercises);

  if (response.statusCode == 200) {
    final data = response.data as List;
    return data.map((e) => LibraryExercise.fromJson(e as Map<String, dynamic>)).toList();
  }
  throw Exception('Failed to load exercises');
});

// Search filter provider
final exerciseSearchProvider = StateProvider<String>((ref) => '');
final selectedMuscleGroupProvider = StateProvider<String?>((ref) => null);
final selectedEquipmentProvider = StateProvider<String?>((ref) => null);

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(exercisesProvider);
    final searchQuery = ref.watch(exerciseSearchProvider);
    final selectedMuscle = ref.watch(selectedMuscleGroupProvider);
    final selectedEquipment = ref.watch(selectedEquipmentProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Exercise Library',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Browse and learn exercises',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
                        ),
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (value) =>
                    ref.read(exerciseSearchProvider.notifier).state = value,
                decoration: InputDecoration(
                  hintText: 'Search exercises...',
                  prefixIcon: Icon(Icons.search, color: isDark ? AppColors.textMuted : AppColorsLight.textMuted),
                  filled: true,
                  fillColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: isDark ? BorderSide.none : BorderSide(color: AppColorsLight.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: isDark ? BorderSide.none : BorderSide(color: AppColorsLight.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? AppColors.cyan : AppColorsLight.cyan),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Filter chips
            SizedBox(
              height: 40,
              child: exercisesAsync.when(
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
                data: (exercises) {
                  final muscleGroups = exercises
                      .map((e) => e.muscleGroup)
                      .where((m) => m != null)
                      .toSet()
                      .toList();

                  return ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _FilterChip(
                        label: 'All',
                        isSelected: selectedMuscle == null,
                        onTap: () {
                          ref.read(selectedMuscleGroupProvider.notifier).state = null;
                        },
                      ),
                      ...muscleGroups.map((muscle) => _FilterChip(
                            label: muscle!,
                            isSelected: selectedMuscle == muscle,
                            onTap: () {
                              ref.read(selectedMuscleGroupProvider.notifier).state =
                                  selectedMuscle == muscle ? null : muscle;
                            },
                          )),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // Exercise list
            Expanded(
              child: exercisesAsync.when(
                loading: () => Center(
                  child: CircularProgressIndicator(color: isDark ? AppColors.cyan : AppColorsLight.cyan),
                ),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: isDark ? AppColors.error : AppColorsLight.error,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text('Failed to load exercises: $e'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.refresh(exercisesProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (exercises) {
                  // Apply filters
                  var filtered = exercises;

                  if (searchQuery.isNotEmpty) {
                    filtered = filtered
                        .where((e) =>
                            e.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                            (e.muscleGroup?.toLowerCase().contains(searchQuery.toLowerCase()) ??
                                false))
                        .toList();
                  }

                  if (selectedMuscle != null) {
                    filtered = filtered
                        .where((e) => e.muscleGroup == selectedMuscle)
                        .toList();
                  }

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          const Text('No exercises found'),
                          if (searchQuery.isNotEmpty || selectedMuscle != null)
                            TextButton(
                              onPressed: () {
                                ref.read(exerciseSearchProvider.notifier).state = '';
                                ref.read(selectedMuscleGroupProvider.notifier).state = null;
                              },
                              child: const Text('Clear filters'),
                            ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final exercise = filtered[index];
                      return _ExerciseCard(exercise: exercise)
                          .animate()
                          .fadeIn(delay: Duration(milliseconds: index * 50));
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Filter Chip
// ─────────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? cyan.withOpacity(0.2) : elevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? cyan : cardBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? cyan : textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Exercise Card
// ─────────────────────────────────────────────────────────────────

class _ExerciseCard extends StatelessWidget {
  final LibraryExercise exercise;

  const _ExerciseCard({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;

    return GestureDetector(
      onTap: () => _showExerciseDetail(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(16),
          border: isDark ? null : Border.all(color: AppColorsLight.cardBorder),
        ),
        child: Row(
          children: [
            // GIF
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: glassSurface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              clipBehavior: Clip.hardEdge,
              child: exercise.gifUrl != null && exercise.gifUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: exercise.gifUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cyan,
                        ),
                      ),
                      errorWidget: (context, url, error) => Icon(
                        Icons.fitness_center,
                        size: 32,
                        color: textMuted,
                      ),
                    )
                  : Icon(
                      Icons.fitness_center,
                      size: 32,
                      color: textMuted,
                    ),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (exercise.muscleGroup != null) ...[
                          _InfoBadge(
                            icon: Icons.accessibility_new,
                            text: exercise.muscleGroup!,
                            color: purple,
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (exercise.difficulty != null)
                          _InfoBadge(
                            icon: Icons.signal_cellular_alt,
                            text: exercise.difficulty!,
                            color: AppColors.getDifficultyColor(exercise.difficulty!),
                          ),
                      ],
                    ),
                    if (exercise.equipment != null &&
                        exercise.equipment!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        exercise.equipment!.take(2).join(', '),
                        style: TextStyle(
                          fontSize: 11,
                          color: textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Arrow
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                Icons.chevron_right,
                color: textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExerciseDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ExerciseDetailSheet(exercise: exercise),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoBadge({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Exercise Detail Sheet
// ─────────────────────────────────────────────────────────────────

class _ExerciseDetailSheet extends StatelessWidget {
  final LibraryExercise exercise;

  const _ExerciseDetailSheet({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBackground = isDark ? AppColors.nearBlack : AppColorsLight.pureWhite;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: sheetBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // GIF
              Container(
                width: double.infinity,
                height: 250,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: elevated,
                  borderRadius: BorderRadius.circular(16),
                  border: isDark ? null : Border.all(color: AppColorsLight.cardBorder),
                ),
                clipBehavior: Clip.hardEdge,
                child: exercise.gifUrl != null && exercise.gifUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: exercise.gifUrl!,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(color: cyan),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.fitness_center,
                          size: 64,
                          color: textMuted,
                        ),
                      )
                    : Icon(
                        Icons.fitness_center,
                        size: 64,
                        color: textMuted,
                      ),
              ),

              const SizedBox(height: 20),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  exercise.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),

              const SizedBox(height: 12),

              // Badges
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (exercise.muscleGroup != null)
                      _DetailBadge(
                        icon: Icons.accessibility_new,
                        label: 'Muscle',
                        value: exercise.muscleGroup!,
                        color: purple,
                      ),
                    if (exercise.difficulty != null)
                      _DetailBadge(
                        icon: Icons.signal_cellular_alt,
                        label: 'Level',
                        value: exercise.difficulty!,
                        color: AppColors.getDifficultyColor(exercise.difficulty!),
                      ),
                    if (exercise.type != null)
                      _DetailBadge(
                        icon: Icons.category,
                        label: 'Type',
                        value: exercise.type!,
                        color: cyan,
                      ),
                  ],
                ),
              ),

              // Equipment
              if (exercise.equipment != null && exercise.equipment!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EQUIPMENT NEEDED',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textMuted,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: exercise.equipment!.map((eq) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: elevated,
                              borderRadius: BorderRadius.circular(8),
                              border: isDark ? null : Border.all(color: AppColorsLight.cardBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.fitness_center,
                                  size: 14,
                                  color: textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  eq,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],

              // Instructions
              if (exercise.instructions != null &&
                  exercise.instructions!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'INSTRUCTIONS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textMuted,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...exercise.instructions!.asMap().entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: cyan.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${entry.key + 1}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: cyan,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  entry.value,
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DetailBadge({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(8),
        border: isDark ? null : Border.all(color: AppColorsLight.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: textMuted,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
