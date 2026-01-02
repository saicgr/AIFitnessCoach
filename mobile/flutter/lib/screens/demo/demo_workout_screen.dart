import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/difficulty_utils.dart';
import '../../data/demo_workouts.dart';
import '../../data/services/analytics_service.dart';
import '../../data/services/api_client.dart';
import '../../core/constants/api_constants.dart';

/// Demo Workout Preview Screen
/// Shows a sample workout to users BEFORE they sign up
/// Allows them to see the workout structure without creating an account
///
/// This screen now fetches PERSONALIZED workouts from the API based on
/// the user's quiz answers, with REAL exercises including video GIFs.
class DemoWorkoutScreen extends ConsumerStatefulWidget {
  final String? workoutType;

  const DemoWorkoutScreen({super.key, this.workoutType});

  @override
  ConsumerState<DemoWorkoutScreen> createState() => _DemoWorkoutScreenState();
}

class _DemoWorkoutScreenState extends ConsumerState<DemoWorkoutScreen> {
  DemoWorkout? _currentWorkout;
  Map<String, dynamic>? _personalizedWorkout;
  bool _isLoading = true;
  int? _expandedExerciseIndex;
  bool _hasTrackedView = false;

  @override
  void initState() {
    super.initState();
    _loadPersonalizedWorkout();
  }

  Future<void> _loadPersonalizedWorkout() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get quiz data from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final goals = prefs.getStringList('preAuth_goals') ?? ['general_health'];
      final fitnessLevel = prefs.getString('preAuth_fitnessLevel') ?? 'intermediate';
      final equipment = prefs.getStringList('preAuth_equipment') ?? ['bodyweight'];
      final workoutType = prefs.getString('preAuth_workoutTypePreference') ?? 'strength';

      // Call the personalized sample workout API
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.post(
        '${ApiConstants.apiBaseUrl}/demo/personalized-sample-workout',
        data: {
          'goals': goals,
          'fitness_level': fitnessLevel,
          'equipment': equipment,
          'workout_type_preference': workoutType,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        setState(() {
          _personalizedWorkout = data;
          _isLoading = false;
        });

        // Track the view
        if (!_hasTrackedView) {
          _trackDemoView();
          _hasTrackedView = true;
        }
      } else {
        // Fall back to static demo workout
        _loadStaticWorkout();
      }
    } catch (e) {
      debugPrint('Failed to load personalized workout: $e');
      // Fall back to static demo workout
      _loadStaticWorkout();
    }
  }

  void _loadStaticWorkout({String? excludeType}) {
    if (widget.workoutType != null && excludeType == null) {
      _currentWorkout = DemoWorkouts.getWorkout(widget.workoutType!);
    } else {
      _currentWorkout = DemoWorkouts.getRandomWorkout(excludeType: excludeType);
    }
    setState(() {
      _isLoading = false;
      _personalizedWorkout = null;
    });

    // Track demo workout view
    if (!_hasTrackedView) {
      _trackDemoView();
      _hasTrackedView = true;
    }
  }

  void _trackDemoView() {
    try {
      final analytics = ref.read(analyticsServiceProvider);
      String workoutName;
      if (_personalizedWorkout != null) {
        final workout = _personalizedWorkout!['workout'] as Map<String, dynamic>?;
        workoutName = workout?['name'] as String? ?? 'personalized';
      } else {
        workoutName = _currentWorkout?.name ?? 'unknown';
      }
      analytics.trackEvent(
        eventName: 'demo_workout_viewed',
        category: 'demo',
        properties: {
          'workout_type': _personalizedWorkout != null ? 'personalized' : (_currentWorkout?.type ?? 'unknown'),
          'workout_name': workoutName,
          'is_personalized': _personalizedWorkout != null,
        },
      );
    } catch (e) {
      debugPrint('Failed to track demo view: $e');
    }
  }

  void _trackConversion(String action) {
    try {
      final analytics = ref.read(analyticsServiceProvider);
      String workoutName;
      if (_personalizedWorkout != null) {
        final workout = _personalizedWorkout!['workout'] as Map<String, dynamic>?;
        workoutName = workout?['name'] as String? ?? 'personalized';
      } else {
        workoutName = _currentWorkout?.name ?? 'unknown';
      }
      analytics.trackEvent(
        eventName: 'demo_to_signup_conversion',
        category: 'conversion',
        properties: {
          'workout_type': _personalizedWorkout != null ? 'personalized' : (_currentWorkout?.type ?? 'unknown'),
          'workout_name': workoutName,
          'action': action,
        },
      );
    } catch (e) {
      debugPrint('Failed to track conversion: $e');
    }
  }

  void _tryAnotherSample() {
    HapticFeedback.lightImpact();
    setState(() {
      _expandedExerciseIndex = null;
    });

    // Track the "try another" action
    try {
      final analytics = ref.read(analyticsServiceProvider);
      analytics.trackEvent(
        eventName: 'demo_try_another_clicked',
        category: 'demo',
        properties: {
          'previous_workout': _personalizedWorkout != null ? 'personalized' : (_currentWorkout?.type ?? 'unknown'),
        },
      );
    } catch (_) {}

    // Reload personalized workout (will get different exercises)
    _loadPersonalizedWorkout();
  }

  void _navigateToSignUp() {
    HapticFeedback.mediumImpact();
    _trackConversion('get_personalized_workouts');
    context.go('/pre-auth-quiz');
  }

  // Helper getters for personalized workout data
  Map<String, dynamic>? get _workout => _personalizedWorkout?['workout'];
  List<dynamic> get _exercises => _workout?['exercises'] as List<dynamic>? ?? [];
  String get _workoutName => _workout?['name'] ?? _currentWorkout?.name ?? 'Sample Workout';
  String get _workoutDescription => _workout?['description'] ?? _currentWorkout?.description ?? '';
  String get _workoutType => _workout?['type'] ?? _currentWorkout?.workoutType ?? 'strength';
  String get _difficulty => _workout?['difficulty'] ?? _currentWorkout?.difficulty ?? 'intermediate';
  int get _durationMinutes => _workout?['duration_minutes'] ?? _currentWorkout?.durationMinutes ?? 30;
  int get _caloriesEstimate => _workout?['calories_estimate'] ?? _currentWorkout?.estimatedCalories ?? 200;
  List<String> get _targetMuscles => (_workout?['target_muscles'] as List<dynamic>?)?.cast<String>() ?? _currentWorkout?.targetMuscles ?? [];
  List<String> get _equipment => (_workout?['equipment'] as List<dynamic>?)?.cast<String>() ?? _currentWorkout?.equipment ?? [];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;

    // Show loading state
    if (_isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.cyan),
              const SizedBox(height: 16),
              Text(
                'Creating your personalized workout...',
                style: TextStyle(
                  color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // If neither personalized nor static workout is available, show error
    if (_personalizedWorkout == null && _currentWorkout == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Failed to load workout',
                style: TextStyle(
                  color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _loadPersonalizedWorkout,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Spacer for floating header
              SliverToBoxAdapter(
                child: SizedBox(height: MediaQuery.of(context).padding.top + 70),
              ),

              // Demo Banner - show personalized badge if using personalized workout
              SliverToBoxAdapter(
                child: _buildDemoBanner(isDark),
              ),

              // Workout Header
              SliverToBoxAdapter(
                child: _buildWorkoutHeader(isDark),
              ),

              // Stats Row
              SliverToBoxAdapter(
                child: _buildStatsRow(isDark),
              ),

              // Target Muscles
              SliverToBoxAdapter(
                child: _buildTargetMuscles(isDark),
              ),

              // Equipment Needed
              if (_equipment.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildEquipmentSection(isDark),
                ),

              // Exercises Header
              SliverToBoxAdapter(
                child: _buildExercisesHeader(isDark),
              ),

              // Exercise List - use personalized exercises if available
              if (_personalizedWorkout != null)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildPersonalizedExerciseCard(
                      index,
                      _exercises[index] as Map<String, dynamic>,
                      isDark,
                    ),
                    childCount: _exercises.length,
                  ),
                )
              else if (_currentWorkout != null)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildExerciseCard(
                      index,
                      _currentWorkout!.exercises[index],
                      isDark,
                    ),
                    childCount: _currentWorkout!.exercises.length,
                  ),
                ),

              // CTA Section
              SliverToBoxAdapter(
                child: _buildCtaSection(isDark),
              ),

              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 32),
              ),
            ],
          ),

          // Floating Header
          _buildFloatingHeader(isDark),
        ],
      ),
    );
  }

  Widget _buildFloatingHeader(bool isDark) {
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : AppColorsLight.elevated,
                borderRadius: BorderRadius.circular(22),
                border:
                    isDark ? null : Border.all(color: cardBorder.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.4)
                        : Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: isDark ? Colors.white : AppColorsLight.textPrimary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Title
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : AppColorsLight.elevated,
                borderRadius: BorderRadius.circular(22),
                border:
                    isDark ? null : Border.all(color: cardBorder.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.4)
                        : Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'Sample Workout',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColorsLight.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2),
    );
  }

  Widget _buildDemoBanner(bool isDark) {
    final isPersonalized = _personalizedWorkout != null;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isPersonalized
              ? [
                  AppColors.purple.withOpacity(0.15),
                  AppColors.cyan.withOpacity(0.1),
                ]
              : [
                  AppColors.cyan.withOpacity(0.15),
                  AppColors.teal.withOpacity(0.1),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPersonalized
              ? AppColors.purple.withOpacity(0.3)
              : AppColors.cyan.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isPersonalized
                  ? AppColors.purple.withOpacity(0.2)
                  : AppColors.cyan.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPersonalized ? Icons.auto_awesome : Icons.preview_rounded,
              color: isPersonalized ? AppColors.purple : AppColors.cyan,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isPersonalized ? 'Your Personalized Workout' : 'Sample Workout Preview',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                      ),
                    ),
                    if (isPersonalized) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.purple.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'AI',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.purple,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isPersonalized
                      ? 'Based on your goals, equipment & fitness level'
                      : 'See what your personalized workouts could look like',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 300.ms);
  }

  Widget _buildWorkoutHeader(bool isDark) {
    final typeColor = AppColors.getWorkoutTypeColor(_workoutType);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Workout name
          Text(
            _workoutName,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                ),
          ),
          const SizedBox(height: 12),

          // Type and difficulty badges
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildBadge(
                label: 'Type',
                value: _workoutType.toUpperCase(),
                color: typeColor,
                backgroundColor: typeColor.withOpacity(0.2),
              ),
              _buildBadge(
                label: 'Difficulty',
                value: DifficultyUtils.getDisplayName(_difficulty),
                color: DifficultyUtils.getColor(_difficulty),
                backgroundColor: DifficultyUtils.getColor(_difficulty)
                    .withOpacity(0.2),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            _workoutDescription,
            style: TextStyle(
              fontSize: 15,
              color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms, duration: 300.ms);
  }

  Widget _buildBadge({
    required String label,
    required String value,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color.withOpacity(0.7),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(bool isDark) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final exerciseCount = _personalizedWorkout != null
        ? _exercises.length
        : (_currentWorkout?.exercises.length ?? 0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildStatCard(
            icon: Icons.timer_outlined,
            value: '$_durationMinutes',
            label: 'min',
            color: AppColors.cyan,
            backgroundColor: elevatedColor,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            icon: Icons.fitness_center,
            value: '$exerciseCount',
            label: 'exercises',
            color: AppColors.purple,
            backgroundColor: elevatedColor,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            icon: Icons.local_fire_department,
            value: '$_caloriesEstimate',
            label: 'cal',
            color: AppColors.orange,
            backgroundColor: elevatedColor,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 300.ms);
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required Color backgroundColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  TextSpan(
                    text: ' $label',
                    style: TextStyle(
                      fontSize: 12,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetMuscles(bool isDark) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    if (_targetMuscles.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cardBorder.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.cyan.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.accessibility_new,
                color: AppColors.cyan,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _targetMuscles.where((m) => m.isNotEmpty).map((muscle) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.cyan.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      muscle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.cyan,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 250.ms, duration: 300.ms);
  }

  Widget _buildEquipmentSection(bool isDark) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    if (_equipment.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
            children: _equipment.where((e) => e.isNotEmpty).map((equipment) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: elevatedColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 14,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      equipment,
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
    ).animate().fadeIn(delay: 300.ms, duration: 300.ms);
  }

  Widget _buildExercisesHeader(bool isDark) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final exerciseCount = _personalizedWorkout != null
        ? _exercises.length
        : (_currentWorkout?.exercises.length ?? 0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.purple.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.fitness_center, color: AppColors.purple, size: 16),
          ),
          const SizedBox(width: 12),
          Text(
            'EXERCISES',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textMuted,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.purple.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$exerciseCount',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.purple,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 350.ms, duration: 300.ms);
  }

  /// Build exercise card for PERSONALIZED workouts with GIF support
  Widget _buildPersonalizedExerciseCard(int index, Map<String, dynamic> exercise, bool isDark) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    final isExpanded = _expandedExerciseIndex == index;

    final exerciseName = exercise['name'] ?? 'Unknown Exercise';
    final muscleGroup = exercise['muscle_group'] ?? exercise['body_part'] ?? 'Unknown';
    final equipmentUsed = exercise['equipment'] ?? 'Bodyweight';
    final sets = exercise['sets'] ?? 3;
    final reps = exercise['reps'] ?? 12;
    final restSeconds = exercise['rest_seconds'] ?? 60;
    final gifUrl = exercise['gif_url'] as String?;
    final notes = exercise['notes'] ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            // Exercise header (tappable to expand)
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _expandedExerciseIndex = isExpanded ? null : index;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Exercise number badge OR GIF thumbnail
                    if (gifUrl != null && gifUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: gifUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.cyan, AppColors.teal],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.cyan, AppColors.teal],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.cyan, AppColors.teal],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: 12),

                    // Exercise info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exerciseName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              _buildExerciseChip(
                                Icons.fitness_center,
                                muscleGroup,
                                AppColors.cyan,
                              ),
                              _buildExerciseChip(
                                Icons.sports_gymnastics,
                                equipmentUsed,
                                AppColors.purple,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Video badge (if has GIF)
                    if (gifUrl != null && gifUrl.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_circle_outline, size: 12, color: AppColors.success),
                            const SizedBox(width: 2),
                            Text(
                              'Video',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],

                    // Expand/collapse icon
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: textMuted,
                    ),
                  ],
                ),
              ),
            ),

            // Sets/reps summary row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: glassSurface.withOpacity(0.3),
                border: Border(
                  top: BorderSide(color: cardBorder.withOpacity(0.3)),
                ),
              ),
              child: Row(
                children: [
                  _buildSummaryChip(
                    Icons.repeat,
                    '$sets sets',
                    AppColors.cyan,
                  ),
                  const SizedBox(width: 12),
                  _buildSummaryChip(
                    Icons.fitness_center,
                    '$reps reps',
                    AppColors.purple,
                  ),
                  const SizedBox(width: 12),
                  _buildSummaryChip(
                    Icons.timer_outlined,
                    _formatRestTime(restSeconds),
                    AppColors.orange,
                  ),
                ],
              ),
            ),

            // Expanded content with GIF and instructions
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState:
                  isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
              firstChild: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: glassSurface.withOpacity(0.5),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // GIF animation (if available)
                    if (gifUrl != null && gifUrl.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: gifUrl,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: double.infinity,
                            height: 200,
                            color: glassSurface,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.cyan,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: double.infinity,
                            height: 200,
                            color: glassSurface,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.videocam_off, size: 40, color: textMuted),
                                const SizedBox(height: 8),
                                Text(
                                  'Video unavailable',
                                  style: TextStyle(color: textMuted, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Instructions
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppColors.cyan,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'How to perform',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.cyan,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      notes.isNotEmpty ? notes : 'Focus on proper form and controlled movements.',
                      style: TextStyle(
                        fontSize: 14,
                        color: textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              secondChild: const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(
          delay: Duration(milliseconds: 400 + (index * 50)),
          duration: 300.ms,
        );
  }

  Widget _buildExerciseCard(int index, DemoExercise exercise, bool isDark) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    final isExpanded = _expandedExerciseIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            // Exercise header (tappable to expand)
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _expandedExerciseIndex = isExpanded ? null : index;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Exercise number badge
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.cyan, AppColors.teal],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Exercise info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              _buildExerciseChip(
                                Icons.fitness_center,
                                exercise.muscleGroup,
                                AppColors.cyan,
                              ),
                              _buildExerciseChip(
                                Icons.sports_gymnastics,
                                exercise.equipment,
                                AppColors.purple,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Expand/collapse icon
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: textMuted,
                    ),
                  ],
                ),
              ),
            ),

            // Sets/reps summary row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: glassSurface.withOpacity(0.3),
                border: Border(
                  top: BorderSide(color: cardBorder.withOpacity(0.3)),
                ),
              ),
              child: Row(
                children: [
                  _buildSummaryChip(
                    Icons.repeat,
                    '${exercise.sets} sets',
                    AppColors.cyan,
                  ),
                  const SizedBox(width: 12),
                  _buildSummaryChip(
                    Icons.fitness_center,
                    _getRepDisplay(exercise),
                    AppColors.purple,
                  ),
                  const SizedBox(width: 12),
                  _buildSummaryChip(
                    Icons.timer_outlined,
                    _formatRestTime(exercise.restSeconds),
                    AppColors.orange,
                  ),
                  if (exercise.weight != null) ...[
                    const SizedBox(width: 12),
                    _buildSummaryChip(
                      Icons.monitor_weight_outlined,
                      '${exercise.weight!.toInt()} kg',
                      AppColors.green,
                    ),
                  ],
                ],
              ),
            ),

            // Expanded instructions
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState:
                  isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
              firstChild: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: glassSurface.withOpacity(0.5),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppColors.cyan,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'How to perform',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.cyan,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      exercise.instructions,
                      style: TextStyle(
                        fontSize: 14,
                        color: textSecondary,
                        height: 1.5,
                      ),
                    ),
                    if (exercise.isUnilateral) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.sync_alt,
                              size: 16,
                              color: AppColors.orange,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'This is a unilateral exercise - perform on each side',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              secondChild: const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(
          delay: Duration(milliseconds: 400 + (index * 50)),
          duration: 300.ms,
        );
  }

  Widget _buildExerciseChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
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
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  String _getRepDisplay(DemoExercise exercise) {
    if (exercise.reps != null) {
      return '${exercise.reps} reps';
    } else if (exercise.holdSeconds != null) {
      return '${exercise.holdSeconds}s hold';
    } else if (exercise.durationSeconds != null) {
      return '${exercise.durationSeconds}s';
    }
    return '8-12 reps';
  }

  String _formatRestTime(int seconds) {
    if (seconds >= 60) {
      final mins = seconds ~/ 60;
      final secs = seconds % 60;
      if (secs > 0) return '${mins}m ${secs}s rest';
      return '${mins}m rest';
    }
    return '${seconds}s rest';
  }

  void _startWorkout() {
    HapticFeedback.mediumImpact();
    _trackConversion('start_workout');

    // Prepare exercises list for active workout
    List<Map<String, dynamic>> exercisesList;
    if (_personalizedWorkout != null) {
      exercisesList = _exercises.map((e) => e as Map<String, dynamic>).toList();
    } else if (_currentWorkout != null) {
      exercisesList = _currentWorkout!.exercises.map((e) => {
        'name': e.name,
        'sets': e.sets,
        'reps': e.reps ?? 12,
        'rest_seconds': e.restSeconds,
        'muscle_group': e.muscleGroup,
        'equipment': e.equipment,
        'gif_url': e.gifUrl,
        'notes': e.instructions,
      }).toList();
    } else {
      return;
    }

    // Navigate to demo active workout
    context.push('/demo-active-workout', extra: {
      'workout': _workout ?? {
        'name': _workoutName,
        'description': _workoutDescription,
        'type': _workoutType,
        'difficulty': _difficulty,
        'duration_minutes': _durationMinutes,
      },
      'exercises': exercisesList,
    });
  }

  Widget _buildCtaSection(bool isDark) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        children: [
          // START WORKOUT BUTTON - Primary CTA
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _startWorkout,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: AppColors.success.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_arrow_rounded, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'Start Workout',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 500.ms).scale(begin: const Offset(0.95, 0.95)),

          const SizedBox(height: 24),

          // Sign up prompt box
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: elevatedColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.cyan.withOpacity(0.2),
                        AppColors.teal.withOpacity(0.2),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: AppColors.cyan,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Get AI-Personalized Workouts',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign up to get workouts tailored to your goals, fitness level, and available equipment.',
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Get Personalized Workouts button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _navigateToSignUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.cyan,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Get Personalized Workouts',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Try Another Sample button
          TextButton.icon(
            onPressed: _tryAnotherSample,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Try Another Sample Workout'),
            style: TextButton.styleFrom(
              foregroundColor: textSecondary,
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms, duration: 400.ms);
  }
}
