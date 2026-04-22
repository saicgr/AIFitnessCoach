// Easy tier — exercise header.
//
// 280 pt tall on default devices (180 pt thumbnail compacted for iPhone SE).
// Shows:
//   • Big exercise name (24 pt, w600, centered)
//   • "Set N of M" subtitle (14 pt muted)
//   • Centered demo thumbnail (gifUrl → videoUrl fallback)
//   • Row: ▶ Show video · 📋 Plan · [ kg | lb ]
//
// Nothing scrolls: the thumbnail sizes down on tiny safe-area heights.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/exercise.dart';
import '../../../../core/services/haptic_service.dart';

class EasyExerciseHeader extends ConsumerWidget {
  final WorkoutExercise exercise;
  final int currentSet; // 1-indexed
  final int totalSets;
  final VoidCallback onShowVideo;
  final VoidCallback onOpenPlan;
  final VoidCallback onShowInfo;

  /// Tap + on the "Set N of M" row. Null disables (e.g. at the upper cap).
  final VoidCallback? onAddSet;

  /// Tap − on the "Set N of M" row. Null disables (e.g. can't drop a
  /// completed or the current set).
  final VoidCallback? onRemoveSet;

  /// Tap handler for the 📝 note chip in the header row. Null hides it.
  final VoidCallback? onEditNote;

  /// Whether a note/audio/photo is currently attached to the focal set.
  final bool hasNote;

  /// When true, compact layout for SE-class devices (180 pt thumbnail).
  final bool compact;

  const EasyExerciseHeader({
    super.key,
    required this.exercise,
    required this.currentSet,
    required this.totalSets,
    required this.onShowVideo,
    required this.onOpenPlan,
    required this.onShowInfo,
    this.onAddSet,
    this.onRemoveSet,
    this.onEditNote,
    this.hasNote = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final muted = textColor.withValues(alpha: 0.58);
    // Max thumbnail size the layout targets. Actual render size shrinks when
    // the title wraps to a second line or when the parent column is short.
    final thumbnailMax = compact ? 140.0 : 180.0;
    // Bumped caps (240 / 320) give room for 2-line titles. The thumbnail is
    // Flexible below, so it still downsizes when available height < cap.
    final maxHeight = compact ? 240.0 : 320.0;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Text(
              exercise.name,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: textColor,
                height: 1.1,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SetCountStepButton(
                  icon: Icons.remove_rounded,
                  onTap: onRemoveSet,
                  color: muted,
                  tooltip: 'Remove set',
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Set $currentSet of $totalSets',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: muted,
                    ),
                  ),
                ),
                _SetCountStepButton(
                  icon: Icons.add_rounded,
                  onTap: onAddSet,
                  color: muted,
                  tooltip: 'Add set',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              fit: FlexFit.loose,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: thumbnailMax,
                  maxHeight: thumbnailMax,
                ),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: _Thumbnail(exercise: exercise, isDark: isDark),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Bottom row: ▶ Video · 📖 Instructions · 📋 Plan · 📝 Note.
            // Video = looping full-screen video player only.
            // Instructions = muscle / body / equipment + written how-to.
            // Plan = full workout at a glance.
            // Note = per-set text + audio + photo (the kg/lb toggle lives
            //       inside the Weight stepper now — right where the unit
            //       appears — so this slot holds the per-set note chip).
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LinkChip(
                  icon: Icons.play_circle_outline,
                  label: 'Video',
                  color: textColor,
                  onTap: () async {
                    await HapticService.instance.tap();
                    onShowVideo();
                  },
                ),
                const SizedBox(width: 10),
                _LinkChip(
                  icon: Icons.menu_book_outlined,
                  label: 'Instructions',
                  color: textColor,
                  onTap: () async {
                    await HapticService.instance.tap();
                    onShowInfo();
                  },
                ),
                const SizedBox(width: 10),
                _LinkChip(
                  icon: Icons.list_alt_rounded,
                  label: 'Plan',
                  color: textColor,
                  onTap: () async {
                    await HapticService.instance.tap();
                    onOpenPlan();
                  },
                ),
                if (onEditNote != null) ...[
                  const SizedBox(width: 10),
                  _NoteHeaderChip(
                    onTap: onEditNote!,
                    hasNote: hasNote,
                    color: textColor,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Centered demo thumbnail. Uses gifUrl if available; falls back to a
/// muted icon placeholder. Videos (videoUrl) render via the Show Video
/// CTA — the still here is just for instant recognition.
class _Thumbnail extends StatelessWidget {
  final WorkoutExercise exercise;
  final bool isDark;
  const _Thumbnail({required this.exercise, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04);
    final border = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.10);
    // Canonical resolution used across the app: static image > animated gif >
    // video-poster fallback. The backend populates `imageS3Path` for almost
    // every library exercise; gifUrl/videoUrl are only set for AI-imported
    // custom ones. Easy was ignoring imageS3Path, which is why beginners
    // always saw the placeholder dumbbell icon.
    final url = exercise.imageS3Path ?? exercise.gifUrl ?? exercise.videoUrl;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      clipBehavior: Clip.antiAlias,
      child: (url != null && url.isNotEmpty)
          ? Image.network(
              url,
              fit: BoxFit.cover,
              loadingBuilder: (ctx, child, progress) {
                if (progress == null) return child;
                return Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color:
                          (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4),
                    ),
                  ),
                );
              },
              errorBuilder: (ctx, err, stack) => _placeholderIcon(isDark),
            )
          : _placeholderIcon(isDark),
    );
  }

  Widget _placeholderIcon(bool isDark) => Center(
        child: Icon(
          Icons.fitness_center_rounded,
          size: 56,
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.22),
        ),
      );
}

class _LinkChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _LinkChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color.withValues(alpha: 0.80)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color.withValues(alpha: 0.80),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small 24-pt +/− button flanking the "Set N of M" subtitle. Null [onTap]
/// disables the button and renders it at reduced opacity.
class _SetCountStepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;
  final String tooltip;

  const _SetCountStepButton({
    required this.icon,
    required this.onTap,
    required this.color,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: enabled
              ? () async {
                  await HapticService.instance.tap();
                  onTap!();
                }
              : null,
          child: Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: enabled ? 0.10 : 0.04),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 14,
              color: color.withValues(alpha: enabled ? 1.0 : 0.35),
            ),
          ),
        ),
      ),
    );
  }
}

/// Header-row `📝 Note` chip. Matches the visual weight of the sibling
/// Video / Instructions / Plan link chips but adds an accent-tinted state
/// + ✓ indicator once the current focal set has a note / audio / photo.
class _NoteHeaderChip extends StatelessWidget {
  final VoidCallback onTap;
  final bool hasNote;
  final Color color;

  const _NoteHeaderChip({
    required this.onTap,
    required this.hasNote,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final fg = hasNote ? accent : color.withValues(alpha: 0.80);
    final label = hasNote ? 'Note ✓' : 'Note';
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        await HapticService.instance.tap();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_note_rounded, size: 18, color: fg),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
