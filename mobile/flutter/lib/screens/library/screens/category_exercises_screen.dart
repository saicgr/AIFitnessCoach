import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/exercise.dart';
import '../../../data/services/api_client.dart';
import '../../../widgets/glass_back_button.dart';
import '../widgets/exercise_card.dart';

/// Screen showing all exercises for a specific category
class CategoryExercisesScreen extends ConsumerStatefulWidget {
  final String categoryName;
  final List<LibraryExercise> initialExercises;

  const CategoryExercisesScreen({
    super.key,
    required this.categoryName,
    required this.initialExercises,
  });

  @override
  ConsumerState<CategoryExercisesScreen> createState() =>
      _CategoryExercisesScreenState();
}

class _CategoryExercisesScreenState
    extends ConsumerState<CategoryExercisesScreen> {
  final ScrollController _scrollController = ScrollController();
  late List<LibraryExercise> _exercises;
  bool _isLoading = false;
  bool _hasMore = true;
  String _sortBy = 'name'; // name, difficulty

  @override
  void initState() {
    super.initState();
    _exercises = List.from(widget.initialExercises);
    _scrollController.addListener(_onScroll);

    // Load more exercises for this category if we only have the preview set
    if (_exercises.length <= 20) {
      _loadMoreExercises();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreExercises();
    }
  }

  Future<void> _loadMoreExercises() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      final apiClient = ref.read(apiClientProvider);

      // Map category name to body parts for API query
      final bodyParts = _getBodyPartsForCategory(widget.categoryName);

      final queryParams = <String, String>{
        'limit': '50',
        'offset': '${_exercises.length}',
      };

      if (bodyParts.isNotEmpty) {
        queryParams['body_parts'] = bodyParts.join(',');
      }

      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      final url = '/library/exercises?$queryString';

      final response = await apiClient.get(url);

      if (response.statusCode == 200 && mounted) {
        final data = response.data as List;
        final newExercises = data
            .map((e) => LibraryExercise.fromJson(e as Map<String, dynamic>))
            .toList();

        setState(() {
          // Filter out duplicates
          final existingIds = _exercises.map((e) => e.id).toSet();
          final uniqueNew = newExercises
              .where((e) => !existingIds.contains(e.id))
              .toList();
          _exercises.addAll(uniqueNew);
          _hasMore = newExercises.length >= 50;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _hasMore = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading more exercises: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasMore = false;
        });
      }
    }
  }

  List<String> _getBodyPartsForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'arms':
        return ['Biceps', 'Triceps', 'Forearms'];
      case 'legs':
        return ['Quadriceps', 'Hamstrings', 'Glutes', 'Calves', 'Hips'];
      case 'chest':
        return ['Chest'];
      case 'back':
        return ['Back'];
      case 'shoulders':
        return ['Shoulders'];
      case 'core':
        return ['Core', 'Abdominals'];
      case 'popular':
        return []; // No filter for popular
      default:
        return [category];
    }
  }

  void _sortExercises(String sortBy) {
    setState(() {
      _sortBy = sortBy;
      if (sortBy == 'name') {
        _exercises.sort((a, b) => a.name.compareTo(b.name));
      } else if (sortBy == 'difficulty') {
        final difficultyOrder = {
          'beginner': 0,
          'intermediate': 1,
          'advanced': 2,
          'expert': 3,
        };
        _exercises.sort((a, b) {
          final aOrder = difficultyOrder[a.difficulty?.toLowerCase()] ?? 4;
          final bOrder = difficultyOrder[b.difficulty?.toLowerCase()] ?? 4;
          return aOrder.compareTo(bOrder);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.nearBlack : AppColorsLight.pureWhite;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: const GlassBackButton(),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.categoryName,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            Text(
              '${_exercises.length} exercises',
              style: TextStyle(
                fontSize: 12,
                color: textMuted,
              ),
            ),
          ],
        ),
        actions: [
          // Sort button
          PopupMenuButton<String>(
            icon: Icon(Icons.sort, color: textMuted),
            color: elevated,
            onSelected: _sortExercises,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'name',
                child: Row(
                  children: [
                    Icon(
                      Icons.sort_by_alpha,
                      size: 20,
                      color: _sortBy == 'name' ? cyan : textMuted,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Name',
                      style: TextStyle(
                        color: _sortBy == 'name' ? cyan : textPrimary,
                        fontWeight:
                            _sortBy == 'name' ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'difficulty',
                child: Row(
                  children: [
                    Icon(
                      Icons.signal_cellular_alt,
                      size: 20,
                      color: _sortBy == 'difficulty' ? cyan : textMuted,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Difficulty',
                      style: TextStyle(
                        color: _sortBy == 'difficulty' ? cyan : textPrimary,
                        fontWeight: _sortBy == 'difficulty'
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _exercises.isEmpty
          ? Center(
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
                    'No exercises found',
                    style: TextStyle(
                      fontSize: 16,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: _exercises.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= _exercises.length) {
                  // Loading indicator at bottom
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: _isLoading
                          ? CircularProgressIndicator(
                              color: cyan,
                              strokeWidth: 2,
                            )
                          : TextButton(
                              onPressed: _loadMoreExercises,
                              child: Text(
                                'Load more',
                                style: TextStyle(color: cyan),
                              ),
                            ),
                    ),
                  );
                }

                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 200 + (index % 10) * 50),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: ExerciseCard(exercise: _exercises[index]),
                );
              },
            ),
    );
  }
}
