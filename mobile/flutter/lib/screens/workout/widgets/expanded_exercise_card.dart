import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/default_weights.dart';
import '../../../core/constants/workout_design.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/providers/week_comparison_provider.dart';
import '../../../core/providers/favorites_provider.dart';
import '../../../core/providers/staples_provider.dart';
import '../../../core/providers/exercise_queue_provider.dart';
import '../../../data/models/exercise.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/glass_sheet.dart';
import 'exercise_options_info_sheet.dart';

part 'expanded_exercise_card_ui_1.dart';
part 'expanded_exercise_card_ui_2.dart';


/// Expanded exercise card that shows the SET/LBS/REP table inline
/// Collapsible by default - shows sets/reps summary when collapsed
/// Tapping opens the full exercise detail screen with autoplay video
class ExpandedExerciseCard extends ConsumerStatefulWidget {
  final WorkoutExercise exercise;
  final int index;
  final String workoutId;
  final VoidCallback? onTap;
  final VoidCallback? onSwap;
  final VoidCallback? onLinkSuperset;
  final VoidCallback? onRemove;
  final VoidCallback? onViewHistory;
  final VoidCallback? onNeverRecommend;
  final bool initiallyExpanded;
  /// Index for ReorderableListView - if provided, drag handle enables reordering
  final int? reorderIndex;
  /// Whether to show the internal drag handle (default: true)
  /// Set to false when using external drag handle to avoid gesture conflicts
  final bool showDragHandle;
  /// Whether this card is a drop target for superset creation (shows highlight)
  final bool isDropTarget;
  /// Whether this card is pending superset pairing (shows highlight)
  final bool isPendingPair;
  /// Callback when a dragged exercise is dropped on this card to create superset
  final void Function(int draggedIndex)? onSupersetDrop;

  const ExpandedExerciseCard({
    super.key,
    required this.exercise,
    required this.index,
    required this.workoutId,
    this.onTap,
    this.onSwap,
    this.onLinkSuperset,
    this.onRemove,
    this.onViewHistory,
    this.onNeverRecommend,
    this.initiallyExpanded = false,
    this.reorderIndex,
    this.showDragHandle = true,
    this.isDropTarget = false,
    this.isPendingPair = false,
    this.onSupersetDrop,
  });

  @override
  ConsumerState<ExpandedExerciseCard> createState() => _ExpandedExerciseCardState();
}

class _ExpandedExerciseCardState extends ConsumerState<ExpandedExerciseCard> {
  String? _imageUrl;
  bool _isLoadingImage = true;
  late bool _isExpanded;
  bool? _useKgOverride; // Local override for kg/lbs toggle, null = use provider
  static final Map<String, String> _imageCache = {};

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _loadImage();
  }

  /// Toggle between kg and lbs units locally
  void _toggleUnit() {
    setState(() {
      final bool currentUseKg = _useKgOverride ?? ref.read(useKgForWorkoutProvider);
      _useKgOverride = !currentUseKg;
    });
  }

  Future<void> _loadImage() async {
    final exerciseName = widget.exercise.name;
    if (exerciseName.isEmpty || exerciseName == 'Exercise') {
      setState(() => _isLoadingImage = false);
      return;
    }

    final cacheKey = exerciseName.toLowerCase();

    // Check API-resolved cache first (populated only by the authoritative
    // /exercise-images/ endpoint, not by potentially wrong gif_url values)
    if (_imageCache.containsKey(cacheKey)) {
      setState(() {
        _imageUrl = _imageCache[cacheKey];
        _isLoadingImage = false;
      });
      return;
    }

    // Fetch from the authoritative /exercise-images/ API (returns S3 illustration)
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get(
        '/exercise-images/${Uri.encodeComponent(exerciseName)}',
      );

      if (response.statusCode == 200 && response.data != null) {
        final url = response.data['url'] as String?;
        if (url != null && mounted) {
          _imageCache[cacheKey] = url;
          setState(() {
            _imageUrl = url;
            _isLoadingImage = false;
          });
          return;
        }
      }
    } catch (e) {
      // Image not found from API
    }

    // Fall back to gifUrl from exercise data if API failed
    final exerciseGifUrl = widget.exercise.gifUrl;
    if (exerciseGifUrl != null && exerciseGifUrl.isNotEmpty && mounted) {
      setState(() {
        _imageUrl = exerciseGifUrl;
        _isLoadingImage = false;
      });
      return;
    }

    if (mounted) {
      setState(() => _isLoadingImage = false);
    }
  }

  String _getRepRange() {
    if (widget.exercise.reps != null) {
      final reps = widget.exercise.reps!;
      if (reps <= 6) return '${reps - 1}-${reps + 1}';
      if (reps <= 12) return '${reps - 2}-${reps + 2}';
      return '${reps - 3}-${reps + 3}';
    } else if (widget.exercise.durationSeconds != null) {
      return '${widget.exercise.durationSeconds}s';
    }
    return '8-12';
  }

  String _formatRestTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    if (mins > 0 && secs > 0) return '${mins}m ${secs}s';
    if (mins > 0) return '${mins}m';
    return '${secs}s';
  }

  /// Get the total number of sets (including warmup) to match active workout screen
  /// Uses AI setTargets length if available, otherwise fallback to exercise.sets
  int _getTotalSetCount() {
    final exercise = widget.exercise;

    // If AI setTargets exist, use total count (including warmup) to match active workout
    if (exercise.hasSetTargets && exercise.setTargets!.isNotEmpty) {
      return exercise.setTargets!.length;
    }

    // Fallback: use exercise.sets
    return exercise.sets ?? 3;
  }

  /// Calculate RIR algorithmically based on set type and position
  /// Based on RP Strength methodology: progressive intensity through sets
  /// Sources:
  /// - PMC: https://pmc.ncbi.nlm.nih.gov/articles/PMC4961270/
  /// - RP Strength: https://rpstrength.com/blogs/articles/progressing-for-hypertrophy
  int? _calculateRir(String setType, int setIndex, int totalWorkingSets) {
    final type = setType.toLowerCase();

    // Warmup sets don't have RIR - they're for preparation, not stimulation
    if (type == 'warmup') return null;

    // Failure/AMRAP sets are always RIR 0 (maximum effort)
    if (type == 'failure' || type == 'amrap') return 0;

    // Drop sets maintain high intensity (RIR 1)
    if (type == 'drop') return 1;

    // Working sets: progressive RIR decrease (3 → 2 → 1)
    if (totalWorkingSets <= 1) return 2;  // Single set = moderate intensity
    if (totalWorkingSets == 2) {
      return setIndex == 0 ? 3 : 1;  // First=3, Last=1
    }
    // 3+ working sets: distribute RIR across thirds (3→2→1)
    final position = setIndex / (totalWorkingSets - 1);  // 0.0 to 1.0
    if (position < 0.33) return 3;      // First third: conservative
    if (position < 0.67) return 2;      // Middle third: moderate
    return 1;                            // Last third: approaching failure
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercise;
    final totalSets = exercise.sets ?? 3;
    final repRange = _getRepRange();
    final restSeconds = exercise.restSeconds ?? 90;

    // Get user's weight unit preference (kg or lbs), with local override
    final bool useKg = _useKgOverride ?? ref.watch(useKgForWorkoutProvider);

    // Theme-aware colors
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    // Use dynamic accent color from provider
    final accentColor = ref.colors(context).accent;

    // Build the main card content
    final cardContent = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cardBorder.withOpacity(0.3),
        ),
      ),
      child: Material(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Image + Exercise Name + Actions (TAPPABLE)
            _buildHeader(context, exercise, glassSurface, textMuted, accentColor),

            // Collapsed summary - shows sets/reps when collapsed
            if (!_isExpanded)
              _buildCollapsedSummary(totalSets, repRange, restSeconds, glassSurface, cardBorder, accentColor),

            // Expandable section
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Column(
                children: [
                  // Divider
                  Divider(
                    color: cardBorder.withOpacity(0.3),
                    height: 1,
                  ),

                  // Rest Timer Row
                  _buildRestTimerRow(restSeconds, textSecondary, textMuted, accentColor),

                  // Divider
                  Divider(
                    color: cardBorder.withOpacity(0.3),
                    height: 1,
                  ),

                  // Set Table Header
                  _buildTableHeader(glassSurface, textMuted, accentColor),

                  // Set Rows - use AI setTargets if available
                  ..._buildSetRows(
                    exercise: exercise,
                    useKg: useKg,
                    cardBorder: cardBorder,
                    glassSurface: glassSurface,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    textSecondary: textSecondary,
                    accentColor: accentColor,
                  ),

                  const SizedBox(height: 8),
                ],
              ),
              secondChild: const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );

    // If reorderIndex is provided, add a drag strip on the left side
    if (widget.reorderIndex != null && widget.showDragHandle) {
      // Determine if we should show highlight border
      final showHighlight = widget.isDropTarget || widget.isPendingPair;

      // Use Stack to overlay the drag strip on the left side of the card
      // This avoids IntrinsicHeight issues with AnimatedCrossFade
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: DragTarget<int>(
          onWillAcceptWithDetails: (details) {
            final willAccept = details.data != widget.index;
            debugPrint('🎯 [DragTarget] onWillAccept: dragged=${details.data}, target=${widget.index}, willAccept=$willAccept, hasCallback=${widget.onSupersetDrop != null}');
            return willAccept;
          },
          onAcceptWithDetails: (details) {
            debugPrint('🎯 [DragTarget] onAccept: dragged=${details.data}, target=${widget.index}, exercise=${widget.exercise.name}');
            widget.onSupersetDrop?.call(details.data);
          },
          builder: (context, candidateData, rejectedData) {
            final isCurrentDropTarget = candidateData.isNotEmpty;
            final shouldHighlight = showHighlight || isCurrentDropTarget;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: shouldHighlight
                    ? Border.all(color: accentColor, width: 2.5)
                    : null,
              ),
              child: Stack(
                children: [
                  // Main card content - shifted right to make room for drag strip
                  // Long-press on card body to drag for superset creation (only if not already in superset)
                  Padding(
                    padding: const EdgeInsets.only(left: 28),
                    child: _buildCardBodyWithOptionalDrag(
                      canDragForSuperset: !widget.exercise.isInSuperset,
                      shouldHighlight: shouldHighlight,
                      exercise: exercise,
                      totalSets: totalSets,
                      repRange: repRange,
                      restSeconds: restSeconds,
                      useKg: useKg,
                      elevatedColor: elevatedColor,
                      cardBorder: cardBorder,
                      glassSurface: glassSurface,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      textSecondary: textSecondary,
                      accentColor: accentColor,
                    ),
                  ),
                  // Drag strip - positioned on the left, stretches to full height
                  // Both short drag and long-press drag trigger reordering
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 28,
                    child: ReorderableDelayedDragStartListener(
                      index: widget.reorderIndex!,
                      child: ReorderableDragStartListener(
                        index: widget.reorderIndex!,
                        child: Container(
                          decoration: BoxDecoration(
                            color: glassSurface.withOpacity(0.5),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              bottomLeft: Radius.circular(16),
                            ),
                            border: shouldHighlight
                                ? null  // No inner border when highlighted
                                : Border.all(color: cardBorder.withOpacity(0.3)),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.drag_indicator,
                              size: 18,
                              color: textMuted.withOpacity(0.6),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    // No drag strip - just the card with padding
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: cardContent,
    );
  }

  /// Collapsed summary showing sets x reps when card is collapsed
  Widget _buildCollapsedSummary(int totalSets, String repRange, int restSeconds, Color glassSurface, Color cardBorder, Color accentColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayAccent = isDark ? accentColor : _darkenColor(accentColor);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: glassSurface.withOpacity(0.3),
        border: Border(
          top: BorderSide(
            color: cardBorder.withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          // Sets info - total sets (including warmup) to match active workout
          _buildSummaryChip(
            Icons.repeat,
            '${_getTotalSetCount()} sets',
            accentColor,
          ),
          const SizedBox(width: 12),
          // Reps info
          _buildSummaryChip(
            Icons.fitness_center,
            '$repRange reps',
            accentColor,
          ),
          const SizedBox(width: 12),
          // Rest time
          _buildSummaryChip(
            Icons.timer_outlined,
            _formatRestTime(restSeconds),
            AppColors.orange,
          ),
          const Spacer(),
          // Expand button
          GestureDetector(
            onTap: () => setState(() => _isExpanded = true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: isDark ? 0.1 : 0.15),
                borderRadius: BorderRadius.circular(8),
                border: isDark ? null : Border.all(color: displayAccent.withOpacity(0.3), width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Details',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: displayAccent,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: displayAccent,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestTimerRow(int seconds, Color textSecondary, Color textMuted, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          // Rest timer info - wrapped in Flexible to prevent overflow
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 16,
                  color: accentColor,
                ),
                const SizedBox(width: 6),
                Text(
                  'Rest Timer:',
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _formatRestTime(seconds),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // kg/lb toggle button
          _buildUnitToggle(accentColor),
          const SizedBox(width: 8),
          // Collapse button
          GestureDetector(
            onTap: () => setState(() => _isExpanded = false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: textMuted.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Collapse',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: textMuted,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.keyboard_arrow_up,
                    size: 14,
                    color: textMuted,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Darken a color for better visibility on light backgrounds
  Color _darkenColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness * 0.7).clamp(0.0, 1.0)).toColor();
  }

  String _shortenMuscle(String muscle) {
    // Take first muscle group if there are multiple
    if (muscle.contains(',')) {
      muscle = muscle.split(',').first.trim();
    }
    // Extract just the main muscle name from parentheses format
    // e.g., "Chest (Pectoralis Major)" -> "Chest"
    final match = RegExp(r'^([^(]+)').firstMatch(muscle);
    if (match != null) {
      return match.group(1)!.trim();
    }
    // Limit length
    return muscle.length > 15 ? '${muscle.substring(0, 15)}...' : muscle;
  }

  String _shortenEquipment(String equipment) {
    // Normalize and shorten equipment names
    final lower = equipment.toLowerCase();
    if (lower.contains('bodyweight') || lower.contains('none')) {
      return 'Bodyweight';
    }
    if (lower.contains('dumbbell')) return 'Dumbbells';
    if (lower.contains('barbell')) return 'Barbell';
    if (lower.contains('cable')) return 'Cable';
    if (lower.contains('machine')) return 'Machine';
    if (lower.contains('kettlebell')) return 'Kettlebell';
    if (lower.contains('stability')) return 'Stability Ball';
    // Convert snake_case identifiers to Title Case (e.g., "leg_press" → "Leg Press")
    if (equipment.contains('_')) {
      final formatted = equipment.split('_').map((w) =>
        w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}'
      ).join(' ');
      return formatted.length > 14 ? '${formatted.substring(0, 14)}...' : formatted;
    }
    // Limit length
    return equipment.length > 12 ? '${equipment.substring(0, 12)}...' : equipment;
  }

  /// Check if exercise uses a barbell (for weight note display)
  bool _isBarbellExercise() {
    final equipment = widget.exercise.equipment?.toLowerCase() ?? '';
    final name = widget.exercise.name.toLowerCase();
    return equipment.contains('barbell') ||
           name.contains('barbell') ||
           name.contains(' bb ') ||
           name.startsWith('bb ');
  }

  void _showBreathingGuidance(BuildContext context) {
    final breathingPattern = _getBreathingPattern();

    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title with icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.air,
                    color: AppColors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Breathing Guide',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.exercise.name,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Breathing pattern
            _buildBreathingStep(
              icon: Icons.arrow_downward_rounded,
              title: breathingPattern['inhale']!['phase']!,
              description: breathingPattern['inhale']!['action']!,
              color: ref.colors(context).accent,
            ),
            const SizedBox(height: 16),
            _buildBreathingStep(
              icon: Icons.arrow_upward_rounded,
              title: breathingPattern['exhale']!['phase']!,
              description: breathingPattern['exhale']!['action']!,
              color: AppColors.orange,
            ),

            const SizedBox(height: 24),

            // Pro tip
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.glassSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: AppColors.yellow,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      breathingPattern['tip']!['text']!,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
      ),
    );
  }

  Map<String, Map<String, String>> _getBreathingPattern() {
    final exerciseName = widget.exercise.name.toLowerCase();
    final category = (widget.exercise.muscleGroup ?? '').toLowerCase();

    // Pushing exercises (chest, shoulders, triceps)
    if (_isPushExercise(exerciseName, category)) {
      return {
        'inhale': {
          'phase': 'Inhale (Lowering)',
          'action': 'Breathe in as you lower the weight or bring it toward your body.',
        },
        'exhale': {
          'phase': 'Exhale (Pushing)',
          'action': 'Breathe out forcefully as you push the weight away from your body.',
        },
        'tip': {
          'text': 'Keep your core tight and maintain steady breathing throughout the movement.',
        },
      };
    }

    // Pulling exercises (back, biceps)
    if (_isPullExercise(exerciseName, category)) {
      return {
        'inhale': {
          'phase': 'Inhale (Extending)',
          'action': 'Breathe in as you extend your arms or lower the weight.',
        },
        'exhale': {
          'phase': 'Exhale (Pulling)',
          'action': 'Breathe out as you pull the weight toward your body.',
        },
        'tip': {
          'text': 'Focus on squeezing your back muscles at peak contraction while exhaling.',
        },
      };
    }

    // Squat and leg press movements
    if (_isSquatMovement(exerciseName)) {
      return {
        'inhale': {
          'phase': 'Inhale (Descending)',
          'action': 'Take a deep breath before descending and hold as you lower.',
        },
        'exhale': {
          'phase': 'Exhale (Rising)',
          'action': 'Exhale forcefully as you drive up through your heels.',
        },
        'tip': {
          'text': 'Use the Valsalva maneuver for heavy lifts: brace your core with a deep breath.',
        },
      };
    }

    // Deadlift and hip hinge movements
    if (_isHingeMovement(exerciseName)) {
      return {
        'inhale': {
          'phase': 'Inhale (Setup/Lowering)',
          'action': 'Breathe in deeply at the top, brace your core before descending.',
        },
        'exhale': {
          'phase': 'Exhale (Lifting)',
          'action': 'Exhale once you pass the sticking point while driving hips forward.',
        },
        'tip': {
          'text': 'Keep your spine neutral and core braced throughout the entire lift.',
        },
      };
    }

    // Core/Ab exercises
    if (_isCoreExercise(exerciseName, category)) {
      return {
        'inhale': {
          'phase': 'Inhale (Relaxing)',
          'action': 'Breathe in during the eccentric phase or rest position.',
        },
        'exhale': {
          'phase': 'Exhale (Contracting)',
          'action': 'Breathe out as you contract your abs and crunch or lift.',
        },
        'tip': {
          'text': 'Focus on drawing your belly button toward your spine as you exhale.',
        },
      };
    }

    // Cardio and dynamic movements
    if (_isCardioMovement(exerciseName)) {
      return {
        'inhale': {
          'phase': 'Rhythmic Breathing',
          'action': 'Breathe in through your nose for 2-3 counts.',
        },
        'exhale': {
          'phase': 'Controlled Exhale',
          'action': 'Breathe out through your mouth for 2-3 counts.',
        },
        'tip': {
          'text': 'Find a breathing rhythm that matches your movement pace.',
        },
      };
    }

    // Default pattern for general resistance training
    return {
      'inhale': {
        'phase': 'Inhale (Eccentric)',
        'action': 'Breathe in during the lowering or stretching phase.',
      },
      'exhale': {
        'phase': 'Exhale (Concentric)',
        'action': 'Breathe out during the lifting or contracting phase.',
      },
      'tip': {
        'text': 'Never hold your breath. Maintain controlled breathing throughout.',
      },
    };
  }

  bool _isPushExercise(String name, String category) {
    return name.contains('press') ||
        name.contains('push') ||
        name.contains('fly') ||
        name.contains('dip') ||
        name.contains('extension') ||
        category.contains('chest') ||
        category.contains('shoulder') ||
        category.contains('tricep');
  }

  bool _isPullExercise(String name, String category) {
    return name.contains('row') ||
        name.contains('pull') ||
        name.contains('curl') ||
        name.contains('lat') ||
        category.contains('back') ||
        category.contains('bicep');
  }

  bool _isSquatMovement(String name) {
    return name.contains('squat') ||
        name.contains('leg press') ||
        name.contains('lunge') ||
        name.contains('split squat');
  }

  bool _isHingeMovement(String name) {
    return name.contains('deadlift') ||
        name.contains('rdl') ||
        name.contains('hip thrust') ||
        name.contains('good morning') ||
        name.contains('romanian');
  }

  bool _isCoreExercise(String name, String category) {
    return name.contains('crunch') ||
        name.contains('plank') ||
        name.contains('sit-up') ||
        name.contains('ab ') ||
        name.contains('core') ||
        name.contains('twist') ||
        category.contains('core') ||
        category.contains('abs');
  }

  bool _isCardioMovement(String name) {
    return name.contains('jump') ||
        name.contains('burpee') ||
        name.contains('mountain climber') ||
        name.contains('running') ||
        name.contains('sprint') ||
        name.contains('cardio');
  }

  /// Get color for set type (matching active workout set_row.dart)
  Color _getSetTypeColor(String setType, Color accentColor) {
    switch (setType.toLowerCase()) {
      case 'warmup':
        return AppColors.orange;
      case 'drop':
        return accentColor;
      case 'failure':
      case 'amrap':
        return Colors.red;
      default:
        return accentColor; // working
    }
  }
}
