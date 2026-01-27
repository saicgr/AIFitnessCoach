import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/repositories/library_repository.dart';
import '../../../../widgets/exercise_image.dart';

/// The type of exercise preference being selected
enum ExercisePickerType {
  favorite,
  staple,
  queue,
  avoided,
}

/// Result from the exercise picker
class ExercisePickerResult {
  final String exerciseName;
  final String? exerciseId;
  final String? muscleGroup;
  final String? reason; // For staples or avoided
  final bool isTemporary; // For avoided
  final DateTime? endDate; // For avoided
  final String? targetMuscleGroup; // For queue

  const ExercisePickerResult({
    required this.exerciseName,
    this.exerciseId,
    this.muscleGroup,
    this.reason,
    this.isTemporary = false,
    this.endDate,
    this.targetMuscleGroup,
  });
}

/// Shows exercise picker sheet and returns the selected exercise with options
Future<ExercisePickerResult?> showExercisePickerSheet(
  BuildContext context,
  WidgetRef ref, {
  required ExercisePickerType type,
  Set<String>? excludeExercises,
}) async {
  return await showModalBottomSheet<ExercisePickerResult>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useRootNavigator: true,
    builder: (context) => _ExercisePickerSheet(
      type: type,
      excludeExercises: excludeExercises ?? {},
    ),
  );
}

class _ExercisePickerSheet extends ConsumerStatefulWidget {
  final ExercisePickerType type;
  final Set<String> excludeExercises;

  const _ExercisePickerSheet({
    required this.type,
    required this.excludeExercises,
  });

  @override
  ConsumerState<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends ConsumerState<_ExercisePickerSheet> {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  List<LibraryExerciseItem> _searchResults = [];
  String _searchQuery = '';

  // For staple exercises
  String? _selectedReason;
  final _reasonOptions = [
    ('core_compound', 'Core Compound'),
    ('favorite', 'Personal Favorite'),
    ('rehab', 'Rehab / Recovery'),
    ('strength_focus', 'Strength Focus'),
    ('other', 'Other'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _title {
    switch (widget.type) {
      case ExercisePickerType.favorite:
        return 'Add Favorite Exercise';
      case ExercisePickerType.staple:
        return 'Add Staple Exercise';
      case ExercisePickerType.queue:
        return 'Add to Exercise Queue';
      case ExercisePickerType.avoided:
        return 'Add Exercise to Avoid';
    }
  }

  String get _subtitle {
    switch (widget.type) {
      case ExercisePickerType.favorite:
        return 'Search for exercises to add to your favorites';
      case ExercisePickerType.staple:
        return 'Search for core lifts to lock in your workouts';
      case ExercisePickerType.queue:
        return 'Search for exercises to include in your next workout';
      case ExercisePickerType.avoided:
        return 'Search for exercises you want to skip';
    }
  }

  Color get _accentColor {
    switch (widget.type) {
      case ExercisePickerType.favorite:
        return AppColors.error; // Heart color
      case ExercisePickerType.staple:
        return AppColors.cyan;
      case ExercisePickerType.queue:
        return AppColors.cyan;
      case ExercisePickerType.avoided:
        return AppColors.orange;
    }
  }

  /// Icon for the header badge
  IconData get _icon {
    switch (widget.type) {
      case ExercisePickerType.favorite:
        return Icons.favorite_border;
      case ExercisePickerType.staple:
        return Icons.push_pin_outlined; // Different from action icon to avoid confusion
      case ExercisePickerType.queue:
        return Icons.add_circle_outline;
      case ExercisePickerType.avoided:
        return Icons.block_outlined;
    }
  }

  /// Icon shown on each exercise card's action button (unselected/add state)
  IconData get _actionIcon {
    switch (widget.type) {
      case ExercisePickerType.favorite:
        return Icons.favorite_border;
      case ExercisePickerType.staple:
        return Icons.lock_open; // Open lock = tap to lock in
      case ExercisePickerType.queue:
        return Icons.add_circle_outline;
      case ExercisePickerType.avoided:
        return Icons.block_outlined;
    }
  }

  Future<void> _search(String query) async {
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
        _searchQuery = query;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchQuery = query;
    });

    try {
      final libraryRepo = ref.read(libraryRepositoryProvider);
      final results = await libraryRepo.searchExercises(query: query);

      // Filter out already added exercises
      final filtered = results.where((e) {
        return !widget.excludeExercises
            .any((name) => name.toLowerCase() == e.name.toLowerCase());
      }).toList();

      if (mounted) {
        setState(() {
          _searchResults = filtered;
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint('Error searching exercises: $e');
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    }
  }

  void _selectExercise(LibraryExerciseItem exercise) {
    HapticFeedback.lightImpact();

    // Return result directly - staples no longer need reason picker
    // Staples are now always included in every workout regardless of reason
    Navigator.pop(
      context,
      ExercisePickerResult(
        exerciseName: exercise.name,
        exerciseId: exercise.id,
        muscleGroup: exercise.targetMuscle ?? exercise.bodyPart,
        targetMuscleGroup: exercise.targetMuscle ?? exercise.bodyPart,
        reason: widget.type == ExercisePickerType.staple ? 'staple' : null,
      ),
    );
  }

  void _showStapleReasonPicker(LibraryExerciseItem exercise) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Why is "${exercise.name}" a staple?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This helps the AI understand your training priorities',
              style: TextStyle(fontSize: 13, color: textMuted),
            ),
            const SizedBox(height: 16),
            ...(_reasonOptions.map((option) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: isDark ? AppColors.glassSurface : AppColorsLight.glassSurface,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    // Pop the reason picker
                    Navigator.pop(context);
                    // Pop the main picker with result
                    Navigator.pop(
                      this.context,
                      ExercisePickerResult(
                        exerciseName: exercise.name,
                        exerciseId: exercise.id,
                        muscleGroup: exercise.targetMuscle ?? exercise.bodyPart,
                        reason: option.$1,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          _getReasonIcon(option.$1),
                          color: AppColors.cyan,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            option.$2,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
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
                ),
              ),
            ))),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  IconData _getReasonIcon(String reason) {
    switch (reason) {
      case 'core_compound':
        return Icons.fitness_center;
      case 'favorite':
        return Icons.favorite;
      case 'rehab':
        return Icons.healing;
      case 'strength_focus':
        return Icons.trending_up;
      default:
        return Icons.star;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.nearBlack : AppColorsLight.pureWhite;
    final cardBackground = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: textMuted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_icon, color: _accentColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _subtitle,
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: TextStyle(color: textPrimary),
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                hintStyle: TextStyle(color: textMuted),
                prefixIcon: Icon(Icons.search, color: textMuted),
                filled: true,
                fillColor: cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _accentColor),
                ),
              ),
              onChanged: _search,
            ),
          ),

          const SizedBox(height: 16),

          // Results
          Expanded(
            child: _isSearching
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: _accentColor),
                        const SizedBox(height: 16),
                        Text(
                          'Searching...',
                          style: TextStyle(color: textMuted),
                        ),
                      ],
                    ),
                  )
                : _searchQuery.isEmpty
                    ? _buildEmptyState(textMuted)
                    : _searchResults.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 48,
                                  color: textMuted.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No exercises found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: textMuted,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try a different search term',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: textMuted.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final exercise = _searchResults[index];
                              return _ExerciseCard(
                                exercise: exercise,
                                accentColor: _accentColor,
                                actionIcon: _actionIcon,
                                textPrimary: textPrimary,
                                textMuted: textMuted,
                                onTap: () => _selectExercise(exercise),
                              );
                            },
                          ),
          ),
        ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color textMuted) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search,
            size: 48,
            color: textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Search for exercises',
            style: TextStyle(
              fontSize: 16,
              color: textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Type at least 2 characters to search',
            style: TextStyle(
              fontSize: 13,
              color: textMuted.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final LibraryExerciseItem exercise;
  final Color accentColor;
  final IconData actionIcon;
  final Color textPrimary;
  final Color textMuted;
  final VoidCallback onTap;

  const _ExerciseCard({
    required this.exercise,
    required this.accentColor,
    required this.actionIcon,
    required this.textPrimary,
    required this.textMuted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBackground = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: cardBackground,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Exercise image (fetches presigned URL from API)
                ExerciseImage(
                  exerciseName: exercise.name,
                  width: 60,
                  height: 60,
                  borderRadius: 8,
                  backgroundColor: glassSurface,
                  iconColor: textMuted,
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          exercise.targetMuscle ?? exercise.bodyPart,
                          exercise.equipment,
                        ].where((s) => s != null && s.isNotEmpty).join(' • '),
                        style: TextStyle(
                          fontSize: 12,
                          color: textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Add icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    actionIcon,
                    color: accentColor,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
