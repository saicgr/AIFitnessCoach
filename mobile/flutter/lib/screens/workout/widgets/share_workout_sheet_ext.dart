part of 'share_workout_sheet.dart';

/// Canonical template id list — matches [_captureKeys] order and is the
/// stable persistence key for favorites/order in
/// [sharePreferencesProvider].
const List<String> kShareTemplateOrder = [
  'anatomy_hero',       // 0
  'volume_hero',        // 1
  'pr_poster',          // 2 (conditional)
  'classic_stats',      // 3
  'streak_calendar',    // 4
  'exercise_breakdown', // 5
  'wrapped',            // 6
  'trading_card',       // 7
  'receipt',            // 8
  'newspaper',          // 9
  'retro_80s',          // 10
  'transparent_sticker',// 11
];

extension __ShareWorkoutSheetStateExt on _ShareWorkoutSheetState {

  /// Build the template gallery. Renders all 12 templates as live
  /// thumbnail previews in a 2-column vertically-scrolling grid.
  /// Tapping a tile sets [_currentPage] and opens the full preview.
  Widget _buildTemplateGallery() {
    final now = DateTime.now();
    final useKg = ref.watch(useKgForWorkoutProvider);
    final weightUnit = useKg ? 'kg' : 'lbs';
    final displayVolume = widget.totalVolumeKg != null && !useKg
        ? widget.totalVolumeKg! * 2.20462
        : widget.totalVolumeKg;
    if (kDebugMode) {
      debugPrint(
        '[ShareSheet] useKg=$useKg unit=$weightUnit '
        'volumeKg=${widget.totalVolumeKg} display=$displayVolume',
      );
    }

    // Apply user's favorites/order if the provider has it.
    final prefs = ref.watch(sharePreferencesProvider);
    final orderedIds = _applyPreferences(prefs);

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 12,
        childAspectRatio: 9 / 16.6, // a hair taller than 9:16 to fit label
      ),
      itemCount: orderedIds.length,
      itemBuilder: (context, displayIndex) {
        final id = orderedIds[displayIndex];
        final index = kShareTemplateOrder.indexOf(id);
        if (index < 0) return const SizedBox.shrink();

        final isFavorite = prefs.favorites.contains(id);
        final isSelected = _currentPage == index;
        final template = _buildTemplateForId(id, weightUnit, displayVolume, now);
        final lockMessage = _lockMessageFor(id);

        return _GalleryTile(
          templateId: id,
          displayName: _prettyName(id),
          isFavorite: isFavorite,
          isSelected: isSelected,
          lockMessage: lockMessage,
          onTap: () {
            if (lockMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(lockMessage)),
              );
              return;
            }
            HapticFeedback.selectionClick();
            setState(() => _currentPage = index);
            _showImagePreview();
          },
          onFavoriteToggle: () {
            HapticFeedback.selectionClick();
            ref
                .read(sharePreferencesProvider.notifier)
                .toggleFavorite(id);
          },
          child: CapturableWidget(
            captureKey: _captureKeys[index],
            child: InstagramStoryWrapper(
              backgroundGradient: _getGradientForTemplate(index),
              child: template,
            ),
          ),
        );
      },
    );
  }

  // Lock state: PR Poster needs a PR; Transparent Sticker works
  // always. If we add Polaroid later, it would lock when no photo.
  String? _lockMessageFor(String id) {
    if (id == 'pr_poster' && (widget.newPRs ?? const []).isEmpty) {
      return 'Log a PR to unlock this template';
    }
    return null;
  }

  /// Return the list of template ids in display order, honoring the
  /// user's favorites + custom order. Favorites pin to the top.
  List<String> _applyPreferences(SharePreferences prefs) {
    final userOrder = prefs.order.where((id) => kShareTemplateOrder.contains(id)).toList();
    final missing = kShareTemplateOrder.where((id) => !userOrder.contains(id)).toList();
    final merged = [...userOrder, ...missing];
    // Pin favorites to top, preserving their relative order.
    final favs = merged.where((id) => prefs.favorites.contains(id)).toList();
    final rest = merged.where((id) => !prefs.favorites.contains(id)).toList();
    return [...favs, ...rest];
  }

  Widget _buildTemplateForId(
    String id,
    String weightUnit,
    double? displayVolume,
    DateTime now,
  ) {
    switch (id) {
      case 'anatomy_hero':
        return AnatomyHeroTemplate(
          workoutName: widget.workoutName,
          durationSeconds: widget.durationSeconds,
          totalSets: widget.totalSets ?? 0,
          totalVolumeKg: displayVolume,
          musclesWorked: widget.musclesWorked ?? const {},
          completedAt: now,
          showWatermark: _showWatermark,
          weightUnit: weightUnit,
        );
      case 'volume_hero':
        return VolumeHeroTemplate(
          workoutName: widget.workoutName,
          totalVolumeKg: displayVolume,
          durationSeconds: widget.durationSeconds,
          totalSets: widget.totalSets ?? 0,
          totalReps: widget.totalReps ?? 0,
          exercisesCount: widget.exercisesCount,
          completedAt: now,
          showWatermark: _showWatermark,
          weightUnit: weightUnit,
        );
      case 'pr_poster':
        return PrPosterTemplate(
          workoutName: widget.workoutName,
          prsData: widget.newPRs ?? const [],
          completedAt: now,
          showWatermark: _showWatermark,
          weightUnit: weightUnit,
          durationSeconds: widget.durationSeconds,
        );
      case 'classic_stats':
        return ClassicStatsTemplate(
          workoutName: widget.workoutName,
          durationSeconds: widget.durationSeconds,
          calories: widget.calories,
          totalVolumeKg: displayVolume,
          totalSets: widget.totalSets,
          totalReps: widget.totalReps,
          exercisesCount: widget.exercisesCount,
          completedAt: now,
          showWatermark: _showWatermark,
          weightUnit: weightUnit,
        );
      case 'streak_calendar':
        return StreakCalendarTemplate(
          currentStreak: widget.currentStreak,
          totalWorkouts: widget.totalWorkouts ?? 1,
          workoutDates: widget.recentWorkoutDates ?? [now],
          completedAt: now,
          showWatermark: _showWatermark,
        );
      case 'exercise_breakdown':
        return ExerciseBreakdownTemplate(
          workoutName: widget.workoutName,
          exercises: widget.exercises ?? const [],
          durationSeconds: widget.durationSeconds,
          totalSets: widget.totalSets ?? 0,
          totalVolumeKg: displayVolume,
          completedAt: now,
          showWatermark: _showWatermark,
          weightUnit: weightUnit,
        );
      case 'wrapped':
        return WrappedTemplate(
          workoutName: widget.workoutName,
          durationSeconds: widget.durationSeconds,
          totalVolumeKg: displayVolume,
          totalSets: widget.totalSets ?? 0,
          exercisesCount: widget.exercisesCount,
          completedAt: now,
          showWatermark: _showWatermark,
          weightUnit: weightUnit,
        );
      case 'trading_card':
        return TradingCardTemplate(
          workoutName: widget.workoutName,
          userDisplayName: widget.userDisplayName,
          userAvatarUrl: widget.userAvatarUrl,
          totalVolumeKg: displayVolume,
          totalSets: widget.totalSets ?? 0,
          currentStreak: widget.currentStreak,
          topExercise: widget.exercises?.isNotEmpty == true
              ? widget.exercises!.first.name
              : null,
          topExerciseWeightKg:
              widget.exercises?.isNotEmpty == true
                  ? widget.exercises!.first.topWeightKg
                  : null,
          completedAt: now,
          showWatermark: _showWatermark,
          weightUnit: weightUnit,
        );
      case 'receipt':
        return ReceiptTemplate(
          workoutName: widget.workoutName,
          exercises: widget.exercises ?? const [],
          durationSeconds: widget.durationSeconds,
          totalSets: widget.totalSets ?? 0,
          totalVolumeKg: displayVolume,
          calories: widget.calories,
          completedAt: now,
          showWatermark: _showWatermark,
          weightUnit: weightUnit,
        );
      case 'newspaper':
        return NewspaperTemplate(
          workoutName: widget.workoutName,
          userDisplayName: widget.userDisplayName,
          totalVolumeKg: displayVolume,
          totalSets: widget.totalSets ?? 0,
          durationSeconds: widget.durationSeconds,
          exercisesCount: widget.exercisesCount,
          exercises: widget.exercises ?? const [],
          completedAt: now,
          showWatermark: _showWatermark,
          weightUnit: weightUnit,
        );
      case 'retro_80s':
        return Retro80sTemplate(
          workoutName: widget.workoutName,
          durationSeconds: widget.durationSeconds,
          totalVolumeKg: displayVolume,
          totalSets: widget.totalSets ?? 0,
          calories: widget.calories,
          completedAt: now,
          showWatermark: _showWatermark,
          weightUnit: weightUnit,
        );
      case 'transparent_sticker':
        return TransparentStickerTemplate(
          workoutName: widget.workoutName,
          totalVolumeKg: displayVolume,
          totalSets: widget.totalSets ?? 0,
          durationSeconds: widget.durationSeconds,
          completedAt: now,
          showWatermark: _showWatermark,
          weightUnit: weightUnit,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  String _prettyName(String id) {
    switch (id) {
      case 'anatomy_hero': return 'Anatomy';
      case 'volume_hero': return 'Volume';
      case 'pr_poster': return 'PR Poster';
      case 'classic_stats': return 'Classic';
      case 'streak_calendar': return 'Streak';
      case 'exercise_breakdown': return 'Breakdown';
      case 'wrapped': return 'Wrapped';
      case 'trading_card': return 'Trading Card';
      case 'receipt': return 'Receipt';
      case 'newspaper': return 'Newspaper';
      case 'retro_80s': return 'Retro 80s';
      case 'transparent_sticker': return 'Sticker';
      default: return id;
    }
  }
}

/// Thumbnail tile in the gallery grid. Handles tap, favorite toggle,
/// selected ring, and lock overlay.
class _GalleryTile extends StatelessWidget {
  final String templateId;
  final String displayName;
  final bool isFavorite;
  final bool isSelected;
  final String? lockMessage;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final Widget child;

  const _GalleryTile({
    required this.templateId,
    required this.displayName,
    required this.isFavorite,
    required this.isSelected,
    this.lockMessage,
    required this.onTap,
    required this.onFavoriteToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: 9 / 16,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Template preview — FittedBox scales the real template
                  // to fit the thumbnail without losing detail.
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: FittedBox(
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: 1080,
                        height: 1920,
                        child: child,
                      ),
                    ),
                  ),
                  // Selected ring
                  if (isSelected)
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFF97316),
                          width: 2,
                        ),
                      ),
                    ),
                  // Favorite star (top-left)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: GestureDetector(
                      onTap: onFavoriteToggle,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFavorite ? Icons.star : Icons.star_border,
                          size: 16,
                          color: isFavorite
                              ? const Color(0xFFFFC107)
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // Lock overlay for conditional templates
                  if (lockMessage != null)
                    Positioned.fill(
                      child: ShareLockOverlay(message: lockMessage!),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            displayName,
            style: TextStyle(
              fontSize: 11,
              color: isSelected
                  ? const Color(0xFFF97316)
                  : Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
