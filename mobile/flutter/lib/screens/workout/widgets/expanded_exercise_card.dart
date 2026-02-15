import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
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
      final bool currentUseKg = _useKgOverride ?? ref.read(useKgProvider);
      _useKgOverride = !currentUseKg;
    });
  }

  Future<void> _loadImage() async {
    final exerciseName = widget.exercise.name;
    if (exerciseName.isEmpty || exerciseName == 'Exercise') {
      setState(() => _isLoadingImage = false);
      return;
    }

    // First check if exercise already has a gifUrl from the database
    final exerciseGifUrl = widget.exercise.gifUrl;
    if (exerciseGifUrl != null && exerciseGifUrl.isNotEmpty) {
      final cacheKey = exerciseName.toLowerCase();
      _imageCache[cacheKey] = exerciseGifUrl;
      setState(() {
        _imageUrl = exerciseGifUrl;
        _isLoadingImage = false;
      });
      return;
    }

    // Fall back to cache
    final cacheKey = exerciseName.toLowerCase();
    if (_imageCache.containsKey(cacheKey)) {
      setState(() {
        _imageUrl = _imageCache[cacheKey];
        _isLoadingImage = false;
      });
      return;
    }

    // Last resort: fetch from API
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
      // Image not found
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

  /// Build set rows from AI setTargets or fallback to legacy format
  List<Widget> _buildSetRows({
    required WorkoutExercise exercise,
    required bool useKg,
    required Color cardBorder,
    required Color glassSurface,
    required Color textPrimary,
    required Color textMuted,
    required Color textSecondary,
    required Color accentColor,
  }) {
    // Use AI-generated setTargets if available
    if (exercise.hasSetTargets && exercise.setTargets!.isNotEmpty) {
      int workingSetNumber = 0;
      final totalWorkingSets = exercise.setTargets!
          .where((t) => t.setType.toLowerCase() == 'working')
          .length;

      return exercise.setTargets!.map((target) {
        // For working sets, track the number (1, 2, 3...)
        String setLabel;
        int currentWorkingIndex = 0;
        if (target.setType.toLowerCase() == 'working') {
          currentWorkingIndex = workingSetNumber;
          workingSetNumber++;
          setLabel = '$workingSetNumber';
        } else {
          setLabel = target.setTypeLabel; // W, D, F, A
        }

        // Use AI RIR if available, otherwise calculate algorithmically
        final calculatedRir = target.targetRir ??
            _calculateRir(target.setType, currentWorkingIndex, totalWorkingSets);

        return _buildSetRow(
          setLabel: setLabel,
          isWarmup: target.isWarmup,
          setType: target.setType,
          weightKg: target.targetWeightKg,
          targetReps: target.targetReps,
          targetRir: calculatedRir,
          useKg: useKg,
          cardBorder: cardBorder,
          glassSurface: glassSurface,
          textPrimary: textPrimary,
          textMuted: textMuted,
          textSecondary: textSecondary,
          accentColor: accentColor,
        );
      }).toList();
    }

    // Fallback to legacy format (hardcoded 2 warmups + working sets)
    final totalSets = exercise.sets ?? 3;
    final warmupSets = 2;
    final defaultReps = exercise.reps ?? 10;

    return [
      ...List.generate(warmupSets, (i) => _buildSetRow(
        setLabel: 'W',
        isWarmup: true,
        setType: 'warmup',
        weightKg: null,
        targetReps: defaultReps,
        targetRir: null, // Warmups don't have RIR
        useKg: useKg,
        cardBorder: cardBorder,
        glassSurface: glassSurface,
        textPrimary: textPrimary,
        textMuted: textMuted,
        textSecondary: textSecondary,
        accentColor: accentColor,
      )),
      ...List.generate(totalSets, (i) => _buildSetRow(
        setLabel: '${i + 1}',
        isWarmup: false,
        setType: 'working',
        weightKg: exercise.weight,
        targetReps: defaultReps,
        targetRir: _calculateRir('working', i, totalSets), // Algorithmic RIR
        useKg: useKg,
        cardBorder: cardBorder,
        glassSurface: glassSurface,
        textPrimary: textPrimary,
        textMuted: textMuted,
        textSecondary: textSecondary,
        accentColor: accentColor,
      )),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercise;
    final totalSets = exercise.sets ?? 3;
    final repRange = _getRepRange();
    final restSeconds = exercise.restSeconds ?? 90;

    // Get user's weight unit preference (kg or lbs), with local override
    final bool useKg = _useKgOverride ?? ref.watch(useKgProvider);

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

  /// Build the card body, optionally wrapped with LongPressDraggable for superset creation
  Widget _buildCardBodyWithOptionalDrag({
    required bool canDragForSuperset,
    required bool shouldHighlight,
    required WorkoutExercise exercise,
    required int totalSets,
    required String repRange,
    required int restSeconds,
    required bool useKg,
    required Color elevatedColor,
    required Color cardBorder,
    required Color glassSurface,
    required Color textPrimary,
    required Color textMuted,
    required Color textSecondary,
    required Color accentColor,
  }) {
    // The card content that's always shown
    Widget cardBody = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        border: shouldHighlight
            ? null  // No inner border when highlighted
            : Border.all(color: cardBorder.withOpacity(0.3)),
      ),
      child: Material(
        color: elevatedColor,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context, exercise, glassSurface, textMuted, accentColor),
            if (!_isExpanded)
              _buildCollapsedSummary(totalSets, repRange, restSeconds, glassSurface, cardBorder, accentColor),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: _isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
              firstChild: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Divider(color: cardBorder.withOpacity(0.3), height: 1),
                  _buildRestTimerRow(restSeconds, textSecondary, textMuted, accentColor),
                  Divider(color: cardBorder.withOpacity(0.3), height: 1),
                  _buildTableHeader(glassSurface, textMuted, accentColor),
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

    // If already in superset, don't allow dragging for superset creation
    if (!canDragForSuperset) {
      return cardBody;
    }

    // Wrap with LongPressDraggable for superset creation
    return LongPressDraggable<int>(
      data: widget.index,
      delay: const Duration(milliseconds: 300),
      feedback: Material(
        elevation: 12,
        borderRadius: BorderRadius.circular(16),
        color: Colors.transparent,
        child: SizedBox(
          width: MediaQuery.of(context).size.width - 64,
          child: Opacity(
            opacity: 0.9,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: accentColor, width: 2),
              ),
              child: Material(
                color: elevatedColor,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(context, exercise, glassSurface, textMuted, accentColor),
                    _buildCollapsedSummary(totalSets, repRange, restSeconds, glassSurface, cardBorder, accentColor),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            border: Border.all(color: cardBorder.withOpacity(0.3)),
          ),
          child: Material(
            color: elevatedColor,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(context, exercise, glassSurface, textMuted, accentColor),
                if (!_isExpanded)
                  _buildCollapsedSummary(totalSets, repRange, restSeconds, glassSurface, cardBorder, accentColor),
              ],
            ),
          ),
        ),
      ),
      onDragStarted: () => HapticFeedback.mediumImpact(),
      child: cardBody,
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

  Widget _buildSummaryChip(IconData icon, String text, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayColor = isDark ? color : _darkenColor(color);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: displayColor),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: displayColor,
          ),
        ),
      ],
    );
  }

  /// Build kg/lb toggle button
  Widget _buildUnitToggle(Color accentColor) {
    final bool useKg = _useKgOverride ?? ref.read(useKgProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayAccent = isDark ? accentColor : _darkenColor(accentColor);

    return GestureDetector(
      onTap: () {
        HapticService.light();
        _toggleUnit();
      },
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
            Icon(
              Icons.swap_horiz,
              size: 14,
              color: displayAccent,
            ),
            const SizedBox(width: 4),
            Text(
              useKg ? 'kg' : 'lbs',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: displayAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WorkoutExercise exercise, Color glassSurface, Color textMuted, Color accentColor) {
    return InkWell(
      onTap: () {
        debugPrint('🎯 [ExerciseCard] Header tapped: ${widget.exercise.name}');
        widget.onTap?.call();
      },
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Note: Drag handle is now a separate strip on the left side of the card
            // when reorderIndex is provided (see build method)
            // Exercise Image
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: glassSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.hardEdge,
              child: _buildImage(glassSurface, textMuted, accentColor),
            ),
            const SizedBox(width: 12),

            // Exercise Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          exercise.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // NEW badge for exercises new this week
                      Consumer(
                        builder: (context, ref, _) {
                          final isNew = ref.watch(isExerciseNewThisWeekProvider(exercise.name));
                          if (!isNew) return const SizedBox.shrink();
                          final isDark = Theme.of(context).brightness == Brightness.dark;
                          final badgeColor = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
                          final badgeTextColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
                          return Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: badgeColor,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: badgeColor.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.fiber_new,
                                  size: 12,
                                  color: badgeTextColor,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'NEW',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: badgeTextColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Exercise details from library
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (exercise.muscleGroup != null || exercise.primaryMuscle != null)
                        _buildInfoChip(
                          Icons.fitness_center,
                          _shortenMuscle(exercise.primaryMuscle ?? exercise.muscleGroup ?? ''),
                          accentColor,
                        ),
                      if (exercise.equipment != null && exercise.equipment!.isNotEmpty)
                        _buildInfoChip(
                          Icons.sports_gymnastics,
                          _shortenEquipment(exercise.equipment!),
                          accentColor,
                        ),
                      // Breathing guidance chip
                      _buildBreathingChip(context),
                      // Alternating hands chip (for single-dumbbell exercises)
                      if (exercise.alternatingHands == true)
                        _buildAlternatingHandsChip(),
                      // Preference indicator chips
                      ..._buildPreferenceChips(),
                    ],
                  ),
                ],
              ),
            ),

            // 3-dot menu for exercise actions
            _buildExerciseOptionsMenu(context, accentColor),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(Color glassSurface, Color textMuted, Color accentColor) {
    if (_isLoadingImage) {
      return Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: accentColor,
          ),
        ),
      );
    }

    if (_imageUrl != null) {
      return CachedNetworkImage(
        imageUrl: _imageUrl!,
        fit: BoxFit.cover,
        placeholder: (_, __) => Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: accentColor),
        ),
        errorWidget: (_, __, ___) => _buildPlaceholder(glassSurface, textMuted),
      );
    }

    return _buildPlaceholder(glassSurface, textMuted);
  }

  Widget _buildPlaceholder(Color glassSurface, Color textMuted) {
    return Container(
      color: glassSurface,
      child: Icon(
        Icons.fitness_center,
        color: textMuted,
        size: 28,
      ),
    );
  }

  /// Build the 3-dot menu with all exercise options
  Widget _buildExerciseOptionsMenu(BuildContext context, Color accentColor) {
    final exerciseName = widget.exercise.name;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    // Watch provider states for toggle indicators
    final isFavorite = ref.watch(favoritesProvider).isFavorite(exerciseName);
    final isStaple = ref.watch(staplesProvider).isStaple(exerciseName);
    final isQueued = ref.watch(exerciseQueueProvider).isQueued(exerciseName);

    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.more_vert,
          size: 18,
          color: accentColor,
        ),
      ),
      onSelected: (value) async {
        HapticService.light();

        switch (value) {
          case 'favorite':
            final success = await ref.read(favoritesProvider.notifier)
                .toggleFavorite(exerciseName, exerciseId: widget.exercise.exerciseId);
            if (mounted && success) {
              final newState = ref.read(favoritesProvider).isFavorite(exerciseName);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(
                        newState ? Icons.favorite : Icons.favorite_border,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(newState ? 'Added to favorites' : 'Removed from favorites'),
                    ],
                  ),
                  backgroundColor: AppColors.success,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
            break;

          case 'queue':
            final success = await ref.read(exerciseQueueProvider.notifier)
                .toggleQueue(exerciseName,
                  exerciseId: widget.exercise.exerciseId,
                  targetMuscleGroup: widget.exercise.muscleGroup,
                );
            if (mounted && success) {
              final newState = ref.read(exerciseQueueProvider).isQueued(exerciseName);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(
                        newState ? Icons.playlist_add_check : Icons.playlist_add,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(newState ? 'Queued for next workout' : 'Removed from queue'),
                    ],
                  ),
                  backgroundColor: AppColors.cyan,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
            break;

          case 'staple':
            final success = await ref.read(staplesProvider.notifier)
                .toggleStaple(exerciseName,
                  libraryId: widget.exercise.libraryId,
                  muscleGroup: widget.exercise.muscleGroup,
                );
            if (mounted && success) {
              final newState = ref.read(staplesProvider).isStaple(exerciseName);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(
                        newState ? Icons.push_pin : Icons.push_pin_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(newState
                        ? 'Marked as staple - updating workout...'
                        : 'Removed from staples'),
                    ],
                  ),
                  backgroundColor: AppColors.purple,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
            break;

          case 'history':
            widget.onViewHistory?.call();
            break;

          case 'swap':
            widget.onSwap?.call();
            break;

          case 'superset':
            widget.onLinkSuperset?.call();
            break;

          case 'remove':
            widget.onRemove?.call();
            break;

          case 'never_recommend':
            widget.onNeverRecommend?.call();
            break;

          case 'info':
            showExerciseOptionsInfoSheet(context: context);
            break;
        }
      },
      itemBuilder: (ctx) => [
        // === TOGGLE OPTIONS ===

        // Favorite toggle
        PopupMenuItem(
          value: 'favorite',
          child: Row(
            children: [
              Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                size: 20,
                color: isFavorite ? AppColors.error : textPrimary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
                  style: TextStyle(
                    color: isFavorite ? AppColors.error : textPrimary,
                  ),
                ),
              ),
              if (isFavorite)
                Icon(Icons.check, size: 16, color: AppColors.error),
            ],
          ),
        ),

        // Queue toggle (Repeat Next Time)
        PopupMenuItem(
          value: 'queue',
          child: Row(
            children: [
              Icon(
                isQueued ? Icons.playlist_add_check : Icons.playlist_add,
                size: 20,
                color: isQueued ? AppColors.cyan : textPrimary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isQueued ? 'Remove from Queue' : 'Repeat Next Time',
                  style: TextStyle(
                    color: isQueued ? AppColors.cyan : textPrimary,
                  ),
                ),
              ),
              if (isQueued)
                Icon(Icons.check, size: 16, color: AppColors.cyan),
            ],
          ),
        ),

        // Staple toggle
        PopupMenuItem(
          value: 'staple',
          child: Row(
            children: [
              Icon(
                isStaple ? Icons.push_pin : Icons.push_pin_outlined,
                size: 20,
                color: isStaple ? AppColors.purple : textPrimary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isStaple ? 'Remove as Staple' : 'Mark as Staple',
                  style: TextStyle(
                    color: isStaple ? AppColors.purple : textPrimary,
                  ),
                ),
              ),
              if (isStaple)
                Icon(Icons.check, size: 16, color: AppColors.purple),
            ],
          ),
        ),

        const PopupMenuDivider(),

        // === ACTION OPTIONS ===

        // View History
        if (widget.onViewHistory != null)
          PopupMenuItem(
            value: 'history',
            child: Row(
              children: [
                Icon(Icons.history_rounded, size: 20, color: textPrimary),
                const SizedBox(width: 12),
                const Text('View History'),
              ],
            ),
          ),

        // Swap Exercise
        if (widget.onSwap != null)
          PopupMenuItem(
            value: 'swap',
            child: Row(
              children: [
                Icon(Icons.swap_horiz, size: 20, color: textPrimary),
                const SizedBox(width: 12),
                const Text('Swap Exercise'),
              ],
            ),
          ),

        // Link as Superset
        if (widget.onLinkSuperset != null)
          PopupMenuItem(
            value: 'superset',
            child: Row(
              children: [
                Icon(Icons.link, size: 20, color: textPrimary),
                const SizedBox(width: 12),
                const Text('Link as Superset'),
              ],
            ),
          ),

        const PopupMenuDivider(),

        // === DESTRUCTIVE OPTIONS ===

        // Remove from Workout
        if (widget.onRemove != null)
          PopupMenuItem(
            value: 'remove',
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                const SizedBox(width: 12),
                Text(
                  'Remove from Workout',
                  style: TextStyle(color: AppColors.error),
                ),
              ],
            ),
          ),

        // Never Recommend
        if (widget.onNeverRecommend != null)
          PopupMenuItem(
            value: 'never_recommend',
            child: Row(
              children: [
                Icon(Icons.block_rounded, size: 20, color: AppColors.error),
                const SizedBox(width: 12),
                Text(
                  'Never Recommend',
                  style: TextStyle(color: AppColors.error),
                ),
              ],
            ),
          ),

        const PopupMenuDivider(),

        // === INFO ===

        // What do these mean?
        PopupMenuItem(
          value: 'info',
          child: Row(
            children: [
              Icon(Icons.help_outline, size: 20, color: textPrimary),
              const SizedBox(width: 12),
              const Text('What do these mean?'),
            ],
          ),
        ),
      ],
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

  Widget _buildTableHeader(Color glassSurface, Color textMuted, Color accentColor) {
    final isBarbell = _isBarbellExercise();
    final bool useKg = _useKgOverride ?? ref.read(useKgProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: glassSurface.withOpacity(0.5),
          ),
          child: Row(
            children: [
              // SET column
              SizedBox(
                width: 50,
                child: Text(
                  'SET',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: textMuted,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              // LAST column - previous session data
              Expanded(
                flex: 3,
                child: Text(
                  'LAST',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: textMuted,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              // TARGET column - AI recommended weight × reps
              Expanded(
                flex: 3,
                child: Text(
                  'TARGET',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: accentColor.withOpacity(0.9),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Barbell weight note - shown only for barbell exercises
        if (isBarbell)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 12,
                  color: textMuted.withOpacity(0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  'Weight includes ${useKg ? '20kg' : '45lb'} barbell',
                  style: TextStyle(
                    fontSize: 10,
                    color: textMuted.withOpacity(0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Use higher opacity for light mode for better visibility
    final bgOpacity = isDark ? 0.1 : 0.15;
    // Darken colors for light mode for better contrast
    final displayColor = isDark ? color : _darkenColor(color);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(bgOpacity),
        borderRadius: BorderRadius.circular(6),
        border: isDark ? null : Border.all(color: displayColor.withOpacity(0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: displayColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: displayColor,
              fontWeight: FontWeight.w500,
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

  Widget _buildBreathingChip(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgOpacity = isDark ? 0.1 : 0.15;
    final displayColor = isDark ? AppColors.green : _darkenColor(AppColors.green);

    return GestureDetector(
      onTap: () => _showBreathingGuidance(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.green.withOpacity(bgOpacity),
          borderRadius: BorderRadius.circular(6),
          border: isDark ? null : Border.all(color: displayColor.withOpacity(0.3), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.air, size: 12, color: displayColor),
            const SizedBox(width: 4),
            Text(
              'Breathing',
              style: TextStyle(
                fontSize: 11,
                color: displayColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlternatingHandsChip() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgOpacity = isDark ? 0.1 : 0.15;
    final displayColor = isDark ? AppColors.orange : _darkenColor(AppColors.orange);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.orange.withOpacity(bgOpacity),
        borderRadius: BorderRadius.circular(6),
        border: isDark ? null : Border.all(color: displayColor.withOpacity(0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sync_alt, size: 12, color: displayColor),
          const SizedBox(width: 4),
          Text(
            'Alternating Hands',
            style: TextStyle(
              fontSize: 11,
              color: displayColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Build preference indicator chips (Staple, Favorite, Queued)
  List<Widget> _buildPreferenceChips() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final exerciseName = widget.exercise.name;
    final chips = <Widget>[];

    final isStaple = ref.watch(staplesProvider).isStaple(exerciseName);
    final isFavorite = ref.watch(favoritesProvider).isFavorite(exerciseName);
    final isQueued = ref.watch(exerciseQueueProvider).isQueued(exerciseName);

    if (isStaple) {
      final purple = isDark ? AppColors.purple : _darkenColor(AppColors.purple);
      final bgOpacity = isDark ? 0.1 : 0.15;
      chips.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.purple.withOpacity(bgOpacity),
          borderRadius: BorderRadius.circular(6),
          border: isDark ? null : Border.all(color: purple.withOpacity(0.3), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.push_pin, size: 12, color: purple),
            const SizedBox(width: 4),
            Text('Staple', style: TextStyle(fontSize: 11, color: purple, fontWeight: FontWeight.w500)),
          ],
        ),
      ));
    }

    if (isFavorite) {
      final red = isDark ? AppColors.error : _darkenColor(AppColors.error);
      final bgOpacity = isDark ? 0.1 : 0.15;
      chips.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(bgOpacity),
          borderRadius: BorderRadius.circular(6),
          border: isDark ? null : Border.all(color: red.withOpacity(0.3), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite, size: 12, color: red),
            const SizedBox(width: 4),
            Text('Favorite', style: TextStyle(fontSize: 11, color: red, fontWeight: FontWeight.w500)),
          ],
        ),
      ));
    }

    if (isQueued) {
      final cyan = isDark ? AppColors.cyan : _darkenColor(AppColors.cyan);
      final bgOpacity = isDark ? 0.1 : 0.15;
      chips.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.cyan.withOpacity(bgOpacity),
          borderRadius: BorderRadius.circular(6),
          border: isDark ? null : Border.all(color: cyan.withOpacity(0.3), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.playlist_add_check, size: 12, color: cyan),
            const SizedBox(width: 4),
            Text('Queued', style: TextStyle(fontSize: 11, color: cyan, fontWeight: FontWeight.w500)),
          ],
        ),
      ));
    }

    return chips;
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

  Widget _buildBreathingStep({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
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

  Widget _buildSetRow({
    required String setLabel,
    required bool isWarmup,
    String setType = 'working',
    double? weightKg,
    int? targetReps,
    int? targetRir,
    required bool useKg,
    required Color cardBorder,
    required Color glassSurface,
    required Color textPrimary,
    required Color textMuted,
    required Color textSecondary,
    required Color accentColor,
  }) {
    final setColor = _getSetTypeColor(setType, accentColor);

    // Convert weight to user's preferred unit (matching active workout screen)
    // All weights are stored in kg internally
    double? displayWeight;
    if (weightKg != null && weightKg > 0) {
      displayWeight = useKg ? weightKg : weightKg * 2.20462;
    }

    // Build target display string: weight unit × reps (matching active workout screen)
    // Include unit label so user knows if weight is in kg or lbs
    final unit = useKg ? 'kg' : 'lbs';
    String targetDisplay = '—';
    if (displayWeight != null && displayWeight > 0 && targetReps != null && targetReps > 0) {
      // Check if this is a failure/amrap set
      if (setType.toLowerCase() == 'failure' || setType.toLowerCase() == 'amrap') {
        targetDisplay = '${displayWeight.toStringAsFixed(0)} $unit × AMRAP';
      } else {
        targetDisplay = '${displayWeight.toStringAsFixed(0)} $unit × $targetReps';
      }
    } else if (targetReps != null && targetReps > 0) {
      // Bodyweight exercise - just show reps (no weight/unit needed)
      if (setType.toLowerCase() == 'failure' || setType.toLowerCase() == 'amrap') {
        targetDisplay = 'AMRAP';
      } else {
        targetDisplay = '$targetReps reps';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: cardBorder.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Align to top so text baselines match
        children: [
          // SET column - Set number with type color badge
          // Add top padding to align badge center with text baseline
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: SizedBox(
              width: 50,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: setColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    setLabel,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: setColor,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // LAST column - previous session data (shows "—" for preview)
          Expanded(
            flex: 3,
            child: Text(
              '—',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textMuted,
                height: 1.5, // Match line height with TARGET column
              ),
            ),
          ),

          // TARGET column - AI recommended weight × reps with RIR badge
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  targetDisplay,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: targetDisplay != '—' ? accentColor : textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                // RIR pill (matching active workout screen)
                if (targetRir != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: WorkoutDesign.getRirColor(targetRir),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        WorkoutDesign.getRirLabel(targetRir),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: WorkoutDesign.getRirTextColor(targetRir),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
