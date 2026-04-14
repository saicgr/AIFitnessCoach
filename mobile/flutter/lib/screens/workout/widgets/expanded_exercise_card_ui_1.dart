part of 'expanded_exercise_card.dart';

/// UI builder methods extracted from _ExpandedExerciseCardState
extension _ExpandedExerciseCardStateUI1 on _ExpandedExerciseCardState {

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
    final bool useKg = _useKgOverride ?? ref.read(useKgForWorkoutProvider);
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


  /// 3-dot menu trigger — opens a glass bottom sheet.
  /// The button itself does NOT watch any provider, so taps feel instant
  /// and the card doesn't rebuild when favorite/staple/queue state changes.
  Widget _buildExerciseOptionsMenu(BuildContext context, Color accentColor) {
    return IconButton(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      visualDensity: VisualDensity.compact,
      splashRadius: 20,
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.more_vert, size: 18, color: accentColor),
      ),
      onPressed: () => _showExerciseOptionsSheet(context),
    );
  }

  /// Shows the exercise-actions bottom sheet. Provider-watching is scoped
  /// to a Consumer inside the sheet so only the list items rebuild.
  void _showExerciseOptionsSheet(BuildContext context) {
    HapticService.light();
    final exerciseName = widget.exercise.name;

    showGlassSheet<void>(
      context: context,
      builder: (sheetCtx) => GlassSheet(
        showHandle: true,
        child: Consumer(
          builder: (ctx, sheetRef, _) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
            final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

            // Scoped selectors — rebuild only when THIS exercise's flag flips.
            final isFavorite = sheetRef.watch(favoritesProvider
                .select((s) => s.isFavorite(exerciseName)));
            final isStaple = sheetRef.watch(staplesProvider
                .select((s) => s.isStaple(exerciseName)));
            final isQueued = sheetRef.watch(exerciseQueueProvider
                .select((s) => s.isQueued(exerciseName)));

            return Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header — exercise name
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: Text(
                      exerciseName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Divider(height: 1, color: textMuted.withOpacity(0.15)),

                  // === TOGGLES ===
                  _sheetTile(
                    context: ctx,
                    icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                    iconColor: isFavorite ? AppColors.error : textPrimary,
                    label: isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
                    trailingCheck: isFavorite ? AppColors.error : null,
                    textPrimary: textPrimary,
                    onTap: () => _handleSheetAction(sheetCtx, 'favorite'),
                  ),
                  _sheetTile(
                    context: ctx,
                    icon: isQueued ? Icons.playlist_add_check : Icons.playlist_add,
                    iconColor: isQueued ? AppColors.cyan : textPrimary,
                    label: isQueued ? 'Remove from Queue' : 'Repeat Next Time',
                    trailingCheck: isQueued ? AppColors.cyan : null,
                    textPrimary: textPrimary,
                    onTap: () => _handleSheetAction(sheetCtx, 'queue'),
                  ),
                  _sheetTile(
                    context: ctx,
                    icon: isStaple ? Icons.push_pin : Icons.push_pin_outlined,
                    iconColor: isStaple ? AppColors.purple : textPrimary,
                    label: isStaple ? 'Remove as Staple' : 'Mark as Staple',
                    trailingCheck: isStaple ? AppColors.purple : null,
                    textPrimary: textPrimary,
                    onTap: () => _handleSheetAction(sheetCtx, 'staple'),
                  ),

                  Divider(height: 1, color: textMuted.withOpacity(0.15)),

                  // === ACTIONS ===
                  if (widget.onViewHistory != null)
                    _sheetTile(
                      context: ctx,
                      icon: Icons.history_rounded,
                      iconColor: textPrimary,
                      label: 'View History',
                      textPrimary: textPrimary,
                      onTap: () => _handleSheetAction(sheetCtx, 'history'),
                    ),
                  if (widget.onSwap != null)
                    _sheetTile(
                      context: ctx,
                      icon: Icons.swap_horiz,
                      iconColor: textPrimary,
                      label: 'Swap Exercise',
                      textPrimary: textPrimary,
                      onTap: () => _handleSheetAction(sheetCtx, 'swap'),
                    ),
                  if (widget.onLinkSuperset != null)
                    _sheetTile(
                      context: ctx,
                      icon: Icons.link,
                      iconColor: textPrimary,
                      label: 'Link as Superset',
                      textPrimary: textPrimary,
                      onTap: () => _handleSheetAction(sheetCtx, 'superset'),
                    ),

                  Divider(height: 1, color: textMuted.withOpacity(0.15)),

                  // === DESTRUCTIVE ===
                  if (widget.onRemove != null)
                    _sheetTile(
                      context: ctx,
                      icon: Icons.delete_outline,
                      iconColor: AppColors.error,
                      label: 'Remove from Workout',
                      labelColor: AppColors.error,
                      textPrimary: textPrimary,
                      onTap: () => _handleSheetAction(sheetCtx, 'remove'),
                    ),
                  if (widget.onNeverRecommend != null)
                    _sheetTile(
                      context: ctx,
                      icon: Icons.block_rounded,
                      iconColor: AppColors.error,
                      label: 'Never Recommend',
                      labelColor: AppColors.error,
                      textPrimary: textPrimary,
                      onTap: () => _handleSheetAction(sheetCtx, 'never_recommend'),
                    ),

                  Divider(height: 1, color: textMuted.withOpacity(0.15)),

                  // === INFO ===
                  _sheetTile(
                    context: ctx,
                    icon: Icons.help_outline,
                    iconColor: textMuted,
                    label: 'What do these mean?',
                    labelColor: textMuted,
                    textPrimary: textPrimary,
                    onTap: () => _handleSheetAction(sheetCtx, 'info'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Compact, tappable row used inside the options sheet.
  Widget _sheetTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String label,
    required Color textPrimary,
    Color? labelColor,
    Color? trailingCheck,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: iconColor),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: labelColor ?? textPrimary,
                ),
              ),
            ),
            if (trailingCheck != null)
              Icon(Icons.check_rounded, size: 18, color: trailingCheck),
          ],
        ),
      ),
    );
  }

  /// Dispatch for sheet actions — closes sheet first, then runs the action
  /// on the next frame so the dismiss animation stays smooth.
  Future<void> _handleSheetAction(BuildContext sheetCtx, String value) async {
    HapticService.light();
    Navigator.of(sheetCtx).pop();

    // Let the sheet dismiss animation run one frame before heavier work.
    await Future<void>.delayed(const Duration(milliseconds: 10));
    if (!mounted) return;

    final exerciseName = widget.exercise.name;

    switch (value) {
      case 'favorite':
        final success = await ref.read(favoritesProvider.notifier).toggleFavorite(
              exerciseName,
              exerciseId: widget.exercise.exerciseId,
            );
        if (!mounted || !success) return;
        final newState = ref.read(favoritesProvider).isFavorite(exerciseName);
        _showActionSnackBar(
          icon: newState ? Icons.favorite : Icons.favorite_border,
          text: newState ? 'Added to favorites' : 'Removed from favorites',
          color: AppColors.success,
        );
        break;

      case 'queue':
        final success = await ref.read(exerciseQueueProvider.notifier).toggleQueue(
              exerciseName,
              exerciseId: widget.exercise.exerciseId,
              targetMuscleGroup: widget.exercise.muscleGroup,
            );
        if (!mounted || !success) return;
        final newState = ref.read(exerciseQueueProvider).isQueued(exerciseName);
        _showActionSnackBar(
          icon: newState ? Icons.playlist_add_check : Icons.playlist_add,
          text: newState ? 'Queued for next workout' : 'Removed from queue',
          color: AppColors.cyan,
        );
        break;

      case 'staple':
        final success = await ref.read(staplesProvider.notifier).toggleStaple(
              exerciseName,
              libraryId: widget.exercise.libraryId,
              muscleGroup: widget.exercise.muscleGroup,
            );
        if (!mounted || !success) return;
        final newState = ref.read(staplesProvider).isStaple(exerciseName);
        _showActionSnackBar(
          icon: newState ? Icons.push_pin : Icons.push_pin_outlined,
          text: newState ? 'Marked as staple - updating workout...' : 'Removed from staples',
          color: AppColors.purple,
        );
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
  }

  void _showActionSnackBar({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(text)),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }


  Widget _buildTableHeader(Color glassSurface, Color textMuted, Color accentColor) {
    final isBarbell = _isBarbellExercise();
    final bool useKg = _useKgOverride ?? ref.read(useKgForWorkoutProvider);

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
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
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

}
