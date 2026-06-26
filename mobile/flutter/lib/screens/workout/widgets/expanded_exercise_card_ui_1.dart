part of 'expanded_exercise_card.dart';

/// UI builder methods extracted from _ExpandedExerciseCardState
extension _ExpandedExerciseCardStateUI1 on _ExpandedExerciseCardState {

  /// Build the set list, grouped into a muted, collapsible "Warmup sets"
  /// section above a highlighted "Effective sets" section (Surface 6a).
  ///
  /// A set is a WARMUP when its [setType] is exactly `'warmup'` (the only
  /// warmup literal used by the AI target schema + the legacy fallback).
  /// Everything else — `working`/`failure`/`amrap`/`drop` — is EFFECTIVE.
  ///
  /// All states are handled gracefully:
  ///   • warmup-only            → only the warmup section renders.
  ///   • no-warmup / all-working → only the effective section renders (no
  ///                               empty warmup header).
  ///   • mixed                  → both sections render.
  ///   • single-set             → renders in the correct section, no toggle
  ///                               clutter when there are no warmups.
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
    final descriptors = _buildSetDescriptors(exercise);
    final warmups = descriptors.where((d) => d.isWarmup).toList();
    final effective = descriptors.where((d) => !d.isWarmup).toList();

    Widget rowFor(_SetDescriptor d) => _buildSetRow(
          setLabel: d.label,
          isWarmup: d.isWarmup,
          setType: d.setType,
          weightKg: d.weightKg,
          targetReps: d.targetReps,
          targetRir: d.targetRir,
          useKg: useKg,
          cardBorder: cardBorder,
          glassSurface: glassSurface,
          textPrimary: textPrimary,
          textMuted: textMuted,
          textSecondary: textSecondary,
          accentColor: accentColor,
        );

    final rows = <Widget>[];

    // ── Warmup section (muted, collapsible) — only when warmups exist.
    if (warmups.isNotEmpty) {
      rows.add(_buildSetGroupHeader(
        label: warmups.length == 1 ? 'Warmup set' : 'Warmup sets',
        count: warmups.length,
        color: AppColors.orange,
        textMuted: textMuted,
        glassSurface: glassSurface,
        cardBorder: cardBorder,
        collapsible: true,
        collapsed: _warmupsHidden,
        onToggle: () {
          HapticService.light();
          setState(() => _warmupsHidden = !_warmupsHidden);
        },
      ));
      if (!_warmupsHidden) {
        rows.addAll(warmups.map(rowFor));
      }
    }

    // ── Effective section (highlighted) — render whenever any effective set
    // exists. When there were NO warmups we skip the header entirely so a
    // plain all-working exercise reads exactly like before (no redundant
    // "Effective sets" banner above a single ungrouped list).
    if (effective.isNotEmpty) {
      if (warmups.isNotEmpty) {
        rows.add(_buildSetGroupHeader(
          label: effective.length == 1 ? 'Effective set' : 'Effective sets',
          count: effective.length,
          color: accentColor,
          textMuted: textMuted,
          glassSurface: glassSurface,
          cardBorder: cardBorder,
          collapsible: false,
          highlighted: true,
        ));
      }
      // Tint the effective block with an accent-left-border when grouped, so
      // the user's eye lands on the sets that actually count.
      if (warmups.isNotEmpty) {
        rows.add(
          Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: accentColor.withOpacity(0.6), width: 2),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: effective.map(rowFor).toList(),
            ),
          ),
        );
      } else {
        rows.addAll(effective.map(rowFor));
      }
    }

    return rows;
  }

  /// Flatten an exercise into ordered set descriptors (AI targets if present,
  /// else the legacy 2-warmup + N-working fallback). Working-set numbering
  /// (1, 2, 3…) and algorithmic RIR are computed here so grouping never
  /// reshuffles the labels the user expects.
  List<_SetDescriptor> _buildSetDescriptors(WorkoutExercise exercise) {
    if (exercise.hasSetTargets && exercise.setTargets!.isNotEmpty) {
      int workingSetNumber = 0;
      final totalWorkingSets = exercise.setTargets!
          .where((t) => t.setType.toLowerCase() == 'working')
          .length;

      return exercise.setTargets!.map((target) {
        String setLabel;
        int currentWorkingIndex = 0;
        if (target.setType.toLowerCase() == 'working') {
          currentWorkingIndex = workingSetNumber;
          workingSetNumber++;
          setLabel = '$workingSetNumber';
        } else {
          setLabel = target.setTypeLabel; // W, D, F, A
        }

        final calculatedRir = target.targetRir ??
            _calculateRir(target.setType, currentWorkingIndex, totalWorkingSets);

        return _SetDescriptor(
          label: setLabel,
          isWarmup: target.isWarmup,
          setType: target.setType,
          weightKg: target.targetWeightKg,
          targetReps: target.targetReps,
          targetRir: calculatedRir,
        );
      }).toList();
    }

    // Fallback to legacy format (hardcoded 2 warmups + working sets)
    final totalSets = exercise.sets ?? 3;
    const warmupSets = 2;
    final defaultReps = exercise.reps ?? 10;

    return [
      ...List.generate(
        warmupSets,
        (i) => _SetDescriptor(
          label: 'W',
          isWarmup: true,
          setType: 'warmup',
          weightKg: null,
          targetReps: defaultReps,
          targetRir: null, // Warmups don't have RIR
        ),
      ),
      ...List.generate(
        totalSets,
        (i) => _SetDescriptor(
          label: '${i + 1}',
          isWarmup: false,
          setType: 'working',
          weightKg: exercise.weight,
          targetReps: defaultReps,
          targetRir: _calculateRir('working', i, totalSets),
        ),
      ),
    ];
  }

  /// Section header for the Warmup / Effective groups. The warmup header is
  /// collapsible (shows a "Hide"/"Show" toggle); the effective header carries
  /// an accent tint so it reads as the "sets that count".
  Widget _buildSetGroupHeader({
    required String label,
    required int count,
    required Color color,
    required Color textMuted,
    required Color glassSurface,
    required Color cardBorder,
    required bool collapsible,
    bool collapsed = false,
    bool highlighted = false,
    VoidCallback? onToggle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayColor = isDark ? color : _darkenColor(color);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 6),
      decoration: BoxDecoration(
        color: highlighted
            ? color.withOpacity(isDark ? 0.06 : 0.08)
            : glassSurface.withOpacity(0.25),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: displayColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: highlighted ? displayColor : textMuted,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textMuted.withOpacity(0.8),
            ),
          ),
          const Spacer(),
          if (collapsible && onToggle != null)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      collapsed ? 'Show' : 'Hide',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: displayColor,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      collapsed
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_up,
                      size: 16,
                      color: displayColor,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }


  /// Small glowing hexagon score chip for the header chip-row (Surface 2).
  /// Renders nothing until the score loads AND has data, so the header stays
  /// quiet for brand-new exercises and never shows a "0" placeholder.
  Widget _buildStrengthScoreChip(Color accentColor) {
    return Consumer(
      builder: (context, ref, _) {
        final scoreAsync =
            ref.watch(exerciseStrengthScoreProvider(widget.exercise.name));
        final ExerciseStrengthScore? score = scoreAsync.asData?.value;
        if (score == null || !score.hasData) {
          return const SizedBox.shrink();
        }
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final color = isDark ? accentColor : _darkenColor(accentColor);
        return HexagonBadge(
          value: '${score.score}',
          color: color,
          size: 34,
          numberSize: 14,
        );
      },
    );
  }

  /// Per-exercise strength score card (Surface 2 / Gravl Image #2), shown
  /// below the set list inside the expanded card. The card itself handles its
  /// loading / empty / populated states, so we just give it side padding so it
  /// doesn't run edge-to-edge like the set rows do.
  Widget _buildStrengthScoreSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: ExerciseStrengthScoreCard(exerciseName: widget.exercise.name),
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
                  // Per-exercise strength score card (Surface 2) below the sets.
                  _buildStrengthScoreSection(),
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
            // Exercise Image (with muscle-group anatomy badge overlay)
            _buildExerciseThumbnail(exercise, glassSurface, textMuted, accentColor),
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
                            margin: const EdgeInsetsDirectional.only(start: 8),
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
                                  AppLocalizations.of(context)!.commonNew,
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
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Small strength-score hexagon chip (Surface 2) — only
                      // when the exercise has logged history. Sits alongside the
                      // existing muscle / equipment / preference chips and
                      // shares the row's horizontal wrap so it never overflows.
                      _buildStrengthScoreChip(accentColor),
                      // "Finisher" chip — when the backend appended this
                      // exercise as a cardio/conditioning finisher (e.g. a
                      // rowing machine the user explicitly picked on a strength
                      // day). Distinct amber accent so it reads as a tag, not a
                      // muscle/equipment label.
                      if (exercise.isFinisher == true) _buildFinisherChip(),
                      // Movement-category chip — SKILL / STRENGTH / PREHAB
                      // (Dr-Yaad audit #8). Mirrors his Today screen tags. Data
                      // is backend-derived (movement_category) with a client
                      // fallback; null → no chip (fail-open).
                      if (exercise.movementCategoryResolved != null)
                        _buildMovementCategoryChip(
                            exercise.movementCategoryResolved!),
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


  /// 60×60 exercise thumbnail with an optional muscle-group anatomy badge
  /// pinned to the bottom-right corner (matches the pattern used in the
  /// exercise library so users get a quick visual cue of the primary muscle).
  Widget _buildExerciseThumbnail(
    WorkoutExercise exercise,
    Color glassSurface,
    Color textMuted,
    Color accentColor,
  ) {
    final muscleAsset = _muscleAssetForExercise(exercise);

    return GestureDetector(
      // Tap on thumbnail = open the exercise info modal (muscle illustration,
      // setup, tips, video). Card-body taps still expand/collapse via the
      // outer InkWell — only the thumbnail short-circuits to info, which
      // matches the user's mental model from the exercise library.
      behavior: HitTestBehavior.opaque,
      onTap: () => showExerciseInfoSheet(context: context, exercise: exercise),
      child: Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: glassSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildImage(glassSurface, textMuted, accentColor),
          if (muscleAsset != null)
            PositionedDirectional(end: 3,
              bottom: 3,
              child: Container(
                width: 22,
                height: 22,
                      padding: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    muscleAsset,
                    fit: BoxFit.cover,
                    cacheWidth: 44,
                    cacheHeight: 44,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
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
    // AI-authored exercises (e.g. "hay bale" moves) have no library
    // illustration — show their representative emoji instead of a generic
    // dumbbell so the thumbnail is never empty/broken (Google-Health style).
    final emoji = widget.exercise.emoji;
    if (emoji != null && emoji.trim().isNotEmpty) {
      return Container(
        color: glassSurface,
        alignment: Alignment.center,
        child: Text(
          emoji.trim(),
          style: const TextStyle(fontSize: 26),
        ),
      );
    }
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
            final l = AppLocalizations.of(ctx)!;
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
                    label: isFavorite ? l.exerciseMenuRemoveFromFavorites : l.exerciseMenuAddToFavorites,
                    trailingCheck: isFavorite ? AppColors.error : null,
                    textPrimary: textPrimary,
                    onTap: () => _handleSheetAction(sheetCtx, 'favorite'),
                  ),
                  _sheetTile(
                    context: ctx,
                    icon: isQueued ? Icons.playlist_add_check : Icons.playlist_add,
                    iconColor: isQueued ? AppColors.cyan : textPrimary,
                    label: isQueued ? l.exerciseMenuRemoveFromQueue : l.exerciseMenuRepeatNextTime,
                    trailingCheck: isQueued ? AppColors.cyan : null,
                    textPrimary: textPrimary,
                    onTap: () => _handleSheetAction(sheetCtx, 'queue'),
                  ),
                  _sheetTile(
                    context: ctx,
                    icon: isStaple ? Icons.push_pin : Icons.push_pin_outlined,
                    iconColor: isStaple ? AppColors.purple : textPrimary,
                    label: isStaple ? l.exerciseMenuRemoveAsStaple : l.exerciseMenuMarkAsStaple,
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
                      label: l.exerciseMenuViewHistory,
                      textPrimary: textPrimary,
                      onTap: () => _handleSheetAction(sheetCtx, 'history'),
                    ),
                  if (widget.onSwap != null)
                    _sheetTile(
                      context: ctx,
                      icon: Icons.swap_horiz,
                      iconColor: textPrimary,
                      label: l.exerciseMenuSwapExercise,
                      textPrimary: textPrimary,
                      onTap: () => _handleSheetAction(sheetCtx, 'swap'),
                    ),
                  if (widget.onLinkSuperset != null)
                    _sheetTile(
                      context: ctx,
                      icon: Icons.link,
                      iconColor: textPrimary,
                      label: l.exerciseMenuLinkAsSuperset,
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
                      label: l.exerciseMenuRemoveFromWorkout,
                      labelColor: AppColors.error,
                      textPrimary: textPrimary,
                      onTap: () => _handleSheetAction(sheetCtx, 'remove'),
                    ),
                  if (widget.onNeverRecommend != null)
                    _sheetTile(
                      context: ctx,
                      icon: Icons.block_rounded,
                      iconColor: AppColors.error,
                      label: l.exerciseMenuNeverRecommend,
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
                    label: l.exerciseMenuWhatDoTheseMean,
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
          text: newState ? AppLocalizations.of(context)!.exerciseMenuAddedToFavorites : AppLocalizations.of(context)!.exerciseMenuRemovedFromFavorites,
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
          text: newState ? AppLocalizations.of(context)!.exerciseMenuQueuedForNext : AppLocalizations.of(context)!.exerciseMenuRemovedFromQueue,
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
          text: newState ? AppLocalizations.of(context)!.exerciseMenuMarkedAsStaple : AppLocalizations.of(context)!.exerciseMenuRemovedFromStaples,
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
    final l = AppLocalizations.of(context)!;
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
                  l.exerciseTableHeaderSet,
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
                  padding: const EdgeInsetsDirectional.only(start: 8),
                  child: Text(
                    l.exerciseTableHeaderLast,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: textMuted,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
              // TARGET column - AI recommended weight × reps.
              // Surface 6a: a per-DB weight badge (dumbbell exercises) and/or a
              // per-arm reps badge (unilateral exercises) clarify what the
              // number means — so "30 lb × 10" reads as "per dumbbell" not
              // "total", and reps as "per arm".
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l.exerciseTableHeaderTarget,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: accentColor.withOpacity(0.9),
                        letterSpacing: 0.3,
                      ),
                    ),
                    _buildPerSideLabels(textMuted, accentColor),
                  ],
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

  /// Per-DB / per-arm clarifier badges under the TARGET header.
  ///
  /// • "PER DB"  when the exercise's equipment (lowercased) contains
  ///   "dumbbell" — the loaded weight is per dumbbell, not the pair total.
  /// • "PER ARM" when the model's [WorkoutExercise.isUnilateral] flag is true —
  ///   the reps are per arm/side (the model exposes a real laterality flag, so
  ///   no brittle name whitelist is needed). `alternatingHands` (single
  ///   dumbbell passed hand-to-hand) is treated as unilateral too.
  ///
  /// Renders nothing when neither applies (the common bilateral barbell case).
  Widget _buildPerSideLabels(Color textMuted, Color accentColor) {
    final equipment = widget.exercise.equipment?.toLowerCase() ?? '';
    final isPerDb = equipment.contains('dumbbell');
    final isPerArm = widget.exercise.isUnilateral == true ||
        widget.exercise.alternatingHands == true;

    if (!isPerDb && !isPerArm) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          if (isPerDb) _buildColumnTag('PER DB', accentColor),
          if (isPerArm) _buildColumnTag('PER ARM', AppColors.orange),
        ],
      ),
    );
  }

  /// Tiny uppercase tag used for the per-DB / per-arm column clarifiers.
  Widget _buildColumnTag(String text, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayColor = isDark ? color : _darkenColor(color);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.12 : 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: displayColor.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: displayColor,
        ),
      ),
    );
  }


  /// Amber "Finisher" tag chip — shown when [WorkoutExercise.isFinisher] is
  /// true (an appended cardio/conditioning finisher). Distinct from the
  /// accent-colored muscle/equipment chips so it reads as a label, not a stat.
  Widget _buildFinisherChip() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const color = Colors.amber;
    final displayColor = isDark ? color : _darkenColor(color);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.12 : 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: displayColor.withOpacity(0.4), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt, size: 12, color: displayColor),
          const SizedBox(width: 4),
          Text(
            'Finisher',
            style: TextStyle(
              fontSize: 11,
              color: displayColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// SKILL / STRENGTH / PREHAB movement-category tag chip (Dr-Yaad audit #8).
  /// Distinct hue per bucket so the user reads the session's intent at a glance:
  /// SKILL = indigo (technique/holds), STRENGTH = the card accent, PREHAB =
  /// teal (mobility/warm-down). Mirrors his Today screen's per-exercise tags.
  Widget _buildMovementCategoryChip(String category) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final IconData icon;
    final Color color;
    switch (category.toUpperCase()) {
      case 'SKILL':
        icon = Icons.auto_awesome;
        color = const Color(0xFF7C6CF4); // indigo
        break;
      case 'PREHAB':
        icon = Icons.healing;
        color = const Color(0xFF14B8A6); // teal
        break;
      case 'STRENGTH':
      default:
        icon = Icons.fitness_center;
        color = const Color(0xFFEF5777); // rose
        break;
    }
    final displayColor = isDark ? color : _darkenColor(color);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.12 : 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: displayColor.withOpacity(0.4), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: displayColor),
          const SizedBox(width: 4),
          Text(
            category.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              color: displayColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
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
              AppLocalizations.of(context)!.exerciseDetailsBreathing,
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
