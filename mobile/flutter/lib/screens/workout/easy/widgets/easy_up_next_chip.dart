// Easy tier — "Up next: <Exercise>" chip.
//
// Shows the next exercise's thumbnail + name in a compact pill. When there
// is no next exercise (final one of the workout) renders "Last exercise —
// nearly there!" as positive reinforcement instead of an empty chip.

import 'package:flutter/material.dart';

class EasyUpNextChip extends StatelessWidget {
  final String? nextExerciseName;
  final String? nextExerciseImageUrl;

  /// Tap to skip forward to the next exercise. Null disables the tap
  /// interaction (e.g. on the final exercise).
  final VoidCallback? onSkipToNext;

  const EasyUpNextChip({
    super.key,
    this.nextExerciseName,
    this.nextExerciseImageUrl,
    this.onSkipToNext,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? Colors.white : Colors.black;
    final bg = base.withValues(alpha: 0.04);
    final border = base.withValues(alpha: 0.10);
    final muted = base.withValues(alpha: 0.58);

    final hasNext = nextExerciseName != null && nextExerciseName!.isNotEmpty;
    final hasImage = hasNext &&
        nextExerciseImageUrl != null &&
        nextExerciseImageUrl!.isNotEmpty;

    final enabled = hasNext && onSkipToNext != null;
    return SizedBox(
      height: 44,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: enabled ? onSkipToNext : null,
          child: Container(
            padding: EdgeInsets.only(
              left: hasImage ? 4 : 12,
              right: 12,
              top: 0,
              bottom: 0,
            ),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: border),
            ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasImage) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 32,
                    height: 32,
                    color: base.withValues(alpha: 0.06),
                    child: Image.network(
                      nextExerciseImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.fitness_center_rounded,
                        size: 18,
                        color: muted,
                      ),
                      loadingBuilder: (ctx, child, progress) {
                        if (progress == null) return child;
                        return Center(
                          child: SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.8,
                              color: muted,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ] else
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    hasNext
                        ? Icons.arrow_forward_rounded
                        : Icons.emoji_events_outlined,
                    size: 14,
                    color: muted,
                  ),
                ),
              Flexible(
                child: Text(
                  hasNext
                      ? 'Up next: ${nextExerciseName!}'
                      : 'Last exercise — nearly there!',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: muted,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (enabled) ...[
                const SizedBox(width: 6),
                Icon(Icons.skip_next_rounded, size: 16, color: muted),
              ],
            ],
          ),
          ),
        ),
      ),
    );
  }
}
